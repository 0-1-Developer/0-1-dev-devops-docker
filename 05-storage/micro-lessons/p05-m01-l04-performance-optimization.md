# p05-m01-l04: Performance Optimization Techniques

> **Duration**: 5 minutes | **Anchor**: `p05-m01-l04` | **Type**: Performance-focused + Benchmarking

## 🎯 Learning Objective

Master Docker storage performance optimization techniques including volume driver selection, mount option tuning, workload-specific optimizations, and performance monitoring for production environments.

## 📊 Storage Performance Fundamentals

### Performance Hierarchy (Fastest to Slowest)

```
┌─────────────────────────────────────┐
│ 🔥 tmpfs (Memory)                   │ ← Fastest: RAM speed
│ • 10-100x faster than disk         │
│ • No persistence                   │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 🚀 Named Volume (Optimized)        │ ← Production: Docker-managed
│ • Good performance                 │
│ • Persistence + portability       │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 📁 Bind Mount (Host FS)            │ ← Development: Direct access
│ • Host filesystem performance     │
│ • OS-dependent behavior           │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 🌐 Network Volume (NFS/Cloud)      │ ← Slowest: Network latency
│ • Network bandwidth limited       │
│ • High latency                    │
└─────────────────────────────────────┘
```

## ⚡ Quick Performance Benchmark Tool

```bash
# Storage performance benchmark function
benchmark_storage() {
    local storage_name=$1
    local mount_config=$2
    
    echo "=== Benchmarking: $storage_name ==="
    
    # Run comprehensive benchmark
    docker run --rm \
        $mount_config \
        alpine sh -c '
            echo "Storage: '$storage_name'"
            
            echo "=== Write Performance Test ==="
            START_TIME=$(date +%s%N)
            dd if=/dev/zero of=/test/write_test bs=1M count=50 2>/dev/null
            END_TIME=$(date +%s%N)
            WRITE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
            echo "Write time: ${WRITE_TIME}ms for 50MB"
            
            echo "=== Read Performance Test ==="
            START_TIME=$(date +%s%N)
            dd if=/test/write_test of=/dev/null bs=1M 2>/dev/null
            END_TIME=$(date +%s%N)
            READ_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
            echo "Read time: ${READ_TIME}ms for 50MB"
            
            echo "=== Random Access Test ==="
            START_TIME=$(date +%s%N)
            for i in $(seq 1 100); do
                dd if=/dev/urandom of=/test/random_$i bs=4k count=1 2>/dev/null
            done
            END_TIME=$(date +%s%N)
            RANDOM_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
            echo "Random write time: ${RANDOM_TIME}ms for 100 files"
            
            # Cleanup
            rm -f /test/write_test /test/random_*
            
            echo "Summary: Write=${WRITE_TIME}ms Read=${READ_TIME}ms Random=${RANDOM_TIME}ms"
            echo ""
        '
}

# Compare different storage types
echo "=== Storage Performance Comparison ==="

# Create test volumes
docker volume create perf-named-vol
mkdir -p perf-bind-mount

# Benchmark each type
benchmark_storage "Named Volume" "-v perf-named-vol:/test"
benchmark_storage "Bind Mount" "-v $(pwd)/perf-bind-mount:/test"
benchmark_storage "tmpfs" "--tmpfs /test:rw,size=200m"

# Cleanup
docker volume rm perf-named-vol
rm -rf perf-bind-mount
```

## 🔧 Volume Driver Optimization

### Optimized Volume Creation

