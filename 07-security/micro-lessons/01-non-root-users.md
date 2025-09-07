# Micro-Lesson 01: Non-Root User Configuration and User Namespace Mapping

> **Anchor**: `p07-m01-l01`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master non-root user configuration and user namespace mapping for container isolation

## Why It Matters

Running containers as root creates massive security risks - any container escape gives attackers full system access. Non-root users provide defense-in-depth, limiting the impact of container compromises. User namespace mapping adds an additional layer of isolation.

## What to Learn

Master non-root security fundamentals:
- **Non-root user creation and configuration** - Create dedicated application users
- **User namespace remapping for security isolation** - Map container users to unprivileged host users
- **UID/GID mapping strategies** - Consistent user mapping across environments
- **File permission security implications** - Handle ownership and permissions properly

## Secure User Configuration

### Insecure Pattern (DON'T USE)
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY app.js .
CMD ["node", "app.js"]  # Runs as root!
```

### Secure Pattern (RECOMMENDED)
```dockerfile
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

## User Namespace Configuration

### Docker Daemon Configuration
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

### Docker Compose Implementation
```yaml
version: '3.8'
services:
  app:
    build: .
    user: "1001:1001"  # Explicit non-root user
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=50m
```

## Verification Commands

### Test User Isolation
```bash
# Test user isolation
docker run --rm myapp:secure whoami  # Should show appuser, not root
docker run --rm myapp:secure id      # Should show UID 1001, not 0

# Test file permission restrictions
docker run --rm myapp:secure touch /etc/test.txt  # Should fail with permission denied

# Verify user namespace mapping (if enabled)
docker run --rm --user 1001 alpine id  # Host sees different UID
```

### Security Testing
```bash
# Test privilege escalation attempts
docker run --rm --user 1001 alpine su -  # Should fail

# Test file system access
docker run --rm --user 1001 alpine ls /root  # Should fail with permission denied
```

## Practice Tasks

1. **Build secure image**: `docker build -t myapp:secure .`
2. **Test user identity**: `docker run --rm myapp:secure whoami`
3. **Verify permissions**: `docker run --rm myapp:secure touch /test.txt`
4. **Check UID/GID**: `docker run --rm myapp:secure id`

## Production Notes

- Use consistent UID/GID across environments for volume compatibility
- Consider using numeric UIDs (e.g., 1001:1001) for better portability
- Test file system permissions with mounted volumes
- User namespace remapping affects volume ownership on host

## Common Pitfalls

❌ **Using generic users**: `USER nobody` (unknown UID)  
✅ **Explicit numeric users**: `USER 1001:1001`

❌ **Forgetting file ownership**: `COPY app.js .`  
✅ **Proper ownership**: `COPY --chown=1001:1001 app.js .`

❌ **Last-minute USER directive**: Easy to forget  
✅ **Early USER directive**: Set user context early

## Key Takeaway

Non-root users are essential for container security - they limit blast radius of container escapes and provide defense-in-depth protection.