# Phase 03: Container Operations - Hands-on Labs

> **Practical exercises for mastering production container lifecycle management**

## 🎯 Lab Overview

These labs provide hands-on experience with container health checks, restart policies, resource management, and signal handling. Each lab builds practical skills essential for production container operations.

**Total Time**: ~120 minutes across 4 progressive labs

## 📋 Lab Environment Setup

### Prerequisites Check
```bash
# Verify Docker version and BuildKit
docker version --format '{{.Server.Version}}'
docker buildx version

# Check available system resources
docker system df
free -h
nproc
```

### Lab Working Directory
```bash
mkdir -p ~/docker-labs/container-operations
cd ~/docker-labs/container-operations
```

---

## 🔬 Lab 1: Health Check Design and Implementation

**Duration**: 30 minutes  
**Objective**: Design and test effective health check strategies for different application types

### Lab 1.1: Basic HTTP Health Checks

Create a web application with health monitoring:

```bash
# Create Node.js application with health endpoint
cat > app.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

let isHealthy = true;
let startTime = Date.now();
let requestCount = 0;

// Basic health check endpoint
app.get('/health', (req, res) => {
    requestCount++;
    
    if (!isHealthy) {
        return res.status(503).json({ 
            status: 'unhealthy', 
            reason: 'Service degraded' 
        });
    }
    
    // Simulate startup time
    const uptime = Date.now() - startTime;
    if (uptime < 10000) {
        return res.status(503).json({ 
            status: 'starting', 
            uptime: uptime 
        });
    }
    
    res.json({ 
        status: 'healthy', 
        uptime: uptime,
        requests: requestCount
    });
});

// Readiness check (more comprehensive)
app.get('/ready', async (req, res) => {
    try {
        // Simulate dependency checks
        const dbConnected = Math.random() > 0.1; // 90% success rate
        const cacheAvailable = true;
        
        if (!dbConnected) {
            throw new Error('Database connection failed');
        }
        
        res.json({ 
            status: 'ready',
            dependencies: {
                database: dbConnected,
                cache: cacheAvailable
            }
        });
    } catch (error) {
        res.status(503).json({ 
            status: 'not ready', 
            error: error.message 
        });
    }
});

// Admin endpoint to simulate failures
app.post('/admin/health/:state', (req, res) => {
    isHealthy = req.params.state === 'true';
    res.json({ health: isHealthy });
});

// Main application route
app.get('/', (req, res) => {
    res.json({ message: 'Health check demo application' });
});

app.listen(port, () => {
    console.log(`Health check demo listening on port ${port}`);
    console.log(`Health endpoint: http://localhost:${port}/health`);
    console.log(`Ready endpoint: http://localhost:${port}/ready`);
});
EOF

# Create package.json
cat > package.json << 'EOF'
{
    "name": "health-check-demo",
    "version": "1.0.0",
    "main": "app.js",
    "dependencies": {
        "express": "^4.18.0"
    },
    "scripts": {
        "start": "node app.js"
    }
}
EOF
```

Create Dockerfile with health check configuration:

```dockerfile
# Create Dockerfile with different health check strategies
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy dependencies first for better caching
COPY package*.json ./
RUN npm install --only=production

# Copy application code
COPY app.js .

# Expose port
EXPOSE 3000

# Health check configuration
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=2 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]
EOF
```

### Lab 1.2: Testing Health Check Scenarios

Build and test the application:

```bash
# Build the application
docker build -t health-demo:v1 .

# Run with health checks enabled
docker run -d --name health-test \
    -p 3001:3000 \
    health-demo:v1

# Monitor health check status
echo "Monitoring health status (press Ctrl+C to stop)..."
watch -n 2 'docker ps --format "table {{.Names}}\t{{.Status}}" | grep health-test'
```

Test different health scenarios:

```bash
# Test healthy state
curl http://localhost:3001/health
curl http://localhost:3001/ready

# Check Docker health status
docker inspect health-test | jq '.State.Health'

# Simulate application failure
curl -X POST http://localhost:3001/admin/health/false

# Wait and observe health status change
sleep 30
docker ps | grep health-test

# Restore health
curl -X POST http://localhost:3001/admin/health/true
sleep 20
docker ps | grep health-test
```

### Lab 1.3: Advanced Health Check Patterns

Create database health check example:

```bash
# Create MySQL health check
cat > Dockerfile.mysql << 'EOF'
FROM mysql:8.0

# Custom health check script
COPY <<EOF /usr/local/bin/health-check.sh
#!/bin/bash
mysql --user=root --password="\$MYSQL_ROOT_PASSWORD" \
      --execute="SELECT 1;" > /dev/null 2>&1
if [ \$? -eq 0 ]; then
    echo "MySQL is healthy"
    exit 0
else
    echo "MySQL is not responding"
    exit 1
fi
EOF

RUN chmod +x /usr/local/bin/health-check.sh

# Health check with custom script
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
    CMD /usr/local/bin/health-check.sh

ENV MYSQL_ROOT_PASSWORD=test123
ENV MYSQL_DATABASE=healthtest
EOF

# Build and test database health checks
docker build -f Dockerfile.mysql -t mysql-health:test .

