# Micro-Lesson 03: Read-Only Filesystems and Runtime Security

> **Anchor**: `p07-m01-l03`  
> **Duration**: 4 minutes  
> **One Key Idea**: Implement read-only root filesystems with secure temporary storage and runtime security policies

## Why It Matters

Read-only filesystems prevent malware persistence, unauthorized file modifications, and many container escape techniques. They enforce immutable infrastructure principles and make containers more predictable and secure. Combined with secure tmpfs, they provide strong runtime protection.

## What to Learn

Master read-only filesystem security:
- **Read-only root filesystem benefits** - Immutable container runtime
- **Secure tmpfs configuration** - Safe writable areas
- **Volume vs tmpfs for writable areas** - Persistent vs temporary storage
- **AppArmor/SELinux integration** - Defense-in-depth security

## Application Design for Read-Only

### Dockerfile Optimization
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

## Runtime Configuration

### Command Line Configuration
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
```

### Docker Compose Implementation
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
      - no-new-privileges:true
    cap_drop:
      - ALL
    environment:
      - NODE_ENV=production

  database:
    image: postgres:15
    user: "999:999"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,nodev,size=100m
      - /var/run/postgresql:noexec,nosuid,size=10m
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password

volumes:
  app-data:
  postgres-data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Tmpfs Security Options

### Secure Tmpfs Configuration
```bash
# Security options for tmpfs:
# noexec   - Cannot execute binaries
# nosuid   - Cannot set setuid bits
# nodev    - Cannot create device files
# size=50m - Limit size to prevent DoS

# Example configurations:
/tmp:noexec,nosuid,nodev,size=100m           # General temp directory
/app/cache:noexec,nosuid,size=50m            # Application cache
/var/run:noexec,nosuid,size=10m              # Runtime files
```

## Security Verification

### Test Read-Only Enforcement
```bash
# Verify read-only enforcement
docker run --rm --read-only alpine:3.18 touch /test.txt  # Should fail

# Test tmpfs permissions
docker exec secure-app touch /test.txt          # Should fail (read-only root)
docker exec secure-app touch /tmp/test.txt      # Should succeed (tmpfs)
docker exec secure-app touch /app/cache/test    # Should succeed (writable area)

# Test tmpfs security options
docker run --rm --tmpfs /tmp:noexec alpine:3.18 sh -c \
  'echo "#!/bin/sh\necho test" > /tmp/script.sh && chmod +x /tmp/script.sh && /tmp/script.sh'
  # Should fail with noexec
```

## Production Stack Example

### Complete Secure Configuration
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    user: "101:101"
    read_only: true
    tmpfs:
      - /var/cache/nginx:noexec,nosuid,size=100m
      - /var/run:noexec,nosuid,size=10m
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - web-logs:/var/log/nginx
    security_opt:
      - apparmor:docker-default
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

  app:
    build: .
    user: "1001:1001"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,nodev,size=50m
      - /app/tmp:noexec,nosuid,size=20m
    volumes:
      - app-data:/app/data
      - app-logs:/app/logs
    security_opt:
      - apparmor:docker-default
      - no-new-privileges:true
    cap_drop:
      - ALL

  db:
    image: postgres:15
    user: "999:999"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,nodev,size=100m
      - /var/run/postgresql:noexec,nosuid,size=10m
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    security_opt:
      - apparmor:docker-default
    cap_drop:
      - ALL

volumes:
  app-data:
  app-logs:
  web-logs:
  db-data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Practice Tasks

1. **Build read-only optimized image**: `docker build -t myapp:readonly .`
2. **Test read-only restrictions**: `docker run --rm --read-only myapp:readonly touch /test.txt`
3. **Deploy secure stack**: `docker compose up -d`
4. **Verify filesystem restrictions**: `docker compose exec app touch /etc/test.txt`
5. **Test tmpfs functionality**: `docker compose exec app touch /tmp/test.txt`
6. **Check security options**: `docker compose exec app mount | grep tmpfs`

## Production Notes

- Read-only root filesystem prevents malware persistence and system file tampering
- Use tmpfs with noexec,nosuid,nodev for security
- Size-limit tmpfs to prevent DoS attacks
- Consider using persistent volumes for application data that must survive container restarts
- Test application compatibility with read-only filesystem during development

## Common Patterns

### Log Management
```yaml
# Option 1: Tmpfs (logs lost on restart)
tmpfs:
  - /app/logs:noexec,nosuid,size=100m

# Option 2: Volume (logs persist)
volumes:
  - app-logs:/app/logs
```

### Cache Management
```yaml
# Application cache (can be tmpfs)
tmpfs:
  - /app/cache:noexec,nosuid,size=200m

# Database cache (should be volume for performance)
volumes:
  - db-cache:/var/lib/postgresql/cache
```

## Key Takeaway

Read-only filesystems with secure tmpfs provide strong runtime protection by preventing unauthorized file modifications and malware persistence while maintaining application functionality.