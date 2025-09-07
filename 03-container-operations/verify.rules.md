# Phase 03: Container Operations - Verification Rules

> **Comprehensive validation of container lifecycle management and production operations skills**

## 🎯 Verification Overview

These rules validate mastery of container operations including health monitoring, restart policies, resource management, and graceful shutdowns. All verification focuses on production reliability and operational excellence.

## ✅ Verification Rules

### Rule 1: Health Check Strategy Implementation
**Anchor**: `p03-health-strategy`  
**Type**: Automated + Manual

**Automated Test Setup**:
```bash
mkdir -p verify-p03-health && cd verify-p03-health

# Create test application with health endpoints
cat > health-app.py << 'EOF'
import http.server
import socketserver
import json
import threading
import time
import random

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            # Basic health check
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'healthy', 'timestamp': time.time()}).encode())
            
        elif self.path == '/ready':
            # Readiness check with dependency simulation
            db_healthy = random.random() > 0.2  # 80% success rate
            cache_healthy = random.random() > 0.1  # 90% success rate
            
            if db_healthy and cache_healthy:
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'status': 'ready',
                    'dependencies': {'database': db_healthy, 'cache': cache_healthy}
                }).encode())
            else:
                self.send_response(503)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'status': 'not ready',
                    'dependencies': {'database': db_healthy, 'cache': cache_healthy}
                }).encode())
                
        else:
            self.send_response(404)
            self.end_headers()
            
    def log_message(self, format, *args):
        pass  # Suppress request logging

if __name__ == '__main__':
    port = 8080
    with socketserver.TCPServer(("", port), HealthHandler) as httpd:
        print(f"Health app serving on port {port}")
        httpd.serve_forever()
EOF
```

**Student Task**: Create Dockerfile with appropriate health check configuration

**Automated Verification**:
```bash
# Test health check implementation
if docker build -t verify-health . >/dev/null 2>&1; then
    echo "✅ Health check Dockerfile builds successfully"
    HEALTH_BUILD=passed
else
    echo "❌ Health check Dockerfile build failed"
    HEALTH_BUILD=failed
fi

# Test health check configuration
HEALTH_CONFIG=$(docker inspect verify-health | jq -r '.Config.Healthcheck.Test[]' 2>/dev/null | tr '\n' ' ')
if [[ "$HEALTH_CONFIG" =~ (curl|wget).*(health|8080) ]]; then
    echo "✅ Health check properly configured"
    HEALTH_CONFIG_TEST=passed
else
    echo "❌ Health check configuration missing or incorrect"
    echo "Found: $HEALTH_CONFIG"
    HEALTH_CONFIG_TEST=failed
fi

# Test health check functionality
docker run -d --name verify-health-run -p 8080:8080 verify-health
sleep 10

# Check health status
HEALTH_STATUS=$(docker inspect verify-health-run | jq -r '.State.Health.Status')
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo "✅ Container reports healthy status"
    HEALTH_FUNCTION=passed
else
    echo "❌ Container not reporting healthy status: $HEALTH_STATUS"
    HEALTH_FUNCTION=failed
fi

# Test health endpoint directly
if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo "✅ Health endpoint responds correctly"
    HEALTH_ENDPOINT=passed
else
    echo "❌ Health endpoint not responding properly"
    HEALTH_ENDPOINT=failed
fi

# Test readiness endpoint
READY_ATTEMPTS=5
READY_SUCCESS=0
for i in $(seq 1 $READY_ATTEMPTS); do
    if curl -s http://localhost:8080/ready | grep -q "ready"; then
        READY_SUCCESS=$((READY_SUCCESS + 1))
    fi
    sleep 1
done

if [ $READY_SUCCESS -ge 3 ]; then
    echo "✅ Readiness endpoint demonstrates dependency checking"
    READINESS_TEST=passed
else
    echo "❌ Readiness endpoint not working properly ($READY_SUCCESS/$READY_ATTEMPTS successes)"
    READINESS_TEST=failed
fi

docker rm -f verify-health-run
docker image rm verify-health
cd .. && rm -rf verify-p03-health
```

