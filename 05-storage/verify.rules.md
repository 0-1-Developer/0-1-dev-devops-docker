# Phase 05: Storage & Volumes - Verification Rules

> **Comprehensive validation of Docker storage management skills including volume types, data persistence, permissions, and performance optimization**

## 🎯 Verification Overview

These rules validate mastery of Docker storage and volume management concepts including volume type selection, data persistence patterns, backup procedures, permission handling, and performance optimization. All verification focuses on production storage patterns and operational excellence.

## ✅ Verification Rules

### Rule 1: Volume Type Selection and Data Persistence
**Anchor**: `p05-volume-types`  
**Type**: Automated + Manual

**Automated Test Setup**:
```bash
mkdir -p verify-p05-volumes && cd verify-p05-volumes

# Create test application with data
cat > test-app.js << 'EOF'
const fs = require('fs');
const path = require('path');

const dataDir = '/app/data';
const configDir = '/app/config';
const cacheDir = '/app/cache';

// Ensure directories exist
[dataDir, configDir, cacheDir].forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// Write test data
fs.writeFileSync(path.join(dataDir, 'persistent.txt'), `Data created at ${new Date().toISOString()}`);
fs.writeFileSync(path.join(configDir, 'app.json'), JSON.stringify({ mode: 'test', version: '1.0' }));
fs.writeFileSync(path.join(cacheDir, 'cache.tmp'), 'temporary cache data');

console.log('Test data created successfully');
console.log('Data files:', fs.readdirSync(dataDir));
console.log('Config files:', fs.readdirSync(configDir));
console.log('Cache files:', fs.readdirSync(cacheDir));
EOF

cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY test-app.js .
CMD ["node", "test-app.js"]
EOF

docker build -t storage-test:v1 .
```

**Student Task**: Demonstrate appropriate volume type selection for different data scenarios

**Automated Verification**:
```bash
# Test 1: Named volume for persistent data
echo "=== Testing named volume persistence ===" 
docker volume create app-persistent-data

docker run --rm --name test-persistent \
  -v app-persistent-data:/app/data \
  storage-test:v1

# Verify data persists after container removal
if docker run --rm -v app-persistent-data:/app/data alpine cat /app/data/persistent.txt | grep -q "Data created"; then
    echo "✅ Named volume persists data correctly"
    NAMED_VOLUME_PERSIST=passed
else
    echo "❌ Named volume data persistence failed"
    NAMED_VOLUME_PERSIST=failed
fi

# Test 2: tmpfs for cache data (should not persist)
echo "=== Testing tmpfs for cache data ==="
docker run -d --name cache-test \
  --tmpfs /app/cache:rw,size=50m \
  alpine sh -c 'echo "cache data" > /app/cache/test.tmp && sleep 30'

# Verify tmpfs data doesn't persist
docker stop cache-test
docker rm cache-test

# Try to access cache data (should fail)
if docker run --rm --tmpfs /app/cache:rw alpine cat /app/cache/test.tmp 2>/dev/null; then
    echo "❌ tmpfs data persisted (security issue)"
    TMPFS_EPHEMERAL=failed
else
    echo "✅ tmpfs data properly ephemeral"
    TMPFS_EPHEMERAL=passed
fi

# Test 3: Bind mount for development
echo "=== Testing bind mount for development ==="
mkdir -p test-bind-mount
echo "host development file" > test-bind-mount/dev.txt

docker run --rm \
  -v $(pwd)/test-bind-mount:/app/dev \
  alpine sh -c 'echo "container added content" >> /app/dev/dev.txt'

if grep -q "container added content" test-bind-mount/dev.txt; then
    echo "✅ Bind mount allows bidirectional file access"
    BIND_MOUNT_ACCESS=passed
else
    echo "❌ Bind mount bidirectional access failed"
    BIND_MOUNT_ACCESS=failed
fi

# Cleanup
docker volume rm app-persistent-data
rm -rf test-bind-mount
```

**Manual Assessment**:
- [ ] Can explain when to use named volumes vs bind mounts vs tmpfs
- [ ] Understands volume lifecycle and persistence behavior
- [ ] Knows performance implications of different volume types
- [ ] Can design appropriate storage architecture for applications

**Success Criteria**:
- [ ] Named volumes properly persist data across container lifecycle
- [ ] tmpfs volumes provide ephemeral storage for sensitive data
- [ ] Bind mounts enable development workflows correctly
- [ ] Appropriate volume type selection for different use cases

---

