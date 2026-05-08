---
name: "playbook-analyzer"
description: "Analyze playbook execution output to identify issues, root causes, and provide solutions. Use when user asks to analyze playbook results, troubleshoot playbook errors, or generate analysis reports."
version: "1.0.0"
author: "Agent Configs"
tags: ["playbook", "analysis", "troubleshooting", "reporting"]
trigger_patterns:
  - "analyze playbook"
  - "playbook report"
  - "วิเคราะห์ผลลัพธ์"
  - "แก้ปัญหา playbook"
  - "ช่วยวิเคราะห์"
---

# Playbook Analyzer

## When to Use

Activate when user provides playbook execution output (shell script results, log files, JSON, text, or investigate-playbook-planner output) and asks for analysis, troubleshooting, or problem resolution.

## Input Types

Skill accepts the following input formats:

- Shell script output
- Log files
- JSON formatted results
- Plain text output
- Standard output from investigate-playbook-planner

## Analysis Process

### Step 1: Parse Input

1. Identify the input format (log, JSON, text, shell output)
2. Extract all execution results, errors, and status messages
3. Categorize entries by type (error, warning, success, info)

### Step 2: Identify Issues

For each error or failure detected:

1. **Problem:** What failed and at what step?
2. **Category:** Classify the issue:
   - `network` - connectivity, DNS, firewall, port issues
   - `disk` - storage, disk space, I/O errors
   - `permission` - file/directory permissions, access denied
   - `configuration` - wrong settings, missing config files
   - `dependency` - missing packages, broken dependencies
   - `runtime` - process failures, timeouts, crashes
   - `security` - SELinux, AppArmor, authentication failures
3. **Cause:** Analyze root cause based on error messages and context
4. **Solution:** Provide specific, actionable fix

### Step 3: Generate Report

Produce a Markdown report following the structure below.

## Markdown Report Structure

```markdown
# Playbook Analysis Report

## Summary

<!-- Overall execution status: Total steps, passed, failed -->

## Issues Found

<!-- For each issue: -->

### Issue N: [Descriptive Title]

- **Problem:** What failed
- **Category:** network | disk | permission | configuration | dependency | runtime | security
- **Cause:** Root cause analysis
- **Solution:** Step-by-step fix

## Recommendations

<!-- Overall suggestions for improvement -->
```

## Issue Category Reference

| Category | Common Indicators | Typical Solutions |
|----------|-------------------|-------------------|
| network | Connection refused, timeout, DNS fail | Check firewall, DNS, network config |
| disk | No space left, I/O error, read-only | Free space, check mount, fix filesystem |
| permission | Access denied, permission denied | chmod, chown, check SELinux |
| configuration | File not found, wrong value | Verify config files, set correct values |
| dependency | Package not found, import error | Install missing packages |
| runtime | Process killed, segfault, timeout | Check resources, increase timeout |
| security | Authentication failed, SELinux | Check credentials, configure SELinux |

## Example

**User Input:**
```
Running playbook...
[ERROR] Failed to connect to apt.repository.com:80
[ERROR] Package nginx could not be installed
[INFO] Step 3 completed
```

**Agent Output:**
> # Playbook Analysis Report
>
> ## Summary
> - Total Steps: 3
> - Passed: 1
> - Failed: 1
> - Status: ❌ Failed
>
> ## Issues Found
>
> ### Issue 1: Package Installation Failed
>
> - **Problem:** nginx package could not be installed due to network connectivity failure
> - **Category:** network
> - **Cause:** Unable to connect to apt.repository.com:80 - possible firewall or DNS issue
> - **Solution:**
>   1. Check DNS resolution: `nslookup apt.repository.com`
>   2. Test connectivity: `curl -I http://apt.repository.com`
>   3. Verify firewall rules allow outbound HTTP (port 80)
>
> ## Recommendations
>
> - Ensure network connectivity to package repositories before running installation steps
> - Consider adding retry logic for network-dependent operations
