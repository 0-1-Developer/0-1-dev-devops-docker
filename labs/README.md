# Docker Learning Labs

> **Purpose**: Centralized collection of hands-on exercises and practical projects  
> **Scope**: Supplementary labs that extend beyond individual phase exercises

## 🧪 Lab Categories

### 🏗️ Integration Labs
Multi-phase labs that combine concepts from different phases for real-world scenarios.

### 🎯 Challenge Labs  
Advanced projects that test your Docker skills in realistic business contexts.

### 🔬 Experiment Labs
Cutting-edge Docker features and experimental techniques for advanced learners.

### 🏢 Industry Labs
Domain-specific labs tailored for different industries and use cases.

---

## 📚 Available Labs

### Integration Lab 01: Full-Stack Application Deployment
**Prerequisites**: Phases 00-06  
**Duration**: 2-3 hours  
**Concepts**: Multi-container applications, networking, volumes, security

Deploy a complete full-stack application with frontend, backend, database, and reverse proxy using Docker Compose.

**Skills Practiced:**
- Service orchestration with Docker Compose
- Network configuration and service discovery  
- Volume management for persistent data
- Basic security hardening
- Health checks and dependency management

**Location**: `labs/integration/01-fullstack-deployment/`

---

### Integration Lab 02: CI/CD Pipeline with Multi-Architecture Support
**Prerequisites**: Phases 00-08  
**Duration**: 3-4 hours  
**Concepts**: Automated builds, multi-architecture, registries, security scanning

Build a complete CI/CD pipeline that builds, tests, scans, and deploys applications across multiple architectures.

**Skills Practiced:**
- GitHub Actions workflow configuration
- Multi-architecture builds with buildx
- Container registry integration
- Vulnerability scanning and SBOM generation
- Automated deployment strategies

**Location**: `labs/integration/02-cicd-multiarch/`

---

### Integration Lab 03: Production Monitoring Stack
**Prerequisites**: Phases 00-10  
**Duration**: 4-5 hours  
**Concepts**: Complete observability, alerting, dashboard creation

Deploy and configure a production-ready monitoring stack with Prometheus, Grafana, Loki, and Jaeger.

**Skills Practiced:**
- Complete observability stack deployment
- Custom metrics and alerting rules
- Log aggregation and analysis
- Distributed tracing configuration
- Performance optimization monitoring

**Location**: `labs/integration/03-monitoring-stack/`

---

### Challenge Lab 01: Microservices E-commerce Platform
**Prerequisites**: All phases  
**Duration**: 8-12 hours  
**Concepts**: Complex microservices architecture, advanced networking, security

Build a realistic e-commerce platform with multiple microservices, advanced networking, and production-ready security.

**Skills Practiced:**
- Microservices architecture design
- Advanced networking with service mesh concepts
- Secrets management and security hardening
- Performance optimization and scaling
- Advanced troubleshooting and debugging

**Location**: `labs/challenges/01-ecommerce-microservices/`

---

### Challenge Lab 02: Cloud-Native Development Environment
**Prerequisites**: All phases  
**Duration**: 6-8 hours  
**Concepts**: Development workflows, remote containers, cloud integration

Create a complete cloud-native development environment with remote containers and cloud integrations.

**Skills Practiced:**
- Development container configurations
- Remote development workflows
- Cloud service integration
- Developer tooling containerization
- Team collaboration environments

**Location**: `labs/challenges/02-cloudnative-devenv/`

---

### Experiment Lab 01: Advanced BuildKit Features
**Prerequisites**: Phases 00-02, 08  
**Duration**: 2-3 hours  
**Concepts**: Cutting-edge BuildKit features, optimization techniques

Explore the latest BuildKit features including advanced cache strategies and build optimizations.

**Skills Practiced:**
- Advanced BuildKit syntax and features
- Complex cache mount strategies
- Build performance optimization
- Experimental BuildKit flags
- Custom build contexts

**Location**: `labs/experiments/01-buildkit-advanced/`

---

### Experiment Lab 02: Container Security Hardening
**Prerequisites**: Phases 00, 07, 11  
**Duration**: 3-4 hours  
**Concepts**: Advanced security techniques, compliance frameworks

Implement advanced container security hardening techniques and compliance frameworks.

**Skills Practiced:**
- Advanced security scanning and analysis
- Compliance framework implementation
- Runtime security monitoring
- Advanced image hardening techniques
- Security policy enforcement

**Location**: `labs/experiments/02-security-hardening/`

---

### Industry Lab 01: Healthcare Data Pipeline
**Prerequisites**: Phases 00-10  
**Duration**: 4-6 hours  
**Concepts**: HIPAA compliance, data processing, secure pipelines

Build a healthcare data processing pipeline with strict compliance and security requirements.

**Skills Practiced:**
- Compliance-focused container design
- Secure data processing workflows
- Audit logging and monitoring
- Data encryption and security
- Regulatory compliance patterns

**Location**: `labs/industry/01-healthcare-pipeline/`

---

### Industry Lab 02: Financial Trading System
**Prerequisites**: Phases 00-11  
**Duration**: 6-8 hours  
**Concepts**: High-performance computing, low-latency networking, security

Develop a financial trading system with strict performance and security requirements.

