# Phase 11 Lab: Advanced Docker Images Hands-on Exercises

> **Objective**: Gain practical experience with advanced Docker image construction techniques including distroless images, static linking, debug variants, and CVE minimization.

## Lab Overview

This lab provides hands-on experience with:
- Building minimal distroless images with zero OS dependencies
- Creating statically linked binaries for maximum portability
- Implementing debug variants without compromising production security
- Applying CVE minimization and vulnerability management strategies
- Multi-architecture builds and image signing
- Advanced Dockerfile patterns and optimization techniques

## Prerequisites

- Docker Engine 24.0+
- Docker Buildx with multi-platform support
- Basic understanding of application build processes
- Text editor for Dockerfile creation
- Internet connection for base image downloads

## Lab Environment Setup

### Initial Setup Script
```bash
#!/bin/bash
# setup-advanced-images-lab.sh

# Create lab directory structure
mkdir -p ~/docker-advanced-images-lab/{go-app,python-app,node-app,rust-app,examples}
cd ~/docker-advanced-images-lab

# Install additional tools
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y curl wget jq
elif command -v yum &> /dev/null; then
    sudo yum install -y curl wget jq
elif command -v apk &> /dev/null; then
    apk add --no-cache curl wget jq
fi

# Install vulnerability scanner
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Install Cosign for image signing
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Install Syft for SBOM generation
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

echo "✅ Lab environment initialized"
echo "📁 Working directory: $(pwd)"
echo "🔧 Tools installed: Docker, Trivy, Cosign, Syft"
```

---

## Exercise 1: Distroless Images Implementation

### Objectives
- Build traditional vs distroless images
- Compare image sizes and vulnerability profiles
- Implement multi-stage distroless builds
- Test runtime behavior and debugging options

### Step 1: Traditional vs Distroless Python Application

```python
# python-app/app.py
import http.server
import socketserver
import json
import os
from datetime import datetime

class HealthHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {
                'status': 'healthy',
                'timestamp': datetime.utcnow().isoformat(),
                'version': os.environ.get('APP_VERSION', '1.0.0'),
                'python_version': os.sys.version,
                'distroless': os.environ.get('DISTROLESS', 'false') == 'true'
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            super().do_GET()

if __name__ == "__main__":
    PORT = int(os.environ.get('PORT', 8080))
    
    with socketserver.TCPServer(("", PORT), HealthHandler) as httpd:
        print(f"Server running on port {PORT}")
        httpd.serve_forever()
```

```text
# python-app/requirements.txt
requests==2.31.0
```

### Step 2: Traditional Docker Build

```dockerfile
# python-app/Dockerfile.traditional
FROM python:3.11

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

ENV APP_VERSION=1.0.0
ENV DISTROLESS=false

EXPOSE 8080
CMD ["python", "app.py"]
```

### Step 3: Distroless Docker Build

```dockerfile
# python-app/Dockerfile.distroless
FROM python:3.11-slim AS build

WORKDIR /app

# Install dependencies in user directory
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Second stage: distroless
FROM gcr.io/distroless/python3-debian11:latest

WORKDIR /app

# Copy Python packages from build stage
COPY --from=build /root/.local /root/.local

# Copy application
COPY app.py .

# Set environment variables
ENV PATH=/root/.local/bin:$PATH
ENV APP_VERSION=1.0.0
ENV DISTROLESS=true

# Use non-root user
USER nonroot

EXPOSE 8080
CMD ["app.py"]
```

### Step 4: Build and Compare Images

```bash
cd python-app

# Build traditional image
docker build -f Dockerfile.traditional -t python-app:traditional .

# Build distroless image
docker build -f Dockerfile.distroless -t python-app:distroless .

# Compare image sizes
echo "Image Size Comparison:"
echo "====================="
docker images | grep python-app

# Scan for vulnerabilities
echo -e "\nVulnerability Scan Results:"
echo "============================"
echo "Traditional image vulnerabilities:"
trivy image --severity HIGH,CRITICAL python-app:traditional | grep Total

echo "Distroless image vulnerabilities:"
trivy image --severity HIGH,CRITICAL python-app:distroless | grep Total

# Test both images
echo -e "\nTesting Traditional Image:"
docker run -d --name python-traditional -p 8080:8080 python-app:traditional
sleep 3
curl http://localhost:8080/health | jq .
docker stop python-traditional && docker rm python-traditional

echo -e "\nTesting Distroless Image:"
docker run -d --name python-distroless -p 8081:8080 python-app:distroless
sleep 3
curl http://localhost:8081/health | jq .
docker stop python-distroless && docker rm python-distroless
```

### Step 5: Debug Variant Implementation

