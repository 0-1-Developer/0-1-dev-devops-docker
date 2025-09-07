# Micro-Lesson 03: Multi-Architecture Builds

> **Duration**: 25 minutes  
> **Objective**: Master Docker BuildKit multi-architecture builds for AMD64, ARM64, and ARM/v7 platforms  
> **Prerequisites**: Docker BuildKit enabled, understanding of CPU architectures, basic Docker build knowledge

## 🎯 Learning Goal

Create multi-architecture container images that run natively on AMD64 (Intel/AMD), ARM64 (Apple Silicon, AWS Graviton), and ARM/v7 (Raspberry Pi) platforms using Docker BuildKit and buildx.

## 📚 Concept Overview

**Multi-architecture builds** create container images that contain platform-specific binaries for different CPU architectures, packaged in a single manifest that automatically selects the correct variant based on the target platform.

### Architecture Landscape
- **AMD64 (x86_64)**: Traditional Intel/AMD processors, most cloud instances
- **ARM64 (aarch64)**: Apple Silicon Macs, AWS Graviton, modern mobile devices
- **ARM/v7**: Raspberry Pi, older ARM devices
- **Other**: RISC-V, s390x (IBM Z), ppc64le (IBM Power)

### Build Strategies
1. **Native Builds**: Compile on each target architecture
2. **Cross-Compilation**: Compile for different architectures on one machine
3. **Emulation**: Use QEMU to emulate target architectures during build

### Benefits
- **Universal Deployment**: Single image works across all supported platforms
- **Performance**: Native execution vs emulation performance penalties
- **Cost Optimization**: Use ARM instances for better price/performance
- **Developer Experience**: Seamless experience across different development machines

## 🔧 Hands-On Implementation

### Step 1: Environment Setup

Enable BuildKit and create a multi-platform builder:

```bash
# Verify Docker BuildKit is enabled
docker buildx version

# Install QEMU for emulation (if not already installed)
docker run --privileged --rm tonistiigi/binfmt --install all

# Create a new builder instance
docker buildx create --name multiarch --driver docker-container --bootstrap
docker buildx use multiarch

# Verify builder capabilities
docker buildx inspect --bootstrap
```

### Step 2: Simple Multi-Arch Go Application

Create a Go application that displays platform information:

**main.go**
```go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "runtime"
    "time"
)

type PlatformInfo struct {
    Message      string    `json:"message"`
    Architecture string    `json:"architecture"`
    OS           string    `json:"os"`
    GoVersion    string    `json:"go_version"`
    NumCPU       int       `json:"num_cpu"`
    Timestamp    time.Time `json:"timestamp"`
    BuildInfo    string    `json:"build_info"`
}

func platformHandler(w http.ResponseWriter, r *http.Request) {
    buildInfo := fmt.Sprintf("Built for %s/%s", runtime.GOOS, runtime.GOARCH)
    
    info := PlatformInfo{
        Message:      fmt.Sprintf("Hello from %s/%s!", runtime.GOOS, runtime.GOARCH),
        Architecture: runtime.GOARCH,
        OS:           runtime.GOOS,
        GoVersion:    runtime.Version(),
        NumCPU:       runtime.NumCPU(),
        Timestamp:    time.Now(),
        BuildInfo:    buildInfo,
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(info)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "OK - Running on %s/%s\n", runtime.GOOS, runtime.GOARCH)
}

func main() {
    http.HandleFunc("/", platformHandler)
    http.HandleFunc("/health", healthHandler)
    
    fmt.Printf("Server starting on :8080 (%s/%s)\n", runtime.GOOS, runtime.GOARCH)
    if err := http.ListenAndServe(":8080", nil); err != nil {
        fmt.Printf("Server failed: %v\n", err)
    }
}
```

**go.mod**
```go
module multiarch-app

go 1.21
```

### Step 3: Multi-Architecture Dockerfile

