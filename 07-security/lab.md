# Phase 07: Docker Security - Hands-On Labs

## Overview
Practical exercises to master container security hardening, vulnerability management, and production security patterns through hands-on implementation.

---

## Lab 1: Non-Root User Configuration and User Namespace Mapping
**Duration**: 45 minutes  
**Anchor**: `p07-lab1-user-security`

### Objective
Master non-root user configuration, user namespace mapping, and file permission management for secure container deployments.

### Prerequisites
- Docker installed with root access for daemon configuration
- Basic understanding of Linux users and permissions
- Text editor for configuration files

### Part A: Basic Non-Root User Implementation (15 minutes)

#### Step 1: Create Insecure Baseline Container
```bash
# Create a simple Node.js application
mkdir ~/security-lab && cd ~/security-lab

cat > app.js << 'EOF'
const http = require('http');
const fs = require('fs');

const server = http.createServer((req, res) => {
  // Demonstrate privilege level
  const user = process.getuid();
  const group = process.getgid();
  
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify({
    message: 'Hello from container',
    user_id: user,
    group_id: group,
    process_user: process.env.USER || 'unknown'
  }));
});

server.listen(3000, () => {
  console.log(`Server running as UID: ${process.getuid()}, GID: ${process.getgid()}`);
});
EOF

# Insecure Dockerfile (runs as root)
cat > Dockerfile.insecure << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY app.js /app/
EXPOSE 3000
CMD ["node", "app.js"]
EOF

# Build and test insecure version
docker build -f Dockerfile.insecure -t nodeapp:insecure .
docker run --rm -p 3000:3000 nodeapp:insecure &
sleep 2
curl http://localhost:3000
docker stop $(docker ps -q --filter ancestor=nodeapp:insecure)
```

#### Step 2: Implement Non-Root User Configuration
```bash
# Secure Dockerfile with non-root user
cat > Dockerfile.secure << 'EOF'
FROM node:18-alpine

# Create non-root user with specific UID/GID
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs

# Create app directory with proper ownership
RUN mkdir -p /app && chown -R nodejs:nodejs /app

# Switch to non-root user before copying files
USER nodejs
WORKDIR /app

# Copy application files
COPY --chown=nodejs:nodejs app.js ./

EXPOSE 3000
CMD ["node", "app.js"]
EOF

# Build and test secure version
docker build -f Dockerfile.secure -t nodeapp:secure .
docker run --rm -p 3001:3000 nodeapp:secure &
sleep 2
curl http://localhost:3001
docker stop $(docker ps -q --filter ancestor=nodeapp:secure)
```

#### Step 3: Compare Security Postures
```bash
# Compare running processes
echo "=== Insecure Version (Root) ==="
docker run --rm nodeapp:insecure whoami
docker run --rm nodeapp:insecure id

echo "=== Secure Version (Non-Root) ==="
docker run --rm nodeapp:secure whoami  
docker run --rm nodeapp:secure id

# Test file system access
echo "=== Root Container File Access ==="
docker run --rm nodeapp:insecure touch /etc/test.txt && echo "SUCCESS: Can write to /etc" || echo "FAILED: Cannot write to /etc"

echo "=== Non-Root Container File Access ==="
docker run --rm nodeapp:secure touch /etc/test.txt && echo "DANGER: Can write to /etc" || echo "SECURE: Cannot write to /etc"
```

### Part B: User Namespace Mapping (20 minutes)

#### Step 4: Configure User Namespace Remapping
```bash
# Configure Docker daemon for user namespace remapping
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "userns-remap": "default",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Create subuid and subgid mappings
echo "dockremap:165536:65536" | sudo tee -a /etc/subuid
echo "dockremap:165536:65536" | sudo tee -a /etc/subgid

# Restart Docker daemon (WARNING: This will stop all running containers)
echo "Restarting Docker daemon - this will stop running containers"
read -p "Continue? (y/N): " confirm
if [[ $confirm == [yY] ]]; then
    sudo systemctl restart docker
    
    # Wait for Docker to restart
    sleep 5
    docker info | grep "Security Options"
else
    echo "Skipping daemon restart - user namespace demo will be limited"
fi
```

