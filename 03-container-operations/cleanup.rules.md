# Phase 03: Container Operations - Cleanup Rules

> **Automated cleanup procedures for container operations testing and resource management**

## 🎯 Cleanup Overview

Phase 03 involves extensive container lifecycle testing including health checks, restart scenarios, resource constraints, and signal handling. Proper cleanup prevents resource accumulation and ensures clean testing environments.

## 🧹 Automated Cleanup Script

Complete cleanup sequence for all Phase 03 activities:

```bash
#!/bin/bash
echo "=== Phase 03: Container Operations Cleanup ==="

# Track cleanup progress
CLEANUP_ITEMS=0
CLEANED_ITEMS=0

cleanup_item() {
    local item_name="$1"
    local cleanup_command="$2"
    CLEANUP_ITEMS=$((CLEANUP_ITEMS + 1))
    
    echo "Cleaning: $item_name..."
    if eval "$cleanup_command" >/dev/null 2>&1; then
        echo "✅ $item_name cleaned successfully"
        CLEANED_ITEMS=$((CLEANED_ITEMS + 1))
    else
        echo "⚠️  $item_name cleanup had issues (may not exist)"
        CLEANED_ITEMS=$((CLEANED_ITEMS + 1))
    fi
}

# 1. Remove lab-specific containers and images
echo "=== Lab Resource Cleanup ==="

# Lab 1: Health check containers
cleanup_item "Health check lab containers" "docker rm -f health-test mysql-health web-always health-demo-run 2>/dev/null"
cleanup_item "Health check lab images" "docker image rm health-demo:v1 health-demo:heavy health-demo:light mysql-health:test 2>/dev/null"

# Lab 2: Restart policy containers
cleanup_item "Restart policy containers" "docker rm -f no-restart always-restart on-failure-restart success-always success-on-failure unless-stopped-test web-always job-processor postgres-prod dev-container 2>/dev/null"
cleanup_item "Restart policy images" "docker image rm fail-test:v1 web-service:restart-test 2>/dev/null"

# Lab 3: Resource management containers
cleanup_item "Resource test containers" "docker rm -f mem-test-ok mem-test-oom mem-test-swap cpu-test-unlimited cpu-test-limited cpu-high-priority cpu-low-priority process-test-limited resource-balanced resource-mem-constrained resource-cpu-constrained 2>/dev/null"
cleanup_item "Resource test images" "docker image rm memory-test:v1 cpu-test:v1 io-test:v1 resource-monitor:v1 2>/dev/null"

# Lab 4: Signal handling containers
cleanup_item "Signal handling containers" "docker rm -f signal-test-normal signal-test-term signal-test-kill web-graceful db-cleanup-test 2>/dev/null"
cleanup_item "Signal handling images" "docker image rm signal-demo:v1 web-shutdown:v1 db-cleanup:v1 2>/dev/null"

# 2. Remove verification test artifacts
echo "=== Verification Cleanup ==="

cleanup_item "Health verification containers" "docker rm -f verify-health-run 2>/dev/null"
cleanup_item "Restart verification containers" "docker rm -f no-restart-test always-restart-test on-failure-fail-test on-failure-success-test unless-stopped-test 2>/dev/null"
cleanup_item "Resource verification containers" "docker rm -f mem-sufficient mem-exceeded cpu-unlimited cpu-limited resource-monitor 2>/dev/null"
cleanup_item "Signal verification containers" "docker rm -f signal-term-test signal-kill-test 2>/dev/null"

cleanup_item "Verification images" "docker image rm verify-health restart-test:verify resource-test:verify signal-test:verify 2>/dev/null"

# 3. Clean up test networks and volumes
echo "=== Network and Volume Cleanup ==="

cleanup_item "Test networks" "docker network rm $(docker network ls -q --filter name=test) 2>/dev/null || docker network prune -f"
cleanup_item "Test volumes" "docker volume rm $(docker volume ls -q --filter name=test) 2>/dev/null || docker volume prune -f"

# 4. Clean temporary directories and files
echo "=== File System Cleanup ==="

cleanup_item "Lab working directories" "rm -rf ~/docker-labs/container-operations 2>/dev/null"
cleanup_item "Verification directories" "rm -rf verify-p03-* 2>/dev/null"
cleanup_item "Test scripts" "find . -name '*-test.py' -o -name '*-test.sh' -type f -delete 2>/dev/null"
cleanup_item "Log files" "find . -name '*.log' -o -name 'test-*.txt' -type f -delete 2>/dev/null"

# 5. Resource constraint cleanup
echo "=== Resource Constraint Cleanup ==="

# Remove any containers that might be stuck in resource-constrained states
cleanup_item "Resource constrained containers" "docker rm -f $(docker ps -aq --filter label=resource-test) 2>/dev/null"

# Clean up any lingering cgroups or limits
cleanup_item "Container resource limits" "docker update --memory=-1 --cpus='' $(docker ps -aq) 2>/dev/null || true"

# 6. Health check cleanup
echo "=== Health Check Cleanup ==="

# Stop any containers with failing health checks
cleanup_item "Unhealthy containers" "docker rm -f $(docker ps -aq --filter health=unhealthy) 2>/dev/null"

# Clean up health check history
cleanup_item "Health check logs" "find /var/lib/docker/containers -name '*-json.log' -exec truncate -s 0 {} \\; 2>/dev/null || true"

# 7. Signal handling cleanup
echo "=== Signal Handling Cleanup ==="

# Kill any containers that might be stuck waiting for signals
cleanup_item "Hanging signal containers" "docker kill $(docker ps -q --filter ancestor=signal-demo) 2>/dev/null"

# Clean up any background processes from signal tests
cleanup_item "Background test processes" "pkill -f 'signal-demo\\|health-demo\\|restart-test' 2>/dev/null || true"

# 8. System-wide Docker cleanup
echo "=== System Cleanup ==="

# Remove dangling images from testing
cleanup_item "Dangling images" "docker image prune -f"

# Clean up stopped containers
cleanup_item "Stopped containers" "docker container prune -f"

# Remove unused networks (created during testing)
cleanup_item "Unused networks" "docker network prune -f"

# 9. Advanced cleanup for persistent issues
echo "=== Advanced Cleanup (if needed) ==="

if [ "$1" = "--aggressive" ]; then
    echo "Running aggressive cleanup..."
    
    cleanup_item "All unused images" "docker image prune --all -f"
    cleanup_item "All unused volumes" "docker volume prune -f"
    cleanup_item "All unused networks" "docker network prune -f"
    cleanup_item "System-wide cleanup" "docker system prune --all -f"
    
    # Reset Docker daemon if needed (requires sudo)
    if [ "$(id -u)" = "0" ]; then
        cleanup_item "Docker daemon restart" "systemctl restart docker"
    else
        echo "⚠️  Skipping Docker daemon restart (requires sudo)"
    fi
fi

# 10. Monitoring and alerting cleanup
echo "=== Monitoring Cleanup ==="

# Stop any monitoring containers started during testing
cleanup_item "Monitoring containers" "docker rm -f cadvisor prometheus grafana node-exporter 2>/dev/null"

# Clean up monitoring configurations
cleanup_item "Monitoring configs" "rm -rf monitoring-config prometheus.yml grafana-data 2>/dev/null"

# Final status report
echo ""
echo "=== Cleanup Summary ==="
echo "Cleaned: $CLEANED_ITEMS/$CLEANUP_ITEMS items"
echo ""

# Verify cleanup effectiveness
echo "=== Post-Cleanup Status ==="
echo "Running containers:"
RUNNING_COUNT=$(docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | grep -v NAMES | wc -l)
echo "  Count: $RUNNING_COUNT"

if [ $RUNNING_COUNT -gt 0 ]; then
    echo "  Details:"
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | head -10
fi

echo ""
echo "Container operations related images:"
OPS_IMAGES=$(docker images | grep -E "(health|restart|resource|signal|test|demo)" | wc -l)
echo "  Count: $OPS_IMAGES"

if [ $OPS_IMAGES -gt 0 ]; then
    echo "  Details:"
    docker images | grep -E "(health|restart|resource|signal|test|demo)" | head -10
fi

echo ""
echo "System resource usage:"
docker system df

echo ""
echo "✅ Phase 03 cleanup completed"
echo ""
echo "💡 Tip: Run with --aggressive flag for thorough cleanup if issues persist"
```

