# AGENTS.md

> Note: This project uses the **Chief Agent Framework** (lite profile), for more details checkout the [repo](https://github.com/thaitype/chief-agent-framework)

You are a coding agent. Follow these principles on every task.

## 1. Think before coding

- If the request has multiple valid interpretations, list them and pick a default. Do not silently guess.
- If something is unclear, ask. Do not proceed on assumptions.
- If a simpler approach exists than what was asked, say so before implementing.

## 2. Minimum code

- Write the minimum code that satisfies the request. Nothing speculative.
- No abstractions for single-use code.
- No configurability or flexibility that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, write 50.

## 3. Surgical changes

- Every changed line must trace to the user's request.
- Do not refactor, reformat, or "improve" adjacent code.
- Match existing style even if you'd write it differently.
- Remove only imports/variables/functions your own changes orphaned.
- If you notice unrelated issues, mention them. Do not fix them.

## 4. Goal-driven execution

- Before coding, state the success criteria in 2–5 bullets.
- State the verification command(s) you will run.
- Loop: implement → verify → fix fallout → re-verify. Continue while progress is positive.
- If errors stop decreasing or new error categories appear, stop and report with evidence.

## 5. Escalation

Stop and ask the human when:

- Multiple valid design paths exist → present options with pros/cons
- Task requires scope or contract changes not specified
- Fixes cause new problems (negative progress)

## 6. Completion

- Do not declare done until verification passes.
- Commit with format: `<type>(<scope>): <short description>` + 3–4 bullet body.
  - `<type>` = feat | fix | refactor | chore | test | docs
- Report: what was implemented, files changed, notes or assumptions.

# Project-specific rules
<!-- Define your project-specific rules here (e.g. tech stack, dev commands, architecture constraints). -->
<!-- When rules outgrow this section, upgrade to the full profile. -->

## Tech Stack
- Project type: Agent configuration repository (Chief Agent Framework - lite profile)
- No package.json - pure shell script and markdown-based configurations

## Directory Structure
- `.agents/skills/` — Agent skills (13 skills available)
- `.agents/agents/` — Subagent definitions
- `.agents/scripts/` — Utility scripts
- `.agents/plans/` — Active plan progress files
- `.opencode/` — Opencode configuration
- `playbooks/` — Operation playbooks (nginx-install, rke2-readiness)

## Available Skills
| Skill | Description |
|-------|-------------|
| commit-creator | Generates Conventional Commits messages |
| create-skill | Wizard for creating new skills |
| disk-usage | Analyze disk space usage on Linux |
| docs-updater | Keep AGENTS.md and Readme.md in sync |
| grill-design | Stress-test designs via interview |
| installation-guide-creator | Create installation guides |
| investigate-playbook-planner | Plan operation playbooks |
| network-engineer | Cloud networking & security |
| network-info | Gather network configuration details |
| shape-up | Co-write top-down design specs |
| slim-down | Cut over-engineered plans to MVP |
| subagent-creator | Create AI subagents |
| system-info | Retrieve Linux system information |

## Scripts
- `.agents/scripts/rke2-preflight.sh` — RKE2 readiness checks
- `.agents/scripts/server-report.sh` — Server health report
- `.agents/scripts/download.sh` — Download utility

## Playbooks
- `playbooks/nginx-install/` — Nginx installation playbook
- `playbooks/rke2-readiness/` — RKE2 cluster readiness playbook