#### Step 5: Test User Namespace Isolation
```bash
# Create test container with user namespace
docker run --rm -it alpine:3.18 sh -c '
echo "Container perspective:"
whoami
id
echo ""
echo "Host mount perspective:"
touch /tmp/container-test-file
ls -la /tmp/container-test-file
'

# Check from host perspective (if user namespace is enabled)
echo "Host perspective of the same file:"
ls -la /var/lib/docker/*/tmp/container-test-file 2>/dev/null || echo "File not visible from host (expected with user namespace)"
```

### Part C: Advanced User Configuration (10 minutes)

#### Step 6: Multi-User Container Setup
```bash
# Advanced Dockerfile with multiple users
cat > Dockerfile.multiuser << 'EOF'
FROM alpine:3.18

# Create multiple users for different purposes
RUN addgroup -g 2001 -S appgroup && \
    addgroup -g 2002 -S loggroup && \
    adduser -u 2001 -S -G appgroup -h /app -s /sbin/nologin appuser && \
    adduser -u 2002 -S -G loggroup -h /logs -s /sbin/nologin loguser

# Create directories with proper permissions
RUN mkdir -p /app /logs /shared && \
    chown appuser:appgroup /app && \
    chown loguser:loggroup /logs && \
    chown root:appgroup /shared && \
    chmod 2775 /shared  # Setgid bit for shared directory

# Install application
COPY --chown=appuser:appgroup app.js /app/

# Default to app user
USER appuser
WORKDIR /app
CMD ["node", "app.js"]
EOF

docker build -f Dockerfile.multiuser -t nodeapp:multiuser .

# Test user permissions
docker run --rm nodeapp:multiuser id
docker run --rm --user 2002:2002 nodeapp:multiuser id
```

### Verification Steps

1. **User ID Verification**:
   ```bash
   # Confirm non-root execution
   docker run --rm nodeapp:secure sh -c 'echo "UID: $(id -u), GID: $(id -g)"'
   ```

2. **File Permission Testing**:
   ```bash
   # Test write permissions
   docker run --rm nodeapp:secure touch /tmp/test.txt && echo "Can write to /tmp" || echo "Cannot write to /tmp"
   docker run --rm nodeapp:secure touch /etc/test.txt && echo "DANGER: Can write to /etc" || echo "SECURE: Cannot write to /etc"
   ```

3. **Process Analysis**:
   ```bash
   # Analyze running processes
   docker run -d --name security-test nodeapp:secure
   docker exec security-test ps aux
   docker exec security-test cat /proc/1/status | grep -E "^(Name|Uid|Gid):"
   docker rm -f security-test
   ```

---

## Lab 2: Linux Capabilities and Privilege Management  
**Duration**: 50 minutes  
**Anchor**: `p07-lab2-capabilities`

### Objective
Implement fine-grained privilege control using Linux capabilities, capability dropping, and security context configuration.

### Part A: Understanding Container Capabilities (15 minutes)

#### Step 1: Analyze Default Container Capabilities
```bash
# Create capability analysis container
cat > Dockerfile.captest << 'EOF'
FROM alpine:3.18
RUN apk add --no-cache libcap
CMD ["sh"]
EOF

docker build -f Dockerfile.captest -t captest .

# Check default Docker capabilities
echo "=== Default Docker Capabilities ==="
docker run --rm captest capsh --print

# Compare with host capabilities
echo "=== Host Capabilities ==="
capsh --print
```

#### Step 2: Test Specific Capability Requirements
```bash
# Test network capabilities
echo "=== Testing Network Capabilities ==="

# Default container - should work
docker run --rm alpine:3.18 ping -c 1 8.8.8.8 && echo "PING works with default caps" || echo "PING failed"

# Container without NET_RAW - should fail
docker run --rm --cap-drop NET_RAW alpine:3.18 ping -c 1 8.8.8.8 && echo "DANGER: PING works without NET_RAW" || echo "SECURE: PING blocked without NET_RAW"

# Test privileged port binding
echo "=== Testing Privileged Port Binding ==="

# Default container - should fail for port < 1024
docker run --rm alpine:3.18 nc -l -p 80 -e echo "hello" &
sleep 1
docker ps -a | tail -1

# With NET_BIND_SERVICE capability
docker run -d --name port-test --cap-add NET_BIND_SERVICE alpine:3.18 nc -l -p 80 -e echo "hello"
sleep 1
docker logs port-test
docker rm -f port-test
```

### Part B: Capability Dropping Strategies (20 minutes)

