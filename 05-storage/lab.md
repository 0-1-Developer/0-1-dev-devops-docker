# Phase 05: Storage & Volumes - Hands-on Labs

> **Practical exercises for mastering Docker storage, data persistence, and volume management**

## 🎯 Lab Overview

This lab phase provides 120 minutes of hands-on experience with Docker storage and volume management. You'll work with different volume types, implement backup strategies, handle file permissions, and optimize storage performance for real-world scenarios.

## ⏱ Time Allocation

- **Lab 1**: Volume Types and Data Persistence (30 minutes)
- **Lab 2**: Backup and Restore Procedures (30 minutes) 
- **Lab 3**: Permission Management and Security (30 minutes)
- **Lab 4**: Performance Optimization and Monitoring (30 minutes)

## 🔧 Lab Prerequisites

- Docker 20.10+ with volume management
- Basic command line experience
- Text editor for configuration files
- Understanding of file permissions (helpful)

---

## Lab 1: Volume Types and Data Persistence
**Duration**: 30 minutes | **Difficulty**: Intermediate

### 🎯 Objectives
- Compare different Docker volume types in practice
- Implement data persistence patterns for various applications
- Understand volume lifecycle and portability

### 📋 Lab Setup

```bash
# Clean environment
docker system prune -f
docker volume prune -f

# Create lab workspace
mkdir -p ~/docker-labs/storage && cd ~/docker-labs/storage
```

### Task 1.1: Volume Type Comparison (10 minutes)

**Test Named Volumes vs Bind Mounts vs tmpfs**

```bash
echo "=== Task 1.1: Volume Type Comparison ==="

# 1. Create named volume
docker volume create lab-named-volume

# 2. Test named volume
docker run --rm --name named-test \
  -v lab-named-volume:/data \
  alpine sh -c '
    echo "Named volume data" > /data/named.txt
    echo "Data written to named volume"
  '

# 3. Test bind mount
mkdir -p ./bind-mount-data
docker run --rm --name bind-test \
  -v $(pwd)/bind-mount-data:/data \
  alpine sh -c '
    echo "Bind mount data" > /data/bind.txt
    echo "Data written to bind mount"
  '

# 4. Test tmpfs mount
docker run --rm --name tmpfs-test \
  --tmpfs /data:rw,noexec,nosuid,size=50m \
  alpine sh -c '
    echo "tmpfs data" > /data/tmpfs.txt
    echo "Data written to tmpfs"
    ls -la /data/
  '

echo "=== Verification ==="
# Check named volume persistence
docker run --rm -v lab-named-volume:/data alpine cat /data/named.txt

# Check bind mount persistence  
cat ./bind-mount-data/bind.txt

# Check tmpfs (should be gone)
echo "tmpfs data persists: $([ -f /tmp/tmpfs.txt ] && echo 'Yes' || echo 'No (expected)')"
```

**🔍 Analysis Questions:**
1. Which volume type persists after container removal?
2. Where is the named volume data actually stored?
3. When would you use tmpfs over other volume types?

### Task 1.2: Database Persistence Pattern (10 minutes)

**Implement database storage with upgrade scenario**

```bash
echo "=== Task 1.2: Database Persistence ==="

# Create database volume
docker volume create postgres-data

# Deploy PostgreSQL v13
docker run -d --name postgres-v13 \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  -e POSTGRES_PASSWORD=testpass \
  postgres:13

# Wait for database to initialize
echo "Waiting for database initialization..."
sleep 10

# Create test data
docker exec postgres-v13 psql -U testuser -d testdb -c "
  CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50));
  INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');
"

# Verify data
echo "=== Initial Data ==="
docker exec postgres-v13 psql -U testuser -d testdb -c "SELECT * FROM users;"

# Upgrade to PostgreSQL v14
echo "=== Database Upgrade Simulation ==="
docker stop postgres-v13
docker rm postgres-v13

# Deploy new version with same volume
docker run -d --name postgres-v14 \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  -e POSTGRES_PASSWORD=testpass \
  postgres:14

# Wait for startup
sleep 10

# Verify data persistence
echo "=== Data After Upgrade ==="
docker exec postgres-v14 psql -U testuser -d testdb -c "SELECT * FROM users;"

# Add more data to show continued operation
docker exec postgres-v14 psql -U testuser -d testdb -c "
  INSERT INTO users (name) VALUES ('David');
  SELECT * FROM users;
"

echo "✅ Database upgrade with data persistence completed"
```

