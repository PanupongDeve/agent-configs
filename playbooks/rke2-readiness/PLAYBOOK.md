# RKE2 Readiness Playbook

This playbook provides a systematic way to verify if an RKE2 node (Server or Agent) is ready after installation.

## Prerequisites

- RKE2 must be installed and the service should be enabled.
- Root or sudo access to run checks and access `/etc/rancher/rke2/rke2.yaml`.

## Steps

### 1. Environment Audit
Checks if the system meets the minimum requirements for RKE2 (CPU, RAM, Disk).
- **Script:** `scripts/audit_env.sh`

### 2. Service Check
Verifies if `rke2-server` or `rke2-agent` systemd service is active and running.
- **Script:** `scripts/step1_service_check.sh`

### 3. Node Readiness
Waits up to 10 minutes for the node to report a `Ready` status to the Kubernetes API.
- **Script:** `scripts/step2_node_ready.sh`

### 4. Add-ons & Pods Check (Server Only)
Checks if static pods (etcd, kube-apiserver, etc.) are running and if HelmCharts are deployed.
- **Script:** `scripts/step3_addons_check.sh`

### 5. Final Validation
A wrapper script that executes all the above checks and provides a summary.
- **Script:** `scripts/final_validation.sh`

## Usage

To run the full validation:
```bash
sudo ./scripts/final_validation.sh
```
