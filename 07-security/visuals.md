# Phase 07: Docker Security - Visual Learning Guide

## Overview
Visual representations and diagrams to understand Docker security concepts, security layers, threat models, and defense-in-depth strategies.

## Visual 1: Docker Security Attack Surface and Threat Model
**Anchor**: `p07-visual-attack-surface`

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Security Attack Surface              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  External Threats                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🌐 Network Attacks    📦 Malicious Images              │   │
│  │  🔓 Registry Compromise 🕷️ Supply Chain Attacks         │   │
│  │  🎯 Targeted Exploits   📋 Config Vulnerabilities       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Host Operating System                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │  │   Docker    │ │   Kernel    │ │  Hardware   │        │   │
│  │  │   Daemon    │ │  Security   │ │  Security   │        │   │
│  │  │             │ │  Modules    │ │  Features   │        │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘        │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │             Container Runtime                   │    │   │
│  │  │  ┌─────────────────────────────────────────┐   │    │   │
│  │  │  │           Container 1                   │   │    │   │
│  │  │  │  ┌───────────────────────────────────┐ │   │    │   │
│  │  │  │  │  Application Code & Dependencies  │ │   │    │   │
│  │  │  │  │  • Vulnerable libraries           │ │   │    │   │
│  │  │  │  │  • Insecure configurations        │ │   │    │   │
│  │  │  │  │  • Hardcoded secrets              │ │   │    │   │
│  │  │  │  └───────────────────────────────────┘ │   │    │   │
│  │  │  └─────────────────────────────────────────┘   │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Attack Vectors:                                               │
│  • Container Breakout (Kernel exploits, Privileged containers) │
│  • Resource Exhaustion (DoS attacks, Fork bombs)               │
│  • Data Exfiltration (Volume mounts, Network access)           │
│  • Privilege Escalation (Capability abuse, User namespace)     │
│  • Supply Chain Compromise (Base images, Dependencies)         │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Multi-layered attack surface from external threats to application code
- Container isolation boundaries and potential breakout points
- Host system security dependencies
- Supply chain security considerations

## Visual 2: Defense-in-Depth Security Architecture
**Anchor**: `p07-visual-defense-layers`

