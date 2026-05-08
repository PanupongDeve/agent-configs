# Progress: Create investigate-playbook-planner Skill

## Goal
Create a skill that helps plan operation playbooks for humans. It takes manual troubleshooting steps and environmental context as input and generates a structured Markdown guide accompanied by standalone, safe-to-run verification/action scripts.

## Tasks
- [ ] **Phase 1: Research & Design**
    - [x] Interview user for requirements (Grill-me session)
    - [x] Review existing script patterns in `.agents/scripts/` for consistency
- [ ] **Phase 2: Skill Definition**
    - [x] Create `.agents/skills/investigate-playbook-planner/SKILL.md`
    - [x] Define trigger patterns (e.g., "plan investigation", "create operation playbook")
- [ ] **Phase 3: Templates & Structure**
    - [x] Design the Markdown template for the "Operation Playbook"
    - [x] Design the shell script template (Idempotent, PASS/FAIL output)
- [ ] **Phase 4: Implementation**
    - [x] Create the directory structure: `.agents/skills/investigate-playbook-planner/scripts/`
    - [x] Write the core instructions in `SKILL.md` focusing on:
        - Infrastructure Audit
        - Task Breakdown
        - Script Generation (separated files)
        - Validation Plan
- [ ] **Phase 5: Verification**
    - [x] Test the skill with a sample scenario (e.g., "Install and verify Nginx on Ubuntu with 2GB RAM")
    - [x] Verify that scripts are correctly generated as separate files
    - [x] Final review of the generated playbook structure

## Notes
- "Playbook" refers to a human-readable guide, not Ansible.
- Scripts must be standalone and "Safe-to-Run".
- Target servers are separate from the agent's environment, so scripts must be portable.
- **Verification Result**: Successfully generated a complete "Nginx Install" playbook with 4 modular scripts in `playbooks/nginx-install/`. All scripts follow the idempotency and PASS/FAIL pattern.
