# Curriculum Changelog

> **Purpose**: Track all curriculum changes, updates, and revisions to the Docker learning path  
> **Scope**: Comprehensive log of educational content modifications per phase and PR

## Format

Each entry follows this format:
```
## [Phase XX] - YYYY-MM-DD - PR #XXX

### Added
- New features or content

### Changed  
- Modified existing content

### Fixed
- Bug fixes or corrections

### Removed
- Deprecated or removed content
```

---

## [Phase 11] - 2025-01-09 - Advanced Images Implementation

### Added
- **Complete Phase 11: Advanced Docker Images** with comprehensive coverage
- **README.md** (22K+ chars): Advanced image construction guide covering distroless, static linking, multi-arch, and signing
- **lab.md** (45K+ chars): 6 hands-on exercises with real-world examples
  - Exercise 1: Distroless Images Implementation
  - Exercise 2: Static Linking and Minimal Binaries
  - Exercise 3: CVE Minimization and Security Scanning
  - Exercise 4: Multi-Architecture and Advanced Build Patterns
  - Exercise 5: Image Signing and Supply Chain Security
  - Exercise 6: Performance Analysis and Optimization
- **verify.rules.md** (18K+ chars): Production verification procedures with automated testing
- **cleanup.rules.md** (17K+ chars): Safe cleanup procedures with recovery options
- **visuals.md** (20K+ chars): Comprehensive Mermaid diagrams and architecture flows
- **4 Micro-lessons**:
  - 01-distroless-conversion.md: Converting traditional apps to distroless
  - 02-static-linking-mastery.md: Creating self-contained binaries for scratch containers
  - 03-multi-arch-builds.md: Cross-platform builds with BuildKit
  - 04-image-signing-security.md: Supply chain security with Cosign and Sigstore

### Technical Coverage Added
- Distroless image implementation with Google's distroless base images
- Static linking techniques for Go, Rust, and C applications
- Multi-architecture builds for AMD64, ARM64, and ARM/v7
- Container image signing with both keyless and key-based methods
- SBOM generation and vulnerability attestation workflows
- CVE minimization strategies and security scanning integration
- Performance optimization and resource efficiency techniques
- Debug variants and troubleshooting strategies for minimal images

### Changed
- **PROGRESS.json** updated to reflect Phase 11 completion (100% - 48/48 lessons)
- Overall curriculum completion status: **COMPLETE**

### Learning Outcomes Added
- Master distroless image conversion with 60%+ size reduction
- Implement static linking for zero-dependency containers
- Create multi-architecture images with native performance
- Establish supply chain security with cryptographic signing
- Minimize CVE attack surface while maintaining functionality
- Optimize container performance and resource utilization

---

## [Phase 10] - 2025-01-09 - Observability Implementation

### Added
- **Complete Phase 10: Observability** with monitoring, logging, and performance analysis
- **README.md** (22K+ chars): Comprehensive observability implementation guide
- **lab.md** (45K+ chars): 6 hands-on exercises covering three pillars of observability
  - Exercise 1: Docker Logging Drivers and Centralized Logging
  - Exercise 2: Metrics Collection with Prometheus and Grafana
  - Exercise 3: Distributed Tracing with Jaeger and OpenTelemetry
  - Exercise 4: Log Aggregation with Loki and Promtail
  - Exercise 5: Performance Analysis and Resource Monitoring
  - Exercise 6: Observability Platform Integration
- **verify.rules.md** (18K+ chars): Production verification procedures for observability stack
- **cleanup.rules.md** (17K+ chars): Safe cleanup procedures for monitoring infrastructure
- **visuals.md** (20K+ chars): Architecture diagrams and monitoring workflows
- **4 Micro-lessons**:
  - 01-logging-drivers.md: Docker logging configuration
  - 02-metrics-collection.md: Prometheus integration
  - 03-image-analysis.md: Container optimization techniques
  - 04-performance-budgets.md: SLI/SLO implementation

