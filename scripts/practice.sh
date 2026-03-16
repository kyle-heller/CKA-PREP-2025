#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# CKA Practice Console — Interactive Lab + Verify Loop
# ═══════════════════════════════════════════════════════════════════
# Usage: ./practice.sh [--skip-setup] [--start N]
#   --skip-setup   Skip tool install and lab setup (resume session)
#   --start N      Start from question N (1-17)
# ═══════════════════════════════════════════════════════════════════

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Question metadata ──────────────────────────────────────
DIRS=(
  "01-mariadb-persistent-volume"
  "02-argocd-helm"
  "03-sidecar"
  "04-resource-allocation"
  "05-hpa"
  "06-crds-cert-manager"
  "07-priority-class"
  "08-cni-network-policy"
  "09-cri-dockerd"
  "10-taints-tolerations"
  "11-gateway-api"
  "12-ingress"
  "13-network-policy"
  "14-storage-class"
  "15-etcd-fix"
  "16-nodeport"
  "17-tls-config"
)

TITLES=(
  "MariaDB Persistent Volume"
  "ArgoCD Helm (No CRDs)"
  "Sidecar Container"
  "Resource Allocation"
  "HorizontalPodAutoscaler"
  "CRDs (cert-manager)"
  "PriorityClass"
  "CNI & Network Policy"
  "CRI-Dockerd"
  "Taints & Tolerations"
  "Gateway API Migration"
  "Ingress"
  "Network Policy (Least-Permissive)"
  "StorageClass"
  "Etcd Fix (API Server Broken)"
  "NodePort Service"
  "TLS Configuration"
)

DIFFICULTIES=(
  "Medium" "Easy" "Easy" "Medium" "Medium"
  "Easy" "Easy" "Easy" "Medium" "Easy"
  "Medium" "Easy" "Medium" "Easy" "Hard"
  "Easy" "Medium"
)

# ── Results tracking ────────────────────────────────────────
declare -A RESULTS       # "pass" | "fail" | "skip" | ""
declare -A ATTEMPTS      # attempt count per question
for i in "${!DIRS[@]}"; do
  RESULTS[$i]=""
  ATTEMPTS[$i]=0
done

# ── Parse args ──────────────────────────────────────────────
SKIP_SETUP=false
START_Q=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-setup) SKIP_SETUP=true; shift ;;
    --start) START_Q="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Helpers ─────────────────────────────────────────────────
hr() {
  printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..70})"
}

banner() {
  clear
  echo ""
  printf "${GREEN}${BOLD}"
  echo "  ╔═══════════════════════════════════════════════════════════╗"
  echo "  ║              CKA Practice Console v1.0                   ║"
  echo "  ║          17 Questions · Interactive · Validated          ║"
  echo "  ╚═══════════════════════════════════════════════════════════╝"
  printf "${RESET}\n"
}

difficulty_color() {
  case "$1" in
    Easy)   printf "${GREEN}$1${RESET}" ;;
    Medium) printf "${YELLOW}$1${RESET}" ;;
    Hard)   printf "${RED}$1${RESET}" ;;
  esac
}

wait_for_apiserver() {
  local max_wait=120
  local elapsed=0
  printf "${DIM}  Waiting for API server"
  while ! kubectl get nodes &>/dev/null; do
    sleep 2
    elapsed=$((elapsed + 2))
    printf "."
    if [ $elapsed -ge $max_wait ]; then
      printf "${RESET}\n"
      printf "${RED}  API server did not recover within ${max_wait}s${RESET}\n"
      return 1
    fi
  done
  printf " ready!${RESET}\n"
  return 0
}

