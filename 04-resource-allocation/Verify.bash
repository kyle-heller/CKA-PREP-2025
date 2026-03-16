#!/bin/bash
# Verify: Q04 — Resource Allocation
PASS=true

echo "=== Q04: Resource Allocation ==="

# Check 3 replicas
REPLICAS=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" = "3" ]; then
  echo "[PASS] Deployment has 3 replicas"
else
  echo "[FAIL] Deployment should have 3 replicas (got: $REPLICAS)"
  PASS=false
fi

# Check main container has resource requests
MAIN_CPU_REQ=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
MAIN_MEM_REQ=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
MAIN_CPU_LIM=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
MAIN_MEM_LIM=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)

if [ -n "$MAIN_CPU_REQ" ] && [ -n "$MAIN_MEM_REQ" ]; then
  echo "[PASS] Main container has resource requests (cpu: $MAIN_CPU_REQ, memory: $MAIN_MEM_REQ)"
else
  echo "[FAIL] Main container missing resource requests"
  PASS=false
fi

if [ -n "$MAIN_CPU_LIM" ] && [ -n "$MAIN_MEM_LIM" ]; then
  echo "[PASS] Main container has resource limits (cpu: $MAIN_CPU_LIM, memory: $MAIN_MEM_LIM)"
else
  echo "[FAIL] Main container missing resource limits"
  PASS=false
fi

# Check init container has resource requests
INIT_CPU_REQ=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}' 2>/dev/null)
INIT_MEM_REQ=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.memory}' 2>/dev/null)
INIT_CPU_LIM=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.cpu}' 2>/dev/null)
INIT_MEM_LIM=$(kubectl get deployment wordpress -n resources -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.memory}' 2>/dev/null)

if [ -n "$INIT_CPU_REQ" ] && [ -n "$INIT_MEM_REQ" ]; then
  echo "[PASS] Init container has resource requests (cpu: $INIT_CPU_REQ, memory: $INIT_MEM_REQ)"
else
  echo "[FAIL] Init container missing resource requests"
  PASS=false
fi

if [ -n "$INIT_CPU_LIM" ] && [ -n "$INIT_MEM_LIM" ]; then
  echo "[PASS] Init container has resource limits (cpu: $INIT_CPU_LIM, memory: $INIT_MEM_LIM)"
else
  echo "[FAIL] Init container missing resource limits"
  PASS=false
fi

# Check init and main have matching resources
if [ "$MAIN_CPU_REQ" = "$INIT_CPU_REQ" ] && [ "$MAIN_MEM_REQ" = "$INIT_MEM_REQ" ] && \
   [ "$MAIN_CPU_LIM" = "$INIT_CPU_LIM" ] && [ "$MAIN_MEM_LIM" = "$INIT_MEM_LIM" ]; then
  echo "[PASS] Init and main containers have matching resource values"
else
  echo "[FAIL] Init and main containers should have identical resources"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
