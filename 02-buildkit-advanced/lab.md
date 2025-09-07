# Phase 02: BuildKit Advanced - Hands-On Labs

> **Master advanced BuildKit features through practical, production-focused exercises**

## 🎯 Lab Overview

These labs will teach you advanced BuildKit techniques that are essential for production Docker usage. You'll learn multi-stage builds, cache optimization, secure secret handling, and build parameterization.

**Total Lab Time**: ~150 minutes  
**Difficulty**: Intermediate  
**Prerequisites**: Phase 01 completed, Docker 20.10+ with BuildKit enabled

## 🚀 Lab Setup

Verify BuildKit capabilities and create workspace:

```bash
# Verify BuildKit is enabled and available
docker buildx version
docker buildx ls

# Create lab workspace
mkdir -p buildkit-labs && cd buildkit-labs

# Verify advanced features are available
docker buildx create --use --name advanced-builder 2>/dev/null || echo "Using default builder"
docker buildx inspect --bootstrap
```

---

## 🧪 Lab 1: Multi-Stage Build Transformation
**Time**: 40 minutes  
**Anchor**: `p02-m01-l01`

### Why It Matters
Multi-stage builds are the most impactful BuildKit feature for production use. They can reduce image sizes by 70-90% while improving security by excluding build tools from runtime images.

### What You'll Learn
- How to separate build and runtime concerns effectively
- Techniques for copying selective artifacts between stages
- Strategies for optimizing both builder and runtime stages
- Impact measurement of multi-stage optimization

### Try It

**Step 1: Create a Realistic Application**
```bash
mkdir multi-stage-demo && cd multi-stage-demo

# Create a Go application (could be any compiled language)
cat > main.go << 'EOF'
package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "time"
)

type AppInfo struct {
    Name      string    `json:"name"`
    Version   string    `json:"version"`
    BuildTime string    `json:"build_time"`
    GoVersion string    `json:"go_version"`
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        info := AppInfo{
            Name:      "BuildKit Demo App",
            Version:   "1.0.0",
            BuildTime: "BUILD_TIME_PLACEHOLDER",
            GoVersion: "1.21",
        }
        
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(info)
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, "OK")
    })

    log.Printf("Server starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF

cat > go.mod << 'EOF'
module buildkit-demo

go 1.21
EOF
```

**Step 2: Build Traditional Single-Stage Version**
```bash
cat > Dockerfile.traditional << 'EOF'
FROM golang:1.21

WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download
COPY . .

# Replace build time placeholder
RUN sed -i "s/BUILD_TIME_PLACEHOLDER/$(date -u +%Y-%m-%dT%H:%M:%SZ)/" main.go

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

EXPOSE 8080
CMD ["./main"]
EOF

# Build and measure traditional approach
echo "Building traditional single-stage image..."
docker build -f Dockerfile.traditional -t demo-traditional .

# Check size and contents
docker image ls demo-traditional
echo "=== Traditional image contents ==="
docker run --rm demo-traditional ls -la /usr/local/go | head -10
```

**Step 3: Create Optimized Multi-Stage Version**
```bash
cat > Dockerfile.multistage << 'EOF'
# =============================================================================
# Builder Stage: Contains all build tools and dependencies
# =============================================================================
FROM golang:1.21 AS builder

# Set build-time environment
ARG BUILD_DATE
ARG VERSION=1.0.0

WORKDIR /app

# Copy dependency files first (better caching)
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# Replace build time placeholder with actual build date
RUN sed -i "s/BUILD_TIME_PLACEHOLDER/${BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}/" main.go

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -a -installsuffix cgo \
    -ldflags "-s -w -X main.version=${VERSION}" \
    -o main .

# =============================================================================
# Runtime Stage: Minimal image with only runtime requirements
# =============================================================================
FROM alpine:latest AS runtime

# Install certificates for HTTPS calls
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN adduser -D -s /bin/sh appuser

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/main .

# Set ownership
RUN chown appuser:appuser /app/main

# Switch to non-root user
USER appuser

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./main"]
EOF

# Build multi-stage version with build arguments
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "Building multi-stage image..."
docker build -f Dockerfile.multistage \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION=2.0.0 \
    -t demo-multistage .
```

