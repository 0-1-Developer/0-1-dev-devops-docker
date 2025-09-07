# Phase 11 Cleanup Rules: Advanced Docker Images

> **Purpose**: Safe cleanup procedures for advanced Docker image artifacts, build caches, and experimental configurations  
> **Scope**: Comprehensive cleanup without disrupting production workloads or losing valuable build optimizations

## 🗑️ Cleanup Overview

This cleanup ensures proper removal of:
- Experimental and test images created during advanced image exercises
- Multi-architecture build artifacts and cached layers
- Security scanning databases and temporary files
- Signing keys and attestation artifacts (with appropriate safeguards)
- Performance test containers and benchmarking data

## 🔄 Cleanup Categories

### Category 1: Safe Cleanup (Always Safe to Run)
Items that can be removed without impacting production or losing significant work:
- Temporary test containers
- Anonymous build cache volumes
- Unused image layers older than 24 hours
- Experimental image variants

### Category 2: Selective Cleanup (Requires Consideration)
Items that might contain valuable data or ongoing work:
- Named build cache volumes
- Multi-architecture build contexts
- Security scanning databases
- Performance benchmarking results

### Category 3: Protected Resources (Manual Review Required)
Items that should be carefully reviewed before removal:
- Production image signatures and keys
- Base image caches used by active development
- Custom buildx builders with specific configurations
- SBOM attestations for compliance

## 🧹 Rule 1: Image and Container Cleanup

### Safe Image Cleanup
```bash
# Remove exercise-specific test images
docker rmi $(docker images --filter "dangling=true" -q) 2>/dev/null || true

# Remove experimental image variants
docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(experiment|test|temp)") 2>/dev/null || true

# Clean up traditional vs distroless comparison images
docker rmi traditional-python-app distroless-python-app 2>/dev/null || true
docker rmi traditional-go-app distroless-go-app 2>/dev/null || true
docker rmi traditional-rust-app distroless-rust-app 2>/dev/null || true
docker rmi traditional-node-app distroless-node-app 2>/dev/null || true

# Remove static linking test images
docker rmi static-go-app static-rust-app scratch-app 2>/dev/null || true

# Remove CVE testing images
docker rmi vulnerable-app secure-app hardened-app 2>/dev/null || true
```

### Container Cleanup
```bash
# Stop and remove test containers
docker stop $(docker ps -aq --filter "name=advanced-test") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=advanced-test") 2>/dev/null || true

# Remove performance benchmark containers
docker stop $(docker ps -aq --filter "label=phase11.benchmark=true") 2>/dev/null || true
docker rm $(docker ps -aq --filter "label=phase11.benchmark=true") 2>/dev/null || true

# Clean up multi-arch test containers
docker stop $(docker ps -aq --filter "label=multiarch.test=true") 2>/dev/null || true
docker rm $(docker ps -aq --filter "label=multiarch.test=true") 2>/dev/null || true
```

### Verification Commands
```bash
# Verify containers stopped
docker ps --filter "label=phase11.exercise=true" --format "{{.Names}}: {{.Status}}"

# Check remaining test images
docker images --filter "reference=*test*" --filter "reference=*experiment*" --format "{{.Repository}}:{{.Tag}}"

# Confirm no orphaned containers
docker ps -a --filter "status=exited" --filter "name=advanced-" --format "{{.Names}}"
```

## 🧹 Rule 2: Build Cache and Context Cleanup

### BuildKit Cache Cleanup
```bash
# Remove unused build cache (keeps recent caches)
docker builder prune --filter "until=24h" --force

# Clear specific build contexts from exercises
docker buildx rm advanced-builder 2>/dev/null || true
docker buildx rm multiarch-builder 2>/dev/null || true
docker buildx rm security-builder 2>/dev/null || true

# Remove anonymous volumes from builds
docker volume rm $(docker volume ls -q --filter "dangling=true") 2>/dev/null || true

# Clean up build secrets (if any were created for exercises)
docker buildx prune --filter "type==cache.export"
```

