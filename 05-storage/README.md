# Phase 05: Storage & Volumes

> **Master Docker data persistence, volume management, and storage optimization for production workloads**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Design and implement persistent data storage strategies for containerized applications
- Choose appropriate volume types for different use cases and performance requirements
- Implement secure backup and restore procedures for containerized data
- Manage file permissions and ownership across container and host boundaries
- Optimize storage performance for high-throughput applications
- Handle stateful applications with proper data lifecycle management

## 📚 Concept Map

```
Docker Storage & Volumes
├── Volume Types & Use Cases
│   ├── Named Volumes (Docker-managed, Portable)
│   ├── Bind Mounts (Host Path Mapping)
│   ├── tmpfs Mounts (Memory-based, Ephemeral)
│   └── Anonymous Volumes (Temporary, Auto-created)
├── Data Persistence Patterns
│   ├── Database Storage (ACID, Backup-friendly)
│   ├── Application State (Config, Cache, Logs)
│   ├── Shared Data (Multi-container Access)
│   └── Development Workflows (Live Reload, Debugging)
├── Performance & Optimization
│   ├── Storage Drivers (Device Mapper, OverlayFS, ZFS)
│   ├── Volume Drivers (Local, NFS, Cloud Storage)
│   ├── I/O Performance Tuning
│   └── Caching Strategies
├── Security & Permissions
│   ├── User ID Mapping (Host ↔ Container)
│   ├── File Ownership Management
│   ├── Read-only Volumes
│   └── Encrypted Storage
└── Backup & Recovery
    ├── Volume Snapshots
    ├── Data Migration Strategies
    ├── Disaster Recovery Planning
    └── Cross-platform Portability
```

## 🔬 Core Topics

### 1. Volume Types and Selection

**Understanding Storage Options**

Docker provides multiple storage mechanisms, each optimized for different scenarios:

- **Named Volumes**: Docker-managed, portable, and persistent across container lifecycle
- **Bind Mounts**: Direct host filesystem mapping with full host access
- **tmpfs Mounts**: Memory-based storage for sensitive or temporary data
- **Anonymous Volumes**: Auto-created temporary volumes for container-specific data

**Key Benefits**:
- Data persistence beyond container lifecycle
- Sharing data between containers and host
- Performance optimization for different workload types
- Security isolation and access control

### 2. Data Persistence Patterns

**Production-Ready Storage Architecture**

Effective containerized applications require thoughtful data management:

- **Stateful Service Patterns**: Database storage with proper backup strategies
- **Configuration Management**: Separating config from application code
- **Log Aggregation**: Centralized logging with volume-based collection
- **Cache Management**: High-performance caching with appropriate storage types

**Critical Patterns**:
- Immutable infrastructure with mutable data
- Backup and restore automation
- Multi-environment data handling
- Performance monitoring and optimization

### 3. Performance Optimization

**Storage Performance Tuning**

Storage performance directly impacts application responsiveness:

- **Volume Driver Selection**: Choose drivers based on I/O patterns
- **Host Filesystem Optimization**: Tune underlying storage for Docker workloads
- **Container Layer Management**: Minimize layer size and optimize caching
- **Network Storage Integration**: Efficient cloud and distributed storage usage

**Performance Considerations**:
- Read vs write performance requirements
- Random vs sequential access patterns
- Throughput vs latency optimization
- Storage capacity planning

### 4. Security and Permissions

**Secure Storage Management**

Container storage security requires careful attention to permissions and access control:

- **User Namespace Mapping**: Align container and host user permissions
- **Volume Access Control**: Implement principle of least privilege
- **Encrypted Storage**: Protect data at rest and in transit
- **Audit and Compliance**: Track storage access and modifications

**Security Best Practices**:
- Never run containers as root when accessing host volumes
- Use read-only volumes when write access isn't needed
- Implement proper backup encryption
- Regular security audits of volume permissions

## 🛠 Prerequisites

- **Completed**: Phase 04 (Networking) - understanding of container communication
- **Docker**: 20.10+ with volume management capabilities
- **Storage Knowledge**: Basic understanding of filesystems, permissions, and I/O
- **Linux Concepts**: File ownership, permissions, and mounting (helpful)

## ⏱ Time Investment

- **Reading & Understanding**: 60 minutes
- **Hands-on Labs**: 120 minutes
- **Verification & Practice**: 30 minutes
- **Total**: ~3.5 hours

## 🎓 Learning Strategy

1. **Master Volume Types**: Understand when to use each storage option
2. **Practice Permission Management**: Handle user ID mapping correctly
3. **Implement Backup Strategies**: Create reliable data persistence
4. **Optimize Performance**: Tune storage for application requirements
5. **Build Production Patterns**: Apply storage best practices

