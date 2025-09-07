# Phase 08 Cleanup Rules: CI/CD & Buildx

> **Purpose**: Safe cleanup procedures for Docker Buildx, CI/CD resources, and build artifacts  
> **Risk Level**: Medium - affects build cache and registry resources

## 🧹 Cleanup Overview

This phase generates significant build artifacts, cache data, and registry resources that require proper cleanup to:
- **Free disk space** from build cache and intermediate images
- **Remove test resources** created during multi-architecture builds
- **Clean CI/CD artifacts** and temporary pipeline resources
- **Manage registry storage** and remove test images
- **Reset build environments** for fresh configurations

## ⚠️ Pre-Cleanup Safety Checklist

### Critical Verification Steps
- [ ] **Backup important images** to external registry or tar files
- [ ] **Document current Buildx configuration** for potential restoration
- [ ] **Save CI/CD pipeline configurations** and secrets
- [ ] **Export SBOM files and security reports** for compliance records
- [ ] **Verify no production builds** are currently running

### Production Protection
```bash
# List production images that should NOT be deleted
docker images | grep -E "(prod|production|release)" > production-images.txt

# Export critical configurations
docker buildx inspect --bootstrap > buildx-config-backup.txt

# Backup CI/CD secrets (example for GitHub)
gh secret list --repo your-org/your-repo > github-secrets-backup.txt
```

## 🗑️ Rule 1: Buildx Environment Cleanup

### Standard Buildx Cleanup
```bash
# Remove unused build cache (safe)
docker buildx prune

# Remove specific builder instance
docker buildx rm lab-builder

# Clean all buildx cache (aggressive)
docker buildx prune --all --force

# List remaining builders
docker buildx ls
```

### Complete Buildx Reset
```bash
# Remove all custom builders
docker buildx ls --format "{{.Name}}" | grep -v "default" | xargs -I {} docker buildx rm {}

# Reset to default builder
docker buildx use default

# Clean all BuildKit state
docker buildx prune --all --force

# Remove BuildKit containers
docker ps -a --filter "ancestor=moby/buildkit" -q | xargs -r docker rm -f
```

### Registry Cache Cleanup
```bash
# Clean registry-based cache (replace with your registry)
REGISTRY="your-registry.com"
CACHE_REPO="$REGISTRY/buildcache"

# List cache tags
docker buildx imagetools inspect $CACHE_REPO --format "{{json .Manifest}}"

# Remove specific cache versions
docker buildx imagetools create --dry-run $CACHE_REPO:cache # Verify before deletion

# Clean registry cache (requires registry API access)
curl -X DELETE "https://$REGISTRY/v2/$CACHE_REPO/manifests/cache"
```

## 🗑️ Rule 2: Multi-Architecture Image Cleanup

### Local Image Cleanup
```bash
# Remove multi-arch test images
docker images | grep -E "(test|multiarch|benchmark)" | awk '{print $1":"$2}' | xargs -r docker rmi -f

# Remove orphaned multi-arch images
docker image prune --filter "dangling=true" --force

# Clean build context cache
docker builder prune --all --force
```

### Registry Multi-Arch Cleanup
```bash
#!/bin/bash
# cleanup-registry-images.sh

REGISTRY="your-registry.com"
REPO="your-app"
CLEANUP_TAGS=("test" "benchmark" "staging-*")

for tag_pattern in "${CLEANUP_TAGS[@]}"; do
  echo "Cleaning images matching: $tag_pattern"
  
  # List matching tags
  curl -s "https://$REGISTRY/v2/$REPO/tags/list" | \
    jq -r '.tags[]' | \
    grep -E "$tag_pattern" | \
    while read tag; do
      echo "Deleting $REPO:$tag"
      
      # Get manifest digest
      DIGEST=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "https://$REGISTRY/v2/$REPO/manifests/$tag" | \
        jq -r '.config.digest')
      
      # Delete by digest
      curl -X DELETE "https://$REGISTRY/v2/$REPO/manifests/$DIGEST"
    done
done
```