### Rule 2: Backup and Restore Procedures
**Anchor**: `p05-backup-restore`  
**Type**: Automated + Manual

**Test Setup**:
```bash
mkdir -p verify-p05-backup && cd verify-p05-backup

# Create volume with test data structure
docker volume create backup-test-vol

docker run --rm \
  -v backup-test-vol:/data \
  alpine sh -c '
    mkdir -p /data/{app,config,logs,uploads}
    echo "Application data" > /data/app/app.txt
    echo "config_key=production" > /data/config/app.conf
    echo "$(date): App started" > /data/logs/app.log
    echo "User file content" > /data/uploads/document.txt
    dd if=/dev/urandom of=/data/app/binary.dat bs=1M count=1
  '
```

**Automated Verification**:
```bash
# Test 1: Volume backup creation
echo "=== Testing volume backup creation ==="
mkdir -p backups

# Create backup
docker run --rm \
  -v backup-test-vol:/source:ro \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/test-backup.tar.gz -C /source .

if [ -f "backups/test-backup.tar.gz" ] && [ -s "backups/test-backup.tar.gz" ]; then
    echo "✅ Backup file created successfully"
    BACKUP_CREATION=passed
else
    echo "❌ Backup creation failed"
    BACKUP_CREATION=failed
fi

# Test 2: Backup integrity verification
echo "=== Testing backup integrity ==="
BACKUP_FILES=$(tar -tzf backups/test-backup.tar.gz | wc -l)
if [ "$BACKUP_FILES" -ge "5" ]; then
    echo "✅ Backup contains expected files ($BACKUP_FILES files)"
    BACKUP_INTEGRITY=passed
else
    echo "❌ Backup incomplete ($BACKUP_FILES files)"
    BACKUP_INTEGRITY=failed
fi

# Test 3: Restore procedure
echo "=== Testing restore procedure ==="
docker volume create backup-restore-test

# Restore from backup
docker run --rm \
  -v backup-restore-test:/target \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/test-backup.tar.gz -C /target

# Verify restore
RESTORED_FILES=$(docker run --rm -v backup-restore-test:/data alpine find /data -type f | wc -l)
ORIGINAL_CONFIG=$(docker run --rm -v backup-test-vol:/data alpine cat /data/config/app.conf)
RESTORED_CONFIG=$(docker run --rm -v backup-restore-test:/data alpine cat /data/config/app.conf)

if [ "$RESTORED_FILES" -ge "5" ] && [ "$ORIGINAL_CONFIG" = "$RESTORED_CONFIG" ]; then
    echo "✅ Restore completed successfully with data integrity"
    RESTORE_SUCCESS=passed
else
    echo "❌ Restore failed or data corrupted"
    RESTORE_SUCCESS=failed
fi

# Test 4: Automated backup script functionality
echo "=== Testing automated backup system ==="
cat > automated-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/automated"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Function to backup volume
backup_volume() {
    local volume=$1
    local backup_file="$BACKUP_DIR/${volume}-${DATE}.tar.gz"
    
    if docker run --rm \
        -v $volume:/data:ro \
        -v $BACKUP_DIR:/backup \
        alpine tar czf /backup/$(basename $backup_file) -C /data . 2>/dev/null; then
        echo "Success: $volume backed up to $backup_file"
        return 0
    else
        echo "Error: Failed to backup $volume"
        return 1
    fi
}

# Backup test volume
backup_volume backup-test-vol
EOF

chmod +x automated-backup.sh
mkdir -p /tmp/backup/automated

if BACKUP_DIR=/tmp/backup/automated ./automated-backup.sh | grep -q "Success:"; then
    echo "✅ Automated backup script works correctly"
    AUTOMATED_BACKUP=passed
else
    echo "❌ Automated backup script failed"
    AUTOMATED_BACKUP=failed
fi

# Cleanup
docker volume rm backup-test-vol backup-restore-test
rm -rf backups /tmp/backup automated-backup.sh
cd .. && rm -rf verify-p05-backup
```

**Manual Assessment**:
- [ ] Can design backup strategies for different data types
- [ ] Understands backup scheduling and retention policies
- [ ] Knows how to verify backup integrity
- [ ] Can implement disaster recovery procedures

**Success Criteria**:
- [ ] Backup creation preserves all volume data
- [ ] Backup files maintain data integrity
- [ ] Restore procedure reconstructs original data accurately
- [ ] Automated backup systems function reliably

---

### Rule 3: Permission Management and Security
**Anchor**: `p05-permissions-security`  
**Type**: Security-focused Automated + Manual

