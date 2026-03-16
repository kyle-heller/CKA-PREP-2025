#!/bin/bash
# Verify: Q06 — CRDs (cert-manager)
PASS=true

echo "=== Q06: CRDs (cert-manager) ==="

# Check /root/resources.yaml exists and has cert-manager entries
if [ -s /root/resources.yaml ]; then
  echo "[PASS] /root/resources.yaml exists and is non-empty"
  if grep -q 'cert-manager' /root/resources.yaml 2>/dev/null; then
    echo "[PASS] File contains cert-manager entries"
  else
    echo "[FAIL] File does not contain cert-manager entries"
    PASS=false
  fi
else
  echo "[FAIL] /root/resources.yaml missing or empty"
  PASS=false
fi

# Check /root/subject.yaml exists and is non-empty
if [ -s /root/subject.yaml ]; then
  echo "[PASS] /root/subject.yaml exists and is non-empty"
else
  echo "[FAIL] /root/subject.yaml missing or empty"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