**Manual Assessment**:
- [ ] Health check interval is appropriate (10-30 seconds)
- [ ] Health check timeout is reasonable (3-10 seconds)
- [ ] Start period accounts for application startup time
- [ ] Health check tests actual application functionality, not just process existence
- [ ] Can explain difference between liveness and readiness probes

**Success Criteria**:
- [ ] Health check properly configured in Dockerfile
- [ ] Container transitions to healthy state after startup
- [ ] Health endpoint provides meaningful status information
- [ ] Demonstrates understanding of health check best practices

---

### Rule 2: Restart Policy Configuration and Testing
**Anchor**: `p03-restart-policies`  
**Type**: Automated

**Automated Test Setup**:
```bash
mkdir -p verify-p03-restart && cd verify-p03-restart

# Create test application with configurable exit behavior
cat > restart-test.py << 'EOF'
import sys
import time
import os
import signal

def signal_handler(signum, frame):
    print(f"Received signal {signum}")
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

exit_code = int(os.environ.get('EXIT_CODE', '0'))
run_time = int(os.environ.get('RUN_TIME', '5'))
exit_after = int(os.environ.get('EXIT_AFTER', run_time))

print(f"Starting application (exit_code={exit_code}, run_time={run_time})")

for i in range(run_time):
    print(f"Working... {i+1}/{run_time}")
    time.sleep(1)
    
    if i >= exit_after - 1:
        print(f"Exiting with code {exit_code}")
        sys.exit(exit_code)

print("Application completed normally")
sys.exit(0)
EOF

cat > Dockerfile.restart << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY restart-test.py .
CMD ["python", "restart-test.py"]
EOF

docker build -f Dockerfile.restart -t restart-test:verify .
```

**Automated Verification**:
```bash
# Test 1: No restart policy - should not restart after failure
echo "=== Testing no restart policy ==="
docker run -d --name no-restart-test \
    --restart no \
    -e EXIT_CODE=1 \
    -e RUN_TIME=3 \
    restart-test:verify

sleep 8
NO_RESTART_STATUS=$(docker inspect no-restart-test | jq -r '.State.Status')
NO_RESTART_COUNT=$(docker inspect no-restart-test | jq '.RestartCount')

if [ "$NO_RESTART_STATUS" = "exited" ] && [ "$NO_RESTART_COUNT" = "0" ]; then
    echo "✅ No restart policy working correctly"
    NO_RESTART_TEST=passed
else
    echo "❌ No restart policy test failed (Status: $NO_RESTART_STATUS, Restarts: $NO_RESTART_COUNT)"
    NO_RESTART_TEST=failed
fi

# Test 2: Always restart - should restart after failure
echo "=== Testing always restart policy ==="
docker run -d --name always-restart-test \
    --restart always \
    -e EXIT_CODE=1 \
    -e RUN_TIME=2 \
    restart-test:verify

sleep 10
ALWAYS_RESTART_COUNT=$(docker inspect always-restart-test | jq '.RestartCount')

if [ "$ALWAYS_RESTART_COUNT" -gt "0" ]; then
    echo "✅ Always restart policy working correctly (Restarts: $ALWAYS_RESTART_COUNT)"
    ALWAYS_RESTART_TEST=passed
else
    echo "❌ Always restart policy test failed (Restarts: $ALWAYS_RESTART_COUNT)"
    ALWAYS_RESTART_TEST=failed
fi

# Test 3: On-failure restart - should restart on failure, not on success
echo "=== Testing on-failure restart policy ==="
# Test failure case
docker run -d --name on-failure-fail-test \
    --restart on-failure:3 \
    -e EXIT_CODE=1 \
    -e RUN_TIME=2 \
    restart-test:verify

sleep 8
FAILURE_RESTART_COUNT=$(docker inspect on-failure-fail-test | jq '.RestartCount')

# Test success case
docker run -d --name on-failure-success-test \
    --restart on-failure:3 \
    -e EXIT_CODE=0 \
    -e RUN_TIME=2 \
    restart-test:verify

sleep 5
SUCCESS_RESTART_COUNT=$(docker inspect on-failure-success-test | jq '.RestartCount')

if [ "$FAILURE_RESTART_COUNT" -gt "0" ] && [ "$SUCCESS_RESTART_COUNT" = "0" ]; then
    echo "✅ On-failure restart policy working correctly"
    echo "   Failure restarts: $FAILURE_RESTART_COUNT, Success restarts: $SUCCESS_RESTART_COUNT"
    ON_FAILURE_TEST=passed
else
    echo "❌ On-failure restart policy test failed"
    echo "   Failure restarts: $FAILURE_RESTART_COUNT, Success restarts: $SUCCESS_RESTART_COUNT"
    ON_FAILURE_TEST=failed
fi

# Test 4: Unless-stopped restart - should restart after failure but not after manual stop
echo "=== Testing unless-stopped restart policy ==="
docker run -d --name unless-stopped-test \
    --restart unless-stopped \
    -e EXIT_CODE=1 \
    -e RUN_TIME=2 \
    restart-test:verify

sleep 8
UNLESS_STOPPED_COUNT=$(docker inspect unless-stopped-test | jq '.RestartCount')

# Manually stop container
docker stop unless-stopped-test

# Try to restart docker daemon simulation (container should not restart)
sleep 3
FINAL_STATUS=$(docker inspect unless-stopped-test | jq -r '.State.Status')

if [ "$UNLESS_STOPPED_COUNT" -gt "0" ] && [ "$FINAL_STATUS" = "exited" ]; then
    echo "✅ Unless-stopped restart policy working correctly"
    UNLESS_STOPPED_TEST=passed
else
    echo "❌ Unless-stopped restart policy test failed"
    UNLESS_STOPPED_TEST=failed
fi

# Cleanup
docker rm -f no-restart-test always-restart-test on-failure-fail-test on-failure-success-test unless-stopped-test
docker image rm restart-test:verify
cd .. && rm -rf verify-p03-restart
```

