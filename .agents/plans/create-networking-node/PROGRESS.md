# แผนการสร้าง Script ตรวจสอบ Pod Network Connectivity

> **สถานะ:** 📋 วางแผน (Planning)
> **อัพเดตล่าสุด:** 2026-05-07

---

## 1. ภาพรวมของปัญหา (Pain Point)

### ปัญหาที่พบ

ใน Kubernetes cluster ที่มีหลาย node (1 control plane + 3 workers) ปัญหา network connectivity ระหว่าง pods เป็นปัญหาที่พบบ่อยและวินิจฉัยยาก สาเหตุหลัก ๆ ได้แก่:

1. **CNI Plugin ทำงานไม่ถูกต้อง** — เช่น Calico, Flannel, Cilium ติดตั้งไม่สมบูรณ์ หรือ config ผิดพลาด ทำให้ pod ไม่สามารถส่ง traffic ข้าม node ได้
2. **Network Policy บล็อก traffic** — Kubernetes NetworkPolicy หรือ policy จาก CNI plugin (เช่น Calico NetworkPolicy) อาจบล็อก traffic โดยไม่ตั้งใจ
3. **Firewall ที่ node (iptables/nftables)** — firewall rules บนแต่ละ node อาจตัด traffic ที่จำเป็นสำหรับ pod-to-pod communication (โดยเฉพาะข้าม node)
4. **IP Forwarding / Bridge ตั้งค่าไม่ถูกต้อง** — sysctl parameters เช่น `net.ipv4.ip_forward`, `net.bridge.bridge-nf-call-iptables` ไม่ได้เปิด
5. **DNS Resolution ล้มเหลว** — CoreDNS หรือ DNS service ใน cluster ทำงานผิดปกติ ทำให้ pods ไม่สามารถ resolve service names ได้
6. **Kernel Modules หายไป** — เช่น `br_netfilter`, `overlay` ไม่ได้โหลด ทำให้ bridge networking และ container filesystem ทำงานไม่ได้

### ผลกระทบ

- Microservices ไม่สามารถติดต่อกันได้ → application ทำงานผิดพลาด
- Troubleshooting ใช้เวลานาน เพราะไม่รู้ว่าปัญหาอยู่ที่ layer ไหน
- Service Level Objectives (SLOs) ไม่ผ่าน
- Downtime หรือ degraded service

### ทำไมต้องมี Script นี้

- **ลดเวลา troubleshooting**: ตรวจสอบทีเดียวทุก layer (L3, L4, L7) จากทุกมุมมอง (intra-node และ inter-node)
- ** consistency**: ทุกครั้งที่ตรวจสอบ จะใช้วิธีเดียวกัน ได้ผลลัพท์ที่เชื่อถือได้
- **Automation**: คน или CI/CD สามารถรัน script นี้ได้ทุกเมื่อที่ต้องการตรวจสอบความพร้อมของ cluster network

---

## 2. Topology ของ Cluster

```
┌─────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                │
│                                                     │
│   ┌──────────────────────────────────────────────┐  │
│   │         Control Plane Node (cp-1)            │  │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │  │
│   │  │  etcd    │  │  kube-   │  │  kube-   │   │  │
│   │  │          │  │  apiserver│  │  control- │   │  │
│   │  └──────────┘  └──────────┘  └───┬──────┘   │  │
│   │                                  │            │  │
│   │  ┌───────────────────────────────┘            │  │
│   │  │  ┌──────────┐  ┌──────────┐                │  │
│   │  │  │  CNI     │  │  CoreDNS │                │  │
│   │  │  │  (agent) │  │  Pod     │                │  │
│   │  │  └──────────┘  └──────────┘                │  │
│   └──────────────────────────────────────────────┘  │
│                    ▲                                 │
│       Node-to-Node │ Network Overlay                 │
│   (VXLAN / IPIP /  │  Direct Routing)               │
│                    ▼                                 │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────┐  │
│   │  Worker-1    │  │  Worker-2    │  │ Worker-3 │  │
│   │  ┌──────────┐│  │  ┌──────────┐│  │ ┌──────┐ │  │
│   │  │  Pod A   ││  │  │  Pod C   ││  │ │ Pod E│ │  │
│   │  │  (app)   ││  │  │  (app)   ││  │ │ (app)│ │  │
│   │  └──────────┘│  │  └──────────┘│  │ └──────┘ │  │
│   │  ┌──────────┐│  │  ┌──────────┐│  │ ┌──────┐ │  │
│   │  │  Pod B   ││  │  │  Pod D   ││  │ │ Pod F│ │  │
│   │  │  (app)   ││  │  │  (app)   ││  │ │ (app)│ │  │
│   │  └──────────┘│  │  └──────────┘│  │ └──────┘ │  │
│   └──────────────┘  └──────────────┘  └──────────┘  │
│                                                     │
│   Node IPs:                                         │
│     cp-1:     192.168.1.10                          │
│     worker-1: 192.168.1.11                          │
│     worker-2: 192.168.1.12                          │
│     worker-3: 192.168.1.13                          │
│                                                     │
│   Pod CIDR: 10.42.0.0/16                            │
│   Service CIDR: 10.43.0.0/16                        │
└─────────────────────────────────────────────────────┘
```

