#!/usr/bin/env bash
# rke2-preflight.sh — RKE2 Node Pre-Flight Check
# Consolidated from: disk-usage, network-info, system-info, network-engineer, installation-guide-creator skills
# Usage: bash rke2-preflight.sh [--server|--agent] [--peer <node-ip>]
set -euo pipefail

MODE="${1:-}"
PEER="${2:-}"
PASS=0
FAIL=0
WARN=0

check() {
  local status="$1" msg="$2"
  case "$status" in
    PASS) echo "  ✓ $msg"; PASS=$((PASS+1)) ;;
    FAIL) echo "  ✗ $msg"; FAIL=$((FAIL+1)) ;;
    WARN) echo "  ⚠ $msg"; WARN=$((WARN+1)) ;;
  esac
}

header() {
  echo ""
  echo "─── [$1] $2 ───"
}

echo "╔══════════════════════════════════════╗"
echo "║     RKE2 NODE PRE-FLIGHT CHECK      ║"
echo "╚══════════════════════════════════════╝"
echo "Date: $(date)"
echo "Host: $(hostname)"
echo "Mode: ${MODE:-all}"

# ────────────────── [1/6] OS & HARDWARE ──────────────────
header "1/6" "OS & HARDWARE"

arch=$(uname -m 2>/dev/null || echo "unknown")
if [[ "$arch" == "x86_64" || "$arch" == "aarch64" ]]; then
  check PASS "Architecture: $arch"
else
  check FAIL "Architecture: $arch (need x86_64 or aarch64)"
fi

if [ -f /etc/os-release ]; then
  os_name=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || grep 'PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
  check PASS "OS: ${os_name:-unknown}"
else
  check WARN "OS: cannot read /etc/os-release"
fi

# Check for systemd (required by RKE2)
if command -v systemctl &>/dev/null; then
  check PASS "init: systemd detected"
else
  check FAIL "init: systemd NOT found (RKE2 requires systemd)"
fi

mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo 0)
mem_gb=$(awk "BEGIN {printf \"%.1f\", $mem_kb/1024/1024}")
if [ "$mem_kb" -ge 4194304 ]; then
  check PASS "RAM: ${mem_gb} GiB (>= 4GB)"
else
  check FAIL "RAM: ${mem_gb} GiB (< 4GB minimum)"
fi

cpu_cores=$(nproc 2>/dev/null || echo 0)
if [ "$cpu_cores" -ge 2 ]; then
  check PASS "CPU: ${cpu_cores} cores (>= 2)"
else
  check FAIL "CPU: ${cpu_cores} cores (< 2 minimum)"
fi

disk_target="/var/lib/rancher/rke2"
if [ -d "$disk_target" ]; then
  disk_avail=$(df -BM "$disk_target" 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'M' || echo 0)
else
  disk_avail=$(df -BM / 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'M' || echo 0)
fi
if [ "$disk_avail" -ge 10240 ]; then
  check PASS "Disk available: ${disk_avail}MB (>= 10GB)"
elif [ "$disk_avail" -ge 5120 ]; then
  check WARN "Disk available: ${disk_avail}MB (>= 5GB, recommend 10GB+)"
else
  check FAIL "Disk available: ${disk_avail}MB (< 5GB, need 10GB+)"
fi

# ────────────────── [2/6] KERNEL MODULES ──────────────────
header "2/6" "KERNEL MODULES"

for mod in overlay br_netfilter; do
  if lsmod | grep -q "^${mod}" 2>/dev/null; then
    check PASS "module: ${mod} loaded"
  else
    check FAIL "module: ${mod} NOT loaded (run: modprobe ${mod})"
  fi
done

# Check nf_conntrack (recommended for RKE2)
if lsmod | grep -q '^nf_conntrack' 2>/dev/null; then
  check PASS "module: nf_conntrack loaded"
else
  check WARN "module: nf_conntrack not loaded (recommended for RKE2)"
fi

# ────────────────── [3/6] SYSCTL ──────────────────
header "3/6" "SYSCTL"

sysctl_keys=(
  "net.ipv4.ip_forward:1"
  "net.bridge.bridge-nf-call-iptables:1"
  "net.bridge.bridge-nf-call-ip6tables:1"
  "net.ipv6.conf.all.forwarding:1"
)

for entry in "${sysctl_keys[@]}"; do
  key="${entry%%:*}"
  expected="${entry##*:}"
  val=$(sysctl -n "$key" 2>/dev/null || echo "unavailable")
  if [ "$val" = "$expected" ]; then
    check PASS "sysctl: ${key} = ${val}"
  elif [ "$val" = "unavailable" ]; then
    # bridge-nf-call-ip6tables may not exist if br_netfilter not loaded
    if [[ "$key" == *bridge* ]]; then
      check WARN "sysctl: ${key} unavailable (ensure br_netfilter is loaded)"
    else
      check WARN "sysctl: ${key} unavailable (kernel may not support it)"
    fi
  else
    if [[ "$key" == *ip6tables* || "$key" == *forwarding ]]; then
      check WARN "sysctl: ${key} = ${val} (expected ${expected}, recommended for dual-stack)"
    else
      check FAIL "sysctl: ${key} = ${val} (expected ${expected})"
    fi
  fi