### Task 1.3: Multi-Container Shared Storage (10 minutes)

**Share data between multiple containers**

```bash
echo "=== Task 1.3: Shared Storage Pattern ==="

# Create shared volume
docker volume create shared-data

# Producer container (writes data)
docker run -d --name data-producer \
  -v shared-data:/shared \
  alpine sh -c '
    while true; do
      echo "$(date): Producer writing data" >> /shared/producer.log
      sleep 5
    done
  '

# Consumer container (reads data)
docker run -d --name data-consumer \
  -v shared-data:/shared:ro \
  alpine sh -c '
    while true; do
      echo "=== Consumer reading at $(date) ==="
      tail -3 /shared/producer.log 2>/dev/null || echo "No data yet"
      sleep 10
    done
  '

# Monitor container (analyzes data)
docker run -d --name data-monitor \
  -v shared-data:/shared:ro \
  alpine sh -c '
    while true; do
      COUNT=$(wc -l /shared/producer.log 2>/dev/null | cut -d" " -f1 || echo 0)
      echo "Monitor: $COUNT lines in producer.log at $(date)"
      sleep 15
    done
  '

# Observe shared data access
echo "=== Monitoring Shared Data (30 seconds) ==="
sleep 30

# Check logs from all containers
echo "=== Producer logs ==="
docker logs data-producer | tail -3

echo "=== Consumer logs ==="
docker logs data-consumer | tail -3

echo "=== Monitor logs ==="
docker logs data-monitor | tail -2

# Cleanup
docker stop data-producer data-consumer data-monitor
docker rm data-producer data-consumer data-monitor

echo "✅ Shared storage pattern completed"
```

### 🧪 Lab 1 Verification

```bash
echo "=== Lab 1 Verification ==="

# 1. Verify volume persistence
echo "Named volumes created:"
docker volume ls | grep lab-

# 2. Verify bind mount files
echo "Bind mount files:"
ls -la bind-mount-data/

# 3. Check database volume
echo "Database volume size:"
docker run --rm -v postgres-data:/data alpine du -sh /data

# 4. Verify shared volume
echo "Shared volume contents:"
docker run --rm -v shared-data:/data alpine ls -la /data

echo "✅ Lab 1 completed successfully"
```

---

## Lab 2: Backup and Restore Procedures
**Duration**: 30 minutes | **Difficulty**: Advanced

### 🎯 Objectives
- Implement automated volume backup strategies
- Practice disaster recovery procedures
- Handle data migration between environments

### Task 2.1: Basic Volume Backup (10 minutes)

**Create and test volume backup procedures**

```bash
echo "=== Task 2.1: Basic Volume Backup ==="

# Create volume with test data
docker volume create backup-demo

# Populate with sample data
docker run --rm \
  -v backup-demo:/data \
  alpine sh -c '
    mkdir -p /data/app /data/config /data/logs
    echo "Application data" > /data/app/app.txt
    echo "config_key=value" > /data/config/app.conf
    echo "$(date): Application started" > /data/logs/app.log
    echo "Sample binary data" > /data/app/binary.dat
  '

# Create backup directory
mkdir -p ./backups

# Backup volume using tar
docker run --rm \
  -v backup-demo:/source:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/backup-demo-$(date +%Y%m%d-%H%M%S).tar.gz -C /source .

# List backup files
echo "=== Backup Created ==="
ls -lh backups/

# Verify backup contents
echo "=== Backup Contents ==="
BACKUP_FILE=$(ls backups/backup-demo-*.tar.gz | head -1)
tar -tzf "$BACKUP_FILE" | head -10

echo "✅ Basic backup completed"
```

### Task 2.2: Automated Backup with Scheduling (10 minutes)

**Implement production-ready backup automation**

