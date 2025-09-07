# Phase 07: Docker Security

> **Implement comprehensive container security hardening and vulnerability management practices**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Configure non-root users and proper user namespace mapping
- Implement capability dropping and privilege restriction
- Secure containers with read-only filesystems and minimal attack surface
- Perform vulnerability scanning and security auditing of container images
- Apply security best practices for production container deployments
- Troubleshoot common security misconfigurations and vulnerabilities

## 📚 Concept Map

```
Docker Security Hardening
├── User & Permission Management
│   ├── Non-root User Configuration
│   ├── User Namespace Mapping
│   ├── UID/GID Mapping Strategies
│   └── File System Permission Control
├── Capability & Privilege Management  
│   ├── Linux Capabilities Overview
│   ├── Capability Dropping Strategies
│   ├── Privileged vs Unprivileged Containers
│   └── Security Context Configuration
├── Filesystem & Runtime Security
│   ├── Read-only Root Filesystems
│   ├── Temporary Filesystem Management
│   ├── Volume Security Considerations
│   └── Runtime Security Policies (AppArmor/SELinux)
├── Image Security & Scanning
│   ├── Base Image Selection Criteria
│   ├── Vulnerability Scanning Integration
│   ├── Image Signing and Verification
│   └── Supply Chain Security
└── Production Security Patterns
    ├── Network Security (Zero Trust)
    ├── Secrets Management Integration
    ├── Security Monitoring and Alerting
    └── Compliance and Audit Frameworks
```

## 🔬 Core Topics

### 1. User and Permission Management

**Running Containers as Non-Root**

The principle of least privilege requires running containers with the minimum permissions necessary. Most container images default to running as root, creating unnecessary security risks.

```dockerfile
# Insecure - runs as root by default
FROM node:18
COPY app.js /app/
CMD ["node", "/app/app.js"]

# Secure - explicit non-root user
FROM node:18
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
COPY --chown=appuser:appgroup app.js /app/
USER appuser
CMD ["node", "/app/app.js"]
```

**User Namespace Mapping**

User namespaces provide isolation by mapping container users to different host users:

```bash
# Enable user namespace remapping in Docker daemon
echo '{
  "userns-remap": "default"
}' | sudo tee /etc/docker/daemon.json

# Restart Docker daemon
sudo systemctl restart docker

# Verify user namespace is active
docker info | grep "Security Options"
```

**Advanced User Configuration**

```dockerfile
# Multi-stage build with security-focused user setup
FROM alpine:3.18 AS security-base
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S -G appgroup -h /app -s /sbin/nologin appuser

FROM security-base AS runtime
COPY --from=build --chown=appuser:appgroup /dist/app /app/
USER 10001:10001
WORKDIR /app
CMD ["./app"]
```

### 2. Linux Capabilities Management

**Understanding Linux Capabilities**

Linux capabilities divide root privileges into distinct units, allowing fine-grained permission control:

```bash
# View default Docker capabilities
docker run --rm alpine:3.18 capsh --print

# Common risky capabilities to drop:
# - CAP_NET_RAW (raw socket creation)
# - CAP_SYS_ADMIN (system administration)
# - CAP_DAC_OVERRIDE (file permission override)
```

**Capability Dropping Strategies**

```dockerfile
# Dockerfile approach
FROM alpine:3.18
RUN apk add --no-cache curl
USER 1000
# Runtime capability dropping happens at container start
```

```bash
# Runtime capability management
docker run --rm \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=100m \
  nginx:alpine

# Docker Compose capability management
version: '3.8'
services:
  webapp:
    image: myapp:latest
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if binding to privileged ports
    security_opt:
      - no-new-privileges:true
```

**Security Context Configuration**

```yaml
# Comprehensive security context
version: '3.8'

services:
  secure-app:
    image: myapp:latest
    user: "10001:10001"
    read_only: true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
      - seccomp:unconfined  # Only if needed
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run:noexec,nosuid,size=10m
    volumes:
      - app-cache:/app/cache:rw
      - app-logs:/var/log/app:rw
```