### Multi-Architecture Builder Cleanup
```bash
# List current builders before cleanup
echo "Current buildx builders:"
docker buildx ls

# Remove exercise-specific builders
docker buildx rm phase11-multiarch 2>/dev/null || true
docker buildx rm exercise-builder 2>/dev/null || true

# Reset to default builder
docker buildx use default

# Clean up QEMU emulation (if installed for exercises)
# Note: Only remove if not needed for other projects
read -p "Remove QEMU emulation setup? (y/N): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi
```

### Verification Commands
```bash
# Check builder status
docker buildx ls

# Verify cache size reduction
docker system df

# Check build context cleanup
docker buildx du
```

## 🧹 Rule 3: Security Artifacts Cleanup

### Scanning Database Cleanup
```bash
# Clean up Trivy vulnerability database (will re-download when needed)
trivy clean --vuln-db 2>/dev/null || true

# Remove Syft cache
rm -rf ~/.cache/syft 2>/dev/null || true

# Clean up Grype database
grype db delete 2>/dev/null || true

# Remove temporary SBOM files from exercises
rm -f *.sbom.json *.spdx.json *-sbom.* 2>/dev/null || true

# Clean up attestation artifacts (temporary ones only)
rm -f temp-*.att attestation-*.json 2>/dev/null || true
```

### Signing Key Cleanup (With Safeguards)
```bash
# WARNING: This section requires manual review
echo "🔐 Security Key Cleanup (REVIEW REQUIRED)"
echo "The following files will be preserved by default:"

# List signing keys for review
ls -la cosign.* 2>/dev/null || echo "No cosign keys found"
ls -la *.pem *.key 2>/dev/null || echo "No key files found"

# Only remove explicitly temporary keys
rm -f temp-cosign.key temp-cosign.pub 2>/dev/null || true
rm -f exercise-*.key exercise-*.pub 2>/dev/null || true

echo "Production keys preserved. Manual review required for permanent key removal."
```

### Verification Commands
```bash
# Check remaining security files
ls -la *.key *.pub *.pem cosign.* 2>/dev/null || echo "No security files found"

# Verify scanning tools still functional
trivy version 2>/dev/null || echo "Trivy not available"
syft version 2>/dev/null || echo "Syft not available"
cosign version 2>/dev/null || echo "Cosign not available"
```

## 🧹 Rule 4: Performance and Benchmarking Cleanup

### Benchmarking Data Cleanup
```bash
# Remove benchmark result files
rm -f benchmark-*.json performance-*.log 2>/dev/null || true
rm -f startup-times.txt memory-usage.csv 2>/dev/null || true

# Clean up performance test volumes
docker volume rm $(docker volume ls -q --filter "name=perf-test") 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=benchmark") 2>/dev/null || true

# Remove load testing containers
docker stop $(docker ps -aq --filter "label=loadtest=true") 2>/dev/null || true
docker rm $(docker ps -aq --filter "label=loadtest=true") 2>/dev/null || true

# Clean up monitoring containers used for performance testing
docker stop performance-monitor 2>/dev/null || true
docker rm performance-monitor 2>/dev/null || true
```

### Resource Usage Cleanup
```bash
# Remove resource monitoring logs
rm -f docker-stats-*.log resource-usage-*.csv 2>/dev/null || true

# Clean up memory profiling files
rm -f memory-profile-*.out cpu-profile-*.out 2>/dev/null || true

# Remove temporary performance data
rm -rf ./perf-data ./benchmark-results 2>/dev/null || true
```

### Verification Commands
```bash
# Check for remaining performance files
ls -la benchmark-* performance-* *.profile 2>/dev/null || echo "No performance files found"

# Verify no performance containers running
docker ps --filter "label=benchmark=true" --format "{{.Names}}: {{.Status}}"

# Check volume cleanup
docker volume ls --filter "name=perf" --format "{{.Name}}"
```

## 🧹 Rule 5: Development Environment Reset

### Configuration Cleanup
```bash
# Remove exercise-specific Docker configs
rm -f ~/.docker/config.json.backup 2>/dev/null || true

# Clean up temporary Docker contexts
docker context rm exercise-context 2>/dev/null || true

# Remove experimental feature flags
sed -i.bak '/experimental/d' ~/.docker/config.json 2>/dev/null || true

# Clean up temporary networks from exercises
docker network rm $(docker network ls -q --filter "name=phase11") 2>/dev/null || true
docker network rm $(docker network ls -q --filter "label=exercise=advanced-images") 2>/dev/null || true
```