**Skills Practiced:**
- High-performance container optimization
- Low-latency networking configurations
- Financial-grade security implementation
- Performance monitoring and tuning
- Risk management and compliance

**Location**: `labs/industry/02-financial-trading/`

---

## 🚀 Getting Started with Labs

### Prerequisites Check
Before starting any lab, ensure you've completed the required phases:

```bash
# Check your progress
make progress

# Verify specific phase completion
make verify-phase PHASE=04
```

### Lab Environment Setup
Each lab includes setup instructions, but general preparation:

```bash
# Clean environment
make clean-safe

# Pre-build common images
make build-images

# Navigate to lab
cd labs/[category]/[lab-name]/
```

### Lab Structure
Each lab follows a consistent structure:

```
lab-name/
├── README.md          # Lab instructions and learning objectives
├── setup/             # Initial setup files and configurations
├── exercises/         # Step-by-step exercise files
├── solutions/         # Reference solutions (when appropriate)
├── validation/        # Verification scripts and tests
└── cleanup/           # Cleanup procedures and scripts
```

---

## 🎯 Learning Paths Through Labs

### Beginner Path (After Phases 00-03)
1. **Integration Lab 01**: Full-Stack Application Deployment
2. **Industry Lab 01**: Healthcare Data Pipeline (simplified version)

### Intermediate Path (After Phases 04-07)  
1. **Integration Lab 02**: CI/CD Pipeline with Multi-Architecture Support
2. **Challenge Lab 02**: Cloud-Native Development Environment
3. **Experiment Lab 01**: Advanced BuildKit Features

### Advanced Path (After Phases 08-11)
1. **Integration Lab 03**: Production Monitoring Stack
2. **Challenge Lab 01**: Microservices E-commerce Platform
3. **Experiment Lab 02**: Container Security Hardening
4. **Industry Lab 02**: Financial Trading System

---

## 🏆 Lab Completion Tracking

### Progress Badges
Complete labs earn special badges beyond phase completion:

- **🔗 Integration Master**: Complete all integration labs
- **🎯 Challenge Champion**: Complete all challenge labs  
- **🔬 Experiment Explorer**: Complete all experiment labs
- **🏢 Industry Expert**: Complete all industry labs

### Verification
Each lab includes verification procedures:

```bash
# Run lab verification
cd labs/[category]/[lab-name]/
./validation/verify.sh

# Check completion status
make lab-status
```

---

## 💡 Lab Development Guidelines

### Contributing New Labs
Interested in contributing labs? Follow these guidelines:

1. **Identify Learning Gap**: What real-world scenario isn't covered?
2. **Define Prerequisites**: Which phases must be completed first?
3. **Create Realistic Scenario**: Base on actual business needs
4. **Provide Complete Solution**: Include setup, exercises, and cleanup
5. **Test Thoroughly**: Verify on multiple platforms

### Lab Quality Standards
- **Realistic scenarios** based on actual business needs
- **Progressive complexity** building on phase knowledge
- **Complete documentation** with clear learning objectives
- **Verification procedures** to confirm successful completion
- **Cleanup procedures** to restore environment state

### Submission Process
1. Create lab in appropriate category directory
2. Follow the standard lab structure
3. Include comprehensive README with objectives
4. Test on multiple platforms (Linux, macOS, Windows/WSL2)
5. Submit PR using lab contribution template

---

## 🛠️ Lab Utilities

### Common Lab Commands
```bash
# List available labs
make list-labs

# Start a specific lab
make start-lab LAB=integration/01-fullstack-deployment

# Verify lab completion
make verify-lab LAB=integration/01-fullstack-deployment

# Clean up lab environment
make clean-lab LAB=integration/01-fullstack-deployment
```

### Lab Environment Management
```bash
# Create isolated lab environment
docker network create lab-network

# Pre-pull required images
docker compose -f setup/docker-compose.yml pull

# Initialize lab data
./setup/initialize.sh
```

---

## 📚 External Resources

### Industry Best Practices
- [CNCF Cloud Native Trail Map](https://github.com/cncf/trailmap)
- [Docker Production Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

### Advanced Learning
- [Container Security Fundamentals](https://www.cisa.gov/sites/default/files/publications/container-security-fundamentals.pdf)
- [Cloud Native Security Whitepaper](https://github.com/cncf/sig-security/blob/master/security-whitepaper/cloud-native-security-whitepaper.md)
- [Production-Ready Microservices](https://www.oreilly.com/library/view/production-ready-microservices/9781491965962/)

---

## 🆘 Lab Support

### Getting Help
- **Check lab-specific README** for troubleshooting steps
- **Review prerequisites** to ensure proper foundation
- **Use lab verification scripts** to identify issues
- **Consult platform notes** for OS-specific guidance
- **Ask questions** using the question issue template

### Common Issues
1. **Resource conflicts**: Use `make clean-safe` between labs
2. **Port conflicts**: Check lab documentation for required ports
3. **Permission issues**: Review platform-specific setup instructions
4. **Network issues**: Ensure Docker networking is properly configured

---

💡 **Philosophy**: Labs bridge the gap between learning Docker concepts and applying them in real-world scenarios. They provide the practical experience needed to confidently use Docker in professional environments.