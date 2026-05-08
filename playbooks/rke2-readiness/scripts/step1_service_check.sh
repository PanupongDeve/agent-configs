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

echo "Checking RKE2 Services..."

SERVICE_NAME=""
if systemctl list-unit-files | grep "^rke2-server.service"; then
    SERVICE_NAME="rke2-server"
elif systemctl list-unit-files | grep "^rke2-agent.service"; then
    SERVICE_NAME="rke2-agent"
fi

if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}[FAIL]${NC} Neither rke2-server nor rke2-agent service found."
    exit 1
fi

check "Service $SERVICE_NAME is enabled" "systemctl is-enabled $SERVICE_NAME >/dev/null 2>&1"
check "Service $SERVICE_NAME is active" "systemctl is-active $SERVICE_NAME >/dev/null 2>&1"

echo "Service checks complete."
