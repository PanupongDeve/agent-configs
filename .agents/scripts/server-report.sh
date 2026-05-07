#!/usr/bin/env bash
# server-report.sh — Linux Server Health Report
# Consolidated from: disk-usage, network-info, system-info skills
# Usage: bash server-report.sh
set -euo pipefail

SEP="========================================"

echo "$SEP"
echo "     LINUX SERVER HEALTH REPORT"
echo "$SEP"
echo "Date : $(date)"
echo "Host : $(hostname)"
echo "User : $(whoami)"
echo ""

# ────────────────── DISK USAGE ──────────────────
echo "$SEP"
echo "  1. DISK USAGE"
echo "$SEP"

echo ""
echo "--- Filesystem Usage ---"
df -h 2>/dev/null || echo "[WARN] df not available"

echo ""
echo "--- Inode Usage ---"
df -i 2>/dev/null || echo "[WARN] df -i not available"

echo ""
echo "--- Block Devices ---"
lsblk 2>/dev/null || echo "[WARN] lsblk not available"

echo ""
echo "--- Mounted Filesystems ---"
mount 2>/dev/null | head -30 || true

# ────────────────── NETWORK INFO ──────────────────
echo ""
echo "$SEP"
echo "  2. NETWORK INFO"
echo "$SEP"

echo ""
echo "--- Interfaces & IPs ---"
ip addr 2>/dev/null || echo "[WARN] ip not available (try ifconfig)"

echo ""
echo "--- Routing Table ---"
ip route 2>/dev/null || echo "[WARN] ip route not available"

echo ""
echo "--- Listening Ports ---"
ss -tuln 2>/dev/null || echo "[WARN] ss not available (try netstat -tuln)"

echo ""
echo "--- DNS Configuration ---"
cat /etc/resolv.conf 2>/dev/null || echo "[WARN] cannot read /etc/resolv.conf"

# ────────────────── SYSTEM INFO ──────────────────
echo ""
echo "$SEP"
echo "  3. SYSTEM INFO"
echo "$SEP"

echo ""
echo "--- OS Release ---"
cat /etc/os-release 2>/dev/null || echo "[WARN] cannot read /etc/os-release"

echo ""
echo "--- Kernel ---"
uname -a 2>/dev/null || echo "[WARN] uname not available"

echo ""
echo "--- CPU ---"
lscpu 2>/dev/null || echo "[WARN] lscpu not available"
if command -v nproc &>/dev/null; then
  echo "  CPUs (nproc): $(nproc)"
fi

echo ""
echo "--- Memory ---"
free -h 2>/dev/null || echo "[WARN] free not available"

echo ""
echo "--- Uptime & Load ---"
uptime 2>/dev/null || echo "[WARN] uptime not available"

echo ""
echo "$SEP"
echo "  REPORT COMPLETE"
echo "$SEP"