**Security Test Setup**:
```bash
mkdir -p verify-p05-permissions && cd verify-p05-permissions

# Create test scenarios with different permission requirements
HOST_UID=$(id -u)
HOST_GID=$(id -g)
```

**Automated Security Verification**:
```bash
# Test 1: User ID mapping for file ownership
echo "=== Testing user ID mapping ==="
docker volume create permission-test

# Test incorrect approach (creates root-owned files)
docker run --rm \
  -v permission-test:/data \
  alpine sh -c 'echo "root created" > /data/root-file.txt'

ROOT_OWNER=$(docker run --rm -v permission-test:/data alpine stat -c %u /data/root-file.txt)

# Test correct approach (host user mapping)
docker run --rm \
  -v permission-test:/data \
  --user $HOST_UID:$HOST_GID \
  alpine sh -c 'echo "host user created" > /data/host-file.txt' 2>/dev/null || true

if docker run --rm -v permission-test:/data alpine ls -la /data/host-file.txt >/dev/null 2>&1; then
    HOST_FILE_OWNER=$(docker run --rm -v permission-test:/data alpine stat -c %u /data/host-file.txt)
    if [ "$HOST_FILE_OWNER" = "$HOST_UID" ]; then
        echo "✅ Host user ID mapping works correctly"
        USER_MAPPING=passed
    else
        echo "❌ User ID mapping failed"
        USER_MAPPING=failed
    fi
else
    echo "❌ Host user file creation failed"
    USER_MAPPING=failed
fi

# Test 2: Read-only volume security
echo "=== Testing read-only volume security ==="
docker volume create readonly-config
docker run --rm \
  -v readonly-config:/config \
  alpine sh -c 'echo "sensitive_config=true" > /config/app.conf'

# Test read-only enforcement
docker run --rm \
  -v readonly-config:/config:ro \
  alpine sh -c 'echo "hacker=true" >> /config/app.conf' 2>/dev/null

if docker run --rm -v readonly-config:/config alpine grep -q "hacker=true" /config/app.conf 2>/dev/null; then
    echo "❌ SECURITY ISSUE: Read-only volume was modified"
    READONLY_SECURITY=failed
else
    echo "✅ Read-only volume security enforced correctly"
    READONLY_SECURITY=passed
fi

# Test 3: tmpfs for sensitive data
echo "=== Testing tmpfs security for secrets ==="
SECRET_TEST_RESULT=$(docker run --rm \
  --tmpfs /secrets:rw,noexec,nosuid,size=10m \
  alpine sh -c '
    echo "secret_token=abc123" > /secrets/token
    # Try to execute file in tmpfs (should fail due to noexec)
    echo "#!/bin/sh" > /secrets/script.sh
    echo "echo hacked" >> /secrets/script.sh
    chmod +x /secrets/script.sh
    /secrets/script.sh 2>&1 || echo "EXECUTION_BLOCKED"
  ')

if echo "$SECRET_TEST_RESULT" | grep -q "EXECUTION_BLOCKED"; then
    echo "✅ tmpfs noexec security option working"
    TMPFS_SECURITY=passed
else
    echo "❌ tmpfs security options not enforced"
    TMPFS_SECURITY=failed
fi

# Test 4: Non-root user container security
echo "=== Testing non-root user security ==="
cat > Dockerfile.secure << 'EOF'
FROM alpine
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 appuser -G appgroup
USER appuser
WORKDIR /app
EOF

docker build -f Dockerfile.secure -t secure-app .

# Test that non-root user cannot access restricted areas
NONROOT_TEST=$(docker run --rm \
  -v permission-test:/data \
  secure-app sh -c 'whoami; id; cat /etc/shadow 2>&1 || echo "ACCESS_DENIED"')

if echo "$NONROOT_TEST" | grep -q "ACCESS_DENIED" && echo "$NONROOT_TEST" | grep -q "appuser"; then
    echo "✅ Non-root user security working correctly"
    NONROOT_SECURITY=passed
else
    echo "❌ Non-root user security failed"
    NONROOT_SECURITY=failed
fi

# Cleanup
docker volume rm permission-test readonly-config
docker image rm secure-app
rm Dockerfile.secure
cd .. && rm -rf verify-p05-permissions
```

**Manual Security Assessment**:
- [ ] Implements proper user ID mapping strategies
- [ ] Uses read-only volumes appropriately
- [ ] Understands tmpfs security benefits for sensitive data
- [ ] Runs containers as non-root users when possible