## 📖 Topic Deep Dives

### Volume Types: Making the Right Choice

**Named Volumes (Recommended)**:
```bash
# Create named volume
docker volume create myapp-data

# Use in container
docker run -d --name webapp \
  -v myapp-data:/app/data \
  myapp:latest

# Volume survives container removal
docker rm webapp
docker volume ls  # myapp-data still exists
```

**Benefits of Named Volumes**:
- Docker manages storage location and optimization
- Portable across different hosts
- Backup and restore tooling integration
- Automatic cleanup when no longer referenced

**Bind Mounts (Development)**:
```bash
# Mount host directory
docker run -d --name dev-webapp \
  -v /host/src:/app/src \
  -v /host/data:/app/data \
  myapp:dev

# Changes on host appear immediately in container
# Perfect for development workflows
```

**When to Use Bind Mounts**:
- Development with live code reloading
- Sharing configuration files
- Direct host filesystem access needed
- Legacy application integration

**tmpfs Mounts (Security)**:
```bash
# Memory-based storage
docker run -d --name secure-app \
  --tmpfs /app/temp:rw,noexec,nosuid,size=100m \
  myapp:latest

# Data exists only in memory
# Automatically cleaned when container stops
```

**When to Use tmpfs**:
- Sensitive data (passwords, keys, tokens)
- High-performance temporary storage
- Preventing disk-based data leakage
- Cache data that shouldn't persist

### Data Persistence Architecture

**Database Storage Pattern**:
```bash
# Production database with named volume
docker volume create postgres-data

docker run -d --name database \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secure123 \
  postgres:13

# Data persists across container updates
docker stop database
docker rm database
docker run -d --name database-updated \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secure123 \
  postgres:14  # Same data, new version
```

**Application Configuration Pattern**:
```bash
# Separate config from application
docker volume create app-config

# Initialize config volume
docker run --rm \
  -v app-config:/config \
  alpine sh -c 'echo "env=production" > /config/app.env'

# Use config in application
docker run -d --name webapp \
  -v app-config:/app/config:ro \
  myapp:latest
```

**Shared Storage Pattern**:
```bash
# Shared volume between multiple containers
docker volume create shared-data

# Writer container
docker run -d --name data-producer \
  -v shared-data:/data \
  producer:latest

# Reader container
docker run -d --name data-consumer \
  -v shared-data:/data:ro \
  consumer:latest

# Both containers access same persistent data
```

### Permission Management

**User ID Mapping Challenge**:
```bash
# Common permission problem
docker run --rm \
  -v /host/data:/app/data \
  alpine touch /app/data/test.txt

# File created with root ownership
ls -la /host/data/  # root:root test.txt

# Fix: Run container with same user ID as host
docker run --rm \
  -v /host/data:/app/data \
  --user $(id -u):$(id -g) \
  alpine touch /app/data/test2.txt

# File created with current user ownership
ls -la /host/data/  # user:user test2.txt
```

**Production Permission Strategy**:
```bash
# Create specific user for application
FROM node:18-alpine
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 appuser -G appgroup
USER appuser

# Deploy with consistent user ID
docker run -d --name webapp \
  --user 1001:1001 \
  -v app-data:/app/data \
  myapp:latest
```

### Performance Optimization

**Volume Driver Selection**:
```bash
# Local storage (default)
docker volume create --driver local app-data

# Create volume with specific options
docker volume create --driver local \
  --opt type=ext4 \
  --opt device=/dev/sdb1 \
  fast-storage

# Use optimized volume
docker run -d --name high-perf-app \
  -v fast-storage:/app/data \
  database:latest
```

**Storage Performance Testing**:
```bash
# Benchmark volume performance
docker run --rm \
  -v test-volume:/data \
  busybox sh -c '
    echo "Testing write performance..."
    time dd if=/dev/zero of=/data/test bs=1M count=100
    echo "Testing read performance..."
    time dd if=/data/test of=/dev/null bs=1M
    rm /data/test
  '
```

**Caching Strategies**:
```bash
# Application with cache volume
docker volume create app-cache

docker run -d --name webapp \
  -v app-data:/app/data \
  -v app-cache:/app/cache \
  --tmpfs /app/temp \
  myapp:latest

# Different storage types for different access patterns
```

## 🔍 Common Use Cases & Patterns

### Pattern 1: Database with Backup

