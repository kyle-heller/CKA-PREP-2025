#!/bin/bash
# setup-tools.sh — Install helm and metrics-server required by CKA questions
set -euo pipefail

echo "=== CKA-PREP-2025: Installing Required Tools ==="

# Install Helm (required for Q02)
if ! command -v helm &>/dev/null; then
  echo "[INFO] Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "[OK] Helm already installed: $(helm version --short 2>/dev/null)"
fi

# Install metrics-server (required for Q05 HPA)
echo "[INFO] Deploying metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>/dev/null || true

echo "[INFO] Patching metrics-server for insecure TLS (lab environment)..."
kubectl patch deployment metrics-server -n kube-system \
  --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null || true

echo "[INFO] Waiting for metrics-server..."
kubectl rollout status deployment metrics-server -n kube-system --timeout=120s || true

echo "=== Tool setup complete ==="
