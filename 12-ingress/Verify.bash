#!/bin/bash
# Verify: Q12 — Ingress
PASS=true

echo "=== Q12: Ingress ==="

# Check service exists and is NodePort
SVC_TYPE=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$SVC_TYPE" = "NodePort" ]; then
  echo "[PASS] Service echo-service is NodePort"
else
  echo "[FAIL] Service echo-service should be NodePort (got: $SVC_TYPE)"
  PASS=false
fi

# Check service port is 8080
SVC_PORT=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
if [ "$SVC_PORT" = "8080" ]; then
  echo "[PASS] Service port is 8080"
else
  echo "[FAIL] Service port should be 8080 (got: $SVC_PORT)"
  PASS=false
fi

# Check Ingress exists
if ! kubectl get ingress echo -n echo-sound &>/dev/null; then
  echo "[FAIL] Ingress echo not found in echo-sound namespace"
  PASS=false
else
  echo "[PASS] Ingress echo exists"

  # Check host
  ING_HOST=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
  if [ "$ING_HOST" = "example.org" ]; then
    echo "[PASS] Ingress host is example.org"
  else
    echo "[FAIL] Ingress host should be example.org (got: $ING_HOST)"
    PASS=false
  fi

  # Check path
  ING_PATH=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
  if [ "$ING_PATH" = "/echo" ]; then
    echo "[PASS] Ingress path is /echo"
  else
    echo "[FAIL] Ingress path should be /echo (got: $ING_PATH)"
    PASS=false
  fi

  # Check backend service
  ING_SVC=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
  if [ "$ING_SVC" = "echo-service" ]; then
    echo "[PASS] Ingress backend is echo-service"
  else
    echo "[FAIL] Ingress backend should be echo-service (got: $ING_SVC)"
    PASS=false
  fi
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
