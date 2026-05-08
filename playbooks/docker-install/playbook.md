# Playbook: Docker Installation

## 1. Overview
- **Objective**: Install Docker Engine and enable the Docker service
- **Environment**:
    - OS: Ubuntu/Debian-based Linux
    - Min Specs: 1 CPU, 512MB RAM, 5GB Disk
    - Stack: Docker Engine (docker.io package)

## 2. Infrastructure Audit
Before proceeding, verify the environment matches requirements.
- [ ] Run `scripts/audit_env.sh`
- **Expected Outcome**: All checks return `[PASS]`.

## 3. Execution Plan

### Phase 1: Update Package Repository
- **Description**: Refresh apt package lists to ensure latest package metadata
- **Action**:
    - [ ] Run `scripts/01_apt_update.sh`
- **Verification**: Script output shows repository sync completed
- **Expected Outcome**: Package lists are up to date

### Phase 2: Install Docker
- **Description**: Install Docker Engine from distribution packages
- **Action**:
    - [ ] Run `scripts/02_install_docker.sh`
- **Verification**: Script confirms docker.io package installed
- **Expected Outcome**: Docker binaries are present at `/usr/bin/docker`

### Phase 3: Enable Docker Service
- **Description**: Enable Docker to start on system boot
- **Action**:
    - [ ] Run `scripts/03_enable_docker.sh`
- **Verification**: Script confirms docker service is enabled
- **Expected Outcome**: `systemctl is-enabled docker` returns `enabled`

## 4. Final Validation
Verify the entire system is functional.
- [ ] Run `scripts/final_validation.sh`
- **Expected Outcome**: Docker is installed, enabled, and running.

## 5. Variables & Configuration
| Variable | Default Value | Description |
|----------|---------------|-------------|
| DOCKER_PACKAGE | docker.io | APT package name for Docker |

## 6. Troubleshooting
| Symptom | Possible Cause | Fix |
|---------|----------------|-----|
| apt update fails | Network connectivity issue | Check internet connection and DNS settings |
| Package not found | Wrong package name or repo | Verify docker.io package exists via `apt-cache search docker` |
| systemctl enable fails | Insufficient permissions | Run with sudo or as root user |