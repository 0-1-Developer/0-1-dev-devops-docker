# Micro-Lesson 01: Multi-Architecture Builds with Docker Buildx

> **Anchor**: `p08-m01-l01`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master Docker Buildx for cross-platform container builds supporting AMD64, ARM64, and other architectures

## Why It Matters

Modern applications need to run across diverse hardware platforms - from AMD64 servers to ARM64 cloud instances, ARM-based IoT devices, and Apple Silicon Macs. Single-architecture images limit deployment flexibility and miss cost optimization opportunities. Multi-architecture builds ensure your containers run efficiently on any platform.

## What to Learn

Master multi-platform container fundamentals:
- **Docker Buildx setup and configuration** - Advanced build toolkit
- **Cross-compilation strategies** - Build for different CPU architectures  
- **Platform-specific optimizations** - Leverage architecture strengths
- **Multi-arch manifest management** - Single tag, multiple platforms

## Buildx Setup and Configuration

### Initialize Multi-Platform Builder
```bash
# Remove default builder if exists
docker buildx rm multibuilder 2>/dev/null || true

# Create advanced multi-platform builder
docker buildx create \
  --name multibuilder \
  --driver docker-container \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --use

# Bootstrap the builder with platform emulation
docker buildx inspect multibuilder --bootstrap

# Verify supported platforms
docker buildx inspect multibuilder | grep Platforms
```

### QEMU Emulation Setup
```bash
# Install QEMU for cross-platform emulation
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify emulation capabilities
docker run --rm --platform linux/arm64 alpine:3.18 uname -m
```

## Multi-Architecture Dockerfile Patterns

### Platform-Aware Multi-Stage Build
```dockerfile
# syntax=docker/dockerfile:1.4
# Multi-architecture Node.js application
FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

# Build arguments for cross-compilation
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Platform-specific dependency installation
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Copy and build application
COPY . .
RUN npm run build

# Production stage - minimal runtime
FROM node:18-alpine

# Security: Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Copy built application
COPY --from=builder --chown=appuser:appuser /app/dist /app
COPY --from=builder --chown=appuser:appuser /app/node_modules /app/node_modules
COPY --chown=appuser:appuser package*.json /app/

USER appuser
WORKDIR /app

# Platform information endpoint
RUN echo '{"platform":"'$(uname -m)'","os":"'$(uname -s)'"}' > platform.json

EXPOSE 3000
CMD ["node", "server.js"]
```

### Go Cross-Compilation Example
```dockerfile
# Cross-compilation optimized Go build
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Cross-compile for target platform
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -a -installsuffix cgo \
    -ldflags="-w -s" \
    -o /app/server .

# Minimal runtime - scratch image
FROM scratch

# Copy CA certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /app/server /server

EXPOSE 8080
ENTRYPOINT ["/server"]
```

## Multi-Platform Build Commands

### Basic Multi-Arch Build
```bash
# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myregistry.com/myapp:latest \
  --push \
  .

# Build with specific output control
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --output type=registry \
  --tag myapp:multi-arch \
  .
```

### Build with Advanced Options
```bash
# Build with cache optimization
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=myregistry.com/myapp:cache \
  --cache-to type=registry,ref=myregistry.com/myapp:cache,mode=max \
  --tag myregistry.com/myapp:v1.0.0 \
  --push \
  .

# Build and load locally (single platform only)
docker buildx build \
  --platform linux/amd64 \
  --load \
  --tag myapp:local \
  .
```

## Platform Verification and Testing

### Multi-Arch Manifest Inspection
```bash
# Inspect multi-architecture manifest
docker buildx imagetools inspect myregistry.com/myapp:latest

# View platform-specific details
docker buildx imagetools inspect myregistry.com/myapp:latest \
  --format "{{json .Manifest}}" | jq '.manifests'
```

### Platform-Specific Testing
```bash
# Test different architectures
platforms=("linux/amd64" "linux/arm64")

for platform in "${platforms[@]}"; do
  echo "Testing $platform..."
  docker run --rm --platform $platform \
    myregistry.com/myapp:latest \
    /bin/sh -c "echo 'Platform: $(uname -m)' && ./health-check.sh"
done
```

## Advanced Multi-Arch Patterns

### Conditional Platform Logic
```dockerfile
# Platform-specific optimizations
FROM node:18-alpine

ARG TARGETARCH

# Install platform-specific packages
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      apk add --no-cache arm64-optimized-lib; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
      apk add --no-cache x86-optimized-lib; \
    fi

# Platform-specific configuration
COPY config-${TARGETARCH}.json /app/config.json

CMD ["npm", "start"]
```

### Build Performance Optimization
```bash
#!/bin/bash
# parallel-build.sh - Build platforms in parallel

# Build AMD64 (fastest, native)
docker buildx build \
  --platform linux/amd64 \
  --tag myapp:amd64 \
  --cache-from type=local,src=cache-amd64 \
  --cache-to type=local,dest=cache-amd64,mode=max \
  . &

# Build ARM64 (emulated, slower)  
docker buildx build \
  --platform linux/arm64 \
  --tag myapp:arm64 \
  --cache-from type=local,src=cache-arm64 \
  --cache-to type=local,dest=cache-arm64,mode=max \
  . &

# Wait for both builds to complete
wait

# Create multi-arch manifest
docker buildx imagetools create \
  --tag myregistry.com/myapp:latest \
  myapp:amd64 \
  myapp:arm64
```

## Practice Tasks

1. **Setup multi-platform builder**:
   ```bash
   docker buildx create --name practice --platform linux/amd64,linux/arm64 --use
   ```

2. **Build simple multi-arch image**:
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 -t test:multi .
   ```

3. **Verify platform support**:
   ```bash
   docker buildx imagetools inspect test:multi
   ```

4. **Test cross-platform execution**:
   ```bash
   docker run --rm --platform linux/arm64 test:multi uname -m
   ```

## Production Considerations

### Platform Selection Strategy
- **AMD64**: Default for most cloud providers, high performance
- **ARM64**: Cost-effective cloud instances (AWS Graviton, Azure ARM)
- **ARMv7**: IoT devices, edge computing, Raspberry Pi
- **Windows**: Windows containers for .NET applications

### Performance Optimization
- Use native builders when possible (ARM64 on ARM64 hosts)
- Implement platform-specific optimizations in code
- Cache builds per platform to avoid unnecessary rebuilds
- Monitor build times and optimize slow architectures

### Registry Management
- Use multi-arch manifests for single tag deployment
- Implement proper tagging strategy (`:latest`, `:v1.0.0`)
- Monitor registry storage usage across platforms
- Clean up unused platform-specific images regularly

## Common Pitfalls

❌ **Forgetting platform arguments**: Missing `ARG TARGETARCH` in Dockerfile  
✅ **Include platform args**: Always declare platform build arguments

❌ **Assuming native performance**: ARM64 emulation is slower than native  
✅ **Plan build times**: Account for emulation overhead in CI/CD

❌ **Platform-specific dependencies**: Hardcoded x86 libraries  
✅ **Conditional dependencies**: Use `TARGETARCH` for platform-specific installs

❌ **Single-platform testing**: Only testing on build platform  
✅ **Multi-platform testing**: Test all target architectures

## Key Takeaway

Multi-architecture builds with Docker Buildx enable true cross-platform container deployment, supporting diverse hardware environments while optimizing for cost and performance across different cloud platforms and edge devices.