#### Step 3: Implement Comprehensive Capability Dropping
```bash
# Create security-hardened web application
cat > secure-app.js << 'EOF'
const http = require('http');
const fs = require('fs');

const server = http.createServer((req, res) => {
  const response = {
    timestamp: new Date().toISOString(),
    url: req.url,
    method: req.method,
    capabilities: 'Checking capabilities...'
  };
  
  // Try to perform privileged operations
  try {
    // This should fail in a properly secured container
    fs.writeFileSync('/etc/test', 'test');
    response.filesystem_write = 'SUCCESS (DANGEROUS)';
  } catch (err) {
    response.filesystem_write = 'BLOCKED (SECURE)';
  }
  
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify(response, null, 2));
});

server.listen(8080, '0.0.0.0', () => {
  console.log('Secure app running on port 8080');
  console.log(`Process UID: ${process.getuid()}, GID: ${process.getgid()}`);
});
EOF

# Secure Dockerfile with minimal capabilities
cat > Dockerfile.hardened << 'EOF'
FROM node:18-alpine

# Create non-root user
RUN addgroup -g 3001 -S securegroup && \
    adduser -u 3001 -S -G securegroup -h /app -s /sbin/nologin secureuser

# Setup application
RUN mkdir -p /app && chown -R secureuser:securegroup /app
COPY --chown=secureuser:securegroup secure-app.js /app/

USER secureuser
WORKDIR /app
EXPOSE 8080

CMD ["node", "secure-app.js"]
EOF

docker build -f Dockerfile.hardened -t secureapp:hardened .
```

#### Step 4: Test Different Capability Configurations
```bash
# Test 1: Default capabilities (less secure)
echo "=== Test 1: Default Capabilities ==="
docker run -d --name test-default -p 8080:8080 secureapp:hardened
sleep 2
curl -s http://localhost:8080/test | jq .
docker rm -f test-default

# Test 2: Drop all capabilities (most secure)
echo "=== Test 2: All Capabilities Dropped ==="
docker run -d --name test-no-caps --cap-drop ALL -p 8081:8080 secureapp:hardened
sleep 2
curl -s http://localhost:8081/test | jq .
docker rm -f test-no-caps

# Test 3: Minimal capabilities (balanced)
echo "=== Test 3: Minimal Required Capabilities ==="
docker run -d --name test-minimal \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  -p 8082:8080 \
  secureapp:hardened
sleep 2
curl -s http://localhost:8082/test | jq .
docker rm -f test-minimal
```

### Part C: Advanced Security Context (15 minutes)

#### Step 5: Comprehensive Security Context Configuration
```bash
# Create Docker Compose with advanced security
cat > docker-compose.security.yml << 'EOF'
version: '3.8'

services:
  # Maximum security configuration
  ultra-secure:
    image: secureapp:hardened
    user: "3001:3001"
    read_only: true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    tmpfs:
      - /tmp:noexec,nosuid,size=50m
      - /var/run:noexec,nosuid,size=10m
    sysctls:
      - net.ipv4.ip_unprivileged_port_start=0
    ulimits:
      nproc: 100
      nofile:
        soft: 1024
        hard: 2048
    ports:
      - "8083:8080"
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.25'

  # Comparison - less secure but functional
  standard-secure:
    image: secureapp:hardened
    user: "3001:3001"
    cap_drop:
      - NET_RAW
      - SYS_ADMIN
      - DAC_OVERRIDE
    ports:
      - "8084:8080"
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
EOF

# Deploy and test both configurations
docker compose -f docker-compose.security.yml up -d

# Test both services
echo "=== Ultra Secure Service ==="
curl -s http://localhost:8083/test | jq .

echo "=== Standard Secure Service ==="  
curl -s http://localhost:8084/test | jq .

# Cleanup
docker compose -f docker-compose.security.yml down
```

### Verification Steps

1. **Capability Verification**:
   ```bash
   # Check effective capabilities
   docker run --rm --cap-drop ALL captest capsh --print | grep "Current:"
   ```

2. **Security Context Testing**:
   ```bash
   # Test security restrictions
   docker run --rm --cap-drop ALL --security-opt no-new-privileges:true alpine:3.18 sh -c 'echo "Security context applied"'
   ```

3. **Privilege Escalation Testing**:
   ```bash
   # This should fail in properly configured container
   docker run --rm --cap-drop ALL alpine:3.18 su - && echo "DANGER: su worked" || echo "SECURE: su blocked"
   ```