### 3. Read-Only Filesystems and Runtime Security

**Implementing Read-Only Root Filesystem**

```dockerfile
# Application designed for read-only filesystem
FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs && \
    mkdir -p /app/cache /app/logs /app/tmp && \
    chown -R nodejs:nodejs /app
    
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --chown=nodejs:nodejs . .
USER nodejs

# These directories will be mounted as tmpfs or volumes
VOLUME ["/app/cache", "/app/logs", "/app/tmp"]
```

```bash
# Runtime read-only configuration
docker run -d \
  --name secure-app \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=100m \
  --tmpfs /var/run:noexec,nosuid,size=10m \
  -v app-cache:/app/cache \
  -v app-logs:/app/logs \
  myapp:secure
```

**AppArmor and SELinux Integration**

```bash
# Create custom AppArmor profile
sudo tee /etc/apparmor.d/docker-myapp <<EOF
#include <tunables/global>

profile docker-myapp flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  
  network inet tcp,
  network inet udp,
  
  deny @{PROC}/* w,
  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/firmware/** rwklx,
  deny /sys/kernel/security/** rwklx,
}
EOF

# Load the profile
sudo apparmor_parser -r -W /etc/apparmor.d/docker-myapp

# Use with Docker
docker run --security-opt apparmor=docker-myapp myapp:latest
```

### 4. Image Security and Vulnerability Scanning

**Secure Base Image Selection**

```dockerfile
# Comparison of base image security
# Alpine (minimal, security-focused)
FROM alpine:3.18
RUN apk add --no-cache nodejs npm

# Distroless (Google's minimal images)
FROM gcr.io/distroless/nodejs18-debian11
COPY app.js /app.js
CMD ["app.js"]

# Ubuntu minimal (if full OS features needed)
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs npm && \
    rm -rf /var/lib/apt/lists/*
```

**Vulnerability Scanning Integration**

```bash
# Using Docker Scout (built-in)
docker scout cves myapp:latest
docker scout recommendations myapp:latest

# Using Trivy
trivy image myapp:latest
trivy image --severity HIGH,CRITICAL myapp:latest

# Using Grype
grype myapp:latest

# Using Clair (via CLI)
clairctl analyze myapp:latest
```

**Multi-stage Security Build**

```dockerfile
# Security-focused multi-stage build
FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Minimal runtime with security hardening
FROM gcr.io/distroless/nodejs18-debian11 AS runtime
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./

# Distroless runs as non-root by default (user nobody)
EXPOSE 3000
CMD ["dist/main.js"]
```

**Image Signing and Verification**

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Sign images during push
docker push myregistry.com/myapp:v1.0.0

# Verify signatures during pull
docker pull myregistry.com/myapp:v1.0.0

# Using Cosign for advanced signing
cosign sign --key cosign.key myregistry.com/myapp:v1.0.0
cosign verify --key cosign.pub myregistry.com/myapp:v1.0.0
```

## 🔍 Security Patterns & Best Practices

### Pattern 1: Minimal Attack Surface Container

```dockerfile
# Ultra-minimal security container
FROM scratch
COPY ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/static-binary /app
USER 65534:65534  # nobody:nobody
EXPOSE 8080
ENTRYPOINT ["/app"]
```

### Pattern 2: Defense in Depth

```yaml
# docker-compose.security.yml
version: '3.8'

services:
  webapp:
    image: myapp:hardened
    user: "10001:10001"
    read_only: true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-myapp
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    sysctls:
      - net.ipv4.ip_unprivileged_port_start=0
    ulimits:
      nproc: 65535
      nofile:
        soft: 20000
        hard: 40000
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

networks:
  app-network:
    driver: bridge
    driver_opts:
      encrypted: "true"
```

### Pattern 3: Security Monitoring

```yaml
# Security monitoring stack
version: '3.8'