```
┌─────────────────────────────────────────────────────────────────┐
│                  Defense-in-Depth Security Model               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Layer 1: Image Security                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 📋 Vulnerability Scanning    🔍 Base Image Hardening    │   │
│  │ ✍️  Image Signing & Trust     📦 Minimal Attack Surface │   │
│  │ 🏗️  Secure Build Pipeline     🔐 Secrets Management     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Layer 2: Container Configuration                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 👤 Non-Root Users           🚫 Capability Dropping       │   │
│  │ 📁 Read-Only Filesystems    🔒 Security Contexts         │   │
│  │ 🎯 Resource Limits          📊 Health Checks             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Layer 3: Runtime Security                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 🛡️  AppArmor/SELinux        🔐 Seccomp Profiles          │   │
│  │ 🌐 Network Segmentation     🔍 Runtime Monitoring        │   │
│  │ 📊 Behavioral Analysis      ⚠️  Anomaly Detection        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Layer 4: Host Security                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 🔧 Kernel Security          👥 User Namespaces           │   │
│  │ 🔥 Host Firewall            📋 Audit Logging             │   │
│  │ 🔄 System Updates           🏠 Host Hardening            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Layer 5: Infrastructure Security                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 🌐 Network Security         🔐 Identity Management       │   │
│  │ 📊 Compliance Monitoring    🎯 Incident Response         │   │
│  │ 💾 Backup & Recovery        📋 Security Policies         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Multiple security layers protecting containers
- Each layer provides independent protection
- Failure in one layer doesn't compromise entire system
- Comprehensive security coverage from image to infrastructure

## Visual 3: User Security and Namespace Isolation
**Anchor**: `p07-visual-user-security`

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Security & Namespace Isolation         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Host System (Real UIDs/GIDs)                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  root (0:0) ──────────────────────────────────────────┐ │   │
│  │  user1 (1000:1000) ────────────────────────────────┐  │ │   │
│  │  user2 (1001:1001) ──────────────────────────────┐ │  │ │   │
│  │  docker (999:999) ─────────────────────────────┐  │ │  │ │   │
│  │                                                 │  │ │  │ │   │
│  │  User Namespace Mapping                         │  │ │  │ │   │
│  │  ┌─────────────────────────────────────────┐   │  │ │  │ │   │
│  │  │        Container View (Virtual)         │   │  │ │  │ │   │
│  │  │                                         │   │  │ │  │ │   │
│  │  │  Container 1:                           │   │  │ │  │ │   │
│  │  │  ┌─────────────────────────────────┐   │   │  │ │  │ │   │
│  │  │  │ root (0:0) ────────────────────┼─┐ │   │  │ │  │ │   │
│  │  │  │   → Host UID 165536            │ │ │   │  │ │  │ │   │
│  │  │  │ appuser (1001:1001) ─────────┼─┼┼─┘   │  │ │  │ │   │
│  │  │  │   → Host UID 166537           │ ││     │  │ │  │ │   │
│  │  │  └─────────────────────────────────┘ ││     │  │ │  │ │   │
│  │  │                                      ││     │  │ │  │ │   │
│  │  │  Container 2:                        ││     │  │ │  │ │   │
│  │  │  ┌─────────────────────────────────┐ ││     │  │ │  │ │   │
│  │  │  │ root (0:0) ────────────────────┼─┘│     │  │ │  │ │   │
│  │  │  │   → Host UID 231072             │  │     │  │ │  │ │   │
│  │  │  │ webuser (2000:2000) ──────────┼──┘     │  │ │  │ │   │
│  │  │  │   → Host UID 233072            │        │  │ │  │ │   │
│  │  │  └─────────────────────────────────┘        │  │ │  │ │   │
│  │  └─────────────────────────────────────────┘   │  │ │  │ │   │
│  │                                                 │  │ │  │ │   │
│  │  File System Permissions:                      │  │ │  │ │   │
│  │  /host/file.txt (owner: 165536:165536) ────────┘  │ │  │ │   │
│  │  /host/data (owner: 1000:1000) ───────────────────┘ │  │ │   │
│  │  /host/app (owner: 166537:166537) ─────────────────────┘  │   │
│  │  /host/web (owner: 233072:233072) ────────────────────────┘   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Security Benefits:                                             │
│  • Container root ≠ Host root                                   │
│  • File system isolation through UID mapping                   │
│  • Privilege escalation prevention                             │
│  • Process isolation between containers                        │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- User namespace remapping isolates container users from host
- Container root user maps to unprivileged host user
- File system permissions maintain isolation
- Multiple containers get separate UID ranges

## Visual 4: Linux Capabilities and Privilege Management
**Anchor**: `p07-visual-capabilities`

```
┌─────────────────────────────────────────────────────────────────┐
│                Linux Capabilities & Privilege Control          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Traditional Unix Model (All or Nothing)                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Root User (UID 0)                                      │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  ALL PRIVILEGES                                 │   │   │
│  │  │  • File system access    • Network control     │   │   │
│  │  │  • Process control       • System administration│   │   │
│  │  │  • Hardware access       • Security settings   │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  Non-Root User (UID > 0)                               │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  LIMITED PRIVILEGES                             │   │   │
│  │  │  • Own files only        • User processes only  │   │   │
│  │  │  • No system access      • No network privileges│   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Modern Capabilities Model (Fine-Grained Control)              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Container with Minimal Capabilities                    │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  GRANTED CAPABILITIES                           │   │   │
│  │  │  ✅ NET_BIND_SERVICE (bind to ports < 1024)    │   │   │
│  │  │  ✅ CHOWN (change file ownership)              │   │   │
│  │  │  ✅ SETUID/SETGID (change user context)       │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  DROPPED CAPABILITIES                           │   │   │
│  │  │  ❌ NET_RAW (raw sockets, ping)                │   │   │
│  │  │  ❌ SYS_ADMIN (system administration)          │   │   │
│  │  │  ❌ SYS_MODULE (load kernel modules)           │   │   │
│  │  │  ❌ SYS_TIME (modify system time)              │   │   │
│  │  │  ❌ DAC_OVERRIDE (bypass file permissions)     │   │   │
│  │  │  ❌ MKNOD (create device files)                │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Docker Default vs Hardened Configuration                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Docker Default (14 capabilities)                       │   │
│  │  ┌─────────────────┐ ┌─────────────────┐              │   │
│  │  │   GRANTED       │ │    BLOCKED      │              │   │
│  │  │  • CHOWN        │ │  • SYS_ADMIN    │              │   │
│  │  │  • DAC_OVERRIDE │ │  • SYS_MODULE   │              │   │
│  │  │  • NET_RAW      │ │  • SYS_BOOT     │              │   │
│  │  │  • KILL         │ │  • NET_ADMIN    │              │   │
│  │  │  • SETUID       │ │  (+ others)     │              │   │
│  │  │  • SETGID       │ │                 │              │   │
│  │  │  (+ 8 others)   │ │                 │              │   │
│  │  └─────────────────┘ └─────────────────┘              │   │
│  │                                                         │   │
│  │  Hardened Container (Minimal capabilities)             │   │
│  │  ┌─────────────────┐ ┌─────────────────┐              │   │
│  │  │   GRANTED       │ │    BLOCKED      │              │   │
│  │  │  • (NONE or     │ │  • ALL          │              │   │
│  │  │     only        │ │    CAPABILITIES │              │   │
│  │  │     required)   │ │    DROPPED      │              │   │
│  │  └─────────────────┘ └─────────────────┘              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Security Commands:                                             │
│  • --cap-drop ALL --cap-add NET_BIND_SERVICE                   │
│  • --cap-drop NET_RAW (disable ping/raw sockets)               │
│  • --security-opt no-new-privileges:true                       │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Linux capabilities provide fine-grained privilege control
- Docker drops dangerous capabilities by default
- Further capability dropping increases security
- Principle of least privilege: grant only required capabilities