**Dockerfile**
```dockerfile
# Use build arguments for cross-compilation
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

# Understand platform arguments
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Display build information
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

WORKDIR /app

# Copy go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build for target platform
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build \
    -ldflags='-w -s' \
    -o multiarch-app .

# Runtime stage - minimal image
FROM --platform=$TARGETPLATFORM alpine:latest

# Install CA certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN adduser -D -s /bin/sh appuser

# Copy binary from builder
COPY --from=builder /app/multiarch-app /usr/local/bin/multiarch-app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run application
ENTRYPOINT ["multiarch-app"]
```

### Step 4: Build Multi-Architecture Images

Build and push multi-architecture images:

```bash
# Build for multiple platforms and push to registry
# Replace 'yourusername' with your Docker Hub username
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t yourusername/multiarch-app:latest \
    --push .

# Build locally for testing (loads only native architecture)
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t multiarch-app:local \
    --load .
```

If you don't have a registry, create a local one for testing:
```bash
# Start local registry
docker run -d -p 5000:5000 --name registry registry:2

# Build and push to local registry
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t localhost:5000/multiarch-app:latest \
    --push .
```

### Step 5: Advanced Multi-Stage with Platform-Specific Optimizations

**Dockerfile.optimized**
```dockerfile
# Multi-stage with platform-specific optimizations
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS base

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

# Platform-specific builder stage
FROM base AS builder-amd64
ENV GOARCH=amd64
ENV CGO_ENABLED=0
# AMD64 specific optimizations
ENV GOAMD64=v3
COPY . .
RUN go build -ldflags='-w -s' -o multiarch-app .

FROM base AS builder-arm64
ENV GOARCH=arm64
ENV CGO_ENABLED=0
COPY . .
RUN go build -ldflags='-w -s' -o multiarch-app .

FROM base AS builder-arm
ENV GOARCH=arm
ENV GOARM=7
ENV CGO_ENABLED=0
COPY . .
RUN go build -ldflags='-w -s' -o multiarch-app .

# Select appropriate builder based on target architecture
FROM builder-${TARGETARCH} AS selected-builder

# Runtime image
FROM --platform=$TARGETPLATFORM alpine:latest AS runtime

RUN apk --no-cache add ca-certificates && \
    adduser -D -s /bin/sh appuser

COPY --from=selected-builder /app/multiarch-app /usr/local/bin/multiarch-app

USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["multiarch-app"]
```

Build the optimized version:
```bash
docker buildx build \
    -f Dockerfile.optimized \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    -t localhost:5000/multiarch-app:optimized \
    --push .
```

## 🔍 Verification and Testing

### Inspect Multi-Architecture Manifest

```bash
# View multi-arch manifest
docker buildx imagetools inspect localhost:5000/multiarch-app:latest

# Check specific platform image
docker buildx imagetools inspect localhost:5000/multiarch-app:latest --format '{{ json . }}'

# View supported platforms
docker manifest inspect localhost:5000/multiarch-app:latest | jq '.manifests[].platform'
```

### Test Different Architectures

```bash
# Run on different platforms
docker run --rm --platform linux/amd64 \
    -p 8080:8080 localhost:5000/multiarch-app:latest &

docker run --rm --platform linux/arm64 \
    -p 8081:8080 localhost:5000/multiarch-app:latest &

# Test each platform
echo "Testing AMD64:"
curl -s http://localhost:8080/ | jq '.architecture'

echo "Testing ARM64:"
curl -s http://localhost:8081/ | jq '.architecture'

# Stop containers
docker stop $(docker ps -q --filter "ancestor=localhost:5000/multiarch-app:latest")
```

### Performance Comparison

