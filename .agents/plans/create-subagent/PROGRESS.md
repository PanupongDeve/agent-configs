# Plan: Create RKE2 Node Preflight Subagent

สร้าง subagent ที่เรียนรู้จาก 5 skills (`disk-usage`, `network-info`, `system-info`, `network-engineer`, `installation-guide-creator`) เพื่อสร้าง bash script สำหรับตรวจสอบความพร้อมของ Linux server ก่อนสร้าง RKE2 Kubernetes cluster

**เปลี่ยนชื่อจาก:** `linux-server-health` → `rke2-node-preflight`
**เปลี่ยน point:** จาก general health check → RKE2-specific pre-flight validation

## Success Criteria

- [x] มี subagent `.md` file ใน `.agents/agents/rke2-node-preflight.md` พร้อม frontmatter metadata
- [x] subagent สร้าง bash script ออกมาเป็นไฟล์เดียว (`rke2-preflight.sh`)
- [x] bash script ตรวจสอบ RKE2 prerequisites หลัก:
  - OS / kernel version compatibility
  - Required kernel modules (overlay, br_netfilter)
  - Required sysctl params (net.ipv4.ip_forward, net.bridge.bridge-nf-call-iptables)
  - RKE2 required ports availability (9345, 6443, 10250, 8472, 2379, 2380)
  - SELinux / AppArmor status
  - Firewall rules (firewalld/ufw/iptables)
  - Disk space for etcd + container images
  - Hostname uniqueness + DNS resolution
- [x] bash script ที่ generate ไปแล้ว portable และรันบน Linux server เป้าหมายได้
- [x] รันแล้วได้ output: พร้อม/ไม่พร้อม แยกเป็นรายการ พร้อมคำแนะนำแก้ไข

## Todo

- [x] **เรียนรู้ 5 skills** — อ่าน SKILL.md ของ disk-usage, network-info, system-info, network-engineer, installation-guide-creator จนเข้าใจ commands และ workflow
- [x] **ร่าง RKE2 pre-flight checklist** — research RKE2 requirements (ports, kernel params, OS versions, etc.) เพื่อกำหนด scope ของ script
- [x] **ออกแบบ subagent prompt** — ร่าง identity, กระบวนการ, output format ของ rke2-node-preflight subagent
- [x] **สร้าง agent file** — สร้าง `.agents/agents/rke2-node-preflight.md` พร้อม frontmatter (name, description, model)
- [x] **ย้าย/ลบไฟล์เก่า** — deprecate `.agents/agents/linux-server-health.md` (redirect to new agent)
- [x] **สร้าง bash script** — สร้าง `.agents/scripts/rke2-preflight.sh` รวมคำสั่งจาก 5 skills
- [x] **ทดสอบ script** — รันแล้ว output รายการ pre-flight check พร้อมสถานะผ่าน/ไม่ผ่าน (PASS=12, FAIL=4, WARN=7) ✓
- [x] **ย้อนกลับมาปรับ prompt** — แก้ regex `ss -tulnp`, AppArmor output formatting, dig multiline

## Verification Commands

```bash
# 1. ตรวจ agent file มีอยู่
ls -la .agents/agents/rke2-node-preflight.md

# 2. รัน script ที่ถูกสร้าง
bash .agents/scripts/rke2-preflight.sh

# 3. ตรวจ output ว่ามี RKE2-specific checks
grep -c "─── " output.txt  # ควรได้ 5 sections
grep -q "KERNEL MODULES" output.txt
grep -q "SYSCTL" output.txt
grep -q "PORT AVAILABILITY" output.txt
```

## Files Created / Modified

| File | Action |
|------|--------|
| `.agents/agents/rke2-node-preflight.md` | **สร้างใหม่** — subagent prompt |
| `.agents/agents/linux-server-health.md` | **แก้ไข** — เพิ่ม deprecation notice |
| `.agents/scripts/rke2-preflight.sh` | **สร้างใหม่** — pre-flight bash script |

## Notes / Assumptions

- Subagent ถูกสร้างโดยใช้ `subagent-creator` skill เป็นแนวทาง
- Script ใช้เฉพาะ built-in commands, portable ไปรันบน Linux server เป้าหมาย
- `--server` flag จะเพิ่มตรวจสอบ etcd ports (2379, 2380)
- 5 skills ที่เรียนรู้: disk-usage, network-info, system-info, network-engineer, installation-guide-creator
- Container runtime (containerd) ไม่ต้องตรวจสอบแยกเพราะ RKE2 bundle มาให้ — แค่ port 10250 ก็พอ
- Network connectivity test ระหว่าง node ยังไม่ได้ทำใน script (ต้องมี IP/node list argument)
