# Phase 02: BuildKit Advanced - Cleanup Rules

> **Automated cleanup procedures for BuildKit advanced features and resource management**

## 🎯 Cleanup Overview

Phase 02 introduces complex build scenarios with multiple stages, persistent cache mounts, build secrets, and parameterized builds. Proper cleanup is essential to prevent resource accumulation, security leaks, and storage bloat.

## 🧹 Automated Cleanup Script

Complete cleanup sequence for all Phase 02 activities:

```bash
#!/bin/bash
echo "=== Phase 02: BuildKit Advanced Cleanup ==="

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

# Lab 1: Multi-stage builds
cleanup_item "Multi-stage lab containers" "docker rm -f multistage-demo backend-build frontend-build 2>/dev/null"
cleanup_item "Multi-stage lab images" "docker image rm myapp-single myapp-multi node-backend go-backend vue-frontend nginx-frontend 2>/dev/null"

# Lab 2: Cache mount optimization  
cleanup_item "Cache lab containers" "docker rm -f cache-demo-cold cache-demo-warm cache-test-npm cache-test-pip 2>/dev/null"
cleanup_item "Cache lab images" "docker image rm cache-demo:v1 cache-demo:v2 cache-test-node cache-test-python 2>/dev/null"

# Lab 3: Build secrets
cleanup_item "Secret lab containers" "docker rm -f secret-demo secret-test-ssh secret-test-api 2>/dev/null"
cleanup_item "Secret lab images" "docker image rm secret-demo secure-app:v1 secure-app:v2 2>/dev/null"

# Lab 4: Build arguments
cleanup_item "Build args lab containers" "docker rm -f buildargs-demo args-test-dev args-test-prod 2>/dev/null"
cleanup_item "Build args lab images" "docker image rm buildargs-demo:dev buildargs-demo:prod configurable-app:latest 2>/dev/null"

# 2. Clear BuildKit-specific resources
echo "=== BuildKit Resource Cleanup ==="

# Cache mounts cleanup (aggressive)
cleanup_item "BuildKit cache volumes" "docker builder prune --filter type=exec.cachemount --force"
cleanup_item "Build cache (non-aggressive)" "docker builder prune --filter type=regular --force"

# Clear any dangling build contexts
cleanup_item "Dangling build contexts" "docker system prune --filter label=phase=02 --force"

# 3. Remove verification test artifacts
echo "=== Verification Cleanup ==="

cleanup_item "Multistage verify containers" "docker rm -f verify-multistage-run 2>/dev/null"
cleanup_item "Multistage verify images" "docker image rm verify-multistage 2>/dev/null"

cleanup_item "Cache verify containers" "docker rm -f cache-verify-test 2>/dev/null" 
cleanup_item "Cache verify images" "docker image rm cache-verify-none cache-verify-cached 2>/dev/null"

cleanup_item "Secret verify images" "docker image rm secret-verify 2>/dev/null"

cleanup_item "Build args verify images" "docker image rm buildargs-default buildargs-custom buildargs-invalid 2>/dev/null"

# 4. Clean temporary directories and files
echo "=== File System Cleanup ==="

# Remove any lab working directories
cleanup_item "Lab working directories" "rm -rf ~/docker-labs/phase02-* 2>/dev/null"
cleanup_item "Temp verification dirs" "rm -rf verify-p02-* 2>/dev/null"
cleanup_item "Cache test directories" "rm -rf cache-verify verify-cache-test 2>/dev/null"

# Remove any accidentally created secret files
cleanup_item "Test secret files" "find . -name '*.secret' -o -name 'test-secret*' -type f -delete 2>/dev/null"
cleanup_item "Build artifact files" "find . -name '*.log' -o -name 'build-*.txt' -type f -delete 2>/dev/null"

# 5. Advanced cleanup for persistent issues
echo "=== Advanced Cleanup (if needed) ==="

# Only run if standard cleanup isn't sufficient
if [ "$1" = "--aggressive" ]; then
    echo "Running aggressive cleanup..."
    
    cleanup_item "All unused build cache" "docker builder prune --all --force"
    cleanup_item "All unused images" "docker image prune --all --force"
    cleanup_item "All unused containers" "docker container prune --force"
    cleanup_item "All unused volumes" "docker volume prune --force"
    cleanup_item "All unused networks" "docker network prune --force"
    
    # Reset BuildKit (nuclear option)
    cleanup_item "Reset BuildKit builder" "docker buildx rm --all-inactive 2>/dev/null || true"
    cleanup_item "Create new builder" "docker buildx create --use --name phase02-builder 2>/dev/null || true"
fi

# 6. Security cleanup
echo "=== Security Cleanup ==="

# Ensure no secrets in environment
cleanup_item "Environment secrets" "unset DOCKER_BUILDKIT_SECRET API_KEY SSH_PRIVATE_KEY 2>/dev/null || true"

# Clear any potentially leaked secrets in build history
cleanup_item "Build history cleanup" "docker system events --filter type=image --filter action=delete --since 1h 2>/dev/null || true"

# Final status report
echo ""
echo "=== Cleanup Summary ==="
echo "Cleaned: $CLEANED_ITEMS/$CLEANUP_ITEMS items"
echo ""

# Verify cleanup effectiveness
echo "=== Post-Cleanup Status ==="
echo "Images remaining with 'phase02' or similar tags:"
docker images | grep -E "(multistage|cache|secret|buildargs|verify)" | wc -l || echo "0"

echo "Containers with Phase 02 names:"
docker ps -a | grep -E "(multistage|cache|secret|buildargs|verify)" | wc -l || echo "0"

echo "Build cache size:"
docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}" | grep -E "(Build Cache)" || echo "Build Cache: 0 0B"

echo ""
echo "✅ Phase 02 cleanup completed"
echo ""
echo "💡 Tip: Run with --aggressive flag for thorough cleanup if issues persist"
```

