#!/bin/bash
# Verify: Q13 — Network Policy
PASS=true

echo "=== Q13: Network Policy ==="

# Check NetworkPolicy policy-z exists in backend namespace
if ! kubectl get networkpolicy policy-z -n backend &>/dev/null; then
  echo "[FAIL] NetworkPolicy policy-z not found in backend namespace"
  PASS=false
else
  echo "[PASS] NetworkPolicy policy-z exists in backend namespace"

  # Check podSelector targets app=backend
  POD_SEL=$(kubectl get networkpolicy policy-z -n backend -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)
  if [ "$POD_SEL" = "backend" ]; then
    echo "[PASS] podSelector matches app=backend"
  else
    echo "[FAIL] podSelector should match app=backend (got: $POD_SEL)"
    PASS=false
  fi

  # Check ingress from has namespaceSelector
  NS_SEL=$(kubectl get networkpolicy policy-z -n backend -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.name}' 2>/dev/null)
  if [ "$NS_SEL" = "frontend" ]; then
    echo "[PASS] ingress namespaceSelector matches name=frontend"
  else
    echo "[FAIL] ingress namespaceSelector should match name=frontend (got: $NS_SEL)"
    PASS=false
  fi

  # Check ingress from has podSelector
  POD_FROM=$(kubectl get networkpolicy policy-z -n backend -o jsonpath='{.spec.ingress[0].from[1].podSelector.matchLabels.app}' 2>/dev/null)
  if [ "$POD_FROM" = "frontend" ]; then
    echo "[PASS] ingress podSelector matches app=frontend"
  else
    echo "[FAIL] ingress podSelector should match app=frontend (got: $POD_FROM)"
    PASS=false
  fi
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
