# Micro-Lesson 03: Registry Publishing and Multi-Platform Distribution

> **Anchor**: `p08-m01-l03`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master container registry publishing with multi-architecture manifests, automated tagging, and distribution strategies

## Why It Matters

Container registries are the distribution hub for containerized applications, serving as the bridge between build systems and deployment environments. Proper registry publishing ensures reliable deployments, efficient storage usage, and seamless multi-platform support. Poor registry management leads to broken deployments, storage bloat, and security vulnerabilities.

## What to Learn

Master registry publishing fundamentals:
- **Multi-platform manifest creation** - Single tag, multiple architectures
- **Registry authentication and security** - Secure access patterns
- **Tagging strategies and lifecycle management** - Organized image versions
- **Registry optimization and maintenance** - Performance and cost efficiency

## Multi-Platform Registry Publishing

### Basic Multi-Arch Push
```bash
# Build and push multi-architecture image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myregistry.com/myapp:latest \
  --tag myregistry.com/myapp:v1.0.0 \
  --push \
  .

# Verify multi-arch manifest
docker buildx imagetools inspect myregistry.com/myapp:latest
```

### Advanced Publishing with Metadata
```bash
# Build with comprehensive metadata
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --label "org.opencontainers.image.title=MyApp" \
  --label "org.opencontainers.image.description=Production web application" \
  --label "org.opencontainers.image.version=1.0.0" \
  --label "org.opencontainers.image.source=https://github.com/org/myapp" \
  --label "org.opencontainers.image.licenses=MIT" \
  --annotation "org.opencontainers.image.created=$(date -Iseconds)" \
  --tag myregistry.com/myapp:1.0.0 \
  --tag myregistry.com/myapp:latest \
  --push \
  .
```

## Registry Authentication Strategies

### Multiple Registry Authentication
```bash
#!/bin/bash
# multi-registry-auth.sh

# Docker Hub authentication
echo "$DOCKER_HUB_PASSWORD" | docker login --username "$DOCKER_HUB_USERNAME" --password-stdin

# GitHub Container Registry
echo "$GITHUB_TOKEN" | docker login ghcr.io --username "$GITHUB_USERNAME" --password-stdin

# AWS ECR authentication
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Google Container Registry
cat /path/to/service-account.json | docker login -u _json_key --password-stdin gcr.io

# Azure Container Registry
az acr login --name myregistry
```

### CI/CD Registry Authentication
```yaml
# GitHub Actions registry login
- name: Log in to registries
  uses: docker/login-action@v3
  with:
    registry: ${{ matrix.registry }}
    username: ${{ secrets[format('{0}_USERNAME', matrix.registry)] }}
    password: ${{ secrets[format('{0}_PASSWORD', matrix.registry)] }}
```

## Advanced Tagging Strategies

### Semantic Versioning Tags
```bash
#!/bin/bash
# semantic-tagging.sh

VERSION="1.2.3"
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f1-2)

# Build with multiple semantic tags
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myregistry.com/myapp:$VERSION \
  --tag myregistry.com/myapp:$MINOR \
  --tag myregistry.com/myapp:$MAJOR \
  --tag myregistry.com/myapp:latest \
  --push \
  .
```

### Environment-Based Tagging
```bash
# Environment-specific tagging strategy
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
COMMIT_SHA=$(git rev-parse --short HEAD)
BUILD_DATE=$(date +%Y%m%d)

case $BRANCH_NAME in
  "main")
    TAGS="--tag myregistry.com/myapp:latest --tag myregistry.com/myapp:stable"
    ;;
  "develop")
    TAGS="--tag myregistry.com/myapp:develop --tag myregistry.com/myapp:dev-$COMMIT_SHA"
    ;;
  "feature/"*)
    FEATURE_NAME=$(echo $BRANCH_NAME | sed 's/feature\///')
    TAGS="--tag myregistry.com/myapp:feature-$FEATURE_NAME"
    ;;
  *)
    TAGS="--tag myregistry.com/myapp:branch-$BRANCH_NAME-$COMMIT_SHA"
    ;;
esac

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  $TAGS \
  --push \
  .
```

### Time-Based and Build Metadata Tags
```bash
# Comprehensive tagging with metadata
BUILD_TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
GIT_SHA=$(git rev-parse --short=8 HEAD)
VERSION=$(cat VERSION 2>/dev/null || echo "0.0.0")

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myregistry.com/myapp:v$VERSION \
  --tag myregistry.com/myapp:$BUILD_TIMESTAMP \
  --tag myregistry.com/myapp:sha-$GIT_SHA \
  --tag myregistry.com/myapp:latest \
  --label "build.timestamp=$BUILD_TIMESTAMP" \
  --label "git.sha=$GIT_SHA" \
  --label "version=$VERSION" \
  --push \
  .
```

## Registry Management and Optimization

### Multi-Registry Distribution
```bash
#!/bin/bash
# multi-registry-sync.sh

IMAGE_NAME="myapp"
VERSION="1.0.0"
REGISTRIES=(
  "docker.io/myorg"
  "ghcr.io/myorg"
  "myregistry.com/myorg"
)

# Build once, push to multiple registries
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --output type=oci,dest=./image.tar \
  .

# Push to all registries
for registry in "${REGISTRIES[@]}"; do
  echo "Pushing to $registry..."
  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag $registry/$IMAGE_NAME:$VERSION \
    --tag $registry/$IMAGE_NAME:latest \
    --push \
    .
done
```