done

# ────────────────── [4/6] PORT AVAILABILITY ──────────────────
header "4/6" "PORT AVAILABILITY"

declare -A port_map=(
  ["6443"]="Kubernetes API server"
  ["9345"]="RKE2 supervisor API"
  ["10250"]="kubelet metrics"
)

# In server mode, etcd ports are required
if [ "$MODE" = "--server" ]; then
  port_map["2379"]="etcd client (server node)"
  port_map["2380"]="etcd peer (server node)"
fi

occupied_ports=$(ss -tuln 2>/dev/null | grep -oP ':\K[0-9]+' | sort -u || true)

for port in "${!port_map[@]}"; do
  desc="${port_map[$port]}"
  if echo "$occupied_ports" | grep -q "^${port}$"; then
    proc_name=$(ss -tulnp 2>/dev/null | grep ":$port " | grep -oP 'users:\(\("?\K[^")]+' | head -1 || echo "")
    if [[ "$proc_name" == *rke2* || "$proc_name" == *kube* || "$proc_name" == *etcd* ]]; then
      check WARN "port ${port}/TCP (${desc}): in use by ${proc_name} (existing RKE2/K8s)"
    else
      if [ -n "$proc_name" ]; then
        check FAIL "port ${port}/TCP (${desc}): IN USE by ${proc_name}"
      else
        check FAIL "port ${port}/TCP (${desc}): IN USE (run as root to identify process)"
      fi
    fi
  else
    check PASS "port ${port}/TCP (${desc}): available"
  fi
done

# Check port 8472/UDP (Flannel VXLAN)
if echo "$occupied_ports" | grep -q "^8472$" 2>/dev/null; then
  check FAIL "port 8472/UDP (Flannel VXLAN): PORT ALREADY IN USE"
else
  check PASS "port 8472/UDP (Flannel VXLAN): available"
fi

# Check NodePort range (30000-32767) for existing conflicts
nodeport_conflicts=$(ss -tuln 2>/dev/null | grep -oP ':\K(3[0-9][0-9][0-9][0-9]|32[0-6][0-9][0-9]|327[0-6][0-7])' | sort -u || true)
conflict_count=$(echo "$nodeport_conflicts" | wc -l)
if [ "$conflict_count" -gt 0 ]; then
  nodeport_list=$(echo "$nodeport_conflicts" | tr '\n' ' ' | xargs)
  check WARN "NodePort range (30000-32767): ${conflict_count} port(s) already in use (${nodeport_list})"
else
  check PASS "NodePort range (30000-32767): no conflicts detected"
fi

# ────────────────── [5/6] SECURITY & NETWORK ──────────────────
header "5/6" "SECURITY & NETWORK"

# Swap check
swap_total=$(swapon --show 2>/dev/null | wc -l || echo 0)
fstab_swap=$(grep -cP '^\S+\s+\S+\s+swap\s+' /etc/fstab 2>/dev/null || echo 0)
if [ "$swap_total" -eq 0 ] && [ "$fstab_swap" -eq 0 ]; then
  check PASS "swap: disabled"
elif [ "$swap_total" -gt 0 ]; then
  check FAIL "swap: ACTIVE (run: swapoff -a, then remove from /etc/fstab)"
else
  check WARN "swap: disabled now but entry exists in /etc/fstab (will re-enable on reboot)"
fi

# SELinux / AppArmor
if command -v getenforce &>/dev/null; then
  selinux=$(getenforce 2>/dev/null || echo "unknown")
  if [ "$selinux" = "Enforcing" ]; then
    check WARN "SELinux: ${selinux} (RKE2 works, may need policy modules)"
  else
    check PASS "SELinux: ${selinux}"
  fi
elif command -v aa-status &>/dev/null; then
  check PASS "AppArmor: active"
else
  check PASS "SELinux/AppArmor: not present"
fi

# Firewall status
firewall_active=false
for fw in firewalld ufw; do
  if command -v systemctl &>/dev/null; then
    if systemctl is-active --quiet "$fw" 2>/dev/null; then
      check WARN "firewall: ${fw} is ACTIVE (ensure ports 6443,9345,8472,10250 are open)"
      firewall_active=true
    fi
  fi