### Platform-Specific Cleanup
```bash
# Clean platform-specific build artifacts
docker buildx imagetools create --dry-run \
  --tag cleanup-test:latest \
  your-registry.com/app:linux-amd64 \
  your-registry.com/app:linux-arm64

# Remove individual platform images if no longer needed
docker rmi your-registry.com/app:linux-amd64
docker rmi your-registry.com/app:linux-arm64
```

## 🗑️ Rule 3: CI/CD Pipeline Cleanup

### GitHub Actions Cleanup
```bash
# Clean workflow runs (requires gh CLI)
gh run list --limit 100 --json databaseId --jq '.[].databaseId' | \
  head -50 | \
  xargs -I {} gh api repos/{owner}/{repo}/actions/runs/{} -X DELETE

# Remove old workflow artifacts
gh api repos/{owner}/{repo}/actions/artifacts | \
  jq -r '.artifacts[] | select(.expired == false) | .id' | \
  head -10 | \
  xargs -I {} gh api repos/{owner}/{repo}/actions/artifacts/{} -X DELETE
```

### GitLab CI Cleanup
```bash
# Clean GitLab CI/CD jobs (requires GitLab CLI or API)
# List old pipelines
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.example.com/api/v4/projects/{id}/pipelines?per_page=100&sort=desc"

# Delete old pipelines (be careful!)
curl --request DELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.example.com/api/v4/projects/{id}/pipelines/{pipeline_id}"
```

### Local CI/CD Artifacts
```bash
# Clean local CI/CD test artifacts
rm -rf .github/workflows/.test-*
rm -rf ci-cache/
rm -rf build-reports/
rm -rf security-scan-results/

# Remove temporary CI/CD configuration files
find . -name "*.ci.tmp" -delete
find . -name "*-pipeline.log" -delete
```

## 🗑️ Rule 4: Security and SBOM Artifacts

### SBOM and Security Report Cleanup
```bash
# Archive important security reports before cleanup
mkdir -p archive/security-reports/$(date +%Y-%m-%d)
mv *.sarif *.spdx.json *.sbom.json archive/security-reports/$(date +%Y-%m-%d)/

# Clean temporary security scan files
rm -f trivy-*.json
rm -f scout-*.json
rm -f vulnerability-report-*.html
rm -f grype-*.json

# Clean security tool cache
docker scout cache prune
trivy clean --cache-dir
```

### Signing Key Cleanup
```bash
# Backup signing keys before cleanup
cp cosign.key cosign.key.backup.$(date +%Y%m%d)
cp cosign.pub cosign.pub.backup.$(date +%Y%m%d)

# Remove temporary signing artifacts
rm -f signature-*.sig
rm -f attestation-*.json
rm -f cosign-*.tmp
```

## 🗑️ Rule 5: Performance and Cache Data

### Build Cache Analysis and Cleanup
```bash
#!/bin/bash
# analyze-and-clean-cache.sh

echo "📊 Build Cache Analysis"
echo "======================"

# Analyze cache usage
df -h /var/lib/docker/buildkit
docker system df --verbose

# Show cache breakdown
docker buildx du

# Clean based on age (older than 7 days)
find /tmp/buildx-cache -name "*.tmp" -mtime +7 -delete

# Clean based on size (keep only last 1GB)
docker buildx prune --keep-storage 1GB
```

### Registry Storage Optimization
```bash
# Analyze registry usage
curl -s "https://$REGISTRY/v2/_catalog" | jq '.repositories[]' | \
  while read repo; do
    echo "Repository: $repo"
    curl -s "https://$REGISTRY/v2/$repo/tags/list" | jq '.tags | length'
  done

# Clean old tags (keep only last 10)
curl -s "https://$REGISTRY/v2/$REPO/tags/list" | \
  jq -r '.tags[]' | \
  sort -V | \
  head -n -10 | \
  while read tag; do
    echo "Cleaning old tag: $tag"
    # Delete tag (implement based on your registry)
  done
```

## 🔄 Progressive Cleanup Strategy

