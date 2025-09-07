# Phase 03: Container Operations

> **Master container lifecycle management, health monitoring, and production runtime operations**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Design robust health check strategies for production containers
- Configure restart policies that ensure service reliability
- Apply resource limits and constraints for optimal performance
- Handle container signals and graceful shutdowns properly
- Implement monitoring and observability for container operations
- Troubleshoot common container runtime issues effectively

## 📚 Concept Map

```
Container Operations
├── Health Management
│   ├── Health Check Configuration
│   ├── Readiness vs Liveness Probes
│   ├── Health Check Best Practices
│   └── Failure Recovery Strategies
├── Lifecycle Control
│   ├── Restart Policies (no, always, on-failure, unless-stopped)
│   ├── Container Dependencies & Ordering
│   ├── Graceful Shutdown Handling
│   └── Signal Processing (SIGTERM, SIGKILL)
├── Resource Management
│   ├── Memory Limits & OOM Handling
│   ├── CPU Constraints & Scheduling
│   ├── I/O Throttling & Block Device Limits
│   └── Process & File Descriptor Limits
└── Monitoring & Observability
    ├── Container Metrics & Statistics
    ├── Log Management & Rotation
    ├── Performance Profiling
    └── Runtime Debugging Techniques
```

## 🔬 Core Topics

### 1. Health Check Strategy

**Ensuring Container Availability**

Health checks are Docker's mechanism for monitoring container health and enabling automatic recovery:

- **Health Check Types**: Command-based, HTTP endpoint, TCP socket checks
- **Health States**: Starting → Healthy → Unhealthy (with automatic restarts)
- **Configuration**: Interval, timeout, retries, start period parameters
- **Best Practices**: Lightweight checks, meaningful health indicators

**Key Benefits**:
- Automatic unhealthy container replacement
- Load balancer integration for traffic routing
- Early detection of application degradation
- Improved system reliability and uptime

### 2. Restart Policy Management

**Automated Container Recovery**

Restart policies define how Docker handles container failures:

- **no**: Never restart containers automatically
- **always**: Always restart, regardless of exit status
- **on-failure**: Restart only on non-zero exit codes
- **unless-stopped**: Always restart unless manually stopped

**Advanced Considerations**:
- Exponential backoff for failed restarts
- Maximum restart attempts configuration
- Dependency management between containers
- Graceful degradation strategies

### 3. Resource Constraints

**Performance and Isolation Control**

Resource limits prevent containers from monopolizing system resources:

- **Memory Management**: Hard limits, soft limits, swap accounting
- **CPU Control**: Shares, quota, cpuset constraints
- **I/O Limits**: Block device read/write throttling
- **Process Limits**: PID namespace constraints

**Production Patterns**:
- Right-sizing containers based on application needs
- Preventing resource starvation scenarios
- Monitoring and alerting on resource usage
- Capacity planning and scaling decisions

### 4. Signal Handling & Shutdown

**Graceful Container Termination**

Proper signal handling ensures clean shutdowns:

- **SIGTERM**: Graceful shutdown signal (default)
- **SIGKILL**: Force termination after timeout
- **Application Integration**: Signal handlers in application code
- **Shutdown Timeouts**: Configurable grace periods

**Critical Patterns**:
- Database connection cleanup
- Request completion before shutdown
- State persistence during termination
- Coordinated multi-container shutdowns

## 🛠 Prerequisites

- **Completed**: Phase 02 (BuildKit Advanced) - understanding of image creation and optimization
- **Docker**: 20.10+ with container runtime experience
- **Systems Knowledge**: Basic understanding of Linux signals and process management
- **Application Architecture**: Familiarity with web services and database patterns

## ⏱ Time Investment

- **Reading & Understanding**: 60 minutes
- **Hands-on Labs**: 120 minutes
- **Verification & Practice**: 45 minutes
- **Total**: ~3.5 hours

## 🎓 Learning Strategy

1. **Master Health Check Patterns**: Learn to design effective health monitoring
2. **Understand Restart Strategies**: Apply appropriate restart policies for different scenarios
3. **Practice Resource Management**: Experience resource constraints and monitoring
4. **Implement Signal Handling**: Ensure graceful shutdowns in applications

## 📖 Topic Deep Dives

### Health Checks: Beyond Simple Ping