```dockerfile
# python-app/Dockerfile.debug
FROM python:3.11-slim AS build

WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production target
FROM gcr.io/distroless/python3-debian11:latest AS production
WORKDIR /app
COPY --from=build /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
USER nonroot
CMD ["app.py"]

# Debug target with shell access
FROM gcr.io/distroless/python3-debian11:debug AS debug
WORKDIR /app
COPY --from=build /root/.local /root/.local
COPY app.py .

# Create symbolic links for debugging tools
RUN ["/busybox/sh", "-c", "mkdir -p /bin && for cmd in sh ps netstat ss curl; do ln -s /busybox/$cmd /bin/$cmd; done"]

ENV PATH=/root/.local/bin:$PATH
USER nonroot
CMD ["app.py"]
```

### Verification
```bash
# Build debug variant
docker build --target production -t python-app:prod -f Dockerfile.debug .
docker build --target debug -t python-app:debug -f Dockerfile.debug .

# Test debug access
docker run -it --rm python-app:debug /bin/sh

# Compare sizes
docker images | grep python-app
```

---

## Exercise 2: Static Linking and Minimal Binaries

### Objectives
- Create statically linked Go binaries
- Build Rust applications with musl
- Implement C++ static builds
- Compare binary sizes and dependencies

### Step 1: Go Static Binary Implementation

```go
// go-app/main.go
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "runtime"
    "time"
)

type HealthResponse struct {
    Status      string    `json:"status"`
    Timestamp   time.Time `json:"timestamp"`
    Version     string    `json:"version"`
    GoVersion   string    `json:"go_version"`
    Platform    string    `json:"platform"`
    StaticBuild bool      `json:"static_build"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    
    response := HealthResponse{
        Status:      "healthy",
        Timestamp:   time.Now().UTC(),
        Version:     getEnv("APP_VERSION", "1.0.0"),
        GoVersion:   runtime.Version(),
        Platform:    runtime.GOOS + "/" + runtime.GOARCH,
        StaticBuild: getEnv("STATIC_BUILD", "false") == "true",
    }
    
    json.NewEncoder(w).Encode(response)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func main() {
    port := getEnv("PORT", "8080")
    
    http.HandleFunc("/health", healthHandler)
    
    log.Printf("Server starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
```

```go
// go-app/go.mod
module go-app

go 1.21
```

### Step 2: Static Binary Dockerfile

```dockerfile
# go-app/Dockerfile.static
FROM golang:1.21-alpine AS build

# Install certificates and git
RUN apk add --no-cache ca-certificates git

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary with all optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a -installsuffix cgo \
    -ldflags='-w -s -extldflags "-static"' \
    -tags 'osusergo netgo static_build' \
    -o app main.go

# Verify it's static
RUN file app
RUN ldd app || echo "Static binary - no dynamic links"

# Final stage - scratch image
FROM scratch

# Copy CA certificates for HTTPS calls
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy timezone data if needed
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

# Copy passwd file for user information
COPY --from=build /etc/passwd /etc/passwd

# Copy the static binary
COPY --from=build /build/app /app

# Use nobody user
USER nobody

ENV STATIC_BUILD=true
ENV APP_VERSION=1.0.0

ENTRYPOINT ["/app"]
```

### Step 3: Rust Static Binary

```rust
// rust-app/src/main.rs
use serde_json::json;
use std::env;
use warp::Filter;

#[tokio::main]
async fn main() {
    let port: u16 = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .expect("PORT must be a number");

    let health = warp::path("health")
        .map(|| {
            let response = json!({
                "status": "healthy",
                "timestamp": chrono::Utc::now(),
                "version": env::var("APP_VERSION").unwrap_or_else(|_| "1.0.0".to_string()),
                "rust_version": env!("RUSTC_VERSION"),
                "static_build": env::var("STATIC_BUILD").unwrap_or_else(|_| "false".to_string()) == "true"
            });
            warp::reply::json(&response)
        });

    println!("Server starting on port {}", port);
    warp::serve(health)
        .run(([0, 0, 0, 0], port))
        .await;
}
```

```toml
# rust-app/Cargo.toml
[package]
name = "rust-app"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1.35", features = ["full"] }
warp = "0.3"
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
```

### Step 4: Rust Static Dockerfile

```dockerfile
# rust-app/Dockerfile.static
FROM rust:1.75-slim AS build

WORKDIR /app

# Install musl for static linking
RUN apt-get update && apt-get install -y musl-tools pkg-config libssl-dev
RUN rustup target add x86_64-unknown-linux-musl

# Copy manifest files
COPY Cargo.toml Cargo.lock ./

# Create dummy source to cache dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release --target x86_64-unknown-linux-musl
RUN rm -f target/x86_64-unknown-linux-musl/release/deps/rust_app*

# Build real application
COPY src ./src
RUN cargo build --release --target x86_64-unknown-linux-musl

# Verify static binary
RUN file target/x86_64-unknown-linux-musl/release/rust-app
RUN ldd target/x86_64-unknown-linux-musl/release/rust-app || echo "Static binary"

FROM scratch

COPY --from=build /app/target/x86_64-unknown-linux-musl/release/rust-app /

ENV STATIC_BUILD=true
ENV APP_VERSION=1.0.0

USER 1000

ENTRYPOINT ["/rust-app"]
```

### Step 5: Build and Compare Static Binaries

```bash
# Build Go static binary
cd go-app
docker build -f Dockerfile.static -t go-app:static .

# Build Rust static binary
cd ../rust-app
docker build -f Dockerfile.static -t rust-app:static .

# Compare image sizes
echo "Static Binary Image Sizes:"
echo "=========================="
docker images | grep -E "(go-app|rust-app)"

# Test static binaries
echo -e "\nTesting Go Static Binary:"
docker run -d --name go-static -p 8080:8080 go-app:static
sleep 3
curl http://localhost:8080/health | jq .
docker stop go-static && docker rm go-static

echo -e "\nTesting Rust Static Binary:"
docker run -d --name rust-static -p 8081:8080 rust-app:static
sleep 3
curl http://localhost:8081/health | jq .
docker stop rust-static && docker rm rust-static

# Analyze binary sizes
echo -e "\nBinary Analysis:"
echo "================"
docker run --rm go-app:static sh -c "ls -lh /app"
docker run --rm rust-app:static sh -c "ls -lh /rust-app"
```

---

## Exercise 3: CVE Minimization and Security Scanning

### Objectives
- Implement vulnerability scanning in build pipelines
- Compare CVE counts across different base images
- Apply security hardening techniques
- Generate and manage Software Bill of Materials (SBOM)

### Step 1: Vulnerability-Aware Node.js Application

```javascript
// node-app/index.js
const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || '1.0.0',
        node_version: process.version,
        platform: process.platform + '/' + process.arch,
        distroless: process.env.DISTROLESS === 'true',
        vulnerabilities_scanned: process.env.VULN_SCANNED === 'true'
    });
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
```

```json
{
  "name": "node-app",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "express": "4.18.2"
  },
  "scripts": {
    "start": "node index.js"
  }
}
```

### Step 2: Security-Focused Multi-Stage Dockerfile

```dockerfile
# node-app/Dockerfile.secure
# Use specific SHA for reproducible builds
FROM node:18.19.0-alpine3.18@sha256:435dcad253bb5b7f347ebc69c8cc52de7c912eb7241098b920f2fc2d7843183d AS build

