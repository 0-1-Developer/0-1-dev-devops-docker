# Micro-Lesson: Resource Constraint Planning

**Anchor**: `p03-m01-l03`  
**Duration**: 4 minutes  
**Objective**: Calculate and apply appropriate resource limits to prevent resource starvation while optimizing performance

## 🎯 Core Concept

**Resource limits prevent one container from starving others**, but they must be set based on actual application needs, not arbitrary numbers. Too low = performance problems. Too high = no protection. Right-sizing requires measurement and understanding.

## 📊 The Resource Planning Process

### 1. Measure Current Usage
```bash
# Monitor container resource usage
docker stats container_name

# Get detailed resource information
docker exec container_name cat /proc/meminfo
docker exec container_name cat /proc/cpuinfo
```

### 2. Calculate Appropriate Limits
**Memory Limit Formula**:
```
Memory Limit = Peak Usage × Safety Factor × Growth Buffer
```
- Peak Usage: Maximum observed memory use
- Safety Factor: 1.2-1.5 (20-50% overhead)
- Growth Buffer: Account for future growth/load

**CPU Limit Guidelines**:
- Web services: 0.5-2.0 CPUs per instance
- Background workers: 0.25-1.0 CPUs per worker
- Databases: 1-4 CPUs (depending on load)

### 3. Apply Limits Progressively
Start conservative, monitor, and adjust based on real behavior.

## 🧠 Memory Management Strategies

### Memory Limit Types
```bash
# Hard memory limit (triggers OOM kill)
docker run -m 512m my-app

# Memory + swap limit  
docker run -m 512m --memory-swap 1g my-app

# Memory reservation (soft limit)
docker run --memory-reservation 256m my-app
```

### Memory Planning Examples

**Web Application**:
```bash
# Small web app (1-10 users)
docker run -m 256m my-web-app

# Medium web app (100 users)  
docker run -m 512m my-web-app

# Large web app (1000+ users)
docker run -m 2g my-web-app
```

**Database Containers**:
```bash
# Development database
docker run -m 512m postgres:13

# Production database (depends on dataset)
docker run -m 4g postgres:13

# In-memory database (Redis)
docker run -m 1g redis:alpine
```

### Memory Anti-Patterns

❌ **No memory limit**:
```bash
# Container can consume all system memory
docker run my-memory-hungry-app
# Risk: OOM killer kills random processes
```

❌ **Arbitrary limits**:
```bash
# Random number without measurement
docker run -m 128m my-app
# Risk: Container killed despite normal usage
```

✅ **Data-driven limits**:
```bash
# Based on measurement: peak 300MB, safety factor 1.5
docker run -m 450m my-app
```

## ⚡ CPU Management Strategies

### CPU Constraint Types
```bash
# CPU shares (relative priority)
docker run --cpu-shares 512 my-app

# CPU quota (absolute limit)
docker run --cpus="1.5" my-app

# CPU affinity (specific cores)
docker run --cpuset-cpus="0,1" my-app
```

### CPU Planning Guidelines

**CPU Shares vs CPU Limits**:
- **Shares**: Relative priority when CPU is contended
- **Limits**: Hard ceiling on CPU usage

**Example Configurations**:
```bash
# Background worker (low priority, limited CPU)
docker run --cpu-shares 256 --cpus="0.5" background-worker

# Web service (normal priority, moderate CPU)
docker run --cpu-shares 1024 --cpus="1.0" web-service

# Database (high priority, high CPU when needed)
docker run --cpu-shares 2048 --cpus="2.0" database
```

### CPU Monitoring and Adjustment
```bash
# Check CPU throttling
docker exec container cat /sys/fs/cgroup/cpu/cpu.stat

# Monitor CPU usage patterns
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

## 💾 I/O and Other Resource Limits

### Block Device I/O
```bash
# Limit read/write speed
docker run \
  --device-read-bps /dev/sda:1mb \
  --device-write-bps /dev/sda:1mb \
  my-app

# I/O weight (relative priority)
docker run --blkio-weight 500 my-app
```

### Process and File Limits
```bash
# Limit number of processes
docker run --pids-limit 100 my-app

