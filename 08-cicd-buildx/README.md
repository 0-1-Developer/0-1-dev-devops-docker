# Phase 08: CI/CD & Buildx

> **Focus**: Build automation, multi-architecture images, and CI/CD integration  
> **Complexity**: Advanced  
> **Duration**: 4-6 hours

## 🎯 Learning Objectives

By the end of this phase, you will:

- **Master Docker Buildx** for advanced build scenarios and multi-platform images
- **Implement CI/CD pipelines** with automated Docker builds and deployments
- **Create multi-architecture images** supporting AMD64, ARM64, and other platforms
- **Optimize build performance** using advanced caching strategies and parallel builds
- **Integrate container registries** with automated publishing and management
- **Generate Software Bill of Materials (SBOM)** for supply chain security and compliance

## 🏗️ Architecture Overview

CI/CD with Docker Buildx enables:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Source Code   │────│  CI/CD Pipeline  │────│   Container     │
│   Repository    │    │                  │    │   Registry      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
            ┌───────▼──┐  ┌─────▼────┐  ┌──▼─────┐
            │ Multi-   │  │ Advanced │  │ SBOM & │
            │ Arch     │  │ Caching  │  │ Security│
            │ Builds   │  │ Strategy │  │ Scanning│
            └──────────┘  └──────────┘  └────────┘
```

## 📚 Conceptual Foundation

### Docker Buildx Fundamentals

**Docker Buildx** is an extended build interface that provides:
- **Multi-platform builds** - Single command builds for multiple architectures
- **Advanced BuildKit features** - Enhanced caching, secrets, SSH agent forwarding
- **Build drivers** - Local, Docker container, Kubernetes, and remote builders
- **Output formats** - Images, tarballs, local directories, registries

### CI/CD Integration Patterns

**Continuous Integration/Continuous Deployment** with containers:
- **Build automation** - Triggered builds on code changes
- **Testing integration** - Unit, integration, and security testing
- **Registry publishing** - Automated image versioning and distribution
- **Deployment automation** - Environment-specific container deployments

### Multi-Architecture Support

**Cross-platform containers** enable:
- **Developer flexibility** - Support ARM Macs, AMD64 servers, ARM IoT devices
- **Cloud optimization** - AWS Graviton, Azure ARM, Google Cloud ARM instances
- **Edge deployment** - Raspberry Pi, NVIDIA Jetson, mobile edge computing
- **Cost optimization** - ARM instances often provide better price/performance

## 🔧 Docker Buildx Setup

### Buildx Installation and Configuration

#### Initialize Buildx Builder
```bash
# Create and use a new builder instance
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

# List available builders
docker buildx ls

# Check supported platforms
docker buildx inspect mybuilder
```

#### Multi-Platform Builder Setup
```bash
# Create builder with specific platforms
docker buildx create \
  --name multiplatform \
  --driver docker-container \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --use

# Enable experimental Docker CLI features
export DOCKER_CLI_EXPERIMENTAL=enabled

# Verify multi-platform capability
docker buildx inspect multiplatform --bootstrap
```

## 🏗️ Multi-Architecture Builds

### Basic Multi-Platform Build

#### Simple Multi-Arch Dockerfile
```dockerfile
# Multi-architecture compatible base image
FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

# Build arguments for cross-compilation
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Install dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application (platform-specific if needed)
RUN npm run build

# Production stage
FROM node:18-alpine

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Copy built application
COPY --from=builder --chown=appuser:appgroup /app /app

USER appuser
WORKDIR /app

EXPOSE 3000
CMD ["node", "server.js"]
```

#### Multi-Platform Build Commands
```bash
# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag myregistry.com/myapp:latest \
  --push \
  .

# Build with specific output
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --output type=registry \
  --tag myapp:multi-arch \
  .

# Build and export to local Docker
docker buildx build \
  --platform linux/amd64 \
  --load \
  --tag myapp:local \
  .
```

### Advanced Cross-Compilation

#### Go Application Multi-Arch Build
```dockerfile
# Multi-stage build for Go application
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build for target platform
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -a -installsuffix cgo -o app .

# Minimal runtime image
FROM scratch

# Copy CA certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /src/app /app

EXPOSE 8080
ENTRYPOINT ["/app"]
```

#### Python Application with Native Dependencies
```dockerfile
# Python multi-arch with native dependencies
FROM --platform=$BUILDPLATFORM python:3.11-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    libffi-dev \
    musl-dev

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Production stage
FROM python:3.11-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    libffi \
    musl

# Create non-root user
RUN adduser -D -u 1001 appuser

