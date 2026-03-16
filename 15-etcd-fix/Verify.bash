#!/bin/bash
# Verify: Q15 — Etcd Fix
PASS=true

echo "=== Q15: Etcd Fix ==="

# Check kubectl works (API server is up)
if kubectl get nodes &>/dev/null; then
  echo "[PASS] kubectl get nodes works — API server is up"
else
  echo "[FAIL] kubectl get nodes failed — API server still down"
  PASS=false
fi

# Check etcd-servers flag uses port 2379
ETCD_SERVERS=$(grep -- '--etcd-servers' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || echo "")
if echo "$ETCD_SERVERS" | grep -q ':2379'; then
  echo "[PASS] etcd-servers uses port 2379"
else
  echo "[FAIL] etcd-servers should use port 2379"
  PASS=false
fi

if echo "$ETCD_SERVERS" | grep -q ':2380'; then
  echo "[FAIL] etcd-servers still references port 2380"
  PASS=false
else
  echo "[PASS] etcd-servers does not reference port 2380"
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
