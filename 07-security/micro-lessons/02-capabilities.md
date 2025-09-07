# Micro-Lesson 02: Linux Capabilities and Privilege Management

> **Anchor**: `p07-m01-l02`  
> **Duration**: 5 minutes  
> **One Key Idea**: Implement fine-grained privilege control using Linux capabilities and security contexts

## Why It Matters

Docker containers run with many dangerous Linux capabilities by default. These capabilities can be exploited for privilege escalation, system manipulation, and container escapes. Dropping unnecessary capabilities follows the principle of least privilege, significantly reducing attack surface.

## What to Learn

Master capability-based security:
- **Linux capabilities vs traditional root privileges** - Fine-grained permission model
- **Capability dropping strategies** - Remove dangerous permissions
- **Security context configuration** - Comprehensive security settings
- **No-new-privileges security option** - Prevent privilege escalation

## Default Docker Capabilities

### Check Default Capabilities
```bash
# Check default Docker capabilities
docker run --rm alpine:3.18 sh -c 'apk add libcap && capsh --print'

# Common dangerous capabilities included by default:
# - NET_RAW (raw sockets, network sniffing)
# - SYS_CHROOT (chroot escapes)
# - MKNOD (create device files)
# - SETUID/SETGID (change user/group)
```

## Secure Capability Configuration

### Drop All Capabilities (Maximum Security)
```bash
# Drop all capabilities (maximum security)
docker run --rm --cap-drop ALL alpine:3.18 ping 8.8.8.8  # Should fail

# Add only required capabilities
docker run --rm \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --user 1001:1001 \
  nginx:alpine
```

### Docker Compose Security Configuration
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

  # Database with minimal capabilities
  database:
    image: postgres:15
    user: "999:999"
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run/postgresql:noexec,nosuid,size=10m
```

## Dangerous Capabilities to Avoid

### Never Grant These Capabilities
```bash
# CAP_SYS_ADMIN - System administration (mount, etc.)
# CAP_DAC_OVERRIDE - Bypass file read/write/execute permissions
# CAP_FOWNER - Bypass file ownership checks  
# CAP_SYS_PTRACE - Trace arbitrary processes
# CAP_SYS_MODULE - Load/unload kernel modules
# CAP_NET_ADMIN - Network administration
```

### Common Safe Capabilities
```bash
# NET_BIND_SERVICE - Bind to ports < 1024 (web servers)
# CHOWN - Change file ownership (limited scope)
# DAC_READ_SEARCH - Bypass file read permission checks (limited)
```

## Advanced Security Testing

### Test Capability Restrictions
```bash
# Test privilege escalation prevention
docker run --rm --security-opt no-new-privileges:true alpine:3.18 su -  # Should fail

# Verify no dangerous capabilities
docker run --rm --cap-drop SYS_ADMIN alpine:3.18 mount -t tmpfs none /mnt  # Should fail

# Test network capabilities
docker run --rm --cap-drop NET_RAW alpine:3.18 ping 8.8.8.8  # Should fail without NET_RAW
```

### Comprehensive Security Stack
```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    user: "101:101"  # nginx user
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # For port 80/443
      - CHOWN             # For log file ownership
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    read_only: true
    tmpfs:
      - /var/cache/nginx:noexec,nosuid,size=100m
      - /var/run:noexec,nosuid,size=10m
    ports:
      - "80:80"
      - "443:443"

  app:
    build: .
    user: "1001:1001"
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=50m
```

## Practice Tasks

1. **Check default capabilities**: `docker run --rm alpine:3.18 sh -c 'apk add libcap && capsh --print'`
2. **Test capability dropping**: `docker run --rm --cap-drop ALL alpine:3.18 ping 8.8.8.8`
3. **Deploy secure stack**: `docker compose up -d`
4. **Verify security**: `docker compose exec app capsh --print`
5. **Test restrictions**: `docker compose exec app mount -t tmpfs none /mnt`

## Production Notes

- Always use `--cap-drop ALL` as starting point, then add only required capabilities
- NET_BIND_SERVICE needed only for ports < 1024
- Avoid CAP_SYS_ADMIN (system administration) and CAP_DAC_OVERRIDE (bypass file permissions)
- Use security-opt no-new-privileges:true to prevent privilege escalation
- Test capability requirements in development environment

## Common Capability Requirements

### Web Servers
- NET_BIND_SERVICE (ports 80/443)
- CHOWN (log file ownership)

### Databases
- Usually no additional capabilities needed
- Run as dedicated user (postgres, mysql)

### Application Servers
- Usually no capabilities needed
- Use unprivileged ports (8080, 3000)

## Key Takeaway

Linux capabilities enable fine-grained privilege control - drop all capabilities by default and add only what's absolutely necessary for your application to function.