# File descriptor limits (via ulimit in container)
docker run --ulimit nofile=1024:1024 my-app
```

## 🎯 Resource Planning Decision Matrix

| Application Type | Memory Strategy | CPU Strategy | I/O Strategy |
|------------------|-----------------|--------------|--------------|
| **Web Service** | Peak + 50% buffer | 0.5-1.0 CPU per instance | Standard limits |
| **Database** | Dataset + buffer | 1-4 CPUs based on load | High I/O limits |
| **Background Worker** | Job size + overhead | 0.25-0.5 CPU per worker | Task-dependent |
| **Cache (Redis)** | Data size × 2 | 0.5-1.0 CPU | High read I/O |
| **Batch Processing** | Working set + 25% | 1-2 CPUs per job | High I/O burst |

## 📈 Resource Monitoring and Optimization

### Monitoring Commands
```bash
# Real-time resource usage
docker stats

# Historical resource data
docker system events --filter type=container

# Container resource configuration
docker inspect container | jq '.HostConfig.Memory'
```

### Resource Usage Analysis
```bash
# Memory usage trend analysis
for i in {1..60}; do 
    echo "$(date): $(docker stats --no-stream container | grep container | awk '{print $3}')"
    sleep 60
done
```

### Optimization Triggers

**Scale Up When**:
- Memory usage consistently >80% of limit
- CPU usage consistently >70% with performance impact
- I/O wait times affecting user experience

**Scale Down When**:
- Memory usage consistently <50% of limit
- CPU usage consistently <30%
- Over-provisioned resources sitting idle

## 🚨 Resource Constraint Warning Signs

### Memory Issues
```bash
# Check for OOM kills
dmesg | grep -i "killed process"

# Monitor memory pressure
docker exec container cat /proc/pressure/memory
```

**Symptoms**:
- Container suddenly stops (exit code 137 = SIGKILL)
- Application performance degradation
- Swapping to disk increases

### CPU Issues
```bash
# Check CPU throttling
docker exec container cat /sys/fs/cgroup/cpu/cpu.stat
```

**Symptoms**:
- High response times despite low system load
- CPU percentage stuck at limit value
- Load average much higher than CPU count

### I/O Issues
**Symptoms**:
- High I/O wait times (`top` shows high `%wa`)
- Slow database queries
- File operations taking excessive time

## 💡 Production Resource Planning

### Environment-Based Limits
```bash
# Development (generous limits for debugging)
docker run -m 1g --cpus="2.0" my-app:dev

# Testing (production-like limits)  
docker run -m 512m --cpus="1.0" my-app:test

# Production (measured and optimized)
docker run -m 450m --cpus="0.75" my-app:prod
```

### Horizontal vs Vertical Scaling
**Vertical** (increase container limits):
- Good for: Memory-bound applications, databases
- Limits: Hardware constraints, single point of failure

**Horizontal** (more containers with same limits):
- Good for: Stateless web services, workers
- Benefits: Better fault tolerance, linear scaling

### Resource Planning Checklist
- [ ] **Measure**: Get baseline resource usage data
- [ ] **Calculate**: Apply safety factors and growth buffers
- [ ] **Test**: Validate limits under realistic load
- [ ] **Monitor**: Set up alerting for resource pressure
- [ ] **Adjust**: Iterate based on production behavior

## 🎓 Practice Scenario

**Plan resources for a blog application**:
- **Web server**: Handles 100 req/sec, uses 200MB RAM typically
- **Database**: Stores 1GB data, 50MB working set
- **Cache**: 100MB data, mostly reads

**Solution**:
```bash
# Web server (peak usage + buffer)
docker run -m 300m --cpus="0.5" blog-web

# Database (working set + buffer + connections)
docker run -m 256m --cpus="1.0" blog-db  

# Cache (data + overhead)
docker run -m 150m --cpus="0.25" blog-cache
```

**Key principle**: Start with measured data, add reasonable buffers, monitor and adjust based on real behavior.