# ── Setup Phase ─────────────────────────────────────────────
run_setup() {
  banner
  printf "${CYAN}${BOLD}  Phase 1: Environment Setup${RESET}\n\n"

  # Tools
  printf "${YELLOW}  [1/3] Installing tools (Helm, metrics-server)...${RESET}\n"
  if bash "$SCRIPT_DIR/setup-tools.sh" &>/dev/null; then
    printf "${GREEN}  ✓ Tools installed${RESET}\n"
  else
    printf "${YELLOW}  ⚠ Tool setup had warnings (may be pre-installed)${RESET}\n"
  fi

  # Lab setup — all except Q15
  printf "\n${YELLOW}  [2/3] Setting up labs Q01-Q14, Q16-Q17...${RESET}\n"
  for i in "${!DIRS[@]}"; do
    local num=$((i + 1))
    # Skip Q15 — run it last since it breaks API server
    [ $num -eq 15 ] && continue

    local dir="$BASE_DIR/${DIRS[$i]}"
    local setup="$dir/LabSetUp"
    if [ -x "$setup" ]; then
      printf "  ${DIM}Q%02d: %s...${RESET}" "$num" "${TITLES[$i]}"
      if bash "$setup" &>/dev/null; then
        printf "\r  ${GREEN}✓${RESET} Q%02d: %s\n" "$num" "${TITLES[$i]}"
      else
        printf "\r  ${YELLOW}⚠${RESET} Q%02d: %s (setup warning)\n" "$num" "${TITLES[$i]}"
      fi
    fi
  done

  # Q15 last — breaks API server
  printf "\n${YELLOW}  [3/3] Setting up Q15 (breaks API server intentionally)...${RESET}\n"
  local q15_setup="$BASE_DIR/15-etcd-fix/LabSetUp"
  if [ -x "$q15_setup" ]; then
    printf "  ${DIM}Q15: Etcd Fix...${RESET}"
    if bash "$q15_setup" &>/dev/null; then
      printf "\r  ${GREEN}✓${RESET} Q15: Etcd Fix (API server now broken — expected)\n"
    else
      printf "\r  ${YELLOW}⚠${RESET} Q15: Etcd Fix setup\n"
    fi
  fi

  echo ""
  hr
  printf "\n${RED}${BOLD}  ⚠  API server is now DOWN (Q15 broke it on purpose).${RESET}\n"
  printf "${BOLD}  You must fix it first before any other questions will work.${RESET}\n"
  printf "${DIM}  Starting you on Q15 — fix the etcd port, then we continue to Q1.${RESET}\n"
  hr
  echo ""
  read -rp "  Press Enter to start with Q15 (Etcd Fix)... "
}

# ── Show Question ───────────────────────────────────────────
show_question() {
  local idx=$1
  local num=$((idx + 1))
  local dir="$BASE_DIR/${DIRS[$idx]}"
  local qfile="$dir/Questions"

  banner
  printf "  ${BOLD}Question %d of 17${RESET}  " "$num"
  difficulty_color "${DIFFICULTIES[$idx]}"
  echo ""
  hr

  if [ -f "$qfile" ]; then
    echo ""
    # Print question text, strip comment markers
    while IFS= read -r line; do
      # Remove leading "# " if present
      line="${line#\# }"
      printf "  %s\n" "$line"
    done < "$qfile"
    echo ""
  else
    printf "\n  ${RED}Questions file not found: $qfile${RESET}\n\n"
  fi

  hr

  # Show attempt/result status
  local attempts="${ATTEMPTS[$idx]}"
  local result="${RESULTS[$idx]}"
  if [ -n "$result" ]; then
    case "$result" in
      pass) printf "  ${GREEN}Status: PASSED${RESET} (attempt $attempts)\n" ;;
      fail) printf "  ${RED}Status: FAILED${RESET} (attempt $attempts)\n" ;;
      skip) printf "  ${DIM}Status: SKIPPED${RESET}\n" ;;
    esac
  else
    printf "  ${DIM}Status: Not attempted${RESET}\n"
  fi
  echo ""
}