WORKDIR /app

# Install security scanning tools
RUN apk add --no-cache curl
RUN curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Copy package files
COPY package*.json ./

# Install dependencies with audit
RUN npm ci --only=production && \
    npm audit --audit-level=high && \
    npm cache clean --force

# Scan dependencies
RUN trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress .

# Generate SBOM
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
RUN syft packages . -o spdx-json > /app.spdx.json

# Copy application code
COPY index.js ./

# Production stage with distroless
FROM gcr.io/distroless/nodejs18-debian11:latest

WORKDIR /app

# Copy dependencies and application
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/index.js ./

# Copy SBOM
COPY --from=build /app.spdx.json /sbom/

# Add labels for security metadata
LABEL org.opencontainers.image.sbom="/sbom/app.spdx.json"
LABEL org.opencontainers.image.source="https://github.com/example/node-app"
LABEL org.opencontainers.image.vulnerability.scanned="true"

ENV APP_VERSION=1.0.0
ENV DISTROLESS=true
ENV VULN_SCANNED=true

USER nonroot

CMD ["index.js"]
```

### Step 3: CVE Comparison Script

```bash
#!/bin/bash
# cve-comparison.sh

echo "🔒 CVE Minimization Analysis"
echo "============================"

# Test different base images for comparison
BASE_IMAGES=(
    "node:18"
    "node:18-slim"  
    "node:18-alpine"
    "gcr.io/distroless/nodejs18-debian11:latest"
)

cd node-app

for base in "${BASE_IMAGES[@]}"; do
    echo -e "\nAnalyzing base image: $base"
    echo "$(printf '=%.0s' {1..50})"
    
    # Create temporary Dockerfile for testing
    cat > Dockerfile.temp <<EOF
