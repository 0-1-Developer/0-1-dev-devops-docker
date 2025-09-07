# Phase 05: Storage & Volumes - Cleanup Rules

> **Automated cleanup procedures for Docker storage resources and data management artifacts**

## 🎯 Cleanup Overview

Phase 05 involves extensive storage and volume testing including different volume types, backup procedures, permission management, and performance optimization. Proper cleanup prevents storage bloat, data leakage, and ensures clean testing environments for subsequent phases.

## 🧹 Automated Cleanup Script

Complete cleanup sequence for all Phase 05 activities:

```bash
#!/bin/bash
echo "=== Phase 05: Storage & Volumes Cleanup ==="

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

# Lab 1: Volume types containers
cleanup_item "Volume types test containers" "docker rm -f named-test bind-test tmpfs-test postgres-v13 postgres-v14 data-producer data-consumer data-monitor 2>/dev/null"

# Lab 2: Backup and restore containers
cleanup_item "Backup test containers" "docker rm -f backup-demo disaster-test secure-db 2>/dev/null"

# Lab 3: Permission test containers
cleanup_item "Permission test containers" "docker rm -f secure-app cache-test perf-db 2>/dev/null"

# Lab 4: Performance test containers
cleanup_item "Performance test containers" "docker rm -f perf-db monitored-app 2>/dev/null"

# Remove storage test images
cleanup_item "Storage test images" "docker image rm storage-test:v1 alpine-with-user secure-app network-test:v1 2>/dev/null"

# 2. Remove lab-specific volumes
echo "=== Volume Cleanup ==="

# Lab volumes
cleanup_item "Lab 1 volumes" "docker volume rm lab-named-volume postgres-data shared-data backup-demo disaster-test 2>/dev/null"
cleanup_item "Lab 2 volumes" "docker volume rm backup-demo disaster-test-backup 2>/dev/null"
cleanup_item "Lab 3 volumes" "docker volume rm permission-test readonly-config secure-db-data 2>/dev/null"
cleanup_item "Lab 4 volumes" "docker volume rm perf-test-named db-optimized log-optimized app-cache 2>/dev/null"

# Verification volumes
cleanup_item "Verification volumes" "docker volume rm app-persistent-data backup-test-vol backup-restore-test perf-named-vol 2>/dev/null"

# Remove all custom volumes (comprehensive)
cleanup_item "All custom volumes" "docker volume ls -q | grep -E 'lab-|test-|perf-|backup-|demo-|secure-|optimized' | xargs -r docker volume rm 2>/dev/null"

# 3. Remove bind mount directories and temporary files
echo "=== File System Cleanup ==="

cleanup_item "Bind mount test directories" "rm -rf bind-mount-data permission-test perf-test-bind perf-bind-mount test-bind-mount 2>/dev/null"
cleanup_item "Lab working directories" "rm -rf ~/docker-labs/storage verify-p05-* 2>/dev/null"
cleanup_item "Backup directories" "rm -rf backups backup automated-backups disaster-backups 2>/dev/null"

# Remove performance test files
cleanup_item "Performance test files" "rm -f perf_*.log monitor-volumes.sh perf-monitor.sh storage-alerts.sh 2>/dev/null"
cleanup_item "Backup scripts" "rm -f backup-script.sh automated-backup.sh restore-volume.sh 2>/dev/null"

# Remove temporary configuration files
cleanup_item "Temporary config files" "rm -f test-app.js Dockerfile Dockerfile.user Dockerfile.secure 2>/dev/null"

# 4. Clean up test data and artifacts
echo "=== Test Artifact Cleanup ==="

cleanup_item "Docker build context" "rm -rf docker-build-* temp-build-* 2>/dev/null"
cleanup_item "Volume inspection logs" "rm -f volume-*.json volume-inspect-*.log 2>/dev/null"
cleanup_item "Storage benchmark results" "rm -f benchmark-*.txt storage-perf-*.log 2>/dev/null"

# Clean up permission test artifacts
cleanup_item "Permission test files" "find . -name '*-file.txt' -o -name 'solution*.txt' -delete 2>/dev/null"
cleanup_item "Test ownership artifacts" "find . -name 'host-file.*' -o -name 'container-file.*' -delete 2>/dev/null"

# 5. Advanced storage cleanup
echo "=== Advanced Storage Cleanup ==="

# Clean up orphaned volumes
cleanup_item "Orphaned volumes" "docker volume ls -qf dangling=true | xargs -r docker volume rm 2>/dev/null"

# Clean up unused images from storage tests
cleanup_item "Unused storage images" "docker image prune -f --filter label=storage-test 2>/dev/null"

# Clean up build cache from storage tests
cleanup_item "Build cache cleanup" "docker builder prune -f 2>/dev/null"

# 6. System storage cleanup
echo "=== System Storage Cleanup ==="

# Remove container layers and metadata
cleanup_item "Container storage cleanup" "docker container prune -f"

# Clean up image layers if safe
if [ "$1" = "--aggressive" ]; then
    cleanup_item "Aggressive image cleanup" "docker image prune -a -f"
    cleanup_item "System-wide storage cleanup" "docker system prune -a -f --volumes"
fi

# Clean up Docker build cache
cleanup_item "Docker build cache" "docker builder prune -f --all 2>/dev/null"

# 7. Permission and security cleanup
echo "=== Security Cleanup ==="

# Reset any test file permissions
cleanup_item "Test file permissions" "find . -name '*test*' -exec chmod 644 {} \\; 2>/dev/null"

# Clean up any test users/groups created during labs
cleanup_item "Test user artifacts" "rm -f /tmp/passwd-test /tmp/group-test 2>/dev/null"

# Remove any temporary mount points
cleanup_item "Temporary mount points" "umount /tmp/docker-test-* 2>/dev/null || true"

# 8. Monitoring and logging cleanup
echo "=== Monitoring Cleanup ==="

cleanup_item "Storage monitoring logs" "rm -f ~/.docker-storage-*.log /tmp/storage-monitor-*.log 2>/dev/null"
cleanup_item "Volume health check logs" "rm -f volume-health-*.log storage-health-*.txt 2>/dev/null"
cleanup_item "Performance monitoring data" "rm -f perf-data-*.csv storage-metrics-*.json 2>/dev/null"

# Clean up any cron job artifacts
cleanup_item "Backup cron artifacts" "rm -f /tmp/backup-*.lock backup-job-*.log 2>/dev/null"

# 9. Development and testing artifacts
echo "=== Development Artifact Cleanup ==="

cleanup_item "Test application files" "rm -f test-app.* sample-app.* demo-app.* 2>/dev/null"
cleanup_item "Temporary Dockerfiles" "rm -f Dockerfile.* dockerfile-* *.dockerfile 2>/dev/null"
cleanup_item "Docker compose test files" "rm -f docker-compose-test.yml compose-storage-test.yml 2>/dev/null"

# Clean up node modules or other package artifacts
cleanup_item "Package artifacts" "rm -rf node_modules package-lock.json yarn.lock 2>/dev/null"

# 10. Verification and cleanup validation
echo "=== Cleanup Validation ==="

# Verify volume cleanup
cleanup_item "Volume cleanup verification" "docker volume ls -q | grep -E 'test|lab|demo|backup' | wc -l | xargs -I {} test {} -eq 0"

# Verify container cleanup
cleanup_item "Container cleanup verification" "docker ps -a -q --filter name=test --filter name=lab --filter name=demo | wc -l | xargs -I {} test {} -eq 0"

# Final status report
echo ""
echo "=== Cleanup Summary ==="
echo "Cleaned: $CLEANED_ITEMS/$CLEANUP_ITEMS items"
echo ""

# Verify cleanup effectiveness
echo "=== Post-Cleanup Status ==="
echo "Custom volumes remaining:"
CUSTOM_VOLUMES=$(docker volume ls -q | grep -E 'test|lab|demo|backup' | wc -l)
echo "  Count: $CUSTOM_VOLUMES"

if [ $CUSTOM_VOLUMES -gt 0 ]; then
    echo "  Remaining volumes:"
    docker volume ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}' | grep -E 'test|lab|demo|backup' | head -5
fi

echo ""
echo "Running containers with storage mounts:"
STORAGE_CONTAINERS=$(docker ps -q --filter volume 2>/dev/null | wc -l)
echo "  Count: $STORAGE_CONTAINERS"

if [ $STORAGE_CONTAINERS -gt 0 ]; then
    echo "  Active containers with volumes:"
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Mounts}}' | grep -v "MOUNTS" | head -5
fi

echo ""
echo "Storage usage overview:"
docker system df

echo ""
echo "✅ Phase 05 storage cleanup completed"
echo ""
echo "💡 Tips:"
echo "  - Run with --aggressive for thorough system cleanup"
echo "  - Check disk usage after cleanup: df -h"
echo "  - Monitor Docker storage: docker system df -v"
echo "  - Regular cleanup prevents storage bloat"
```