### สิ่งที่ต้องตรวจสอบตาม topology นี้

| การตรวจสอบ | จาก | ไปยัง | Protocol |
|------------|------|-------|----------|
| Intra-node | Pod A (worker-1) | Pod B (worker-1) | ICMP / TCP |
| Inter-node | Pod A (worker-1) | Pod C (worker-2) | ICMP / TCP |
| Inter-node | Pod A (worker-1) | Pod E (worker-3) | ICMP / TCP |
| Inter-node | Pod C (worker-2) | Pod E (worker-3) | ICMP / TCP |
| Control → Worker | Pod on cp-1 | Pod on worker-1 | ICMP / TCP |
| DNS | Pod on any node | Service name | UDP/TCP 53 |

---

## 3. แนวทางการตรวจสอบ Network (Methods)

### Layer 3: IP Connectivity (ping)

- **ping** ระหว่าง pod IPs — ตรวจสอบว่า IP packet ถึงกันได้ (ข้าม node หรือ same node)
- ใช้ `kubectl exec` เพื่อรัน ping จาก pod หนึ่งไปยังอีก pod หนึ่ง
- กรณีที่ไม่มี `ping` ใน container (distroless image) ให้ใช้ `curl`, `wget`, หรือ python แทน

### Layer 4: Port Connectivity (curl / nc)

- **curl** ไปยัง pod IP + port (เช่น `curl http://10.42.1.3:8080`)
- **nc (netcat)** สำหรับ TCP port checking (เช่น `nc -zv 10.42.1.3 8080`)
- กรณีไม่มี curl/nc → ใช้ `/dev/tcp` ของ bash (เช่น `echo > /dev/tcp/10.42.1.3/8080`)

### Layer 7: Service DNS Resolution

- **nslookup** หรือ **dig** จากภายใน pod เพื่อ resolve service name (เช่น `nslookup kubernetes.default.svc.cluster.local`)
- **curl** ไปยัง service name (เช่น `curl http://my-service.namespace.svc.cluster.local:8080`)
- ตรวจสอบ CoreDNS pod ว่าทำงานอยู่
- ตรวจสอบ `/etc/resolv.conf` ภายใน pod

### Host-level Checks (บน node)

- `ip route` — ดู routing table ว่า route ไปยัง pod CIDR ของ node อื่นหรือไม่
- `iptables -L -n -t nat` — ดู SNAT/DNAT rules
- `bridge fdb show` — ตรวจสอบ forwarding database ของ bridge (ถ้าใช้ Flannel VXLAN)
- `ip neigh` — ARP table

---

## 4. รายละเอียด Script ที่จะสร้าง

### ชื่อไฟล์

```
.agents/scripts/pod-network-check.sh
```

### ภาษา

**Bash** — เลือก Bash เพราะ:
- มีอยู่ใน Linux distribution ทุกตัว ไม่ต้องติดตั้งเพิ่ม
- สามารถใช้ `kubectl exec` เพื่อรันคำสั่งภายใน pods
- สามารถใช้ `/dev/tcp` built-in ของ Bash สำหรับ TCP connection testing (ไม่ต้องพึ่ง curl/nc)

### Logic ที่ใช้

