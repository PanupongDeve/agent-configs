# Plan: Create Subagent - playbook-manager

**Status:** Completed

## Overview

สร้าง subagent `playbook-manager` สำหรับวางแผน playbook ในการจัดการ infra และวิเคราะห์ข้อมูลจาก script เพื่อหา solution

## Subagent Spec

```yaml
name: playbook-manager
description: |
  Playbook planning specialist. Use when:
  - Analyzing script output to find issues and propose solutions
  - Planning new playbooks from manual steps
  - Existing playbook needs improvements
model: inherit
```

## Workflow

1. **Receive & Parse** - รับ script output, exit codes, logs, config files
2. **Analyze** - ระบุ patterns, issues, root causes, improvement opportunities
3. **Propose Solution** - เสนอ playbook updates หรือออกแบบ playbook ใหม่
4. **Generate Todo List** - สร้าง todo list พร้อม priority และ expected outcomes

## Todo Format

```
- **Critical** (must fix): [Step] → [Expected outcome]
- **High** (should fix): [Step] → [Expected outcome]
- **Medium** (consider): [Step] → [Expected outcome]
- **Low** (nice to have): [Step] → [Expected outcome]
```

## Output

- Analysis summary
- Prioritized todo list
- Recommended playbook actions
- Notes and assumptions

## Scope

- ทำงานกับ playbook ที่มีอยู่ (nginx-install, rke2-readiness, etc.)
- สามารถออกแบบ playbook ใหม่ได้
- เสนออย่างเดียว ไม่ execute (รอ approval)
- Inherits workspace context จาก parent

## Design Decisions

| Decision | Choice |
|----------|--------|
| Input types | Script output, exit codes, logs, config files |
| Todo structure | Priority + steps + expected outcome |
| Post-analysis action | Proposal only (no execution) |
| Playbook scope | Both existing and new |
| Model | inherit |
| Workspace | Inherits from parent |

## Next Steps

- [x] Review and approve plan
- [x] Create subagent file at `.agents/agents/playbook-manager.md`
- [ ] Test subagent description triggers correctly

---

## Test Checklist

### Test Case 1: สร้าง Playbook ใหม่

**Scenario:** ผู้ใช้มี manual steps สำหรับติดตั้ง Docker

**Steps:**
1. สั่ง subagent ด้วย: "ฉันต้องการสร้าง playbook สำหรับติดตั้ง Docker มีขั้นตอนดังนี้: 1) apt update 2) apt install docker.io 3) systemctl enable docker"
2. ตรวจสอบว่า subagent แปลง steps เป็น structured playbook format
3. ตรวจสอบว่า todo list มี priority และ expected outcome

**Expected Output:**
```
## Analysis
- 3 manual steps identified
- Suitable for automation

## Todo List
- **High** (should do): Convert step 1 to idempotent apt update → Ensure package list is fresh
- **High** (should do): Convert step 2 to apt install docker.io → Docker installed
- **High** (should do): Convert step 3 to systemd enable → Docker starts on boot

## Playbook Action
- Create new playbook: docker-install.md
```

**Validation Criteria:**
- [x] Subagent triggers correctly (description matches)
- [x] Manual steps ถูกแปลงเป็น playbook structure
- [x] Todo list มี priority level ถูกต้อง
- [x] Output format ตรงกับ spec

---

### Test Case 2: วิเคราะห์ Playbook Output

**Scenario:** มี script output จากการ run playbook แล้ว error

**Input:**
```
=== RKE2 Installation Playbook ===
Step 1/5: Check prerequisites... FAILED
Error: Port 6443 is already in use
Step 2/5: Download RKE2 binary... SKIPPED
...
```

**Steps:**
1. สั่ง subagent ด้วย: "วิเคราะห์ output นี้แล้วเสนอ solution"
2. ตรวจสอบว่า subagent ระบุ root cause ได้
3. ตรวจสอบว่า todo list เสนอวิธีแก้ไข

**Expected Output:**
```
## Analysis Summary
- Root cause: Port 6443 conflict (another process using it)
- Impact: Installation cannot proceed
- Secondary issues: Steps after failure were skipped

## Todo List
- **Critical** (must fix): Identify process using port 6443 → Port available for RKE2
- **Critical** (must fix): Stop conflicting process or configure RKE2 to use different port → Installation proceeds
- **Medium** (consider): Add pre-check for port availability → Prevent future failures

## Recommended Playbook Actions
- Update rke2-install playbook to include port pre-check
- Add conflict resolution step
```

**Validation Criteria:**
- [x] Root cause ถูกระบุอย่างชัดเจน
- [x] Todo list มีความสอดคล้องกับปัญหา
- [x] Priority สอดคล้องกับ severity
- [x] มี recommendation สำหรับ playbook improvement

---

### Test Case 3: ปรับปรุง Playbook ที่มีอยู่

**Scenario:** ผู้ใช้ต้องการให้วิเคราะห์ playbook nginx-install ที่มีอยู่

**Steps:**
1. สั่ง subagent ด้วย: "วิเคราะห์ playbook nginx-install แล้วเสนอ improvements"
2. ตรวจสอบว่า subagent อ่าน playbook แล้ววิเคราะห์ได้

**Validation Criteria:**
- [x] Subagent อ่านไฟล์ playbook ที่มีอยู่ได้
- [x] ระบุ improvement opportunities ได้
- [x] เสนอ todo list ที่ actionable มากพอ