```bash
# Database-optimized volume
create_database_volume() {
    local volume_name=$1
    
    echo "Creating database-optimized volume: $volume_name"
    
    # Create volume with performance optimizations
    docker volume create $volume_name \
        --driver local \
        --opt type=ext4 \
        --opt o=noatime,nodiratime,data=ordered
    
    echo "✅ Database volume created with optimizations:"
    echo "   - noatime: Reduces write operations"
    echo "   - nodiratime: Reduces directory access time updates"
    echo "   - data=ordered: Ensures metadata consistency"
}

# High-throughput log volume
create_log_volume() {
    local volume_name=$1
    
    echo "Creating log-optimized volume: $volume_name"
    
    docker volume create $volume_name \
        --driver local \
        --opt type=ext4 \
        --opt o=noatime,data=writeback
    
    echo "✅ Log volume created with optimizations:"
    echo "   - noatime: Reduces access time overhead"
    echo "   - data=writeback: Faster async writes"
}

# Cache-optimized volume (with size limits)
create_cache_volume() {
    local volume_name=$1
    local size_limit=${2:-1G}
    
    echo "Creating cache-optimized volume: $volume_name (size: $size_limit)"
    
    docker volume create $volume_name \
        --driver local \
        --opt type=tmpfs \
        --opt device=tmpfs \
        --opt o=size=$size_limit,noatime
    
    echo "✅ Cache volume created in memory with size limit: $size_limit"
}

# Demonstrate optimized volumes
create_database_volume db-perf
create_log_volume log-perf
create_cache_volume cache-perf 256m
```

## 🎯 Workload-Specific Optimizations

### Database Workload Optimization

```bash
echo "=== Database Performance Optimization ==="

# Create optimized database setup
docker volume create postgres-data \
    --driver local \
    --opt type=ext4 \
    --opt o=noatime

docker volume create postgres-backups
docker volume create postgres-wal

# Deploy optimized PostgreSQL
docker run -d --name postgres-optimized \
    -v postgres-data:/var/lib/postgresql/data \
    -v postgres-backups:/backups \
    -v postgres-wal:/var/lib/postgresql/wal \
    --tmpfs /tmp:rw,size=256m \
    --tmpfs /var/run/postgresql:rw,size=64m \
    -e POSTGRES_DB=perftest \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test123 \
    postgres:13

# Wait for startup
sleep 10

# Performance test
docker exec postgres-optimized psql -U test -d perftest -c "
    -- Create test table
    CREATE TABLE perf_test (
        id SERIAL PRIMARY KEY,
        data TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    );
    
    -- Insert performance test
    \timing on
    INSERT INTO perf_test (data) 
    SELECT 'Performance test data row ' || generate_series(1, 10000);
    
    -- Query performance test
    SELECT COUNT(*) FROM perf_test;
    
    -- Index performance
    CREATE INDEX idx_perf_created ON perf_test(created_at);
    SELECT COUNT(*) FROM perf_test WHERE created_at > NOW() - INTERVAL '1 hour';
"

echo "✅ Database performance test completed"

# Cleanup
docker stop postgres-optimized
docker rm postgres-optimized
docker volume rm postgres-data postgres-backups postgres-wal
```

### Web Application Cache Optimization

```bash
echo "=== Web Application Cache Optimization ==="

# Multi-tier cache strategy
docker network create cache-network

# Redis for session cache (named volume for persistence)
docker volume create redis-data
docker run -d --name redis-persistent \
    --network cache-network \
    -v redis-data:/data \
    redis:7-alpine redis-server --appendonly yes

# Application cache (tmpfs for speed)
docker run -d --name webapp-cache \
    --network cache-network \
    --tmpfs /app/cache:rw,size=512m \
    --tmpfs /app/temp:rw,size=128m \
    -v app-data:/app/data \
    alpine sh -c '
        while true; do
            # Simulate cache operations
            echo "$(date): Cache entry" > /app/cache/cache-$(date +%s).txt
            sleep 5
            
            # Cleanup old cache entries
            find /app/cache -name "cache-*" -mmin +1 -delete
        done
    '

# Monitor cache performance
sleep 15
echo "=== Cache Performance Metrics ==="

# Check memory cache usage
docker exec webapp-cache df -h /app/cache

# Check Redis performance
docker exec redis-persistent redis-cli info memory | grep used_memory

# Cleanup
docker stop redis-persistent webapp-cache
docker rm redis-persistent webapp-cache
docker network rm cache-network
docker volume rm redis-data
```

### Build System Optimization