```
┌──────────────────────────────────────────────────┐
│               pod-network-check.sh               │
├──────────────────────────────────────────────────┤
│                                                   │
│  1. ตรวจสอบ Pre-requisites                       │
│     ├─ kubectl ติดตั้งและสามารถ connect cluster   │
│     ├─ jq ติดตั้ง (optional)                       │
│     └─ current context ถูกต้อง                     │
│                                                   │
│  2. ตรวจสอบ Node Status                           │
│     ├─ node ทั้งหมด ready หรือไม่                  │
│     └─ node IPs และ roles                         │
│                                                   │
│  3. ตรวจสอบ Core System Pods                     │
│     ├─ CoreDNS ทำงานหรือไม่                        │
│     ├─ CNI pods ทำงานหรือไม่ (calico/ flannel/..) │
│     └─ kube-proxy ทำงานหรือไม่                    │
│                                                   │
│  4. Deploy Debug Pods บนทุก node                  │
│     ├─ ใช้ image: alpine (มี ping, nc, nslookup)   │
│     ├─ สร้าง 1 pod ต่อ node                       │
│     └─ รอให้ pods พร้อม (Running)                  │
│                                                   │
│  5. Intra-node Connectivity Test                  │
│     ├─ สำหรับ debug pod แต่ละ node:               │
│     ├─ ping ไปยัง loopback (127.0.0.1)            │
│     └─ ping ไปยัง pod IP ของตัวเอง                │
│                                                   │
│  6. Inter-node Connectivity Test                  │
│     ├─ debug pod worker-1 → ping pod worker-2     │
│     ├─ debug pod worker-1 → ping pod worker-3     │
│     ├─ debug pod worker-2 → ping pod worker-3     │
│     └─ debug pod cp-1 → ping pod worker-1         │
│                                                   │
│  7. Port Connectivity Test (TCP)                   │
│     ├─ เปิด http server (python3) บน debug pod     │
│     │   (พอร์ต 8080)                              │
│     ├─ pod worker-1 → curl :8080 pod worker-2     │
│     ├─ pod worker-1 → curl :8080 pod worker-3     │
│     └─ (ต่อเนื่องทุกคู่)                            │
│                                                   │
│  8. DNS Resolution Test                           │
│     ├─ nslookup kubernetes.default.svc.cluster.local │
│     ├─ nslookup <service-name>                    │
│     ├─ curl ไปยัง kubernetes service              │
│     └─ ตรวจสอบ /etc/resolv.conf ใน pod            │
│                                                   │
│  9. Cleanup Debug Pods                            │
│     ├─ ลบ debug deployments                       │
│     └─ แสดง summary                               │
│                                                   │
│  10. Report Summary                               │
│      ├─ PASS/FAIL แต่ละ test                      │
│      ├─ คำแนะนำถ้า FAIL                            │
│      └─ สรุปภาพรวม                                │
│                                                   │
└──────────────────────────────────────────────────┘
```

### Output Format

```
╔════════════════════════════════════════════════╗
║       K8s Pod Network Connectivity Check      ║
╚════════════════════════════════════════════════╝
Cluster: my-cluster
Date: 2026-05-07
Nodes: 4 (1 cp, 3 workers)

─── [1/4] Pre-flight Checks ───
✓ kubectl: connected (context: my-cluster)
✓ Nodes: 4/4 Ready
✓ CoreDNS: Running (2/2 pods)
✓ CNI: Calico Running (4/4 pods)

─── [2/4] Intra-Node Connectivity ───
✓ worker-1: Pod A → Pod B (same node) [ping OK]
✓ worker-2: Pod C → Pod D (same node) [ping OK]
✓ worker-3: Pod E → Pod F (same node) [ping OK]

─── [3/4] Inter-Node Connectivity ───
✓ worker-1 → worker-2: ping OK (RTT: 0.45ms)
✓ worker-1 → worker-3: ping OK (RTT: 0.52ms)
✓ worker-2 → worker-3: ping OK (RTT: 0.38ms)
✓ cp-1 → worker-1: ping OK (RTT: 0.41ms)

─── [4/4] DNS Resolution ───
✓ kubernetes.default.svc resolved to 10.43.0.1
✓ curl http://kubernetes.default.svc:443 → 200 OK

─── Summary ───
✓ PASS: 12/12 tests
✗ FAIL: 0
⚠ WARN: 0

Network connectivity: HEALTHY
```

---

## 5. ขั้นตอนการ Run Script (Pre-requisites)

### สิ่งที่ต้องมีก่อนรัน

