#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

check() {
    local label=$1
    local condition=$2
    if eval "$condition"; then
        echo -e "${GREEN}[PASS]${NC} $label"
    else
        echo -e "${RED}[FAIL]${NC} $label"
        return 1
    fi
}

echo "Starting Environment Audit..."

# CPU Check (Min 2 Cores)
check "CPU: at least 2 cores" "[ $(nproc) -ge 2 ]"

# RAM Check (Min 4GB)
# Using total memory in KB from /proc/meminfo
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
check "RAM: at least 4GB" "[ $TOTAL_MEM -ge 3900000 ]"

# Disk Check (Min 20GB on /var/lib/rancher)
# If directory doesn't exist yet, check /var/lib or /
CHECK_DIR="/var/lib/rancher"
if [ ! -d "$CHECK_DIR" ]; then
    CHECK_DIR="/var/lib"
fi
FREE_DISK=$(df -k "$CHECK_DIR" | tail -1 | awk '{print $4}')
check "Disk: at least 20GB free on $CHECK_DIR" "[ $FREE_DISK -ge 20000000 ]"

echo "Environment Audit Complete."
