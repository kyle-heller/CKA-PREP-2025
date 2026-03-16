#!/bin/bash
# Verify: Q05 — HPA
PASS=true

echo "=== Q05: HPA ==="

# Check HPA exists
if ! kubectl get hpa apache-server -n autoscale &>/dev/null; then
  echo "[FAIL] HPA apache-server not found in autoscale namespace"
  PASS=false
else
  echo "[PASS] HPA apache-server exists"

  # Check target deployment
  TARGET=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)
  if [ "$TARGET" = "apache-deployment" ]; then
    echo "[PASS] HPA targets apache-deployment"
  else
    echo "[FAIL] HPA should target apache-deployment (got: $TARGET)"
    PASS=false
  fi

  # Check CPU target 50%
  CPU_TARGET=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}' 2>/dev/null)
  if [ "$CPU_TARGET" = "50" ]; then
    echo "[PASS] CPU target is 50%"
  else
    echo "[FAIL] CPU target should be 50% (got: $CPU_TARGET)"
    PASS=false
  fi

  # Check min/max replicas
  MIN=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
  MAX=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
  if [ "$MIN" = "1" ] && [ "$MAX" = "4" ]; then
    echo "[PASS] Min replicas: 1, Max replicas: 4"
  else
    echo "[FAIL] Min should be 1 and max should be 4 (got: min=$MIN, max=$MAX)"
    PASS=false
  fi

  # Check scaleDown stabilization window
  STABILIZATION=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}' 2>/dev/null)
  if [ "$STABILIZATION" = "30" ]; then
    echo "[PASS] ScaleDown stabilization window is 30s"
  else
    echo "[FAIL] ScaleDown stabilization should be 30s (got: $STABILIZATION)"
    PASS=false
  fi
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