**Traditional Problem**: Container process running ≠ application healthy

```bash
# Process exists but application is deadlocked
docker ps  # Shows "Up 2 hours"
curl localhost:8080  # Connection refused
```

**Health Check Solution**: Monitor application functionality

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

**Advanced Health Check Examples**:

```dockerfile
# Database connectivity check
HEALTHCHECK CMD pg_isready -h localhost -p 5432 -U postgres || exit 1

# Multi-endpoint health check
HEALTHCHECK CMD curl -f http://localhost:8080/health && \
                curl -f http://localhost:8080/ready || exit 1

# Custom health script
COPY healthcheck.sh /usr/local/bin/
HEALTHCHECK CMD /usr/local/bin/healthcheck.sh
```

### Restart Policies: Reliability Patterns

**Policy Selection Matrix**:

| Scenario | Policy | Reasoning |
|----------|--------|-----------|
| Web Service | `always` | Should recover from any failure |
| Batch Job | `on-failure` | Only restart on errors, not normal completion |
| Development | `no` | Manual control for debugging |
| System Service | `unless-stopped` | Automatic recovery but respect manual stops |

**Configuration Examples**:

```bash
# Always restart web service
docker run -d --restart always nginx:alpine

# Restart database on failure only
docker run -d --restart on-failure:5 postgres:13

# No automatic restart for development
docker run -it --restart no node:18-alpine sh
```

### Resource Management: Performance Boundaries

**Memory Management**:

```bash
# Hard memory limit - container killed if exceeded
docker run -m 512m my-app

# Memory + swap limit
docker run -m 512m --memory-swap 1g my-app

# OOM score adjustment
docker run --oom-score-adj 100 my-app
```

**CPU Management**:

```bash
# CPU shares (relative weight)
docker run --cpu-shares 1024 my-app

# CPU quota (percentage of CPU time)
docker run --cpus="1.5" my-app

# CPU affinity (specific cores)
docker run --cpuset-cpus="0,1" my-app
```

**I/O Management**:

```bash
# Block device read/write limits
docker run --device-read-bps /dev/sda:1mb my-app
docker run --device-write-bps /dev/sda:1mb my-app

# I/O weight priority
docker run --blkio-weight 500 my-app
```

### Signal Handling: Graceful Shutdowns

**Application Signal Handler Example** (Node.js):

```javascript
process.on('SIGTERM', async () => {
    console.log('SIGTERM received, starting graceful shutdown...');
    
    // Stop accepting new requests
    server.close(async () => {
        // Clean up resources
        await database.close();
        await cache.disconnect();
        
        console.log('Graceful shutdown completed');
        process.exit(0);
    });
    
    // Force shutdown after timeout
    setTimeout(() => {
        console.log('Force shutdown after timeout');
        process.exit(1);
    }, 10000);
});
```

**Docker Configuration**:

```bash
# Custom stop timeout
docker run --stop-timeout 30 my-app

# Custom stop signal
docker run --stop-signal SIGUSR1 my-app
```

## 🔍 Common Use Cases & Patterns

### Pattern 1: Web Service with Health Checks
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["node", "server.js"]
```

```bash
docker run -d --name web-service \
    --restart always \
    -p 3000:3000 \
    --memory 512m \
    --cpus="0.5" \
    web-service:latest
```

### Pattern 2: Database with Resource Constraints
```bash
docker run -d --name postgres-db \
    --restart unless-stopped \
    -e POSTGRES_DB=myapp \
    -e POSTGRES_USER=appuser \
    -e POSTGRES_PASSWORD_FILE=/run/secrets/db_password \
    --memory 2g \
    --cpus="1.0" \
    --shm-size=256m \
    -v postgres_data:/var/lib/postgresql/data \
    postgres:13-alpine
```

### Pattern 3: Batch Processing with Failure Handling
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# No health check for batch jobs
# Use exit codes for success/failure indication
CMD ["python", "batch_processor.py"]
```

```bash
docker run --name batch-job \
    --restart on-failure:3 \
    --memory 1g \
    --cpu-shares 512 \
    batch-processor:latest
```

## 💡 Production Considerations

### Health Check Design

**Effective Health Checks**:
- Check critical dependencies (database, external APIs)
- Verify application logic, not just process existence
- Keep checks lightweight (sub-second execution)
- Use meaningful HTTP status codes and responses

