#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===================================================="
echo " RKE2 READINESS FINAL VALIDATION"
echo "===================================================="

FAILED=0

run_script() {
    local script_name=$1
    echo "--- Running $script_name ---"
    if ! bash "$SCRIPT_DIR/$script_name"; then
        FAILED=1
    fi
    echo ""
}

run_script "audit_env.sh"
run_script "step1_service_check.sh"
run_script "step2_node_ready.sh"
run_script "step3_addons_check.sh"

echo "===================================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}RESULT: PASS${NC}"
    echo "RKE2 node is ready for use."
else
    echo -e "${RED}RESULT: FAIL${NC}"
    echo "Please check the logs above for specific failures."
    exit 1
fi
echo "===================================================="