**Step 4: Compare Results and Test**
```bash
# Compare image sizes
echo "=== Image Size Comparison ==="
docker image ls | grep demo-
echo ""

# Calculate size reduction
TRADITIONAL_SIZE=$(docker image ls demo-traditional --format "table {{.Size}}" | tail -1)
MULTISTAGE_SIZE=$(docker image ls demo-multistage --format "table {{.Size}}" | tail -1)

echo "Traditional: $TRADITIONAL_SIZE"
echo "Multi-stage: $MULTISTAGE_SIZE"

# Test both applications
echo "=== Testing Traditional Version ==="
docker run -d --name demo-traditional-test -p 8081:8080 demo-traditional
sleep 3
curl http://localhost:8081
curl http://localhost:8081/health
docker rm -f demo-traditional-test

echo ""
echo "=== Testing Multi-stage Version ==="
docker run -d --name demo-multistage-test -p 8082:8080 demo-multistage
sleep 3
curl http://localhost:8082
curl http://localhost:8082/health
docker rm -f demo-multistage-test

# Inspect runtime image contents
echo ""
echo "=== Multi-stage Runtime Contents ==="
docker run --rm demo-multistage ls -la /app
docker run --rm demo-multistage ps aux
```

**Step 5: Advanced Multi-Stage Techniques**
```bash
# Create version with multiple builder stages
cat > Dockerfile.advanced << 'EOF'
# =============================================================================
# Base builder with common dependencies
# =============================================================================
FROM golang:1.21 AS base-builder
WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download

# =============================================================================
# Development builder (includes debugging tools)
# =============================================================================
FROM base-builder AS dev-builder
RUN go install github.com/go-delve/delve/cmd/dlv@latest
COPY . .
RUN go build -gcflags="all=-N -l" -o main-debug .

# =============================================================================
# Production builder (optimized binary)
# =============================================================================
FROM base-builder AS prod-builder
COPY . .
ARG BUILD_DATE
ARG VERSION=1.0.0
RUN sed -i "s/BUILD_TIME_PLACEHOLDER/${BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}/" main.go
RUN CGO_ENABLED=0 GOOS=linux go build \
    -a -installsuffix cgo \
    -ldflags "-s -w -X main.version=${VERSION}" \
    -o main .

# =============================================================================
# Development runtime (with debug tools)
# =============================================================================
FROM alpine:latest AS development
RUN apk --no-cache add ca-certificates
COPY --from=dev-builder /go/bin/dlv /usr/local/bin/
COPY --from=dev-builder /app/main-debug /app/main
EXPOSE 8080 40000
CMD ["dlv", "--listen=:40000", "--headless=true", "--api-version=2", "exec", "/app/main"]

# =============================================================================
# Production runtime (minimal)
# =============================================================================
FROM alpine:latest AS production
RUN apk --no-cache add ca-certificates
RUN adduser -D -s /bin/sh appuser
WORKDIR /app
COPY --from=prod-builder /app/main .
RUN chown appuser:appuser /app/main
USER appuser
EXPOSE 8080
CMD ["./main"]
EOF

# Build different targets
echo "Building production target..."
docker build -f Dockerfile.advanced --target production \
    --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -t demo-production .

echo "Building development target..."
docker build -f Dockerfile.advanced --target development \
    --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -t demo-development .

# Compare all versions
echo "=== All Image Sizes ==="
docker image ls | grep demo-

cd ..
```

### Verify It
- [ ] Multi-stage image is significantly smaller than traditional (>50% reduction)
- [ ] Multi-stage runtime contains no Go toolchain or source code
- [ ] Both applications function identically
- [ ] Can build different targets for different purposes
- [ ] Understand artifact copying between stages

---

## 🧪 Lab 2: Cache Mounts for Speed
**Time**: 35 minutes  
**Anchor**: `p02-m01-l02`

### Why It Matters
Cache mounts can reduce build times from minutes to seconds by persisting dependency caches across builds. This is crucial for development velocity and CI/CD performance.

### What You'll Learn
- How to implement cache mounts for different package managers
- Strategies for cache scope and security
- Performance measurement and optimization techniques
- Cache invalidation and management

### Try It