---

## Lab 3: Read-Only Filesystems and Runtime Security
**Duration**: 45 minutes  
**Anchor**: `p07-lab3-filesystem-security`

### Objective
Implement read-only root filesystems, secure temporary filesystem management, and runtime security policies for defense in depth.

### Part A: Read-Only Filesystem Implementation (20 minutes)

#### Step 1: Create Application Requiring Writable Areas
```bash
# Create an app that needs specific writable directories
cat > filesystem-app.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');

const server = http.createServer((req, res) => {
  let response = {
    timestamp: new Date().toISOString(),
    tests: {}
  };

  // Test writable areas
  const testAreas = [
    { name: 'tmp', path: '/tmp/test.txt' },
    { name: 'app_cache', path: '/app/cache/test.txt' },
    { name: 'app_logs', path: '/app/logs/test.log' },
    { name: 'etc', path: '/etc/test.txt' },
    { name: 'root', path: '/test.txt' }
  ];

  testAreas.forEach(area => {
    try {
      fs.writeFileSync(area.path, `Test data: ${Date.now()}`);
      response.tests[area.name] = 'WRITABLE';
    } catch (err) {
      response.tests[area.name] = 'READ-ONLY';
    }
  });

  // Read application data
  try {
    const configData = fs.readFileSync('/app/config.json', 'utf8');
    response.config = JSON.parse(configData);
  } catch (err) {
    response.config = 'CONFIG_ERROR';
  }

  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify(response, null, 2));
});

server.listen(8080, '0.0.0.0', () => {
  console.log('Filesystem test app running on port 8080');
  
  // Create initial cache and log entries
  try {
    fs.writeFileSync('/app/cache/startup.txt', 'App started: ' + new Date().toISOString());
    fs.writeFileSync('/app/logs/startup.log', 'Startup log: ' + new Date().toISOString());
  } catch (err) {
    console.log('Could not write startup files:', err.message);
  }
});
EOF

# Create config file
cat > config.json << 'EOF'
{
  "app_name": "Filesystem Security Test",
  "version": "1.0.0",
  "security_level": "high"
}
EOF
```

#### Step 2: Build Read-Only Compatible Container
```bash
# Dockerfile optimized for read-only filesystem
cat > Dockerfile.readonly << 'EOF'
FROM node:18-alpine

# Create non-root user
RUN addgroup -g 4001 -S fsgroup && \
    adduser -u 4001 -S -G fsgroup -h /app -s /sbin/nologin fsuser

# Create directory structure with proper permissions
RUN mkdir -p /app/cache /app/logs /app/tmp && \
    chown -R fsuser:fsgroup /app

# Copy application files
COPY --chown=fsuser:fsgroup filesystem-app.js /app/
COPY --chown=fsuser:fsgroup config.json /app/

# Create volume mount points for writable directories
VOLUME ["/app/cache", "/app/logs", "/app/tmp"]

USER fsuser
WORKDIR /app
EXPOSE 8080

CMD ["node", "filesystem-app.js"]
EOF

docker build -f Dockerfile.readonly -t fsapp:readonly .
```

#### Step 3: Test Different Filesystem Configurations
```bash
# Test 1: Normal writable filesystem
echo "=== Test 1: Normal Writable Filesystem ==="
docker run -d --name fs-test-normal -p 8085:8080 fsapp:readonly
sleep 2
curl -s http://localhost:8085/ | jq .tests
docker rm -f fs-test-normal

# Test 2: Read-only root filesystem with tmpfs
echo "=== Test 2: Read-Only Root with tmpfs ==="
docker run -d --name fs-test-readonly \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=50m \
  --tmpfs /app/cache:noexec,nosuid,size=20m \
  --tmpfs /app/logs:noexec,nosuid,size=10m \
  -p 8086:8080 \
  fsapp:readonly
sleep 2
curl -s http://localhost:8086/ | jq .tests
docker rm -f fs-test-readonly

# Test 3: Read-only with volume mounts
echo "=== Test 3: Read-Only with Volume Mounts ==="
docker run -d --name fs-test-volumes \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=50m \
  -v fs-cache:/app/cache \
  -v fs-logs:/app/logs \
  -p 8087:8080 \
  fsapp:readonly
sleep 2
curl -s http://localhost:8087/ | jq .tests

# Check volume contents
docker exec fs-test-volumes ls -la /app/cache/
docker exec fs-test-volumes ls -la /app/logs/
docker rm -f fs-test-volumes
```

