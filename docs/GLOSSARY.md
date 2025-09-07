# Docker Learning Path Glossary

> **Purpose**: Comprehensive definitions of Docker terms and concepts used throughout the learning path  
> **Scope**: Technical terminology with cross-references to relevant phases and lessons

## 📖 How to Use This Glossary

- **Terms** are alphabetically organized within categories
- **Phase References** link to where concepts are introduced (e.g., `→ Phase 04`)  
- **Cross-references** connect related concepts
- **Progressive Complexity** builds from basic to advanced terms

---

## 🏗️ Core Docker Concepts

### Base Image
The foundation layer of a Docker image, typically an operating system like Ubuntu, Alpine, or distroless variants. All subsequent layers build upon the base image.  
*→ Phase 01: Dockerfile Basics*  
*See also: [Distroless Images](#distroless-images), [Scratch Image](#scratch-image)*

### Build Context
The set of files and directories sent to the Docker daemon during image builds. Managed by `.dockerignore` to exclude unnecessary files.  
*→ Phase 01: Dockerfile Basics*  
*See also: [.dockerignore](#dockerignore), [BuildKit](#buildkit)*

### Container
A running instance of a Docker image. Containers are isolated, portable, and ephemeral by design.  
*→ Phase 00: Foundations*  
*See also: [Image](#image), [Container Lifecycle](#container-lifecycle)*

### Container Lifecycle
The states a container transitions through: created → running → paused → stopped → removed. Understanding lifecycle is crucial for operations.  
*→ Phase 00: Foundations, Phase 03: Container Operations*  
*See also: [Health Checks](#health-checks), [Restart Policies](#restart-policies)*

### Digest
A cryptographic hash (SHA256) that uniquely identifies image content. Unlike tags, digests are immutable and guarantee content integrity.  
*→ Phase 00: Foundations*  
*See also: [Image Tags](#image-tags), [Registry](#registry)*

### Dockerfile
A text file containing instructions to build a Docker image. Each instruction creates a new layer in the image.  
*→ Phase 01: Dockerfile Basics*  
*See also: [Multi-stage Builds](#multi-stage-builds), [BuildKit](#buildkit)*

### Image
A read-only template used to create containers. Images consist of layered filesystems and metadata.  
*→ Phase 00: Foundations*  
*See also: [Container](#container), [Image Layers](#image-layers)*

### Image Layers
Individual filesystem changes stacked to form a complete image. Layers enable efficient storage and transfer through deduplication.  
*→ Phase 00: Foundations, Phase 01: Dockerfile Basics*  
*See also: [Build Cache](#build-cache), [Distroless Images](#distroless-images)*

### Image Tags
Human-readable labels for image versions (e.g., `nginx:1.21`, `app:latest`). Tags are mutable and can point to different content over time.  
*→ Phase 00: Foundations*  
*See also: [Digest](#digest), [Registry](#registry)*

### Registry
A service that stores and distributes Docker images. Examples include Docker Hub, Amazon ECR, and self-hosted registries.  
*→ Phase 09: Registries*  
*See also: [Repository](#repository), [Image Tags](#image-tags)*

### Repository
A collection of related Docker images, typically different versions of the same application.  
*→ Phase 09: Registries*  
*See also: [Registry](#registry), [Image Tags](#image-tags)*

---

## 🔧 Build System

### .dockerignore
A file specifying patterns for files and directories to exclude from the build context, similar to `.gitignore`.  
*→ Phase 01: Dockerfile Basics*  
*See also: [Build Context](#build-context), [Build Performance](#build-performance)*

### ARG (Build Argument)
Variables available only during image build time, used to parameterize builds without affecting the runtime environment.  
*→ Phase 02: BuildKit Advanced*  
*See also: [ENV](#env-environment-variables), [Multi-stage Builds](#multi-stage-builds)*

### Build Cache
Docker's mechanism for reusing intermediate layers from previous builds to accelerate subsequent builds.  
*→ Phase 01: Dockerfile Basics, Phase 02: BuildKit Advanced*  
*See also: [Image Layers](#image-layers), [Cache Mounts](#cache-mounts)*

### BuildKit
Docker's enhanced build engine providing advanced features like parallel builds, cache mounts, and multi-architecture support.  
*→ Phase 02: BuildKit Advanced, Phase 08: CI/CD & Buildx*  
*See also: [Buildx](#buildx), [Multi-stage Builds](#multi-stage-builds)*

### Buildx
Docker CLI plugin for extended build capabilities, including multi-architecture builds and advanced BuildKit features.  
*→ Phase 08: CI/CD & Buildx*  
*See also: [BuildKit](#buildkit), [Multi-architecture Builds](#multi-architecture-builds)*

### Cache Mounts
BuildKit feature allowing build steps to mount persistent cache directories, dramatically improving build times for package managers.  
*→ Phase 02: BuildKit Advanced*  
*See also: [Build Cache](#build-cache), [BuildKit](#buildkit)*

### Multi-stage Builds
Dockerfile technique using multiple FROM instructions to create complex build pipelines, typically separating build and runtime environments.  
*→ Phase 02: BuildKit Advanced*  
*See also: [Dockerfile](#dockerfile), [Build Performance](#build-performance)*

### Secret Mounts
BuildKit feature for securely providing secrets during builds without exposing them in the final image or build cache.  
*→ Phase 02: BuildKit Advanced*  
*See also: [BuildKit](#buildkit), [Security](#security-concepts)*

---

## 🐳 Container Runtime

### CMD
Dockerfile instruction specifying the default command to run when a container starts. Can be overridden by command-line arguments.  
*→ Phase 01: Dockerfile Basics*  
*See also: [ENTRYPOINT](#entrypoint), [Container Lifecycle](#container-lifecycle)*

### ENTRYPOINT
Dockerfile instruction defining the fixed command that always runs when a container starts. Arguments become parameters to the entrypoint.  
*→ Phase 01: Dockerfile Basics*  
*See also: [CMD](#cmd), [Signal Handling](#signal-handling)*

### ENV (Environment Variables)
Dockerfile instruction and runtime mechanism for setting environment variables accessible to container processes.  
*→ Phase 01: Dockerfile Basics, Phase 06: Compose*  
*See also: [ARG](#arg-build-argument), [Secrets Management](#secrets-management)*

### EXPOSE
Dockerfile instruction documenting which ports a container listens on. Does not actually publish ports.  
*→ Phase 01: Dockerfile Basics, Phase 04: Networking*  
*See also: [Port Publishing](#port-publishing), [Networking](#networking-concepts)*

### Health Checks
Mechanism to determine if a container is functioning correctly by running periodic test commands.  
*→ Phase 03: Container Operations*  
*See also: [Container Lifecycle](#container-lifecycle), [Restart Policies](#restart-policies)*

### Init Process
PID 1 process inside a container responsible for signal handling and zombie process reaping. Critical for proper container behavior.  
*→ Phase 03: Container Operations*  
*See also: [Signal Handling](#signal-handling), [Zombie Processes](#zombie-processes)*

### Resource Limits
Constraints on CPU, memory, and other resources that a container can consume, preventing resource exhaustion.  
*→ Phase 03: Container Operations*  
*See also: [cgroups](#cgroups), [Container Isolation](#container-isolation)*

### Restart Policies
Rules governing when and how containers should be automatically restarted after exits or failures.  
*→ Phase 03: Container Operations*  
*See also: [Health Checks](#health-checks), [Container Lifecycle](#container-lifecycle)*

### Signal Handling
Process management technique for containers to respond gracefully to termination signals (SIGTERM, SIGKILL).  
*→ Phase 03: Container Operations*  
*See also: [Init Process](#init-process), [Graceful Shutdown](#graceful-shutdown)*

---

## 🌐 Networking Concepts

### Bridge Network
Default Docker network driver creating an isolated network segment for containers with NAT-based external access.  
*→ Phase 04: Networking*  
*See also: [Host Network](#host-network), [User-defined Networks](#user-defined-networks)*

### Container DNS
Docker's built-in DNS resolution allowing containers to communicate using container names instead of IP addresses.  
*→ Phase 04: Networking*  
*See also: [Service Discovery](#service-discovery), [User-defined Networks](#user-defined-networks)*

### Host Network
Network mode where containers share the host's network stack, providing maximum performance at the cost of isolation.  
*→ Phase 04: Networking*  
*See also: [Bridge Network](#bridge-network), [Network Isolation](#network-isolation)*

### Network Isolation
Security principle of separating containers into distinct network segments to limit communication and reduce attack surfaces.  
*→ Phase 04: Networking*  
*See also: [User-defined Networks](#user-defined-networks), [Security](#security-concepts)*

### Port Publishing
Mechanism for making container ports accessible from the host system using `-p` or `--publish` flags.  
*→ Phase 04: Networking*  
*See also: [EXPOSE](#expose), [Bridge Network](#bridge-network)*

### Service Discovery
Mechanism allowing containers to find and communicate with each other using predictable names rather than IP addresses.  
*→ Phase 04: Networking, Phase 06: Compose*  
*See also: [Container DNS](#container-dns), [Docker Compose](#docker-compose)*

### User-defined Networks
Custom Docker networks providing better isolation, automatic DNS resolution, and advanced networking features compared to the default bridge.  
*→ Phase 04: Networking*  
*See also: [Bridge Network](#bridge-network), [Network Isolation](#network-isolation)*

---

## 💾 Storage and Data

### Anonymous Volumes
Docker-managed storage volumes created automatically when no name is specified, typically for temporary data.  
*→ Phase 05: Storage & Volumes*  
*See also: [Named Volumes](#named-volumes), [Bind Mounts](#bind-mounts)*

### Bind Mounts
Direct mapping of host filesystem paths into containers, providing real-time synchronization between host and container.  
*→ Phase 05: Storage & Volumes*  
*See also: [Named Volumes](#named-volumes), [Volume Permissions](#volume-permissions)*

### Data Persistence
Strategy for maintaining container data beyond container lifecycle, typically through volumes or external storage systems.  
*→ Phase 05: Storage & Volumes*  
*See also: [Stateful vs Stateless](#stateful-vs-stateless), [Backup Strategies](#backup-strategies)*

### Named Volumes
Docker-managed storage volumes with human-readable names, providing persistent data storage with better portability than bind mounts.  
*→ Phase 05: Storage & Volumes*  
*See also: [Anonymous Volumes](#anonymous-volumes), [Volume Drivers](#volume-drivers)*

### tmpfs Mounts
Memory-based temporary storage for containers, providing high performance for temporary files that should not persist.  
*→ Phase 05: Storage & Volumes*  
*See also: [Named Volumes](#named-volumes), [Performance Optimization](#performance-optimization)*

### Volume Drivers
Pluggable storage backends for Docker volumes, enabling integration with various storage systems (NFS, AWS EBS, etc.).  
*→ Phase 05: Storage & Volumes*  
*See also: [Named Volumes](#named-volumes), [External Storage](#external-storage)*

### Volume Permissions
Access control mechanisms for shared storage between host and container, particularly important on Linux systems.  
*→ Phase 05: Storage & Volumes*  
*See also: [Bind Mounts](#bind-mounts), [User Mapping](#user-mapping)*

---

## 📦 Docker Compose

### Docker Compose
Tool for defining and running multi-container Docker applications using YAML configuration files.  
*→ Phase 06: Compose*  
*See also: [Service Definition](#service-definition), [Compose Profiles](#compose-profiles)*

### Compose Profiles
Feature allowing selective activation of services within a Compose file, enabling environment-specific deployments.  
*→ Phase 06: Compose*  
*See also: [Environment Variables](#environment-variables), [Service Definition](#service-definition)*

### depends_on
Compose configuration specifying service startup order dependencies, though it doesn't guarantee readiness.  
*→ Phase 06: Compose*  
*See also: [Health Checks](#health-checks), [Service Readiness](#service-readiness)*

### Service Definition
Compose YAML section defining how to run a specific container, including image, ports, volumes, and other runtime configuration.  
*→ Phase 06: Compose*  
*See also: [Docker Compose](#docker-compose), [Compose Networks](#compose-networks)*

### Service Readiness
Pattern ensuring services are fully functional before dependent services start, typically implemented through health checks.  
*→ Phase 06: Compose*  
*See also: [Health Checks](#health-checks), [depends_on](#depends_on)*

---

## 🔒 Security Concepts

### Capabilities
Linux kernel feature providing fine-grained permissions for containers, allowing privilege escalation without full root access.  
*→ Phase 07: Security*  
*See also: [Non-root Users](#non-root-users), [Principle of Least Privilege](#principle-of-least-privilege)*

### Container Escape
Security vulnerability where processes break out of container isolation to access the host system.  
*→ Phase 07: Security*  
*See also: [Container Isolation](#container-isolation), [Security Hardening](#security-hardening)*

### Container Isolation
Security foundation providing separation between containers and the host through namespaces, cgroups, and other kernel features.  
*→ Phase 07: Security*  
*See also: [Namespaces](#namespaces), [cgroups](#cgroups)*

### Image Scanning
Security practice of analyzing container images for known vulnerabilities, malware, and policy violations.  
*→ Phase 07: Security, Phase 11: Advanced Images*  
*See also: [CVE](#cve), [Security Hardening](#security-hardening)*

### Non-root Users
Security practice of running container processes as unprivileged users rather than root, reducing attack impact.  
*→ Phase 07: Security*  
*See also: [Capabilities](#capabilities), [Principle of Least Privilege](#principle-of-least-privilege)*

### Read-only Root Filesystem
Security hardening technique making the container's root filesystem immutable, preventing runtime modifications.  
*→ Phase 07: Security*  
*See also: [tmpfs Mounts](#tmpfs-mounts), [Security Hardening](#security-hardening)*

### Secrets Management
Secure handling of sensitive data (passwords, API keys, certificates) in containerized environments.  
*→ Phase 06: Compose, Phase 07: Security*  
*See also: [Environment Variables](#environment-variables), [Secret Mounts](#secret-mounts)*

### Security Hardening
Process of reducing attack surfaces and vulnerabilities through configuration, minimal images, and security best practices.  
*→ Phase 07: Security*  
*See also: [Distroless Images](#distroless-images), [Principle of Least Privilege](#principle-of-least-privilege)*

---

## 🚀 CI/CD and Automation

### Continuous Integration (CI)
Development practice of automatically building, testing, and validating code changes, often including container image creation.  
*→ Phase 08: CI/CD & Buildx*  
*See also: [Automated Builds](#automated-builds), [Image Registries](#image-registries)*

### Multi-architecture Builds
Technique for creating container images that run natively on different CPU architectures (AMD64, ARM64, etc.).  
*→ Phase 08: CI/CD & Buildx, Phase 11: Advanced Images*  
*See also: [Buildx](#buildx), [Cross-compilation](#cross-compilation)*

### SBOM (Software Bill of Materials)
Inventory of software components and dependencies in a container image, essential for security and compliance.  
*→ Phase 08: CI/CD & Buildx, Phase 11: Advanced Images*  
*See also: [Supply Chain Security](#supply-chain-security), [Image Scanning](#image-scanning)*

### Supply Chain Security
Security practices ensuring the integrity and authenticity of software components throughout the development and deployment pipeline.  
*→ Phase 08: CI/CD & Buildx, Phase 11: Advanced Images*  
*See also: [Image Signing](#image-signing), [SBOM](#sbom-software-bill-of-materials)*

---

## 📊 Observability and Monitoring

### Container Logs
Output from container processes, essential for debugging and monitoring application behavior.  
*→ Phase 10: Observability*  
*See also: [Logging Drivers](#logging-drivers), [Log Aggregation](#log-aggregation)*

### Distributed Tracing
Observability technique tracking requests across multiple services to understand system behavior and performance.  
*→ Phase 10: Observability*  
*See also: [Microservices](#microservices), [Performance Monitoring](#performance-monitoring)*

### Health Metrics
Quantitative measurements of container and application performance, including CPU, memory, network, and custom application metrics.  
*→ Phase 10: Observability*  
*See also: [Resource Monitoring](#resource-monitoring), [Performance Budgets](#performance-budgets)*

### Log Aggregation
Practice of collecting, centralizing, and analyzing logs from multiple containers and services.  
*→ Phase 10: Observability*  
*See also: [Container Logs](#container-logs), [Logging Drivers](#logging-drivers)*

### Logging Drivers
Docker's pluggable logging backend system supporting various destinations (files, syslog, cloud services).  
*→ Phase 10: Observability*  
*See also: [Container Logs](#container-logs), [Log Aggregation](#log-aggregation)*

### Metrics Collection
Systematic gathering of performance and operational data from containers and applications for monitoring and alerting.  
*→ Phase 10: Observability*  
*See also: [Health Metrics](#health-metrics), [Performance Monitoring](#performance-monitoring)*

### Performance Budgets
Predefined limits for performance metrics (response time, resource usage) used to maintain system performance standards.  
*→ Phase 10: Observability*  
*See also: [SLI/SLO](#slislo), [Performance Monitoring](#performance-monitoring)*

---

## 🏗️ Advanced Image Techniques

### CVE (Common Vulnerabilities and Exposures)
Standardized identifiers for publicly known security vulnerabilities, crucial for container security assessment.  
*→ Phase 11: Advanced Images*  
*See also: [Image Scanning](#image-scanning), [Vulnerability Management](#vulnerability-management)*

### Distroless Images
Minimal container images containing only application and runtime dependencies, excluding package managers and shells.  
*→ Phase 11: Advanced Images*  
*See also: [Scratch Image](#scratch-image), [Security Hardening](#security-hardening)*

### Image Signing
Cryptographic technique for ensuring container image authenticity and integrity using digital signatures.  
*→ Phase 11: Advanced Images*  
*See also: [Supply Chain Security](#supply-chain-security), [Container Registry Security](#container-registry-security)*

### Scratch Image
Empty base image containing no operating system files, used for statically-linked binaries requiring minimal attack surface.  
*→ Phase 11: Advanced Images*  
*See also: [Static Linking](#static-linking), [Distroless Images](#distroless-images)*

### Static Linking
Compilation technique producing self-contained binaries with all dependencies embedded, enabling scratch-based images.  
*→ Phase 11: Advanced Images*  
*See also: [Scratch Image](#scratch-image), [Dynamic Linking](#dynamic-linking)*

---

## 💻 System-Level Concepts

### cgroups (Control Groups)
Linux kernel feature for resource management and limitation, fundamental to container resource isolation.  
*→ Phase 03: Container Operations*  
*See also: [Resource Limits](#resource-limits), [Container Isolation](#container-isolation)*

### Container Runtime
Low-level software responsible for container execution, with examples including containerd, CRI-O, and Docker's runtime.  
*→ Phase 00: Foundations*  
*See also: [Docker Daemon](#docker-daemon), [OCI](#oci-open-container-initiative)*

### Docker Daemon
Background service managing Docker containers, images, networks, and volumes on a host system.  
*→ Phase 00: Foundations*  
*See also: [Docker Client](#docker-client), [Container Runtime](#container-runtime)*

### Docker Client
Command-line interface and API client for communicating with the Docker daemon.  
*→ Phase 00: Foundations*  
*See also: [Docker Daemon](#docker-daemon), [Docker API](#docker-api)*

### Namespaces
Linux kernel feature providing process isolation by giving containers their own view of system resources.  
*→ Phase 07: Security*  
*See also: [Container Isolation](#container-isolation), [cgroups](#cgroups-control-groups)*

### OCI (Open Container Initiative)
Industry standards for container formats and runtimes, ensuring compatibility across different container technologies.  
*→ Phase 00: Foundations*  
*See also: [Container Runtime](#container-runtime), [Image Format](#image-format)*

---

## 🔗 Cross-References by Phase

### Phase 00: Foundations
[Container](#container) • [Image](#image) • [Container Lifecycle](#container-lifecycle) • [Image Tags](#image-tags) • [Digest](#digest) • [Registry](#registry) • [Docker Daemon](#docker-daemon) • [Docker Client](#docker-client)

### Phase 01: Dockerfile Basics  
[Dockerfile](#dockerfile) • [Base Image](#base-image) • [Build Context](#build-context) • [.dockerignore](#dockerignore) • [CMD](#cmd) • [ENTRYPOINT](#entrypoint) • [ENV](#env-environment-variables) • [EXPOSE](#expose)

### Phase 02: BuildKit Advanced
[BuildKit](#buildkit) • [Multi-stage Builds](#multi-stage-builds) • [Cache Mounts](#cache-mounts) • [Secret Mounts](#secret-mounts) • [ARG](#arg-build-argument) • [Build Cache](#build-cache)

### Phase 03: Container Operations
[Health Checks](#health-checks) • [Restart Policies](#restart-policies) • [Resource Limits](#resource-limits) • [Signal Handling](#signal-handling) • [Init Process](#init-process) • [cgroups](#cgroups-control-groups)

### Phase 04: Networking
[Bridge Network](#bridge-network) • [Host Network](#host-network) • [User-defined Networks](#user-defined-networks) • [Port Publishing](#port-publishing) • [Service Discovery](#service-discovery) • [Network Isolation](#network-isolation)

### Phase 05: Storage & Volumes
[Named Volumes](#named-volumes) • [Bind Mounts](#bind-mounts) • [Anonymous Volumes](#anonymous-volumes) • [tmpfs Mounts](#tmpfs-mounts) • [Volume Permissions](#volume-permissions) • [Data Persistence](#data-persistence)

### Phase 06: Compose
[Docker Compose](#docker-compose) • [Service Definition](#service-definition) • [Compose Profiles](#compose-profiles) • [depends_on](#depends_on) • [Service Readiness](#service-readiness) • [Secrets Management](#secrets-management)

### Phase 07: Security
[Non-root Users](#non-root-users) • [Capabilities](#capabilities) • [Read-only Root Filesystem](#read-only-root-filesystem) • [Image Scanning](#image-scanning) • [Security Hardening](#security-hardening) • [Container Isolation](#container-isolation)

### Phase 08: CI/CD & Buildx
[Buildx](#buildx) • [Multi-architecture Builds](#multi-architecture-builds) • [SBOM](#sbom-software-bill-of-materials) • [Supply Chain Security](#supply-chain-security) • [Continuous Integration](#continuous-integration)

### Phase 09: Registries
[Registry](#registry) • [Repository](#repository) • [Image Tags](#image-tags) • [Digest](#digest) • [Registry Authentication](#registry-authentication) • [Registry Mirroring](#registry-mirroring)

### Phase 10: Observability
[Container Logs](#container-logs) • [Logging Drivers](#logging-drivers) • [Log Aggregation](#log-aggregation) • [Metrics Collection](#metrics-collection) • [Health Metrics](#health-metrics) • [Performance Budgets](#performance-budgets)

### Phase 11: Advanced Images
[Distroless Images](#distroless-images) • [Scratch Image](#scratch-image) • [Static Linking](#static-linking) • [Image Signing](#image-signing) • [CVE](#cve-common-vulnerabilities-and-exposures) • [Multi-architecture Builds](#multi-architecture-builds)

---

*Last updated: 2025-01-09 | Cross-references: 150+ terms across 12 phases*