**Step 1: Create Node.js Application**
```bash
mkdir cache-mount-demo && cd cache-mount-demo

# Create realistic package.json with many dependencies
cat > package.json << 'EOF'
{
  "name": "cache-mount-demo",
  "version": "1.0.0",
  "description": "BuildKit cache mount demonstration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "test": "jest",
    "build": "webpack --mode=production"
  },
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.21",
    "moment": "^2.29.4",
    "axios": "^1.6.0",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "webpack": "^5.89.0",
    "webpack-cli": "^5.1.4",
    "@babel/core": "^7.23.0",
    "@babel/preset-env": "^7.23.0",
    "babel-loader": "^9.1.3"
  }
}
EOF

# Create simple Express server
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const _ = require('lodash');
const moment = require('moment');

const app = express();
const port = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'Cache Mount Demo',
    timestamp: moment().toISOString(),
    randomNumber: _.random(1, 1000),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
EOF

# Create webpack config
cat > webpack.config.js << 'EOF'
const path = require('path');

module.exports = {
  entry: './server.js',
  target: 'node',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'server.bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env']
          }
        }
      }
    ]
  }
};
EOF
```

**Step 2: Build Without Cache Mounts (Baseline)**
```bash
cat > Dockerfile.nocache << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (no cache mount)
RUN npm install

# Copy source code
COPY . .

# Build application
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
EOF

# Build without cache and measure time
echo "=== Building without cache mounts (baseline) ==="
time docker build -f Dockerfile.nocache -t cache-demo-nocache .

# Simulate code change and rebuild
echo "// Code change" >> server.js
echo "=== Rebuilding after code change (no cache) ==="
time docker build -f Dockerfile.nocache -t cache-demo-nocache .
```

**Step 3: Implement Cache Mounts**
```bash
cat > Dockerfile.cached << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copy source code
COPY . .

# Build with cache mount for webpack cache
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=./node_modules/.cache/webpack \
    npm run build

EXPOSE 3000
CMD ["npm", "start"]
EOF

# Build with cache mounts
echo "=== Building with cache mounts (first time) ==="
time docker build -f Dockerfile.cached -t cache-demo-cached .

# Simulate code change and rebuild
echo "// Another code change" >> server.js
echo "=== Rebuilding after code change (with cache) ==="
time docker build -f Dockerfile.cached -t cache-demo-cached .

# Make package.json change and rebuild
cat package.json | jq '.description = "Updated description"' > package.json.tmp && mv package.json.tmp package.json
echo "=== Rebuilding after dependency change (with cache) ==="
time docker build -f Dockerfile.cached -t cache-demo-cached .
```

**Step 4: Advanced Cache Strategies**
```bash
# Create production-optimized Dockerfile with selective caching
cat > Dockerfile.optimized << 'EOF'
# =============================================================================
# Builder stage with comprehensive caching
# =============================================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies with cache mount
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    --mount=type=cache,target=/app/node_modules/.cache \
    npm ci

# Copy source code
COPY . .

# Build with cache mounts
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/app/node_modules/.cache \
    --mount=type=cache,target=/tmp/webpack-cache \
    npm run build

# =============================================================================  
# Runtime stage with production dependencies only
# =============================================================================
FROM node:18-alpine AS runtime

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies with cache
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --only=production && \
    npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.js ./server.js

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Change ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["npm", "start"]
EOF

# Build optimized version
echo "=== Building optimized multi-stage with cache mounts ==="
time docker build -f Dockerfile.optimized -t cache-demo-optimized .

# Test the optimized version
docker run -d --name cache-test -p 3001:3000 cache-demo-optimized
sleep 3
curl http://localhost:3001
curl http://localhost:3001/health
docker rm -f cache-test
```

**Step 5: Cache Management and Analysis**
```bash
# Inspect cache usage
echo "=== Docker Build Cache Information ==="
docker system df

# Show build cache details
docker buildx du

# Clean build cache if needed
read -p "Clean build cache? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker buildx prune -f
fi

# Compare final image sizes
echo "=== Image Size Comparison ==="
docker image ls | grep cache-demo

cd ..
```

### Verify It
- [ ] Cached builds are significantly faster than uncached (>5x speedup)
- [ ] Cache persists across different builds of the same project
- [ ] Cache mounts don't affect final image contents or size
- [ ] Different cache scopes work appropriately
- [ ] Can manage and clean build caches effectively

---

## 🧪 Lab 3: Secure Build Secrets
**Time**: 35 minutes  
**Anchor**: `p02-m01-l03`

### Why It Matters
Accidentally embedding secrets in Docker images is a common security vulnerability. BuildKit secret mounts provide a secure way to handle credentials during builds without any risk of leakage.