# ── Verify Question ─────────────────────────────────────────
verify_question() {
  local idx=$1
  local num=$((idx + 1))
  local dir="$BASE_DIR/${DIRS[$idx]}"
  local verify="$dir/Verify.bash"

  ATTEMPTS[$idx]=$(( ${ATTEMPTS[$idx]} + 1 ))

  echo ""
  printf "  ${CYAN}Running verification for Q%02d...${RESET}\n\n" "$num"
  hr

  if [ ! -x "$verify" ]; then
    printf "  ${RED}Verify script not found: $verify${RESET}\n"
    RESULTS[$idx]="fail"
    return 1
  fi

  # Run verify and capture output
  local output
  local exit_code=0
  output=$(bash "$verify" 2>&1) || exit_code=$?

  # Display output with indentation
  while IFS= read -r line; do
    if [[ "$line" == *"[PASS]"* ]]; then
      printf "  ${GREEN}%s${RESET}\n" "$line"
    elif [[ "$line" == *"[FAIL]"* ]]; then
      printf "  ${RED}%s${RESET}\n" "$line"
    elif [[ "$line" == *"ALL CHECKS PASSED"* ]]; then
      printf "  ${GREEN}${BOLD}%s${RESET}\n" "$line"
    elif [[ "$line" == *"SOME CHECKS FAILED"* ]]; then
      printf "  ${RED}${BOLD}%s${RESET}\n" "$line"
    else
      printf "  %s\n" "$line"
    fi
  done <<< "$output"

  hr
  echo ""

  if [ $exit_code -eq 0 ]; then
    printf "  ${GREEN}${BOLD}★ Q%02d PASSED!${RESET}\n\n" "$num"
    RESULTS[$idx]="pass"
    return 0
  else
    printf "  ${RED}${BOLD}✗ Q%02d FAILED${RESET} — review and try again\n\n" "$num"
    RESULTS[$idx]="fail"
    return 1
  fi
}

# ── Show Solution ───────────────────────────────────────────
show_solution() {
  local idx=$1
  local num=$((idx + 1))
  local dir="$BASE_DIR/${DIRS[$idx]}"
  local notes="$dir/SolutionNotes"

  echo ""
  printf "  ${YELLOW}${BOLD}═══ Solution for Q%02d: %s ═══${RESET}\n\n" "$num" "${TITLES[$idx]}"

  if [ -f "$notes" ]; then
    while IFS= read -r line; do
      # Colorize comments vs commands
      if [[ "$line" =~ ^# ]]; then
        printf "  ${DIM}%s${RESET}\n" "$line"
      elif [[ -n "$line" ]]; then
        printf "  ${GREEN}%s${RESET}\n" "$line"
      else
        echo ""
      fi
    done < "$notes"
  else
    printf "  ${RED}SolutionNotes not found${RESET}\n"
  fi

  echo ""
  hr
}

# ── Scoreboard ──────────────────────────────────────────────
show_scoreboard() {
  echo ""
  printf "  ${BOLD}${CYAN}═══ Scoreboard ═══${RESET}\n\n"

  local passed=0 failed=0 skipped=0 unattempted=0

  for i in "${!DIRS[@]}"; do
    local num=$((i + 1))
    local result="${RESULTS[$i]}"
    local status_icon

    case "$result" in
      pass)
        status_icon="${GREEN}✓ PASS${RESET}"
        passed=$((passed + 1))
        ;;
      fail)
        status_icon="${RED}✗ FAIL${RESET}"
        failed=$((failed + 1))
        ;;
      skip)
        status_icon="${DIM}– SKIP${RESET}"
        skipped=$((skipped + 1))
        ;;
      *)
        status_icon="${DIM}  ···${RESET}"
        unattempted=$((unattempted + 1))
        ;;
    esac

    printf "  Q%02d  %-40s  %b  %b\n" \
      "$num" "${TITLES[$i]}" \
      "$(difficulty_color "${DIFFICULTIES[$i]}")" \
      "$status_icon"
  done

  echo ""
  hr
  printf "  ${GREEN}Passed: $passed${RESET}  ${RED}Failed: $failed${RESET}  ${DIM}Skipped: $skipped  Remaining: $unattempted${RESET}\n"
  printf "  Score: ${BOLD}$passed / 17${RESET}  ($(( passed * 100 / 17 ))%%)\n"
  hr
  echo ""
}