```bash
echo "=== Task 2.2: Automated Backup System ==="

# Create backup script
cat > backup-script.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/docker-volumes"
DATE=$(date +%Y%m%d-%H%M%S)
LOG_FILE="/backup/backup.log"

# Create backup directory
mkdir -p $BACKUP_DIR

# Function to backup a volume
backup_volume() {
    local volume_name=$1
    local backup_file="$BACKUP_DIR/${volume_name}-${DATE}.tar.gz"
    
    echo "$(date): Starting backup of volume: $volume_name" >> $LOG_FILE
    
    # Create backup
    docker run --rm \
        -v $volume_name:/data:ro \
        -v $BACKUP_DIR:/backup \
        alpine tar czf /backup/$(basename $backup_file) -C /data . \
        && echo "$(date): Successfully backed up $volume_name" >> $LOG_FILE \
        || echo "$(date): Failed to backup $volume_name" >> $LOG_FILE
}

# Backup all volumes (or specific ones)
for volume in postgres-data backup-demo shared-data; do
    if docker volume inspect $volume >/dev/null 2>&1; then
        backup_volume $volume
    else
        echo "$(date): Volume $volume not found, skipping" >> $LOG_FILE
    fi
done

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
echo "$(date): Backup job completed" >> $LOG_FILE
EOF

chmod +x backup-script.sh

# Create backup directory
mkdir -p ./backup/docker-volumes

# Run backup script
BACKUP_DIR=$(pwd)/backup/docker-volumes ./backup-script.sh

# Check results
echo "=== Backup Results ==="
cat backup/backup.log
echo ""
echo "=== Backup Files ==="
ls -lh backup/docker-volumes/

echo "✅ Automated backup system tested"
```

### Task 2.3: Disaster Recovery Simulation (10 minutes)

**Test complete data loss and recovery scenario**

```bash
echo "=== Task 2.3: Disaster Recovery Simulation ==="

# 1. Create application with data
docker volume create disaster-test
docker run --rm \
  -v disaster-test:/app/data \
  alpine sh -c '
    echo "Critical application data" > /app/data/critical.txt
    echo "User preferences" > /app/data/config.json
    mkdir -p /app/data/uploads
    echo "User uploaded file" > /app/data/uploads/document.pdf
  '

# 2. Create backup
docker run --rm \
  -v disaster-test:/source:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/disaster-test-backup.tar.gz -C /source .

echo "=== Pre-disaster state ==="
docker run --rm -v disaster-test:/data alpine find /data -type f

# 3. SIMULATE DISASTER - Remove volume
echo "=== SIMULATING DISASTER (volume deletion) ==="
docker volume rm disaster-test
echo "Volume deleted - data lost!"

# 4. RECOVERY PROCEDURE
echo "=== DISASTER RECOVERY IN PROGRESS ==="

# Recreate volume
docker volume create disaster-test

# Restore from backup
docker run --rm \
  -v disaster-test:/target \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/disaster-test-backup.tar.gz -C /target

# 5. Verify recovery
echo "=== Post-recovery state ==="
docker run --rm -v disaster-test:/data alpine find /data -type f

echo "=== Verify file contents ==="
docker run --rm -v disaster-test:/data alpine cat /data/critical.txt

echo "✅ Disaster recovery simulation completed successfully"
```

### 🧪 Lab 2 Verification

```bash
echo "=== Lab 2 Verification ==="

# Check backup files exist
echo "Backup files created:"
ls -la backups/

# Verify backup script execution
echo "Backup log:"
cat backup/backup.log | tail -5

# Test restore capability
echo "Testing restore from any backup:"
LATEST_BACKUP=$(ls backups/*.tar.gz | tail -1)
echo "Latest backup: $LATEST_BACKUP"
tar -tzf "$LATEST_BACKUP" | wc -l
echo "files in backup"

echo "✅ Lab 2 verification completed"
```

---

## Lab 3: Permission Management and Security
**Duration**: 30 minutes | **Difficulty**: Intermediate

### 🎯 Objectives
- Understand and resolve permission issues between containers and host
- Implement secure volume access patterns
- Handle user ID mapping correctly

### Task 3.1: Permission Problem Identification (10 minutes)

**Reproduce and understand common permission issues**