```bash
# Production database setup
docker volume create postgres-data
docker volume create postgres-backups

# Database container
docker run -d --name database \
  -v postgres-data:/var/lib/postgresql/data \
  -v postgres-backups:/backups \
  -e POSTGRES_PASSWORD=secure123 \
  postgres:13

# Backup script container
docker run --rm \
  -v postgres-data:/data:ro \
  -v postgres-backups:/backups \
  postgres:13 pg_dump -U postgres -h database mydb > /backups/backup-$(date +%Y%m%d).sql

# Automated backup with cron
echo "0 2 * * * docker run --rm -v postgres-data:/data:ro -v postgres-backups:/backups postgres:13 pg_dump -U postgres mydb > /backups/backup-\$(date +\\%Y\\%m\\%d).sql" | crontab -
```

### Pattern 2: Development Environment

```bash
# Development with live reload
PROJECT_DIR=/path/to/project
docker run -d --name dev-env \
  -v $PROJECT_DIR/src:/app/src \
  -v $PROJECT_DIR/config:/app/config \
  -v dev-node-modules:/app/node_modules \
  -p 3000:3000 \
  node:18 npm run dev

# Source code changes reflect immediately
# node_modules stored in named volume for performance
```

### Pattern 3: Multi-Stage Application

```bash
# Web application with separate data concerns
docker volume create webapp-data
docker volume create webapp-logs
docker volume create webapp-cache

# Web server
docker run -d --name web \
  -v webapp-data:/app/data:ro \
  -v webapp-logs:/app/logs \
  -p 80:80 \
  nginx:alpine

# Application server
docker run -d --name app \
  -v webapp-data:/app/data \
  -v webapp-cache:/app/cache \
  myapp:latest

# Log processor
docker run -d --name logs \
  -v webapp-logs:/logs:ro \
  logstash:latest
```

### Pattern 4: Secure Configuration Management

```bash
# Secrets and config separation
docker volume create app-config

# Initialize secure config (run once)
docker run --rm \
  -v app-config:/config \
  alpine sh -c '
    echo "DATABASE_URL=postgresql://user:pass@db:5432/app" > /config/.env
    echo "API_KEY=secret-key-here" >> /config/.env
    chmod 600 /config/.env
  '

# Use config in application (read-only)
docker run -d --name webapp \
  -v app-config:/app/config:ro \
  --user 1001:1001 \
  myapp:latest
```

## 💡 Production Considerations

### Storage Security Best Practices

**Volume Encryption**:
```bash
# Encrypted volume with dm-crypt
sudo cryptsetup luksFormat /dev/sdb
sudo cryptsetup luksOpen /dev/sdb encrypted-disk
sudo mkfs.ext4 /dev/mapper/encrypted-disk
sudo mount /dev/mapper/encrypted-disk /var/lib/docker/volumes/encrypted-data/_data

# Use encrypted volume
docker volume create --driver local \
  --opt type=ext4 \
  --opt device=/dev/mapper/encrypted-disk \
  encrypted-volume
```

**Read-Only Volumes**:
```bash
# Prevent accidental data modification
docker run -d --name readonly-app \
  -v app-data:/app/data:ro \
  -v app-config:/app/config:ro \
  --tmpfs /app/temp \
  myapp:latest

# Application can read data but not modify it
```

### Backup and Recovery

**Automated Volume Backup**:
```bash
#!/bin/bash
# backup-volumes.sh
BACKUP_DIR="/backup/docker-volumes"
DATE=$(date +%Y%m%d-%H%M%S)

backup_volume() {
    local volume_name=$1
    local backup_path="$BACKUP_DIR/$volume_name-$DATE.tar.gz"
    
    echo "Backing up volume: $volume_name"
    docker run --rm \
        -v $volume_name:/data:ro \
        -v $BACKUP_DIR:/backup \
        alpine tar czf /backup/$(basename $backup_path) -C /data .
    
    echo "Backup created: $backup_path"
}

# Backup all named volumes
for volume in $(docker volume ls -q); do
    backup_volume $volume
done
```

**Volume Restore Procedure**:
```bash
#!/bin/bash
# restore-volume.sh
restore_volume() {
    local volume_name=$1
    local backup_file=$2
    
    # Create new volume
    docker volume create $volume_name
    
    # Restore data
    docker run --rm \
        -v $volume_name:/data \
        -v $(dirname $backup_file):/backup \
        alpine tar xzf /backup/$(basename $backup_file) -C /data
    
    echo "Volume $volume_name restored from $backup_file"
}

# Usage: ./restore-volume.sh myapp-data /backup/myapp-data-20231201-120000.tar.gz
```

### Performance Monitoring

**Storage Metrics Collection**:
```bash
# Monitor volume usage
docker run --rm \
  -v /var/lib/docker:/docker:ro \
  alpine du -sh /docker/volumes/*/_data

# Per-container storage stats
docker stats --format "table {{.Container}}\t{{.BlockIO}}"

# Volume performance testing
docker run --rm \
  -v test-volume:/test \
  busybox fio --name=random-write --ioengine=sync --rw=randwrite --bs=4k --size=1G --numjobs=1 --directory=/test
```

