#!/usr/bin/env bash
# step1_install_nginx.sh — Update and install Nginx
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

echo "--- Phase 1: Installation ---"

# Update apt
echo "Updating apt packages..."
sudo apt-get update -y &>/dev/null
check $? "Apt update completed"

# Install Nginx
echo "Installing Nginx..."
sudo apt-get install -y nginx &>/dev/null
check $? "Nginx installation"

# Verify installation
if command -v nginx &>/dev/null; then
    check 0 "Nginx binary found: $(nginx -v 2>&1)"
else
    check 1 "Nginx binary NOT found"
fi