**Success Criteria**:
- [ ] No restart policy prevents automatic restarts
- [ ] Always restart policy restarts containers after any exit
- [ ] On-failure restart policy only restarts after non-zero exit codes
- [ ] Unless-stopped restart policy respects manual stops

---

### Rule 3: Resource Management and Monitoring
**Anchor**: `p03-resource-management`  
**Type**: Automated Performance Test

**Test Setup**:
```bash
mkdir -p verify-p03-resources && cd verify-p03-resources

# Create resource testing application
cat > resource-app.py << 'EOF'
import time
import threading
import multiprocessing
import os
import sys

def memory_test(target_mb):
    """Test memory allocation up to target"""
    try:
        memory_blocks = []
        for i in range(target_mb):
            block = bytearray(1024 * 1024)  # 1MB
            memory_blocks.append(block)
            if (i + 1) % 10 == 0:
                print(f"Allocated {i + 1}MB")
        
        print(f"Successfully allocated {target_mb}MB")
        time.sleep(10)  # Hold memory
        return True
    except MemoryError:
        print(f"MemoryError at {i}MB")
        return False

def cpu_test(duration):
    """CPU intensive test"""
    start_time = time.time()
    count = 0
    
    while time.time() - start_time < duration:
        count += 1
        
    return count

def main():
    test_type = os.environ.get('TEST_TYPE', 'memory')
    
    if test_type == 'memory':
        target_mb = int(os.environ.get('MEMORY_TARGET', '100'))
        success = memory_test(target_mb)
        sys.exit(0 if success else 1)
        
    elif test_type == 'cpu':
        duration = int(os.environ.get('CPU_DURATION', '10'))
        worker_count = int(os.environ.get('CPU_WORKERS', '4'))
        
        with multiprocessing.Pool(worker_count) as pool:
            results = pool.map(cpu_test, [duration] * worker_count)
            
        total = sum(results)
        print(f"CPU test completed: {total} operations")
        
if __name__ == '__main__':
    main()
EOF

cat > Dockerfile.resources << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY resource-app.py .
CMD ["python", "resource-app.py"]
EOF

docker build -f Dockerfile.resources -t resource-test:verify .
```

**Student Task**: Demonstrate proper resource limit configuration