### Technical Coverage Added
- Docker logging drivers (json-file, fluentd, syslog, journald)
- Metrics collection with Prometheus, cAdvisor, and Node Exporter
- Distributed tracing with Jaeger and OpenTelemetry instrumentation
- Log aggregation with Loki, Promtail, and LogQL queries
- Performance monitoring with resource budgets and SLO implementation
- Complete observability stack architecture and integration patterns

### Changed
- **PROGRESS.json** updated to reflect Phase 10 completion (92% → near completion)

---

## [Phases 00-09] - 2025-01-08 - Foundation Implementation

### Added
- **Complete implementation of Phases 00-09** covering Docker fundamentals to registries
- Each phase includes comprehensive 5-file structure:
  - README.md: Concept maps and learning objectives
  - lab.md: Hands-on exercises and practical implementation
  - verify.rules.md: Verification procedures and success criteria
  - cleanup.rules.md: Safe cleanup and resource management
  - visuals.md: Diagrams and visual learning aids
- **Micro-lessons** for focused learning (2-5 minute modules)
- **Production notes** and **pitfalls** sections for real-world applicability
- **Cross-platform support** with Windows/WSL2/Linux considerations

### Phase-by-Phase Coverage Added

#### Phase 00: Foundations
- Docker fundamentals: images, containers, lifecycle
- Container vs VM concepts and resource mapping
- Registry and image reference anatomy

#### Phase 01: Dockerfile Basics  
- Dockerfile directives and best practices
- Build context optimization and .dockerignore
- Cache strategies and deterministic builds

#### Phase 02: BuildKit Advanced
- Multi-stage builds and optimization
- Build secrets and cache mounts
- Advanced BuildKit features and Bake

#### Phase 03: Container Operations
- Health checks and restart policies
- Resource limits and signal handling
- Container lifecycle management

#### Phase 04: Networking
- Docker networking models and drivers
- Service discovery and network isolation
- Multi-container communication patterns

#### Phase 05: Storage & Volumes
- Volume types and data persistence
- Backup/restore strategies
- Permission handling across platforms

#### Phase 06: Compose
- Multi-service application stacks
- Environment profiles and configuration
- Service dependencies and health gating

#### Phase 07: Security
- Container hardening and non-root users
- Capability management and read-only filesystems
- Security scanning and vulnerability management

#### Phase 08: CI/CD & Buildx
- Multi-architecture builds and automation
- Cache strategies and registry integration
- SBOM generation and build attestation

#### Phase 09: Registries
- Local registry setup and proxy configuration
- Authentication flows and security
- Registry mirroring and rate limiting

### Technical Infrastructure Added
- **Progress tracking system** with PROGRESS.json
- **Verification framework** with automated testing capabilities
- **Cleanup procedures** for safe environment restoration
- **Visual documentation** with Mermaid diagrams
- **Cross-platform compatibility** notes and testing

---

## Template for Future Changes

```markdown
## [Phase XX] - YYYY-MM-DD - PR #XXX - [Brief Description]

### Added
- New content or features
- File additions
- New learning objectives

### Changed
- Modified existing content
- Updated examples or procedures
- Revised documentation

### Fixed
- Corrected errors or bugs
- Fixed broken examples
- Resolved platform-specific issues

### Removed
- Deprecated content
- Outdated examples
- Unnecessary complexity

### Technical Notes
- Implementation details
- Breaking changes
- Migration notes

### Learning Impact
- New skills acquired
- Changed learning outcomes
- Improved educational effectiveness
```

---

## Changelog Maintenance

### Update Frequency
- **Every PR** that modifies curriculum content must update this changelog
- **Major releases** should include comprehensive impact summaries
- **Monthly reviews** to ensure accuracy and completeness

### Entry Guidelines
- **Descriptive titles** that clearly indicate the scope of changes
- **Technical details** sufficient for understanding impact
- **Learning impact** assessment for educational value
- **Cross-references** to relevant PRs, issues, or related changes

### Quality Standards
- All entries must be reviewed before merge
- Breaking changes must be clearly marked
- Migration paths provided for significant structural changes
- Links to relevant documentation and examples

---

💡 **Note**: This changelog serves as the definitive record of curriculum evolution. It enables learners, contributors, and maintainers to understand the development history and make informed decisions about future changes.