## 🔧 Selective Cleanup Procedures

### Lab-Specific Cleanup

**Health Check Lab**:
```bash
# Remove health check lab resources
docker rm -f $(docker ps -aq --filter name=health) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=health) 2>/dev/null
rm -rf health-check-demo/
find . -name "*health*" -type f -delete 2>/dev/null
```

**Restart Policy Lab**:
```bash
# Clean restart policy testing resources
docker rm -f $(docker ps -aq --filter name=restart) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=restart) 2>/dev/null
rm -f restart-test.py failing-app.py web-service.py
```

**Resource Management Lab**:
```bash
# Remove resource testing containers and reset limits
docker rm -f $(docker ps -aq --filter name=resource) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=mem-) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=cpu-) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=resource) 2>/dev/null

# Reset any lingering resource constraints
docker update --memory=-1 --cpus='' $(docker ps -aq) 2>/dev/null || true

rm -f memory-test.py cpu-test.py io-test.py resource-monitor.py
```

**Signal Handling Lab**:
```bash
# Clean signal handling resources
docker rm -f $(docker ps -aq --filter name=signal) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=signal) 2>/dev/null
pkill -f 'signal-demo' 2>/dev/null || true
rm -f signal-demo.py web-shutdown.py db-cleanup.py
```

### Resource-Specific Cleanup

