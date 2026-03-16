#!/bin/bash
# Verify: Q02 — ArgoCD Helm
PASS=true

echo "=== Q02: ArgoCD Helm ==="

# Check file exists and is non-empty
if [ -s /root/argo-helm.yaml ]; then
  echo "[PASS] /root/argo-helm.yaml exists and is non-empty"
else
  echo "[FAIL] /root/argo-helm.yaml missing or empty"
  PASS=false
fi

# Check file contains argocd resources
if grep -qi 'argocd' /root/argo-helm.yaml 2>/dev/null; then
  echo "[PASS] File contains argocd resources"
else
  echo "[FAIL] File does not contain argocd resources"
  PASS=false
fi

# Check file does NOT contain CRD definitions
if grep -q 'kind: CustomResourceDefinition' /root/argo-helm.yaml 2>/dev/null; then
  echo "[FAIL] File contains CRD definitions (should be excluded)"
  PASS=false
else
  echo "[PASS] File does not contain CRD definitions"
fi

# Check namespace argocd exists
if kubectl get ns argocd &>/dev/null; then
  echo "[PASS] Namespace argocd exists"
else
  echo "[FAIL] Namespace argocd does not exist"
  PASS=false
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