**Automated Performance Test**:
```bash
# Test 1: Memory limit enforcement
echo "=== Testing memory limit enforcement ==="
# Container with sufficient memory limit
docker run --name mem-sufficient \
    --memory 256m \
    -e TEST_TYPE=memory \
    -e MEMORY_TARGET=128 \
    resource-test:verify

MEM_SUFFICIENT_EXIT=$(docker wait mem-sufficient)
if [ "$MEM_SUFFICIENT_EXIT" = "0" ]; then
    echo "✅ Container runs successfully within memory limit"
    MEMORY_SUFFICIENT=passed
else
    echo "❌ Container failed within memory limit"
    MEMORY_SUFFICIENT=failed
fi

# Container exceeding memory limit
docker run --name mem-exceeded \
    --memory 128m \
    -e TEST_TYPE=memory \
    -e MEMORY_TARGET=256 \
    resource-test:verify

MEM_EXCEEDED_EXIT=$(docker wait mem-exceeded)
if [ "$MEM_EXCEEDED_EXIT" != "0" ]; then
    echo "✅ Container properly terminated when exceeding memory limit"
    MEMORY_LIMIT=passed
else
    echo "❌ Container did not respect memory limit"
    MEMORY_LIMIT=failed
fi

# Test 2: CPU limit effectiveness
echo "=== Testing CPU limit effectiveness ==="
# Unlimited CPU
start_time=$(date +%s)
docker run --name cpu-unlimited \
    -e TEST_TYPE=cpu \
    -e CPU_DURATION=10 \
    -e CPU_WORKERS=2 \
    resource-test:verify >/dev/null 2>&1

unlimited_time=$(($(date +%s) - start_time))

# Limited CPU
start_time=$(date +%s)
docker run --name cpu-limited \
    --cpus="0.5" \
    -e TEST_TYPE=cpu \
    -e CPU_DURATION=10 \
    -e CPU_WORKERS=2 \
    resource-test:verify >/dev/null 2>&1

limited_time=$(($(date +%s) - start_time))

# CPU limited should take longer (allowing for variance)
if [ "$limited_time" -gt "$((unlimited_time + 2))" ] || [ "$limited_time" -gt 15 ]; then
    echo "✅ CPU limits effectively restrict container performance"
    echo "   Unlimited: ${unlimited_time}s, Limited: ${limited_time}s"
    CPU_LIMIT=passed
else
    echo "⚠️  CPU limits may not be effectively restricting performance"
    echo "   Unlimited: ${unlimited_time}s, Limited: ${limited_time}s"
    CPU_LIMIT=warning
fi

# Test 3: Resource monitoring capability
echo "=== Testing resource monitoring ==="
# Run container and capture stats
docker run -d --name resource-monitor \
    --memory 256m \
    --cpus="0.5" \
    -e TEST_TYPE=memory \
    -e MEMORY_TARGET=128 \
    resource-test:verify

sleep 5

# Check if we can get resource stats
MEMORY_USAGE=$(docker stats --no-stream --format "{{.MemUsage}}" resource-monitor 2>/dev/null)
CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" resource-monitor 2>/dev/null)

if [ -n "$MEMORY_USAGE" ] && [ -n "$CPU_USAGE" ]; then
    echo "✅ Resource monitoring working (Memory: $MEMORY_USAGE, CPU: $CPU_USAGE)"
    RESOURCE_MONITOR=passed
else
    echo "❌ Resource monitoring not available"
    RESOURCE_MONITOR=failed
fi

docker wait resource-monitor

# Cleanup
docker rm -f mem-sufficient mem-exceeded cpu-unlimited cpu-limited resource-monitor
docker image rm resource-test:verify
cd .. && rm -rf verify-p03-resources
```

**Success Criteria**:
- [ ] Memory limits prevent containers from using excessive memory
- [ ] CPU limits effectively restrict container CPU usage
- [ ] Resource monitoring provides meaningful usage statistics
- [ ] Containers behave predictably under resource constraints

---

### Rule 4: Signal Handling and Graceful Shutdown
**Anchor**: `p03-signal-handling`  
**Type**: Manual + Automated