```bash
echo "=== Task 3.1: Permission Problem Demo ==="

# Create host directory
mkdir -p ./permission-test
echo "Host file created by $(whoami)" > ./permission-test/host-file.txt

# 1. Demonstrate the problem - container as root
docker run --rm \
  -v $(pwd)/permission-test:/data \
  alpine sh -c '
    whoami
    id
    echo "Container file by root" > /data/container-file.txt
    ls -la /data/
  '

# Check file ownership on host
echo "=== File ownership on host ==="
ls -la permission-test/

# Show the problem - host user cannot modify container-created files
echo "Trying to modify container-created file as host user:"
echo "additional data" >> permission-test/container-file.txt 2>&1 || echo "Permission denied (expected)"

# 2. Show another common issue - wrong user in container
docker run --rm \
  -v $(pwd)/permission-test:/data \
  --user 1000:1000 \
  alpine sh -c '
    whoami 2>/dev/null || echo "User does not exist in container"
    id
    touch /data/user1000-file.txt 2>&1 || echo "Cannot create file"
  '

echo "✅ Permission problems demonstrated"
```

### Task 3.2: User ID Mapping Solutions (10 minutes)

**Implement proper permission management**

```bash
echo "=== Task 3.2: Permission Solutions ==="

# Solution 1: Run container with host user ID
echo "=== Solution 1: Host User ID Mapping ==="
docker run --rm \
  -v $(pwd)/permission-test:/data \
  --user $(id -u):$(id -g) \
  alpine sh -c '
    id
    echo "File created with host user ID" > /data/solution1.txt
    ls -la /data/solution1.txt
  '

# Verify host can access file
echo "Host verification:"
cat permission-test/solution1.txt
echo "additional content" >> permission-test/solution1.txt
echo "✅ Host can modify file created by container"

# Solution 2: Create matching user in container
echo "=== Solution 2: Container User Creation ==="
cat > Dockerfile.user << EOF
FROM alpine
RUN addgroup -g $(id -g) hostgroup && \
    adduser -D -u $(id -u) -G hostgroup hostuser
USER hostuser
CMD ["sh"]
EOF

docker build -f Dockerfile.user -t alpine-with-user .

docker run --rm \
  -v $(pwd)/permission-test:/data \
  alpine-with-user sh -c '
    whoami
    id
    echo "File with proper user setup" > /data/solution2.txt
    ls -la /data/solution2.txt
  '

echo "Host verification for solution 2:"
ls -la permission-test/solution2.txt

# Solution 3: Use numeric user ID with proper setup
echo "=== Solution 3: Application-specific User ==="
HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker run --rm \
  -v $(pwd)/permission-test:/data \
  -e HOST_UID=$HOST_UID \
  -e HOST_GID=$HOST_GID \
  alpine sh -c '
    addgroup -g $HOST_GID appgroup
    adduser -D -u $HOST_UID -G appgroup appuser
    su appuser -c "
      echo \"File from app user\" > /data/solution3.txt
      ls -la /data/solution3.txt
    "
  '

echo "✅ Permission solutions implemented"
```

### Task 3.3: Secure Volume Patterns (10 minutes)

**Implement security-focused volume configurations**

```bash
echo "=== Task 3.3: Secure Volume Patterns ==="

# 1. Read-only volumes
docker volume create readonly-config
docker run --rm \
  -v readonly-config:/config \
  alpine sh -c '
    echo "app_mode=production" > /config/app.conf
    echo "secret_key=abc123" > /config/secrets.conf
  '

# Use config as read-only
docker run --rm \
  -v readonly-config:/config:ro \
  alpine sh -c '
    echo "=== Reading config ==="
    cat /config/app.conf
    echo "=== Attempting write (should fail) ==="
    echo "hacker=true" >> /config/app.conf 2>&1 || echo "Write blocked (good!)"
  '

# 2. tmpfs for secrets
echo "=== tmpfs for sensitive data ==="
docker run --rm \
  --tmpfs /secrets:rw,noexec,nosuid,size=10m \
  alpine sh -c '
    echo "sensitive_token=secret123" > /secrets/token
    echo "=== Secret stored in memory ==="
    cat /secrets/token
    echo "=== Checking if secret persists (it should not) ==="
  '

# Verify tmpfs doesn't persist
echo "Checking if secret file persists (should be no):"
[ -f /tmp/token ] && echo "SECURITY ISSUE: Secret persisted!" || echo "✅ Secret properly isolated"

# 3. Secure database setup
echo "=== Secure Database Configuration ==="
docker volume create secure-db-data

# Create database with proper security
docker run -d --name secure-db \
  -v secure-db-data:/var/lib/postgresql/data \
  --tmpfs /tmp \
  --tmpfs /var/run/postgresql \
  --user 999:999 \
  -e POSTGRES_DB=secureapp \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/db_password \
  postgres:13

# Note: In production, you'd use Docker secrets or external secret management

# Stop secure database
docker stop secure-db
docker rm secure-db

echo "✅ Secure volume patterns demonstrated"
```