# ── Question Menu ───────────────────────────────────────────
question_menu() {
  local idx=$1

  while true; do
    show_question "$idx"

    printf "  ${BOLD}Actions:${RESET}\n"
    printf "    ${CYAN}v${RESET} — Verify my solution\n"
    printf "    ${CYAN}s${RESET} — Show solution / hints\n"
    printf "    ${CYAN}n${RESET} — Next question\n"
    printf "    ${CYAN}p${RESET} — Previous question\n"
    printf "    ${CYAN}k${RESET} — Skip this question\n"
    printf "    ${CYAN}b${RESET} — Scoreboard\n"
    printf "    ${CYAN}g${RESET} — Go to question #\n"
    printf "    ${CYAN}q${RESET} — Quit\n"
    echo ""
    read -rp "  > " choice

    case "$choice" in
      v|V)
        verify_question "$idx"
        read -rp "  Press Enter to continue... "
        ;;
      s|S)
        show_solution "$idx"
        read -rp "  Press Enter to continue... "
        ;;
      n|N)
        if [ $idx -eq 14 ] && [ "${RESULTS[14]}" = "" ] || [ "${RESULTS[14]}" = "pass" ]; then
          # After Q15 (idx 14), go to Q1 (idx 0) — the natural starting point
          # once the API server is fixed
          if [ $idx -eq 14 ]; then
            return 0
          fi
        fi
        if [ $idx -lt 16 ]; then
          local next_idx=$((idx + 1))
          # Skip Q15 in normal sequence (already done first)
          [ $next_idx -eq 14 ] && next_idx=15
          return $next_idx
        else
          printf "\n  ${DIM}Already at the last question.${RESET}\n"
          read -rp "  Press Enter to continue... "
        fi
        ;;
      p|P)
        if [ $idx -gt 0 ]; then
          return $((idx - 1))
        else
          printf "\n  ${DIM}Already at the first question.${RESET}\n"
          read -rp "  Press Enter to continue... "
        fi
        ;;
      k|K)
        RESULTS[$idx]="skip"
        if [ $idx -lt 16 ]; then
          return $((idx + 1))
        fi
        ;;
      b|B)
        show_scoreboard
        read -rp "  Press Enter to continue... "
        ;;
      g|G)
        read -rp "  Go to question # (1-17): " goto_num
        if [[ "$goto_num" =~ ^[0-9]+$ ]] && [ "$goto_num" -ge 1 ] && [ "$goto_num" -le 17 ]; then
          return $((goto_num - 1))
        else
          printf "  ${RED}Invalid question number${RESET}\n"
          read -rp "  Press Enter to continue... "
        fi
        ;;
      q|Q)
        return 99
        ;;
      *)
        printf "  ${RED}Unknown option: $choice${RESET}\n"
        sleep 0.5
        ;;
    esac
  done
}

# ── Main Loop ───────────────────────────────────────────────
main() {
  # Setup phase
  if ! $SKIP_SETUP; then
    run_setup
  else
    banner
    printf "  ${YELLOW}Skipping setup (--skip-setup).${RESET}\n"
    printf "  ${DIM}Assuming labs are already configured.${RESET}\n\n"
    read -rp "  Press Enter to begin... "
  fi

  # After setup, start on Q15 (etcd fix) since API server is broken
  # User must fix it before anything else works
  local current_idx
  if ! $SKIP_SETUP; then
    current_idx=14  # index 14 = Q15
  else
    current_idx=$((START_Q - 1))
    if [ $current_idx -lt 0 ]; then current_idx=0; fi
    if [ $current_idx -gt 16 ]; then current_idx=16; fi
  fi

  while true; do
    question_menu "$current_idx"
    local next=$?
    if [ $next -eq 99 ]; then
      break
    fi
    current_idx=$next
  done

  # Exit — show final scoreboard
  banner
  printf "  ${BOLD}Session Complete${RESET}\n"
  show_scoreboard

  printf "  ${DIM}Tip: Run with --skip-setup to resume without re-setting up labs.${RESET}\n"
  printf "  ${DIM}     Run with --start N to jump to a specific question.${RESET}\n\n"
}

main
