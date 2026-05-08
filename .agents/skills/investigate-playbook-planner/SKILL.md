---
name: "investigate-playbook-planner"
description: "Plans human-readable operation playbooks based on manual steps and environment context. Generates structured Markdown guides and standalone, safe-to-run verification scripts."
version: "1.0.0"
author: "Gemini CLI"
tags: ["planning", "operations", "playbook", "investigation"]
trigger_patterns:
  - "plan investigation"
  - "create operation playbook"
  - "plan playbook for"
  - "investigate-playbook-planner"
---

# Investigate Playbook Planner

This skill helps you transition from vague troubleshooting ideas to a concrete, human-executable operation playbook. It focuses on clarity, safety, and verifiability.

## When to Use
- When you need to document a series of manual steps for a human to follow.
- When you need to create a plan for setting up or troubleshooting a system.
- When you want to ensure a procedure is safe and verifiable with scripts.

## Core Mandates
1. **Human-Centric**: The final Playbook (Markdown) must be easy for a human to read and follow.
2. **Safe-to-Run Scripts**: All generated scripts MUST be idempotent and provide clear PASS/FAIL feedback.
3. **Standalone Scripts**: Scripts must be created as separate files in the `.agents/skills/investigate-playbook-planner/scripts/` directory (or a project-specific scripts folder) so they can be transferred to target servers.
4. **Environment Awareness**: Always check the provided OS, resources, and stack constraints before suggesting commands.

## The Process

### Step 1: Analyze Input
Gather the manual steps, OS, resources (RAM/CPU/Disk), and the technology stack from the user.

### Step 2: Plan the Playbook (Markdown)
Create a structured Markdown file with the following sections:
1. **Overview**: Goal of the playbook and environment requirements.
2. **Infrastructure Audit**: Commands to verify the environment (RAM, OS version, etc.) before starting.
3. **Execution Steps**: Broken down into logical phases. Each phase should have:
    - Description of what is being done.
    - Reference to a script file for automated execution/verification.
    - Expected outcome.
4. **Variables**: List of values that might change (IPs, versions, paths).
5. **Final Validation**: A final script to verify the entire stack is healthy.

### Step 3: Generate Scripts
For each logical task, generate a shell script (`.sh`).
**Script Requirements:**
- Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Include a `check()` function for consistent output:
  ```bash
  check() {
    local status=$1
    local msg=$2
    if [ "$status" -eq 0 ]; then
      echo "  ✓ $msg [PASS]"
    else
      echo "  ✗ $msg [FAIL]"
      exit 1
    fi
  }
  ```
- Use descriptive headers and comments.
- Ensure idempotency (e.g., check if a line exists before adding it).

## Example Playbook Structure

```markdown
# Playbook: [Goal Name]

## 1. Prerequisites
- OS: [OS Name]
- Specs: [RAM/CPU]
- Run `scripts/audit_env.sh` to verify.

## 2. Phase 1: [Phase Name]
1. Run `scripts/step1_install.sh`
2. Expected: [Outcome]

...
```

## Tips
- Always ask for clarification if the "manual steps" are too vague.
- Use `lsmod`, `sysctl`, `systemctl`, and `df` for robust environment checks.
- If a step is risky, add a `[CAUTION]` note in the Markdown.