### 🧪 Lab 3 Verification

```bash
echo "=== Lab 3 Verification ==="

# Check file permissions
echo "File ownership verification:"
ls -la permission-test/ | head -10

# Verify solutions work
echo "Testing host access to container-created files:"
for file in solution1.txt solution2.txt solution3.txt; do
    if [ -f "permission-test/$file" ]; then
        echo "$file: $(stat -c %U:%G permission-test/$file)"
    fi
done

# Check secure volume
echo "Secure volumes:"
docker volume inspect readonly-config --format '{{.Name}}: {{.Driver}}'

echo "✅ Lab 3 verification completed"
```

---

## Lab 4: Performance Optimization and Monitoring
**Duration**: 30 minutes | **Difficulty**: Advanced

### 🎯 Objectives
- Benchmark different storage configurations
- Optimize volume performance for specific workloads
- Implement storage monitoring and alerting

### Task 4.1: Storage Performance Benchmarking (10 minutes)

**Measure and compare storage performance**

```bash
echo "=== Task 4.1: Storage Performance Benchmarking ==="

# Create different volume types for testing
docker volume create perf-test-named
mkdir -p ./perf-test-bind

# Benchmark function
benchmark_storage() {
    local storage_type=$1
    local mount_option=$2
    
    echo "=== Benchmarking $storage_type ==="
    
    docker run --rm \
        $mount_option \
        alpine sh -c '
            echo "=== Sequential Write Test ==="
            time dd if=/dev/zero of=/test/seq_write bs=1M count=50 2>&1
            
            echo "=== Sequential Read Test ==="
            time dd if=/test/seq_write of=/dev/null bs=1M 2>&1
            
            echo "=== Random Write Test ==="
            time for i in $(seq 1 20); do
                dd if=/dev/urandom of=/test/random_$i bs=64k count=1 2>/dev/null
            done 2>&1
            
            echo "=== File Operations Test ==="
            time for i in $(seq 1 100); do
                echo "file $i content" > /test/file_$i
            done 2>&1
            
            # Cleanup
            rm -f /test/seq_write /test/random_* /test/file_*
        ' > perf_${storage_type}.log 2>&1
    
    echo "Results saved to perf_${storage_type}.log"
}

# Test named volume
benchmark_storage "named_volume" "-v perf-test-named:/test"

# Test bind mount
benchmark_storage "bind_mount" "-v $(pwd)/perf-test-bind:/test"

# Test tmpfs
benchmark_storage "tmpfs" "--tmpfs /test:rw,size=200m"

echo "=== Performance Comparison ==="
echo "Named Volume Results:"
grep "real" perf_named_volume.log

echo "Bind Mount Results:"
grep "real" perf_bind_mount.log

echo "tmpfs Results:"
grep "real" perf_tmpfs.log

echo "✅ Performance benchmarking completed"
```

### Task 4.2: Volume Driver Optimization (10 minutes)

**Configure optimized storage for specific use cases**