## 🔧 Selective Cleanup Procedures

### Lab-Specific Cleanup

**Multi-Stage Build Lab**:
```bash
# Remove multi-stage lab resources
docker rm -f $(docker ps -aq --filter name=multistage) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=multistage) 2>/dev/null
rm -rf ~/docker-labs/multistage-*
```

**Cache Mount Lab**:
```bash
# Clear cache lab resources and persistent cache
docker rm -f $(docker ps -aq --filter name=cache) 2>/dev/null  
docker image rm $(docker images -q --filter label=lab=cache) 2>/dev/null
docker builder prune --filter type=exec.cachemount --force
```

**Build Secrets Lab**:
```bash  
# Remove secret lab resources (security-focused)
docker rm -f $(docker ps -aq --filter name=secret) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=secrets) 2>/dev/null
find . -name "test-secret*" -delete
unset API_KEY SSH_PRIVATE_KEY 2>/dev/null
```

**Build Arguments Lab**:
```bash
# Clean build args lab resources
docker rm -f $(docker ps -aq --filter name=buildargs) 2>/dev/null
docker image rm $(docker images -q --filter label=lab=buildargs) 2>/dev/null  
rm -f build-config-*.txt
```

### Cache Management

**Conservative Cache Cleanup** (keeps recent cache):
```bash
# Remove only old cache entries (>7 days)
docker builder prune --filter until=168h --force
```

**Aggressive Cache Cleanup** (removes all cache):
```bash
# Nuclear option - removes all build cache
docker builder prune --all --force
docker buildx prune --all --force
```

### Secret Security Cleanup

**Environment Cleanup**:
```bash  
# Clear any secret-related environment variables
env | grep -E "(SECRET|KEY|TOKEN)" | cut -d= -f1 | xargs -I {} unset {} 2>/dev/null
```

**File System Secret Sweep**:
```bash
# Find and remove any accidentally created secret files
find . -type f \( -name "*.key" -o -name "*.pem" -o -name "*secret*" \) -not -path "./.git/*" -delete
```