docker run -d --name mysql-health \
    -e MYSQL_ROOT_PASSWORD=test123 \
    -e MYSQL_DATABASE=healthtest \
    mysql-health:test

# Monitor database startup and health
echo "Monitoring MySQL health (this takes ~60 seconds)..."
for i in {1..20}; do
    echo "Check $i:"
    docker inspect mysql-health | jq -r '.State.Health.Status // "no health check"'
    sleep 3
done
```

### Lab 1.4: Health Check Best Practices

Compare different health check approaches:

```bash
# Clean up previous containers
docker rm -f health-test mysql-health

# Test lightweight vs heavy health checks
cat > heavy-health.dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY app.js .
EXPOSE 3000

# ANTI-PATTERN: Heavy health check
HEALTHCHECK --interval=5s --timeout=10s --start-period=10s --retries=2 \
    CMD npm test && curl -f http://localhost:3000/health

CMD ["npm", "start"]
EOF

cat > light-health.dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY app.js .
EXPOSE 3000

# BEST PRACTICE: Lightweight health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["npm", "start"]
EOF

# Compare performance impact
echo "Building heavy health check version..."
docker build -f heavy-health.dockerfile -t health-demo:heavy . &

echo "Building light health check version..."  
docker build -f light-health.dockerfile -t health-demo:light . &

wait
echo "Both builds completed"
```

**Lab 1 Summary Questions**:
1. What's the difference between health checks and readiness probes?
2. When would you use a longer `start-period` value?
3. How do health checks integrate with Docker Swarm or orchestrators?

---

## ♻️ Lab 2: Restart Policy Configuration and Testing

**Duration**: 30 minutes  
**Objective**: Configure and test different restart policies for various failure scenarios

### Lab 2.1: Restart Policy Comparison

Create test applications with different behaviors:

```bash
# Create failing application
cat > failing-app.py << 'EOF'
#!/usr/bin/env python3
import sys
import time
import random
import os

exit_code = int(os.environ.get('EXIT_CODE', '1'))
run_time = int(os.environ.get('RUN_TIME', '10'))
failure_probability = float(os.environ.get('FAILURE_PROB', '0.5'))

print(f"Starting app (exit_code={exit_code}, run_time={run_time}s)")

# Simulate some work
for i in range(run_time):
    print(f"Working... {i+1}/{run_time}")
    time.sleep(1)
    
    # Random failure simulation
    if random.random() < failure_probability:
        print("ERROR: Random failure occurred!")
        sys.exit(exit_code)

print("Work completed successfully!")
sys.exit(0)
EOF

chmod +x failing-app.py

# Create Dockerfile for test application
cat > Dockerfile.failtest << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY failing-app.py .
CMD ["python", "failing-app.py"]
EOF

docker build -f Dockerfile.failtest -t fail-test:v1 .
```

### Lab 2.2: Testing Different Restart Policies

Test each restart policy:

```bash
# 1. Test 'no' restart policy
echo "=== Testing 'no' restart policy ==="
docker run -d --name no-restart \
    --restart no \
    -e EXIT_CODE=1 \
    -e RUN_TIME=5 \
    -e FAILURE_PROB=1.0 \
    fail-test:v1

# Wait and check status
sleep 10
docker ps -a | grep no-restart
echo "Restart count: $(docker inspect no-restart | jq '.RestartCount')"

# 2. Test 'always' restart policy  
echo "=== Testing 'always' restart policy ==="
docker run -d --name always-restart \
    --restart always \
    -e EXIT_CODE=1 \
    -e RUN_TIME=3 \
    -e FAILURE_PROB=1.0 \
    fail-test:v1

# Monitor restarts
sleep 15
docker ps | grep always-restart
echo "Restart count: $(docker inspect always-restart | jq '.RestartCount')"

# 3. Test 'on-failure' restart policy
echo "=== Testing 'on-failure' restart policy ==="
docker run -d --name on-failure-restart \
    --restart on-failure:3 \
    -e EXIT_CODE=1 \
    -e RUN_TIME=2 \
    -e FAILURE_PROB=1.0 \
    fail-test:v1

# Wait for max retries
sleep 15
docker ps -a | grep on-failure-restart
echo "Restart count: $(docker inspect on-failure-restart | jq '.RestartCount')"

# 4. Test successful completion with different policies
echo "=== Testing successful completion ==="
docker run -d --name success-always \
    --restart always \
    -e EXIT_CODE=0 \
    -e RUN_TIME=3 \
    -e FAILURE_PROB=0.0 \
    fail-test:v1

docker run -d --name success-on-failure \
    --restart on-failure \
    -e EXIT_CODE=0 \
    -e RUN_TIME=3 \
    -e FAILURE_PROB=0.0 \
    fail-test:v1

sleep 10
docker ps -a | grep success-
```

### Lab 2.3: Advanced Restart Scenarios

Simulate real-world restart scenarios:

```bash
# Web service restart scenario
cat > web-service.py << 'EOF'
#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import time
import signal
import sys
import os

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_response(404)
            self.end_headers()
            
    def log_message(self, format, *args):
        # Suppress default logging
        pass