```bash
echo "=== Task 4.2: Volume Driver Optimization ==="

# 1. Create optimized volume for database workload
echo "=== Database-optimized Volume ==="
docker volume create db-optimized \
    --driver local \
    --opt type=ext4 \
    --opt o=noatime,nodiratime

# Test database performance
docker run -d --name perf-db \
    -v db-optimized:/var/lib/postgresql/data \
    -e POSTGRES_DB=perftest \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test \
    postgres:13

# Wait for DB startup
sleep 10

# Run database performance test
docker exec perf-db psql -U test -d perftest -c "
    CREATE TABLE perf_test (
        id SERIAL PRIMARY KEY,
        data TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    );
    
    -- Insert test data
    INSERT INTO perf_test (data) 
    SELECT 'Performance test data ' || generate_series(1, 1000);
    
    -- Test query performance
    \timing on
    SELECT COUNT(*) FROM perf_test;
    SELECT * FROM perf_test WHERE id > 500 LIMIT 10;
"

# 2. Create cache-optimized volume
echo "=== Cache-optimized Volume (tmpfs) ==="
docker run --rm \
    --tmpfs /cache:rw,size=100m,nr_inodes=10k \
    alpine sh -c '
        echo "=== Cache Performance Test ==="
        time for i in $(seq 1 500); do
            echo "cache_key_$i:cache_value_$i" > /cache/key_$i
        done
        
        echo "=== Cache Read Test ==="
        time for i in $(seq 1 500); do
            cat /cache/key_$i > /dev/null
        done
        
        echo "Cache files created: $(ls /cache | wc -l)"
    '

# 3. Log-optimized volume (append-heavy workload)
echo "=== Log-optimized Volume ==="
docker volume create log-optimized \
    --driver local \
    --opt type=ext4 \
    --opt o=noatime,data=writeback

docker run --rm \
    -v log-optimized:/logs \
    alpine sh -c '
        echo "=== Log Write Performance ==="
        time for i in $(seq 1 1000); do
            echo "$(date): Log entry $i with some additional data" >> /logs/app.log
        done
        
        echo "Log file size: $(wc -l /logs/app.log)"
    '

# Cleanup
docker stop perf-db
docker rm perf-db

echo "✅ Volume optimization completed"
```

### Task 4.3: Storage Monitoring Setup (10 minutes)

**Implement comprehensive storage monitoring**

```bash
echo "=== Task 4.3: Storage Monitoring ==="

# 1. Volume usage monitoring script
cat > monitor-volumes.sh << 'EOF'
#!/bin/bash

echo "=== Docker Volume Usage Report ==="
echo "Generated at: $(date)"
echo ""

# Volume usage summary
echo "=== Volume Usage Summary ==="
printf "%-20s %-10s %-15s\n" "VOLUME NAME" "SIZE" "MOUNT POINT"
echo "----------------------------------------"

for volume in $(docker volume ls -q); do
    SIZE=$(docker run --rm -v $volume:/data alpine du -sh /data 2>/dev/null | cut -f1 || echo "N/A")
    MOUNT=$(docker volume inspect $volume --format '{{.Mountpoint}}' 2>/dev/null || echo "N/A")
    printf "%-20s %-10s %-15s\n" "$volume" "$SIZE" "$(basename $MOUNT)"
done

echo ""

# Container storage usage
echo "=== Container Storage Usage ==="
docker ps --format "table {{.Names}}\t{{.Size}}" 2>/dev/null || echo "No running containers"

echo ""

# System storage overview
echo "=== System Storage Overview ==="
echo "Docker Root Dir Usage:"
df -h /var/lib/docker 2>/dev/null || echo "Cannot access Docker root directory"

echo ""
echo "=== Volume Health Check ==="
for volume in $(docker volume ls -q | head -5); do
    echo "Checking volume: $volume"
    docker run --rm -v $volume:/check alpine sh -c '
        echo "  Files: $(find /check -type f 2>/dev/null | wc -l)"
        echo "  Directories: $(find /check -type d 2>/dev/null | wc -l)"
        echo "  Permissions OK: $(ls -la /check >/dev/null 2>&1 && echo Yes || echo No)"
    '
done
EOF

chmod +x monitor-volumes.sh

# Run monitoring
./monitor-volumes.sh

# 2. Performance monitoring
echo "=== Storage Performance Monitoring ==="
cat > perf-monitor.sh << 'EOF'
#!/bin/bash

echo "=== Storage Performance Monitor ==="

# Monitor container I/O
echo "Container I/O Statistics:"
docker stats --no-stream --format "table {{.Container}}\t{{.BlockIO}}" 2>/dev/null

echo ""

# Volume performance test
test_volume_performance() {
    local volume_name=$1
    echo "Testing volume: $volume_name"
    
    docker run --rm -v $volume_name:/test alpine sh -c '
        # Quick write test
        START_TIME=$(date +%s%N)
        dd if=/dev/zero of=/test/perf_test bs=1M count=10 2>/dev/null
        END_TIME=$(date +%s%N)
        
        DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
        echo "  Write time: ${DURATION}ms for 10MB"
        
        # Quick read test
        START_TIME=$(date +%s%N)
        dd if=/test/perf_test of=/dev/null 2>/dev/null
        END_TIME=$(date +%s%N)
        
        DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
        echo "  Read time: ${DURATION}ms for 10MB"
        
        rm /test/perf_test
    '
}

# Test existing volumes
for volume in $(docker volume ls -q | head -3); do
    test_volume_performance $volume
done
EOF

chmod +x perf-monitor.sh
./perf-monitor.sh

# 3. Automated alerts (simulation)
echo "=== Storage Alerts Setup ==="
cat > storage-alerts.sh << 'EOF'
#!/bin/bash

ALERT_THRESHOLD_MB=1000  # Alert if volume > 1GB

check_volume_size() {
    local volume_name=$1
    local size_kb=$(docker run --rm -v $volume_name:/data alpine du -sk /data 2>/dev/null | cut -f1)
    local size_mb=$((size_kb / 1024))
    
    if [ $size_mb -gt $ALERT_THRESHOLD_MB ]; then
        echo "ALERT: Volume $volume_name is ${size_mb}MB (exceeds ${ALERT_THRESHOLD_MB}MB threshold)"
        # In production, send to monitoring system
        return 1
    else
        echo "OK: Volume $volume_name is ${size_mb}MB"
        return 0
    fi
}

echo "=== Volume Size Alerts ==="
for volume in $(docker volume ls -q); do
    check_volume_size $volume
done

# Check for orphaned volumes
echo ""
echo "=== Orphaned Volume Check ==="
for volume in $(docker volume ls -q); do
    USED_BY=$(docker ps -a --filter volume=$volume --format '{{.Names}}' | wc -l)
    if [ $USED_BY -eq 0 ]; then
        echo "WARNING: Volume $volume appears to be orphaned (not used by any container)"
    fi
done
EOF

chmod +x storage-alerts.sh
./storage-alerts.sh

echo "✅ Storage monitoring setup completed"
```