| Tool | เหตุผล | วิธีตรวจสอบ |
|------|--------|-------------|
| `kubectl` | สั่งงาน Kubernetes cluster | `kubectl version --client` |
| `kubectl` context | ต้อง connect ถูก cluster | `kubectl config current-context` |
| `jq` (optional) | parse JSON output | `jq --version` |
| `bash` ≥ 4 | รัน script | `bash --version` |
| Cluster admin rights | สร้าง/ลบ pods บน namespace ใดก็ได้ | `kubectl auth can-i create pods` |

### Cluster Requirements

- kubeconfig ต้องสามารถ connect ไปยัง cluster ได้
- cluster ต้องมี nodes อย่างน้อย 2 เครื่อง (เพื่อ test inter-node)
- Image registry ที่ pods สามารถ pull image `alpine:latest` หรือ `nicolaka/netshoot` ได้
- RBAC: service account ที่ใช้ต้องมีสิทธิ์ `get pods`, `create pods`, `delete pods` (script จะใช้ kubeconfig ที่ user มีอยู่)

### วิธีรัน

```bash
# 1. ให้สิทธิ์ execute
chmod +x .agents/scripts/pod-network-check.sh

# 2. รัน script
./.agents/scripts/pod-network-check.sh

# หรือรันแบบ verbose
./.agents/scripts/pod-network-check.sh -v

# หรือรันโดยไม่ cleanup (debug)
./.agents/scripts/pod-network-check.sh --no-cleanup
```

### Exit Codes

| Code | ความหมาย |
|------|----------|
| 0 | ทุก test ผ่าน (PASS) |
| 1 | มี test ที่ FAIL |
| 2 | Pre-requisite ไม่พร้อม (kubectl ไม่มี, cluster offline) |

---

## 6. วิธี Interpret ผลลัพธ์ (Pass/Fail Criteria)

### PASS (✓)

| Test | Criteria |
|------|----------|
| kubectl connectivity | `kubectl get nodes` สำเร็จ ได้ HTTP 200 |
| Node Ready | `kubectl get nodes` ทุก node status = Ready |
| Intra-node ping | pod ping ไปยังอีก pod บน node เดียวกันสำเร็จ (0% loss) |
| Inter-node ping | pod ping ไปยังอีก pod บน node อื่นสำเร็จ (0% loss) |
| Intra-node TCP | pod curl/telnet ไปยังอีก pod บน node เดียวกัน → port open |
| Inter-node TCP | pod curl/telnet ไปยังอีก pod บน node อื่น → port open |
| DNS resolution | `nslookup kubernetes.default.svc` → resolve ชื่อได้ |
| Service access | `curl` ไปยัง service name → HTTP 200 หรือ connection successful |

### FAIL (✗)

| Test | Criteria | สาเหตุที่เป็นไปได้ |
|------|----------|-------------------|
| kubectl connectivity | command error หรือ timeout | kubeconfig ผิด, cluster down |
| Node Ready | node status != Ready | kubelet ปิด, resource exhaustion |
| Intra-node ping | packet loss > 0% | CNI ผิด, loopback/interfaces ผิดพลาด |
| Inter-node ping | packet loss > 0% หรือ timeout | overlay network (VXLAN) ผิด, firewall, ip_forward ไม่เปิด |
| TCP port | connection refused หรือ timeout | service ไม่ได้รัน, NetworkPolicy บล็อก |
| DNS | ไม่ resolve | CoreDNS ไม่ทำงาน, DNS config ผิด |
| Service access | curl fails | service selector ผิด, backend pods ไม่พร้อม |

### WARN (⚠)

| Test | Criteria | หมายเหตุ |
|------|----------|----------|
| High RTT | ping RTT > 10ms (inter-node) | อาจเป็น network congestion |
| Missing tools | container ไม่มี ping/nslookup | script จะใช้ fallback method |
| kube-proxy mode | IPVS mode ถูกตั้งค่าหรือไม่ | ปกติ แต่ควรตรวจสอบ |

### การตัดสินใจ

- **✅ HEALTHY**: PASS 100% — ทุก test ผ่าน, network พร้อมใช้งาน
- **⚠️ DEGRADED**: มี WARN แต่ไม่มี FAIL — network ใช้งานได้ แต่อาจมี performance issue
- **❌ UNHEALTHY**: มี FAIL 1+ test — ต้องแก้ไขก่อน deploy workloads