### What You'll Learn
- Different types of secret mounts and their use cases
- How to ensure zero-leakage of sensitive information
- Integration with external secret management systems
- Best practices for secret lifecycle management

### Try It

**Step 1: Demonstrate the Problem**
```bash
mkdir build-secrets-demo && cd build-secrets-demo

# Create a private configuration that requires authentication
cat > fetch-config.sh << 'EOF'
#!/bin/sh
# Simulate fetching configuration from a private API
if [ -z "$API_TOKEN" ]; then
    echo "Error: API_TOKEN not provided"
    exit 1
fi

echo "Fetching configuration with token: ${API_TOKEN:0:8}..."
# Simulate API call
cat > app-config.json << CONFIG
{
  "database_url": "postgres://prod-db:5432/app",
  "api_endpoints": {
    "user_service": "https://api.example.com/users",
    "payment_service": "https://api.example.com/payments"
  },
  "features": {
    "advanced_analytics": true,
    "beta_features": false
  }
}
CONFIG
echo "Configuration fetched successfully"
EOF

chmod +x fetch-config.sh

# Create vulnerable Dockerfile (DON'T DO THIS IN REAL PROJECTS)
cat > Dockerfile.vulnerable << 'EOF'
FROM alpine:latest

# VULNERABLE: Token will be in image layers
ENV API_TOKEN="secret-token-12345-abcdef"

COPY fetch-config.sh /fetch-config.sh

# Even if we try to remove the token, it's still in previous layers
RUN /fetch-config.sh && \
    unset API_TOKEN

# The damage is done - token is permanently in the image

CMD ["cat", "app-config.json"]
EOF

# Build vulnerable version
echo "=== Building vulnerable version ==="
docker build -f Dockerfile.vulnerable -t secrets-vulnerable .

# Show the security problem
echo "=== Security Issue: Token visible in image history ==="
docker history secrets-vulnerable
docker run --rm secrets-vulnerable env | grep API || echo "Token not in runtime env (but still in layers!)"
```

**Step 2: Implement Secret Mounts**
```bash
# Create secure configuration fetch script
cat > fetch-config-secure.sh << 'EOF'
#!/bin/sh
# Secure version using mounted secrets
SECRET_FILE="/run/secrets/api-token"

if [ ! -f "$SECRET_FILE" ]; then
    echo "Error: Secret file not found at $SECRET_FILE"
    exit 1
fi

API_TOKEN=$(cat "$SECRET_FILE")

if [ -z "$API_TOKEN" ]; then
    echo "Error: Empty API token"
    exit 1
fi

echo "Fetching configuration with token: ${API_TOKEN:0:8}..."

# Simulate authenticated API call
cat > app-config.json << CONFIG
{
  "database_url": "postgres://prod-db:5432/app",
  "api_endpoints": {
    "user_service": "https://api.example.com/users",
    "payment_service": "https://api.example.com/payments"
  },
  "features": {
    "advanced_analytics": true,
    "beta_features": false
  },
  "fetch_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
CONFIG

echo "Configuration fetched securely"
EOF

chmod +x fetch-config-secure.sh

# Create actual secret file
echo "secret-api-token-67890-secure" > api-token.secret

# Create secure Dockerfile
cat > Dockerfile.secure << 'EOF'
FROM alpine:latest

WORKDIR /app
COPY fetch-config-secure.sh .

# Use secret mount - secret never persists in any layer
RUN --mount=type=secret,id=api-token \
    ./fetch-config-secure.sh

# Secret is gone after RUN instruction completes
CMD ["cat", "app-config.json"]
EOF

# Build with secret mount
echo "=== Building with secure secret mount ==="
docker build --secret id=api-token,src=./api-token.secret -f Dockerfile.secure -t secrets-secure .

# Verify security
echo "=== Security Verification ==="
docker history secrets-secure
docker run --rm secrets-secure cat app-config.json
echo "=== Attempting to find secret in image (should fail) ==="
docker run --rm secrets-secure find / -name "*secret*" -o -name "*token*" 2>/dev/null | grep -v "/proc" || echo "No secrets found in image ✅"
```