### Registry Storage Optimization
```bash
#!/bin/bash
# registry-optimization.sh

REGISTRY="myregistry.com"
REPO="myorg/myapp"

echo "🔍 Registry Storage Analysis"

# Analyze image sizes across platforms
docker buildx imagetools inspect $REGISTRY/$REPO:latest | \
  jq -r '.manifests[] | "\(.platform.architecture): \(.size) bytes"'

# Find duplicate layers
docker buildx imagetools inspect $REGISTRY/$REPO:latest --format "{{json .}}" | \
  jq -r '.manifests[].manifest.layers[] | .digest' | \
  sort | uniq -d | \
  while read digest; do
    echo "Duplicate layer: $digest"
  done

# Check manifest size efficiency
MANIFEST_SIZE=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  "https://$REGISTRY/v2/$REPO/manifests/latest" | jq -r '.config.size')
echo "Manifest config size: $MANIFEST_SIZE bytes"
```

## Registry Security and Compliance

### Image Signing with Registry Integration
```bash
#!/bin/bash
# secure-registry-publish.sh

IMAGE="myregistry.com/myapp:v1.0.0"

# Build and push image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag $IMAGE \
  --push \
  .

# Sign image with Cosign
export COSIGN_EXPERIMENTAL=1
cosign sign --yes $IMAGE

# Attach SBOM
docker scout sbom $IMAGE --format spdx-json | \
  cosign attest --predicate - --type spdx $IMAGE

# Verify signature
cosign verify $IMAGE
```

### Vulnerability Scanning in Registry
```bash
#!/bin/bash
# registry-security-scan.sh

IMAGE="myregistry.com/myapp:latest"

# Scan before push (gate)
echo "🔒 Pre-push security scan..."
trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE

if [ $? -eq 0 ]; then
  echo "✅ Security scan passed, pushing to registry"
  docker push $IMAGE
  
  # Post-push verification
  echo "🔍 Post-push verification..."
  docker scout cves $IMAGE --format sarif > security-report.sarif
  
  # Generate and store SBOM
  docker scout sbom $IMAGE --format spdx-json > $IMAGE-sbom.spdx.json
else
  echo "❌ Security scan failed, blocking push"
  exit 1
fi
```

## Registry Performance Monitoring

### Registry Health Checks
```bash
#!/bin/bash
# registry-health.sh

REGISTRIES=(
  "docker.io"
  "ghcr.io" 
  "myregistry.com"
)

for registry in "${REGISTRIES[@]}"; do
  echo "Checking $registry..."
  
  # Test registry connectivity
  start_time=$(date +%s.%N)
  docker login $registry --username test --password-stdin <<< "test" 2>/dev/null
  end_time=$(date +%s.%N)
  
  response_time=$(echo "$end_time - $start_time" | bc)
  echo "$registry response time: ${response_time}s"
  
  # Test image pull performance
  start_time=$(date +%s.%N)
  docker pull $registry/hello-world:latest > /dev/null 2>&1
  end_time=$(date +%s.%N)
  
  pull_time=$(echo "$end_time - $start_time" | bc)
  echo "$registry pull time: ${pull_time}s"
done
```

### Registry Usage Analytics
```bash
#!/bin/bash
# registry-analytics.sh

REGISTRY="myregistry.com"
ORG="myorg"

echo "📊 Registry Usage Analytics"

# List all repositories
curl -s "https://$REGISTRY/v2/_catalog" | \
  jq -r '.repositories[]' | \
  grep "^$ORG/" | \
  while read repo; do
    echo "Repository: $repo"
    
    # Get tag count
    TAG_COUNT=$(curl -s "https://$REGISTRY/v2/$repo/tags/list" | jq '.tags | length')
    echo "  Tags: $TAG_COUNT"
    
    # Get latest manifest size
    MANIFEST=$(curl -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      "https://$REGISTRY/v2/$repo/manifests/latest")
    SIZE=$(echo "$MANIFEST" | jq -r '.config.size')
    echo "  Latest size: $SIZE bytes"
  done
```

## Practice Tasks

1. **Setup multi-registry authentication**:
   ```bash
   echo "$TOKEN" | docker login ghcr.io --username user --password-stdin
   ```

2. **Build and push multi-arch image**:
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 \
     --tag myregistry.com/test:latest --push .
   ```

3. **Inspect multi-arch manifest**:
   ```bash
   docker buildx imagetools inspect myregistry.com/test:latest
   ```

4. **Implement tagging strategy**:
   ```bash
   VERSION=$(git describe --tags)
   docker buildx build --tag myapp:$VERSION --tag myapp:latest .
   ```

## Production Best Practices

### Registry Selection Criteria
- **Performance**: Geographic proximity and CDN availability
- **Reliability**: SLA guarantees and redundancy
- **Security**: Vulnerability scanning and access controls
- **Cost**: Storage and bandwidth pricing models
- **Compliance**: Data residency and audit requirements

### Image Lifecycle Management
- **Retention policies**: Automatic cleanup of old images
- **Security patching**: Regular base image updates
- **Monitoring**: Registry health and usage metrics
- **Backup strategies**: Registry data protection
- **Disaster recovery**: Cross-region replication

### Multi-Registry Strategy
- **Primary registry**: Main production image storage
- **Fallback registries**: Disaster recovery and availability
- **Development registries**: Separate from production
- **Staging registries**: Pre-production testing
- **Public registries**: Open source image distribution

## Key Takeaway

Effective registry publishing with multi-architecture support, proper authentication, strategic tagging, and lifecycle management ensures reliable, secure, and efficient container distribution across diverse deployment environments.