class WebService:
    def __init__(self, port=8080):
        self.port = port
        self.server = None
        self.running = False
        
    def start(self):
        self.server = HTTPServer(('', self.port), HealthHandler)
        self.running = True
        print(f"Web service starting on port {self.port}")
        
        # Simulate random crashes
        crash_thread = threading.Thread(target=self.random_crash)
        crash_thread.daemon = True
        crash_thread.start()
        
        try:
            self.server.serve_forever()
        except KeyboardInterrupt:
            self.stop()
            
    def random_crash(self):
        import random
        crash_probability = float(os.environ.get('CRASH_PROB', '0.1'))
        
        while self.running:
            time.sleep(30)  # Check every 30 seconds
            if random.random() < crash_probability:
                print("CRITICAL ERROR: Simulated crash!")
                os._exit(1)
                
    def stop(self):
        self.running = False
        if self.server:
            self.server.shutdown()
        print("Web service stopped")

# Signal handling for graceful shutdown
def signal_handler(signum, frame):
    print(f"Received signal {signum}")
    service.stop()
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

if __name__ == '__main__':
    service = WebService()
    service.start()
EOF

cat > Dockerfile.webservice << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY web-service.py .

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=2 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

EXPOSE 8080
CMD ["python", "web-service.py"]
EOF

docker build -f Dockerfile.webservice -t web-service:restart-test .

# Test web service with different restart policies
docker run -d --name web-always \
    --restart always \
    -p 8081:8080 \
    -e CRASH_PROB=0.3 \
    web-service:restart-test

# Monitor the service and its restarts
echo "Monitoring web service restarts (press Ctrl+C to stop)..."
for i in {1..10}; do
    echo "=== Check $i ==="
    echo "Status: $(docker ps --format 'table {{.Status}}' | grep -v STATUS | head -1)"
    echo "Health: $(docker inspect web-always | jq -r '.State.Health.Status // "no health check"')"
    echo "Restart count: $(docker inspect web-always | jq '.RestartCount')"
    echo "---"
    sleep 15
done
```

### Lab 2.4: Restart Policy Best Practices

Create production-ready restart configurations:

```bash
# Database restart configuration
docker run -d --name postgres-prod \
    --restart unless-stopped \
    -e POSTGRES_PASSWORD=secure123 \
    -e POSTGRES_DB=proddb \
    --memory 1g \
    --cpus="0.5" \
    postgres:13-alpine

# Background job processor
docker run -d --name job-processor \
    --restart on-failure:5 \
    -e EXIT_CODE=1 \
    -e RUN_TIME=60 \
    -e FAILURE_PROB=0.1 \
    fail-test:v1

# Development container (manual control)
docker run -d --name dev-container \
    --restart no \
    -it \
    node:18-alpine sh

# Check all running containers and their restart policies
echo "=== Container Restart Policies ==="
docker ps --format "table {{.Names}}\t{{.Status}}"

# Inspect restart policies
for container in postgres-prod job-processor dev-container; do
    echo "=== $container ==="
    docker inspect $container | jq '.HostConfig.RestartPolicy'
    echo
done
```

**Lab 2 Summary Questions**:
1. When would you choose `unless-stopped` over `always`?
2. How do restart policies interact with health checks?
3. What happens to restart counts when you manually stop a container?

---

## 🎛️ Lab 3: Resource Management and Constraints

**Duration**: 35 minutes  
**Objective**: Apply memory, CPU, and I/O constraints to optimize container performance

### Lab 3.1: Memory Limit Testing

Create memory-intensive application:

```bash
# Create memory testing application
cat > memory-test.py << 'EOF'
#!/usr/bin/env python3
import sys
import time
import os

def allocate_memory(size_mb):
    """Allocate specified amount of memory"""
    print(f"Allocating {size_mb}MB of memory...")
    
    # Allocate memory in chunks
    memory_blocks = []
    chunk_size = 1024 * 1024  # 1MB chunks
    
    for i in range(size_mb):
        try:
            # Allocate and fill with data to prevent optimization
            block = bytearray(chunk_size)
            # Fill with data to ensure actual memory allocation
            for j in range(0, chunk_size, 1024):
                block[j:j+1024] = b'x' * 1024
            memory_blocks.append(block)
            
            if (i + 1) % 10 == 0:
                print(f"Allocated {i + 1}MB so far...")
                time.sleep(0.1)  # Brief pause
                
        except MemoryError:
            print(f"MemoryError: Could not allocate memory at {i}MB")
            return memory_blocks
            
    print(f"Successfully allocated {size_mb}MB")
    return memory_blocks

def main():
    target_mb = int(os.environ.get('MEMORY_TARGET', '100'))
    hold_time = int(os.environ.get('HOLD_TIME', '30'))
    
    print(f"Memory test starting - targeting {target_mb}MB for {hold_time} seconds")
    
    memory_blocks = allocate_memory(target_mb)
    
    print(f"Holding memory for {hold_time} seconds...")
    time.sleep(hold_time)
    
    print("Releasing memory and exiting...")
    del memory_blocks
    print("Memory test completed")

if __name__ == '__main__':
    main()
EOF

cat > Dockerfile.memtest << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY memory-test.py .
CMD ["python", "memory-test.py"]
EOF

