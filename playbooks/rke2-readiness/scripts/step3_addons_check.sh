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

# Only run if it's a server (check for /var/lib/rancher/rke2/server)
if [ ! -d "/var/lib/rancher/rke2/server" ]; then
    echo "This node is an agent, skipping server-specific add-on checks."
    exit 0
fi

echo "Checking RKE2 Static Pods and Add-ons..."

# Check Static Pods
check "Static Pod: etcd" "kubectl get pods -n kube-system -l component=etcd --field-selector status.phase=Running | grep -q etcd"
check "Static Pod: kube-apiserver" "kubectl get pods -n kube-system -l component=kube-apiserver --field-selector status.phase=Running | grep -q kube-apiserver"
check "Static Pod: kube-scheduler" "kubectl get pods -n kube-system -l component=kube-scheduler --field-selector status.phase=Running | grep -q kube-scheduler"
check "Static Pod: kube-controller-manager" "kubectl get pods -n kube-system -l component=kube-controller-manager --field-selector status.phase=Running | grep -q kube-controller-manager"

echo "Add-ons check complete."