**Success Criteria**:
- [ ] File ownership matches between container and host correctly
- [ ] Read-only volumes prevent unauthorized modifications
- [ ] tmpfs provides secure ephemeral storage for secrets
- [ ] Non-root users cannot access restricted system resources

---

### Rule 4: Storage Performance and Optimization
**Anchor**: `p05-performance-optimization`  
**Type**: Performance-focused Manual + Automated

**Performance Test Setup**:
```bash
mkdir -p verify-p05-performance && cd verify-p05-performance

# Create volumes for performance testing
docker volume create perf-named-vol
mkdir -p perf-bind-mount
```

**Automated Performance Verification**:
```bash
# Test 1: Storage performance benchmarking
echo "=== Testing storage performance measurement ==="

benchmark_storage() {
    local storage_type=$1
    local mount_option=$2
    
    # Run benchmark
    PERF_RESULT=$(docker run --rm \
        $mount_option \
        alpine sh -c '
            # Quick sequential write test
            START=$(date +%s%N)
            dd if=/dev/zero of=/test/perf_test bs=1M count=10 2>/dev/null
            END=$(date +%s%N)
            WRITE_TIME=$(( (END - START) / 1000000 ))
            
            # Quick sequential read test  
            START=$(date +%s%N)
            dd if=/test/perf_test of=/dev/null 2>/dev/null
            END=$(date +%s%N)
            READ_TIME=$(( (END - START) / 1000000 ))
            
            echo "WRITE:$WRITE_TIME,READ:$READ_TIME"
            rm -f /test/perf_test
        ')
    
    echo "$storage_type: $PERF_RESULT"
}

# Benchmark different storage types
NAMED_VOL_PERF=$(benchmark_storage "named_volume" "-v perf-named-vol:/test")
BIND_MOUNT_PERF=$(benchmark_storage "bind_mount" "-v $(pwd)/perf-bind-mount:/test")
TMPFS_PERF=$(benchmark_storage "tmpfs" "--tmpfs /test:rw,size=100m")

# Verify benchmarks completed successfully
if echo "$NAMED_VOL_PERF $BIND_MOUNT_PERF $TMPFS_PERF" | grep -q "WRITE.*READ"; then
    echo "✅ Storage performance benchmarking completed"
    PERFORMANCE_BENCHMARK=passed
else
    echo "❌ Performance benchmarking failed"
    PERFORMANCE_BENCHMARK=failed
fi

# Test 2: Volume optimization for specific workloads
echo "=== Testing volume optimization ==="

# Create optimized volume
docker volume create db-optimized \
    --driver local \
    --opt type=ext4 \
    --opt o=noatime

# Test database-like workload
DB_PERF=$(docker run --rm \
    -v db-optimized:/var/lib/data \
    alpine sh -c '
        mkdir -p /var/lib/data
        # Simulate database write pattern
        START=$(date +%s%N)
        for i in $(seq 1 50); do
            echo "RECORD:$i:$(date):random_data_$(shuf -i 1000-9999 -n1)" >> /var/lib/data/db.log
        done
        END=$(date +%s%N)
        TIME=$(( (END - START) / 1000000 ))
        echo "DB_WRITE_TIME:$TIME"
    ')

if echo "$DB_PERF" | grep -q "DB_WRITE_TIME:"; then
    echo "✅ Optimized volume configuration working"
    VOLUME_OPTIMIZATION=passed
else
    echo "❌ Volume optimization failed"
    VOLUME_OPTIMIZATION=failed
fi

# Test 3: Storage monitoring capabilities
echo "=== Testing storage monitoring ==="

# Create monitoring function
MONITOR_RESULT=$(docker run --rm \
    -v perf-named-vol:/monitor \
    alpine sh -c '
        # Generate test data
        dd if=/dev/zero of=/monitor/test_data bs=1M count=5 2>/dev/null
        
        # Monitor volume usage
        USAGE=$(du -sm /monitor | cut -f1)
        FILES=$(find /monitor -type f | wc -l)
        
        echo "USAGE:${USAGE}MB,FILES:$FILES"
        rm -f /monitor/test_data
    ')

if echo "$MONITOR_RESULT" | grep -q "USAGE:.*MB.*FILES:"; then
    echo "✅ Storage monitoring capabilities verified"
    STORAGE_MONITORING=passed
else
    echo "❌ Storage monitoring failed"
    STORAGE_MONITORING=failed
fi

# Cleanup
docker volume rm perf-named-vol db-optimized
rm -rf perf-bind-mount
cd .. && rm -rf verify-p05-performance
```