### 🧪 Lab 4 Verification

```bash
echo "=== Lab 4 Verification ==="

# Check performance logs exist
echo "Performance test results:"
ls -la perf_*.log

# Check monitoring scripts
echo "Monitoring scripts created:"
ls -la monitor-volumes.sh perf-monitor.sh storage-alerts.sh

# Show volume optimization
echo "Optimized volumes:"
docker volume ls | grep -E "(optimized|perf-test)"

# Final storage overview
echo "=== Final Storage State ==="
docker volume ls
echo ""
docker system df

echo "✅ Lab 4 verification completed"
```

---

## 🎓 Lab Summary and Cleanup

### Key Concepts Demonstrated

1. **Volume Types**: Named volumes vs bind mounts vs tmpfs - when to use each
2. **Data Persistence**: Database upgrades and data migration patterns
3. **Backup/Restore**: Automated backup procedures and disaster recovery
4. **Permission Management**: User ID mapping and secure access patterns
5. **Performance Optimization**: Storage benchmarking and optimization techniques
6. **Monitoring**: Comprehensive storage monitoring and alerting

### Production Patterns Learned

- Database storage with persistence across updates
- Shared storage for multi-container applications  
- Secure configuration and secret management
- Automated backup and disaster recovery procedures
- Permission handling for host-container integration
- Performance optimization for different workloads
- Storage monitoring and capacity planning

### Optional Cleanup

```bash
# Clean up lab resources (optional)
echo "=== Lab Cleanup ==="

# Stop and remove containers
docker ps -aq | xargs -r docker stop
docker ps -aq | xargs -r docker rm

# Remove volumes (keep if you want to preserve for reference)
echo "Remove all lab volumes? [y/N]"
read -n 1 response
if [[ $response =~ ^[Yy]$ ]]; then
    docker volume ls -q | xargs -r docker volume rm
fi

# Clean up files
rm -rf ~/docker-labs/storage
rm -f perf_*.log
rm -f monitor-volumes.sh perf-monitor.sh storage-alerts.sh

echo "✅ Lab cleanup completed"
```

---

> 💡 **Key Takeaway**: Proper storage management is essential for production containerized applications. These labs demonstrated the practical skills needed to handle data persistence, security, performance, and operational monitoring for Docker storage systems.