# p05-m01-l03: Permission Handling and Security

> **Duration**: 4 minutes | **Anchor**: `p05-m01-l03` | **Type**: Security-focused + Troubleshooting

## 🎯 Learning Objective

Master Docker volume permission management, resolve common ownership issues, and implement secure storage patterns that align with production security requirements.

## 🔒 The Permission Challenge

### Understanding the Core Problem

```bash
# The Problem: UID/GID Mismatch
Host User:      uid=1000, gid=1000 (alice)
Container User: uid=0,    gid=0    (root)

# Result: Permission conflicts
┌─────────────────┐    ┌─────────────────┐
│   Host Side     │    │  Container Side │
│                 │    │                 │
│ $ touch file.txt│───▶│ # ls -la        │
│ alice:alice     │    │ root:root       │
│ -rw-r--r--      │    │ -rw-r--r--      │
└─────────────────┘    └─────────────────┘
      ↑ Can't modify files created by container
```

## 💡 Permission Solution Patterns

### Pattern 1: User ID Mapping (Recommended)

```bash
# Get host user info
HOST_UID=$(id -u)
HOST_GID=$(id -g)

echo "Host user: $HOST_UID:$HOST_GID"

# Run container with host user ID
docker run --rm \
  --user $HOST_UID:$HOST_GID \
  -v $(pwd)/shared:/data \
  alpine sh -c '
    id  # Shows container running as host user
    echo "test content" > /data/host-owned-file.txt
    ls -la /data/
  '

# Verify file ownership on host
ls -la shared/
# File owned by host user - can be modified
```

### Pattern 2: Container User Creation

```bash
# Build image with matching user
cat > Dockerfile.usersetup << EOF
FROM alpine
ARG HOST_UID=1000
ARG HOST_GID=1000

# Create user matching host
RUN addgroup -g \$HOST_GID appgroup && \
    adduser -D -u \$HOST_UID -G appgroup appuser

USER appuser
WORKDIR /app
EOF

# Build with host user IDs
docker build \
  --build-arg HOST_UID=$(id -u) \
  --build-arg HOST_GID=$(id -g) \
  -f Dockerfile.usersetup \
  -t app-with-user .

# Run with proper user
docker run --rm \
  -v $(pwd)/shared:/app/data \
  app-with-user sh -c '
    whoami  # Shows appuser
    echo "content from appuser" > /app/data/appuser-file.txt
  '

# Clean up
rm Dockerfile.usersetup
docker image rm app-with-user
```

### Pattern 3: Runtime User Setup

```bash
# Dynamic user creation at runtime
setup_runtime_user() {
    local host_uid=$(id -u)
    local host_gid=$(id -g)
    
    docker run --rm \
        -v $(pwd)/shared:/data \
        -e HOST_UID=$host_uid \
        -e HOST_GID=$host_gid \
        alpine sh -c '
            # Create user dynamically
            addgroup -g $HOST_GID hostgroup
            adduser -D -u $HOST_UID -G hostgroup hostuser
            
            # Switch to created user and work
            su hostuser -c "
                echo \"Dynamic user setup\" > /data/dynamic-user-file.txt
                ls -la /data/
            "
        '
}

setup_runtime_user
```

## ⚡ Live Permission Demo (2 minutes)

```bash
echo "=== Permission Problem & Solution Demo ==="

# Setup test directory
mkdir -p permission-demo && cd permission-demo

echo "=== PROBLEM: Permission Conflict ==="

# 1. Container creates file as root
docker run --rm \
  -v $(pwd):/data \
  alpine sh -c 'echo "root created file" > /data/root-file.txt'

# Check ownership (will be root)
ls -la root-file.txt
echo "File owner: $(stat -c %U:%G root-file.txt)"

# Try to modify as host user (should fail)
echo "Trying to modify root-created file as host user:"
echo "additional content" >> root-file.txt 2>&1 || echo "❌ Permission denied (expected)"

echo ""
echo "=== SOLUTION: User ID Mapping ==="

# 2. Container uses host user ID
docker run --rm \
  --user $(id -u):$(id -g) \
  -v $(pwd):/data \
  alpine sh -c 'echo "host user created file" > /data/host-user-file.txt'

# Check ownership (will match host user)
ls -la host-user-file.txt
echo "File owner: $(stat -c %U:%G host-user-file.txt)"

# Modify as host user (should succeed)
echo "Trying to modify host-user-created file:"
echo "additional content" >> host-user-file.txt
echo "✅ Success! File modified by host user"

# Cleanup
cd .. && rm -rf permission-demo
```