```bash
# Create performance test script
cat > performance-test.sh << 'EOF'
#!/bin/bash

PLATFORMS=("linux/amd64" "linux/arm64" "linux/arm/v7")
IMAGE="localhost:5000/multiarch-app:latest"

for platform in "${PLATFORMS[@]}"; do
    echo "Testing $platform..."
    
    # Measure startup time
    start_time=$(date +%s%N)
    container_id=$(docker run -d --platform $platform -p 0:8080 $IMAGE)
    
    # Wait for container to be ready
    while ! docker exec $container_id wget --spider -q http://localhost:8080/health 2>/dev/null; do
        sleep 0.1
    done
    
    end_time=$(date +%s%N)
    startup_time=$(( (end_time - start_time) / 1000000 ))
    
    # Get port
    port=$(docker port $container_id 8080 | cut -d: -f2)
    
    # Performance test
    echo "Startup time: ${startup_time}ms"
    echo "Platform info:"
    curl -s http://localhost:$port/ | jq '{architecture, num_cpu}'
    
    # Cleanup
    docker stop $container_id > /dev/null
    docker rm $container_id > /dev/null
    
    echo "---"
done
EOF

chmod +x performance-test.sh
./performance-test.sh
```

### Build Time Analysis

```bash
# Measure build times for each platform
time docker buildx build --platform linux/amd64 -t test:amd64 .
time docker buildx build --platform linux/arm64 -t test:arm64 .
time docker buildx build --platform linux/arm/v7 -t test:armv7 .

# Clean up test images
docker rmi test:amd64 test:arm64 test:armv7 2>/dev/null || true
```

## ⚡ Advanced Techniques

### Custom Platform Variables

```dockerfile
# Use custom build arguments for fine-grained control
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# Custom variables based on platform
ARG BUILD_FLAGS=""
ARG OPTIMIZATION_LEVEL=""

# Set platform-specific build flags
RUN case "$TARGETARCH" in \
    "amd64") export BUILD_FLAGS="-march=x86-64-v3" ;; \
    "arm64") export BUILD_FLAGS="-march=armv8-a" ;; \
    "arm") export BUILD_FLAGS="-march=armv7-a" ;; \
    esac

WORKDIR /app
COPY . .

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build \
    -ldflags='-w -s' \
    -gcflags="$BUILD_FLAGS" \
    -o multiarch-app .
```

### Conditional Dependencies

```dockerfile
# Install platform-specific dependencies
FROM --platform=$TARGETPLATFORM alpine:latest

ARG TARGETARCH

RUN case "$TARGETARCH" in \
    "amd64") apk add --no-cache intel-ucode ;; \
    "arm64") apk add --no-cache device-tree-compiler ;; \
    "arm") apk add --no-cache raspberrypi-bootloader ;; \
    esac
```

### Build Cache Optimization

```bash
# Use build cache for faster multi-arch builds
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --cache-from=type=registry,ref=localhost:5000/multiarch-app:buildcache \
    --cache-to=type=registry,ref=localhost:5000/multiarch-app:buildcache,mode=max \
    -t localhost:5000/multiarch-app:cached \
    --push .
```

## 🚫 Common Pitfalls

### Platform Argument Confusion
```dockerfile
# Wrong: Using hardcoded platform
FROM golang:1.21-alpine

# Correct: Using platform arguments
FROM --platform=$BUILDPLATFORM golang:1.21-alpine
```

### Missing Cross-Compilation Setup
```dockerfile
# Wrong: Not setting target OS/ARCH
RUN go build -o app .

# Correct: Setting target platform
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o app .
```

### Emulation Performance Issues
```bash
# Problem: Building ARM on AMD64 is slow
# Solution: Use native builders or cross-compilation

# Set up native ARM64 builder (if available)
docker context create arm64-builder --docker "host=ssh://user@arm64-host"
docker buildx create --name arm64 --driver docker --driver-opt default-load=true arm64-builder
```

### Registry Push Issues
```bash
# Problem: Can't push manifest list to some registries
# Solution: Use buildx with --push flag, not docker push
docker buildx build --platform linux/amd64,linux/arm64 --push -t myapp .
```