docker build -f Dockerfile.memtest -t memory-test:v1 .
```

Test memory limits and OOM behavior:

```bash
# Test 1: Container with sufficient memory
echo "=== Test 1: Sufficient memory (512MB limit, 256MB usage) ==="
docker run --name mem-test-ok \
    --memory 512m \
    -e MEMORY_TARGET=256 \
    -e HOLD_TIME=10 \
    memory-test:v1

docker wait mem-test-ok
echo "Exit code: $?"
docker rm mem-test-ok

# Test 2: Container hitting memory limit
echo "=== Test 2: Memory limit exceeded (256MB limit, 512MB usage) ==="
docker run --name mem-test-oom \
    --memory 256m \
    -e MEMORY_TARGET=512 \
    -e HOLD_TIME=10 \
    memory-test:v1

docker wait mem-test-oom
echo "Exit code: $?"

# Check for OOM killer logs
docker logs mem-test-oom
docker rm mem-test-oom

# Test 3: Memory with swap limit
echo "=== Test 3: Memory + swap limit ==="
docker run --name mem-test-swap \
    --memory 256m \
    --memory-swap 512m \
    -e MEMORY_TARGET=400 \
    -e HOLD_TIME=10 \
    memory-test:v1

docker wait mem-test-swap
echo "Exit code: $?"
docker logs mem-test-swap
docker rm mem-test-swap
```

### Lab 3.2: CPU Constraint Testing

Create CPU-intensive application:

```bash
# Create CPU testing application
cat > cpu-test.py << 'EOF'
#!/usr/bin/env python3
import multiprocessing
import time
import os
import sys

def cpu_intensive_task(duration, worker_id):
    """CPU intensive computation"""
    start_time = time.time()
    count = 0
    
    print(f"Worker {worker_id} starting CPU intensive task for {duration} seconds")
    
    while time.time() - start_time < duration:
        # CPU intensive calculation
        for i in range(1000):
            count += i ** 2
        
    print(f"Worker {worker_id} completed {count} calculations")
    return count

def main():
    duration = int(os.environ.get('CPU_DURATION', '30'))
    workers = int(os.environ.get('CPU_WORKERS', str(multiprocessing.cpu_count())))
    
    print(f"Starting CPU test with {workers} workers for {duration} seconds")
    print(f"Available CPUs: {multiprocessing.cpu_count()}")
    
    start_time = time.time()
    
    # Create worker processes
    with multiprocessing.Pool(processes=workers) as pool:
        results = [
            pool.apply_async(cpu_intensive_task, (duration, i)) 
            for i in range(workers)
        ]
        
        # Wait for all workers to complete
        total_calculations = sum(result.get() for result in results)
    
    end_time = time.time()
    elapsed = end_time - start_time
    
    print(f"CPU test completed in {elapsed:.2f} seconds")
    print(f"Total calculations: {total_calculations}")
    print(f"Calculations per second: {total_calculations / elapsed:.0f}")

if __name__ == '__main__':
    main()
EOF

cat > Dockerfile.cputest << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY cpu-test.py .
CMD ["python", "cpu-test.py"]
EOF

docker build -f Dockerfile.cputest -t cpu-test:v1 .
```

Test CPU constraints:

```bash
# Test 1: Unlimited CPU access
echo "=== Test 1: Unlimited CPU ==="
time docker run --name cpu-test-unlimited \
    -e CPU_DURATION=10 \
    -e CPU_WORKERS=4 \
    cpu-test:v1

docker rm cpu-test-unlimited

# Test 2: CPU limit (50% of 1 core)
echo "=== Test 2: Limited CPU (0.5 cores) ==="
time docker run --name cpu-test-limited \
    --cpus="0.5" \
    -e CPU_DURATION=10 \
    -e CPU_WORKERS=4 \
    cpu-test:v1

docker rm cpu-test-limited

# Test 3: CPU shares (lower priority)
echo "=== Test 3: CPU shares comparison ==="

# High priority container
docker run -d --name cpu-high-priority \
    --cpu-shares 1024 \
    -e CPU_DURATION=20 \
    -e CPU_WORKERS=2 \
    cpu-test:v1 &

# Low priority container  
docker run -d --name cpu-low-priority \
    --cpu-shares 512 \
    -e CPU_DURATION=20 \
    -e CPU_WORKERS=2 \
    cpu-test:v1 &

# Monitor CPU usage
echo "Monitoring CPU usage (press Ctrl+C to stop)..."
docker stats --no-stream cpu-high-priority cpu-low-priority

# Wait for completion
docker wait cpu-high-priority cpu-low-priority

# Check results
echo "High priority results:"
docker logs cpu-high-priority | tail -3

echo "Low priority results:"  
docker logs cpu-low-priority | tail -3

docker rm cpu-high-priority cpu-low-priority
```

### Lab 3.3: I/O and Process Limits

Test I/O and process constraints:

```bash
# Create I/O intensive application
cat > io-test.py << 'EOF'
#!/usr/bin/env python3
import os
import time
import threading

