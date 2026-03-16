#!/bin/bash
# Verify: Q08 — CNI & Network Policy
PASS=true

echo "=== Q08: CNI & Network Policy ==="

# Check all nodes are Ready
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -v "Ready" | wc -l)
if [ "$NOT_READY" -eq 0 ]; then
  echo "[PASS] All nodes are Ready"
else
  echo "[FAIL] Some nodes are not Ready"
  PASS=false
fi

# Check CNI pods running in kube-system (Cilium, Calico, or Flannel)
CNI_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -E '(cilium|calico|flannel|weave)' | grep -c 'Running' || echo "0")
if [ "$CNI_PODS" -ge 1 ]; then
  echo "[PASS] CNI pods running in kube-system ($CNI_PODS pods)"
else
  # Also check tigera-operator namespace for Calico
  CALICO_NS=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | grep -c 'Running' || echo "0")
  TIGERA_NS=$(kubectl get pods -n tigera-operator --no-headers 2>/dev/null | grep -c 'Running' || echo "0")
  if [ "$CALICO_NS" -ge 1 ] || [ "$TIGERA_NS" -ge 1 ]; then
    echo "[PASS] Calico CNI pods running"
  else
    echo "[FAIL] No CNI pods found running"
    PASS=false
  fi
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
