# p05-m01-l01: Volume Types and Selection Guide

> **Duration**: 4 minutes | **Anchor**: `p05-m01-l01` | **Type**: Decision Guide + Quick Practice

## 🎯 Learning Objective

Master the selection criteria for different Docker volume types and understand when to use each type based on application requirements and operational constraints.

## 📋 Volume Type Decision Matrix

### Quick Selection Guide

| Need | Use Case | Volume Type | Command Example |
|------|----------|-------------|-----------------|
| **Production Data** | Database, User files | Named Volume | `docker volume create app-data` |
| **Development** | Live code reload | Bind Mount | `-v $(pwd)/src:/app/src` |
| **Secrets/Cache** | Temporary sensitive data | tmpfs | `--tmpfs /secrets:size=10m` |
| **Build Artifacts** | Temporary build files | Anonymous | `VOLUME /app/build` |

## 🔍 Volume Type Deep Dive

### Named Volumes (Production Choice)

```bash
# Create and use named volume
docker volume create myapp-data
docker run -d --name webapp \
  -v myapp-data:/app/data \
  nginx

# Key benefits:
# ✅ Docker manages storage location
# ✅ Survives container removal  
# ✅ Easy backup and migration
# ✅ Cross-platform portability
```

**When to use**:
- Production applications
- Database storage
- User-generated content
- Any data that must survive container updates

### Bind Mounts (Development Choice)

```bash
# Mount host directory into container
docker run -d --name dev-app \
  -v /host/project:/app/project \
  -v /host/config:/app/config:ro \
  node:18

# Key benefits:
# ✅ Direct host filesystem access
# ✅ Real-time file synchronization
# ✅ Host tools can edit files
# ✅ Zero Docker storage overhead
```

**When to use**:
- Development environments
- Configuration file injection
- Source code mounting
- Integration with host tools

### tmpfs Mounts (Security Choice)

```bash
# Memory-based storage
docker run -d --name secure-app \
  --tmpfs /app/secrets:rw,noexec,nosuid,size=100m \
  --tmpfs /app/cache:rw,size=256m \
  myapp:latest

# Key benefits:
# ✅ Memory-only storage (no disk writes)
# ✅ Automatic cleanup on container stop
# ✅ High performance (RAM speed)
# ✅ Security (no data persistence)
```

**When to use**:
- Sensitive data (passwords, tokens, keys)
- High-performance cache
- Temporary processing data
- Build artifacts that shouldn't persist

## ⚡ Quick Practice (3 minutes)

```bash
echo "=== Volume Type Practice ==="

# 1. Named Volume: Production database
docker volume create practice-db
docker run -d --name db-prod \
  -v practice-db:/var/lib/mysql \
  mysql:8.0

echo "Named volume for persistent data: ✅"

# 2. Bind Mount: Development environment
mkdir -p ./dev-src
echo "console.log('Hello from host');" > ./dev-src/app.js

docker run --rm \
  -v $(pwd)/dev-src:/app \
  node:18 node /app/app.js

echo "Bind mount for development: ✅"

# 3. tmpfs: Secure temporary storage
docker run --rm \
  --tmpfs /secure:rw,noexec,size=50m \
  alpine sh -c '
    echo "secret_token=abc123" > /secure/token
    echo "Secret stored in memory: $(cat /secure/token)"
    echo "No disk persistence - security guaranteed"
  '

echo "tmpfs for secure data: ✅"

# 4. Anonymous Volume: Temporary build cache
docker run --rm \
  -v /app/build \
  alpine sh -c '
    echo "build artifact" > /app/build/output.txt
    ls -la /app/build/
    echo "Anonymous volume created automatically"
  '

echo "Anonymous volume for temp data: ✅"

# Cleanup
docker rm -f db-prod
docker volume rm practice-db
rm -rf dev-src
```

## 🎯 Decision Flowchart

```
Data Storage Decision Tree
├── Data must survive container restarts?
│   ├── Yes → Data shared between containers?
│   │   ├── Yes → Named Volume (shared persistent)
│   │   └── No → Named Volume (isolated persistent)
│   └── No → High performance required?
│       ├── Yes → tmpfs (memory-based)
│       └── No → Anonymous Volume
├── Development environment?
│   └── Yes → Need host file editing?
│       ├── Yes → Bind Mount
│       └── No → Named Volume
└── Security-sensitive data?
    └── Yes → tmpfs (no disk persistence)
```

## 💡 Production Selection Criteria