## 🛡️ Security-First Storage Patterns

### Secure Configuration Management

```bash
echo "=== Secure Configuration Pattern ==="

# Create config volume
docker volume create app-config

# Initialize config with proper permissions
docker run --rm \
  -v app-config:/config \
  --user root \
  alpine sh -c '
    echo "database_url=postgresql://user:pass@db:5432/app" > /config/app.env
    echo "api_key=secret-key-here" >> /config/app.env
    
    # Create application user and set ownership
    adduser -D -u 1001 appuser
    chown -R appuser:appuser /config
    chmod 600 /config/app.env  # Readable only by owner
  '

# Use config with application user (read-only)
docker run --rm \
  -v app-config:/app/config:ro \
  --user 1001:1001 \
  alpine sh -c '
    whoami  # Should show user with uid 1001
    ls -la /app/config/
    cat /app/config/app.env
    
    # Try to modify (should fail due to read-only)
    echo "hack=true" >> /app/config/app.env 2>&1 || echo "✅ Read-only protection working"
  '

echo "✅ Secure configuration pattern implemented"
```

### tmpfs for Sensitive Data Security

```bash
echo "=== tmpfs Security Pattern ==="

# Demonstrate tmpfs security benefits
docker run --rm \
  --tmpfs /secrets:rw,noexec,nosuid,size=10m \
  --user 1001:1001 \
  alpine sh -c '
    echo "=== tmpfs Security Test ==="
    
    # Store sensitive data
    echo "secret_token=abc123456" > /secrets/token
    echo "private_key=-----BEGIN PRIVATE KEY-----" > /secrets/key.pem
    
    # Verify data is accessible
    echo "Secret stored: $(cat /secrets/token)"
    
    # Try to execute file (should fail due to noexec)
    echo "#!/bin/sh" > /secrets/malicious.sh
    echo "echo hacked" >> /secrets/malicious.sh
    chmod +x /secrets/malicious.sh
    
    echo "Attempting to execute script from tmpfs:"
    /secrets/malicious.sh 2>&1 || echo "✅ Execution blocked by noexec"
    
    echo "Data exists only in memory - no disk persistence"
  '

echo "✅ tmpfs security benefits demonstrated"
```

### Non-Root Container Security

```bash
echo "=== Non-Root Container Security ==="

# Create secure application image
cat > Dockerfile.secure << 'EOF'
FROM alpine

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 appuser -G appgroup

# Create app directory with proper ownership
RUN mkdir -p /app/data && \
    chown -R appuser:appgroup /app

USER appuser
WORKDIR /app

# Application can only write to owned directories
CMD ["sh", "-c", "while true; do echo 'App running as:'; id; sleep 10; done"]
EOF

docker build -f Dockerfile.secure -t secure-app .

# Test non-root security
docker run --rm \
  -v $(pwd):/host-data \
  --user 1001:1001 \
  secure-app sh -c '
    echo "=== Security Test ==="
    whoami || echo "User: uid=$(id -u), gid=$(id -g)"
    
    # Can write to volume with matching ownership
    echo "app data" > /host-data/app-owned.txt 2>/dev/null && echo "✅ Can write to owned volume" || echo "❌ Cannot write"
    
    # Cannot access system files
    cat /etc/shadow 2>/dev/null && echo "❌ SECURITY BREACH" || echo "✅ Cannot access system files"
    
    # Cannot modify system directories
    touch /etc/hacked 2>/dev/null && echo "❌ SECURITY BREACH" || echo "✅ Cannot modify system directories"
  '

# Cleanup
rm Dockerfile.secure
docker image rm secure-app
rm -f app-owned.txt
```

## 🔧 Permission Troubleshooting Guide

### Permission Diagnostic Tool

```bash
# Permission diagnostic function
diagnose_permissions() {
    local volume_or_path=$1
    
    echo "=== Permission Diagnosis: $volume_or_path ==="
    
    # Check if it's a volume or bind mount
    if docker volume inspect $volume_or_path >/dev/null 2>&1; then
        echo "Type: Named Volume"
        
        # Check volume contents and permissions
        docker run --rm \
            -v $volume_or_path:/check \
            alpine sh -c '
                echo "Volume contents:"
                ls -la /check/ 2>/dev/null || echo "Empty or inaccessible"
                
                echo "Volume ownership:"
                stat -c "Owner: %U:%G (UID:%u GID:%g)" /check 2>/dev/null || echo "Cannot determine"
                
                echo "Volume permissions:"
                stat -c "Permissions: %A (%a)" /check 2>/dev/null || echo "Cannot determine"
            '
    else
        echo "Type: Bind Mount or Directory"
        
        if [ -d "$volume_or_path" ]; then
            echo "Directory exists on host"
            ls -la "$volume_or_path" | head -5
            echo "Owner: $(stat -c %U:%G "$volume_or_path")"
            echo "Permissions: $(stat -c %A "$volume_or_path")"
        else
            echo "❌ Directory does not exist: $volume_or_path"
        fi
    fi
    
    echo "Host user info:"
    echo "  Current user: $(whoami) (UID:$(id -u) GID:$(id -g))"
}

# Example usage
diagnose_permissions app-config
```