def write_test_data(filename, size_mb, chunk_size=1024*1024):
    """Write test data to file"""
    print(f"Writing {size_mb}MB to {filename}")
    
    start_time = time.time()
    with open(filename, 'wb') as f:
        for i in range(size_mb):
            data = os.urandom(chunk_size)
            f.write(data)
            if (i + 1) % 10 == 0:
                print(f"Written {i + 1}MB...")
    
    end_time = time.time()
    elapsed = end_time - start_time
    print(f"Write completed in {elapsed:.2f} seconds ({size_mb/elapsed:.1f} MB/s)")

def read_test_data(filename):
    """Read test data from file"""
    print(f"Reading from {filename}")
    
    start_time = time.time()
    size = 0
    with open(filename, 'rb') as f:
        while True:
            chunk = f.read(1024*1024)
            if not chunk:
                break
            size += len(chunk)
    
    end_time = time.time()
    elapsed = end_time - start_time
    size_mb = size / (1024*1024)
    print(f"Read {size_mb:.1f}MB in {elapsed:.2f} seconds ({size_mb/elapsed:.1f} MB/s)")

def main():
    size_mb = int(os.environ.get('IO_SIZE', '100'))
    
    # Write test
    write_test_data('/tmp/testfile', size_mb)
    
    # Read test
    read_test_data('/tmp/testfile')
    
    # Cleanup
    os.remove('/tmp/testfile')
    print("I/O test completed")

if __name__ == '__main__':
    main()
EOF

cat > Dockerfile.iotest << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY io-test.py .
CMD ["python", "io-test.py"]
EOF

docker build -f Dockerfile.iotest -t io-test:v1 .

# Test I/O limits (requires root privileges and specific block device)
echo "=== I/O Limits Test (basic demonstration) ==="
# Note: I/O limits work best with specific block devices

# Test without limits
echo "Test without I/O limits:"
time docker run --name io-test-unlimited \
    -e IO_SIZE=50 \
    io-test:v1

docker rm io-test-unlimited

# Test process limits
echo "=== Process Limit Test ==="
cat > process-test.sh << 'EOF'
#!/bin/bash
echo "Testing process limits..."
echo "Current PID limit: $(cat /sys/fs/cgroup/pids/pids.max 2>/dev/null || echo 'not available')"

# Try to create multiple processes
for i in {1..1000}; do
    sleep 60 &
    if [ $i -eq 50 ] || [ $i -eq 100 ] || [ $i -eq 500 ] || [ $i -eq 1000 ]; then
        echo "Created $i background processes"
    fi
done

echo "Process creation completed"
wait
EOF

chmod +x process-test.sh

# Run with process limit
docker run --name process-test-limited \
    --pids-limit 100 \
    -v $(pwd)/process-test.sh:/test.sh \
    alpine:latest /test.sh &

sleep 5
echo "Process limit test status:"
docker logs process-test-limited

docker rm -f process-test-limited
```

### Lab 3.4: Resource Monitoring and Optimization

Monitor and analyze resource usage:

```bash
# Create comprehensive resource monitoring
cat > resource-monitor.py << 'EOF'
#!/usr/bin/env python3
import time
import threading
import multiprocessing
import os

class ResourceMonitor:
    def __init__(self):
        self.running = True
        
    def memory_consumer(self, target_mb):
        """Consume specified amount of memory"""
        memory_blocks = []
        for i in range(target_mb):
            block = bytearray(1024 * 1024)  # 1MB
            memory_blocks.append(block)
            time.sleep(0.1)
        
        print(f"Memory consumer holding {target_mb}MB")
        while self.running:
            time.sleep(1)
            
    def cpu_consumer(self, worker_id):
        """Consume CPU cycles"""
        print(f"CPU worker {worker_id} starting")
        count = 0
        while self.running:
            for _ in range(10000):
                count += 1
            time.sleep(0.001)  # Brief pause
        
        print(f"CPU worker {worker_id} completed {count} operations")
        
    def start_test(self):
        memory_mb = int(os.environ.get('MEMORY_MB', '200'))
        cpu_workers = int(os.environ.get('CPU_WORKERS', '2'))
        duration = int(os.environ.get('TEST_DURATION', '30'))
        
        print(f"Starting resource test: {memory_mb}MB memory, {cpu_workers} CPU workers, {duration}s duration")
        
        # Start memory consumer
        memory_thread = threading.Thread(target=self.memory_consumer, args=(memory_mb,))
        memory_thread.start()
        
        # Start CPU consumers
        cpu_threads = []
        for i in range(cpu_workers):
            thread = threading.Thread(target=self.cpu_consumer, args=(i,))
            thread.start()
            cpu_threads.append(thread)
        
        # Run for specified duration
        time.sleep(duration)
        
        # Stop all workers
        print("Stopping resource test...")
        self.running = False
        
        # Wait for threads to complete
        memory_thread.join()
        for thread in cpu_threads:
            thread.join()
            
        print("Resource test completed")

if __name__ == '__main__':
    monitor = ResourceMonitor()
    monitor.start_test()
EOF

cat > Dockerfile.monitor << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY resource-monitor.py .
CMD ["python", "resource-monitor.py"]
EOF

docker build -f Dockerfile.monitor -t resource-monitor:v1 .

# Run resource monitor with different constraints
echo "=== Resource Monitoring with Constraints ==="