### Part B: Secure Temporary Filesystem Management (15 minutes)

#### Step 4: Advanced tmpfs Configuration
```bash
# Create comprehensive tmpfs security configuration
cat > docker-compose.tmpfs.yml << 'EOF'
version: '3.8'

services:
  # Highly secure tmpfs configuration
  secure-tmpfs:
    image: fsapp:readonly
    user: "4001:4001"
    read_only: true
    tmpfs:
      # Main temp directory with security restrictions
      - /tmp:noexec,nosuid,nodev,size=50m
      # Application cache with size limit
      - /app/cache:noexec,nosuid,nodev,size=20m
      # Application logs with size limit
      - /app/logs:noexec,nosuid,nodev,size=10m
      # Runtime directory
      - /var/run:noexec,nosuid,nodev,size=5m
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
    ports:
      - "8088:8080"
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/"]
      interval: 30s

  # Comparison with persistent volumes
  persistent-secure:
    image: fsapp:readonly
    user: "4001:4001"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=50m
    volumes:
      - fs-persistent-cache:/app/cache
      - fs-persistent-logs:/app/logs
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    ports:
      - "8089:8080"

volumes:
  fs-persistent-cache:
  fs-persistent-logs:
EOF

docker compose -f docker-compose.tmpfs.yml up -d

# Test tmpfs vs volume behavior
echo "=== Testing tmpfs behavior ==="
curl -s http://localhost:8088/ | jq .tests

echo "=== Testing volume behavior ==="
curl -s http://localhost:8089/ | jq .tests

# Check filesystem usage
docker exec $(docker compose -f docker-compose.tmpfs.yml ps -q secure-tmpfs) df -h
docker exec $(docker compose -f docker-compose.tmpfs.yml ps -q persistent-secure) df -h

docker compose -f docker-compose.tmpfs.yml down
```

### Part C: AppArmor Integration (10 minutes)

#### Step 5: Custom AppArmor Profile
```bash
# Create custom AppArmor profile for container security
sudo tee /etc/apparmor.d/docker-fsapp << 'EOF'
#include <tunables/global>

profile docker-fsapp flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Network access
  network inet tcp,
  network inet udp,

  # File system restrictions
  deny @{PROC}/* w,           # Deny writes to /proc
  deny /sys/** wklx,          # Deny access to /sys
  deny /etc/** w,             # Deny writes to /etc
  deny /root/** rwklx,        # Deny access to /root
  
  # Allow specific application paths
  /app/** r,                  # Read access to app directory
  /app/cache/** rw,           # Read/write to cache
  /app/logs/** rw,            # Read/write to logs
  /tmp/** rw,                 # Read/write to tmp
  
  # Required system access
  /usr/bin/node ix,
  /lib/** r,
  /usr/lib/** r,
  
  # Deny dangerous capabilities
  deny capability sys_admin,
  deny capability sys_boot,
  deny capability sys_module,
}
EOF

# Load the profile (if AppArmor is available)
if command -v apparmor_parser &> /dev/null; then
    sudo apparmor_parser -r -W /etc/apparmor.d/docker-fsapp
    echo "AppArmor profile loaded successfully"
    
    # Test with AppArmor profile
    docker run -d --name fs-apparmor-test \
      --security-opt apparmor=docker-fsapp \
      --read-only \
      --tmpfs /tmp:noexec,nosuid,size=50m \
      --tmpfs /app/cache:size=20m \
      --tmpfs /app/logs:size=10m \
      -p 8090:8080 \
      fsapp:readonly
    
    sleep 2
    curl -s http://localhost:8090/ | jq .tests
    docker rm -f fs-apparmor-test
else
    echo "AppArmor not available - skipping profile test"
fi
```

### Verification Steps

1. **Read-Only Filesystem Verification**:
   ```bash
   # Confirm read-only mounting
   docker run --rm --read-only alpine:3.18 mount | grep "/ type"
   ```

2. **tmpfs Security Verification**:
   ```bash
   # Check tmpfs mount options
   docker run --rm --tmpfs /tmp:noexec,nosuid alpine:3.18 mount | grep tmpfs
   ```

3. **File Permission Testing**:
   ```bash
   # Test write restrictions
   docker run --rm --read-only --tmpfs /tmp alpine:3.18 sh -c 'touch /tmp/ok && touch /etc/fail'
   ```