```bash
echo "=== Build System Performance Optimization ==="

# Create build-optimized environment
docker volume create build-cache
docker volume create build-artifacts

# Optimized build container
docker run --rm \
    -v build-cache:/build/cache \
    -v build-artifacts:/build/output \
    --tmpfs /build/temp:rw,size=1g \
    --tmpfs /tmp:rw,size=512m \
    alpine sh -c '
        echo "=== Build Performance Test ==="
        
        # Simulate build process
        echo "Building application..."
        START_TIME=$(date +%s%N)
        
        # Create build artifacts
        for i in $(seq 1 100); do
            echo "Build artifact $i" > /build/output/artifact-$i.txt
        done
        
        # Use temp space for intermediate files
        for i in $(seq 1 200); do
            echo "Temp data $i" > /build/temp/temp-$i.txt
        done
        
        # Cache frequently used files
        echo "Caching build dependencies..."
        for i in $(seq 1 50); do
            echo "Cache entry $i" > /build/cache/cache-$i.txt
        done
        
        END_TIME=$(date +%s%N)
        BUILD_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
        
        echo "Build completed in: ${BUILD_TIME}ms"
        echo "Artifacts created: $(ls /build/output | wc -l)"
        echo "Cache entries: $(ls /build/cache | wc -l)"
        echo "Temp usage: $(df -h /build/temp | tail -1)"
    '

# Verify persistent cache
echo "=== Build Cache Verification ==="
docker run --rm -v build-cache:/cache alpine ls -la /cache | head -5

# Cleanup
docker volume rm build-cache build-artifacts
```

## 📊 Performance Monitoring and Tuning

### Real-Time Performance Monitoring

```bash
# Performance monitoring function
monitor_storage_performance() {
    local container_name=$1
    local duration=${2:-30}
    
    echo "=== Monitoring storage performance for $container_name ($duration seconds) ==="
    
    # Create monitoring container
    docker run -d --name perf-monitor \
        --pid container:$container_name \
        --volumes-from $container_name \
        alpine sh -c '
            while true; do
                echo "$(date): I/O Stats"
                cat /proc/self/io 2>/dev/null || echo "I/O stats unavailable"
                echo "---"
                sleep 5
            done
        '
    
    # Monitor for specified duration
    sleep $duration
    
    # Get final stats
    echo "=== Final Performance Statistics ==="
    docker logs perf-monitor | tail -10
    
    # Cleanup monitor
    docker stop perf-monitor
    docker rm perf-monitor
}

# Create test container for monitoring
docker run -d --name storage-test \
    -v monitor-vol:/data \
    --tmpfs /temp:rw,size=100m \
    alpine sh -c '
        while true; do
            echo "$(date): Data write" >> /data/activity.log
            echo "$(date): Temp write" > /temp/temp.log
            sleep 2
        done
    '

# Monitor performance
monitor_storage_performance storage-test 20

# Cleanup
docker stop storage-test
docker rm storage-test
docker volume rm monitor-vol 2>/dev/null || true
```

### Storage Usage Analysis

```bash
# Storage analysis tool
analyze_storage_usage() {
    echo "=== Docker Storage Analysis ==="
    
    # Overall system usage
    echo "=== System Storage Overview ==="
    docker system df
    
    echo ""
    echo "=== Volume Usage Details ==="
    
    # Analyze each volume
    for volume in $(docker volume ls -q); do
        echo "Analyzing volume: $volume"
        
        # Get volume size and file count
        STATS=$(docker run --rm \
            -v $volume:/analyze \
            alpine sh -c '
                SIZE=$(du -sh /analyze 2>/dev/null | cut -f1)
                FILES=$(find /analyze -type f 2>/dev/null | wc -l)
                DIRS=$(find /analyze -type d 2>/dev/null | wc -l)
                echo "$SIZE,$FILES,$DIRS"
            ')
        
        SIZE=$(echo $STATS | cut -d, -f1)
        FILES=$(echo $STATS | cut -d, -f2)
        DIRS=$(echo $STATS | cut -d, -f3)
        
        printf "  Volume: %-20s Size: %-8s Files: %-6s Dirs: %s\n" "$volume" "$SIZE" "$FILES" "$DIRS"
    done
    
    echo ""
    echo "=== Container Storage Usage ==="
    docker ps --format "table {{.Names}}\t{{.Size}}" 2>/dev/null || echo "No running containers"
    
    echo ""
    echo "=== Storage Recommendations ==="
    
    # Check for large volumes
    for volume in $(docker volume ls -q); do
        SIZE_KB=$(docker run --rm -v $volume:/check alpine du -sk /check 2>/dev/null | cut -f1 || echo 0)
        if [ $SIZE_KB -gt 1048576 ]; then  # > 1GB
            echo "⚠️  Large volume detected: $volume (>1GB) - consider cleanup or archival"
        fi
    done
    
    # Check for unused volumes
    echo ""
    echo "Unused volumes:"
    docker volume ls --filter dangling=true -q | head -5
}

# Run storage analysis
analyze_storage_usage
```