# Test 1: Balanced resources
docker run -d --name resource-balanced \
    --memory 512m \
    --cpus="1.0" \
    -e MEMORY_MB=256 \
    -e CPU_WORKERS=2 \
    -e TEST_DURATION=20 \
    resource-monitor:v1

# Test 2: Memory constrained
docker run -d --name resource-mem-constrained \
    --memory 256m \
    --cpus="2.0" \
    -e MEMORY_MB=200 \
    -e CPU_WORKERS=4 \
    -e TEST_DURATION=20 \
    resource-monitor:v1

# Test 3: CPU constrained
docker run -d --name resource-cpu-constrained \
    --memory 1g \
    --cpus="0.5" \
    -e MEMORY_MB=256 \
    -e CPU_WORKERS=4 \
    -e TEST_DURATION=20 \
    resource-monitor:v1

# Monitor all containers
echo "Monitoring resource usage..."
docker stats --no-stream resource-balanced resource-mem-constrained resource-cpu-constrained

# Wait for completion
docker wait resource-balanced resource-mem-constrained resource-cpu-constrained

# Check results
echo "=== Test Results ==="
for container in resource-balanced resource-mem-constrained resource-cpu-constrained; do
    echo "=== $container ==="
    docker logs $container | tail -3
    echo
done

# Cleanup
docker rm resource-balanced resource-mem-constrained resource-cpu-constrained
```

**Lab 3 Summary Questions**:
1. How do you determine appropriate resource limits for an application?
2. What's the difference between memory limit and memory+swap limit?
3. When would you use CPU shares vs CPU quotas?

---

## 📡 Lab 4: Signal Handling and Graceful Shutdowns

**Duration**: 25 minutes  
**Objective**: Implement proper signal handling for graceful container shutdowns

### Lab 4.1: Basic Signal Handling

Create applications that handle signals properly:

```bash
# Create Python application with signal handling
cat > signal-demo.py << 'EOF'
#!/usr/bin/env python3
import signal
import sys
import time
import threading
import queue

class GracefulService:
    def __init__(self):
        self.running = True
        self.work_queue = queue.Queue()
        self.active_tasks = 0
        self.completed_tasks = 0
        
    def signal_handler(self, signum, frame):
        signal_names = {
            signal.SIGTERM: 'SIGTERM',
            signal.SIGINT: 'SIGINT',
            signal.SIGUSR1: 'SIGUSR1',
            signal.SIGUSR2: 'SIGUSR2'
        }
        
        signal_name = signal_names.get(signum, f'Signal {signum}')
        print(f"Received {signal_name} - initiating graceful shutdown...")
        
        if signum == signal.SIGUSR1:
            # Custom signal - print status
            print(f"Status: {self.active_tasks} active tasks, {self.completed_tasks} completed")
            return
            
        # Start graceful shutdown
        self.running = False
        
        # Stop accepting new work
        print("Stopping work queue...")
        
        # Wait for active tasks to complete (with timeout)
        shutdown_timeout = 10
        start_time = time.time()
        
        while self.active_tasks > 0 and (time.time() - start_time) < shutdown_timeout:
            print(f"Waiting for {self.active_tasks} active tasks to complete...")
            time.sleep(1)
            
        if self.active_tasks > 0:
            print(f"Force shutdown - {self.active_tasks} tasks will be terminated")
        else:
            print("All tasks completed successfully")
            
        print("Graceful shutdown completed")
        sys.exit(0)
        
    def worker(self, worker_id):
        """Worker thread that processes tasks"""
        while self.running or not self.work_queue.empty():
            try:
                task = self.work_queue.get(timeout=1)
                self.active_tasks += 1
                
                print(f"Worker {worker_id} processing task {task}")
                
                # Simulate work (interruptible)
                for i in range(10):
                    if not self.running:
                        print(f"Worker {worker_id} interrupted during task {task}")
                        break
                    time.sleep(0.5)
                    
                self.completed_tasks += 1
                self.active_tasks -= 1
                print(f"Worker {worker_id} completed task {task}")
                
                self.work_queue.task_done()
                
            except queue.Empty:
                continue
                
        print(f"Worker {worker_id} shutting down")
        
    def start(self):
        # Register signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGUSR1, self.signal_handler)
        
        print("Service starting with graceful shutdown support...")
        print("Send SIGUSR1 for status, SIGTERM/SIGINT for graceful shutdown")
        
        # Start worker threads
        workers = []
        for i in range(3):
            worker = threading.Thread(target=self.worker, args=(i,))
            worker.start()
            workers.append(worker)
            
        # Add work to queue
        for i in range(20):
            self.work_queue.put(f"task-{i}")
            time.sleep(0.5)  # Simulate work arrival
            
        print("All work queued, workers processing...")
        
        # Wait for all work to complete or shutdown signal
        try:
            self.work_queue.join()
            print("All work completed naturally")
        except KeyboardInterrupt:
            print("Interrupted by user")
            
        # Clean shutdown
        self.running = False
        for worker in workers:
            worker.join()
            
        print("Service shutdown complete")

if __name__ == '__main__':
    service = GracefulService()
    service.start()
EOF

cat > Dockerfile.signals << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY signal-demo.py .

