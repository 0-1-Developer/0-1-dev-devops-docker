# Phase 00: Foundations - Cleanup Rules

> **Restore your system to clean state after completing Phase 00**

## 🎯 Cleanup Overview

This file defines exactly what Docker resources to remove after completing Phase 00 foundations. Following these rules ensures:
- No resource accumulation between phases
- Clean environment for subsequent phases
- Predictable starting state for troubleshooting

## 🧹 Resources Created in Phase 00

During Phase 00 labs and verification, these resources are created:

### Images Pulled
- `alpine:3.18` - Used in Labs 1 & 2
- `nginx:alpine` - Used in Labs 2, 3, 4 and verification
- `nginx:latest` - Pulled in Lab 4 for digest demonstration
- `nginx:1.21` - Pulled in Lab 4 for version comparison

### Containers Created
**Lab Containers:**
- `container1`, `container2` - Lab 1 demos
- `interactive`, `interactive2` - Lab 1 filesystem isolation
- `lifecycle-demo` - Lab 2 state transitions
- `short-lived` - Lab 2 exit behavior
- `no-ports`, `with-ports`, `multi-ports` - Lab 3 networking
- `resource-map` - Lab 3 resource boundaries
- `tag-ref`, `digest-ref` - Lab 4 reference formats

**Verification Containers:**
- `verify-container1`, `verify-container2` - Rule 2 verification
- `lifecycle-test` - Rule 3 verification
- `port-verify` - Rule 4 verification
- `lifecycle-verify` - Full verification sequence

### Files Created
- `deployment.txt` - Lab 4 production scenario examples
- Any personal notes or resource maps created during labs

## 🗑 Cleanup Commands

### Option 1: Targeted Cleanup (Recommended)
Remove only Phase 00 resources, keeping other Docker work intact:

```bash
#!/bin/bash
echo "=== Phase 00 Foundations Cleanup ==="

# Remove containers created in Phase 00
echo "Removing Phase 00 containers..."
docker rm -f \
  container1 container2 interactive interactive2 \
  lifecycle-demo short-lived no-ports with-ports multi-ports \
  resource-map tag-ref digest-ref \
  verify-container1 verify-container2 lifecycle-test \
  port-verify lifecycle-verify 2>/dev/null

# Remove images pulled specifically for Phase 00
echo "Removing Phase 00 images..."  
docker image rm \
  alpine:3.18 \
  nginx:alpine \
  nginx:latest \
  nginx:1.21 2>/dev/null

# Clean up any dangling images created
docker image prune -f

echo "✅ Phase 00 cleanup completed"
```

### Option 2: Complete Docker Cleanup (Nuclear Option)
⚠️ **Warning**: This removes ALL Docker resources on your system:

```bash
# Stop all running containers
docker stop $(docker ps -aq) 2>/dev/null

# Remove all containers
docker container prune -f

# Remove all images  
docker image prune -a -f

# Remove all volumes
docker volume prune -f

# Remove all networks (except defaults)
docker network prune -f

# Remove all build cache
docker builder prune -a -f

echo "⚠️ Complete Docker cleanup performed"
```

### Option 3: Verification Cleanup Only
Just clean up verification artifacts, keep lab resources for review:

```bash
# Remove only verification containers
docker rm -f \
  verify-container1 verify-container2 \
  lifecycle-test port-verify lifecycle-verify 2>/dev/null

echo "Verification containers cleaned up"
```

## 📋 Cleanup Verification

After running cleanup, verify the clean state:

```bash
# Check no Phase 00 containers remain
docker ps -a --filter name=container1 \
              --filter name=container2 \
              --filter name=interactive \
              --filter name=lifecycle-demo \
              --filter name=short-lived \
              --filter name=no-ports \
              --filter name=with-ports \
              --filter name=multi-ports \
              --filter name=resource-map \
              --filter name=tag-ref \
              --filter name=digest-ref \
              --filter name=verify-container \
              --filter name=lifecycle-test \
              --filter name=port-verify
# Should show no results

# Check Docker system usage
docker system df
```

**Expected clean state:**
- No containers with Phase 00 names
- No dangling images
- Reasonable disk usage

## 🔄 Files to Remove

Clean up any files created during Phase 00:

```bash
# Remove files created in labs (if they exist)
rm -f deployment.txt 2>/dev/null

# Remove any personal notes files you created
# rm -f my-notes.txt phase00-notes.md etc.
```

## 🚨 Troubleshooting Cleanup

### Container Won't Remove
```bash
# If container is still running
docker kill <container-name>
docker rm <container-name>

# If container doesn't exist but command fails
docker rm <container-name> 2>/dev/null || echo "Container not found (OK)"
```

### Image Won't Remove
```bash
# Check if image is being used by containers
docker ps -a --filter ancestor=<image-name>

# Remove containers using the image first
docker rm -f $(docker ps -a --filter ancestor=<image-name> -q) 2>/dev/null

# Then remove image
docker image rm <image-name>
```

### Port Still in Use
```bash
# Check what's using the port (Linux/macOS)
lsof -i :8080

# Check what's using the port (Windows)
netstat -ano | findstr :8080

# Kill process if needed
kill <PID>  # Linux/macOS
taskkill /PID <PID> /F  # Windows
```

## 📈 Pre-Next-Phase Checklist

Before starting Phase 01, confirm:

- [ ] All Phase 00 containers removed
- [ ] Phase 00 images removed (optional - can keep for reference)  
- [ ] No ports from labs still bound
- [ ] Docker daemon responsive (`docker ps` works)
- [ ] Reasonable disk space available
- [ ] Any personal notes saved outside Docker

## 🔄 Automated Cleanup Script

Save this as `cleanup-phase00.sh` for reuse:

```bash
#!/bin/bash
set -e

echo "=== Phase 00 Cleanup Script ==="

# Function to safely remove containers
remove_containers() {
    local containers="$1"
    echo "Removing containers: $containers"
    echo "$containers" | xargs docker rm -f 2>/dev/null || echo "Some containers already removed"
}

# Function to safely remove images  
remove_images() {
    local images="$1"
    echo "Removing images: $images"
    echo "$images" | xargs docker image rm 2>/dev/null || echo "Some images already removed"
}

# Phase 00 containers
PHASE00_CONTAINERS="container1 container2 interactive interactive2 lifecycle-demo short-lived no-ports with-ports multi-ports resource-map tag-ref digest-ref verify-container1 verify-container2 lifecycle-test port-verify lifecycle-verify"

# Phase 00 images
PHASE00_IMAGES="alpine:3.18 nginx:alpine nginx:latest nginx:1.21"

# Remove containers
remove_containers "$PHASE00_CONTAINERS"

# Remove images (optional)
read -p "Remove Phase 00 images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    remove_images "$PHASE00_IMAGES"
fi

# Clean dangling resources
docker image prune -f
docker container prune -f

# Remove any created files
rm -f deployment.txt 2>/dev/null || true

echo "✅ Phase 00 cleanup completed successfully"
echo ""
echo "System status:"
docker system df
echo ""
echo "Ready for Phase 01!"
```

Make it executable:
```bash
chmod +x cleanup-phase00.sh
./cleanup-phase00.sh
```

---

> 💡 **Remember**: Cleanup is optional but recommended. It prevents resource accumulation and ensures each phase starts with a predictable environment.