# Copy wheels and install
COPY --from=builder /app/wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache /wheels/*

# Copy application
COPY --chown=appuser:appuser . /app

USER appuser
WORKDIR /app

CMD ["python", "app.py"]
```

## 🚀 Advanced Caching Strategies

### Build Cache Optimization

#### Cache Mount Strategy
```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Cache npm dependencies
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Cache application build
COPY . .
RUN --mount=type=cache,target=/app/.next/cache \
    npm run build

# Production stage with minimal layers
FROM node:18-alpine
COPY --from=builder /app /app
WORKDIR /app
CMD ["npm", "start"]
```

#### Registry Cache Configuration
```bash
# Build with registry cache
docker buildx build \
  --cache-from type=registry,ref=myregistry.com/myapp:cache \
  --cache-to type=registry,ref=myregistry.com/myapp:cache,mode=max \
  --platform linux/amd64,linux/arm64 \
  --tag myregistry.com/myapp:latest \
  --push \
  .
```

#### Local Cache with BuildKit
```bash
# Build with local cache
docker buildx build \
  --cache-from type=local,src=/tmp/buildx-cache \
  --cache-to type=local,dest=/tmp/buildx-cache,mode=max \
  --platform linux/amd64,linux/arm64 \
  --tag myapp:cached \
  .
```

## 🔄 CI/CD Pipeline Integration

### GitHub Actions Integration

#### Complete GitHub Actions Workflow
```yaml
# .github/workflows/docker-build.yml
name: Docker Build and Deploy

on:
  push:
    branches: [main, develop]
    tags: ['v*.*.*']
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      security-events: write
      
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          platforms: linux/amd64,linux/arm64
          
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
            
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          
      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          format: spdx-json
          
      - name: Security scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          format: sarif
          output: trivy-results.sarif
          
      - name: Upload security results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: trivy-results.sarif
```

#### Multi-Environment Deployment
```yaml
# .github/workflows/deploy.yml
name: Deploy to Environments

on:
  workflow_run:
    workflows: ["Docker Build and Deploy"]
    branches: [main]
    types: [completed]

jobs:
  deploy-staging:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying to staging environment"
          # Add deployment logic here
          
  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying to production environment"
          # Add deployment logic here
```

### GitLab CI Integration

#### .gitlab-ci.yml Configuration
```yaml
# .gitlab-ci.yml
variables:
  DOCKER_BUILDKIT: 1
  BUILDX_VERSION: v0.11.2
  
stages:
  - build
  - test
  - security
  - deploy

.docker-buildx: &docker-buildx
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    - docker buildx create --name mybuilder --use
    - docker buildx inspect --bootstrap
    - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY

build:
  <<: *docker-buildx
  stage: build
  script:
    - |
      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --cache-from type=registry,ref=$CI_REGISTRY_IMAGE:cache \
        --cache-to type=registry,ref=$CI_REGISTRY_IMAGE:cache,mode=max \
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA \
        --tag $CI_REGISTRY_IMAGE:latest \
        --push \
        .
  only:
    - main
    - develop

security-scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --format template --template "@/contrib/sarif.tpl" -o trivy-report.sarif $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      sast: trivy-report.sarif
  only:
    - main
    - develop

deploy-staging:
  stage: deploy
  environment:
    name: staging
  script:
    - echo "Deploying to staging"
    # Add staging deployment logic
  only:
    - main

deploy-production:
  stage: deploy
  environment:
    name: production
  when: manual
  script:
    - echo "Deploying to production"
    # Add production deployment logic
  only:
    - main
```

## 🔒 Security and Compliance

### SBOM Generation

#### Automated SBOM Creation
```bash
# Generate SBOM during build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --sbom=true \
  --tag myapp:with-sbom \
  .

# Extract SBOM from image
docker buildx imagetools inspect myapp:with-sbom --format "{{ json .SBOM }}"

# Use external SBOM tools
syft packages myapp:latest -o spdx-json > myapp-sbom.spdx.json
```

#### SBOM Integration in CI/CD
```yaml
# SBOM generation step in GitHub Actions
- name: Generate and upload SBOM
  uses: anchore/sbom-action@v0
  with:
    image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    format: spdx-json
    output-file: sbom.spdx.json
    upload-artifact: true
    upload-release-assets: true
```

## 📊 Monitoring and Observability

### Build Metrics and Analytics

#### Build Performance Monitoring
```bash
# Enable BuildKit metrics
export BUILDKIT_PROGRESS=plain

# Build with timing information
time docker buildx build \
  --progress=plain \
  --platform linux/amd64,linux/arm64 \
  --tag myapp:monitored \
  .
```

#### Registry Analytics
```bash
# Image size analysis
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep myapp

# Multi-arch manifest inspection
docker buildx imagetools inspect myregistry.com/myapp:latest
```

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Set up and configure Docker Buildx for multi-platform builds
- [ ] Create Dockerfiles optimized for cross-compilation and multiple architectures  
- [ ] Implement advanced caching strategies for faster build times
- [ ] Design and deploy CI/CD pipelines with automated Docker builds
- [ ] Generate and manage Software Bill of Materials (SBOM) for compliance
- [ ] Integrate security scanning and vulnerability management in build pipelines
- [ ] Deploy multi-architecture images to container registries
- [ ] Monitor and optimize build performance across different platforms

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p08-m01-l01` - Multi-arch Builds
- `p08-m01-l02` - Cache Strategies  
- `p08-m01-l03` - Registry Publishing
- `p08-m01-l04` - SBOM Generation

## 🎯 What's Next

After mastering CI/CD & Buildx:

→ **Phase 09**: Registries - Private registry setup, authentication, and management  
→ **Phase 10**: Observability - Logging, monitoring, and performance optimization  
→ **Phase 11**: Advanced Images - Distroless, static linking, and minimal containers

---

💡 **Key Insight**: Docker Buildx and CI/CD integration enable scalable, secure, multi-platform container delivery pipelines that support modern cloud-native development workflows.