### Common Permission Fixes

```bash
# Fix 1: Retroactive ownership correction
fix_volume_ownership() {
    local volume_name=$1
    local target_uid=${2:-$(id -u)}
    local target_gid=${3:-$(id -g)}
    
    echo "Fixing ownership for volume: $volume_name"
    echo "Target UID:GID = $target_uid:$target_gid"
    
    docker run --rm \
        -v $volume_name:/data \
        alpine sh -c "
            # Add target user if it doesn't exist
            addgroup -g $target_gid targetgroup 2>/dev/null || true
            adduser -D -u $target_uid -G targetgroup targetuser 2>/dev/null || true
            
            # Fix ownership recursively
            chown -R $target_uid:$target_gid /data
            
            echo 'Ownership fixed:'
            ls -la /data/ | head -5
        "
}

# Fix 2: Reset permissions for security
reset_volume_permissions() {
    local volume_name=$1
    
    echo "Resetting permissions for security: $volume_name"
    
    docker run --rm \
        -v $volume_name:/data \
        alpine sh -c '
            # Set secure permissions
            find /data -type f -exec chmod 644 {} \;  # Files: rw-r--r--
            find /data -type d -exec chmod 755 {} \;  # Dirs:  rwxr-xr-x
            
            echo "Permissions reset:"
            find /data -ls | head -5
        '
}

# Fix 3: Create user-specific workspace
create_user_workspace() {
    local volume_name=$1
    local username=${2:-$(whoami)}
    local user_uid=${3:-$(id -u)}
    local user_gid=${4:-$(id -g)}
    
    echo "Creating user workspace: $volume_name for $username"
    
    docker run --rm \
        -v $volume_name:/workspace \
        alpine sh -c "
            # Create user directory structure
            mkdir -p /workspace/$username/{data,config,temp}
            
            # Create user in container
            addgroup -g $user_gid usergroup
            adduser -D -u $user_uid -G usergroup $username
            
            # Set ownership
            chown -R $user_uid:$user_gid /workspace/$username
            chmod 700 /workspace/$username  # Private to user
            
            echo 'User workspace created:'
            ls -la /workspace/
        "
}
```

## 🚨 Security Anti-Patterns and Fixes

### Anti-Pattern 1: Running as root unnecessarily

❌ **Dangerous root access**
```bash
# Gives container unnecessary system access
docker run -v /host/data:/app/data myapp:latest
```

✅ **Proper user mapping**
```bash
# Limits container to necessary permissions only
docker run --user $(id -u):$(id -g) -v /host/data:/app/data myapp:latest
```

### Anti-Pattern 2: World-writable volumes

❌ **Overpermissive volumes**
```bash
# Creates security vulnerability
docker run --rm -v data:/app/data alpine chmod -R 777 /app/data
```

✅ **Least privilege permissions**
```bash
# Secure permission management
docker run --rm -v data:/app/data --user 1001:1001 alpine chmod 644 /app/data/*
```

### Anti-Pattern 3: Storing secrets in named volumes

❌ **Persistent secrets on disk**
```bash
# Secrets persist in Docker storage
docker volume create secrets
docker run -v secrets:/app/secrets myapp
```

✅ **tmpfs for secrets**
```bash
# Secrets only in memory
docker run --tmpfs /app/secrets:rw,noexec,size=10m myapp
```

## 🔗 Production Security Checklist

- [ ] **Non-root users**: All containers run with specific user IDs
- [ ] **Read-only volumes**: Configuration and static content mounted read-only
- [ ] **tmpfs for secrets**: Sensitive data stored in memory only
- [ ] **Proper ownership**: File ownership matches container user expectations
- [ ] **Minimal permissions**: Files and directories have least required permissions
- [ ] **User namespace mapping**: Container users map appropriately to host users
- [ ] **Security scanning**: Regular permission audits of volumes and containers
- [ ] **Principle of least privilege**: Containers have minimum required access

---

**Next**: Performance Optimization Techniques (`p05-m01-l04`)