## 🚀 Advanced Performance Techniques

### I/O Optimization Patterns

```bash
# I/O pattern optimization
optimize_io_patterns() {
    echo "=== I/O Pattern Optimization ==="
    
    # Sequential I/O optimization
    echo "Testing sequential I/O patterns..."
    docker run --rm \
        -v io-test:/test \
        alpine sh -c '
            echo "=== Sequential Write Test ==="
            time dd if=/dev/zero of=/test/sequential bs=1M count=100 conv=fsync
            
            echo "=== Sequential Read Test ==="  
            time dd if=/test/sequential of=/dev/null bs=1M
        '
    
    # Random I/O with different block sizes
    echo "Testing random I/O patterns..."
    docker run --rm \
        -v io-test:/test \
        alpine sh -c '
            echo "=== Random I/O Test (4K blocks) ==="
            time for i in $(seq 1 1000); do
                dd if=/dev/urandom of=/test/random_4k_$i bs=4k count=1 2>/dev/null
            done
            
            echo "=== Random I/O Test (64K blocks) ==="
            time for i in $(seq 1 100); do
                dd if=/dev/urandom of=/test/random_64k_$i bs=64k count=1 2>/dev/null
            done
        '
    
    # Cleanup
    docker volume rm io-test
}

optimize_io_patterns
```

### Memory-Based Performance Tuning

```bash
# Memory optimization for high-performance scenarios
tune_memory_performance() {
    echo "=== Memory-Based Performance Tuning ==="
    
    # Multi-level cache architecture
    docker run --rm \
        --tmpfs /cache/l1:rw,size=128m \
        --tmpfs /cache/l2:rw,size=256m \
        -v persistent-cache:/cache/l3 \
        alpine sh -c '
            echo "=== Multi-Level Cache Test ==="
            
            # L1 Cache (fastest, smallest)
            echo "L1 Cache (128MB tmpfs):"
            time for i in $(seq 1 100); do
                echo "L1 cache data $i" > /cache/l1/item_$i.txt
            done
            
            # L2 Cache (medium speed, medium size)  
            echo "L2 Cache (256MB tmpfs):"
            time for i in $(seq 1 200); do
                echo "L2 cache data $i" > /cache/l2/item_$i.txt
            done
            
            # L3 Cache (persistent, larger)
            echo "L3 Cache (persistent volume):"
            time for i in $(seq 1 50); do
                echo "L3 cache data $i" > /cache/l3/item_$i.txt
            done
            
            echo "Cache utilization:"
            df -h /cache/l1 /cache/l2 /cache/l3
        '
}

# Create persistent cache volume
docker volume create persistent-cache
tune_memory_performance
docker volume rm persistent-cache
```

## 🔗 Performance Optimization Principles

1. **Know Your Workload**: Identify I/O patterns (sequential vs random, read vs write)
2. **Choose Appropriate Storage**: Match volume type to performance requirements
3. **Use tmpfs for Speed**: Memory-based storage for cache and temporary data
4. **Optimize Mount Options**: noatime, data=ordered, writeback for specific needs
5. **Size tmpfs Appropriately**: Balance performance with memory availability
6. **Monitor Continuously**: Regular performance monitoring and optimization
7. **Test in Production-Like Conditions**: Realistic workload testing

## 📊 Performance Tuning Checklist

- [ ] **Benchmark baseline performance** before optimization
- [ ] **Select optimal volume types** for each data pattern
- [ ] **Configure mount options** for workload characteristics
- [ ] **Size tmpfs volumes** based on available memory
- [ ] **Monitor storage metrics** in production
- [ ] **Implement caching strategies** for frequently accessed data
- [ ] **Regular performance reviews** and tuning adjustments

---

**Phase 05 Storage & Volumes Complete** - Ready for Phase 06: Docker Compose