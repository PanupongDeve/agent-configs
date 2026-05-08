#!/usr/bin/env bash
# step2_enable_nginx.sh — Enable and Start Nginx
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

echo "--- Phase 2: Configuration & Service ---"

# Enable Nginx
echo "Enabling Nginx service..."
sudo systemctl enable nginx &>/dev/null
check $? "Nginx enabled on boot"

# Start Nginx
echo "Starting Nginx service..."
sudo systemctl start nginx &>/dev/null
check $? "Nginx service started"

# Check status
if systemctl is-active nginx &>/dev/null; then
    check 0 "Nginx service is active"
else
    check 1 "Nginx service is NOT active"
fi