### File System Cleanup
```bash
# Remove exercise working directories
rm -rf ./advanced-images-exercises 2>/dev/null || true
rm -rf ./distroless-examples 2>/dev/null || true
rm -rf ./static-linking-examples 2>/dev/null || true

# Clean up temporary build contexts
rm -rf ./temp-build-* ./build-context-* 2>/dev/null || true

# Remove downloaded base images for comparison (optional)
read -p "Remove large base images used for comparison? (y/N): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi ubuntu:latest alpine:latest debian:slim 2>/dev/null || true
fi
```

### Verification Commands
```bash
# Check Docker context
docker context ls

# Verify network cleanup
docker network ls --filter "name=phase11" --format "{{.Name}}"

# Check remaining files
ls -la ./advanced-* ./distroless-* ./static-* 2>/dev/null || echo "No exercise directories found"
```

## 🔧 Automated Cleanup Scripts

### Conservative Cleanup (Recommended)
```bash
#!/bin/bash
# cleanup-conservative.sh - Safe cleanup that preserves important resources

echo "🧹 Phase 11: Conservative Cleanup"
echo "================================="

# Stop test containers
echo "Stopping test containers..."
docker stop $(docker ps -aq --filter "label=phase11.exercise=true") 2>/dev/null || true
docker rm $(docker ps -aq --filter "label=phase11.exercise=true") 2>/dev/null || true

# Remove test images (keeping production ones)
echo "Removing test images..."
docker rmi $(docker images --filter "reference=*test*" --format "{{.Repository}}:{{.Tag}}") 2>/dev/null || true
docker rmi $(docker images --filter "reference=*experiment*" --format "{{.Repository}}:{{.Tag}}") 2>/dev/null || true

# Clean up build cache (keep recent)
echo "Cleaning build cache..."
docker builder prune --filter "until=24h" --force

# Remove dangling volumes
echo "Removing dangling volumes..."
docker volume rm $(docker volume ls -q --filter "dangling=true") 2>/dev/null || true

# Clean temporary files
echo "Cleaning temporary files..."
rm -f temp-*.json exercise-*.log benchmark-*.csv 2>/dev/null || true

# Verify cleanup
echo "================================="
echo "Cleanup Summary:"
echo "Remaining images: $(docker images -q | wc -l)"
echo "Remaining containers: $(docker ps -aq | wc -l)"
echo "Remaining volumes: $(docker volume ls -q | wc -l)"
echo "✅ Conservative cleanup complete"
```

### Aggressive Cleanup (Use with Caution)
```bash
#!/bin/bash
# cleanup-aggressive.sh - Thorough cleanup that removes most exercise artifacts

echo "⚠️  Phase 11: Aggressive Cleanup"
echo "================================="
read -p "This will remove most exercise artifacts. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Remove all exercise-related images
echo "Removing all exercise images..."
docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(distroless|static|secure|traditional|multiarch|phase11)") 2>/dev/null || true

# Remove all test containers
echo "Removing all test containers..."
docker rm -f $(docker ps -aq --filter "name=test") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=exercise") 2>/dev/null || true

# Clean all build cache
echo "Cleaning all build cache..."
docker builder prune --all --force

# Remove custom builders
echo "Removing custom builders..."
docker buildx rm $(docker buildx ls --format "{{.Name}}" | grep -v "default") 2>/dev/null || true

# System prune (removes unused resources)
echo "System pruning..."
docker system prune --all --force

# Clean up files
echo "Cleaning up files..."
rm -rf ./advanced-images-exercises ./distroless-examples ./static-linking-examples 2>/dev/null || true
rm -f *.sbom.json *.spdx.json benchmark-*.* performance-*.* 2>/dev/null || true

echo "================================="
echo "🗑️  Aggressive cleanup complete"
echo "You may need to rebuild base images for future exercises"
```