## 🔧 Selective Cleanup Procedures

### Lab-Specific Cleanup

**Volume Types Lab**:
```bash
# Remove volume type test resources
docker rm -f $(docker ps -aq --filter name=named-test) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=bind-test) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=tmpfs-test) 2>/dev/null
docker volume rm lab-named-volume postgres-data shared-data 2>/dev/null
rm -rf bind-mount-data
```

**Backup and Restore Lab**:
```bash
# Clean backup test resources
docker rm -f $(docker ps -aq --filter name=backup) 2>/dev/null
docker volume rm backup-demo disaster-test backup-restore-test 2>/dev/null
rm -rf backups backup automated-backups
rm -f backup-script.sh automated-backup.sh restore-volume.sh
```

**Permission Management Lab**:
```bash
# Remove permission test resources
docker rm -f $(docker ps -aq --filter name=permission) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=secure) 2>/dev/null
docker volume rm permission-test readonly-config secure-db-data 2>/dev/null
docker image rm alpine-with-user secure-app 2>/dev/null
rm -rf permission-test
rm -f Dockerfile.user Dockerfile.secure
```

**Performance Optimization Lab**:
```bash
# Clean performance test resources
docker rm -f $(docker ps -aq --filter name=perf) 2>/dev/null
docker volume rm perf-test-named db-optimized log-optimized 2>/dev/null
rm -rf perf-test-bind perf-bind-mount
rm -f perf_*.log monitor-volumes.sh perf-monitor.sh storage-alerts.sh
```

