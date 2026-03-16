#!/bin/bash
# Verify: Q01 — MariaDB Persistent Volume
PASS=true

echo "=== Q01: MariaDB Persistent Volume ==="

# Check PVC exists and is Bound
PVC_PHASE=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_PHASE" = "Bound" ]; then
  echo "[PASS] PVC mariadb exists and is Bound"
else
  echo "[FAIL] PVC mariadb not found or not Bound (got: $PVC_PHASE)"
  PASS=false
fi

# Check Deployment exists and is available
AVAIL=$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${AVAIL:-0}" -ge 1 ] 2>/dev/null; then
  echo "[PASS] Deployment mariadb is available (replicas: $AVAIL)"
else
  echo "[FAIL] Deployment mariadb not available (availableReplicas: ${AVAIL:-none})"
  PASS=false
fi

# Check pod has a volume mount for mariadb-storage
POD=$(kubectl get pods -n mariadb -l app=mariadb -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
  MOUNT=$(kubectl get pod "$POD" -n mariadb -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name=="mariadb-storage")].mountPath}' 2>/dev/null)
  if [ "$MOUNT" = "/var/lib/mysql" ]; then
    echo "[PASS] Pod volume mounted at /var/lib/mysql"
  else
    echo "[FAIL] Pod volume mount not found at /var/lib/mysql (got: $MOUNT)"
    PASS=false
  fi
else
  echo "[FAIL] No mariadb pod running"
  PASS=false
fi

# Check PV is bound to the PVC
PV_CLAIM=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.claimRef.name}' 2>/dev/null)
if [ "$PV_CLAIM" = "mariadb" ]; then
  echo "[PASS] PV mariadb-pv is bound to PVC mariadb"
else
  echo "[FAIL] PV mariadb-pv not bound to PVC mariadb (got: $PV_CLAIM)"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
