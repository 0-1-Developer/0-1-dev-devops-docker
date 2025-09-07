# 🐳 Docker Learning Path: Zero to Production Master

> **Transform from Docker novice to production expert** through the most comprehensive, hands-on Docker curriculum available. Master containerization from core concepts to enterprise-grade implementations across 12 progressive phases.

[![Progress](https://img.shields.io/badge/Progress-100%25-brightgreen)]()
[![Phases](https://img.shields.io/badge/Phases-12-blue)]()
[![Lessons](https://img.shields.io/badge/Lessons-48-orange)]()
[![Duration](https://img.shields.io/badge/Duration-40--50hrs-green)]()
[![Platform](https://img.shields.io/badge/Platform-Cross--Platform-purple)]()
[![Labs](https://img.shields.io/badge/Labs-Available-yellow)]()

## 🚀 What Makes This Different?

This isn't just another Docker tutorial. It's a **production-focused learning experience** that:

- ✅ **Teaches real-world patterns** used by industry professionals
- ✅ **Emphasizes security first** with hardening from day one
- ✅ **Includes comprehensive labs** that simulate actual business scenarios
- ✅ **Provides verification systems** to ensure true understanding
- ✅ **Covers advanced topics** like multi-architecture builds and observability
- ✅ **Offers multiple learning paths** for different experience levels

## 🎯 Learning Outcomes

By completing this curriculum, you'll master:

### 🏗️ **Foundation Skills**
- Container lifecycle management and resource isolation
- Image architecture and layer optimization strategies  
- Network design patterns for microservices architectures
- Data persistence with backup/recovery procedures

### ⚡ **Advanced Techniques**
- Multi-stage builds with BuildKit optimizations
- Cross-platform image creation for ARM64, AMD64, ARM/v7
- Security hardening with distroless images and non-root users
- Supply chain security with SBOM generation and image signing

### 🎛️ **Production Operations**
- Comprehensive monitoring with Prometheus, Grafana, and distributed tracing
- CI/CD pipeline automation with multi-architecture support
- Container registry management and distribution strategies
- Performance optimization and resource management patterns

### 🛡️ **Enterprise Readiness**
- Security scanning, vulnerability management, and compliance
- Advanced troubleshooting and debugging techniques
- High-availability patterns and disaster recovery
- Team collaboration workflows and best practices

## 📊 Comprehensive Learning Path

### 🎓 **Learning Tracks Available**

#### **🚀 Beginner Track** (Phases 00-03) • *12-15 hours*
Perfect for developers new to containerization
- Container fundamentals and lifecycle management
- Dockerfile creation and optimization
- Production container operations

#### **🏗️ Intermediate Track** (Phases 04-07) • *15-18 hours*  
For developers building production applications
- Container networking and service communication
- Data persistence and volume management
- Multi-service orchestration with Compose
- Security hardening and vulnerability management

#### **⚡ Advanced Track** (Phases 08-11) • *18-20 hours*
For platform engineers and DevOps professionals  
- CI/CD automation and multi-architecture builds
- Registry management and distribution
- Comprehensive observability and monitoring
- Advanced image optimization and supply chain security

### 📋 **Phase Overview**

| Phase | Topic | Lessons | Duration | Status |
|-------|-------|---------|----------|--------|
| **00** | [Foundations](./00-foundations) | 4 | 3-4 hrs | ✅ Complete |
| **01** | [Dockerfile Basics](./01-dockerfile-basics) | 4 | 3-4 hrs | ✅ Complete |
| **02** | [BuildKit Advanced](./02-buildkit-advanced) | 4 | 4-5 hrs | ✅ Complete |
| **03** | [Container Operations](./03-container-ops) | 4 | 3-4 hrs | ✅ Complete |
| **04** | [Networking](./04-networking) | 4 | 4-5 hrs | ✅ Complete |
| **05** | [Storage & Volumes](./05-storage-volumes) | 4 | 3-4 hrs | ✅ Complete |
| **06** | [Compose](./06-compose) | 4 | 4-5 hrs | ✅ Complete |
| **07** | [Security](./07-security) | 4 | 4-5 hrs | ✅ Complete |
| **08** | [CI/CD & Buildx](./08-ci-cd-buildx) | 4 | 4-5 hrs | ✅ Complete |
| **09** | [Registries](./09-registries) | 4 | 3-4 hrs | ✅ Complete |
| **10** | [Observability](./10-observability) | 4 | 4-5 hrs | ✅ Complete |
| **11** | [Advanced Images](./11-advanced-images) | 4 | 3-4 hrs | ✅ Complete |

**Total:** 48 lessons • 42-50 focused hours • 100% Complete

## 🏁 Getting Started

### 🚀 **Quick Setup** (5 minutes)

```bash
# 1. Clone the repository
git clone https://github.com/0-1-Developer/docker.git
cd docker

# 2. Verify your Docker installation
make setup

# 3. Check your current progress
make progress

# 4. Start learning!
cd 00-foundations && cat README.md
```

### 📖 **Your Learning Journey Options**

#### **🎯 Self-Paced Individual Learning**
- Work through phases at your own speed
- Use built-in verification systems
- Track progress with automated tools

#### **👥 Team/Classroom Learning**
- Follow structured learning paths
- Use instructor resources and guides  
- Implement team progress tracking

#### **🏢 Corporate Training**
- Customize phases for your tech stack
- Integration with existing CI/CD systems
- Enterprise-specific security patterns

### ⚡ **Docker in 60 Seconds**

Never used Docker? Get started instantly:

```bash
# Pull and run your first container
docker run hello-world

# Run a web server (visit http://localhost:8080)
docker run -d -p 8080:80 nginx:alpine

# List running containers
docker ps

# Stop and clean up
docker stop $(docker ps -q)
docker system prune -f
```

**What just happened?** You downloaded, ran, and cleaned up a containerized web server without installing anything on your system. That's the power of containers!

## 🎓 Phase Deep Dive

### 🏗️ **Foundation Phases** (00-03)

<details>
<summary><strong>Phase 00: Foundations</strong> — Master container fundamentals</summary>

**Core Concepts:** Images vs containers, lifecycle states, resource boundaries, process isolation  
**Hands-On:** Interactive container management, resource mapping, troubleshooting common issues  
**Real-World Skills:** Understanding what containers are, why they matter, and how they work  
**Verification:** Successfully run and manage container lifecycles with proper resource allocation

**Key Learning Outcomes:**
- Explain the difference between images and containers with practical examples
- Demonstrate container lifecycle management (create, start, stop, remove)
- Configure resource boundaries and understand process isolation
- Troubleshoot common container startup and runtime issues
</details>

<details>
<summary><strong>Phase 01: Dockerfile Basics</strong> — Build optimized images</summary>

**Core Concepts:** Dockerfile directives, layer caching, build context, .dockerignore patterns  
**Hands-On:** Create Dockerfiles for different application types, optimize for cache efficiency  
**Real-World Skills:** Building production-ready images with proper optimization  
**Verification:** Create multi-layer images with efficient caching and minimal size

**Key Learning Outcomes:**
- Write Dockerfiles following best practices for different languages and frameworks
- Understand and leverage Docker's layer caching system
- Optimize build contexts and use .dockerignore effectively
- Debug build failures and understand build-time vs runtime considerations
</details>

<details>
<summary><strong>Phase 02: BuildKit Advanced</strong> — Master modern build techniques</summary>

**Core Concepts:** Multi-stage builds, cache mounts, build secrets, BuildKit syntax  
**Hands-On:** Complex multi-stage pipelines, secret handling, cross-platform considerations  
**Real-World Skills:** Advanced build optimization and security-conscious image creation  
**Verification:** Build production images with zero secret leakage and optimal performance

**Key Learning Outcomes:**
- Implement sophisticated multi-stage builds for different use cases
- Use BuildKit features like cache mounts and secret handling securely
- Optimize build performance with advanced caching strategies
- Handle build secrets without leaking them into final images
</details>

<details>
<summary><strong>Phase 03: Container Operations</strong> — Production-ready containers</summary>

**Core Concepts:** Health checks, restart policies, resource limits, signal handling  
**Hands-On:** Configure resilient containers, implement graceful shutdown patterns  
**Real-World Skills:** Operating containers in production environments reliably  
**Verification:** Deploy self-healing services with proper lifecycle management

**Key Learning Outcomes:**
- Configure comprehensive health checks and restart policies
- Set appropriate resource limits and understand their implications
- Implement graceful shutdown patterns and signal handling
- Monitor and troubleshoot container performance and reliability
</details>

### 🌐 **Architecture Phases** (04-07)

<details>
<summary><strong>Phase 04: Networking</strong> — Connect services securely</summary>

**Core Concepts:** Network types, service discovery, DNS resolution, network isolation  
**Hands-On:** Design multi-tier architectures, implement service mesh concepts  
**Real-World Skills:** Building scalable, secure network architectures for microservices  
**Verification:** Create isolated network segments with controlled inter-service communication

**Key Learning Outcomes:**
- Design and implement container network topologies
- Configure service discovery and load balancing patterns
- Implement network security with proper isolation and firewall rules
- Troubleshoot network connectivity and performance issues
</details>

<details>
<summary><strong>Phase 05: Storage & Volumes</strong> — Persistent data management</summary>

**Core Concepts:** Volume types, backup/restore strategies, permission handling, performance  
**Hands-On:** Implement data persistence, configure backup procedures, handle migrations  
**Real-World Skills:** Managing stateful applications with reliable data persistence  
**Verification:** Deploy applications where data survives complete infrastructure replacement

**Key Learning Outcomes:**
- Choose appropriate volume types for different use cases
- Implement backup and restore procedures for containerized data
- Handle file permissions and ownership across different platforms
- Optimize storage performance for database and application workloads
</details>

<details>
<summary><strong>Phase 06: Compose</strong> — Orchestrate multi-service applications</summary>

**Core Concepts:** Service definitions, profiles, networks, dependency management  
**Hands-On:** Build complete application stacks, manage different environments  
**Real-World Skills:** Orchestrating complex applications with multiple interdependent services  
**Verification:** Deploy full-stack applications with single-command deployment

**Key Learning Outcomes:**
- Design and implement multi-service application architectures
- Manage environment-specific configurations and secrets
- Configure service dependencies and startup ordering
- Implement development, staging, and production deployment patterns
</details>

<details>
<summary><strong>Phase 07: Security</strong> — Harden containers and images</summary>

**Core Concepts:** Non-root users, capabilities, vulnerability scanning, compliance frameworks  
**Hands-On:** Implement security hardening, scan for vulnerabilities, apply patches  
**Real-World Skills:** Building secure, compliant containerized applications  
**Verification:** Deploy hardened applications with minimal attack surface and security monitoring

**Key Learning Outcomes:**
- Implement comprehensive security hardening following industry standards
- Configure non-root users and minimize container capabilities
- Integrate vulnerability scanning into development and deployment pipelines
- Apply security policies and compliance requirements effectively
</details>

### 🚀 **Advanced Phases** (08-11)

<details>
<summary><strong>Phase 08: CI/CD & Buildx</strong> — Automate build and deployment</summary>

**Core Concepts:** Multi-platform builds, build automation, SBOM generation, supply chain security  
**Hands-On:** Create GitHub Actions pipelines, implement multi-architecture builds  
**Real-World Skills:** Building enterprise-grade CI/CD pipelines with security integration  
**Verification:** Deploy automated pipelines producing verified, multi-architecture images

**Key Learning Outcomes:**
- Implement comprehensive CI/CD pipelines with Docker integration
- Build and publish multi-architecture images (AMD64, ARM64, ARM/v7)
- Generate and manage Software Bill of Materials (SBOM)
- Integrate security scanning and compliance checks into automation
</details>

<details>
<summary><strong>Phase 09: Registries</strong> — Manage image distribution</summary>

**Core Concepts:** Registry operations, authentication, mirroring, content trust  
**Hands-On:** Set up private registries, configure caching, implement access controls  
**Real-World Skills:** Managing enterprise image distribution and security policies  
**Verification:** Deploy scalable registry infrastructure with proper authentication and caching

**Key Learning Outcomes:**
- Deploy and configure private container registries
- Implement authentication, authorization, and access control policies
- Configure registry mirroring and caching for performance optimization
- Manage image lifecycle policies and cleanup procedures
</details>

<details>
<summary><strong>Phase 10: Observability</strong> — Monitor and optimize performance</summary>

**Core Concepts:** Logging strategies, metrics collection, distributed tracing, alerting  
**Hands-On:** Deploy monitoring stacks, create dashboards, configure alerting  
**Real-World Skills:** Implementing comprehensive observability for production systems  
**Verification:** Monitor applications with metrics, logs, and traces providing actionable insights

**Key Learning Outcomes:**
- Implement comprehensive monitoring with Prometheus, Grafana, and other tools
- Configure centralized logging with proper structure and filtering
- Set up distributed tracing for microservices architectures  
- Create meaningful alerts and runbooks for operational issues
</details>

<details>
<summary><strong>Phase 11: Advanced Images</strong> — Optimize for production</summary>

**Core Concepts:** Distroless images, static linking, CVE minimization, image signing  
**Hands-On:** Create minimal images, implement signing workflows, optimize for security  
**Real-World Skills:** Building production-optimized images with minimal attack surface  
**Verification:** Deploy minimal images with comprehensive supply chain security verification

**Key Learning Outcomes:**
- Create distroless and scratch-based images for minimal attack surface
- Implement static linking strategies for different programming languages
- Minimize CVE exposure through careful base image selection and updates
- Implement image signing and supply chain security verification
</details>

## 💻 Platform Support & Requirements

### 🖥️ **Supported Platforms**

| Platform | Recommendation | Setup Command | Special Considerations |
|----------|---------------|---------------|----------------------|
| **🐧 Linux** | Native Docker Engine | `curl -fsSL https://get.docker.com \| sh` | Best performance, native containers |
| **🍎 macOS** | Docker Desktop | `brew install --cask docker` | Virtualization overhead, good dev experience |
| **🪟 Windows 11/10** | Docker Desktop + WSL2 | `winget install Docker.DockerDesktop` | Requires WSL2 backend for best performance |
| **☁️ Cloud** | Any Linux VM | `make setup` | Great for team learning environments |

### ⚙️ **System Requirements**

| Component | Minimum | Recommended | Enterprise |
|-----------|---------|-------------|------------|
| **RAM** | 8GB | 16GB | 32GB+ |
| **Storage** | 50GB free | 100GB free | 500GB+ SSD |
| **CPU** | 4 cores | 8 cores | 16+ cores |
| **Network** | Broadband | Fiber | Dedicated |

### 🛠️ **Quick Platform Setup**

<details>
<summary><strong>🐧 Linux (Ubuntu/Debian)</strong></summary>

```bash
# Install Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get update && sudo apt-get install docker-compose-plugin

# Verify installation
docker --version && docker compose version

# Clone learning path
git clone https://github.com/0-1-Developer/docker.git && cd docker
make setup
```
</details>

<details>
<summary><strong>🍎 macOS</strong></summary>

```bash
# Install Docker Desktop (requires Homebrew)
brew install --cask docker

# Start Docker Desktop from Applications
open /Applications/Docker.app

# Verify installation  
docker --version && docker compose version

# Clone learning path
git clone https://github.com/0-1-Developer/docker.git && cd docker
make setup
```
</details>

<details>
<summary><strong>🪟 Windows 10/11</strong></summary>

```powershell
# Enable WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Install Docker Desktop
winget install Docker.DockerDesktop

# In WSL2 Ubuntu terminal:
git clone https://github.com/0-1-Developer/docker.git && cd docker
make setup
```
</details>

## 🏆 Achievement System

### 📊 **Progress Tracking**

Your learning journey is tracked through multiple systems:

| System | Purpose | Location |
|--------|---------|----------|
| **Progress Anchors** | Micro-lesson completion | Each phase directory |
| **JSON Progress** | Automated tracking | [`docs/PROGRESS.json`](./docs/PROGRESS.json) |
| **Badge System** | Visual achievements | [`docs/badges/README.md`](./docs/badges/README.md) |
| **Verification Scripts** | Skill validation | `verify.rules.md` in each phase |

### 📈 **Track Your Progress**

```bash
# Check overall completion percentage
make progress

# View detailed progress breakdown  
cat docs/PROGRESS.json | jq '.phases[] | {phase, completion}'

# Verify specific phase completion
make verify-phase PHASE=04

# Check earned badges
ls docs/badges/earned/
```

### 🎯 **Progress Milestones**

- **🚀 25% Complete**: Docker Fundamentals Badge
- **🏗️ 50% Complete**: Production Ready Badge  
- **⚡ 75% Complete**: Advanced Practitioner Badge
- **🏆 100% Complete**: Docker Master Certification

## 🧪 Hands-On Labs

Beyond the core 48 lessons, explore specialized labs that combine multiple concepts:

### 🔗 **Integration Labs**
- **Full-Stack Deployment**: Complete MERN stack with Docker Compose
- **CI/CD Pipeline**: Multi-architecture builds with GitHub Actions
- **Monitoring Stack**: Prometheus, Grafana, and distributed tracing

### 🎯 **Challenge Labs** 
- **Microservices E-commerce**: Complex service mesh with security
- **Cloud-Native DevEnv**: Remote development containers
- **Healthcare Data Pipeline**: HIPAA-compliant data processing

### 🔬 **Experiment Labs**
- **Advanced BuildKit**: Cutting-edge build optimizations
- **Security Hardening**: Compliance frameworks and scanning
- **Performance Tuning**: Resource optimization and monitoring

**[Explore All Labs →](./labs/README.md)**

## 🎓 Learning Philosophy

This curriculum is built on proven educational principles:

### 🔨 **Practice-First Approach**
Every concept is immediately applied in hands-on exercises. No passive reading.

### 🎯 **Production Focus** 
Learn patterns actually used in enterprise environments, not just demos.

### ⚠️ **Failure as Learning**
Common mistakes are documented and practiced to build troubleshooting skills.

### 🌍 **Real-World Relevance**
Every lesson connects to actual business problems and career skills.

### 🔄 **Iterative Mastery**
Concepts are revisited and built upon throughout the curriculum.

## 🗂️ Repository Structure

```
docker-learning-path/
├── 00-foundations/           # Container fundamentals  
├── 01-dockerfile-basics/     # Image building
├── 02-buildkit-advanced/     # Advanced builds
├── ...                       # Phases 03-10
├── 11-advanced-images/       # Production optimization
├── labs/                     # Integration & challenge labs
│   ├── integration/          # Multi-phase projects
│   ├── challenges/           # Advanced scenarios  
│   └── experiments/          # Cutting-edge features
├── solutions/                # Reference implementations
├── docs/                     # Documentation hub
│   ├── PROGRESS.json         # Progress tracking
│   ├── FAQ.md               # Common questions
│   ├── GLOSSARY.md          # Terminology reference
│   └── badges/              # Achievement system
└── scripts/                  # Automation utilities
```

### 📁 **Each Phase Contains**

| File | Purpose |
|------|---------|
| `README.md` | Learning objectives and concept overview |
| `lab.md` | Step-by-step hands-on exercises |
| `verify.rules.md` | Success criteria and validation |
| `cleanup.rules.md` | Resource cleanup procedures |
| `visuals.md` | Diagrams and visual learning aids |

## 🤝 Contributing & Community

### 🛠️ **Ways to Contribute**

- 🐛 **Bug Reports**: Found an issue? [Report it](../../issues/new?template=bug_report.yml)  
- 💡 **Improvements**: [Suggest curriculum enhancements](../../issues/new?template=lesson_improvement.yml)
- 🎨 **Visual Content**: [Request diagrams or visual aids](../../issues/new?template=visual_request.yml)
- ❓ **Questions**: [Ask for help or clarification](../../issues/new?template=question.yml)

### 📋 **Contribution Guidelines**

All contributions must follow our [authorship policy](./CLAUDE.md) and use the provided [templates](./.github/PULL_REQUEST_TEMPLATE/).

## 📚 Essential Resources

| Resource | Purpose |
|----------|---------|
| 📋 **[Quick Reference](./docs/GLOSSARY.md)** | Docker terminology and commands |
| ❓ **[FAQ](./docs/FAQ.md)** | Common questions and solutions |
| 🖥️ **[Platform Notes](./docs/platform-notes.md)** | OS-specific setup guidance |
| 🏆 **[Badge System](./docs/badges/README.md)** | Achievement tracking |
| 📈 **[Progress Tracking](./docs/PROGRESS.json)** | Your learning journey |

## 🚀 Start Your Journey

Ready to become a Docker expert?

### **🎯 Option 1: Individual Learning**
```bash
git clone https://github.com/0-1-Developer/docker.git
cd docker && make setup
cd 00-foundations && cat README.md
```

### **👥 Option 2: Team Training** 
Perfect for corporate training or bootcamp environments
- Instructor guides available for each phase
- Progress tracking for multiple learners
- Customizable curriculum for specific tech stacks

### **🏢 Option 3: Enterprise Deployment**
- Integration with existing CI/CD systems
- Compliance-focused security patterns  
- Custom labs for your technology stack

**[Get Started Now →](./00-foundations)** | **[View Learning Tracks →](#-comprehensive-learning-path)** | **[Ask Questions →](../../issues/new?template=question.yml)**

## 🏆 Achievement Gallery

Track your progress through our comprehensive badge system:

### 🎯 **Phase Completion Badges**

| Phase | Badge | Status | Earned |
|-------|-------|--------|--------|
| **00** | ![Docker Foundations](https://img.shields.io/badge/Docker-Foundations-blue?logo=docker) | ✅ Complete | ⭐ |
| **01** | ![Dockerfile Architect](https://img.shields.io/badge/Dockerfile-Architect-green?logo=docker) | ✅ Complete | ⭐ |
| **02** | ![BuildKit Master](https://img.shields.io/badge/BuildKit-Master-orange?logo=docker) | ✅ Complete | ⭐ |
| **03** | ![Container Operator](https://img.shields.io/badge/Container-Operator-red?logo=docker) | ✅ Complete | ⭐ |
| **04** | ![Network Architect](https://img.shields.io/badge/Network-Architect-purple?logo=docker) | ✅ Complete | ⭐ |
| **05** | ![Storage Specialist](https://img.shields.io/badge/Storage-Specialist-yellow?logo=docker) | ✅ Complete | ⭐ |
| **06** | ![Stack Orchestrator](https://img.shields.io/badge/Stack-Orchestrator-lightblue?logo=docker) | ✅ Complete | ⭐ |
| **07** | ![Security Guardian](https://img.shields.io/badge/Security-Guardian-darkred?logo=docker) | ✅ Complete | ⭐ |
| **08** | ![CI/CD Architect](https://img.shields.io/badge/CICD-Architect-darkgreen?logo=docker) | ✅ Complete | ⭐ |
| **09** | ![Registry Admin](https://img.shields.io/badge/Registry-Admin-navy?logo=docker) | ✅ Complete | ⭐ |
| **10** | ![Observability Engineer](https://img.shields.io/badge/Observability-Engineer-teal?logo=docker) | ✅ Complete | ⭐ |
| **11** | ![Image Optimization Master](https://img.shields.io/badge/Optimization-Master-gold?logo=docker) | ✅ Complete | ⭐ |

### 🏅 **Mastery Achievements**

- ![Docker Expert](https://img.shields.io/badge/Docker-Expert-brightgreen?style=for-the-badge&logo=docker) **All 12 phases completed**
- ![Production Ready](https://img.shields.io/badge/Production-Ready-blue?style=for-the-badge&logo=docker) **Advanced techniques mastered**  
- ![Security Hardened](https://img.shields.io/badge/Security-Hardened-red?style=for-the-badge&logo=docker) **Security best practices implemented**

**[View Complete Badge System →](./docs/badges/README.md)**

---

<div align="center">

### 🎉 **Ready to Master Docker?**

**[🚀 Start Learning](./00-foundations)** • **[📋 View All Phases](#-comprehensive-learning-path)** • **[🏆 Badge System](./docs/badges/README.md)** • **[❓ Get Help](./docs/FAQ.md)**

<br>

![Docker Learning Journey](https://img.shields.io/badge/Journey-Complete-success?style=for-the-badge&logo=docker)

*The most comprehensive Docker learning path available. Transform from beginner to production expert.*

**⭐ Star this repository to bookmark your learning journey ⭐**

</div>

---

### 📊 **Repository Stats**

![Complete](https://img.shields.io/badge/Curriculum-100%25%20Complete-brightgreen)
![Phases](https://img.shields.io/badge/Phases-12-blue)
![Lessons](https://img.shields.io/badge/Lessons-48-orange)
![Labs](https://img.shields.io/badge/Labs-24+-yellow)
![Contributors](https://img.shields.io/badge/Contributors-Welcome-purple)

*Built with ❤️ for the Docker community*