### Volume-Specific Cleanup

**Named Volumes**:
```bash
# Remove all test-related named volumes
docker volume ls --format '{{.Name}}' | grep -E 'test|lab|demo|backup|perf' | \
while read volume; do
    echo "Removing volume: $volume"
    docker volume rm $volume 2>/dev/null || true
done
```

**Orphaned Volume Cleanup**:
```bash
# Find and remove orphaned volumes
echo "=== Orphaned Volume Cleanup ==="
for volume in $(docker volume ls -q); do
    USED_BY=$(docker ps -a --filter volume=$volume --format '{{.Names}}' | wc -l)
    if [ $USED_BY -eq 0 ]; then
        echo "Removing orphaned volume: $volume"
        docker volume rm $volume 2>/dev/null || true
    fi
done
```

**Bind Mount Cleanup**:
```bash
# Remove bind mount directories created during testing
find . -maxdepth 2 -type d -name '*bind*' -o -name '*mount*' -o -name '*test*' | \
while read dir; do
    if [ -d "$dir" ]; then
        echo "Removing bind mount directory: $dir"
        rm -rf "$dir"
    fi
done
```

### Security Cleanup

**Permission Reset**:
```bash
# Reset file permissions for any test files
find . -name '*test*' -o -name '*lab*' -o -name '*demo*' | \
while read file; do
    if [ -f "$file" ]; then
        chmod 644 "$file" 2>/dev/null || true
    fi
done

# Remove any files created with wrong permissions
find . -user root -name '*container*' -delete 2>/dev/null || true
```

**Security Artifact Cleanup**:
```bash
# Remove security test artifacts
rm -f /tmp/secret-* /tmp/token-* 2>/dev/null
rm -f ~/.docker-test-* ~/.storage-test-* 2>/dev/null

# Clean up any test certificates or keys
find . -name '*.pem' -o -name '*.key' -o -name '*.crt' | \
grep -E 'test|demo|lab' | xargs rm -f 2>/dev/null
```

### Performance Cleanup

**Benchmark Data Cleanup**:
```bash
# Remove performance test data
rm -f benchmark-*.txt perf-*.log storage-*.csv
rm -f iotest-* disktest-* performance-*.json

# Clean up large test files
find . -size +10M -name '*test*' -delete 2>/dev/null
find . -size +10M -name '*perf*' -delete 2>/dev/null
```

**Monitoring Cleanup**:
```bash
# Remove monitoring scripts and logs
rm -f monitor-*.sh alert-*.sh check-*.sh
rm -f storage-monitor-*.log volume-health-*.log
rm -rf monitoring-data performance-data
```

## 🚨 Emergency Storage Cleanup

When standard cleanup fails or storage space is critically low:

```bash
#!/bin/bash
echo "=== EMERGENCY PHASE 05 STORAGE CLEANUP ==="

echo "WARNING: This will remove ALL Docker storage including production data!"
read -p "Continue with emergency cleanup? (y/N): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Stop all containers
docker stop $(docker ps -q) 2>/dev/null

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null

# Remove all volumes (DANGEROUS)
docker volume rm $(docker volume ls -q) 2>/dev/null

# Remove all images
docker image rm $(docker image ls -q) 2>/dev/null

# Clean all system storage
docker system prune -a -f --volumes

# Clean build cache
docker builder prune -a -f

# Remove all Docker networks
docker network rm $(docker network ls -q) 2>/dev/null || true

# Reset to default networks
docker network create bridge 2>/dev/null || true

echo "Emergency storage cleanup completed."
echo "WARNING: All Docker data has been removed!"
```

## 📋 Pre-Lab Cleanup Checklist

