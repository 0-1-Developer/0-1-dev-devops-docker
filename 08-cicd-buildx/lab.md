# Phase 08 Lab: CI/CD & Buildx Hands-On

> **Estimated Duration**: 3-4 hours  
> **Difficulty**: Advanced  
> **Prerequisites**: Phases 00-07 completed

## 🧪 Lab Overview

This lab provides intensive hands-on experience with Docker Buildx, multi-architecture builds, and CI/CD pipeline integration. You'll build real-world scenarios that mirror production container delivery workflows.

## 📋 Lab Environment Setup

### Prerequisites Checklist
- [ ] Docker Desktop 4.0+ or Docker Engine 20.10+ installed
- [ ] Git repository access (GitHub/GitLab account)
- [ ] Container registry access (Docker Hub, GitHub Container Registry, or private registry)
- [ ] Basic understanding of CI/CD concepts

### Lab Files Structure
```
lab/
├── apps/
│   ├── webapp/          # Node.js web application
│   ├── api/             # Go REST API
│   └── worker/          # Python background worker  
├── pipelines/
│   ├── github/          # GitHub Actions workflows
│   ├── gitlab/          # GitLab CI configurations
│   └── jenkins/         # Jenkins pipeline scripts
└── configs/
    ├── buildx/          # Buildx configurations
    └── registries/      # Registry configurations
```

## 🏗️ Lab 1: Docker Buildx Setup and Multi-Platform Builds

### Exercise 1.1: Buildx Builder Configuration

#### Setup Multi-Platform Builder
```bash
# Remove default builder if exists
docker buildx rm mybuilder 2>/dev/null || true

# Create advanced multi-platform builder
docker buildx create \
  --name lab-builder \
  --driver docker-container \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --use

# Bootstrap the builder
docker buildx inspect lab-builder --bootstrap

# Verify platform support
docker buildx ls
```

#### Test Platform Availability
```bash
# Check available platforms
docker buildx inspect lab-builder | grep Platforms

# Test simple multi-arch build
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag test:multi-arch \
  - <<EOF
FROM alpine:3.18
RUN echo "Platform: \$(uname -m)" > /platform.txt
CMD cat /platform.txt
EOF
```

### Exercise 1.2: Multi-Architecture Web Application

#### Create Sample Web Application
```bash
mkdir -p lab/apps/webapp
cd lab/apps/webapp
```

**package.json**:
```json
{
  "name": "multi-arch-webapp",
  "version": "1.0.0",
  "description": "Multi-architecture web application demo",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "os": "^0.1.2"
  }
}
```

**server.js**:
```javascript
const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Multi-Architecture Web App',
    platform: os.platform(),
    arch: os.arch(),
    cpus: os.cpus().length,
    hostname: os.hostname(),
    uptime: os.uptime(),
    memory: {
      total: Math.round(os.totalmem() / 1024 / 1024) + ' MB',
      free: Math.round(os.freemem() / 1024 / 1024) + ' MB'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Platform: ${os.platform()} ${os.arch()}`);
});
```

**Dockerfile**:
```dockerfile
# Multi-stage build optimized for multiple architectures
FROM --platform=$BUILDPLATFORM node:18-alpine AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with platform-specific optimizations
RUN npm ci --only=production --no-audit

# Production stage
FROM node:18-alpine

# Security: Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Create app directory with proper ownership
RUN mkdir -p /app && chown -R appuser:appgroup /app

# Copy dependencies from builder stage
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

# Copy application code
COPY --chown=appuser:appgroup package*.json ./
COPY --chown=appuser:appgroup server.js ./

USER appuser
WORKDIR /app

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

EXPOSE 3000
CMD ["npm", "start"]
```

#### Build Multi-Platform Image
```bash
# Build and push multi-architecture image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag $REGISTRY/webapp:multi-arch \
  --push \
  .

# Inspect the multi-arch manifest
docker buildx imagetools inspect $REGISTRY/webapp:multi-arch
```

### Exercise 1.3: Go API with Cross-Compilation

#### Create Go REST API
```bash
mkdir -p lab/apps/api
cd lab/apps/api
```

**go.mod**:
```go
module github.com/lab/api

