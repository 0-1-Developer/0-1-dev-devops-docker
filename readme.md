# 🐳 Docker Learning Path: Zero to Advanced

> **Transform from Docker beginner to production-ready practitioner** through hands-on, progressive learning across 12 comprehensive phases.

[![Progress](https://img.shields.io/badge/Progress-0%25-red)]() 
[![Phases](https://img.shields.io/badge/Phases-12-blue)]()
[![Duration](https://img.shields.io/badge/Duration-30--40hrs-green)]()
[![Platform](https://img.shields.io/badge/Platform-Cross--Platform-orange)]()

## 🎯 What You'll Learn

This comprehensive Docker curriculum takes you from foundational concepts to advanced production patterns through:

- **Container fundamentals** and lifecycle management
- **Image creation** with optimized Dockerfiles and BuildKit
- **Networking** patterns for multi-service architectures  
- **Data persistence** with volumes and backup strategies
- **Security hardening** and vulnerability management
- **CI/CD integration** with multi-platform builds
- **Observability** and performance optimization
- **Production-ready** patterns and best practices

## 📊 Learning Path Overview

| Phase | Topic | Duration | Status |
|-------|-------|----------|--------|
| **00** | [Foundations](#phase-00--foundations) | 2-3 hrs | 🔴 Pending |
| **01** | [Dockerfile Basics](#phase-01--dockerfile-basics) | 3-4 hrs | 🔴 Pending |
| **02** | [BuildKit Advanced](#phase-02--buildkit-advanced) | 3-4 hrs | 🔴 Pending |
| **03** | [Container Operations](#phase-03--container-operations) | 3-4 hrs | 🔴 Pending |
| **04** | [Networking](#phase-04--networking) | 3-4 hrs | 🔴 Pending |
| **05** | [Storage & Volumes](#phase-05--storage--volumes) | 2-3 hrs | 🔴 Pending |
| **06** | [Compose](#phase-06--compose) | 4-5 hrs | 🔴 Pending |
| **07** | [Security](#phase-07--security) | 3-4 hrs | 🔴 Pending |
| **08** | [CI/CD & Buildx](#phase-08--cicd--buildx) | 3-4 hrs | 🔴 Pending |
| **09** | [Registries](#phase-09--registries) | 2-3 hrs | 🔴 Pending |
| **10** | [Observability](#phase-10--observability) | 2-3 hrs | 🔴 Pending |
| **11** | [Advanced Images](#phase-11--advanced-images) | 2-3 hrs | 🔴 Pending |

**Total Estimated Time:** 30-40 focused hours

## 🚀 Quick Start (5-Minute Tour)

Get a taste of Docker in 5 minutes:

1. **Verify Installation**
   ```bash
   docker --version
   docker run hello-world
   ```

2. **Run Your First Service**
   ```bash
   docker run -d -p 8080:80 nginx:alpine
   # Visit http://localhost:8080
   ```

3. **Clean Up**
   ```bash
   docker stop $(docker ps -q)
   docker system prune -f
   ```

Congratulations! You've just:
- ✅ Verified Docker is working
- ✅ Pulled and ran an image
- ✅ Published a port
- ✅ Cleaned up resources

## 📚 Phase Details

### Phase 00 — Foundations
**Learn:** Images vs containers, lifecycle states, resource boundaries  
**Build:** Understanding of core Docker concepts  
**Verify:** Run services with proper resource mapping

### Phase 01 — Dockerfile Basics
**Learn:** Dockerfile directives, caching, context management  
**Build:** Optimized single-stage images  
**Verify:** Efficient builds with proper layer management

### Phase 02 — BuildKit Advanced
**Learn:** Multi-stage builds, cache mounts, build secrets  
**Build:** Production-grade images with zero secret leakage  
**Verify:** Faster builds with smaller final images

### Phase 03 — Container Operations
**Learn:** Health checks, restart policies, resource limits  
**Build:** Resilient containers with proper lifecycle management  
**Verify:** Self-healing services with graceful shutdown

### Phase 04 — Networking
**Learn:** Network types, service discovery, isolation patterns  
**Build:** Multi-tier architectures with proper segmentation  
**Verify:** Secure inter-service communication

### Phase 05 — Storage & Volumes
**Learn:** Volume types, backup/restore, permission handling  
**Build:** Stateful services with data persistence  
**Verify:** Data survives container replacement

### Phase 06 — Compose
**Learn:** Multi-container stacks, profiles, dependency management  
**Build:** Environment-specific configurations  
**Verify:** Single-command application deployment

### Phase 07 — Security
**Learn:** Non-root users, capabilities, vulnerability scanning  
**Build:** Hardened containers following least-privilege  
**Verify:** Minimal attack surface with security gates

### Phase 08 — CI/CD & Buildx
**Learn:** Multi-platform builds, cache optimization, SBOM generation  
**Build:** Automated build pipelines  
**Verify:** Reproducible builds across architectures

### Phase 09 — Registries
**Learn:** Registry operations, mirroring, authentication  
**Build:** Private registry with caching  
**Verify:** Efficient image distribution

### Phase 10 — Observability
**Learn:** Logging drivers, metrics, performance analysis  
**Build:** Monitored containerized services  
**Verify:** Metrics-driven optimization

### Phase 11 — Advanced Images
**Learn:** Distroless/scratch bases, static linking, debug strategies  
**Build:** Minimal production images  
**Verify:** Reduced CVE surface without losing debuggability

## 💻 Platform Support

| Platform | Docker Desktop | Docker Engine | Special Notes |
|----------|---------------|---------------|---------------|
| **Linux** | ✅ Optional | ✅ Recommended | Native performance |
| **macOS** | ✅ Required | ❌ | Virtualization overhead |
| **Windows Pro/Enterprise** | ✅ Recommended | ⚠️ WSL2 | WSL2 backend preferred |
| **Windows Home** | ✅ WSL2 Required | ⚠️ WSL2 | Full WSL2 setup needed |

## 📈 Progress Tracking

Your learning progress is tracked through:

- **Progress Anchors**: Unique identifiers like `p04-m01-l02` (Phase 4, Module 1, Lesson 2)
- **Progress File**: [`/docs/PROGRESS.json`](./docs/PROGRESS.json) maintains your completion status
- **Badges**: Earn visual badges for completing phases
- **Verification**: Each lab includes automated verification rules

### How to Track Your Progress

1. Check your current status:
   ```bash
   cat docs/PROGRESS.json | grep '"status": "completed"' | wc -l
   ```

2. Mark lessons complete by updating the status in `PROGRESS.json`

3. Run verification tests to confirm understanding

## 📖 Documentation

- **[Revamp Plan](./docs/REVAMP_PLAN.md)** - Detailed curriculum structure and requirements
- **[FAQ](./docs/FAQ.md)** - Common questions and troubleshooting
- **[Glossary](./docs/GLOSSARY.md)** - Docker terminology reference
- **[Progress Tracking](./docs/PROGRESS.json)** - Your learning progress
- **[Contribution Guidelines](./CLAUDE.md)** - How to contribute

## 🛠 Prerequisites

Before starting, ensure you have:

- **Docker 20.10+** installed ([Get Docker](https://docs.docker.com/get-docker/))
- **8GB RAM** minimum (16GB recommended)
- **20GB free disk space**
- **Basic command-line skills**
- **Text editor** (VS Code, vim, etc.)

## 🎓 Learning Philosophy

This curriculum emphasizes:

- **🔨 Hands-on practice** over passive reading
- **🎯 Production readiness** from day one
- **⚠️ Learning from failures** with documented pitfalls
- **🔄 Iterative improvement** through repeated practice
- **🌍 Real-world relevance** in every lesson

## 🚧 Repository Structure

```
/00-foundations/        # Phase 00: Core concepts
/01-dockerfile-basics/  # Phase 01: Image building fundamentals
/02-buildkit-advanced/  # Phase 02: Advanced build techniques
...
/11-advanced-images/    # Phase 11: Minimal containers
/labs/                  # Hands-on exercises
/scripts/               # Utility scripts
/docs/                  # Documentation and progress tracking
/.github/               # CI/CD and templates
```

Each phase directory contains:
- `README.md` - Concept overview and learning objectives
- `lab.md` - Hands-on exercises
- `verify.rules.md` - Success criteria
- `cleanup.rules.md` - Resource cleanup instructions
- `visuals.md` - Diagram specifications

## 🤝 Contributing

We welcome contributions that enhance the learning experience. Please review:

- [Contribution Guidelines](./CLAUDE.md)
- [Issue Templates](./.github/ISSUE_TEMPLATE/)
- [PR Template](./.github/pull_request_template.md)

### How to Contribute

1. **Report Issues**: Found a bug or have a suggestion? [Open an issue](../../issues)
2. **Improve Content**: Submit PRs following our authorship policy
3. **Share Experience**: Add to FAQ or create visual aids
4. **Test Labs**: Verify exercises work across platforms

## 📝 License

This educational content is provided for learning purposes. See [LICENSE](./LICENSE) for details.

## 🌟 Getting Started

Ready to begin your Docker journey?

1. **Fork this repository** to track your progress
2. **Review Phase 00** in [`/00-foundations`](./00-foundations)
3. **Complete the first lab** and verify success
4. **Update your progress** in [`docs/PROGRESS.json`](./docs/PROGRESS.json)
5. **Continue through phases** at your own pace

> 💡 **Tip**: Spend time on each phase until you're comfortable. Real mastery comes from understanding, not speed.

## 📊 Progress Badges

Earn badges as you complete each phase:

| Phase | Badge | Status |
|-------|-------|--------|
| Foundations | ![](https://img.shields.io/badge/Foundations-Pending-lightgrey) | 🔴 |
| Dockerfile Basics | ![](https://img.shields.io/badge/Dockerfile-Pending-lightgrey) | 🔴 |
| BuildKit | ![](https://img.shields.io/badge/BuildKit-Pending-lightgrey) | 🔴 |
| Container Ops | ![](https://img.shields.io/badge/Operations-Pending-lightgrey) | 🔴 |
| Networking | ![](https://img.shields.io/badge/Networking-Pending-lightgrey) | 🔴 |
| Storage | ![](https://img.shields.io/badge/Storage-Pending-lightgrey) | 🔴 |
| Compose | ![](https://img.shields.io/badge/Compose-Pending-lightgrey) | 🔴 |
| Security | ![](https://img.shields.io/badge/Security-Pending-lightgrey) | 🔴 |
| CI/CD | ![](https://img.shields.io/badge/CI%2FCD-Pending-lightgrey) | 🔴 |
| Registries | ![](https://img.shields.io/badge/Registries-Pending-lightgrey) | 🔴 |
| Observability | ![](https://img.shields.io/badge/Observability-Pending-lightgrey) | 🔴 |
| Advanced | ![](https://img.shields.io/badge/Advanced-Pending-lightgrey) | 🔴 |

---

<div align="center">

**[Start Learning →](./00-foundations)** | **[View Roadmap](./docs/REVAMP_PLAN.md)** | **[Get Help](./docs/FAQ.md)**

*Built with 🐳 for the developer community*

</div>