## Visual 5: Read-Only Filesystem Security Architecture
**Anchor**: `p07-visual-readonly-filesystem`

```
┌─────────────────────────────────────────────────────────────────┐
│                Read-Only Filesystem Security Model             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Traditional Writable Container (Higher Attack Surface)        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Container Filesystem (All Writable)                    │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  / (root) ────── 🔓 WRITABLE                    │   │   │
│  │  │  ├── /etc ────── 🔓 System configs can be modified │   │   │
│  │  │  ├── /bin ────── 🔓 Binaries can be replaced    │   │   │
│  │  │  ├── /lib ────── 🔓 Libraries can be modified   │   │   │
│  │  │  ├── /app ────── 🔓 Application files writable │   │   │
│  │  │  ├── /tmp ────── 🔓 Temporary files            │   │   │
│  │  │  └── /var ────── 🔓 Variable data writable     │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  Security Risks:                                        │   │
│  │  ❌ Malware can modify system files                     │   │
│  │  ❌ Configuration tampering possible                    │   │
│  │  ❌ Binary replacement attacks                          │   │
│  │  ❌ Persistent foothold establishment                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Hardened Read-Only Container (Minimal Attack Surface)         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Container Filesystem (Mostly Read-Only)                │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  / (root) ────── 🔒 READ-ONLY                   │   │   │
│  │  │  ├── /etc ────── 🔒 System configs protected    │   │   │
│  │  │  ├── /bin ────── 🔒 Binaries immutable          │   │   │
│  │  │  ├── /lib ────── 🔒 Libraries protected         │   │   │
│  │  │  ├── /app ────── 🔒 Application code protected  │   │   │
│  │  │  │               │                              │   │   │
│  │  │  │  tmpfs mounts │ (Secure Writable Areas)     │   │   │
│  │  │  ├── /tmp ────── 🔓 tmpfs (noexec,nosuid,50MB) │   │   │
│  │  │  ├── /var/run ── 🔓 tmpfs (noexec,nosuid,10MB) │   │   │
│  │  │  │               │                              │   │   │
│  │  │  │  Volume mounts│ (Persistent Writable)       │   │   │
│  │  │  ├── /app/cache─ 🔓 Volume (application cache) │   │   │
│  │  │  └── /app/logs── 🔓 Volume (application logs)  │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  Security Benefits:                                     │   │
│  │  ✅ System files cannot be modified                     │   │
│  │  ✅ Binary replacement prevented                        │   │
│  │  ✅ Configuration tampering blocked                     │   │
│  │  ✅ Malware persistence hindered                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Secure tmpfs Configuration                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Security Option  │ Purpose                              │   │
│  │  ──────────────── │ ─────────────────────────────────── │   │
│  │  noexec          │ Prevent executable file execution    │   │
│  │  nosuid          │ Ignore SUID/SGID bits               │   │
│  │  nodev           │ Ignore device files                  │   │
│  │  size=50m        │ Limit tmpfs size to prevent DoS     │   │
│  │                  │                                      │   │
│  │  Example: --tmpfs /tmp:noexec,nosuid,nodev,size=50m     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Implementation Commands:                                       │
│  • docker run --read-only --tmpfs /tmp:noexec,nosuid myapp     │
│  • docker run --read-only -v cache:/app/cache myapp            │
│  • security_opt: [read_only: true] in docker-compose.yml       │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Read-only root filesystem prevents system file modification
- tmpfs provides secure temporary storage with restrictions
- Volume mounts allow controlled persistent data areas
- Significant reduction in attack surface and malware persistence

## Visual 6: Container Image Security and Vulnerability Management
**Anchor**: `p07-visual-image-security`

```
┌─────────────────────────────────────────────────────────────────┐
│              Container Image Security & Vulnerability Pipeline │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Secure Image Development Lifecycle                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. Base Image Selection                                │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │
│  │  │   Ubuntu    │ │   Alpine    │ │ Distroless  │       │   │
│  │  │   22.04     │ │    3.18     │ │  (Google)   │       │   │
│  │  │             │ │             │ │             │       │   │
│  │  │ Size: 77MB  │ │ Size: 7MB   │ │ Size: 2MB   │       │   │
│  │  │ CVEs: High  │ │ CVEs: Low   │ │ CVEs: Minimal│       │   │
│  │  │ Packages:   │ │ Packages:   │ │ Packages:   │       │   │
│  │  │ ~400        │ │ ~15         │ │ None        │       │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘       │   │
│  │        │                │                │             │   │
│  │        ▼ (worst)        ▼ (better)       ▼ (best)      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  2. Secure Multi-Stage Build                           │   │
│  │                                                         │   │
│  │  Build Stage (Large, Development Tools)                │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  FROM node:18 AS builder                        │   │   │
│  │  │  • Install build dependencies                   │   │   │
│  │  │  • Compile source code                          │   │   │
│  │  │  • Run tests                                    │   │   │
│  │  │  • Generate optimized build                     │   │   │
│  │  │  Size: 900MB, Many vulnerabilities             │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                             │                           │   │
│  │                             ▼ (copy artifacts only)    │   │
│  │  Runtime Stage (Minimal)                               │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  FROM gcr.io/distroless/nodejs AS runtime      │   │   │
│  │  │  • Copy compiled application only              │   │   │
│  │  │  • No build tools or development dependencies  │   │   │
│  │  │  • Minimal attack surface                      │   │   │
│  │  │  Size: 150MB, Minimal vulnerabilities          │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  3. Vulnerability Scanning Pipeline                    │   │
│  │                                                         │   │
│  │  Image Built ──▶ Vulnerability Scan ──▶ Security Gate  │   │
│  │       │               │                      │          │   │
│  │       │               ▼                      ▼          │   │
│  │       │        ┌─────────────┐         ┌─────────────┐  │   │
│  │       │        │   Trivy     │         │   Policy    │  │   │
│  │       │        │ Docker Scout│         │   Check     │  │   │
│  │       │        │   Grype     │         │             │  │   │
│  │       │        │   Snyk      │         │ Critical: 0 │  │   │
│  │       │        │   Clair     │         │ High: ≤ 5   │  │   │
│  │       │        └─────────────┘         │ Medium: ≤15 │  │   │
│  │       │               │                └─────────────┘  │   │
│  │       │               ▼                      │          │   │
│  │       │        Vulnerability Report          ▼          │   │
│  │       │        ┌─────────────────────┐    ✅ PASS      │   │
│  │       │        │ Critical: 0         │    ❌ FAIL      │   │
│  │       │        │ High: 3             │                 │   │
│  │       │        │ Medium: 12          │                 │   │
│  │       │        │ Low: 45             │                 │   │
│  │       │        │ Total: 60           │                 │   │
│  │       │        └─────────────────────┘                 │   │
│  │       │                                                │   │
│  │       ▼ (if passed)                                    │   │
│  │  Registry Push ──▶ Image Signing ──▶ Production       │   │
│  │       │                 │                 │            │   │
│  │       ▼                 ▼                 ▼            │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐      │   │
│  │  │   Harbor    │ │   Cosign    │ │  Kubernetes │      │   │
│  │  │     or      │ │  Notary v2  │ │    Docker   │      │   │
│  │  │  Docker Hub │ │   GPG Keys  │ │   Compose   │      │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  4. Runtime Security Monitoring                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Continuous Vulnerability Assessment                    │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  Running Containers                             │   │   │
│  │  │  ├── app:v1.0 ─── Scan every 24h ─── 📊 Report │   │   │
│  │  │  ├── db:v2.1  ─── Scan every 24h ─── 📊 Report │   │   │
│  │  │  └── web:v1.5 ─── Scan every 24h ─── 📊 Report │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                             │                           │   │
│  │                             ▼                           │   │
│  │  Security Alerts & Actions                              │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │ New Critical CVE Detected                       │   │   │
│  │  │ ⚠️  CVE-2023-1234 in app:v1.0                   │   │   │
│  │  │ 🔄 Auto-rebuild triggered                       │   │   │
│  │  │ 📧 Security team notified                       │   │   │
│  │  │ 🚫 Block new deployments of vulnerable image    │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Secure base image selection dramatically reduces vulnerability count
- Multi-stage builds minimize final image attack surface
- Automated vulnerability scanning prevents vulnerable deployments
- Continuous monitoring catches new vulnerabilities in production
- Image signing ensures supply chain integrity