go 1.21

require (
    github.com/gorilla/mux v1.8.0
)
```

**main.go**:
```go
package main

import (
    "encoding/json"
    "log"
    "net/http"
    "os"
    "runtime"
    "time"

    "github.com/gorilla/mux"
)

type SystemInfo struct {
    OS           string `json:"os"`
    Architecture string `json:"architecture"`
    GoVersion    string `json:"go_version"`
    NumCPU       int    `json:"num_cpu"`
    Hostname     string `json:"hostname"`
    Timestamp    string `json:"timestamp"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "status": "healthy",
        "timestamp": time.Now().UTC().Format(time.RFC3339),
    })
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
    hostname, _ := os.Hostname()
    
    info := SystemInfo{
        OS:           runtime.GOOS,
        Architecture: runtime.GOARCH,
        GoVersion:    runtime.Version(),
        NumCPU:       runtime.NumCPU(),
        Hostname:     hostname,
        Timestamp:    time.Now().UTC().Format(time.RFC3339),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(info)
}

func main() {
    r := mux.NewRouter()
    
    r.HandleFunc("/health", healthHandler).Methods("GET")
    r.HandleFunc("/info", infoHandler).Methods("GET")
    
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    
    log.Printf("Starting server on port %s", port)
    log.Printf("Platform: %s/%s", runtime.GOOS, runtime.GOARCH)
    
    log.Fatal(http.ListenAndServe(":"+port, r))
}
```

**Dockerfile**:
```dockerfile
# Multi-stage Go build with cross-compilation
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

# Build for target platform with optimizations
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -a -installsuffix cgo -ldflags="-w -s" -o api .

# Minimal runtime image
FROM scratch

# Copy CA certificates for HTTPS calls
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary
COPY --from=builder /src/api /api

EXPOSE 8080

# Health check (using minimal wget-like tool)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/api", "-health-check"] || exit 1

ENTRYPOINT ["/api"]
```

#### Build and Test Go API
```bash
# Build multi-platform Go API
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --tag $REGISTRY/api:multi-arch \
  --push \
  .

# Test locally (AMD64)
docker run --rm -p 8080:8080 $REGISTRY/api:multi-arch &
curl http://localhost:8080/info
```

## 🚀 Lab 2: Advanced Caching Strategies

### Exercise 2.1: Cache Mount Implementation

#### Create Cache-Optimized Dockerfile
```dockerfile
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS builder

WORKDIR /app

# Cache npm dependencies globally
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production

# Cache application build artifacts
COPY . .
RUN --mount=type=cache,target=/app/.cache \
    npm run build

# Production stage
FROM nginx:alpine

# Copy build artifacts
COPY --from=builder /app/dist /usr/share/nginx/html

# Custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Test Cache Performance
```bash
# First build (cold cache)
time docker buildx build -t webapp:cache-test .

# Second build (warm cache)  
time docker buildx build -t webapp:cache-test .

# Compare build times
```

### Exercise 2.2: Registry Cache Strategy

#### Build with Registry Cache
```bash
# Build with registry-based cache
docker buildx build \
  --cache-from type=registry,ref=$REGISTRY/webapp:cache \
  --cache-to type=registry,ref=$REGISTRY/webapp:cache,mode=max \
  --platform linux/amd64,linux/arm64 \
  --tag $REGISTRY/webapp:cached \
  --push \
  .
```

#### Local Cache Strategy
```bash
# Create cache directory
mkdir -p /tmp/buildx-cache

# Build with local cache
docker buildx build \
  --cache-from type=local,src=/tmp/buildx-cache \
  --cache-to type=local,dest=/tmp/buildx-cache,mode=max \
  --platform linux/amd64 \
  --tag webapp:local-cache \
  --load \
  .
```

## 🔄 Lab 3: GitHub Actions CI/CD Pipeline

### Exercise 3.1: Complete GitHub Actions Workflow

#### Create Advanced Workflow
**`.github/workflows/build-deploy.yml`**:
```yaml
name: Build and Deploy Multi-Arch Containers

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
  # Job 1: Build and Test
  build:
    runs-on: ubuntu-latest
    outputs:
      image: ${{ steps.image.outputs.image }}
      digest: ${{ steps.build.outputs.digest }}
    
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
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          sbom: true
          provenance: true
          
      - name: Output image
        id: image
        run: echo "image=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}" >> $GITHUB_OUTPUT

  # Job 2: Security Scanning
  security:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name != 'pull_request'
    
    steps:
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ needs.build.outputs.image }}
          format: sarif
          output: trivy-results.sarif
          
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: trivy-results.sarif
          
      - name: Generate SBOM
        uses: anchore/sbom-action@v0
        with:
          image: ${{ needs.build.outputs.image }}
          format: spdx-json
          output-file: sbom.spdx.json
          
      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v3
        with:
          name: sbom
          path: sbom.spdx.json

  # Job 3: Integration Tests
  test:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name != 'pull_request'
    
    strategy:
      matrix:
        platform: [linux/amd64, linux/arm64]
        
    steps:
      - name: Test multi-arch image
        run: |
          docker run --rm --platform ${{ matrix.platform }} \
            ${{ needs.build.outputs.image }} \
            /bin/sh -c "echo 'Testing ${{ matrix.platform }}'"

  # Job 4: Deploy to Staging
  deploy-staging:
    needs: [build, security, test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: staging
    
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying ${{ needs.build.outputs.image }} to staging"
          # Add your deployment logic here

  # Job 5: Deploy to Production
  deploy-production:
    needs: [build, security, test, deploy-staging]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    environment: production
    
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying ${{ needs.build.outputs.image }} to production"
          # Add your deployment logic here
```

### Exercise 3.2: GitLab CI Integration

#### Create GitLab CI Configuration
**`.gitlab-ci.yml`**:
```yaml
# GitLab CI/CD for Multi-Architecture Containers
variables:
  DOCKER_BUILDKIT: 1
  DOCKER_CLI_EXPERIMENTAL: enabled
  BUILDX_VERSION: v0.11.2

stages:
  - prepare
  - build
  - test
  - security
  - deploy

# Prepare buildx
prepare-buildx:
  stage: prepare
  image: docker:24-dind
  services:
    - docker:24-dind
  script:
    - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    - docker buildx create --name cibuilder --use
    - docker buildx inspect --bootstrap
  artifacts:
    expire_in: 1 hour

# Multi-architecture build
build-multi-arch:
  stage: build
  image: docker:24-dind
  services:
    - docker:24-dind
  dependencies:
    - prepare-buildx
  before_script:
    - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
    - docker buildx create --name cibuilder --use 2>/dev/null || true
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

# Security scanning
security-scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --format template --template "@/contrib/sarif.tpl" -o trivy-report.sarif $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      sast: trivy-report.sarif
    expire_in: 1 week
  dependencies:
    - build-multi-arch
  only:
    - main
    - develop

# Integration tests
integration-tests:
  stage: test
  image: docker:24-dind
  services:
    - docker:24-dind
  parallel:
    matrix:
      - PLATFORM: linux/amd64
      - PLATFORM: linux/arm64
  script:
    - docker run --rm --platform $PLATFORM $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA /app/test.sh
  dependencies:
    - build-multi-arch
  only:
    - main
    - develop

# Deploy to staging
deploy-staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - echo "Deploying to staging environment"
    - echo "Image: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
  dependencies:
    - security-scan
    - integration-tests
  only:
    - main

# Deploy to production
deploy-production:
  stage: deploy
  environment:
    name: production
    url: https://production.example.com
  when: manual
  script:
    - echo "Deploying to production environment"
    - echo "Image: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
  dependencies:
    - deploy-staging
  only:
    - main
```

## 🔒 Lab 4: Security and SBOM Integration

### Exercise 4.1: Automated Security Scanning

#### Comprehensive Security Pipeline
```bash
#!/bin/bash
# security-pipeline.sh

IMAGE=$1
if [[ -z "$IMAGE" ]]; then
    echo "Usage: $0 <image>"
    exit 1
fi

echo "🔍 Starting comprehensive security scan for $IMAGE"

# 1. Trivy vulnerability scan
echo "Running Trivy scan..."
trivy image --format json --output trivy-results.json $IMAGE
trivy image --severity HIGH,CRITICAL $IMAGE

# 2. Docker Scout scan
echo "Running Docker Scout scan..."
docker scout cves $IMAGE --format json --output scout-results.json

# 3. Generate SBOM
echo "Generating SBOM..."
syft packages $IMAGE -o spdx-json --file sbom.spdx.json

# 4. Compliance check
echo "Checking compliance..."
grype $IMAGE --fail-on high

# 5. Security summary
echo "📊 Security Summary:"
echo "Trivy results: $(jq '.Results[0].Vulnerabilities | length' trivy-results.json) vulnerabilities found"
echo "SBOM packages: $(jq '.packages | length' sbom.spdx.json) packages cataloged"

echo "✅ Security scan completed"
```

### Exercise 4.2: SBOM Generation and Management

#### Automated SBOM Workflow
```yaml
# .github/workflows/sbom.yml
name: SBOM Generation and Management

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  generate-sbom:
    runs-on: ubuntu-latest
    steps:
      - name: Generate SBOM with Syft
        uses: anchore/sbom-action@v0
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          format: spdx-json
          output-file: sbom.spdx.json
          
      - name: Generate SBOM with Docker Scout
        run: |
          docker scout sbom ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest \
            --format spdx-json \
            --output scout-sbom.spdx.json
            
      - name: Upload SBOM artifacts
        uses: actions/upload-artifact@v3
        with:
          name: sbom-files
          path: |
            sbom.spdx.json
            scout-sbom.spdx.json
            
      - name: Sign SBOM with Cosign
        uses: sigstore/cosign-installer@v3
        
      - name: Sign and attach SBOM
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cosign attach sbom --sbom sbom.spdx.json ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

## 📊 Lab 5: Performance Optimization and Monitoring

### Exercise 5.1: Build Performance Analysis

#### Benchmark Different Build Strategies
```bash
#!/bin/bash
# build-benchmark.sh

ITERATIONS=3
IMAGE_BASE="benchmark-test"

echo "🚀 Docker Build Performance Benchmark"

# Test 1: Standard build
echo "Test 1: Standard Docker build"
for i in $(seq 1 $ITERATIONS); do
    echo "Iteration $i"
    time docker build -t $IMAGE_BASE:standard-$i . 2>&1 | grep real
done

# Test 2: Buildx with cache
echo "Test 2: Buildx with cache"
for i in $(seq 1 $ITERATIONS); do
    echo "Iteration $i"
    time docker buildx build \
        --cache-from type=local,src=/tmp/buildx-cache \
        --cache-to type=local,dest=/tmp/buildx-cache \
        -t $IMAGE_BASE:buildx-$i . 2>&1 | grep real
done

# Test 3: Multi-stage with cache mounts
echo "Test 3: Multi-stage with cache mounts"
for i in $(seq 1 $ITERATIONS); do
    echo "Iteration $i"
    time docker buildx build \
        -f Dockerfile.cache \
        -t $IMAGE_BASE:cache-$i . 2>&1 | grep real
done
```

### Exercise 5.2: Registry Performance Optimization

#### Parallel Push Strategy
```bash
#!/bin/bash
# parallel-push.sh

REGISTRY="your-registry.com"
IMAGE_NAME="multi-arch-app"
TAG="v1.0.0"

# Build all architectures in parallel
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --cache-from type=registry,ref=$REGISTRY/$IMAGE_NAME:cache \
  --cache-to type=registry,ref=$REGISTRY/$IMAGE_NAME:cache,mode=max \
  --tag $REGISTRY/$IMAGE_NAME:$TAG \
  --push \
  .

# Verify multi-arch manifest
docker buildx imagetools inspect $REGISTRY/$IMAGE_NAME:$TAG
```

## 🏆 Lab Validation and Assessment

### Validation Checklist

#### Buildx Configuration
- [ ] Multi-platform builder created and configured
- [ ] Platform support verified (AMD64, ARM64, ARMv7)
- [ ] Builder bootstrapped successfully

#### Multi-Architecture Builds
- [ ] Node.js web application built for multiple platforms
- [ ] Go API cross-compiled successfully
- [ ] Python worker optimized for different architectures
- [ ] All images pushed to registry with multi-arch manifests

#### CI/CD Integration
- [ ] GitHub Actions workflow implemented and tested
- [ ] GitLab CI pipeline configured and validated
- [ ] Build caching strategy optimized
- [ ] Security scanning integrated

#### Security and Compliance
- [ ] Vulnerability scanning automated
- [ ] SBOM generation implemented
- [ ] Image signing configured
- [ ] Compliance checks passing

#### Performance Optimization
- [ ] Build times measured and optimized
- [ ] Cache strategies implemented
- [ ] Registry operations optimized
- [ ] Performance benchmarks documented

### Assessment Criteria

| Component | Excellent (90-100%) | Good (80-89%) | Satisfactory (70-79%) | Needs Improvement (<70%) |
|-----------|-------------------|---------------|----------------------|------------------------|
| **Buildx Setup** | Multi-platform builder with all target architectures | Basic multi-platform support | Single additional platform | Default builder only |
| **Multi-Arch Builds** | All apps built for 3+ platforms | 2-3 applications multi-arch | 1-2 applications multi-arch | Single architecture only |
| **CI/CD Integration** | Full pipeline with all stages | Basic build and test pipeline | Simple build automation | Manual build process |
| **Security** | Comprehensive scanning + SBOM + signing | Vulnerability scanning + SBOM | Basic vulnerability scanning | No security measures |
| **Performance** | Optimized caching + benchmarking | Good caching strategy | Basic caching | No optimization |

## 📚 Additional Resources and Challenges

### Advanced Challenges

#### Challenge 1: Custom Builder Driver
```bash
# Create Kubernetes-based builder
docker buildx create \
  --name k8s-builder \
  --driver kubernetes \
  --platform linux/amd64,linux/arm64
```

#### Challenge 2: BuildKit Frontend
```dockerfile
# syntax=docker/dockerfile:1.4
# Custom BuildKit frontend usage
FROM scratch AS custom-frontend
# Implementation details...
```

#### Challenge 3: Remote Cache Optimization
```bash
# S3-based remote cache
docker buildx build \
  --cache-from type=s3,region=us-west-2,bucket=build-cache \
  --cache-to type=s3,region=us-west-2,bucket=build-cache,mode=max \
  .
```

### Troubleshooting Guide

#### Common Issues and Solutions

**Issue**: Platform not supported
```bash
# Solution: Update builder configuration
docker buildx rm mybuilder
docker buildx create --name mybuilder --platform linux/amd64,linux/arm64 --use
```

**Issue**: Cache not working effectively
```bash
# Solution: Verify cache configuration
docker buildx build --cache-from type=registry,ref=... --progress=plain .
```

**Issue**: QEMU emulation slow
```bash
# Solution: Use native builders when possible
docker buildx create --name native-arm64 --platform linux/arm64 tcp://arm64-host:2376
```

## 🎯 Lab Summary

Upon completing this lab, you have:

1. **Configured advanced Docker Buildx environments** with multi-platform support
2. **Built production-ready multi-architecture applications** using best practices
3. **Implemented comprehensive CI/CD pipelines** with security and compliance
4. **Optimized build performance** using advanced caching strategies
5. **Integrated security scanning and SBOM generation** for supply chain security

These skills enable you to build and deploy containerized applications that work seamlessly across different architectures and cloud platforms, with robust automation and security measures in place.

---

💡 **Next Steps**: Apply these techniques to your own projects and explore advanced BuildKit features like custom frontends and distributed building capabilities.