**Test Setup**:
```bash
mkdir -p verify-p03-signals && cd verify-p03-signals

# Create test application with signal handling
cat > signal-app.py << 'EOF'
import signal
import sys
import time
import threading
import os

class GracefulApp:
    def __init__(self):
        self.running = True
        self.cleanup_completed = False
        
    def signal_handler(self, signum, frame):
        print(f"Received signal {signum}")
        
        if signum == signal.SIGTERM:
            print("Starting graceful shutdown...")
            self.running = False
            
            # Simulate cleanup work
            cleanup_time = int(os.environ.get('CLEANUP_TIME', '3'))
            print(f"Performing cleanup for {cleanup_time} seconds...")
            time.sleep(cleanup_time)
            
            self.cleanup_completed = True
            print("Graceful shutdown completed")
            sys.exit(0)
            
    def run(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        print("Application starting...")
        
        # Main application loop
        count = 0
        while self.running:
            count += 1
            print(f"Working... {count}")
            time.sleep(1)
            
        print("Application stopped")

if __name__ == '__main__':
    app = GracefulApp()
    app.run()
EOF
```

**Student Task**: Create Dockerfile that properly handles signals

**Automated Verification**:
```bash
# Build test image (student should provide Dockerfile)
if docker build -t signal-test:verify . >/dev/null 2>&1; then
    echo "✅ Signal handling Dockerfile builds successfully"
    SIGNAL_BUILD=passed
else
    echo "❌ Signal handling Dockerfile build failed"
    SIGNAL_BUILD=failed
    exit 1
fi

# Test 1: Normal SIGTERM handling
echo "=== Testing SIGTERM graceful shutdown ==="
docker run -d --name signal-term-test \
    -e CLEANUP_TIME=5 \
    signal-test:verify

sleep 3
echo "Sending SIGTERM..."
start_time=$(date +%s)
docker stop --time 10 signal-term-test
stop_time=$(date +%s)
shutdown_time=$((stop_time - start_time))

# Check if graceful shutdown was performed
if docker logs signal-term-test | grep -q "graceful shutdown completed"; then
    echo "✅ Graceful shutdown completed successfully"
    GRACEFUL_SHUTDOWN=passed
else
    echo "❌ Graceful shutdown not detected in logs"
    GRACEFUL_SHUTDOWN=failed
fi

# Check shutdown timing (should be >= cleanup time but < stop timeout)
if [ "$shutdown_time" -ge 4 ] && [ "$shutdown_time" -le 8 ]; then
    echo "✅ Shutdown timing appropriate (${shutdown_time}s)"
    SHUTDOWN_TIMING=passed
else
    echo "❌ Shutdown timing unexpected (${shutdown_time}s)"
    SHUTDOWN_TIMING=failed
fi

# Test 2: Force kill behavior
echo "=== Testing force kill (SIGKILL) ==="
docker run -d --name signal-kill-test \
    -e CLEANUP_TIME=20 \
    signal-test:verify

sleep 2
echo "Force killing container..."
docker kill signal-kill-test

# Check that cleanup was not completed (killed before finishing)
if docker logs signal-kill-test | grep -q "graceful shutdown completed"; then
    echo "❌ Unexpected: graceful shutdown completed during force kill"
    FORCE_KILL_TEST=failed
else
    echo "✅ Force kill prevented graceful shutdown as expected"
    FORCE_KILL_TEST=passed
fi

# Test 3: CMD vs ENTRYPOINT signal handling
echo "=== Testing signal handling with different CMD forms ==="
# Check Dockerfile format (should use exec form)
if grep -q 'CMD \["python"' Dockerfile* 2>/dev/null; then
    echo "✅ Dockerfile uses exec form for CMD (proper signal handling)"
    CMD_FORM=passed
elif grep -q 'ENTRYPOINT \["python"' Dockerfile* 2>/dev/null; then
    echo "✅ Dockerfile uses exec form for ENTRYPOINT (proper signal handling)"
    CMD_FORM=passed
else
    echo "❌ Dockerfile should use exec form for proper signal handling"
    CMD_FORM=failed
fi

# Cleanup
docker rm -f signal-term-test signal-kill-test
docker image rm signal-test:verify
cd .. && rm -rf verify-p03-signals
```

**Manual Assessment**:
- [ ] Dockerfile uses exec form (CMD ["python", "script.py"] not CMD python script.py)
- [ ] Application registers signal handlers for SIGTERM
- [ ] Graceful shutdown includes proper cleanup (connections, files, etc.)
- [ ] Can explain the difference between SIGTERM and SIGKILL
- [ ] Understands PID 1 signal handling in containers