Run before starting any Phase 05 lab:

- [ ] No test volumes exist (`docker volume ls`)
- [ ] No containers using test volumes
- [ ] Working directory is clean of test files
- [ ] No orphaned bind mount directories
- [ ] Sufficient disk space available (`df -h`)

## 📊 Post-Lab Verification

After each lab completion:

```bash
# Quick verification of storage cleanup
echo "=== Storage Cleanup Check ==="
echo "Test volumes: $(docker volume ls -q | grep -E 'test|lab|demo' | wc -l)"
echo "Running containers: $(docker ps -q | wc -l)"
echo "Orphaned volumes: $(docker volume ls -qf dangling=true | wc -l)"

echo ""
echo "=== Storage Health Check ==="
echo "Total volumes: $(docker volume ls -q | wc -l)"
echo "System storage usage:"
docker system df

echo ""
echo "=== Disk Space Check ==="
df -h . | tail -1 | awk '{print "Available: " $4 " (" $5 " used)"}'

echo ""
echo "=== Volume Health Status ==="
for volume in $(docker volume ls -q | head -5); do
    SIZE=$(docker run --rm -v $volume:/check alpine du -sh /check 2>/dev/null | cut -f1 || echo "N/A")
    echo "$volume: $SIZE"
done
```

## ⚠️ Cleanup Warnings

**Volume Dependencies**:
- Volumes may be in use by stopped containers
- Some volumes may have external dependencies
- Named volumes require explicit removal

**Data Safety**:
- Always backup important data before cleanup
- Test cleanup procedures in non-production environments
- Verify cleanup results before proceeding to next phase

**Permission Issues**:
- Some files may require sudo for cleanup
- Bind mount directories may have permission restrictions
- Container-created files may be owned by root

**System Integration**:
- Docker may recreate default volumes automatically
- System containers may interfere with cleanup
- Host filesystem mounts need careful handling

## 🔄 Automated Cleanup Integration

**Pre-commit Hook**:
```bash
# Add to .git/hooks/pre-commit
if [ -d "05-storage" ]; then
    echo "Running Phase 05 storage cleanup before commit..."
    bash 05-storage/cleanup.sh --conservative
fi
```

**Makefile Integration**:
```makefile
# Add to project Makefile
.PHONY: clean-storage
clean-storage:
	@echo "Cleaning up Phase 05 storage resources..."
	@bash 05-storage/cleanup.sh

.PHONY: clean-storage-aggressive  
clean-storage-aggressive:
	@echo "Aggressive cleanup of all storage resources..."
	@bash 05-storage/cleanup.sh --aggressive
```

**Cron Job for Regular Cleanup**:
```bash
# Add to crontab for regular storage cleanup
# Run every day at 3 AM
0 3 * * * /path/to/docker/05-storage/cleanup.sh >/dev/null 2>&1
```

## 📈 Cleanup Monitoring

Track cleanup effectiveness and storage health:

```bash
# Create storage cleanup log
echo "$(date): Phase 05 storage cleanup completed" >> ~/.docker-storage-cleanup.log
echo "  - Volumes removed: $(docker volume ls -q | wc -l)" >> ~/.docker-storage-cleanup.log
echo "  - Containers cleaned: $(docker ps -a | wc -l)" >> ~/.docker-storage-cleanup.log
echo "  - Disk space freed: $(df -h . | tail -1 | awk '{print $4}')" >> ~/.docker-storage-cleanup.log
echo "  - Storage efficiency: $(docker system df | tail -1)" >> ~/.docker-storage-cleanup.log
```

## 🔍 Troubleshooting Cleanup Issues

**Common Problems and Solutions**:

1. **Volume in use error**:
   ```bash
   # Find containers using the volume
   docker ps -a --filter volume=volume_name
   
   # Remove containers first
   docker rm -f container_name
   docker volume rm volume_name
   ```

2. **Permission denied on bind mounts**:
   ```bash
   # Check file ownership
   ls -la bind-mount-directory/
   
   # Fix permissions or use sudo
   sudo rm -rf bind-mount-directory/
   ```

3. **Cannot remove volume: volume is in use**:
   ```bash
   # Force remove all containers using volume
   docker rm -f $(docker ps -aq --filter volume=volume_name)
   docker volume rm volume_name
   ```

4. **Disk space not freed after cleanup**:
   ```bash
   # Force system cleanup
   docker system prune -a -f --volumes
   
   # Clear build cache
   docker builder prune -a -f
   ```

---

> 💡 **Cleanup Philosophy**: Phase 05 storage creates persistent data and volume resources that can accumulate quickly. Thorough cleanup prevents storage bloat, ensures consistent test environments, and maintains system performance essential for reliable storage management testing.