**Step 3: Advanced Secret Patterns**
```bash
# Create multi-secret scenario
echo "db-password-super-secret" > db-password.secret
echo "jwt-signing-key-ultra-secure" > jwt-key.secret

cat > multi-secret-setup.sh << 'EOF'
#!/bin/sh

# Read database password
if [ -f "/run/secrets/db-password" ]; then
    DB_PASSWORD=$(cat /run/secrets/db-password)
    echo "Database password loaded (${#DB_PASSWORD} characters)"
else
    echo "Warning: Database password not available"
fi

# Read JWT signing key
if [ -f "/run/secrets/jwt-key" ]; then
    JWT_KEY=$(cat /run/secrets/jwt-key)
    echo "JWT key loaded (${#JWT_KEY} characters)"
else
    echo "Warning: JWT key not available"
fi

# Create configuration template (no actual secrets stored)
cat > final-config.json << CONFIG
{
  "database": {
    "host": "postgres://localhost:5432/app",
    "password_configured": $([ -n "$DB_PASSWORD" ] && echo "true" || echo "false")
  },
  "auth": {
    "jwt_configured": $([ -n "$JWT_KEY" ] && echo "true" || echo "false"),
    "algorithm": "HS256"
  },
  "setup_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
CONFIG

echo "Multi-secret setup completed"
EOF

chmod +x multi-secret-setup.sh

# Create Dockerfile with multiple secrets
cat > Dockerfile.multi-secret << 'EOF'
FROM alpine:latest

WORKDIR /app
COPY multi-secret-setup.sh .

# Use multiple secret mounts in single RUN instruction
RUN --mount=type=secret,id=db-password \
    --mount=type=secret,id=jwt-key \
    ./multi-secret-setup.sh

CMD ["cat", "final-config.json"]
EOF

# Build with multiple secrets
echo "=== Building with multiple secrets ==="
docker build \
    --secret id=db-password,src=./db-password.secret \
    --secret id=jwt-key,src=./jwt-key.secret \
    -f Dockerfile.multi-secret \
    -t secrets-multi .

# Test multi-secret image
docker run --rm secrets-multi
```

**Step 4: SSH Secret for Git Access**
```bash
# Create SSH key for demonstration (in real usage, use existing keys)
ssh-keygen -t rsa -b 2048 -f ./demo-key -N "" -C "demo@example.com"

# Create repository access script
cat > clone-repo.sh << 'EOF'
#!/bin/sh
# This would clone a private repository in real usage

# Check if SSH agent is available
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "SSH agent available"
    ssh-add -l || echo "No keys loaded"
else
    echo "No SSH agent available"
fi

# Simulate git clone (replace with real repository in practice)
mkdir -p /app/repo
cat > /app/repo/README.md << 'README'
# Private Repository Content

This content was fetched from a private repository using SSH key authentication.

## Features
- Secure authentication
- No key leakage
- Clean build process

Cloned at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
README

echo "Repository cloned successfully"
EOF

chmod +x clone-repo.sh

# Create Dockerfile with SSH secret
cat > Dockerfile.ssh << 'EOF'
FROM alpine:latest

# Install git and openssh
RUN apk add --no-cache git openssh-client

WORKDIR /app
COPY clone-repo.sh .

# Use SSH secret mount for git operations
RUN --mount=type=ssh \
    ./clone-repo.sh

CMD ["cat", "/app/repo/README.md"]
EOF

# Build with SSH secret (simulated)
echo "=== Building with SSH secret mount ==="
DOCKER_BUILDKIT=1 docker build --ssh default=$HOME/.ssh/id_rsa -f Dockerfile.ssh -t secrets-ssh . 2>/dev/null || \
docker build -f Dockerfile.ssh -t secrets-ssh . && echo "SSH mount simulated (no actual SSH key used)"

# Test SSH secret image  
docker run --rm secrets-ssh

# Clean up secret files
rm -f *.secret demo-key demo-key.pub

cd ..
```

### Verify It
- [ ] Secret mounts prevent any secret leakage into image layers
- [ ] Multiple secrets can be used simultaneously in single RUN instructions
- [ ] Secret files are only available during the specific RUN instruction
- [ ] Image history shows no trace of secret content
- [ ] SSH secret mounts work for repository access scenarios

---

## 🧪 Lab 4: Build Arguments & Target Selection
**Time**: 40 minutes  
**Anchor**: `p02-m01-l04`

### Why It Matters
Build arguments and target selection enable flexible, reusable Dockerfiles that can adapt to different environments, configurations, and deployment scenarios without code duplication.