**Success Criteria**:
- [ ] Container responds to SIGTERM with graceful shutdown
- [ ] Shutdown process completes within reasonable time
- [ ] Application performs proper cleanup before exit
- [ ] Uses exec form for proper signal propagation

---

### Rule 5: Production Operations Integration
**Anchor**: `p03-production-ops`  
**Type**: Comprehensive Manual Assessment

**Integration Scenario**: Student demonstrates complete container operations setup for a production service.

**Assessment Requirements**:

**Service Configuration**:
- [ ] Appropriate health check strategy with meaningful endpoints
- [ ] Correct restart policy for service type and requirements
- [ ] Resource limits set based on application needs and system capacity
- [ ] Proper signal handling for graceful shutdowns

**Operational Excellence**:
- [ ] Health checks test actual application functionality
- [ ] Restart policy prevents cascading failures
- [ ] Resource limits prevent resource starvation
- [ ] Shutdown process completes all necessary cleanup

**Monitoring and Observability**:
- [ ] Container exposes metrics for monitoring systems
- [ ] Logs are structured and meaningful for debugging
- [ ] Resource usage can be tracked and analyzed
- [ ] Failure scenarios are properly detected and handled

**Production Readiness**:
- [ ] Service can handle expected load with configured resources
- [ ] Health checks integrate with load balancers/orchestrators
- [ ] Restart policies support high availability requirements
- [ ] Signal handling ensures data consistency during updates

---

## 🔄 Comprehensive Verification Script

Complete verification sequence for all rules:

```bash
#!/bin/bash
echo "=== Phase 03 Container Operations Verification ==="

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
    elif [ "$test_result" = "warning" ]; then
        echo "⚠️  $test_name: WARNING"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ $test_name: FAILED"
    fi
}

echo "Testing Rule 1: Health Check Strategy..."
# ... (health check tests)

echo "Testing Rule 2: Restart Policies..."
# ... (restart policy tests)

echo "Testing Rule 3: Resource Management..."
# ... (resource management tests)

echo "Testing Rule 4: Signal Handling..."
# ... (signal handling tests)

echo ""
echo "=== Verification Results ==="
echo "Automated Tests: $PASSED_TESTS/$TOTAL_TESTS passed"
echo ""
echo "Manual verification required for:"
echo "- [ ] Health check strategy design and endpoint implementation"
echo "- [ ] Restart policy selection rationale for different service types"
echo "- [ ] Resource limit calculation and monitoring setup"
echo "- [ ] Signal handling implementation with proper cleanup"
echo "- [ ] Production integration and operational excellence"
echo ""
echo "Complete manual assessments to finish Phase 03 verification."
```

## 📋 Manual Verification Checklist

### Container Operations Concepts
- [ ] **Health Strategy**: Designs effective health checks that test application functionality
- [ ] **Restart Management**: Selects appropriate restart policies based on service characteristics
- [ ] **Resource Planning**: Calculates and applies resource limits based on application needs
- [ ] **Signal Processing**: Implements proper signal handlers for graceful shutdowns

### Production Skills
- [ ] **Monitoring Integration**: Configures container monitoring and alerting
- [ ] **Performance Analysis**: Analyzes and optimizes container resource usage
- [ ] **Failure Recovery**: Designs resilient systems with proper restart and health strategies
- [ ] **Operational Debugging**: Troubleshoots container issues using logs and metrics

### Integration Capabilities
- [ ] **Load Balancer Integration**: Health checks work with load balancing systems
- [ ] **Orchestration Ready**: Container operations integrate with orchestrators
- [ ] **CI/CD Integration**: Operations patterns work in automated deployment pipelines
- [ ] **Team Processes**: Designs operations that work for development teams

## 🎯 Success Criteria Summary

**Complete Phase 03 when:**
- [ ] All automated verification tests pass
- [ ] Manual assessment confirms operational expertise
- [ ] Can design and implement production-ready container operations
- [ ] Demonstrates troubleshooting skills for container runtime issues
- [ ] Ready to progress to Docker networking in Phase 04

---

> **Critical Success Indicator**: Can design and implement a complete container operations strategy that ensures reliable, scalable, and maintainable containerized services with appropriate health monitoring, restart policies, resource management, and graceful shutdown handling.