# Important: Use exec form to ensure proper signal handling
CMD ["python", "signal-demo.py"]
EOF

docker build -f Dockerfile.signals -t signal-demo:v1 .
```

### Lab 4.2: Testing Signal Behavior

Test different signal scenarios:

```bash
# Test 1: Normal completion
echo "=== Test 1: Normal completion ==="
docker run --name signal-test-normal signal-demo:v1 &
CONTAINER_PID=$!

sleep 15
docker logs signal-test-normal
docker wait signal-test-normal
docker rm signal-test-normal

# Test 2: SIGTERM graceful shutdown
echo "=== Test 2: SIGTERM graceful shutdown ==="
docker run -d --name signal-test-term signal-demo:v1

# Let it start working
sleep 5

# Send status signal first
echo "Sending SIGUSR1 for status..."
docker kill --signal SIGUSR1 signal-test-term
sleep 2

# Send graceful shutdown
echo "Sending SIGTERM for graceful shutdown..."
docker stop --time 15 signal-test-term

# Check logs
docker logs signal-test-term
docker rm signal-test-term

# Test 3: SIGKILL force shutdown
echo "=== Test 3: SIGKILL force shutdown ==="
docker run -d --name signal-test-kill signal-demo:v1

sleep 3
echo "Force killing container..."
docker kill signal-test-kill

docker logs signal-test-kill
docker rm signal-test-kill
```

### Lab 4.3: Web Service Graceful Shutdown

Create web service with proper shutdown handling:

```bash
# Create web service with graceful shutdown
cat > web-shutdown.py << 'EOF'
#!/usr/bin/env python3
import signal
import sys
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import queue

class GracefulHTTPServer:
    def __init__(self, port=8080):
        self.port = port
        self.server = None
        self.shutting_down = False
        self.active_requests = 0
        self.total_requests = 0
        
    def signal_handler(self, signum, frame):
        print(f"\nReceived signal {signum} - starting graceful shutdown...")
        self.shutdown()
        
    def shutdown(self):
        self.shutting_down = True
        
        if self.server:
            print("Stopping HTTP server...")
            
            # Wait for active requests to complete
            shutdown_timeout = 10
            start_time = time.time()
            
            while self.active_requests > 0 and (time.time() - start_time) < shutdown_timeout:
                print(f"Waiting for {self.active_requests} active requests...")
                time.sleep(1)
                
            self.server.shutdown()
            print(f"HTTP server stopped. Processed {self.total_requests} total requests.")
            
        sys.exit(0)
        
    def start(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        handler = self.create_handler()
        self.server = HTTPServer(('', self.port), handler)
        
        print(f"Starting HTTP server on port {self.port}")
        print("Send SIGTERM for graceful shutdown")
        
        try:
            self.server.serve_forever()
        except KeyboardInterrupt:
            self.shutdown()
            
    def create_handler(self):
        server = self
        
        class RequestHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                server.active_requests += 1
                server.total_requests += 1
                
                try:
                    if server.shutting_down:
                        self.send_response(503)
                        self.send_header('Content-type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({
                            'status': 'shutting_down',
                            'message': 'Server is shutting down'
                        }).encode())
                        return
                        
                    if self.path == '/health':
                        self.send_response(200)
                        self.send_header('Content-type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({
                            'status': 'healthy',
                            'active_requests': server.active_requests,
                            'total_requests': server.total_requests
                        }).encode())
                        
                    elif self.path == '/slow':
                        # Simulate slow request
                        print(f"Processing slow request... ({server.active_requests} active)")
                        time.sleep(5)
                        
                        self.send_response(200)
                        self.send_header('Content-type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({
                            'message': 'Slow request completed',
                            'processing_time': 5
                        }).encode())
                        
                    else:
                        self.send_response(200)
                        self.send_header('Content-type', 'application/json')  
                        self.end_headers()
                        self.wfile.write(json.dumps({
                            'message': 'Hello from graceful web server',
                            'request_count': server.total_requests
                        }).encode())
                        
                finally:
                    server.active_requests -= 1
                    
            def log_message(self, format, *args):
                # Suppress default request logging
                pass
                
        return RequestHandler

if __name__ == '__main__':
    server = GracefulHTTPServer()
    server.start()
EOF

cat > Dockerfile.webshutdown << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY web-shutdown.py .

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=2 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

EXPOSE 8080
CMD ["python", "web-shutdown.py"]
EOF

docker build -f Dockerfile.webshutdown -t web-shutdown:v1 .

# Test web service graceful shutdown
echo "=== Testing Web Service Graceful Shutdown ==="
docker run -d --name web-graceful \
    -p 8082:8080 \
    web-shutdown:v1

# Wait for startup
sleep 5

# Make some requests
echo "Making normal requests..."
curl -s http://localhost:8082/health | jq .
curl -s http://localhost:8082/ | jq .

# Start slow request in background
echo "Starting slow request..."
curl -s http://localhost:8082/slow &
CURL_PID=$!

sleep 1

# Trigger graceful shutdown while slow request is processing
echo "Triggering graceful shutdown..."
docker stop --time 20 web-graceful

# Wait for background curl to complete
wait $CURL_PID
echo "Slow request completed"