done
if ! $firewall_active; then
  # Check iptables rules (raw check for restrictive policies)
  if command -v iptables &>/dev/null; then
    default_policy=$(iptables -L INPUT -n 2>/dev/null | head -1 | grep -oP 'policy \K\w+' || echo "")
    if [ "$default_policy" = "DROP" ] || [ "$default_policy" = "REJECT" ]; then
      check WARN "iptables: INPUT policy is ${default_policy} (ensure required ports are open)"
    else
      check PASS "iptables: INPUT policy ACCEPT (no active firewall detected)"
    fi
  else
    check PASS "firewall: no active firewall detected"
  fi
fi

# NetworkManager check
if command -v systemctl &>/dev/null; then
  if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    check WARN "NetworkManager: active (may need to ignore CNI interfaces)"
  else
    check PASS "NetworkManager: not active"
  fi
fi

# Hostname FQDN
fqdn=$(hostname -f 2>/dev/null || echo "unavailable")
if [ "$fqdn" != "unavailable" ] && [ -n "$fqdn" ]; then
  check PASS "hostname -f: ${fqdn}"
else
  check WARN "hostname -f: FQDN not resolvable (may cause node registration issues)"
fi

# Hostname uniqueness check (resolve hostname via DNS/ hosts)
my_hostname=$(hostname -s 2>/dev/null || echo "unknown")
if command -v getent &>/dev/null; then
  resolved_ips=$(getent hosts "$my_hostname" 2>/dev/null | awk '{print $1}' || echo "")
  if [ -n "$resolved_ips" ]; then
    my_ips=$(hostname -I 2>/dev/null || echo "")
    for ip in $resolved_ips; do
      # Skip localhost
      if [ "$ip" = "127.0.0.1" ] || [ "$ip" = "::1" ]; then
        continue
      fi
      if ! echo "$my_ips" | grep -q "$ip"; then
        check WARN "hostname uniqueness: ${my_hostname} resolves to ${ip} (not a local IP — possible duplicate)"
        break
      fi
    done
    check PASS "hostname uniqueness: ${my_hostname} resolves to local IP(s)"
  else
    check WARN "hostname uniqueness: ${my_hostname} does not resolve to any IP"
  fi
elif command -v dig &>/dev/null; then
  check WARN "hostname uniqueness: getent not available, cannot verify"
else
  check WARN "hostname uniqueness: getent not available, cannot verify"
fi

# DNS resolution
if command -v nslookup &>/dev/null; then
  dns_result=$(nslookup "$my_hostname" 2>/dev/null | grep -A1 'Name' | tail -1 || echo "")
  if [ -n "$dns_result" ]; then
    check PASS "DNS resolution: ${my_hostname} resolves"
  else
    check WARN "DNS resolution: ${my_hostname} does not resolve via DNS"
  fi
elif command -v dig &>/dev/null; then
  dns_result=$(dig +short "$my_hostname" 2>/dev/null || echo "")
  if [ -n "$dns_result" ]; then
    check PASS "DNS resolution: ${my_hostname} resolves to ${dns_result}"
  else
    check WARN "DNS resolution: ${my_hostname} does not resolve via DNS"
  fi
else
  check WARN "DNS resolution: dig/nslookup not available (install dnsutils/bind-utils)"
fi

# ────────────────── [6/6] CONNECTIVITY (optional) ──────────────────
header "6/6" "CONNECTIVITY (optional)"

# If a peer IP was provided, test connectivity
if [ -n "$PEER" ]; then
  if command -v ping &>/dev/null; then
    if ping -c 1 -W 2 "$PEER" &>/dev/null; then
      check PASS "ping to ${PEER}: reachable"
    else
      check WARN "ping to ${PEER}: unreachable (may be expected if ICMP blocked)"
    fi
  else
    check WARN "ping: command not available"
  fi
  if command -v nc &>/dev/null; then
    if nc -zv -w 3 "$PEER" 6443 &>/dev/null; then
      check WARN "connectivity to ${PEER}:6443 — port open (existing cluster?)"
    else
      check PASS "connectivity to ${PEER}:6443 — not reachable (expected for new cluster)"
    fi
  else
    check WARN "nc: command not available (install netcat for port connectivity tests)"
  fi
else
  check WARN "peer connectivity: skipped (pass --peer <node-ip> to test)"
fi

# ────────────────── SUMMARY ──────────────────
echo ""
echo "╔══════════════════════════════════════╗"
echo "║           CHECK SUMMARY              ║"
echo "╚══════════════════════════════════════╝"
echo "  PASS: $PASS    FAIL: $FAIL    WARN: $WARN"
total=$((PASS+FAIL+WARN))
if [ "$FAIL" -eq 0 ]; then
  echo "  STATUS: ✓ Ready for RKE2 installation"
else
  echo "  STATUS: ✗ ${FAIL} issue(s) must be fixed before RKE2 installation"
  echo ""
  echo "  Fix the FAIL items above, then re-run this script."
fi
echo ""
