#!/usr/bin/env bash
# final_validation.sh — Verify Web Access
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

echo "--- Final Validation ---"

# Check if port 80 is listening
if ss -tuln | grep -q ":80 "; then
    check 0 "Port 80 is listening"
else
    check 1 "Port 80 is NOT listening"
fi

# Check HTTP response
status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$status_code" -eq 200 ]; then
    check 0 "Localhost returned HTTP 200"
else
    check 1 "Localhost returned HTTP ${status_code} (Expected 200)"
fi