services:
  # Main application with security monitoring
  webapp:
    image: myapp:latest
    labels:
      - "security.scan=enabled"
      - "monitoring.metrics=true"
    logging:
      driver: syslog
      options:
        syslog-address: "tcp://security-logs:514"
        tag: "webapp"

  # Security event monitoring
  falco:
    image: falcosecurity/falco:latest
    privileged: true
    volumes:
      - /var/run/docker.sock:/host/var/run/docker.sock
      - /dev:/host/dev
      - /proc:/host/proc:ro
      - /boot:/host/boot:ro
      - /lib/modules:/host/lib/modules:ro
      - /usr:/host/usr:ro
      - /etc:/host/etc:ro
    command:
      - falco
      - --cri
      - /usr/bin/docker

  # Log aggregation for security analysis
  security-logs:
    image: fluent/fluent-bit:latest
    volumes:
      - ./fluent-bit-security.conf:/fluent-bit/etc/fluent-bit.conf
    ports:
      - "514:514"
```

## 💡 Production Security Considerations

### Network Security Implementation

```yaml
# Zero-trust network configuration
version: '3.8'

services:
  # Frontend (DMZ network)
  frontend:
    image: nginx:alpine
    networks:
      - dmz
      - app-tier
    ports:
      - "443:443"
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

  # Application (internal network only)
  backend:
    image: myapp:latest
    networks:
      - app-tier
      - data-tier
    # No external ports exposed
    cap_drop:
      - ALL

  # Database (most restricted network)
  database:
    image: postgres:15-alpine
    networks:
      - data-tier  # Only accessible by backend
    cap_drop:
      - ALL
    cap_add:
      - SETUID
      - SETGID

networks:
  dmz:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.1.0/24
  app-tier:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.2.0/24
  data-tier:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.3.0/24
```

### Secrets and Configuration Security

```bash
# Docker secrets with rotation
#!/bin/bash

# Rotate database password
NEW_PASSWORD=$(openssl rand -base64 32)
echo "$NEW_PASSWORD" | docker secret create db_password_v$(date +%s) -

# Update service to use new secret
docker service update --secret-rm db_password_old --secret-add db_password_new myapp_db

# Remove old secret after successful update
docker secret rm db_password_old
```

### Security Auditing and Compliance

```bash
# Docker Bench Security audit
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
sudo sh docker-bench-security.sh

# CIS Kubernetes Benchmark (if using Kubernetes)
docker run --rm -v /etc:/etc:ro -v /var:/var:ro \
  aquasec/kube-bench:latest run --targets node

# Custom security audit script
#!/bin/bash
echo "=== Docker Security Audit ==="

echo "1. Checking for privileged containers..."
docker ps --format "table {{.Names}}\t{{.Status}}" --filter="status=running" | \
  xargs -I {} docker inspect {} | grep -i "privileged.*true" || echo "✓ No privileged containers"

echo "2. Checking for containers running as root..."
docker ps -q | xargs docker inspect | \
  jq -r '.[] | select(.Config.User == "" or .Config.User == "root" or .Config.User == "0") | .Name'

echo "3. Checking image vulnerabilities..."
docker images --format "{{.Repository}}:{{.Tag}}" | \
  head -5 | xargs -I {} trivy image --severity HIGH,CRITICAL {}