### What You'll Learn
- Effective use of ARG for build-time parameterization
- Target selection strategies for different deployment scenarios
- Default value patterns and validation techniques
- Integration with CI/CD pipelines and build matrices

### Try It

**Step 1: Create Parameterized Application**
```bash
mkdir build-args-demo && cd build-args-demo

# Create flexible application
cat > app.py << 'EOF'
import os
import json
from flask import Flask, jsonify

app = Flask(__name__)

# Configuration loaded from environment
CONFIG = {
    'environment': os.getenv('APP_ENV', 'development'),
    'debug': os.getenv('DEBUG', 'false').lower() == 'true',
    'version': os.getenv('APP_VERSION', 'unknown'),
    'build_date': os.getenv('BUILD_DATE', 'unknown'),
    'features': {
        'analytics': os.getenv('ENABLE_ANALYTICS', 'false').lower() == 'true',
        'monitoring': os.getenv('ENABLE_MONITORING', 'false').lower() == 'true',
        'debug_mode': os.getenv('ENABLE_DEBUG', 'false').lower() == 'true'
    }
}

@app.route('/')
def info():
    return jsonify({
        'message': 'Build Args Demo',
        'config': CONFIG
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = CONFIG['debug']
    app.run(host='0.0.0.0', port=port, debug=debug)
EOF

cat > requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
EOF

# Create configuration files for different environments
cat > config-dev.env << 'EOF'
APP_ENV=development
DEBUG=true
ENABLE_DEBUG=true
ENABLE_ANALYTICS=false
ENABLE_MONITORING=false
EOF

cat > config-staging.env << 'EOF'
APP_ENV=staging
DEBUG=false
ENABLE_DEBUG=false
ENABLE_ANALYTICS=true
ENABLE_MONITORING=true
EOF

cat > config-prod.env << 'EOF'
APP_ENV=production
DEBUG=false
ENABLE_DEBUG=false
ENABLE_ANALYTICS=true
ENABLE_MONITORING=true
EOF
```

**Step 2: Build Arguments with Validation**
```bash
cat > Dockerfile.parameterized << 'EOF'
# =============================================================================
# Parameterized Dockerfile with build arguments
# =============================================================================
FROM python:3.11-slim AS base

# Build arguments with defaults
ARG APP_ENV=development
ARG APP_VERSION=1.0.0
ARG BUILD_DATE
ARG PYTHON_VERSION=3.11
ARG ENABLE_ANALYTICS=false
ARG ENABLE_MONITORING=false
ARG ENABLE_DEBUG=false

# Validate critical arguments
RUN test -n "$APP_VERSION" || (echo "ERROR: APP_VERSION is required" && exit 1)
RUN test -n "$BUILD_DATE" || (echo "ERROR: BUILD_DATE is required" && exit 1)

# Validate environment values
RUN case "$APP_ENV" in \
        development|staging|production) echo "Environment: $APP_ENV" ;; \
        *) echo "ERROR: APP_ENV must be development, staging, or production" && exit 1 ;; \
    esac

# Set build-time labels for traceability
LABEL build.environment="$APP_ENV" \
      build.version="$APP_VERSION" \
      build.date="$BUILD_DATE" \
      build.python_version="$PYTHON_VERSION"

WORKDIR /app

# Install system dependencies based on environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    $(if [ "$APP_ENV" = "development" ]; then echo "curl vim"; fi) \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Set runtime environment variables from build args
ENV APP_ENV="$APP_ENV" \
    APP_VERSION="$APP_VERSION" \
    BUILD_DATE="$BUILD_DATE" \
    ENABLE_ANALYTICS="$ENABLE_ANALYTICS" \
    ENABLE_MONITORING="$ENABLE_MONITORING" \
    ENABLE_DEBUG="$ENABLE_DEBUG"

# Conditional user setup
RUN if [ "$APP_ENV" != "development" ]; then \
        adduser --disabled-password --gecos '' appuser && \
        chown -R appuser:appuser /app; \
    fi

# Switch to non-root user in non-dev environments
USER $(if [ "$APP_ENV" = "development" ]; then echo "root"; else echo "appuser"; fi)

EXPOSE 5000

# Default command
CMD ["python", "app.py"]
EOF

# Build for different environments
echo "=== Building for Development Environment ==="
docker build -f Dockerfile.parameterized \
    --build-arg APP_ENV=development \
    --build-arg APP_VERSION=1.0.0-dev \
    --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --build-arg ENABLE_DEBUG=true \
    -t build-args-dev .

echo "=== Building for Production Environment ==="
docker build -f Dockerfile.parameterized \
    --build-arg APP_ENV=production \
    --build-arg APP_VERSION=1.2.3 \
    --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --build-arg ENABLE_ANALYTICS=true \
    --build-arg ENABLE_MONITORING=true \
    -t build-args-prod .

# Test different builds
echo "=== Testing Development Build ==="
docker run -d --name dev-test -p 5001:5000 build-args-dev
sleep 3
curl -s http://localhost:5001 | python3 -m json.tool
docker rm -f dev-test

echo "=== Testing Production Build ==="
docker run -d --name prod-test -p 5002:5000 build-args-prod
sleep 3  
curl -s http://localhost:5002 | python3 -m json.tool
docker rm -f prod-test
```

