#!/bin/bash
# Verify: Q09 — CRI-Dockerd
PASS=true

echo "=== Q09: CRI-Dockerd ==="

# Check sysctl values (these can be verified regardless of cri-dockerd install)
check_sysctl() {
  local key="$1"
  local expected="$2"
  local actual
  actual=$(sysctl -n "$key" 2>/dev/null || echo "MISSING")
  if [ "$actual" = "$expected" ]; then
    echo "[PASS] $key = $expected"
  else
    echo "[FAIL] $key should be $expected (got: $actual)"
    PASS=false
  fi
}

check_sysctl "net.bridge.bridge-nf-call-iptables" "1"
check_sysctl "net.ipv6.conf.all.forwarding" "1"
check_sysctl "net.ipv4.ip_forward" "1"
check_sysctl "net.netfilter.nf_conntrack_max" "131072"

# Check cri-docker service if available
if systemctl list-unit-files cri-docker.service &>/dev/null; then
  CRI_ENABLED=$(systemctl is-enabled cri-docker.service 2>/dev/null || echo "disabled")
  CRI_ACTIVE=$(systemctl is-active cri-docker.service 2>/dev/null || echo "inactive")
  if [ "$CRI_ENABLED" = "enabled" ]; then
    echo "[PASS] cri-docker.service is enabled"
  else
    echo "[FAIL] cri-docker.service should be enabled (got: $CRI_ENABLED)"
    PASS=false
  fi
  if [ "$CRI_ACTIVE" = "active" ]; then
    echo "[PASS] cri-docker.service is active"
  else
    echo "[FAIL] cri-docker.service should be active (got: $CRI_ACTIVE)"
    PASS=false
  fi
else
  echo "[INFO] cri-docker.service not found (dpkg may not work on this platform) — checking sysctl only"
fi

if $PASS; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== SOME CHECKS FAILED ==="
  exit 1
fi
