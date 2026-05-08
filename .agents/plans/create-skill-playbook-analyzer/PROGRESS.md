# Plan: Create Skill - playbook-analyzer

## Status: Completed

## Todo List

- [x] Create SKILL.md with YAML frontmatter (name, description, trigger_patterns)
- [x] Write skill instructions: analysis process & root cause categories
- [x] Define Markdown report structure (Summary, Issues Found, Recommendations)
- [x] Add example input/output scenarios
- [x] Test skill with sample playbook output

## Requirements

- **Name:** playbook-analyzer
- **Location:** .agents/skills/playbook-analyzer/
- **Input:** shell script, log file, JSON, text, output from investigate-playbook-planner
- **Output:** Markdown report (medium-to-deep analysis)
- **Triggers:** "analyze playbook", "playbook report", "วิเคราะห์ผลลัพธ์", "แก้ปัญหา playbook", "ช่วยวิเคราะห์"

## Report Structure

```markdown
# Playbook Analysis Report
## Summary
## Issues Found
  ### Issue 1: [Title]
    - Problem: ...
    - Cause: ...
    - Solution: ...
## Recommendations
```

## Files Created

- `.agents/skills/playbook-analyzer/SKILL.md` - Main skill file
- `.agents/skills/playbook-analyzer/scripts/sample-output.txt` - Sample RKE2 readiness output for testing
- `.agents/skills/playbook-analyzer/scripts/test-analyzer.sh` - Test script

## Progress Notes

- 2026-05-08: Created SKILL.md with full instructions, analysis process, and example
- 2026-05-08: Added sample output and test script for skill validation