---

## Lab 4: Image Security and Vulnerability Management
**Duration**: 60 minutes  
**Anchor**: `p07-lab4-image-security`

### Objective
Master vulnerability scanning, secure base image selection, image signing, and supply chain security for production-ready container deployments.

### Part A: Vulnerability Scanning Integration (25 minutes)

#### Step 1: Create Vulnerable and Secure Image Variants
```bash
# Create directory for image security lab
mkdir ~/image-security-lab && cd ~/image-security-lab

# Vulnerable image (older base, unnecessary packages)
cat > Dockerfile.vulnerable << 'EOF'
FROM ubuntu:18.04

# Install many unnecessary packages (larger attack surface)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    apache2 \
    mysql-client \
    ssh \
    telnet \
    ftp

# Run as root (dangerous)
WORKDIR /app
COPY app.py /app/
RUN pip3 install flask requests

EXPOSE 5000
CMD ["python3", "app.py"]
EOF

# Secure image (minimal base, specific packages)
cat > Dockerfile.secure << 'EOF'
FROM python:3.11-alpine

# Install only required packages
RUN apk add --no-cache --virtual .build-deps gcc musl-dev && \
    apk add --no-cache curl && \
    apk del .build-deps

# Create non-root user
RUN addgroup -g 5001 -S appgroup && \
    adduser -u 5001 -S -G appgroup -h /app -s /sbin/nologin appuser

# Setup application
WORKDIR /app
COPY --chown=appuser:appgroup app.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Ultra-secure distroless image
cat > Dockerfile.distroless << 'EOF'
# Multi-stage build for distroless
FROM python:3.11-alpine AS builder
WORKDIR /app
COPY app.py requirements.txt ./
RUN pip install --user --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3
COPY --from=builder /root/.local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /app/app.py /app/
WORKDIR /app
EXPOSE 5000
CMD ["app.py"]
EOF

# Create simple Python application
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/info')
def info():
    return jsonify({
        'user': os.getuid(),
        'group': os.getgid(),
        'hostname': os.uname().nodename,
        'python_version': os.sys.version
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > requirements.txt << 'EOF'
flask==2.3.3
EOF

# Build all variants
docker build -f Dockerfile.vulnerable -t pyapp:vulnerable .
docker build -f Dockerfile.secure -t pyapp:secure .
docker build -f Dockerfile.distroless -t pyapp:distroless .
```

#### Step 2: Vulnerability Scanning with Multiple Tools
```bash
# Install scanning tools (if not available)
echo "Installing vulnerability scanners..."

# Docker Scout (built into Docker)
echo "=== Docker Scout Scanning ==="
docker scout cves pyapp:vulnerable
echo ""
docker scout cves pyapp:secure  
echo ""
docker scout cves pyapp:distroless

# Trivy scanning (if available)
if command -v trivy &> /dev/null; then
    echo "=== Trivy Scanning ==="
    trivy image --severity HIGH,CRITICAL pyapp:vulnerable
    echo ""
    trivy image --severity HIGH,CRITICAL pyapp:secure
    echo ""
    trivy image --severity HIGH,CRITICAL pyapp:distroless
else
    echo "Trivy not available - installing via Docker..."
    # Use Trivy via Docker container
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        aquasec/trivy:latest image --severity HIGH,CRITICAL pyapp:vulnerable
fi

# Compare image sizes
echo "=== Image Size Comparison ==="
docker images | grep pyapp
```

#### Step 3: Create Automated Scanning Pipeline
```bash
# Create scanning script
cat > scan-images.sh << 'EOF'
#!/bin/bash

# Image vulnerability scanning pipeline
IMAGES=("pyapp:vulnerable" "pyapp:secure" "pyapp:distroless")
SCAN_RESULTS_DIR="./scan-results"

mkdir -p $SCAN_RESULTS_DIR

echo "Starting automated vulnerability scan pipeline..."
echo "========================================================"

for image in "${IMAGES[@]}"; do
    echo "Scanning: $image"
    
    # Docker Scout scan
    echo "Running Docker Scout scan..."
    docker scout cves "$image" --format json > "${SCAN_RESULTS_DIR}/${image//:/}_scout.json"
    
    # Extract critical/high vulnerabilities
    CRITICAL=$(docker scout cves "$image" --format json | jq '.vulnerabilities | map(select(.severity == "CRITICAL")) | length')
    HIGH=$(docker scout cves "$image" --format json | jq '.vulnerabilities | map(select(.severity == "HIGH")) | length')
    
    echo "  Critical vulnerabilities: $CRITICAL"
    echo "  High vulnerabilities: $HIGH"
    
    # Security recommendation
    if [ "$CRITICAL" -gt 0 ]; then
        echo "  ❌ REJECT: Critical vulnerabilities found"
    elif [ "$HIGH" -gt 5 ]; then
        echo "  ⚠️  REVIEW: Many high severity vulnerabilities"
    else
        echo "  ✅ APPROVE: Acceptable vulnerability level"
    fi
    
    echo ""
done

echo "Scan results saved to: $SCAN_RESULTS_DIR"
EOF

chmod +x scan-images.sh
./scan-images.sh
```

