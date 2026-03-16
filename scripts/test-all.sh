#!/bin/bash
# test-all.sh — Run LabSetUp + Verify for all 17 CKA questions
# Tests that labs set up correctly and verify scripts can detect pass/fail
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0
ERROR_COUNT=0
RESULTS=()

API_SERVER_QUESTION="15-etcd-fix"

wait_for_apiserver() {
  echo "[INFO] Waiting for API server to become available..."
  local max_wait=120
  local elapsed=0
  while ! kubectl get nodes &>/dev/null; do
    sleep 5
    elapsed=$((elapsed + 5))
    if [ $elapsed -ge $max_wait ]; then
      echo "[ERROR] API server did not come back after ${max_wait}s"
      return 1
    fi
    echo "[INFO] Still waiting... (${elapsed}s)"
  done
  echo "[INFO] API server is up after ${elapsed}s"
}

ALL_DIRS=(
  01-mariadb-persistent-volume
  02-argocd-helm
  03-sidecar
  04-resource-allocation
  05-hpa
  06-crds-cert-manager
  07-priority-class
  08-cni-network-policy
  09-cri-dockerd
  10-taints-tolerations
  11-gateway-api
  12-ingress
  13-network-policy
  14-storage-class
  15-etcd-fix
  16-nodeport
  17-tls-config
)

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   CKA-PREP-2025: Test All Questions      ║"
echo "╚══════════════════════════════════════════╝"

# ─── Phase 1: Run all LabSetUp scripts ─────────────────────────────────────

echo ""
echo "=== Phase 1: Lab Setup ==="

# Non-API-server questions first
for dir in "${ALL_DIRS[@]}"; do
  if [ "$dir" = "$API_SERVER_QUESTION" ]; then
    continue
  fi
  full_path="$SCRIPT_DIR/$dir"
  if [ -f "$full_path/LabSetUp" ]; then
    echo ""
    echo "--- Setup: $dir ---"
    bash "$full_path/LabSetUp" || echo "[WARN] Setup had errors: $dir"
  fi
done

# Q15 LAST (breaks API server)
echo ""
echo "--- Setup: $API_SERVER_QUESTION (breaks API server) ---"
bash "$SCRIPT_DIR/$API_SERVER_QUESTION/LabSetUp" || echo "[WARN] Setup had errors"

# ─── Phase 2: Run all Verify scripts ──────────────────────────────────────

echo ""
echo "=== Phase 2: Verify ==="

for dir in "${ALL_DIRS[@]}"; do
  full_path="$SCRIPT_DIR/$dir"
  name="$(basename "$dir")"

  # Q15 needs API server fix first
  if [ "$dir" = "$API_SERVER_QUESTION" ]; then
    echo ""
    echo "--- Skipping verify for $name (API server intentionally broken by setup) ---"
    echo "    Run solve-and-verify.sh to see full solve+verify cycle"
    RESULTS+=("SKIP: $name (API server question)")
    continue
  fi

  if [ -f "$full_path/Verify.bash" ]; then
    echo ""
    echo "--- Verify: $name ---"
    if bash "$full_path/Verify.bash"; then
      RESULTS+=("PASS: $name")
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      RESULTS+=("FAIL: $name")
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    echo "[WARN] No Verify.bash for $name"
    RESULTS+=("ERROR: $name (no Verify.bash)")
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

# ─── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            TEST RESULTS                  ║"
echo "╚══════════════════════════════════════════╝"
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""
echo "  PASSED: $PASS_COUNT"
echo "  FAILED: $FAIL_COUNT"
echo "  ERRORS: $ERROR_COUNT"
echo "  SKIPPED: 1 (Q15 etcd-fix)"

if [ $ERROR_COUNT -eq 0 ]; then
  echo ""
  echo "=== TEST RUN COMPLETE ==="
else
  echo ""
  echo "=== SOME TESTS HAD ERRORS ==="
fi
