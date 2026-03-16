#!/bin/bash
# Verify: Q14 — StorageClass
PASS=true

echo "=== Q14: StorageClass ==="

# Check SC local-storage exists
if ! kubectl get storageclass local-storage &>/dev/null; then
  echo "[FAIL] StorageClass local-storage not found"
  PASS=false
else
  echo "[PASS] StorageClass local-storage exists"

  # Check provisioner
  PROV=$(kubectl get storageclass local-storage -o jsonpath='{.provisioner}' 2>/dev/null)
  if [ "$PROV" = "rancher.io/local-path" ]; then
    echo "[PASS] Provisioner is rancher.io/local-path"
  else
    echo "[FAIL] Provisioner should be rancher.io/local-path (got: $PROV)"
    PASS=false
  fi

  # Check volumeBindingMode
  BIND=$(kubectl get storageclass local-storage -o jsonpath='{.volumeBindingMode}' 2>/dev/null)
  if [ "$BIND" = "WaitForFirstConsumer" ]; then
    echo "[PASS] VolumeBindingMode is WaitForFirstConsumer"
  else
    echo "[FAIL] VolumeBindingMode should be WaitForFirstConsumer (got: $BIND)"
    PASS=false
  fi

  # Check is-default-class annotation
  IS_DEFAULT=$(kubectl get storageclass local-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null)
  if [ "$IS_DEFAULT" = "true" ]; then
    echo "[PASS] local-storage is marked as default"
  else
    echo "[FAIL] local-storage should be default (got: $IS_DEFAULT)"
    PASS=false
  fi
fi

# Check no other SC is default
OTHER_DEFAULTS=$(kubectl get storageclass -o json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
count = 0
for sc in data.get('items', []):
    name = sc['metadata']['name']
    ann = sc['metadata'].get('annotations', {})
    if name != 'local-storage' and ann.get('storageclass.kubernetes.io/is-default-class') == 'true':
        count += 1
print(count)
" 2>/dev/null || echo "0")

if [ "$OTHER_DEFAULTS" = "0" ]; then
  echo "[PASS] No other StorageClass is marked as default"
else
  echo "[FAIL] $OTHER_DEFAULTS other StorageClass(es) still marked as default"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