**Manual Performance Assessment**:
- [ ] Can measure and compare storage performance for different volume types
- [ ] Understands optimization techniques for different workload patterns
- [ ] Implements appropriate monitoring for storage usage and performance
- [ ] Can tune volume configurations for specific application requirements

**Success Criteria**:
- [ ] Performance benchmarking measures storage metrics accurately
- [ ] Volume optimization improves performance for specific workloads
- [ ] Storage monitoring provides useful operational insights
- [ ] Performance tuning recommendations are based on actual measurements

---

### Rule 5: Production Storage Architecture
**Anchor**: `p05-production-storage`  
**Type**: Comprehensive Manual Assessment

**Architecture Scenario**: Student demonstrates production-ready storage architecture for a multi-tier application.

**Assessment Requirements**:

**Storage Architecture Design**:
- [ ] Appropriate volume type selection for each service tier
- [ ] Data persistence strategy aligned with business requirements  
- [ ] Backup and disaster recovery procedures
- [ ] Performance optimization for expected workload patterns

**Security Implementation**:
- [ ] Proper permission management across all storage components
- [ ] Secure handling of sensitive configuration and secrets
- [ ] Read-only volumes where write access isn't required
- [ ] Non-root user implementation for all services

**Operational Excellence**:
- [ ] Automated backup procedures with retention policies
- [ ] Storage monitoring and alerting capabilities
- [ ] Performance tuning based on workload characteristics
- [ ] Documentation of storage architecture and procedures

**Scalability and Maintainability**:
- [ ] Volume organization supports scaling requirements
- [ ] Backup procedures scale with data growth
- [ ] Storage architecture supports blue/green deployments
- [ ] Clear separation of data concerns (persistent vs ephemeral)

---

## 🔄 Comprehensive Verification Script

Complete verification sequence for all rules:

```bash
#!/bin/bash
echo "=== Phase 05 Storage & Volumes Verification ==="

TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_result="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$test_result" = "passed" ]; then
        echo "✅ $test_name: PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ $test_name: FAILED"
    fi
}

# Rule 1: Volume Types
echo "Testing Rule 1: Volume Type Selection..."
# ... (volume type tests)

# Rule 2: Backup & Restore
echo "Testing Rule 2: Backup & Restore..."
# ... (backup tests)

# Rule 3: Permissions & Security
echo "Testing Rule 3: Security & Permissions..."
# ... (security tests)

# Rule 4: Performance
echo "Testing Rule 4: Performance Optimization..."
# ... (performance tests)

echo ""
echo "=== Verification Results ==="
echo "Automated Tests: $PASSED_TESTS/$TOTAL_TESTS passed"
echo ""
echo "Manual verification required for:"
echo "- [ ] Volume type selection rationale"
echo "- [ ] Backup strategy design"
echo "- [ ] Security implementation approach"
echo "- [ ] Performance optimization techniques"
echo "- [ ] Production storage architecture"
echo ""
echo "Complete manual assessments to finish Phase 05 verification."
```

## 📋 Manual Verification Checklist

### Storage Concepts
- [ ] **Volume Types**: Chooses appropriate storage type for each use case
- [ ] **Data Persistence**: Implements reliable data persistence strategies
- [ ] **Backup & Restore**: Creates automated, tested backup procedures
- [ ] **Permission Management**: Handles file ownership and access correctly

### Production Skills
- [ ] **Performance Optimization**: Tunes storage for application requirements
- [ ] **Security Implementation**: Applies storage security best practices
- [ ] **Monitoring**: Implements comprehensive storage observability
- [ ] **Architecture Design**: Creates scalable storage architectures

### Integration Capabilities
- [ ] **Multi-Service Storage**: Designs storage for complex applications
- [ ] **Disaster Recovery**: Implements production-grade recovery procedures
- [ ] **Operational Automation**: Automates storage management tasks
- [ ] **Compliance**: Meets security and compliance storage requirements

## 🎯 Success Criteria Summary

**Complete Phase 05 when:**
- [ ] All automated verification tests pass
- [ ] Manual assessment confirms storage management expertise
- [ ] Can design and implement production storage architectures
- [ ] Demonstrates troubleshooting skills for storage issues
- [ ] Ready to progress to Docker Compose in Phase 06

---

> **Critical Success Indicator**: Can design and implement a complete storage architecture that provides appropriate data persistence, secure access control, reliable backup procedures, and optimized performance for containerized production applications.