## Visual 7: Production Security Monitoring Architecture
**Anchor**: `p07-visual-security-monitoring`

```
┌─────────────────────────────────────────────────────────────────┐
│                Production Security Monitoring Stack            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Container Workloads (Security Events Generation)              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │  │   Web App   │ │     API     │ │  Database   │        │   │
│  │  │  Container  │ │  Container  │ │  Container  │        │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘        │   │
│  │        │               │               │                │   │
│  │        │ audit logs    │ system calls  │ network        │   │
│  │        ▼               ▼               ▼                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Runtime Security Detection Layer                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │   │
│  │  │    Falco    │ │  Aqua TTA   │ │ Twistlock   │        │   │
│  │  │(Behavioral) │ │(Compliance) │ │(Runtime)    │        │   │
│  │  │             │ │             │ │             │        │   │
│  │  │ • Syscalls  │ │ • CIS Rules │ │ • Anomaly   │        │   │
│  │  │ • File I/O  │ │ • Policies  │ │   Detection │        │   │
│  │  │ • Network   │ │ • Drift     │ │ • Behavioral│        │   │
│  │  │ • Process   │ │   Detection │ │   Analysis  │        │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘        │   │
│  │        │               │               │                │   │
│  │        │ security      │ compliance    │ runtime        │   │
│  │        │ events        │ violations    │ threats        │   │
│  │        ▼               ▼               ▼                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Security Event Processing & Correlation                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │           Event Aggregation                     │   │   │
│  │  │  ┌─────────────┐  ┌─────────────┐              │   │   │
│  │  │  │   Fluentd   │  │  Logstash   │              │   │   │
│  │  │  │   (Logs)    │  │ (Processing)│              │   │   │
│  │  │  └─────────────┘  └─────────────┘              │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                             │                           │   │
│  │                             ▼                           │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │        Security Information & Event             │   │   │
│  │  │        Management (SIEM)                        │   │   │
│  │  │  ┌─────────────┐  ┌─────────────┐              │   │   │
│  │  │  │  Splunk     │  │ Elastic     │              │   │   │
│  │  │  │             │  │ SIEM        │              │   │   │
│  │  │  │ • Correlation│  │ • Machine   │              │   │   │
│  │  │  │ • Analytics  │  │   Learning  │              │   │   │
│  │  │  │ • Forensics  │  │ • Threat    │              │   │   │
│  │  │  │              │  │   Detection │              │   │   │
│  │  │  └─────────────┘  └─────────────┘              │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Security Response & Orchestration                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Automated Response (SOAR)                              │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │                                                 │   │   │
│  │  │  High Priority Alerts                           │   │   │
│  │  │  ┌─────────────┐  ┌─────────────┐              │   │   │
│  │  │  │ Container   │  │ Privilege   │              │   │   │
│  │  │  │ Escape      │  │ Escalation  │              │   │   │
│  │  │  │ Attempt     │  │ Detected    │              │   │   │
│  │  │  └─────────────┘  └─────────────┘              │   │   │
│  │  │         │                 │                    │   │   │
│  │  │         ▼                 ▼                    │   │   │
│  │  │  ┌─────────────────────────────────────────┐  │   │   │
│  │  │  │        Automated Actions                │  │   │   │
│  │  │  │  • Isolate container                   │  │   │   │
│  │  │  │  • Block network traffic               │  │   │   │
│  │  │  │  • Create forensic snapshot            │  │   │   │
│  │  │  │  • Notify security team                │  │   │   │
│  │  │  │  • Update firewall rules               │  │   │   │
│  │  │  └─────────────────────────────────────────┘  │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  Manual Response (Security Team)                       │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  📊 Security Dashboard                          │   │   │
│  │  │  📋 Incident Tickets                            │   │   │
│  │  │  🔍 Forensic Investigation                      │   │   │
│  │  │  📞 Incident Response Procedures               │   │   │
│  │  │  📝 Compliance Reporting                        │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Key Security Metrics & KPIs                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  • Mean Time to Detection (MTTD): < 5 minutes             │   │
│  │  • Mean Time to Response (MTTR): < 15 minutes             │   │
│  │  • False Positive Rate: < 5%                              │   │
│  │  • Security Coverage: > 95% of containers monitored      │   │
│  │  • Compliance Score: > 90% CIS/NIST benchmarks           │   │
│  │  • Vulnerability Window: < 24 hours from disclosure      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Multi-layered security monitoring from containers to SIEM
- Real-time behavioral analysis and anomaly detection
- Automated response reduces incident response time
- Comprehensive logging and forensic capabilities
- Security metrics drive continuous improvement

## Security Implementation Commands Reference

### Quick Security Hardening Commands
```bash
# Maximum security container deployment
docker run -d \
  --name secure-app \
  --user 1001:1001 \
  --read-only \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --security-opt no-new-privileges:true \
  --security-opt apparmor:docker-default \
  --tmpfs /tmp:noexec,nosuid,size=50m \
  --tmpfs /var/run:noexec,nosuid,size=10m \
  --memory 512m \
  --cpus 0.5 \
  --health-cmd "curl -f http://localhost:8080/health" \
  --health-interval 30s \
  myapp:hardened

# Vulnerability scanning pipeline
docker scout cves myapp:latest --format json
trivy image --severity HIGH,CRITICAL myapp:latest
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image myapp:latest

# Security monitoring with Falco
docker run -i -t \
  --name falco \
  --privileged \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /dev:/host/dev \
  -v /proc:/host/proc:ro \
  -v /boot:/host/boot:ro \
  -v /lib/modules:/host/lib/modules:ro \
  -v /usr:/host/usr:ro \
  -v /etc:/host/etc:ro \
  falcosecurity/falco:latest
```

### Security Verification Commands
```bash
# Container security audit
docker inspect <container> | jq '{
  user: .Config.User,
  privileged: .HostConfig.Privileged,
  readonly: .HostConfig.ReadonlyRootfs,
  caps: .HostConfig.CapDrop,
  security_opt: .HostConfig.SecurityOpt
}'

# System-wide security check
docker ps --format "table {{.Names}}\t{{.Status}}" | \
  xargs -I {} sh -c 'echo "Container: {}"; docker inspect {} | jq .Config.User'
```

---

**Note**: These visual guides represent security concepts and architectures. In production environments, adapt these patterns based on specific security requirements, compliance frameworks, and organizational policies.