**Step 3: Multi-Target Architecture**
```bash
cat > Dockerfile.multi-target << 'EOF'
# =============================================================================
# Base stage with common dependencies
# =============================================================================
FROM python:3.11-slim AS base

ARG APP_VERSION=1.0.0
ARG BUILD_DATE

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

# Set common labels
LABEL app.version="$APP_VERSION" \
      app.build_date="$BUILD_DATE"

# =============================================================================
# Development target with debugging tools
# =============================================================================
FROM base AS development

# Install development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        vim \
        net-tools \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Install Python debugging packages
RUN pip install --no-cache-dir debugpy pytest flask-debugtoolbar

ENV APP_ENV=development \
    APP_VERSION="$APP_VERSION" \
    BUILD_DATE="$BUILD_DATE" \
    DEBUG=true \
    ENABLE_DEBUG=true \
    FLASK_ENV=development

# Run as root for development convenience
USER root

# Enable debug mode
EXPOSE 5000 5678
CMD ["python", "-m", "debugpy", "--listen", "0.0.0.0:5678", "--wait-for-client", "app.py"]

# =============================================================================
# Testing target with test dependencies
# =============================================================================
FROM base AS testing

# Install testing tools
RUN pip install --no-cache-dir pytest pytest-cov pytest-flask coverage

# Copy test files (would exist in real project)
RUN mkdir -p tests && echo 'def test_health(): assert True' > tests/test_app.py

ENV APP_ENV=testing \
    APP_VERSION="$APP_VERSION" \
    BUILD_DATE="$BUILD_DATE"

# Run tests by default
CMD ["pytest", "-v", "--cov=app", "tests/"]

# =============================================================================
# Staging target with monitoring enabled
# =============================================================================
FROM base AS staging

# Install production dependencies
RUN pip install --no-cache-dir gunicorn prometheus_client

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

ENV APP_ENV=staging \
    APP_VERSION="$APP_VERSION" \
    BUILD_DATE="$BUILD_DATE" \
    ENABLE_ANALYTICS=true \
    ENABLE_MONITORING=true

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]

# =============================================================================
# Production target - minimal and secure
# =============================================================================
FROM python:3.11-slim AS production

ARG APP_VERSION=1.0.0
ARG BUILD_DATE

# Install only production dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn && \
    pip cache purge

# Copy application
COPY app.py .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Production environment
ENV APP_ENV=production \
    APP_VERSION="$APP_VERSION" \
    BUILD_DATE="$BUILD_DATE" \
    ENABLE_ANALYTICS=true \
    ENABLE_MONITORING=true \
    PYTHONUNBUFFERED=1

# Security and performance labels
LABEL security.scan="required" \
      performance.profile="production"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "--timeout", "30", "app:app"]
EOF

# Build different targets
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
VERSION="2.1.0"

echo "=== Building Development Target ==="
docker build -f Dockerfile.multi-target --target development \
    --build-arg APP_VERSION="$VERSION-dev" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    -t multi-target-dev .

echo "=== Building Testing Target ==="
docker build -f Dockerfile.multi-target --target testing \
    --build-arg APP_VERSION="$VERSION-test" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    -t multi-target-test .

echo "=== Building Production Target ==="
docker build -f Dockerfile.multi-target --target production \
    --build-arg APP_VERSION="$VERSION" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    -t multi-target-prod .

# Compare image sizes
echo "=== Target Size Comparison ==="
docker image ls | grep multi-target

# Test different targets
echo "=== Running Tests ==="
docker run --rm multi-target-test

echo "=== Testing Production Target ==="
docker run -d --name prod-final-test -p 5003:5000 multi-target-prod
sleep 5
curl -s http://localhost:5003 | python3 -m json.tool
docker rm -f prod-final-test
```

