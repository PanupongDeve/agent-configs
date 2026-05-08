#!/usr/bin/env bash
# audit_env.sh — Verify Ubuntu and RAM
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check() {
    if [ "$1" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $2 [PASS]"
    else
        echo -e "  ${RED}✗${NC} $2 [FAIL]"
        exit 1
    fi
}

echo "--- Infrastructure Audit ---"

# Check OS
if grep -qi "ubuntu" /etc/os-release; then
    check 0 "OS is Ubuntu"
else
    check 1 "OS is NOT Ubuntu"
fi

# Check RAM (Min 2GB ~ 2000000 KB)
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$mem_total" -ge 1900000 ]; then
    check 0 "RAM is >= 2GB (${mem_total} KB)"
else
    check 1 "RAM is < 2GB (${mem_total} KB)"
fi