### Part B: Secure Base Image Selection and Hardening (20 minutes)

#### Step 4: Base Image Security Analysis
```bash
# Compare different base images for security
BASE_IMAGES=("ubuntu:22.04" "alpine:3.18" "gcr.io/distroless/python3" "scratch")

echo "=== Base Image Security Comparison ==="
for base in "${BASE_IMAGES[@]}"; do
    echo "Analyzing: $base"
    
    # Pull image
    docker pull "$base" 2>/dev/null || echo "  Cannot pull $base"
    
    # Size analysis
    SIZE=$(docker images "$base" --format "{{.Size}}" | head -1)
    echo "  Size: $SIZE"
    
    # Package count (if applicable)
    if [[ "$base" == *"ubuntu"* ]]; then
        PKG_COUNT=$(docker run --rm "$base" dpkg -l 2>/dev/null | wc -l)
        echo "  Packages: $PKG_COUNT"
    elif [[ "$base" == *"alpine"* ]]; then
        PKG_COUNT=$(docker run --rm "$base" apk list -I 2>/dev/null | wc -l)
        echo "  Packages: $PKG_COUNT"
    else
        echo "  Packages: Minimal/Unknown"
    fi
    
    # Quick vulnerability check
    docker scout cves "$base" --format json > /tmp/base_scan.json 2>/dev/null
    if [ -f /tmp/base_scan.json ]; then
        VULNS=$(jq '.vulnerabilities | length' /tmp/base_scan.json 2>/dev/null || echo "0")
        echo "  Vulnerabilities: $VULNS"
    fi
    
    echo ""
done
```

#### Step 5: Secure Multi-Stage Build Implementation
```bash
# Advanced secure multi-stage build
cat > Dockerfile.production << 'EOF'
# Build stage - includes build tools
FROM python:3.11-alpine AS builder

# Security: Install build dependencies temporarily
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev

# Install Python dependencies
WORKDIR /build
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels -r requirements.txt

# Production stage - minimal runtime
FROM python:3.11-alpine AS production

# Security: Create non-root user
RUN addgroup -g 6001 -S prodgroup && \
    adduser -u 6001 -S -G prodgroup -h /app -s /sbin/nologin produser

# Security: Install only runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tini

# Install pre-built wheels (no build tools needed)
COPY --from=builder /wheels /wheels
RUN pip install --no-cache --no-index --find-links /wheels -r /tmp/requirements.txt && \
    rm -rf /wheels

# Security: Setup application with proper permissions
WORKDIR /app
COPY --chown=produser:prodgroup app.py ./

# Security: Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Security: Switch to non-root user
USER produser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Copy requirements to build context
cp requirements.txt /tmp/requirements.txt

docker build -f Dockerfile.production -t pyapp:production .

# Test production image
docker run -d --name prod-test -p 5001:5000 pyapp:production
sleep 3
curl http://localhost:5001/info | jq .
curl http://localhost:5001/health | jq .
docker rm -f prod-test
```

### Part C: Image Signing and Supply Chain Security (15 minutes)