**Health Check Anti-patterns**:
❌ Checking only if process is running
❌ Heavy operations that impact performance  
❌ Checks that depend on external services exclusively
❌ No health checks on critical services

### Resource Planning

**Capacity Planning**:
- Monitor actual resource usage patterns
- Set limits based on peak + safety margin
- Plan for resource contention scenarios
- Use monitoring to validate assumptions

**Resource Monitoring**:
```bash
# Container resource usage
docker stats container_name

# Detailed resource information
docker inspect container_name | jq '.HostConfig'

# System-wide resource usage
docker system df
docker system events
```

### Signal Management

**Graceful Shutdown Checklist**:
- [ ] Application handles SIGTERM signal properly
- [ ] Database connections closed cleanly
- [ ] In-progress requests completed when possible
- [ ] Temporary files and locks cleaned up
- [ ] Dependent services notified of shutdown

**Testing Signal Handling**:
```bash
# Test graceful shutdown
docker stop --time 30 container_name

# Force immediate termination (for testing)
docker kill container_name

# Send custom signals
docker kill --signal SIGUSR1 container_name
```

## 🚨 Troubleshooting Common Issues

### Health Check Problems

**Issue**: Health checks always fail
```bash
# Debug health check command
docker exec container_name /bin/sh -c "curl -f http://localhost:8080/health"

# Check health check logs
docker inspect container_name | jq '.State.Health'
```

**Issue**: Container marked unhealthy but seems fine
```bash
# Review health check configuration
docker inspect container_name | jq '.Config.Healthcheck'

# Monitor health check execution
docker logs container_name | grep health
```

### Restart Loop Issues

**Issue**: Container keeps restarting
```bash
# Check restart count and policies
docker inspect container_name | jq '.RestartCount, .HostConfig.RestartPolicy'

# Review container logs for exit reasons
docker logs --tail 100 container_name

# Check resource constraints
docker stats container_name
```

### Resource Limit Problems

**Issue**: Container killed by OOM
```bash
# Check memory usage patterns
docker stats container_name

# Review system logs for OOM events  
dmesg | grep -i "killed process"

# Analyze container resource settings
docker inspect container_name | jq '.HostConfig.Memory'
```

## 📊 Monitoring & Metrics

### Container Performance Metrics

**Key Metrics to Monitor**:
- Memory usage and limits
- CPU utilization and throttling
- I/O operations and bandwidth
- Network connections and throughput
- Health check success rates
- Restart frequency and causes

**Monitoring Tools Integration**:
```bash
# Export metrics to monitoring systems
docker run -d \
    --name cadvisor \
    -p 8080:8080 \
    -v /:/rootfs:ro \
    -v /var/run:/var/run:ro \
    -v /sys:/sys:ro \
    -v /var/lib/docker/:/var/lib/docker:ro \
    gcr.io/cadvisor/cadvisor:latest
```

### Log Management

**Log Configuration**:
```bash
# Configure log driver and rotation
docker run -d \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    my-app:latest
```

**Log Analysis**:
```bash
# Follow logs in real-time
docker logs -f container_name

# Search logs for specific patterns
docker logs container_name 2>&1 | grep ERROR

# Export logs for analysis
docker logs --since 1h container_name > app.log
```

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Design and implement effective health check strategies for different application types
- [ ] Choose and configure appropriate restart policies based on service requirements  
- [ ] Set resource limits that optimize performance while preventing resource starvation
- [ ] Implement proper signal handling for graceful container shutdowns
- [ ] Monitor container performance and troubleshoot common operational issues
- [ ] Apply container operations best practices in production environments

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p03-m01-l01` - Health Check Design Patterns
- `p03-m01-l02` - Restart Policy Selection Matrix
- `p03-m01-l03` - Resource Constraint Planning
- `p03-m01-l04` - Signal Handling Implementation

## 🎯 What's Next

After mastering container operations:
- **Phase 04**: Docker networking and service communication
- **Phase 05**: Storage and volume management
- **Phase 10**: Advanced observability and monitoring

---

> 💡 **Key Insight**: Container operations is where Docker transitions from a development tool to a production platform. Mastering health checks, resource management, and lifecycle control is essential for running reliable, scalable containerized services. These operational patterns form the foundation for orchestration and advanced deployment strategies.