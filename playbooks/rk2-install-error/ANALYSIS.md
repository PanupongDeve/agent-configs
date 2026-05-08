# Playbook Analysis Report

## Summary

- **Playbook:** RKE2 Installation
- **Total Steps:** 5
- **Passed:** 0
- **Failed:** 1 (Step 1/5)
- **Skipped:** 1 (Step 2/5)
- **Status:** ❌ Failed

## Issues Found

### Issue 1: Port 6443 Already in Use

- **Problem:** Step 1/5 (Check prerequisites) failed because Port 6443 is already in use
- **Category:** network (port conflict)
- **Cause:** Port 6443 is the default port for RKE2 kube-apiserver. Another process (possibly another Kubernetes cluster, k3s, or existing RKE2 installation) is already占用 this port.
- **Solution:**
  1. Check what process is using port 6443:
     ```bash
     sudo ss -tlnp | grep 6443
     # or
     sudo lsof -i :6443
     ```
  2. If it's another Kubernetes cluster (k3s, microk8s, etc.):
     - Stop the conflicting service: `sudo systemctl stop <service-name>`
     - Disable it if needed: `sudo systemctl disable <service-name>`
  3. If it's a stale RKE2 process:
     - Check for remaining RKE2 processes: `ps aux | grep rke2`
     - Kill them: `sudo kill <PID>`
  4. After clearing the port, re-run the installation playbook

## Recommendations

- Add pre-flight check to detect existing Kubernetes installations before starting
- Consider adding a step to automatically stop conflicting services (k3s, microk8s, old RKE2)
- Document that Port 6443 must be available for RKE2 installation to succeed