FROM $base
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production 2>/dev/null || npm install --only=production
COPY index.js ./
CMD ["node", "index.js"]
EOF
    
    # Build test image
    docker build -f Dockerfile.temp -t test-image:latest . >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Get image size
        SIZE=$(docker images test-image:latest --format "{{.Size}}")
        echo "Image Size: $SIZE"
        
        # Scan for vulnerabilities
        VULN_COUNT=$(trivy image --quiet --format json test-image:latest | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH" or .Severity=="CRITICAL")] | length')
        echo "High/Critical CVEs: $VULN_COUNT"
        
        # Clean up
        docker rmi test-image:latest >/dev/null 2>&1
    else
        echo "Build failed for $base"
    fi
    
    rm -f Dockerfile.temp
done

echo -e "\n✅ CVE analysis complete"
```

### Step 4: SBOM Generation and Analysis

```bash
#!/bin/bash
# sbom-analysis.sh

echo "📋 SBOM Generation and Analysis"
echo "==============================="

# Build secure image
docker build -f Dockerfile.secure -t node-app:secure .

# Extract SBOM from image
docker run --rm node-app:secure cat /sbom/app.spdx.json > node-app-sbom.spdx.json

# Analyze SBOM
echo "SBOM Analysis:"
echo "=============="
TOTAL_PACKAGES=$(jq '.packages | length' node-app-sbom.spdx.json)
echo "Total packages: $TOTAL_PACKAGES"

echo -e "\nTop 10 packages by name:"
jq -r '.packages[] | .name' node-app-sbom.spdx.json | head -10

# Generate vulnerability report from SBOM
echo -e "\nScanning SBOM for vulnerabilities..."
trivy sbom node-app-sbom.spdx.json --severity HIGH,CRITICAL

# Create package inventory
echo -e "\nCreating package inventory..."
jq -r '.packages[] | "\(.name)@\(.versionInfo // "unknown")"' node-app-sbom.spdx.json | \
    sort > package-inventory.txt

echo "Package inventory saved to package-inventory.txt"
```

### Step 5: Security Policy Implementation

```dockerfile
# node-app/Dockerfile.hardened
FROM node:18-alpine AS build

# Security: Update all packages
RUN apk update && apk upgrade

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with security audit
RUN npm ci --only=production && \
    npm audit --audit-level=moderate && \
    npm cache clean --force

# Security: Remove npm (not needed in production)
RUN npm uninstall -g npm

FROM gcr.io/distroless/nodejs18-debian11:latest

WORKDIR /app

# Copy only necessary files
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY index.js ./

# Security: Run as non-root user
USER nonroot

# Security: Use read-only root filesystem (requires external volume for logs)
# Add this when running: --read-only --tmpfs /tmp

# Security: Drop all capabilities (done by distroless by default)

# Security: Set resource limits (done at runtime with --memory --cpus)

# Security: Add security labels
LABEL security.scan.date="$(date -Iseconds)"
LABEL security.base.image="gcr.io/distroless/nodejs18-debian11"
LABEL security.non-root="true"
LABEL security.read-only="supported"

ENV NODE_ENV=production
ENV APP_VERSION=1.0.0

CMD ["index.js"]
```

### Verification
```bash
# Run CVE comparison
chmod +x cve-comparison.sh
./cve-comparison.sh

# Run SBOM analysis
chmod +x sbom-analysis.sh
./sbom-analysis.sh

# Test secure image
docker build -f Dockerfile.secure -t node-app:secure .
docker run -d --name node-secure -p 8080:8080 node-app:secure
curl http://localhost:8080/health | jq .
docker stop node-secure && docker rm node-secure
```

---

## Exercise 4: Multi-Architecture and Advanced Build Patterns

### Objectives
- Build multi-architecture images
- Implement advanced Dockerfile patterns
- Use build arguments and target selection
- Apply cache optimization techniques

### Step 1: Multi-Architecture Go Application

```dockerfile
# examples/Dockerfile.multiarch
# syntax=docker/dockerfile:1.6
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN echo "Building on $BUILDPLATFORM, targeting $TARGETPLATFORM"

WORKDIR /app

# Cache Go modules
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Cross-compile for target platform
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build \
    -ldflags="-w -s -X main.platform=$TARGETOS/$TARGETARCH" \
    -o app main.go

# Verify binary architecture
RUN file app

FROM gcr.io/distroless/static-debian11:latest

COPY --from=build /app/app /

USER nonroot
ENTRYPOINT ["/app"]
```

### Step 2: Advanced Build Script

```bash
#!/bin/bash
# multi-arch-build.sh

echo "🏗️  Multi-Architecture Build"
echo "============================"

# Set up buildx if not already configured
docker buildx create --use --name multiarch-builder 2>/dev/null || true

# Build for multiple architectures
PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7"
IMAGE_NAME="examples/multiarch-app"
TAG="v1.0.0"

echo "Building for platforms: $PLATFORMS"

cd examples

# Build and push multi-arch image
docker buildx build \
    --platform $PLATFORMS \
    --file Dockerfile.multiarch \
    --tag $IMAGE_NAME:$TAG \
    --tag $IMAGE_NAME:latest \
    --push \
    .

# Inspect manifest
echo -e "\nInspecting multi-arch manifest:"
docker buildx imagetools inspect $IMAGE_NAME:$TAG

echo "✅ Multi-architecture build complete"
```

### Step 3: Advanced Dockerfile with Heredoc and Mounts

```dockerfile
# examples/Dockerfile.advanced
# syntax=docker/dockerfile:1.6
FROM alpine:3.18 AS base

# Use heredoc for complex setup script
RUN <<EOF
set -ex

# Update and install packages
apk update
apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    jq

# Create application user and directories
addgroup -g 1001 appgroup
adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# Setup directories with proper permissions
mkdir -p /app/{bin,config,logs,data}
chown -R appuser:appgroup /app
chmod 755 /app

# Cleanup
rm -rf /var/cache/apk/*
EOF

FROM golang:1.21-alpine AS build

WORKDIR /build

# Use cache mount for Go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=bind,source=go.mod,target=go.mod \
    --mount=type=bind,source=go.sum,target=go.sum \
    go mod download

# Build with cache mounts
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=bind,source=.,target=. \
    CGO_ENABLED=0 go build -o /app/binary main.go

# Use secret mount for private keys (example)
RUN --mount=type=secret,id=signing-key \
    echo "Would sign binary with key from /run/secrets/signing-key" && \
    ls -la /run/secrets/ || echo "No secrets mounted"

FROM base AS final

WORKDIR /app

# Copy binary from build stage
COPY --from=build /app/binary ./bin/

# Copy configuration files
COPY --chown=appuser:appgroup config/ ./config/

USER appuser

ENTRYPOINT ["./bin/binary"]
```

### Step 4: Build Args and Target Selection

```dockerfile
# examples/Dockerfile.flexible
ARG BUILD_ENV=production
ARG GO_VERSION=1.21
ARG APP_VERSION=1.0.0

FROM golang:${GO_VERSION}-alpine AS base

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Development target
FROM base AS development
RUN apk add --no-cache git curl vim
RUN go build -gcflags="all=-N -l" -o app main.go
USER 1000
ENTRYPOINT ["./app"]

# Testing target
FROM base AS testing
RUN apk add --no-cache git
RUN go test ./...
RUN go build -race -o app main.go
USER 1000
ENTRYPOINT ["./app"]

# Production target (default)
FROM base AS production
RUN CGO_ENABLED=0 go build \
    -ldflags="-w -s -X main.version=${APP_VERSION} -X main.env=${BUILD_ENV}" \
    -o app main.go

FROM gcr.io/distroless/static-debian11:latest AS final
COPY --from=production /app/app /
USER nonroot
ENTRYPOINT ["/app"]
```

### Step 5: Performance Optimization Patterns

```dockerfile
# examples/Dockerfile.optimized
FROM node:18-alpine AS dependencies

WORKDIR /app

# Install only production dependencies
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force && \
    rm -rf ~/.npm

FROM node:18-alpine AS build

WORKDIR /app

# Install all dependencies for building
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build && \
    npm prune --production

FROM gcr.io/distroless/nodejs18-debian11:latest AS final

WORKDIR /app

# Copy only what's needed for runtime
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package*.json ./

# Security and performance labels
LABEL build.optimization="true" \
      build.stage="production" \
      security.distroless="true"

USER nonroot

CMD ["dist/index.js"]
```

### Verification
```bash
# Build different targets
docker build --target development -t app:dev -f Dockerfile.flexible .
docker build --target testing -t app:test -f Dockerfile.flexible .
docker build --target final -t app:prod -f Dockerfile.flexible .

# Build with build args
docker build \
    --build-arg BUILD_ENV=staging \
    --build-arg APP_VERSION=2.0.0 \
    --target final \
    -t app:staging \
    -f Dockerfile.flexible .

# Compare image sizes
docker images | grep app:

# Test advanced patterns
docker build -f Dockerfile.advanced -t app:advanced .
docker build -f Dockerfile.optimized -t app:optimized .
```

---

## Exercise 5: Image Signing and Supply Chain Security

### Objectives
- Sign container images with Cosign
- Implement SBOM attestation
- Verify image signatures
- Create secure CI/CD pipeline

### Step 1: Image Signing Setup

```bash
#!/bin/bash
# setup-signing.sh

echo "🔐 Setting up Image Signing"
echo "============================"

# Generate signing key pair
export COSIGN_EXPERIMENTAL=1
cosign generate-key-pair

echo "✅ Key pair generated"
echo "Private key: cosign.key"
echo "Public key: cosign.pub"

# Create test image for signing
cd go-app
docker build -f Dockerfile.static -t localhost/go-app:signed .

# Sign the image
echo -e "\nSigning image..."
cosign sign --key cosign.key localhost/go-app:signed

# Generate SBOM and attest
echo -e "\nGenerating SBOM attestation..."
syft packages localhost/go-app:signed -o spdx-json > go-app.spdx.json
cosign attest --key cosign.key --predicate go-app.spdx.json --type spdx localhost/go-app:signed

echo "✅ Image signed and attested"
```

### Step 2: Verification Script

```bash
#!/bin/bash
# verify-signature.sh

echo "🔍 Verifying Image Signatures"
echo "============================="

IMAGE="localhost/go-app:signed"

# Verify signature
echo "Verifying signature..."
cosign verify --key cosign.pub $IMAGE

# Verify attestation
echo -e "\nVerifying SBOM attestation..."
cosign verify-attestation --key cosign.pub --type spdx $IMAGE

# Download and inspect SBOM
echo -e "\nExtracting SBOM..."
cosign download attestation $IMAGE | jq '.payload' | base64 -d | jq '.predicate' > extracted-sbom.json

echo "SBOM packages:"
jq -r '.packages[] | "\(.name)@\(.versionInfo)"' extracted-sbom.json | head -10

echo "✅ Verification complete"
```

### Step 3: Secure Build Pipeline

```yaml
# .github/workflows/secure-build.yml
name: Secure Image Build and Sign

on:
  push:
    branches: [main]
    tags: ['v*']

permissions:
  contents: read
  packages: write
  id-token: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/secure-app

jobs:
  build-and-sign:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Install Cosign
        uses: sigstore/cosign-installer@v3
        
      - name: Install Syft
        uses: anchore/sbom-action@v0
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: Log in to Registry
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
            
      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          platforms: linux/amd64,linux/arm64
          cache-from: type=gha
          cache-to: type=gha,mode=max
          
      - name: Generate SBOM
        run: |
          syft packages ${{ steps.meta.outputs.tags }} -o spdx-json > sbom.spdx.json
          
      - name: Sign image and attest SBOM
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          # Sign the image
          cosign sign --yes ${{ steps.meta.outputs.tags }}
          
          # Attest SBOM
          cosign attest --yes --predicate sbom.spdx.json \
            --type spdx ${{ steps.meta.outputs.tags }}
            
      - name: Upload SBOM
        uses: actions/upload-artifact@v3
        with:
          name: sbom
          path: sbom.spdx.json
```

### Step 4: Policy Enforcement

```bash
#!/bin/bash
# policy-enforcement.sh

echo "📜 Policy Enforcement Example"
echo "============================"

IMAGE="localhost/go-app:signed"

# Example policy: Must be signed
echo "Checking signature requirement..."
if cosign verify --key cosign.pub $IMAGE >/dev/null 2>&1; then
    echo "✅ Image signature verified"
else
    echo "❌ Image signature verification failed"
    exit 1
fi

# Example policy: Must have SBOM
echo -e "\nChecking SBOM requirement..."
if cosign verify-attestation --key cosign.pub --type spdx $IMAGE >/dev/null 2>&1; then
    echo "✅ SBOM attestation verified"
else
    echo "❌ SBOM attestation verification failed"
    exit 1
fi

# Example policy: No high/critical vulnerabilities
echo -e "\nChecking vulnerability policy..."
VULN_COUNT=$(trivy image --quiet --format json $IMAGE | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH" or .Severity=="CRITICAL")] | length')

if [ "$VULN_COUNT" -eq 0 ]; then
    echo "✅ No high/critical vulnerabilities found"
else
    echo "❌ Found $VULN_COUNT high/critical vulnerabilities"
    # In real scenario, you might fail the deployment here
    echo "⚠️  Policy violation detected but continuing for demo"
fi

echo -e "\n✅ Policy enforcement complete"
```

### Verification
```bash
# Set up signing
chmod +x setup-signing.sh
./setup-signing.sh

# Verify signatures
chmod +x verify-signature.sh
./verify-signature.sh

# Test policy enforcement
chmod +x policy-enforcement.sh
./policy-enforcement.sh
```

---

## Exercise 6: Performance Analysis and Optimization

### Objectives
- Measure image build and runtime performance
- Analyze startup times across different approaches
- Optimize layer caching and image sizes
- Compare resource usage patterns

### Step 1: Performance Measurement Framework

```bash
#!/bin/bash
# performance-benchmark.sh

echo "⚡ Image Performance Benchmark"
echo "=============================="

# Test images to benchmark
IMAGES=(
    "python-app:traditional"
    "python-app:distroless"
    "go-app:static"
    "rust-app:static"
    "node-app:secure"
)

# Results file
RESULTS_FILE="performance-results.json"
echo '{"benchmarks": []}' > $RESULTS_FILE

for image in "${IMAGES[@]}"; do
    echo -e "\nBenchmarking: $image"
    echo "$(printf '=%.0s' {1..40})"
    
    # Check if image exists
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
        echo "Image $image not found, skipping..."
        continue
    fi
    
    # Measure image size
    SIZE=$(docker images $image --format "{{.Size}}")
    SIZE_BYTES=$(docker inspect $image | jq '.[0].Size')
    
    # Measure startup time (5 runs for average)
    STARTUP_TIMES=()
    PORT=$(( RANDOM % 1000 + 8000 ))
    
    for i in {1..5}; do
        echo -n "Startup test $i/5... "
        
        START_TIME=$(date +%s.%N)
        
        # Start container
        CONTAINER_ID=$(docker run -d -p $PORT:8080 $image 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo "failed to start"
            break
        fi
        
        # Wait for service to be ready
        READY=false
        TIMEOUT=30
        ELAPSED=0
        
        while [ $ELAPSED -lt $TIMEOUT ] && [ "$READY" = false ]; do
            if curl -s http://localhost:$PORT/health >/dev/null 2>&1; then
                END_TIME=$(date +%s.%N)
                STARTUP_TIME=$(echo "$END_TIME - $START_TIME" | bc)
                STARTUP_TIMES+=($STARTUP_TIME)
                READY=true
                echo "${STARTUP_TIME}s"
            else
                sleep 0.5
                ELAPSED=$(echo "$ELAPSED + 0.5" | bc)
            fi
        done
        
        # Cleanup
        docker stop $CONTAINER_ID >/dev/null 2>&1
        docker rm $CONTAINER_ID >/dev/null 2>&1
        
        if [ "$READY" = false ]; then
            echo "timeout"
            break
        fi
        
        sleep 1
    done
    
    # Calculate average startup time
    if [ ${#STARTUP_TIMES[@]} -gt 0 ]; then
        AVG_STARTUP=$(printf '%s\n' "${STARTUP_TIMES[@]}" | awk '{sum+=$1} END {print sum/NR}')
        MIN_STARTUP=$(printf '%s\n' "${STARTUP_TIMES[@]}" | sort -n | head -1)
        MAX_STARTUP=$(printf '%s\n' "${STARTUP_TIMES[@]}" | sort -n | tail -1)
        
        echo "Average startup time: ${AVG_STARTUP}s"
        echo "Min/Max startup time: ${MIN_STARTUP}s / ${MAX_STARTUP}s"
    else
        AVG_STARTUP="null"
        MIN_STARTUP="null"
        MAX_STARTUP="null"
        echo "Startup time measurement failed"
    fi
    
    # Memory usage test
    echo -n "Memory usage test... "
    CONTAINER_ID=$(docker run -d -p $PORT:8080 $image 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        sleep 5  # Let it stabilize
        MEMORY_USAGE=$(docker stats $CONTAINER_ID --no-stream --format "{{.MemUsage}}" | cut -d'/' -f1)
        echo "$MEMORY_USAGE"
        
        docker stop $CONTAINER_ID >/dev/null 2>&1
        docker rm $CONTAINER_ID >/dev/null 2>&1
    else
        MEMORY_USAGE="unknown"
        echo "failed"
    fi
    
    # Add to results
    RESULT=$(jq -n \
        --arg image "$image" \
        --arg size "$SIZE" \
        --argjson size_bytes "$SIZE_BYTES" \
        --argjson avg_startup "$AVG_STARTUP" \
        --argjson min_startup "$MIN_STARTUP" \
        --argjson max_startup "$MAX_STARTUP" \
        --arg memory "$MEMORY_USAGE" \
        '{
            image: $image,
            size: $size,
            size_bytes: $size_bytes,
            startup_time: {
                average: $avg_startup,
                min: $min_startup,
                max: $max_startup
            },
            memory_usage: $memory
        }')
    
    # Append to results
    jq --argjson result "$RESULT" '.benchmarks += [$result]' $RESULTS_FILE > temp.json
    mv temp.json $RESULTS_FILE
done

echo -e "\n📊 Performance Summary"
echo "====================="
jq -r '.benchmarks[] | "\(.image): \(.size) (\(.startup_time.average // "N/A")s startup)"' $RESULTS_FILE

echo -e "\nDetailed results saved to: $RESULTS_FILE"
```

### Step 2: Build Time Analysis

```bash
#!/bin/bash
# build-time-analysis.sh

echo "🔨 Build Time Analysis"
echo "====================="

BUILD_RESULTS="build-times.json"
echo '{"builds": []}' > $BUILD_RESULTS

DOCKERFILES=(
    "python-app/Dockerfile.traditional:python-app:traditional"
    "python-app/Dockerfile.distroless:python-app:distroless" 
    "go-app/Dockerfile.static:go-app:static"
    "rust-app/Dockerfile.static:rust-app:static"
    "node-app/Dockerfile.secure:node-app:secure"
)

for dockerfile_info in "${DOCKERFILES[@]}"; do
    IFS=':' read -r dockerfile image <<< "$dockerfile_info"
    
    echo -e "\nAnalyzing build time for: $dockerfile"
    
    # Clean up any existing image
    docker rmi $image 2>/dev/null || true
    
    # Clear build cache for accurate measurement
    docker builder prune -f >/dev/null 2>&1
    
    # Measure build time
    START_TIME=$(date +%s)
    
    if docker build -f $dockerfile -t $image $(dirname $dockerfile) >/dev/null 2>&1; then
        END_TIME=$(date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        echo "Build time: ${BUILD_TIME}s"
        STATUS="success"
    else
        echo "Build failed"
        BUILD_TIME=null
        STATUS="failed"
    fi
    
    # Add to results
    RESULT=$(jq -n \
        --arg dockerfile "$dockerfile" \
        --arg image "$image" \
        --argjson build_time "$BUILD_TIME" \
        --arg status "$STATUS" \
        '{
            dockerfile: $dockerfile,
            image: $image,
            build_time_seconds: $build_time,
            status: $status
        }')
    
    jq --argjson result "$RESULT" '.builds += [$result]' $BUILD_RESULTS > temp.json
    mv temp.json $BUILD_RESULTS
done

echo -e "\n📊 Build Time Summary"
echo "==================="
jq -r '.builds[] | select(.status == "success") | "\(.image): \(.build_time_seconds)s"' $BUILD_RESULTS | sort -k2 -n

echo -e "\nBuild results saved to: $BUILD_RESULTS"
```

### Step 3: Layer Analysis and Optimization

```bash
#!/bin/bash
# layer-analysis.sh

echo "📐 Layer Analysis"
echo "================"

analyze_image() {
    local image=$1
    
    echo -e "\nAnalyzing layers for: $image"
    echo "$(printf '-%.0s' {1..30})"
    
    # Get layer information
    docker history $image --format "table {{.CreatedBy}}\t{{.Size}}\t{{.CreatedSince}}" --no-trunc | head -20
    
    # Count layers
    LAYER_COUNT=$(docker history $image --quiet | wc -l)
    echo "Total layers: $LAYER_COUNT"
    
    # Get largest layers
    echo -e "\nLargest layers:"
    docker history $image --format "{{.Size}}\t{{.CreatedBy}}" | sort -hr | head -5
}

# Analyze different image types
IMAGES=(
    "python-app:traditional"
    "python-app:distroless"
    "go-app:static"
)

for image in "${IMAGES[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
        analyze_image $image
    else
        echo "Image $image not found"
    fi
done
```

### Verification
```bash
# Run performance benchmarks
chmod +x performance-benchmark.sh
./performance-benchmark.sh

# Analyze build times
chmod +x build-time-analysis.sh
./build-time-analysis.sh

# Analyze layers
chmod +x layer-analysis.sh
./layer-analysis.sh

# View results
echo -e "\nPerformance Results:"
jq '.' performance-results.json

echo -e "\nBuild Time Results:"
jq '.' build-times.json
```

---

## Lab Cleanup

### Complete Cleanup Script
```bash
#!/bin/bash
# cleanup-advanced-images-lab.sh

echo "🧹 Cleaning up Advanced Images Lab"
echo "=================================="

# Stop all running containers
echo "Stopping containers..."
docker stop $(docker ps -q) 2>/dev/null || true

# Remove lab images
echo "Removing lab images..."
LAB_IMAGES=(
    "python-app:traditional"
    "python-app:distroless" 
    "python-app:prod"
    "python-app:debug"
    "go-app:static"
    "rust-app:static"
    "node-app:secure"
    "test-image:latest"
    "localhost/go-app:signed"
    "examples/multiarch-app:v1.0.0"
    "examples/multiarch-app:latest"
    "app:dev"
    "app:test"
    "app:prod"
    "app:staging"
    "app:advanced"
    "app:optimized"
)

for image in "${LAB_IMAGES[@]}"; do
    docker rmi $image 2>/dev/null || true
done

# Remove buildx builder
docker buildx rm multiarch-builder 2>/dev/null || true

# Clean up build cache
echo "Cleaning build cache..."
docker builder prune -a -f

# Clean up system
echo "Cleaning system..."
docker system prune -a -f

# Remove generated files
echo "Removing generated files..."
rm -f *.json *.txt *.spdx.json
rm -f cosign.key cosign.pub
rm -f Dockerfile.temp

echo "✅ Cleanup complete!"
```

---

## Lab Summary

### What You Learned

1. **Distroless Images**
   - Built minimal images without OS packages
   - Compared sizes and vulnerability profiles
   - Implemented debug variants

2. **Static Linking**
   - Created self-contained Go and Rust binaries
   - Used scratch base images
   - Eliminated runtime dependencies

3. **CVE Minimization**
   - Compared vulnerability counts across base images
   - Implemented security scanning in builds
   - Generated and analyzed SBOMs

4. **Multi-Architecture Builds**
   - Built images for multiple platforms
   - Used advanced Dockerfile patterns
   - Optimized build performance with caching

5. **Image Signing**
   - Signed images with Cosign
   - Created SBOM attestations
   - Implemented signature verification

6. **Performance Optimization**
   - Measured startup times and resource usage
   - Analyzed build times and layer efficiency
   - Optimized image construction patterns

### Best Practices Demonstrated

- ✅ Minimal attack surface with distroless images
- ✅ Zero-dependency static binaries
- ✅ Comprehensive vulnerability management
- ✅ Supply chain security with signing
- ✅ Multi-architecture support
- ✅ Performance-optimized builds
- ✅ Advanced Dockerfile patterns
- ✅ Automated security scanning

### Next Steps

1. Integrate these patterns into your CI/CD pipelines
2. Implement organization-wide image policies
3. Explore advanced container runtimes (gVisor, Kata)
4. Consider WebAssembly for ultra-minimal deployments
5. Build custom distroless base images

---

*Congratulations! You've mastered advanced Docker image construction techniques!* 🎉🐳