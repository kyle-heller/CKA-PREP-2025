#!/bin/bash
# Verify: Q11 — Gateway API
PASS=true

echo "=== Q11: Gateway API ==="

# Check Gateway exists
if ! kubectl get gateway web-gateway &>/dev/null; then
  echo "[FAIL] Gateway web-gateway not found"
  PASS=false
else
  echo "[PASS] Gateway web-gateway exists"

  # Check hostname
  GW_HOST=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].hostname}' 2>/dev/null)
  if [ "$GW_HOST" = "gateway.web.k8s.local" ]; then
    echo "[PASS] Gateway hostname is gateway.web.k8s.local"
  else
    echo "[FAIL] Gateway hostname should be gateway.web.k8s.local (got: $GW_HOST)"
    PASS=false
  fi

  # Check TLS config
  GW_TLS_SECRET=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].tls.certificateRefs[0].name}' 2>/dev/null)
  if [ "$GW_TLS_SECRET" = "web-tls" ]; then
    echo "[PASS] Gateway TLS references web-tls secret"
  else
    echo "[FAIL] Gateway should reference web-tls secret (got: $GW_TLS_SECRET)"
    PASS=false
  fi

  # Check gatewayClassName
  GW_CLASS=$(kubectl get gateway web-gateway -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
  if [ "$GW_CLASS" = "nginx-class" ]; then
    echo "[PASS] Gateway uses gatewayClassName=nginx-class"
  else
    echo "[FAIL] Gateway should use nginx-class (got: $GW_CLASS)"
    PASS=false
  fi
fi

# Check HTTPRoute exists
if ! kubectl get httproute web-route &>/dev/null; then
  echo "[FAIL] HTTPRoute web-route not found"
  PASS=false
else
  echo "[PASS] HTTPRoute web-route exists"

  # Check parentRef
  PARENT=$(kubectl get httproute web-route -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
  if [ "$PARENT" = "web-gateway" ]; then
    echo "[PASS] HTTPRoute references web-gateway as parent"
  else
    echo "[FAIL] HTTPRoute should reference web-gateway (got: $PARENT)"
    PASS=false
  fi

  # Check backendRef
  BACKEND=$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)
  if [ "$BACKEND" = "web-service" ]; then
    echo "[PASS] HTTPRoute backend is web-service"
  else
    echo "[FAIL] HTTPRoute backend should be web-service (got: $BACKEND)"
    PASS=false
  fi
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