```

## 🚨 Common Security Issues and Solutions

### Issue 1: Container Breakout Vulnerabilities

**Problem**: Containers running with excessive privileges
```bash
# Dangerous - full host access
docker run --privileged -v /:/host ubuntu:latest
```

**Solution**: Minimal privilege configuration
```bash
# Secure - minimal required privileges
docker run --read-only --cap-drop ALL --user 1000:1000 ubuntu:latest
```

### Issue 2: Secrets in Images

**Problem**: Hardcoded secrets in Dockerfile
```dockerfile
# Insecure - secrets in image layers
FROM alpine
RUN echo "API_KEY=secret123" >> /app/.env
```

**Solution**: Runtime secret injection
```dockerfile
FROM alpine
# No secrets in image
```
```bash
# Secrets provided at runtime
docker run -e API_KEY_FILE=/run/secrets/api_key myapp:latest
```

### Issue 3: Vulnerable Base Images

**Problem**: Using outdated or vulnerable base images
```bash
# Check image age and vulnerabilities
docker scout cves ubuntu:18.04  # Old version with many CVEs
```

**Solution**: Regular base image updates and scanning
```bash
# Use recent, maintained images
docker scout cves ubuntu:22.04  # Recent version, fewer CVEs
trivy image --severity HIGH,CRITICAL ubuntu:22.04
```

## Micro-Lessons

### Micro-Lesson 1: Non-Root User Configuration and User Namespace Mapping (4 minutes)
**Anchor**: `p07-m01-l01`

**Objective**: Master non-root user configuration and user namespace mapping for container isolation.

**Key Concepts**:
- Non-root user creation and configuration
- User namespace remapping for security isolation
- UID/GID mapping strategies
- File permission security implications

**Hands-On**:
```dockerfile
# Insecure: Default root user
FROM node:18-alpine
WORKDIR /app
COPY app.js .
CMD ["node", "app.js"]

# Secure: Explicit non-root user
FROM node:18-alpine

# Create dedicated user with specific UID/GID
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 -G appgroup -h /app -s /sbin/nologin appuser

# Setup application with proper ownership
RUN mkdir -p /app && chown -R appuser:appgroup /app
USER appuser
WORKDIR /app

COPY --chown=appuser:appgroup app.js .
CMD ["node", "app.js"]
```

**User Namespace Configuration**:
```bash
# Configure Docker daemon for user namespace remapping
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "userns-remap": "default"
}
EOF

# Setup subuid/subgid mappings
echo "dockremap:165536:65536" | sudo tee -a /etc/subuid
echo "dockremap:165536:65536" | sudo tee -a /etc/subgid

# Restart Docker daemon
sudo systemctl restart docker
```

**Verification Commands**:
```bash
# Test user isolation
docker run --rm myapp:secure whoami  # Should show appuser, not root
docker run --rm myapp:secure id      # Should show UID 1001, not 0

# Test file permission restrictions
docker run --rm myapp:secure touch /etc/test.txt  # Should fail with permission denied
```

**Production Notes**:
- Use consistent UID/GID across environments for volume compatibility
- Consider using numeric UIDs (e.g., 1001:1001) for better portability
- Test file system permissions with mounted volumes
- User namespace remapping affects volume ownership on host

---

### Micro-Lesson 2: Linux Capabilities and Privilege Management (5 minutes)
**Anchor**: `p07-m01-l02`

**Objective**: Implement fine-grained privilege control using Linux capabilities and security contexts.

**Key Concepts**:
- Linux capabilities vs traditional root privileges
- Capability dropping strategies
- Security context configuration
- No-new-privileges security option

**Hands-On**:
```bash
# Check default Docker capabilities
docker run --rm alpine:3.18 sh -c 'apk add libcap && capsh --print'

# Drop all capabilities (maximum security)
docker run --rm --cap-drop ALL alpine:3.18 ping 8.8.8.8  # Should fail

# Minimal capabilities (only what's needed)
docker run --rm \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --user 1001:1001 \
  nginx:alpine

# Test capability restrictions
docker run --rm --cap-drop NET_RAW alpine:3.18 ping 8.8.8.8  # Should fail without NET_RAW
```

**Docker Compose Security Configuration**:
```yaml
version: '3.8'

services:
  secure-app:
    image: myapp:latest
    user: "1001:1001"
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if binding to ports < 1024
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=50m
```

**Advanced Security Testing**:
```bash
# Test privilege escalation prevention
docker run --rm --security-opt no-new-privileges:true alpine:3.18 su -  # Should fail

