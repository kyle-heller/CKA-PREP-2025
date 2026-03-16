#!/bin/bash
# Verify: Q17 — TLS Configuration
PASS=true

echo "=== Q17: TLS Configuration ==="

# Check ConfigMap has TLSv1.3
CM_DATA=$(kubectl get configmap nginx-config -n nginx-static -o jsonpath='{.data.nginx\.conf}' 2>/dev/null)
if echo "$CM_DATA" | grep -q 'TLSv1.3'; then
  echo "[PASS] ConfigMap contains TLSv1.3"
else
  echo "[FAIL] ConfigMap should contain TLSv1.3"
  PASS=false
fi

# Check ConfigMap does NOT have TLSv1.2
if echo "$CM_DATA" | grep -q 'TLSv1.2'; then
  echo "[FAIL] ConfigMap still contains TLSv1.2 (should be removed)"
  PASS=false
else
  echo "[PASS] ConfigMap does not contain TLSv1.2"
fi

# Check /etc/hosts has ckaquestion.k8s.local
if grep -q 'ckaquestion.k8s.local' /etc/hosts 2>/dev/null; then
  echo "[PASS] /etc/hosts contains ckaquestion.k8s.local"
else
  echo "[FAIL] /etc/hosts missing ckaquestion.k8s.local entry"
  PASS=false
fi

# Check pods are running
RUNNING=$(kubectl get pods -n nginx-static -l app=nginx-static --no-headers 2>/dev/null | grep -c 'Running' || echo "0")
if [ "$RUNNING" -ge 1 ]; then
  echo "[PASS] nginx-static pods running ($RUNNING)"
else
  echo "[FAIL] No nginx-static pods running"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
