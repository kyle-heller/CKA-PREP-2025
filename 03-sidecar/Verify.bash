#!/bin/bash
# Verify: Q03 — Sidecar Container
PASS=true

echo "=== Q03: Sidecar Container ==="

# Check deployment has 2 containers
CONTAINER_COUNT=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers}' 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
if [ "$CONTAINER_COUNT" = "2" ]; then
  echo "[PASS] Deployment has 2 containers"
else
  echo "[FAIL] Deployment should have 2 containers (got: $CONTAINER_COUNT)"
  PASS=false
fi

# Check sidecar container name
SIDECAR_NAME=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].name}' 2>/dev/null)
if [ "$SIDECAR_NAME" = "sidecar" ]; then
  echo "[PASS] Sidecar container named 'sidecar'"
else
  echo "[FAIL] No container named 'sidecar' found"
  PASS=false
fi

# Check sidecar image
SIDECAR_IMAGE=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}' 2>/dev/null)
if [ "$SIDECAR_IMAGE" = "busybox:stable" ]; then
  echo "[PASS] Sidecar uses busybox:stable image"
else
  echo "[FAIL] Sidecar image should be busybox:stable (got: $SIDECAR_IMAGE)"
  PASS=false
fi

# Check emptyDir volume exists
VOLUME_TYPE=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.volumes[?(@.emptyDir)].name}' 2>/dev/null)
if [ -n "$VOLUME_TYPE" ]; then
  echo "[PASS] emptyDir volume exists (name: $VOLUME_TYPE)"
else
  echo "[FAIL] No emptyDir volume found"
  PASS=false
fi

# Check sidecar mounts /var/log
SIDECAR_MOUNT=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[0].mountPath}' 2>/dev/null)
if [ "$SIDECAR_MOUNT" = "/var/log" ]; then
  echo "[PASS] Sidecar mounts volume at /var/log"
else
  echo "[FAIL] Sidecar should mount at /var/log (got: $SIDECAR_MOUNT)"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
