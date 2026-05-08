# Playbook: Install and Verify Nginx

## 1. Overview
- **Objective**: Install Nginx web server and ensure it is running and accessible.
- **Environment**:
    - OS: Ubuntu
    - Min Specs: 2GB RAM
    - Stack: Nginx

## 2. Infrastructure Audit
Before proceeding, verify the environment matches requirements.
- [ ] Run `scripts/audit_env.sh`
- **Expected Outcome**: OS is Ubuntu and RAM is >= 2GB.

## 3. Execution Plan

### Phase 1: Installation
- **Description**: Update system packages and install the Nginx package.
- **Action**:
    - [ ] Run `scripts/step1_install_nginx.sh`
- **Verification**: `nginx -v` should return the version.
- **Expected Outcome**: Nginx is installed on the system.

### Phase 2: Configuration & Service
- **Description**: Enable Nginx to start on boot and ensure the service is active.
- **Action**:
    - [ ] Run `scripts/step2_enable_nginx.sh`
- **Verification**: `systemctl is-active nginx` should return `active`.
- **Expected Outcome**: Nginx service is running and enabled.

## 4. Final Validation
Verify the web server is actually serving content.
- [ ] Run `scripts/final_validation.sh`
- **Expected Outcome**: Localhost returns HTTP 200 OK.

## 5. Variables & Configuration
| Variable | Default Value | Description |
|----------|---------------|-------------|
| PORT     | 80            | Nginx default listening port |

## 6. Troubleshooting
| Symptom | Possible Cause | Fix |
|---------|----------------|-----|
| Install fails | Network issue or apt lock | Check connection; run `sudo fuser -vki /var/lib/dpkg/lock-frontend` |
| Service won't start | Port 80 occupied | Check `ss -tuln | grep :80` |
