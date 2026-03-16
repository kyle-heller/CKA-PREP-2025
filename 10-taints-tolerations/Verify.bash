#!/bin/bash
# Verify: Q10 — Taints & Tolerations
PASS=true

echo "=== Q10: Taints & Tolerations ==="

# Check node01 has taint PERMISSION=granted:NoSchedule
TAINTS=$(kubectl get node node01 -o jsonpath='{.spec.taints}' 2>/dev/null)
if echo "$TAINTS" | grep -q '"key":"PERMISSION"' && echo "$TAINTS" | grep -q '"value":"granted"' && echo "$TAINTS" | grep -q '"effect":"NoSchedule"'; then
  echo "[PASS] node01 has taint PERMISSION=granted:NoSchedule"
else
  echo "[FAIL] node01 missing taint PERMISSION=granted:NoSchedule"
  PASS=false
fi

# Check nginx pod exists and is Running
POD_STATUS=$(kubectl get pod nginx -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" = "Running" ]; then
  echo "[PASS] Pod nginx is Running"
else
  echo "[FAIL] Pod nginx should be Running (got: $POD_STATUS)"
  PASS=false
fi

# Check pod has toleration for PERMISSION
POD_TOLERATIONS=$(kubectl get pod nginx -o jsonpath='{.spec.tolerations}' 2>/dev/null)
if echo "$POD_TOLERATIONS" | grep -q '"key":"PERMISSION"'; then
  echo "[PASS] Pod nginx has PERMISSION toleration"
else
  echo "[FAIL] Pod nginx missing PERMISSION toleration"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