### Multi-Environment Storage

**Environment-Specific Volumes**:
```bash
# Development
docker run -d --name webapp-dev \
  -v $(pwd)/src:/app/src \
  -v dev-data:/app/data \
  myapp:dev

# Staging  
docker run -d --name webapp-staging \
  -v staging-data:/app/data \
  myapp:staging

# Production
docker run -d --name webapp-prod \
  -v prod-data:/app/data \
  myapp:prod

# Each environment has isolated storage
```

## 🚨 Common Storage Problems

### Volume Permission Issues

**Problem**: Files created with wrong ownership
```bash
# Creates files as root
docker run --rm -v /host/data:/data alpine touch /data/file.txt
ls -la /host/data/  # root:root file.txt
```

**Solution**: Use proper user mapping
```bash
# Run with host user ID
docker run --rm \
  -v /host/data:/data \
  --user $(id -u):$(id -g) \
  alpine touch /data/file.txt
```

### Storage Performance Issues

**Problem**: Slow database performance
```bash
# Diagnose I/O performance
docker exec database iostat -x 1

# Check volume driver
docker volume inspect db-data | grep Driver
```

**Solution**: Optimize storage configuration
```bash
# Use appropriate volume driver
docker volume create --driver local \
  --opt type=ext4 \
  --opt o=noatime,nodiratime \
  fast-db-storage
```

### Data Loss Prevention

**Problem**: Accidental volume deletion
```bash
# Dangerous: removes volume and data
docker volume rm app-data
```

**Solution**: Implement backup before cleanup
```bash
# Safe volume removal with backup
backup_volume app-data
docker volume rm app-data
```

## 📊 Storage Monitoring and Troubleshooting

### Volume Health Checks

```bash
# Check volume integrity
check_volume_health() {
    local volume_name=$1
    
    echo "Checking volume: $volume_name"
    
    # Check if volume exists
    if ! docker volume inspect $volume_name >/dev/null 2>&1; then
        echo "❌ Volume does not exist"
        return 1
    fi
    
    # Check volume size
    SIZE=$(docker run --rm -v $volume_name:/data alpine du -sh /data | cut -f1)
    echo "Volume size: $SIZE"
    
    # Check permissions
    docker run --rm -v $volume_name:/data alpine ls -la /data
    
    # Test read/write access
    docker run --rm -v $volume_name:/data alpine sh -c '
        echo "test" > /data/.health_check
        cat /data/.health_check
        rm /data/.health_check
    ' && echo "✅ Volume is healthy" || echo "❌ Volume has issues"
}

# Check all volumes
for volume in $(docker volume ls -q); do
    check_volume_health $volume
done
```

### Performance Benchmarking

```bash
# Comprehensive storage benchmark
benchmark_storage() {
    local volume_name=$1
    
    echo "Benchmarking volume: $volume_name"
    
    docker run --rm -v $volume_name:/test busybox sh -c '
        echo "=== Sequential Write Test ==="
        time dd if=/dev/zero of=/test/seq_write bs=1M count=100
        
        echo "=== Sequential Read Test ==="
        time dd if=/test/seq_write of=/dev/null bs=1M
        
        echo "=== Random Write Test ==="
        for i in $(seq 1 100); do
            dd if=/dev/urandom of=/test/random_$i bs=1M count=1 2>/dev/null
        done
        
        echo "=== Cleanup ==="
        rm -f /test/seq_write /test/random_*
        
        echo "Benchmark completed"
    '
}
```

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Create and manage different types of Docker volumes appropriately
- [ ] Implement proper file permissions and user ID mapping
- [ ] Design backup and restore procedures for persistent data
- [ ] Optimize storage performance for different application types
- [ ] Secure sensitive data using appropriate storage methods
- [ ] Troubleshoot common volume and permission issues

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p05-m01-l01` - Volume Types and Selection Guide
- `p05-m01-l02` - Backup and Restore Strategies
- `p05-m01-l03` - Permission Handling and Security
- `p05-m01-l04` - Performance Optimization Techniques

## 🎯 What's Next

After mastering Docker storage and volumes:
- **Phase 06**: Docker Compose for multi-container applications
- **Phase 07**: Security hardening and best practices
- **Phase 08**: CI/CD integration and automation

---

> 💡 **Key Insight**: Proper storage management is crucial for stateful applications in production. Understanding volume types, permission handling, and performance optimization ensures data persistence, security, and optimal application performance. These concepts form the foundation for complex multi-container architectures and production deployments.