---

## 7. แผนการทดสอบ (Test Plan)

### การทดสอบ Script ด้วยตนเอง

#### Test Case 1: Healthy Cluster
- **Objective**: ทดสอบกับ cluster ที่ทำงานปกติ
- **Steps**:
  1. รัน script
  2. ตรวจสอบว่า output format ถูกต้อง
  3. ตรวจสอบว่า debug pods ถูกสร้างแล้วถูกลบ
  4. ตรวจสอบผลลัพท์ว่าเป็น PASS ทั้งหมด
- **Expected**: PASS 100%

#### Test Case 2: Cluster ที่มี NetworkPolicy บล็อก traffic
- **Objective**: ทดสอบว่า script detect network policy issue ได้
- **Steps**:
  1. สร้าง NetworkPolicy ที่ deny all ingress
  2. รัน script
  3. ตรวจสอบว่า inter-node test FAIL
- **Expected**: FAIL ที่ inter-node connectivity test

#### Test Case 3: Cluster ที่ CoreDNS ไม่ทำงาน
- **Objective**: ทดสอบ DNS failure detection
- **Steps**:
  1. Scale down CoreDNS (`kubectl scale deploy coredns -n kube-system --replicas=0`)
  2. รัน script
  3. ตรวจสอบผล DNS test
- **Expected**: FAIL ที่ DNS test

#### Test Case 4: เครื่องมือไม่พร้อม (No kubectl)
- **Objective**: ทดสอบ error handling
- **Steps**:
  1. รัน script บนเครื่องที่ไม่มี `kubectl`
  2. ตรวจสอบ error message
- **Expected**: Script หยุดทันที พร้อมข้อความแจ้งว่า missing kubectl

#### Test Case 5: Cluster มี node ไม่พอ
- **Objective**: ทดสอบ minimum node requirement
- **Steps**:
  1. รัน script กับ cluster ที่มี node เดียว
  2. ตรวจสอบ behavior
- **Expected**: Script ควร WARN ว่าไม่สามารถ test inter-node ได้

#### Test Case 6: Container ไม่มี network tools
- **Objective**: ทดสอบ fallback method
- **Steps**:
  1. ใช้ image ที่ไม่มี ping (เช่น `nginx:alpine`)
  2. รัน script
  3. ตรวจสอบว่า script ใช้ fallback (เช่น `/dev/tcp` หรือ python)
- **Expected**: Script ใช้ fallback method และให้ผลลัพท์ถูกต้อง

#### Test Case 7: Cleanup ทดสอบ
- **Objective**: ตรวจสอบว่า cleanup ทำงานถูกต้องเสมอ (รวมถึงกรณี script error)
- **Steps**:
  1. รัน script
  2. ระหว่างที่ script รัน ให้กด Ctrl+C
  3. ตรวจสอบว่า debug pods ถูกลบหรือไม่
- **Expected**: trap handler ต้อง cleanup debug pods แม้จะถูก interrupt

### การทดสอบอัตโนมัติ (CI)

```
# ใน pipeline
- name: Pod Network Check
  run: |
    ./.agents/scripts/pod-network-check.sh
  post-run:
    # ตรวจสอบว่าไม่มี debug pods ค้างอยู่
    - kubectl get pods -n default | grep net-check  || true
    - kubectl get pods -n kube-system | grep net-check || true
```

---

## หมายเหตุเพิ่มเติม

- **Security**: Script นี้ต้องการสิทธิ์สร้าง pods ใน namespace — ควรมี warning ใน documentation
- **Portability**: ควรใช้ `alpine` image ขนาดเล็ก (≈5MB) เพื่อลด overhead
- **Timeout**: แต่ละ test ควรมี timeout (default 10 วินาที) เพื่อป้องกัน hanging
- **Idempotent**: Script ควรมี `trap` เพื่อ cleanup debug pods ทุกกรณี
- **Namespace**: ใช้ namespace ที่ user เลือกได้ (default: `default` หรือ `kube-system`)

---

## ขั้นตอนถัดไป

- [x] สร้างแผน (PROGRESS.md)
- [ ] เขียน script `.agents/scripts/pod-network-check.sh`
- [ ] ทดสอบกับ cluster จริง (unit test + integration test)
- [ ] แก้ไข bugs (ถ้ามี)
- [ ] สร้าง commit