# Verify no dangerous capabilities
docker run --rm --cap-drop SYS_ADMIN alpine:3.18 mount -t tmpfs none /mnt  # Should fail
```

**Production Notes**:
- Always use `--cap-drop ALL` as starting point, then add only required capabilities
- NET_BIND_SERVICE needed only for ports < 1024
- Avoid CAP_SYS_ADMIN (system administration) and CAP_DAC_OVERRIDE (bypass file permissions)
- Use security-opt no-new-privileges:true to prevent privilege escalation

---

### Micro-Lesson 3: Read-Only Filesystems and Runtime Security (4 minutes)
**Anchor**: `p07-m01-l03`

**Objective**: Implement read-only root filesystems with secure temporary storage and runtime security policies.

**Key Concepts**:
- Read-only root filesystem benefits
- Secure tmpfs configuration
- Volume vs tmpfs for writable areas
- AppArmor/SELinux integration

**Hands-On**:
```dockerfile
# Application optimized for read-only filesystem
FROM node:18-alpine

RUN adduser -D -u 1001 appuser && \
    mkdir -p /app/cache /app/logs /app/tmp && \
    chown -R appuser:appuser /app

# Copy application files
COPY --chown=appuser:appuser package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --chown=appuser:appuser . .

USER appuser
WORKDIR /app

# Mark writable directories as volumes
VOLUME ["/app/cache", "/app/logs", "/app/tmp"]

CMD ["node", "server.js"]
```

**Runtime Configuration**:
```bash
# Read-only with secure tmpfs
docker run -d \
  --name secure-app \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,nodev,size=50m \
  --tmpfs /app/cache:size=20m \
  --tmpfs /app/logs:size=10m \
  --user 1001:1001 \
  myapp:readonly

# Test filesystem restrictions
docker exec secure-app touch /test.txt          # Should fail (read-only root)
docker exec secure-app touch /tmp/test.txt      # Should succeed (tmpfs)
docker exec secure-app touch /app/cache/test    # Should succeed (writable area)
```

**Docker Compose Implementation**:
```yaml
version: '3.8'

services:
  app:
    image: myapp:readonly
    user: "1001:1001"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,nodev,size=50m
      - /app/cache:size=20m
      - /app/logs:size=10m
    volumes:
      - app-data:/app/data  # Persistent data
    security_opt:
      - apparmor:docker-default

volumes:
  app-data:
```

**Security Verification**:
```bash
# Verify read-only enforcement
docker run --rm --read-only alpine:3.18 touch /test.txt  # Should fail

# Test tmpfs security options
docker run --rm --tmpfs /tmp:noexec alpine:3.18 sh -c 'echo "#!/bin/sh\necho test" > /tmp/script.sh && chmod +x /tmp/script.sh && /tmp/script.sh'  # Should fail with noexec
```

**Production Notes**:
- Read-only root filesystem prevents malware persistence and system file tampering
- Use tmpfs with noexec,nosuid,nodev for security
- Size-limit tmpfs to prevent DoS attacks
- Consider using persistent volumes for application data that must survive container restarts

---

### Micro-Lesson 4: Image Security and Vulnerability Management (5 minutes)
**Anchor**: `p07-m01-l04`

**Objective**: Implement comprehensive image security through vulnerability scanning and supply chain security.

**Key Concepts**:
- Secure base image selection criteria
- Vulnerability scanning integration
- Multi-stage builds for security
- Image signing and verification

**Hands-On**:
```dockerfile
# Vulnerable base image (DON'T USE)
FROM ubuntu:18.04
RUN apt-get update && apt-get install -y python3 python3-pip curl wget git
COPY app.py /app.py
CMD ["python3", "/app.py"]

# Secure minimal base image (RECOMMENDED)
FROM python:3.11-alpine
RUN adduser -D -u 1001 appuser
COPY --chown=appuser:appuser requirements.txt /app/
WORKDIR /app
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=appuser:appuser app.py .
USER appuser
CMD ["python", "app.py"]