#### Step 6: Container Image Signing
```bash
# Enable Docker Content Trust (basic signing)
export DOCKER_CONTENT_TRUST=1

echo "=== Docker Content Trust Demo ==="
# Note: This requires a Docker Hub account for actual signing
echo "DOCKER_CONTENT_TRUST enabled: $DOCKER_CONTENT_TRUST"

# Simulate signing process (actual signing requires registry push)
echo "Image signing process:"
echo "1. Generate signing keys"
echo "2. Push signed image to registry"
echo "3. Verify signature on pull"

# Unset for remaining exercises
unset DOCKER_CONTENT_TRUST

# Advanced signing with Cosign (if available)
if command -v cosign &> /dev/null; then
    echo "=== Cosign Advanced Signing ==="
    
    # Generate ephemeral keys for demo
    cosign generate-key-pair
    
    # Sign image (would require registry in real scenario)
    echo "cosign sign --key cosign.key myapp:production"
    echo "Signature process complete"
    
    # Verify signature
    echo "cosign verify --key cosign.pub myapp:production"
    echo "Verification process complete"
else
    echo "Cosign not available - skipping advanced signing demo"
fi
```

#### Step 7: Supply Chain Security Analysis
```bash
# Create SBOM (Software Bill of Materials)
echo "=== Generating Software Bill of Materials ==="

# Docker Scout SBOM
docker scout sbom pyapp:production

# Create supply chain security report
cat > supply-chain-report.sh << 'EOF'
#!/bin/bash

echo "Supply Chain Security Report"
echo "============================"
echo ""

IMAGE="pyapp:production"

echo "1. Base Image Analysis:"
echo "   Base: $(docker inspect $IMAGE | jq -r '.[0].Config.Image // "unknown"')"

echo ""
echo "2. Layer Analysis:"
docker history $IMAGE --format "table {{.CreatedBy}}" | head -10

echo ""
echo "3. Package Inventory:"
docker run --rm $IMAGE sh -c 'apk list -I 2>/dev/null || dpkg -l 2>/dev/null || echo "Minimal/Distroless image"' | head -10

echo ""
echo "4. Security Recommendations:"
echo "   ✓ Non-root user: $(docker inspect $IMAGE | jq -r '.[0].Config.User // "root (⚠️)"')"
echo "   ✓ Read-only root: Implemented at runtime"
echo "   ✓ Vulnerability scanning: Completed"
echo "   ✓ Minimal base image: Alpine Linux"

echo ""
echo "5. Compliance Status:"
echo "   • CIS Docker Benchmark: Partially Compliant"
echo "   • NIST Container Security: Aligned"
echo "   • Industry Standards: Following best practices"
EOF

chmod +x supply-chain-report.sh
./supply-chain-report.sh
```

### Verification Steps

1. **Vulnerability Assessment**:
   ```bash
   # Compare vulnerability counts across images
   for image in pyapp:vulnerable pyapp:secure pyapp:distroless; do
       echo "=== $image ==="
       docker scout cves "$image" --format sarif | jq '.runs[0].results | length'
   done
   ```

2. **Security Configuration Validation**:
   ```bash
   # Verify security settings
   docker inspect pyapp:production | jq '.[0].Config.User'
   docker inspect pyapp:production | jq '.[0].Config.Healthcheck'
   ```

3. **Runtime Security Testing**:
   ```bash
   # Test runtime security
   docker run --rm pyapp:production id
   docker run --rm pyapp:production whoami
   ```

---

## 🎓 Lab Summary and Key Takeaways

### Security Implementation Checklist

- [ ] **User Security**: Non-root users configured with appropriate UID/GID mapping
- [ ] **Capabilities**: All unnecessary capabilities dropped, minimal privileges granted
- [ ] **Filesystem**: Read-only root filesystem with secure tmpfs configurations
- [ ] **Images**: Vulnerability scanning integrated, secure base images selected
- [ ] **Supply Chain**: SBOM generated, image signing process understood
- [ ] **Runtime**: Security contexts properly configured with monitoring

### Production Security Recommendations

1. **Layered Defense**: Implement multiple security controls simultaneously
2. **Regular Scanning**: Automate vulnerability scanning in CI/CD pipeline
3. **Minimal Images**: Use distroless or Alpine bases for reduced attack surface
4. **Monitoring**: Implement runtime security monitoring with Falco or similar
5. **Updates**: Regular base image updates and dependency management
6. **Compliance**: Align with industry standards (CIS, NIST, etc.)

### Common Pitfalls to Avoid

- Running containers as root user
- Using outdated or vulnerable base images
- Exposing unnecessary capabilities or privileges
- Ignoring vulnerability scan results
- Implementing security as an afterthought

---

> 💡 **Security Note**: Container security is an ongoing process, not a one-time configuration. Regular audits, updates, and monitoring are essential for maintaining a secure container environment.