## 🧪 Testing Your Implementation

Comprehensive multi-architecture validation:

```bash
#!/bin/bash
echo "🧪 Multi-Architecture Build Validation"

IMAGE="localhost:5000/multiarch-app:latest"
PLATFORMS=("linux/amd64" "linux/arm64" "linux/arm/v7")

# Test 1: Verify multi-arch manifest exists
echo "Test 1: Multi-arch manifest verification"
if docker buildx imagetools inspect $IMAGE | grep -q "MediaType:.*manifest.list"; then
    echo "✅ Multi-architecture manifest found"
else
    echo "❌ Multi-architecture manifest missing"
fi

# Test 2: Check all platforms are present
echo "Test 2: Platform availability"
for platform in "${PLATFORMS[@]}"; do
    if docker buildx imagetools inspect $IMAGE --format '{{json .}}' | jq -e ".manifests[] | select(.platform.architecture==\"$(echo $platform | cut -d/ -f2)\")" > /dev/null; then
        echo "✅ $platform available"
    else
        echo "❌ $platform missing"
    fi
done

# Test 3: Functional testing on each platform
echo "Test 3: Functional testing"
for platform in "${PLATFORMS[@]}"; do
    echo "Testing $platform..."
    container_id=$(docker run -d --platform $platform -p 0:8080 $IMAGE)
    
    # Wait for startup
    sleep 3
    
    port=$(docker port $container_id 8080 | cut -d: -f2)
    
    if [ -n "$port" ]; then
        response=$(curl -s http://localhost:$port/ 2>/dev/null)
        expected_arch=$(echo $platform | cut -d/ -f2)
        actual_arch=$(echo "$response" | jq -r '.architecture' 2>/dev/null)
        
        if [[ "$actual_arch" == "$expected_arch"* ]]; then
            echo "✅ $platform functional"
        else
            echo "❌ $platform architecture mismatch: expected $expected_arch, got $actual_arch"
        fi
    else
        echo "❌ $platform failed to start"
    fi
    
    docker stop $container_id >/dev/null 2>&1
    docker rm $container_id >/dev/null 2>&1
done

# Test 4: Build performance check
echo "Test 4: Build time analysis"
start_time=$(date +%s)
docker buildx build --platform linux/amd64,linux/arm64 -t test-build:multiarch . >/dev/null 2>&1
end_time=$(date +%s)
build_time=$((end_time - start_time))

if [ $build_time -lt 300 ]; then  # Less than 5 minutes
    echo "✅ Build completed in reasonable time (${build_time}s)"
else
    echo "⚠️  Build took longer than expected (${build_time}s)"
fi

docker rmi test-build:multiarch >/dev/null 2>&1

echo "Multi-architecture validation complete!"
```

## 🎓 Key Takeaways

1. **Platform Arguments**: Always use `--platform=$BUILDPLATFORM` and `--platform=$TARGETPLATFORM`
2. **Cross-Compilation**: Set `GOOS` and `GOARCH` for target platform
3. **Emulation is Slow**: Native builds or cross-compilation are much faster
4. **Registry Support**: Not all registries support multi-arch manifests
5. **Testing is Critical**: Always verify each platform works correctly

## 📚 Advanced Topics

### GitHub Actions Multi-Arch Pipeline
```yaml
name: Multi-Arch Build
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          platforms: linux/amd64,linux/arm64,linux/arm/v7
          push: true
          tags: user/app:latest
```

### Cost Optimization Strategy
- Use ARM64 instances for 20-40% better price/performance
- Build natively on each architecture when possible
- Cache build layers to reduce repeated compilation
- Consider build time vs runtime performance tradeoffs

---

💡 **Multi-Arch Mastery**: You've mastered multi-architecture builds when your images work seamlessly across AMD64, ARM64, and ARM/v7 platforms with optimal performance and reasonable build times!