#!/bin/bash
# Verify: Q16 — NodePort
PASS=true

echo "=== Q16: NodePort ==="

# Check deployment has containerPort 80
CONTAINER_PORT=$(kubectl get deployment nodeport-deployment -n relative \
  -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null)
if [ "$CONTAINER_PORT" = "80" ]; then
  echo "[PASS] Deployment has containerPort 80"
else
  echo "[FAIL] Deployment should have containerPort 80 (got: $CONTAINER_PORT)"
  PASS=false
fi

# Check service exists and is NodePort
SVC_TYPE=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$SVC_TYPE" = "NodePort" ]; then
  echo "[PASS] Service nodeport-service is NodePort"
else
  echo "[FAIL] Service should be NodePort (got: $SVC_TYPE)"
  PASS=false
fi

# Check NodePort is 30080
NODE_PORT=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$NODE_PORT" = "30080" ]; then
  echo "[PASS] NodePort is 30080"
else
  echo "[FAIL] NodePort should be 30080 (got: $NODE_PORT)"
  PASS=false
fi

# Check service port is 80
SVC_PORT=$(kubectl get svc nodeport-service -n relative -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
if [ "$SVC_PORT" = "80" ]; then
  echo "[PASS] Service port is 80"
else
  echo "[FAIL] Service port should be 80 (got: $SVC_PORT)"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