# Check logs
docker logs web-graceful
docker rm web-graceful
```

### Lab 4.4: Database Connection Cleanup

Simulate database connection cleanup during shutdown:

```bash
# Create database simulation with connection cleanup
cat > db-cleanup.py << 'EOF'
#!/usr/bin/env python3
import signal
import sys
import time
import threading
import random

class DatabaseConnection:
    def __init__(self, conn_id):
        self.conn_id = conn_id
        self.active = True
        self.transactions = 0
        
    def execute_query(self, query):
        if not self.active:
            raise Exception("Connection closed")
            
        print(f"Connection {self.conn_id}: Executing {query}")
        time.sleep(random.uniform(0.1, 0.5))  # Simulate query time
        self.transactions += 1
        
    def close(self):
        if self.active:
            print(f"Connection {self.conn_id}: Closing (processed {self.transactions} transactions)")
            self.active = False
            time.sleep(0.1)  # Simulate cleanup time

class DatabaseService:
    def __init__(self):
        self.running = True
        self.connections = []
        self.connection_lock = threading.Lock()
        
    def signal_handler(self, signum, frame):
        print(f"\nReceived signal {signum} - starting database shutdown...")
        self.shutdown()
        
    def create_connection(self):
        with self.connection_lock:
            conn = DatabaseConnection(len(self.connections))
            self.connections.append(conn)
            print(f"Created database connection {conn.conn_id}")
            return conn
            
    def query_worker(self, worker_id):
        """Worker that makes database queries"""
        conn = self.create_connection()
        
        try:
            while self.running:
                if random.random() < 0.7:  # 70% chance of making a query
                    query = f"SELECT * FROM table_{random.randint(1,5)}"
                    try:
                        conn.execute_query(query)
                    except Exception as e:
                        print(f"Worker {worker_id}: Query failed - {e}")
                        break
                        
                time.sleep(random.uniform(0.5, 2.0))
                
        finally:
            conn.close()
            print(f"Worker {worker_id} finished")
            
    def shutdown(self):
        print("Initiating database service shutdown...")
        self.running = False
        
        # Wait a moment for workers to finish current queries
        time.sleep(2)
        
        # Close all connections
        with self.connection_lock:
            print(f"Closing {len(self.connections)} database connections...")
            for conn in self.connections:
                conn.close()
                
        print("Database service shutdown completed")
        sys.exit(0)
        
    def start(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        print("Starting database service...")
        
        # Start query workers
        workers = []
        for i in range(5):
            worker = threading.Thread(target=self.query_worker, args=(i,))
            worker.start()
            workers.append(worker)
            
        # Keep service running
        try:
            for worker in workers:
                worker.join()
        except KeyboardInterrupt:
            self.shutdown()
            
        print("All workers completed")

if __name__ == '__main__':
    service = DatabaseService()
    service.start()
EOF

cat > Dockerfile.dbcleanup << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY db-cleanup.py .
CMD ["python", "db-cleanup.py"]
EOF

docker build -f Dockerfile.dbcleanup -t db-cleanup:v1 .

# Test database cleanup
echo "=== Testing Database Connection Cleanup ==="
docker run -d --name db-cleanup-test db-cleanup:v1

# Let it run for a bit
sleep 10

# Trigger graceful shutdown
echo "Triggering graceful database shutdown..."
docker stop --time 15 db-cleanup-test

# Check logs
docker logs db-cleanup-test
docker rm db-cleanup-test
```

**Lab 4 Summary Questions**:
1. Why is the exec form of CMD important for signal handling?
2. What's the difference between SIGTERM and SIGKILL?
3. How do you handle cleanup when some operations can't be interrupted?

---

## 🧹 Lab Cleanup

Clean up all lab resources:

```bash
# Remove all test containers
docker rm -f $(docker ps -aq --filter label=lab=container-ops) 2>/dev/null || true

# Remove lab images
docker rmi -f \
    health-demo:v1 health-demo:heavy health-demo:light \
    mysql-health:test fail-test:v1 web-service:restart-test \
    memory-test:v1 cpu-test:v1 io-test:v1 resource-monitor:v1 \
    signal-demo:v1 web-shutdown:v1 db-cleanup:v1 \
    2>/dev/null || true

# Clean up working directory
cd ~
rm -rf ~/docker-labs/container-operations

# Clean up Docker system
docker system prune -f

echo "Lab cleanup completed!"
```

## 🎯 Lab Summary & Next Steps

### Key Skills Acquired:
- ✅ Health check design and implementation
- ✅ Restart policy configuration and testing
- ✅ Resource constraint application and monitoring  
- ✅ Signal handling and graceful shutdown implementation

### Production Readiness Checklist:
- [ ] Health checks monitor actual application functionality
- [ ] Restart policies match service reliability requirements
- [ ] Resource limits prevent container resource monopolization
- [ ] Applications handle SIGTERM for graceful shutdowns
- [ ] Database connections and resources cleaned up properly

### Advanced Topics to Explore:
- Container orchestration with health checks
- Advanced resource scheduling and affinity
- Custom signal handlers for complex applications
- Integration with monitoring and alerting systems

These container operations skills form the foundation for reliable, production-grade containerized services.