### Performance Ranking (fastest to slowest)
1. **tmpfs** - Memory speed, no I/O overhead
2. **Named Volume** - Docker-optimized storage
3. **Bind Mount** - Host filesystem performance
4. **Anonymous Volume** - Docker-managed temporary

### Security Ranking (most to least secure)
1. **tmpfs** - No persistence, memory-only
2. **Named Volume** - Docker-managed isolation
3. **Anonymous Volume** - Temporary isolation  
4. **Bind Mount** - Direct host access

### Management Complexity (easiest to hardest)
1. **Named Volume** - Docker CLI management
2. **Anonymous Volume** - Automatic lifecycle
3. **tmpfs** - Simple memory allocation
4. **Bind Mount** - Host filesystem management

## 🚨 Common Selection Mistakes

❌ **Using bind mounts in production**
```bash
# Fragile - depends on host filesystem structure
docker run -v /host/data:/app/data myapp:prod
```

✅ **Use named volumes for production**
```bash
# Portable and Docker-managed
docker volume create app-data
docker run -v app-data:/app/data myapp:prod
```

❌ **Using named volumes for development**
```bash
# Can't edit files with host tools
docker volume create dev-src
docker run -v dev-src:/app/src myapp:dev
```

✅ **Use bind mounts for development**
```bash
# Live reload and host tool integration
docker run -v $(pwd)/src:/app/src myapp:dev
```

❌ **Storing secrets in named volumes**
```bash
# Data persists on disk
docker run -v secrets:/app/secrets myapp
```

✅ **Use tmpfs for secrets**
```bash
# Memory-only, no disk persistence
docker run --tmpfs /app/secrets:size=10m myapp
```

## 🔧 Advanced Selection Patterns

### Multi-Tier Application Storage

```bash
# Frontend: Static assets (named volume)
docker run -d --name frontend \
  -v webapp-assets:/usr/share/nginx/html \
  nginx

# Backend: Application data (named volume) + cache (tmpfs)
docker run -d --name backend \
  -v app-data:/app/data \
  --tmpfs /app/cache:size=256m \
  myapp:backend

# Database: Persistent data (optimized named volume)
docker volume create --driver local \
  --opt type=ext4 \
  --opt o=noatime \
  db-data

docker run -d --name database \
  -v db-data:/var/lib/postgresql/data \
  --tmpfs /tmp:size=100m \
  postgres:13
```

### Development Environment Setup

```bash
# Source code: Bind mount for live editing
# Dependencies: Named volume for performance
# Logs: tmpfs for high-frequency writes

docker run -d --name dev-env \
  -v $(pwd)/src:/app/src \
  -v node_modules:/app/node_modules \
  --tmpfs /app/logs:size=100m \
  -p 3000:3000 \
  node:18 npm run dev
```

### Microservices Storage Strategy

```bash
# Each service gets appropriate storage types
# Auth service: tmpfs for sessions
docker run -d --name auth \
  --tmpfs /app/sessions:size=50m \
  auth:latest

# User service: named volume for profiles
docker run -d --name users \
  -v user-data:/app/data \
  users:latest

# Logging service: bind mount for host access
docker run -d --name logs \
  -v /var/log/app:/app/logs \
  fluentd:latest
```

## 🔗 Key Decision Principles

1. **Production = Named Volumes**: Reliable, managed, portable
2. **Development = Bind Mounts**: Live editing, host integration
3. **Secrets = tmpfs**: Security through non-persistence
4. **Cache = tmpfs**: Performance through memory storage
5. **Build Artifacts = Anonymous**: Temporary, auto-cleanup
6. **Configuration = Bind Mount (readonly)**: Easy updates, version control

## 📊 Volume Type Comparison Summary

| Aspect | Named Volume | Bind Mount | tmpfs | Anonymous |
|--------|-------------|------------|-------|-----------|
| **Persistence** | ✅ Permanent | ✅ Permanent | ❌ Temporary | ⚠️ Container lifecycle |
| **Performance** | 🟢 Good | 🟢 Good | 🔥 Excellent | 🟢 Good |
| **Security** | 🟢 High | 🟡 Medium | 🔥 Highest | 🟢 High |
| **Portability** | 🔥 Excellent | 🔴 Poor | 🔥 Excellent | 🟢 Good |
| **Management** | 🔥 Easy | 🟡 Manual | 🟢 Simple | 🔥 Automatic |
| **Best for** | Production | Development | Secrets/Cache | Temp files |

---

**Next**: Backup and Restore Strategies (`p05-m01-l02`)