### Level 1: Conservative Cleanup (Recommended)
```bash
#!/bin/bash
# conservative-cleanup.sh

echo "🧹 Conservative Cleanup - Phase 08"

# Clean only safe, regeneratable resources
docker buildx prune --filter "until=24h"
docker image prune --filter "dangling=true"
docker container prune --filter "until=24h"

# Clean temporary files
rm -f *.tmp
rm -f *-temp.*

echo "✅ Conservative cleanup completed"
```

### Level 2: Standard Cleanup
```bash
#!/bin/bash
# standard-cleanup.sh

echo "🧹 Standard Cleanup - Phase 08"

# Clean build artifacts
docker buildx prune --all
docker image prune --all --filter "until=48h"

# Clean test images
docker images | grep -E "(test|benchmark)" | awk '{print $3}' | xargs -r docker rmi -f

# Clean CI/CD artifacts
rm -rf ci-cache/
rm -f build-*.log

echo "✅ Standard cleanup completed"
```

### Level 3: Aggressive Cleanup (Use with caution)
```bash
#!/bin/bash
# aggressive-cleanup.sh

echo "⚠️  Aggressive Cleanup - Phase 08"
read -p "This will remove ALL build cache and test images. Continue? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Nuclear option - clean everything
  docker buildx prune --all --force
  docker system prune --all --volumes --force
  
  # Remove all custom builders
  docker buildx ls --format "{{.Name}}" | grep -v "default" | xargs -I {} docker buildx rm {}
  
  # Clean all CI/CD artifacts
  rm -rf .ci-cache/
  rm -rf build-reports/
  rm -rf security-reports/
  
  echo "💥 Aggressive cleanup completed"
else
  echo "Cleanup cancelled"
fi
```

## 📊 Cleanup Verification

### Post-Cleanup Validation
```bash
#!/bin/bash
# verify-cleanup.sh

echo "🔍 Post-Cleanup Verification"
echo "============================="

# Check disk space recovered
df -h /var/lib/docker

# Verify essential services still work
docker buildx ls
docker buildx inspect

# Test basic functionality
docker buildx build --platform linux/amd64 -t cleanup-test - <<EOF
FROM alpine:3.18
CMD echo "Cleanup verification successful"
EOF

# Verify registry connectivity
docker login --username test --password-stdin < /dev/null

echo "✅ Cleanup verification completed"
```

### Cleanup Metrics Dashboard
```bash
#!/bin/bash
# cleanup-metrics.sh

echo "📊 Cleanup Metrics Dashboard"
echo "============================="

# Before cleanup snapshot
BEFORE_SIZE=$(docker system df --format "table {{.TotalCount}}\t{{.Size}}" | tail -n +2 | awk '{sum += $2} END {print sum}')

# Perform cleanup (call your cleanup script here)
./standard-cleanup.sh

# After cleanup snapshot
AFTER_SIZE=$(docker system df --format "table {{.TotalCount}}\t{{.Size}}" | tail -n +2 | awk '{sum += $2} END {print sum}')

# Calculate savings
SAVINGS=$((BEFORE_SIZE - AFTER_SIZE))

echo "Space before cleanup: ${BEFORE_SIZE}MB"
echo "Space after cleanup: ${AFTER_SIZE}MB"
echo "Space recovered: ${SAVINGS}MB"
```

## 📝 Cleanup Checklist

### Pre-Cleanup Verification
- [ ] Production images identified and protected
- [ ] Build configurations backed up
- [ ] CI/CD secrets documented
- [ ] No active builds running
- [ ] Registry access confirmed

### Standard Cleanup Tasks
- [ ] Build cache pruned
- [ ] Test images removed  
- [ ] Unused builders cleaned
- [ ] CI/CD artifacts archived
- [ ] Security reports saved

### Post-Cleanup Validation
- [ ] Essential functionality tested
- [ ] Disk space recovered verified
- [ ] No critical resources lost
- [ ] Build capability confirmed
- [ ] Registry connectivity maintained

### Emergency Recovery
- [ ] Backup restoration procedure documented
- [ ] Contact information for registry admin
- [ ] Alternative builder configuration ready
- [ ] Critical image restoration plan
- [ ] CI/CD pipeline recovery steps

---

💡 **Cleanup Success**: Regular cleanup maintains optimal build performance while preserving essential resources and configurations for production workflows.