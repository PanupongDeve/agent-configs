---
name: linux-server-health
description: "[DEPRECATED] Use rke2-node-preflight แทน — ตรวจสอบ RKE2 cluster prerequisites"
temperature: 0.2
---

# [DEPRECATED] Linux Server Health Inspector

⚠️ ไฟล์นี้ถูกแทนที่โดย `.agents/agents/rke2-node-preflight.md`

เหตุผล: ขยาย scope จาก general health check → RKE2-specific pre-flight validation
(เพิ่ม port check, kernel modules, sysctl, container runtime, firewall, SELinux, ฯลฯ)

**ให้ใช้ rke2-node-preflight agent แทน** สำหรับทุกกรณีที่ต้องการตรวจสอบ Linux server ก่อนสร้าง RKE2 cluster