## 🚨 Emergency Cleanup

When cleanup script fails or system becomes unstable:

```bash
#!/bin/bash  
echo "=== EMERGENCY PHASE 02 CLEANUP ==="

# Stop all containers
docker stop $(docker ps -q) 2>/dev/null

# Remove all containers  
docker rm $(docker ps -aq) 2>/dev/null

# Remove all images (DANGEROUS - removes everything)
read -p "WARNING: This removes ALL Docker images. Continue? (y/N): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker image rm $(docker images -q) --force 2>/dev/null
fi

# Nuclear BuildKit reset
docker buildx rm --all-inactive 2>/dev/null
docker builder prune --all --force 2>/dev/null

# System-wide cleanup
docker system prune --all --volumes --force

echo "Emergency cleanup completed. System reset."
```

## 📋 Pre-Lab Cleanup Checklist

Run before starting any Phase 02 lab:

- [ ] `docker ps -a` shows no Phase 02 containers  
- [ ] `docker images` shows no old Phase 02 images
- [ ] Available disk space > 5GB
- [ ] No environment variables with secrets set
- [ ] Working directory is clean of previous artifacts

## 📊 Post-Lab Verification  

After each lab completion:

```bash
# Quick verification of resource cleanup
echo "=== Resource Check ==="
echo "Running containers: $(docker ps --format 'table {{.Names}}\t{{.Image}}' | grep -E '(multistage|cache|secret|buildargs)' | wc -l)"
echo "Lab images: $(docker images | grep -E '(demo|test|verify)' | wc -l)"  
echo "Build cache size: $(docker system df | grep 'Build Cache' | awk '{print $3}')"
echo ""

# Security check for secrets
echo "=== Security Check ==="
echo "Environment secrets: $(env | grep -E '(SECRET|KEY|TOKEN)' | grep -v 'PATH\|HOME' | wc -l)"
echo "Secret files: $(find . -name '*secret*' -o -name '*.key' 2>/dev/null | wc -l)"
```

## ⚠️ Cleanup Warnings

**Cache Mount Considerations**:
- Cache mounts persist between builds intentionally
- Only clear cache when troubleshooting performance issues
- Cache cleanup affects all projects using same cache paths

**Secret Handling**:  
- Always verify no secrets remain in filesystem after labs
- Check for accidentally committed secrets before git operations
- Unset environment variables containing sensitive data

**Multi-Stage Build Cleanup**:
- Intermediate build stages may be cached automatically  
- Use `docker image prune` to remove dangling intermediate images
- Large builder images may need manual removal

## 🔄 Automated Cleanup Integration

**Git Hook Integration**:
```bash
# Add to .git/hooks/pre-commit
if [ -f "02-buildkit-advanced/cleanup.rules.md" ]; then
    echo "Running Phase 02 cleanup before commit..."
    bash 02-buildkit-advanced/cleanup.sh --conservative
fi
```

**VS Code Task**:
```json
{
    "label": "Phase 02 Cleanup",
    "type": "shell", 
    "command": "bash",
    "args": ["02-buildkit-advanced/cleanup.sh"],
    "group": "build",
    "problemMatcher": []
}
```

## 📈 Cleanup Monitoring

Track cleanup effectiveness over time:

```bash
# Create cleanup log
echo "$(date): Phase 02 cleanup completed" >> ~/.docker-learning-cleanup.log
echo "  - Images cleaned: $(docker images | grep -E '(demo|test)' | wc -l)" >> ~/.docker-learning-cleanup.log  
echo "  - Cache size: $(docker system df | grep 'Build Cache' | awk '{print $3}')" >> ~/.docker-learning-cleanup.log
```

---

> 💡 **Cleanup Philosophy**: Phase 02 builds powerful but resource-intensive features. Regular cleanup prevents resource exhaustion and maintains a clean learning environment while preserving legitimate cache benefits for performance.