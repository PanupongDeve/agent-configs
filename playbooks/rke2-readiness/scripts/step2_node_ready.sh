#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

export KUBECONFIG=${KUBECONFIG:-/etc/rancher/rke2/rke2.yaml}
export PATH=$PATH:/var/lib/rancher/rke2/bin:/usr/local/bin

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

echo "Waiting for node to be Ready (Timeout: 10m)..."

check_node_ready() {
    # Get local hostname and convert to lowercase to match K8s node name
    local NODE_NAME=$(hostname | tr '[:upper:]' '[:lower:]')
    kubectl get node "$NODE_NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"
}

# Wait loop
TIMEOUT=600
ELAPSED=0
INTERVAL=10

until check_node_ready || [ $ELAPSED -ge $TIMEOUT ]; do
    echo "Still waiting... (${ELAPSED}s/${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

# Use lowercase hostname for final check message
LOW_HOSTNAME=$(hostname | tr '[:upper:]' '[:lower:]')
check "Node $LOW_HOSTNAME is Ready" "check_node_ready"

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${RED}[ERROR]${NC} Timed out waiting for node to be Ready."
    exit 1
fi