# Ultra-secure distroless image (BEST)
FROM python:3.11-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3
COPY --from=builder /root/.local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY app.py /app/
WORKDIR /app
CMD ["app.py"]
```

**Vulnerability Scanning Pipeline**:
```bash
# Docker Scout (built-in)
docker scout cves myapp:latest --format json

# Trivy scanning
trivy image --severity HIGH,CRITICAL myapp:latest

# Compare base image security
echo "=== Ubuntu 18.04 ==="
docker scout cves ubuntu:18.04 --format sarif | jq '.runs[0].results | length'

echo "=== Alpine 3.18 ==="
docker scout cves alpine:3.18 --format sarif | jq '.runs[0].results | length'

echo "=== Distroless Python ==="
docker scout cves gcr.io/distroless/python3 --format sarif | jq '.runs[0].results | length'
```

**Automated Security Pipeline**:
```bash
#!/bin/bash
# security-gate.sh
IMAGE=$1
CRITICAL_THRESHOLD=0
HIGH_THRESHOLD=5

# Scan image
SCAN_RESULTS=$(docker scout cves "$IMAGE" --format json)

# Extract vulnerability counts
CRITICAL=$(echo "$SCAN_RESULTS" | jq '.vulnerabilities | map(select(.severity == "CRITICAL")) | length')
HIGH=$(echo "$SCAN_RESULTS" | jq '.vulnerabilities | map(select(.severity == "HIGH")) | length')

echo "Vulnerabilities found: Critical: $CRITICAL, High: $HIGH"

# Security gate decision
if [[ $CRITICAL -gt $CRITICAL_THRESHOLD ]]; then
    echo "❌ REJECT: $CRITICAL critical vulnerabilities (max: $CRITICAL_THRESHOLD)"
    exit 1
elif [[ $HIGH -gt $HIGH_THRESHOLD ]]; then
    echo "❌ REJECT: $HIGH high vulnerabilities (max: $HIGH_THRESHOLD)"
    exit 1
else
    echo "✅ APPROVE: Security scan passed"
    exit 0
fi
```

**Supply Chain Security**:
```bash
# Generate SBOM (Software Bill of Materials)
docker scout sbom myapp:latest --format json > sbom.json

# Enable Docker Content Trust for image signing
export DOCKER_CONTENT_TRUST=1

# Advanced signing with Cosign
cosign generate-key-pair
cosign sign --key cosign.key myregistry.com/myapp:v1.0.0
cosign verify --key cosign.pub myregistry.com/myapp:v1.0.0
```

**Production Notes**:
- Use minimal base images (Alpine, Distroless) to reduce attack surface
- Automate vulnerability scanning in CI/CD pipeline
- Set security gates: 0 critical, ≤5 high vulnerabilities
- Regularly update base images and dependencies
- Implement image signing for supply chain security
- Generate and maintain SBOM for compliance

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Configure containers to run as non-root users with proper user namespace mapping
- [ ] Implement capability dropping and privilege restriction effectively
- [ ] Deploy containers with read-only filesystems and secure runtime configurations
- [ ] Integrate vulnerability scanning into your container build and deployment pipeline
- [ ] Apply comprehensive security hardening for production container deployments
- [ ] Audit and monitor container security posture continuously

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p07-m01-l01` - Non-root User Configuration and User Namespace Mapping
- `p07-m01-l02` - Linux Capabilities and Privilege Management
- `p07-m01-l03` - Read-only Filesystems and Runtime Security
- `p07-m01-l04` - Image Security, Vulnerability Scanning, and Supply Chain Security

## 🎯 What's Next

After mastering Docker Security:
- **Phase 08**: CI/CD integration with automated security scanning
- **Phase 09**: Registry management with security policies
- **Phase 10**: Monitoring and observability with security focus

---

> 💡 **Key Insight**: Container security is not a single configuration but a layered approach combining user privileges, capability restrictions, filesystem security, image hygiene, and continuous monitoring. Each layer provides defense in depth, ensuring that a compromise in one area doesn't lead to complete system compromise.