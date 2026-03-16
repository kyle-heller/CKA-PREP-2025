#!/bin/bash
# Verify: Q07 — PriorityClass
PASS=true

echo "=== Q07: PriorityClass ==="

# Check PriorityClass high-priority exists
if kubectl get priorityclass high-priority &>/dev/null; then
  echo "[PASS] PriorityClass high-priority exists"
else
  echo "[FAIL] PriorityClass high-priority not found"
  PASS=false
fi

# Check value is 999
PC_VALUE=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null)
if [ "$PC_VALUE" = "999" ]; then
  echo "[PASS] PriorityClass value is 999"
else
  echo "[FAIL] PriorityClass value should be 999 (got: $PC_VALUE)"
  PASS=false
fi

# Check deployment uses high-priority
PC_NAME=$(kubectl get deployment busybox-logger -n priority -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null)
if [ "$PC_NAME" = "high-priority" ]; then
  echo "[PASS] Deployment uses priorityClassName=high-priority"
else
  echo "[FAIL] Deployment should use priorityClassName=high-priority (got: $PC_NAME)"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