### Selective Cleanup Menu
```bash
#!/bin/bash
# cleanup-selective.sh - Interactive cleanup with choices

echo "🎛️  Phase 11: Selective Cleanup"
echo "==============================="

cleanup_images() {
    echo "Available cleanup options for images:"
    echo "1) Remove only test/experiment images"
    echo "2) Remove distroless comparison images"
    echo "3) Remove static linking images"
    echo "4) Remove all exercise images"
    echo "5) Skip image cleanup"
    
    read -p "Select option (1-5): " choice
    case $choice in
        1) docker rmi $(docker images --filter "reference=*test*" --filter "reference=*experiment*" -q) 2>/dev/null || true ;;
        2) docker rmi $(docker images --filter "reference=*distroless*" -q) 2>/dev/null || true ;;
        3) docker rmi $(docker images --filter "reference=*static*" -q) 2>/dev/null || true ;;
        4) docker rmi $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(phase11|exercise)") 2>/dev/null || true ;;
        5) echo "Skipping image cleanup" ;;
        *) echo "Invalid option" ;;
    esac
}

cleanup_builders() {
    echo "Buildx builders:"
    docker buildx ls
    
    read -p "Remove exercise builders? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker buildx rm $(docker buildx ls --format "{{.Name}}" | grep -E "(exercise|phase11|multiarch)" | grep -v "default") 2>/dev/null || true
    fi
}

cleanup_security() {
    echo "Security artifacts found:"
    ls -la *.key *.pub *.sbom.json cosign.* 2>/dev/null || echo "None found"
    
    read -p "Remove temporary security files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f temp-*.key temp-*.pub exercise-*.sbom.json 2>/dev/null || true
        echo "Temporary files removed, production keys preserved"
    fi
}

# Main menu
while true; do
    echo ""
    echo "Select cleanup category:"
    echo "1) Images and containers"
    echo "2) Buildx builders and cache"
    echo "3) Security artifacts"
    echo "4) All (conservative)"
    echo "5) Exit"
    
    read -p "Choice (1-5): " main_choice
    case $main_choice in
        1) cleanup_images ;;
        2) cleanup_builders ;;
        3) cleanup_security ;;
        4) ./cleanup-conservative.sh ;;
        5) echo "Cleanup complete"; break ;;
        *) echo "Invalid option" ;;
    esac
done
```

## 📋 Cleanup Verification Checklist

### Post-Cleanup Verification
- [ ] No orphaned containers from exercises remain
- [ ] Build cache size reduced appropriately
- [ ] Production images and keys preserved
- [ ] Docker daemon responsive and functional
- [ ] Development environment still operational

### Recovery Testing
- [ ] Base image pulls work correctly
- [ ] BuildKit functionality intact
- [ ] Multi-arch builder can be recreated
- [ ] Security scanning tools functional
- [ ] Signing capabilities preserved

### Documentation Updates
- [ ] Cleanup procedures documented
- [ ] Recovery steps recorded
- [ ] Resource usage baselines updated
- [ ] Team notified of cleanup completion

## ⚠️ Important Warnings

1. **Production Keys**: Never automatically remove signing keys or certificates without manual verification
2. **Shared Builders**: Check if buildx builders are used by other projects before removal
3. **Base Images**: Consider the impact of removing base images on development workflows
4. **Security Databases**: Vulnerability databases will re-download (may take time and bandwidth)
5. **Performance Data**: Benchmark results may be valuable for future analysis

## 🔄 Recovery Procedures

### Quick Recovery Script
```bash
#!/bin/bash
# recovery.sh - Restore essential components after aggressive cleanup

echo "🔧 Phase 11: Recovery Setup"

# Recreate multi-arch builder
docker buildx create --name multiarch --driver docker-container --bootstrap
docker buildx use multiarch

# Pull essential base images
docker pull gcr.io/distroless/python3-debian11:latest
docker pull gcr.io/distroless/java17-debian11:latest
docker pull gcr.io/distroless/static-debian11:latest

# Update security databases
trivy image --download-db-only
grype db update

# Verify recovery
echo "Recovery verification:"
docker buildx ls
docker images --filter "reference=gcr.io/distroless/*" --format "{{.Repository}}:{{.Tag}}"

echo "✅ Recovery complete"
```

---

💡 **Cleanup Best Practice**: Always use conservative cleanup first, then selectively remove additional resources based on your specific needs and team requirements.