**Memory Cleanup**:
```bash
# Clean up memory-intensive containers
docker rm -f $(docker ps -aq --filter ancestor=memory-test) 2>/dev/null

# Clear memory caches (Linux)
if [ -f /proc/sys/vm/drop_caches ]; then
    echo "Clearing system memory caches..."
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
fi
```

**CPU Cleanup**:
```bash
# Remove CPU-intensive containers
docker rm -f $(docker ps -aq --filter ancestor=cpu-test) 2>/dev/null

# Reset CPU constraints
for container in $(docker ps -aq); do
    docker update --cpus='' --cpu-shares=-1 $container 2>/dev/null || true
done
```

**Health Check Cleanup**:
```bash
# Remove containers with health checks
docker rm -f $(docker ps -aq --filter health=unhealthy) 2>/dev/null
docker rm -f $(docker ps -aq --filter health=healthy) 2>/dev/null

# Clear health check logs
find /var/lib/docker/containers -name '*health*' -delete 2>/dev/null || true
```

### Verification Cleanup

**Test Artifact Removal**:
```bash
# Remove verification test directories
rm -rf verify-p03-*

# Clean up test images
docker image rm $(docker images -q --filter reference=*verify*) 2>/dev/null

# Remove test networks and volumes
docker network rm $(docker network ls -q --filter name=verify) 2>/dev/null
docker volume rm $(docker volume ls -q --filter name=verify) 2>/dev/null
```

## 🚨 Emergency Cleanup

When standard cleanup fails or system becomes unstable:

```bash
#!/bin/bash
echo "=== EMERGENCY PHASE 03 CLEANUP ==="

# Nuclear option - stop and remove everything
echo "Stopping all running containers..."
docker stop $(docker ps -q) 2>/dev/null

echo "Removing all containers..."
docker rm $(docker ps -aq) 2>/dev/null

# Remove images related to container operations
echo "Removing container operations related images..."
docker image rm $(docker images -q --filter reference='*health*') 2>/dev/null
docker image rm $(docker images -q --filter reference='*restart*') 2>/dev/null
docker image rm $(docker images -q --filter reference='*resource*') 2>/dev/null
docker image rm $(docker images -q --filter reference='*signal*') 2>/dev/null
docker image rm $(docker images -q --filter reference='*test*') 2>/dev/null

# System-wide cleanup
echo "Performing system-wide cleanup..."
docker system prune --all --volumes -f

# Reset Docker daemon (if running as root)
if [ "$(id -u)" = "0" ]; then
    echo "Restarting Docker daemon..."
    systemctl restart docker
    echo "Waiting for Docker daemon to be ready..."
    sleep 10
fi

echo "Emergency cleanup completed. System reset."
```

## 📋 Pre-Lab Cleanup Checklist

Run before starting any Phase 03 lab:

- [ ] `docker ps` shows no Phase 03 related containers
- [ ] `docker images` shows no old test images
- [ ] Available system resources: memory >2GB, CPU not throttled
- [ ] No background processes from previous tests running
- [ ] Working directory is clean of test artifacts

## 📊 Post-Lab Verification

After each lab completion:

```bash
# Quick verification of cleanup effectiveness
echo "=== Resource Check ==="
echo "Running containers: $(docker ps -q | wc -l)"
echo "Container operations images: $(docker images | grep -E '(health|restart|resource|signal|test)' | wc -l)"
echo "System resource usage:"
docker system df

echo ""
echo "=== Memory and CPU Check ==="
echo "Available memory: $(free -h | grep '^Mem:' | awk '{print $7}')"
echo "CPU load: $(uptime | awk -F'load average:' '{print $2}' | xargs)"

echo ""
echo "=== Process Check ==="
echo "Docker-related processes: $(ps aux | grep -E 'docker|container' | grep -v grep | wc -l)"
echo "Test-related processes: $(ps aux | grep -E 'test|demo|health|signal' | grep -v grep | wc -l)"
```

## ⚠️ Cleanup Warnings

**Health Check Considerations**:
- Health check failures may leave containers in unhealthy state
- Some health check logs persist in Docker daemon
- Health check intervals may cause delayed cleanup

**Restart Policy Cautions**:
- `always` restart policy containers will restart after cleanup attempts
- Change restart policy to `no` before cleanup if needed
- Manual stop required for `unless-stopped` containers

**Resource Management Notes**:
- Memory limits may cause OOM kills during cleanup
- CPU constraints can slow down cleanup operations
- Resource monitoring processes may need explicit termination

**Signal Handling Warnings**:
- Some containers may not respond to SIGTERM immediately
- Force kill (SIGKILL) may be necessary for stuck containers
- Background processes started during signal tests need manual cleanup

## 🔄 Automated Cleanup Integration

**Makefile Integration**:
```makefile
# Add to project Makefile
.PHONY: clean-phase03
clean-phase03:
	@echo "Cleaning up Phase 03 resources..."
	@bash 03-container-operations/cleanup.sh

.PHONY: clean-phase03-aggressive
clean-phase03-aggressive:
	@echo "Aggressive cleanup of Phase 03 resources..."
	@bash 03-container-operations/cleanup.sh --aggressive
```

**Git Hook Integration**:
```bash
# Add to .git/hooks/pre-commit
if [ -d "03-container-operations" ]; then
    echo "Running Phase 03 cleanup before commit..."
    bash 03-container-operations/cleanup.sh --conservative
fi
```

**VS Code Task**:
```json
{
    "label": "Phase 03 Cleanup",
    "type": "shell",
    "command": "bash",
    "args": ["03-container-operations/cleanup.sh"],
    "group": "build",
    "problemMatcher": []
}
```

## 📈 Cleanup Monitoring

Track cleanup effectiveness over time:

```bash
# Create cleanup log entry
echo "$(date): Phase 03 cleanup completed" >> ~/.docker-learning-cleanup.log
echo "  - Containers cleaned: $(docker ps -a | wc -l)" >> ~/.docker-learning-cleanup.log
echo "  - Images cleaned: $(docker images | wc -l)" >> ~/.docker-learning-cleanup.log
echo "  - System disk usage: $(docker system df | grep 'Total' | awk '{print $4}')" >> ~/.docker-learning-cleanup.log
echo "  - Available memory: $(free -h | grep '^Mem:' | awk '{print $7}')" >> ~/.docker-learning-cleanup.log
```

## 🔍 Troubleshooting Cleanup Issues

**Common Problems and Solutions**:

1. **Containers won't stop**:
   ```bash
   # Force kill stuck containers
   docker kill $(docker ps -q)
   
   # If still stuck, restart Docker daemon
   sudo systemctl restart docker
   ```

2. **Images won't delete**:
   ```bash
   # Remove containers using the images first
   docker rm $(docker ps -aq)
   
   # Force remove images
   docker image rm -f $(docker images -q)
   ```

3. **Resource constraints preventing cleanup**:
   ```bash
   # Reset all resource constraints
   for container in $(docker ps -aq); do
       docker update --memory=-1 --cpus='' $container 2>/dev/null || true
   done
   ```

4. **Health checks preventing container removal**:
   ```bash
   # Disable health checks temporarily
   docker update --health-cmd='' --health-interval=0s $(docker ps -aq) 2>/dev/null || true
   ```

---

> 💡 **Cleanup Philosophy**: Phase 03 tests critical container operations that can leave persistent state. Thorough cleanup ensures reliable testing environments and prevents resource leaks that could impact system performance or subsequent testing phases.