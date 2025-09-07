# Phase 01: Dockerfile Basics - Cleanup Rules

> **Comprehensive cleanup procedures for Phase 01 resources and artifacts**

## 🎯 Cleanup Overview

Phase 01 involves building multiple Docker images, creating various Dockerfiles, and generating temporary files. This cleanup guide ensures complete resource cleanup while preserving any work you want to keep.

## 🗂 Resources Created in Phase 01

### Images Built During Labs
**Lab 1 - Base Image Selection:**
- `my-node-app:v1` - First custom image built

**Lab 2 - Caching Optimization:**
- `cache-demo:bad` - Inefficient caching example
- `cache-demo:good` - Optimized caching version
- `cache-demo:analysis` - Cache analysis version

**Lab 3 - Context Control:**
- `context-demo:bloated` - Image without .dockerignore
- `context-demo:clean` - Image with proper context control

**Lab 4 - CMD vs ENTRYPOINT:**
- `cmd-demo` - CMD-only demonstration
- `entrypoint-demo` - ENTRYPOINT-only demonstration
- `combined-demo` - ENTRYPOINT + CMD combination
- `webapp-demo` - Configurable web server example

**Lab 5 - Optimization:**
- `flask-app:naive` - Non-optimized Python application
- `flask-app:optimized` - Size-optimized version
- `flask-app:deterministic` - Reproducible build version

### Verification Images
- `verify-basic` - Basic Dockerfile verification
- `cache-test:v1`, `cache-test:v2` - Caching verification
- `context-before`, `context-after`, `context-final` - Context verification
- `cmd-test`, `entrypoint-test`, `combined-test` - CMD/ENTRYPOINT verification

### Containers Created
**Lab containers:**
- `lab1-app` - Testing first application
- Various temporary containers from image testing

**Verification containers:**
- `verify-basic-run` - Basic verification testing
- `webapp1`, `webapp2` - Web application testing
- `naive-app`, `optimized-app` - Flask app comparisons

### Directories and Files Created
**Lab directories:**
- `dockerfile-labs/` - Main lab workspace
  - `simple-node-app/` - Lab 1 application
  - `cache-demo/` - Lab 2 caching examples
  - `context-demo/` - Lab 3 context control
  - `cmd-vs-entrypoint/` - Lab 4 execution examples
  - `optimization-demo/` - Lab 5 size optimization

**Verification directories:**
- `verify-p01/` - Basic verification workspace
- `cache-verify/` - Caching verification
- `context-verify/` - Context control verification
- `cmd-entrypoint-verify/` - CMD/ENTRYPOINT verification

**Generated files:**
- Various `Dockerfile`, `Dockerfile.*` variants
- `.dockerignore` files
- Application source files (`*.js`, `*.py`, etc.)
- Configuration files (`package.json`, `requirements.txt`)
- Shell scripts (`*.sh`)

## 🗑 Cleanup Commands

### Option 1: Complete Phase 01 Cleanup (Recommended)
Removes all Phase 01 resources while preserving other Docker work:

```bash
#!/bin/bash
echo "=== Phase 01 Dockerfile Basics Cleanup ==="

# Stop and remove any running containers from Phase 01
echo "Stopping Phase 01 containers..."
docker stop $(docker ps -q --filter "name=lab1-app") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=verify-basic-run") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=webapp") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=naive-app") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=optimized-app") 2>/dev/null || true

# Remove containers
echo "Removing Phase 01 containers..."
docker rm -f \
    lab1-app \
    verify-basic-run \
    webapp1 webapp2 \
    naive-app optimized-app \
    2>/dev/null || true

# Remove images created in Phase 01
echo "Removing Phase 01 images..."
docker image rm -f \
    my-node-app:v1 \
    cache-demo:bad cache-demo:good cache-demo:analysis \
    context-demo:bloated context-demo:clean \
    cmd-demo entrypoint-demo combined-demo webapp-demo \
    flask-app:naive flask-app:optimized flask-app:deterministic \
    verify-basic \
    cache-test:v1 cache-test:v2 \
    context-before context-after context-final \
    cmd-test entrypoint-test combined-test \
    2>/dev/null || true

# Clean up lab directories (be careful with this!)
echo "Cleaning up lab directories..."
rm -rf dockerfile-labs/ 2>/dev/null || true
rm -rf verify-p01/ 2>/dev/null || true
rm -rf cache-verify/ 2>/dev/null || true
rm -rf context-verify/ 2>/dev/null || true
rm -rf cmd-entrypoint-verify/ 2>/dev/null || true

# Clean up any dangling images and build cache
docker image prune -f
docker builder prune -f

echo "✅ Phase 01 cleanup completed successfully"
```

### Option 2: Selective Cleanup
Keep specific images or directories for reference:

```bash
# Keep optimized examples but remove others
docker image rm -f \
    my-node-app:v1 \
    cache-demo:bad \
    context-demo:bloated \
    flask-app:naive \
    2>/dev/null || true

# Keep: cache-demo:good, flask-app:optimized for reference
echo "Keeping optimized examples for reference"
```

### Option 3: Verification Cleanup Only
Remove only verification artifacts, keep lab results:

```bash
# Remove verification images only
docker image rm -f \
    verify-basic \
    cache-test:v1 cache-test:v2 \
    context-before context-after context-final \
    cmd-test entrypoint-test combined-test \
    2>/dev/null || true

# Remove verification directories
rm -rf verify-p01/ cache-verify/ context-verify/ cmd-entrypoint-verify/
```

## 📋 Cleanup Verification

After cleanup, verify the clean state:

```bash
# Check no Phase 01 containers remain
echo "=== Container Check ==="
docker ps -a --filter "name=lab1" \
             --filter "name=verify-basic" \
             --filter "name=webapp" \
             --filter "name=cache-demo" \
             --filter "name=context-demo"
# Should show no results

# Check image cleanup
echo "=== Image Check ==="
docker image ls --filter "reference=my-node-app" \
               --filter "reference=cache-demo" \
               --filter "reference=context-demo" \
               --filter "reference=flask-app" \
               --filter "reference=*-demo"
# Should show only intentionally kept images

# Check disk space reclaimed  
echo "=== Disk Usage ==="
docker system df

# Check for any leftover directories
echo "=== Directory Check ==="
ls -la | grep -E "(dockerfile-labs|verify-p01|cache-verify|context-verify|cmd-entrypoint-verify)" || echo "No lab directories found"
```

## 🚨 Troubleshooting Cleanup Issues

### Containers Won't Stop/Remove
```bash
# Force kill containers
docker kill $(docker ps -q --filter "name=lab1-app") 2>/dev/null || true
docker kill $(docker ps -q --filter "name=verify-basic") 2>/dev/null || true

# Force remove with --force flag
docker rm --force lab1-app verify-basic-run 2>/dev/null || true
```

### Images Won't Remove (In Use)
```bash
# Find what's using the image
docker ps -a --filter "ancestor=my-node-app:v1"

# Remove containers using the image first
docker rm -f $(docker ps -aq --filter "ancestor=my-node-app:v1") 2>/dev/null
docker image rm my-node-app:v1
```

### Permission Issues with Directories
```bash
# On Linux/macOS, if directories have permission issues
sudo rm -rf dockerfile-labs/ verify-p01/

# On Windows, try using PowerShell as Administrator
Remove-Item -Recurse -Force dockerfile-labs, verify-p01
```

### Build Cache Issues
```bash
# Clear all build cache if builds are failing
docker builder prune -a

# Reset builder if needed (nuclear option)
docker buildx rm --all-inactive
```

## 🔒 Preserving Important Work

Before cleanup, consider saving:

### Sample Dockerfiles
```bash
# Create a reference collection
mkdir -p ~/docker-references/phase01
cp dockerfile-labs/optimization-demo/Dockerfile.optimized ~/docker-references/phase01/
cp dockerfile-labs/cache-demo/Dockerfile.good ~/docker-references/phase01/
cp dockerfile-labs/context-demo/.dockerignore ~/docker-references/phase01/
```

### Performance Measurements
```bash
# Save size comparisons if useful
docker image ls flask-app > phase01-size-comparison.txt
docker image ls cache-demo >> phase01-size-comparison.txt
```

### Working Applications
```bash
# Export useful images for future reference
docker save flask-app:optimized -o flask-optimized-reference.tar
docker save cache-demo:good -o cache-optimized-reference.tar
```

## 📝 Pre-Phase 02 Checklist

Before starting Phase 02, confirm:

- [ ] All Phase 01 containers stopped and removed
- [ ] Phase 01 images cleaned up (or intentionally preserved)
- [ ] Lab directories removed or archived
- [ ] Docker system showing reasonable disk usage
- [ ] No port conflicts from remaining containers
- [ ] BuildKit functioning properly for advanced features
- [ ] Any important work preserved in reference directory

## 🔄 Automated Cleanup Script

Save this as `cleanup-phase01.sh` for easy reuse:

```bash
#!/bin/bash
set -e

echo "=== Phase 01 Dockerfile Basics Cleanup Script ==="

# Function to safely remove containers
cleanup_containers() {
    echo "Stopping and removing Phase 01 containers..."
    local containers="lab1-app verify-basic-run webapp1 webapp2 naive-app optimized-app"
    for container in $containers; do
        docker stop "$container" 2>/dev/null || true
        docker rm -f "$container" 2>/dev/null || true
    done
}

# Function to safely remove images
cleanup_images() {
    echo "Removing Phase 01 images..."
    local images="my-node-app:v1 cache-demo:bad cache-demo:good cache-demo:analysis context-demo:bloated context-demo:clean cmd-demo entrypoint-demo combined-demo webapp-demo flask-app:naive flask-app:optimized flask-app:deterministic verify-basic cache-test:v1 cache-test:v2 context-before context-after context-final cmd-test entrypoint-test combined-test"
    
    for image in $images; do
        docker image rm -f "$image" 2>/dev/null || true
    done
}

# Function to clean directories
cleanup_directories() {
    echo "Cleaning up lab directories..."
    rm -rf dockerfile-labs/ verify-p01/ cache-verify/ context-verify/ cmd-entrypoint-verify/ 2>/dev/null || true
}

# Function to clean Docker system
cleanup_docker_system() {
    echo "Cleaning Docker system..."
    docker image prune -f
    docker builder prune -f
}

# Main execution
main() {
    echo "Starting Phase 01 cleanup..."
    
    cleanup_containers
    cleanup_images
    
    # Ask before removing directories
    read -p "Remove all Phase 01 lab directories? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_directories
    fi
    
    cleanup_docker_system
    
    echo "✅ Phase 01 cleanup completed!"
    echo ""
    echo "System status:"
    docker system df
}

main "$@"
```

Make it executable and run:
```bash
chmod +x cleanup-phase01.sh
./cleanup-phase01.sh
```

---

> 💡 **Remember**: Cleanup between phases prevents resource accumulation and ensures a clean starting point for advanced topics. Consider keeping one optimized example from each lab for future reference.