**Step 4: Build Matrix with Docker Bake**
```bash
# Create Docker Bake configuration
cat > docker-bake.hcl << 'EOF'
variable "APP_VERSION" {
    default = "1.0.0"
}

variable "BUILD_DATE" {
    default = ""
}

group "default" {
    targets = ["development", "staging", "production"]
}

target "base" {
    dockerfile = "Dockerfile.multi-target"
    args = {
        APP_VERSION = "${APP_VERSION}"
        BUILD_DATE = "${BUILD_DATE}"
    }
}

target "development" {
    inherits = ["base"]
    target = "development"
    tags = ["multi-target:dev", "multi-target:development"]
    labels = {
        "environment" = "development"
    }
}

target "testing" {
    inherits = ["base"]
    target = "testing"
    tags = ["multi-target:test"]
    labels = {
        "environment" = "testing"
    }
}

target "staging" {
    inherits = ["base"]
    target = "staging"
    tags = ["multi-target:staging"]
    labels = {
        "environment" = "staging"
    }
}

target "production" {
    inherits = ["base"]
    target = "production"
    tags = ["multi-target:prod", "multi-target:${APP_VERSION}"]
    labels = {
        "environment" = "production"
        "version" = "${APP_VERSION}"
    }
}
EOF

# Build using Docker Bake
echo "=== Building with Docker Bake ==="
APP_VERSION="3.0.0" BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" docker buildx bake

# Show all built images
echo "=== All Built Images ==="
docker image ls | grep multi-target

cd ..
```

### Verify It
- [ ] Build arguments successfully parameterize Dockerfiles
- [ ] Different targets produce appropriate images for different environments
- [ ] Argument validation prevents invalid builds
- [ ] Docker Bake simplifies complex build matrices
- [ ] Image labels and metadata reflect build parameters correctly

---

## 🧹 Lab Cleanup

After completing all labs:

```bash
# Remove containers
docker rm -f $(docker ps -aq --filter "name=demo-") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=cache-") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=secrets-") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=dev-test") 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=prod-test") 2>/dev/null || true

# Remove images
docker image rm -f \
    demo-traditional demo-multistage demo-production demo-development \
    cache-demo-nocache cache-demo-cached cache-demo-optimized \
    secrets-vulnerable secrets-secure secrets-multi secrets-ssh \
    build-args-dev build-args-prod \
    multi-target-dev multi-target-test multi-target-prod \
    multi-target:dev multi-target:staging multi-target:prod \
    2>/dev/null || true

# Clean up lab directories
cd .. && rm -rf buildkit-labs

# Clean build cache
docker buildx prune -f

# Clean general Docker resources
docker system prune -f
```

## 📝 Lab Summary

**What you accomplished:**
1. ✅ Transformed single-stage builds into optimized multi-stage builds with 70%+ size reduction
2. ✅ Implemented cache mounts that dramatically improve build performance (5-10x speedup)
3. ✅ Mastered secure secret handling with zero-leakage guarantee
4. ✅ Created flexible, parameterized builds using ARG and target selection
5. ✅ Explored Docker Bake for advanced build orchestration

**Key insights gained:**
- Multi-stage builds are essential for production deployments
- Cache mounts transform development workflow efficiency
- Secret security requires BuildKit advanced features
- Build parameterization enables flexible CI/CD pipelines
- Target selection provides environment-specific optimization

**Real-world applications:**
- **Production deployments**: Multi-stage builds for security and size
- **CI/CD pipelines**: Cache mounts for build speed and cost reduction
- **Secret management**: Secure credential handling in automated builds
- **Environment management**: Consistent builds across dev/staging/prod
- **Build optimization**: Dramatic improvements in build time and resource usage

**Production patterns learned:**
- Builder vs runtime stage separation strategies
- Cache scope and security considerations
- Secret lifecycle management best practices
- Build argument validation and default patterns
- Target-based environment differentiation

---

> 🎯 **Next**: With advanced BuildKit mastery, you're ready for **Phase 03: Container Operations** where you'll learn runtime management, health checks, and resource optimization.