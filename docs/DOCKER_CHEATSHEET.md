# 🐳 Docker Cheatsheet: Complete Reference Guide

> **Purpose**: Comprehensive Docker command reference from basics to advanced production patterns  
> **Scope**: All Docker concepts covered in the learning path with practical examples  
> **Usage**: Quick reference for practitioners at all skill levels

[![Docker](https://img.shields.io/badge/Docker-Basics%20to%20Advanced-blue?logo=docker)](https://docs.docker.com/)
[![Learning Path](https://img.shields.io/badge/Learning%20Path-Complete%20Guide-green)](./README.md)

---

## 📖 Table of Contents

- [🏗️ Container Basics](#️-container-basics)
- [🖼️ Image Management](#️-image-management)
- [📝 Dockerfile Reference](#-dockerfile-reference)
- [⚡ BuildKit Advanced](#-buildkit-advanced)
- [🔧 Container Operations](#-container-operations)
- [🌐 Networking](#-networking)
- [💾 Storage & Volumes](#-storage--volumes)
- [🎼 Docker Compose](#-docker-compose)
- [🛡️ Security](#️-security)
- [🚀 CI/CD & Multi-Architecture](#-cicd--multi-architecture)
- [🏪 Registry Operations](#-registry-operations)
- [📊 Monitoring & Observability](#-monitoring--observability)
- [🎯 Advanced Patterns](#-advanced-patterns)
- [🚨 Troubleshooting](#-troubleshooting)
- [📚 Quick Reference Cards](#-quick-reference-cards)

---

## 🏗️ Container Basics

### Container Lifecycle

```bash
# Run containers
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
docker run -d nginx                           # Detached mode
docker run -it ubuntu bash                    # Interactive mode
docker run --name myapp nginx                 # Named container
docker run -p 8080:80 nginx                   # Port mapping
docker run -v /host:/container nginx          # Volume mount

# Container management
docker ps                                     # List running containers
docker ps -a                                  # List all containers
docker start CONTAINER                        # Start stopped container
docker stop CONTAINER                         # Stop running container
docker restart CONTAINER                      # Restart container
docker pause CONTAINER                        # Pause container
docker unpause CONTAINER                      # Unpause container
docker kill CONTAINER                         # Kill container (SIGKILL)
docker rm CONTAINER                           # Remove stopped container
docker rm -f CONTAINER                        # Force remove running container

# Container inspection
docker logs CONTAINER                         # View logs
docker logs -f CONTAINER                      # Follow logs
docker logs --tail 100 CONTAINER              # Last 100 lines
docker logs --since="2h" CONTAINER            # Logs from last 2 hours
docker inspect CONTAINER                      # Detailed info
docker stats CONTAINER                        # Real-time stats
docker top CONTAINER                          # Running processes
docker exec -it CONTAINER bash                # Execute command in running container
```

### Container Resource Management

```bash
# Memory limits
docker run -m 512m nginx                      # Limit to 512MB RAM
docker run --memory=1g nginx                  # Limit to 1GB RAM
docker run --oom-kill-disable -m 512m nginx   # Disable OOM killer

# CPU limits
docker run --cpus=1.5 nginx                   # Limit to 1.5 CPU cores
docker run --cpu-shares=512 nginx             # Relative CPU weight
docker run --cpuset-cpus="0,1" nginx          # Pin to specific CPU cores

# Combined resource limits
docker run -m 1g --cpus=2 --name webapp nginx

# Disk I/O limits
docker run --device-read-bps /dev/sda:1mb nginx    # Read speed limit
docker run --device-write-bps /dev/sda:1mb nginx   # Write speed limit
```

---

## 🖼️ Image Management

### Basic Image Operations

```bash
# Image lifecycle
docker images                                 # List local images
docker pull IMAGE[:TAG]                       # Download image
docker push IMAGE[:TAG]                       # Upload image to registry
docker rmi IMAGE                              # Remove image
docker rmi -f IMAGE                           # Force remove image
docker prune images                           # Remove unused images

# Image inspection
docker inspect IMAGE                          # Detailed image info
docker history IMAGE                          # Image layer history
docker image ls --digests                     # Show image digests
docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Image tagging
docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]
docker tag myapp:latest myapp:v1.0
docker tag myapp:latest registry.com/myapp:latest
```

### Advanced Image Operations

```bash
# Image analysis
docker image inspect --format='{{.Config.Env}}' IMAGE    # Environment variables
docker image inspect --format='{{.Architecture}}' IMAGE  # Architecture
docker image inspect --format='{{.Os}}' IMAGE            # Operating system
docker image inspect --format='{{.Size}}' IMAGE          # Image size

# Image cleanup
docker image prune                            # Remove dangling images
docker image prune -a                         # Remove all unused images
docker image prune --filter "until=24h"      # Remove images older than 24h
docker system prune -a --volumes             # Comprehensive cleanup

# Export/Import images
docker save IMAGE > image.tar                # Export image to tar
docker save IMAGE | gzip > image.tar.gz      # Compressed export
docker load < image.tar                      # Import image from tar
docker export CONTAINER > container.tar      # Export container filesystem
docker import container.tar IMAGE:TAG        # Import container as image
```

---

## 📝 Dockerfile Reference

### Essential Instructions

```dockerfile
# Base image
FROM ubuntu:20.04
FROM node:18-alpine AS builder
FROM scratch

# Metadata
LABEL maintainer="you@example.com"
LABEL version="1.0"
LABEL description="My application"

# Environment
ENV NODE_ENV=production
ENV PATH="/app/bin:$PATH"
ARG BUILD_DATE
ARG VERSION=latest

# Working directory
WORKDIR /app
WORKDIR /usr/src/app

# Copy files
COPY package*.json ./
COPY --from=builder /app/dist ./dist
COPY --chown=node:node . .
ADD https://example.com/file.tar.gz /tmp/

# Dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Multi-line RUN with cleanup
RUN set -ex \
    && npm install --only=production \
    && npm cache clean --force

# User management
USER node
USER 1001:1001

# Networking
EXPOSE 8080
EXPOSE 8080/tcp
EXPOSE 53/udp

# Startup
CMD ["npm", "start"]
ENTRYPOINT ["./entrypoint.sh"]
ENTRYPOINT ["npm", "start"]
CMD ["--help"]  # Default arguments for ENTRYPOINT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Volumes
VOLUME ["/data"]
VOLUME ["/var/log", "/var/lib/app"]
```

### Dockerfile Best Practices

```dockerfile
# Multi-stage build example
FROM node:18-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runtime
# Security: non-root user
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=base --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --chown=nextjs:nodejs package*.json ./

USER nextjs
EXPOSE 3000
ENV NODE_ENV=production
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### .dockerignore Patterns

```dockerignore
# Version control
.git
.gitignore

# Dependencies
node_modules
npm-debug.log*

# Environment files
.env
.env.local
.env.*.local

# Build outputs
dist/
build/
*.log

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Documentation
*.md
LICENSE
docs/

# Test files
tests/
__tests__/
*.test.js
coverage/

# Development files
docker-compose.yml
docker-compose.*.yml
Dockerfile*
```

---

## ⚡ BuildKit Advanced

### BuildKit Features

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
docker buildx create --use

# Advanced build options
docker build --progress=plain .                    # Detailed build output
docker build --no-cache .                         # Disable cache
docker build --target production .                # Build specific stage
docker build --platform linux/amd64,linux/arm64 . # Multi-platform

# Cache management
docker build --cache-from=myapp:cache .           # Use external cache
docker build --cache-to=type=registry,ref=myapp:cache . # Export cache
```

### BuildKit Dockerfile Syntax

```dockerfile
# syntax=docker/dockerfile:1.4

FROM alpine AS base
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --update git

FROM node:18-alpine AS deps
WORKDIR /app
# Cache mount for npm
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    npm ci --production

FROM node:18-alpine AS builder
WORKDIR /app
# Secret mount (never stored in image)
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install

# SSH mount for private repos
RUN --mount=type=ssh git clone git@github.com:user/private-repo.git

# Bind mount (read-only access to build context)
RUN --mount=type=bind,source=.,target=/src \
    cp -r /src /app

FROM scratch AS runtime
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./
CMD ["node", "index.js"]
```

### Multi-Architecture Builds

```bash
# Setup buildx
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# Multi-platform builds
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --tag myapp:latest \
    --push .

# Local multi-arch testing
docker buildx build \
    --platform linux/arm64 \
    --load \
    --tag myapp:arm64 .

# Build with attestations
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --attest type=provenance,mode=max \
    --attest type=sbom \
    --tag myapp:latest \
    --push .
```

---

## 🔧 Container Operations

### Health Checks & Restart Policies

```bash
# Health check examples
docker run -d \
    --health-cmd="curl -f http://localhost:8080/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --health-start-period=60s \
    nginx

# Restart policies
docker run -d --restart=no nginx              # Never restart
docker run -d --restart=on-failure nginx     # Restart on failure
docker run -d --restart=on-failure:3 nginx   # Max 3 restart attempts
docker run -d --restart=always nginx         # Always restart
docker run -d --restart=unless-stopped nginx # Restart unless manually stopped

# Resource constraints with health checks
docker run -d \
    --name web \
    --restart=unless-stopped \
    --memory=512m \
    --cpus=1 \
    --health-cmd="curl -f http://localhost || exit 1" \
    --health-interval=30s \
    nginx
```

### Signal Handling

```bash
# Send signals to containers
docker kill --signal=SIGTERM CONTAINER       # Graceful shutdown
docker kill --signal=SIGUSR1 CONTAINER       # Custom signal
docker kill --signal=SIGHUP CONTAINER        # Reload configuration

# Container with proper signal handling
docker run -d \
    --name app \
    --init \
    myapp:latest

# Stop containers gracefully
docker stop --time=30 CONTAINER              # Wait 30s before SIGKILL
```

### Container Debugging

```bash
# Debug running containers
docker exec -it CONTAINER bash               # Interactive shell
docker exec -it CONTAINER sh                 # Alpine shell
docker exec CONTAINER ps aux                 # List processes
docker exec CONTAINER netstat -tulpn         # Network connections
docker exec CONTAINER df -h                  # Disk usage

# Debug stopped containers
docker logs CONTAINER                        # Container logs
docker inspect CONTAINER                     # Container config
docker diff CONTAINER                        # Filesystem changes
docker cp CONTAINER:/path/to/file ./         # Copy files out

# Performance debugging
docker stats --no-stream                     # Resource usage snapshot
docker system events                         # Real-time system events
docker system df                             # Disk usage summary
```

---

## 🌐 Networking

### Network Management

```bash
# Network operations
docker network ls                            # List networks
docker network create mynetwork              # Create network
docker network create --driver bridge mynet  # Specify driver
docker network rm mynetwork                  # Remove network
docker network prune                         # Remove unused networks

# Network inspection
docker network inspect mynetwork             # Network details
docker network inspect bridge               # Default bridge network

# Connect containers to networks
docker run -d --network=mynetwork nginx      # Connect at startup
docker network connect mynetwork CONTAINER  # Connect running container
docker network disconnect mynetwork CONTAINER # Disconnect container
```

### Advanced Networking

```bash
# Custom bridge networks
docker network create \
    --driver=bridge \
    --subnet=172.20.0.0/16 \
    --ip-range=172.20.240.0/20 \
    --gateway=172.20.0.1 \
    mybridge

# Host networking
docker run -d --network=host nginx           # Use host network stack

# Container networking
docker run -d --network=container:web nginx  # Share network with 'web'

# None networking
docker run -d --network=none alpine          # No network access

# Custom DNS
docker run -d \
    --dns=8.8.8.8 \
    --dns-search=example.com \
    --hostname=myhost \
    nginx

# Port mapping advanced
docker run -d \
    -p 127.0.0.1:8080:80 \
    -p 8443:443 \
    -p 3000-3005:3000-3005 \
    nginx
```

### Service Discovery

```bash
# Container linking (legacy)
docker run -d --name db mysql
docker run -d --link db:database webapp

# Modern service discovery with custom networks
docker network create myapp
docker run -d --network=myapp --name db mysql
docker run -d --network=myapp --name web nginx
# 'web' can reach 'db' by name

# External service discovery
docker run -d \
    --add-host=api.example.com:192.168.1.100 \
    nginx
```

---

## 💾 Storage & Volumes

### Volume Management

```bash
# Volume operations
docker volume ls                             # List volumes
docker volume create myvolume                # Create named volume
docker volume inspect myvolume               # Volume details
docker volume rm myvolume                    # Remove volume
docker volume prune                          # Remove unused volumes

# Volume mounting
docker run -v myvolume:/data nginx           # Named volume
docker run -v /host/path:/container/path nginx # Bind mount
docker run -v /host/path:/container/path:ro nginx # Read-only bind mount
docker run --tmpfs /tmp nginx                # tmpfs mount (in-memory)

# Advanced volume options
docker run -v myvolume:/data:Z nginx         # SELinux label (shared)
docker run -v myvolume:/data:z nginx         # SELinux label (private)
docker run --mount type=volume,source=myvolume,target=/data nginx

# Volume drivers
docker volume create \
    --driver local \
    --opt type=nfs \
    --opt o=addr=192.168.1.1,rw \
    --opt device=:/path/to/dir \
    nfs-volume
```

### Storage Patterns

```bash
# Backup and restore
docker run --rm \
    -v myvolume:/data \
    -v $(pwd):/backup \
    ubuntu \
    tar czf /backup/backup.tar.gz -C /data .

docker run --rm \
    -v myvolume:/data \
    -v $(pwd):/backup \
    ubuntu \
    tar xzf /backup/backup.tar.gz -C /data

# Data containers (legacy pattern)
docker create --name datastore -v /data ubuntu
docker run --volumes-from datastore nginx

# Modern data sharing
docker network create myapp
docker run -d --network=myapp -v shared:/data --name worker1 myapp
docker run -d --network=myapp -v shared:/data --name worker2 myapp
```

### Performance Optimization

```bash
# Volume performance options
docker run -v /data:/data:cached nginx       # macOS: relaxed consistency
docker run -v /data:/data:delegated nginx    # macOS: container authority
docker run -v /data:/data:consistent nginx   # Default: strict consistency

# tmpfs for temporary data
docker run --tmpfs /tmp:rw,size=100m nginx   # 100MB tmpfs

# Device mapping
docker run --device=/dev/sda:/dev/xvda nginx # Map block device
```

---

## 🎼 Docker Compose

### Basic Compose Operations

```bash
# Compose lifecycle
docker compose up                            # Start services
docker compose up -d                         # Start in background
docker compose up --build                    # Rebuild images
docker compose up --scale web=3              # Scale service
docker compose down                          # Stop and remove
docker compose down -v                       # Remove volumes too
docker compose restart                       # Restart services
docker compose pause                         # Pause services
docker compose unpause                       # Unpause services

# Service management
docker compose start SERVICE                 # Start specific service
docker compose stop SERVICE                  # Stop specific service
docker compose restart SERVICE               # Restart specific service
docker compose logs SERVICE                  # View service logs
docker compose logs -f SERVICE               # Follow service logs
docker compose exec SERVICE bash             # Execute in service
docker compose run SERVICE command           # Run one-off command

# Compose inspection
docker compose ps                            # List running services
docker compose top                           # Show running processes
docker compose port web 80                   # Show published port
docker compose config                        # Validate and view config
```

### Advanced Compose File

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
      cache_from:
        - myapp:cache
    image: myapp:latest
    container_name: web
    hostname: web-server
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
    env_file:
      - .env
      - .env.production
    ports:
      - "3000:3000"
      - "3001:3001"
    volumes:
      - ./app:/app
      - logs:/var/log
      - /etc/localtime:/etc/localtime:ro
    networks:
      - frontend
      - backend
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
        reservations:
          memory: 256M
          cpus: '0.5'
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    user: "1001:1001"

  db:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
      POSTGRES_DB: myapp
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - backend
    ports:
      - "127.0.0.1:5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    volumes:
      - redis_data:/data
      - ./redis.conf:/etc/redis/redis.conf:ro
    networks:
      - backend
    command: redis-server /etc/redis/redis.conf
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/ssl:ro
      - logs:/var/log/nginx
    networks:
      - frontend
    depends_on:
      - web

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  logs:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt

configs:
  nginx_config:
    file: ./nginx.conf
```

### Compose Profiles & Environments

```yaml
# Development profile
services:
  web:
    profiles: ["dev", "debug"]
    build:
      target: development
    volumes:
      - ./src:/app/src
    environment:
      - NODE_ENV=development

  debug:
    profiles: ["debug"]
    image: myapp:latest
    command: node --inspect=0.0.0.0:9229 app.js
    ports:
      - "9229:9229"
```

```bash
# Use profiles
docker compose --profile dev up          # Development services
docker compose --profile debug up        # Include debug services
COMPOSE_PROFILES=dev,debug docker compose up  # Environment variable
```

---

## 🛡️ Security

### Container Security Hardening

```bash
# Run as non-root user
docker run -u 1001:1001 nginx
docker run --user="nobody" nginx

# Drop capabilities
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx
docker run --cap-drop=ALL --cap-add=SETUID --cap-add=SETGID myapp

# Read-only filesystem
docker run --read-only --tmpfs /tmp nginx

# Security options
docker run --security-opt=no-new-privileges nginx
docker run --security-opt=apparmor:docker-default nginx
docker run --security-opt=seccomp:seccomp-profile.json nginx

# Resource limits for security
docker run \
    --memory=128m \
    --cpus=0.5 \
    --pids-limit=100 \
    --ulimit nofile=1024:1024 \
    nginx
```

### Secrets Management

```bash
# Docker secrets (Swarm mode)
echo "mysecret" | docker secret create db_password -
docker service create \
    --secret db_password \
    --name myapp \
    myapp:latest

# Secrets in Compose
docker compose up  # Uses secrets defined in compose file

# Environment variable secrets (less secure)
docker run -e DB_PASSWORD="$(cat db_password.txt)" myapp

# Vault integration example
docker run \
    -v vault-token:/vault/token:ro \
    --env VAULT_ADDR=https://vault.example.com \
    myapp
```

### Image Security

```dockerfile
# Security-focused Dockerfile
FROM node:18-alpine AS base

# Create non-root user
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nextjs -u 1001

# Security updates
RUN apk update && apk upgrade

FROM base AS deps
WORKDIR /app
USER nextjs
COPY --chown=nextjs:nodejs package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM base AS runtime
WORKDIR /app

# Copy application
COPY --from=deps --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .

# Security settings
USER nextjs
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

CMD ["node", "server.js"]
```

### Security Scanning

```bash
# Scan images for vulnerabilities
docker scout quickview
docker scout cves myapp:latest
docker scout recommendations myapp:latest

# Alternative scanners
trivy image myapp:latest
grype myapp:latest
clair-scanner --ip host.docker.internal myapp:latest
```

---

## 🚀 CI/CD & Multi-Architecture

### GitHub Actions Integration

```yaml
# .github/workflows/docker.yml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      attestations: write
      id-token: write

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

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

    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        attestations: type=provenance,mode=max
        sbom: true
```

### Multi-Architecture Builds

```bash
# Set up buildx
docker buildx create --name multibuilder --use
docker buildx inspect --bootstrap

# Build for multiple platforms
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --tag myapp:latest \
    --push .

# Build with cache optimization
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --cache-from type=registry,ref=myapp:buildcache \
    --cache-to type=registry,ref=myapp:buildcache,mode=max \
    --tag myapp:latest \
    --push .

# Local testing of different architectures
docker buildx build --platform linux/arm64 --load -t myapp:arm64 .
docker run --platform linux/arm64 myapp:arm64
```

### SBOM and Attestations

```bash
# Generate SBOM
docker buildx build \
    --sbom=true \
    --tag myapp:latest \
    --push .

# Generate provenance attestation
docker buildx build \
    --attest type=provenance,mode=max \
    --tag myapp:latest \
    --push .

# Combine SBOM and provenance
docker buildx build \
    --sbom=true \
    --attest type=provenance,mode=max \
    --tag myapp:latest \
    --push .

# View attestations
docker buildx imagetools inspect myapp:latest --format "{{ json .Attestations }}"
```

---

## 🏪 Registry Operations

### Registry Management

```bash
# Registry operations
docker login registry.example.com
docker login -u username -p password registry.com
docker logout registry.example.com

# Push/Pull from specific registries
docker tag myapp:latest registry.example.com/myapp:latest
docker push registry.example.com/myapp:latest
docker pull registry.example.com/myapp:latest

# Private registry with authentication
docker login \
    -u "$REGISTRY_USER" \
    -p "$REGISTRY_PASS" \
    "$REGISTRY_URL"
```

### Local Registry Setup

```bash
# Run local registry
docker run -d \
    -p 5000:5000 \
    --restart=unless-stopped \
    --name registry \
    -v registry-data:/var/lib/registry \
    registry:2

# Secure registry with TLS
docker run -d \
    -p 5000:5000 \
    --restart=unless-stopped \
    --name secure-registry \
    -v /certs:/certs \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
    -e REGISTRY_HTTP_TLS_PRIVATE_KEY=/certs/domain.key \
    -v registry-data:/var/lib/registry \
    registry:2

# Registry with authentication
docker run -d \
    -p 5000:5000 \
    --restart=unless-stopped \
    --name auth-registry \
    -v /auth:/auth \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    -v registry-data:/var/lib/registry \
    registry:2
```

### Registry Configuration

```yaml
# registry-config.yml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

### Registry Mirroring

```bash
# Configure Docker daemon for mirror
# /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://mirror.registry.com"
  ]
}

# Restart Docker daemon
sudo systemctl restart docker

# Pull-through cache registry
docker run -d \
    -p 5000:5000 \
    --restart=unless-stopped \
    --name mirror \
    -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
    registry:2
```

---

## 📊 Monitoring & Observability

### Container Monitoring

```bash
# Basic monitoring
docker stats                                 # All containers stats
docker stats CONTAINER                       # Specific container
docker stats --no-stream                     # One-time snapshot
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# System monitoring
docker system df                             # Disk usage
docker system events                         # Real-time events
docker system events --filter container=myapp
docker system events --since="2023-01-01T00:00:00"

# Resource usage
docker exec CONTAINER cat /sys/fs/cgroup/memory/memory.usage_in_bytes
docker exec CONTAINER cat /proc/meminfo
docker exec CONTAINER cat /proc/cpuinfo
```

### Logging Configuration

```bash
# Logging drivers
docker run -d --log-driver=json-file nginx
docker run -d --log-driver=syslog nginx
docker run -d --log-driver=journald nginx
docker run -d --log-driver=fluentd --log-opt fluentd-address=localhost:24224 nginx

# Log options
docker run -d \
    --log-driver=json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    nginx

# Centralized logging
docker run -d \
    --log-driver=fluentd \
    --log-opt fluentd-address=fluentd.example.com:24224 \
    --log-opt tag="docker.{{.Name}}" \
    nginx
```

### Prometheus Monitoring Stack

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro

volumes:
  prometheus_data:
  grafana_data:
```

---

## 🎯 Advanced Patterns

### Distroless Images

```dockerfile
# Multi-stage with distroless
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM gcr.io/distroless/static-debian11
COPY --from=builder /app/main /
EXPOSE 8080
USER 65534
ENTRYPOINT ["/main"]
```

### Scratch-based Images

```dockerfile
# Minimal scratch image
FROM scratch
COPY ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/binary /binary
EXPOSE 8080
ENTRYPOINT ["/binary"]
```

### Init Systems

```bash
# Use tini as init system
docker run -d --init nginx

# Manual tini usage
FROM alpine
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["my-app"]
```

### Development Containers

```json
// .devcontainer/devcontainer.json
{
  "name": "My Dev Container",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "forwardPorts": [3000, 8080],
  "postCreateCommand": "npm install",
  "remoteUser": "node",
  "mounts": [
    "source=${localWorkspaceFolder}/.git,target=/workspaces/${localWorkspaceFolderBasename}/.git,type=bind,consistency=cached"
  ]
}
```

---

## 🚨 Troubleshooting

### Common Issues & Solutions

```bash
# Container won't start
docker logs CONTAINER                        # Check startup logs
docker inspect CONTAINER                     # Check configuration
docker exec -it CONTAINER sh                 # Debug interactively

# Permission issues
docker exec CONTAINER ls -la /path           # Check file permissions
docker exec CONTAINER id                     # Check user/group
docker exec CONTAINER ps aux                 # Check running processes

# Network connectivity
docker exec CONTAINER ping host              # Test connectivity
docker exec CONTAINER nslookup domain        # DNS resolution
docker exec CONTAINER netstat -tulpn         # Network connections
docker network inspect NETWORK               # Network configuration

# Resource issues
docker stats                                 # Resource usage
docker system df                             # Disk usage
docker exec CONTAINER df -h                  # Container disk usage
docker exec CONTAINER free -h                # Container memory

# Image issues
docker image inspect IMAGE                   # Image details
docker history IMAGE                         # Layer history
docker image prune                           # Clean unused images
```

### Docker Daemon Issues

```bash
# Daemon status
sudo systemctl status docker
sudo journalctl -u docker.service

# Daemon configuration
sudo dockerd --debug                         # Debug mode
cat /etc/docker/daemon.json                 # Configuration file

# Reset Docker
sudo systemctl restart docker
docker system prune -a --volumes           # Nuclear option
```

### Performance Debugging

```bash
# I/O monitoring
docker exec CONTAINER iostat -x 1
docker exec CONTAINER iotop

# Memory analysis
docker exec CONTAINER cat /proc/meminfo
docker exec CONTAINER pmap PID

# CPU analysis
docker exec CONTAINER top
docker exec CONTAINER htop
docker exec CONTAINER cat /proc/cpuinfo
```

---

## 📚 Quick Reference Cards

### Essential Commands Card

```bash
# Container Lifecycle
docker run -d IMAGE                          # Run detached
docker stop CONTAINER                        # Stop container
docker start CONTAINER                       # Start container
docker rm CONTAINER                          # Remove container
docker ps                                    # List running
docker ps -a                                 # List all

# Images
docker images                                # List images
docker pull IMAGE                            # Download image
docker build -t NAME .                       # Build image
docker rmi IMAGE                             # Remove image

# Logs & Debug
docker logs -f CONTAINER                     # Follow logs
docker exec -it CONTAINER bash              # Interactive shell
docker inspect CONTAINER                     # Inspect container
docker stats CONTAINER                       # Container stats
```

### Dockerfile Quick Reference

```dockerfile
# Essential Instructions
FROM image:tag                               # Base image
WORKDIR /app                                 # Working directory
COPY . .                                     # Copy files
RUN command                                  # Run command
EXPOSE 8080                                  # Expose port
CMD ["command"]                              # Default command
ENTRYPOINT ["command"]                       # Entry point
ENV KEY=value                                # Environment variable
USER user                                   # Run as user
VOLUME /data                                 # Volume mount point
HEALTHCHECK CMD command                      # Health check
```

### Compose Quick Reference

```yaml
# Essential Compose Structure
version: '3.8'
services:
  app:
    build: .                                 # Build from Dockerfile
    image: image:tag                         # Use existing image
    ports: ["8080:8080"]                     # Port mapping
    volumes: ["./app:/app"]                  # Volume mapping
    environment: ["NODE_ENV=production"]     # Environment variables
    depends_on: ["db"]                       # Dependencies
    restart: unless-stopped                  # Restart policy
    networks: ["mynetwork"]                  # Networks

volumes:
  data:                                      # Named volume

networks:
  mynetwork:                                 # Custom network
```

### Security Checklist

- [ ] Use non-root user (`USER 1001:1001`)
- [ ] Drop all capabilities (`--cap-drop=ALL`)
- [ ] Use read-only filesystem (`--read-only`)
- [ ] Set resource limits (`--memory=128m --cpus=0.5`)
- [ ] Enable security options (`--security-opt=no-new-privileges`)
- [ ] Scan images for vulnerabilities
- [ ] Use secrets for sensitive data
- [ ] Keep base images updated
- [ ] Minimize image size
- [ ] Use distroless images when possible

### Performance Checklist

- [ ] Use multi-stage builds
- [ ] Optimize layer caching
- [ ] Use .dockerignore
- [ ] Minimize RUN instructions
- [ ] Use Alpine/slim base images
- [ ] Set appropriate resource limits
- [ ] Use volume caching for development
- [ ] Implement health checks
- [ ] Monitor resource usage
- [ ] Use init system for proper signal handling

---

## 🔗 Related Resources

### Learning Path Integration

- **[Phase 00: Foundations](../00-foundations)** - Container basics covered here
- **[Phase 01: Dockerfile Basics](../01-dockerfile-basics)** - Dockerfile reference expanded
- **[Phase 02: BuildKit Advanced](../02-buildkit-advanced)** - Advanced build patterns
- **[Phase 03: Container Operations](../03-container-operations)** - Operations commands
- **[Phase 04: Networking](../04-networking)** - Network configuration
- **[Phase 05: Storage](../05-storage)** - Volume management
- **[Phase 06: Compose](../06-compose)** - Multi-service orchestration
- **[Phase 07: Security](../07-security)** - Security hardening
- **[Phase 08: CI/CD & Buildx](../08-ci-cd-buildx)** - Build automation
- **[Phase 09: Registries](../09-registries)** - Registry operations
- **[Phase 10: Observability](../10-observability)** - Monitoring setup
- **[Phase 11: Advanced Images](../11-advanced-images)** - Optimization techniques

### Additional References

- **[Official Docker Documentation](https://docs.docker.com/)**
- **[Docker Best Practices](https://docs.docker.com/develop/best-practices/)**
- **[Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)**
- **[Compose File Reference](https://docs.docker.com/compose/compose-file/)**
- **[Docker Hub](https://hub.docker.com/)** - Public registry
- **[Docker Security](https://docs.docker.com/engine/security/)**

---

## 📖 Usage Guide

### How to Use This Cheatsheet

1. **Quick Reference**: Use the TOC to jump to specific sections
2. **Copy-Paste Ready**: All commands are tested and ready to use
3. **Progressive Learning**: Start with basics, advance through sections
4. **Real-World Examples**: Production-ready patterns and configurations
5. **Cross-Referenced**: Links to detailed learning path phases

### Bookmark This Guide

- **Print Version**: Generate PDF for offline reference
- **Mobile Friendly**: Responsive design for mobile devices
- **Search Friendly**: Use Ctrl+F to find specific commands
- **Version Control**: Track updates with Git history

---

*Last updated: 2025-01-09 | Docker Learning Path v2.0*

**[← Back to Learning Path](../README.md)** | **[Next: Advanced Labs →](../labs/README.md)**