# Phase 09 Lab: Registries Hands-On

> **Estimated Duration**: 4-5 hours  
> **Difficulty**: Advanced  
> **Prerequisites**: Phases 00-08 completed, Docker knowledge, basic networking

## 🧪 Lab Overview

This lab provides comprehensive hands-on experience with Docker registries, from basic private registry setup to enterprise-grade solutions with authentication, mirroring, and high availability. You'll build production-ready registry infrastructure that supports real-world development workflows.

## 📋 Lab Environment Setup

### Prerequisites Checklist
- [ ] Docker Desktop 4.0+ or Docker Engine 20.10+ installed
- [ ] Docker Compose v2.0+ available
- [ ] OpenSSL for certificate generation
- [ ] Basic understanding of networking and DNS
- [ ] Access to cloud storage (AWS S3, Google Cloud Storage) - optional

### Lab Infrastructure Requirements
```bash
# Minimum system requirements per registry node:
# - CPU: 2 cores
# - RAM: 4GB  
# - Storage: 50GB for registry data
# - Network: Stable internet connection

# Check system resources
echo "=== System Check ==="
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk space: $(df -h / | awk 'NR==2 {print $4}')"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker compose version)"
```

### Lab Network Setup
```bash
# Create dedicated network for registry lab
docker network create registry-lab \
  --driver bridge \
  --subnet 172.20.0.0/16 \
  --gateway 172.20.0.1

# Verify network creation
docker network ls | grep registry-lab
```

## 🏗️ Lab 1: Basic Private Registry Setup

### Exercise 1.1: Deploy Simple Private Registry

#### Basic Registry Deployment
```bash
# Create directory structure
mkdir -p ~/registry-lab/{config,data,certs,auth,logs}
cd ~/registry-lab

# Generate self-signed certificates
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key \
  -x509 -days 365 \
  -out certs/domain.crt \
  -subj "/C=US/ST=CA/L=Lab/O=Registry-Lab/CN=registry.lab.local"

# Create basic registry configuration
cat > config/registry-config.yml << 'EOF'
version: 0.1
log:
  accesslog:
    disabled: false
  level: info
  formatter: text
  fields:
    service: registry
    environment: lab
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
    X-Frame-Options: [DENY]
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
  debug:
    addr: :5001
    prometheus:
      enabled: true
      path: /metrics
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# Create Docker Compose for basic registry
cat > docker-compose.basic-registry.yml << 'EOF'
version: '3.8'

services:
  registry:
    image: registry:2.8
    container_name: basic-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
      - "5001:5001"  # Debug/metrics port
    volumes:
      - ./data:/var/lib/registry
      - ./config/registry-config.yml:/etc/docker/registry/config.yml
      - ./certs:/certs:ro
      - ./logs:/var/log/registry
    environment:
      - REGISTRY_STORAGE_DELETE_ENABLED=true
    networks:
      - registry-lab
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5000/v2/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  registry-lab:
    external: true
EOF

# Deploy basic registry
docker compose -f docker-compose.basic-registry.yml up -d

# Verify registry is running
docker compose -f docker-compose.basic-registry.yml ps
curl -k https://localhost:5000/v2/
```

#### Test Basic Registry Operations
```bash
# Add registry to Docker daemon (insecure for lab)
echo '{
  "insecure-registries": ["localhost:5000", "registry.lab.local:5000"],
  "registry-mirrors": []
}' | sudo tee /etc/docker/daemon.json

# Restart Docker daemon (adjust for your system)
sudo systemctl restart docker  # Linux
# Or restart Docker Desktop on Windows/Mac

# Test push/pull operations
docker pull alpine:3.18
docker tag alpine:3.18 localhost:5000/lab/alpine:3.18
docker push localhost:5000/lab/alpine:3.18

# Verify image in registry
curl -k https://localhost:5000/v2/_catalog
curl -k https://localhost:5000/v2/lab/alpine/tags/list

# Test pull from registry
docker rmi localhost:5000/lab/alpine:3.18
docker pull localhost:5000/lab/alpine:3.18
```

### Exercise 1.2: Registry with Authentication

#### Setup HTTP Basic Authentication
```bash
# Create htpasswd file with multiple users
docker run --rm --entrypoint htpasswd \
  httpd:2.4-alpine -Bbn admin labpassword123 > auth/htpasswd

docker run --rm --entrypoint htpasswd \
  httpd:2.4-alpine -Bbn developer devpassword456 >> auth/htpasswd

docker run --rm --entrypoint htpasswd \
  httpd:2.4-alpine -Bbn readonly readpassword789 >> auth/htpasswd

# View created users
cat auth/htpasswd

# Create authenticated registry configuration
cat > config/auth-registry-config.yml << 'EOF'
version: 0.1
log:
  level: info
  formatter: json
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
  debug:
    addr: :5001
    prometheus:
      enabled: true
auth:
  htpasswd:
    realm: "Registry Lab"
    path: /auth/htpasswd
notifications:
  events:
    includereferences: true
  endpoints:
    - name: webhook
      url: https://webhook.site/unique-id
      headers:
        Authorization: [Bearer secret-token]
      timeout: 5s
      threshold: 3
      backoff: 1s
EOF

# Create authenticated registry service
cat > docker-compose.auth-registry.yml << 'EOF'
version: '3.8'

services:
  auth-registry:
    image: registry:2.8
    container_name: auth-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
      - "5001:5001"
    volumes:
      - ./data-auth:/var/lib/registry
      - ./config/auth-registry-config.yml:/etc/docker/registry/config.yml
      - ./certs:/certs:ro
      - ./auth:/auth:ro
    environment:
      - REGISTRY_AUTH=htpasswd
      - REGISTRY_AUTH_HTPASSWD_REALM=Registry Lab
      - REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd
    networks:
      - registry-lab

networks:
  registry-lab:
    external: true
EOF

# Deploy authenticated registry
docker compose -f docker-compose.auth-registry.yml up -d
```

#### Test Authentication
```bash
# Test without authentication (should fail)
docker pull alpine:3.18
docker tag alpine:3.18 localhost:5000/auth/alpine:3.18
docker push localhost:5000/auth/alpine:3.18  # Should fail with 401

# Login with credentials
docker login localhost:5000
# Username: admin
# Password: labpassword123

# Test authenticated operations
docker push localhost:5000/auth/alpine:3.18  # Should succeed
curl -u admin:labpassword123 -k https://localhost:5000/v2/_catalog

# Test different user permissions
docker logout localhost:5000
docker login localhost:5000  # Use developer credentials
docker push localhost:5000/auth/nginx:latest  # Test permissions

# Verify authentication logs
docker compose -f docker-compose.auth-registry.yml logs auth-registry | grep auth
```

## 🔄 Lab 2: Registry Mirroring and Caching

### Exercise 2.1: Docker Hub Pull-Through Cache

#### Configure Pull-Through Cache
```bash
# Create Docker Hub pull-through cache configuration
cat > config/mirror-config.yml << 'EOF'
version: 0.1
log:
  level: info
  formatter: json
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  maintenance:
    uploadpurging:
      enabled: true
      age: 72h
      interval: 12h
http:
  addr: :5000
  debug:
    addr: :5001
    prometheus:
      enabled: true
proxy:
  remoteurl: https://registry-1.docker.io
  username: your-dockerhub-username  # Optional, for rate limit increase
  password: your-dockerhub-token     # Optional
  ttl: 168h  # Cache images for 1 week
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# Create mirror service
cat > docker-compose.mirror.yml << 'EOF'
version: '3.8'

services:
  docker-mirror:
    image: registry:2.8
    container_name: docker-mirror
    restart: unless-stopped
    ports:
      - "5002:5000"
      - "5003:5001"
    volumes:
      - ./data-mirror:/var/lib/registry
      - ./config/mirror-config.yml:/etc/docker/registry/config.yml
    environment:
      - REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
      - REGISTRY_PROXY_TTL=168h
    networks:
      - registry-lab

networks:
  registry-lab:
    external: true
EOF

# Deploy mirror
docker compose -f docker-compose.mirror.yml up -d
```

#### Test Mirror Functionality
```bash
# Configure Docker to use mirror
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": ["http://localhost:5002"],
  "insecure-registries": ["localhost:5000", "localhost:5002"],
  "max-concurrent-downloads": 6,
  "max-concurrent-uploads": 5,
  "debug": false
}
EOF

# Restart Docker daemon
sudo systemctl restart docker

# Test mirror with timing
echo "=== Testing Mirror Performance ==="

# First pull (cache miss)
echo "First pull (should be slower):"
time docker pull nginx:alpine

# Second pull (cache hit)
echo "Second pull (should be faster):"
docker rmi nginx:alpine
time docker pull nginx:alpine

# Verify cache contents
curl http://localhost:5002/v2/_catalog
curl http://localhost:5002/v2/library/nginx/tags/list

# Check mirror metrics
curl http://localhost:5003/metrics | grep registry
```

### Exercise 2.2: Multi-Registry Mirror Setup

#### Create Advanced Mirror Configuration
```bash
# Create configuration for multiple upstream registries
cat > config/multi-mirror-config.yml << 'EOF'
version: 0.1
log:
  level: info
  formatter: json
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  maintenance:
    uploadpurging:
      enabled: true
      age: 72h
      interval: 12h
http:
  addr: :5000
middleware:
  registry:
    - name: proxy
      options:
        remoteurl: https://registry-1.docker.io
        ttl: 168h
    - name: redirect
      options:
        rules:
          - pattern: "^quay.io/(.*)$"
            replacement: "https://quay.io/v2/$1"
          - pattern: "^gcr.io/(.*)$"
            replacement: "https://gcr.io/v2/$1"
proxy:
  remoteurl: https://registry-1.docker.io
  ttl: 168h
health:
  storagedriver:
    enabled: true
EOF

# Create multi-mirror service
cat > docker-compose.multi-mirror.yml << 'EOF'
version: '3.8'

services:
  multi-mirror:
    image: registry:2.8
    container_name: multi-mirror
    restart: unless-stopped
    ports:
      - "5004:5000"
    volumes:
      - ./data-multi-mirror:/var/lib/registry
      - ./config/multi-mirror-config.yml:/etc/docker/registry/config.yml
    networks:
      - registry-lab

  # Additional service for registry statistics
  registry-stats:
    image: nginx:alpine
    container_name: registry-stats
    ports:
      - "8080:80"
    volumes:
      - ./web:/usr/share/nginx/html:ro
    networks:
      - registry-lab
    depends_on:
      - multi-mirror

networks:
  registry-lab:
    external: true
EOF

# Create simple stats web interface
mkdir -p web
cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Registry Lab Statistics</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .stats { background: #f5f5f5; padding: 20px; border-radius: 8px; }
        .metric { margin: 10px 0; }
    </style>
</head>
<body>
    <h1>Registry Lab Statistics</h1>
    <div class="stats">
        <div class="metric">Basic Registry: <a href="https://localhost:5000/v2/">https://localhost:5000/v2/</a></div>
        <div class="metric">Mirror Cache: <a href="http://localhost:5002/v2/">http://localhost:5002/v2/</a></div>
        <div class="metric">Multi-Mirror: <a href="http://localhost:5004/v2/">http://localhost:5004/v2/</a></div>
    </div>
</body>
</html>
EOF

# Deploy multi-mirror setup
docker compose -f docker-compose.multi-mirror.yml up -d
```

## 🔐 Lab 3: Advanced Authentication and Authorization

### Exercise 3.1: Token-Based Authentication

#### Setup JWT Token Service
```bash
# Generate JWT signing keys
mkdir -p tokens
openssl genpkey -algorithm RSA -out tokens/private_key.pem -pkcs8
openssl pkey -in tokens/private_key.pem -pubout -out tokens/public_key.pem

# Create token authentication service configuration
cat > config/token-auth-config.yml << 'EOF'
server:
  addr: ":5001"
  certificate: "/certs/domain.crt"
  key: "/certs/domain.key"

token:
  issuer: "Registry Lab Token Service"
  expiration: 900
  certificate: "/certs/public_key.pem"
  key: "/certs/private_key.pem"

users:
  "admin":
    password: "$2y$05$LO.vzwpWtQGqyPUHc.tcrmloD6kjVWpUl0v4W0CUG4UeSJJEYGqJe"
    actions: ["*"]
  "developer":
    password: "$2y$05$8B6TUkYuQHaE1p6/0Lz8lO1w2Y5c8xO.7Z3L.F0Q3tCXxVY4.Q1Ry"
    actions: ["pull", "push"]
  "readonly":
    password: "$2y$05$9C7UVlZvRI7eJ2q7/8M9m.1x3Z6d9yA.8A4M.G1R4uDYwWZ5.R2Sz"
    actions: ["pull"]

acl:
  - match: {account: "admin"}
    actions: ["*"]
    name: "*"
  
  - match: {account: "developer"}
    actions: ["pull", "push"] 
    name: "library/*"
    
  - match: {account: "developer"}
    actions: ["pull", "push"]
    name: "dev/*"
    
  - match: {account: "readonly"}
    actions: ["pull"]
    name: "*"
EOF

# Create registry config for token auth
cat > config/token-registry-config.yml << 'EOF'
version: 0.1
log:
  level: debug
  formatter: json
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
auth:
  token:
    realm: https://localhost:5001/auth
    service: "Registry Lab"
    issuer: "Registry Lab Token Service"
    rootcertbundle: /certs/public_key.pem
EOF

# Create token-based authentication setup
cat > docker-compose.token-auth.yml << 'EOF'
version: '3.8'

services:
  token-auth-service:
    image: cesanta/docker_auth:1.7
    container_name: token-auth-service
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - ./config/token-auth-config.yml:/config/auth_config.yml:ro
      - ./certs:/certs:ro
      - ./tokens:/certs:ro
    command: ["/config/auth_config.yml"]
    networks:
      - registry-lab

  token-registry:
    image: registry:2.8
    container_name: token-registry
    restart: unless-stopped
    ports:
      - "5005:5000"
    volumes:
      - ./data-token:/var/lib/registry
      - ./config/token-registry-config.yml:/etc/docker/registry/config.yml:ro
      - ./certs:/certs:ro
      - ./tokens:/certs:ro
    depends_on:
      - token-auth-service
    networks:
      - registry-lab

networks:
  registry-lab:
    external: true
EOF

# Deploy token authentication
docker compose -f docker-compose.token-auth.yml up -d
```

#### Test Token Authentication
```bash
# Test token-based authentication
echo "=== Testing Token Authentication ==="

# Try without authentication (should fail)
curl -k https://localhost:5005/v2/_catalog

# Get token manually
TOKEN=$(curl -k -u admin:admin123 \
  "https://localhost:5001/auth?service=Registry%20Lab&scope=repository:library/alpine:pull" | \
  jq -r '.token')

echo "Token: $TOKEN"

# Use token for authenticated request
curl -k -H "Authorization: Bearer $TOKEN" \
  https://localhost:5005/v2/_catalog

# Test Docker login with token auth
docker login localhost:5005
# Username: admin
# Password: admin123

# Test push with different permission levels
docker tag alpine:3.18 localhost:5005/library/alpine:token-test
docker push localhost:5005/library/alpine:token-test

# Test with developer account
docker logout localhost:5005
docker login localhost:5005  # Use developer credentials
docker tag nginx:alpine localhost:5005/dev/nginx:latest
docker push localhost:5005/dev/nginx:latest

# Test readonly access
docker logout localhost:5005
docker login localhost:5005  # Use readonly credentials
docker pull localhost:5005/library/alpine:token-test  # Should work
docker push localhost:5005/library/alpine:readonly-test  # Should fail
```

## 📦 Lab 4: Registry Lifecycle Management

### Exercise 4.1: Automated Cleanup and Retention

#### Create Registry Cleanup Script
```bash
# Create comprehensive cleanup script
cat > scripts/registry-cleanup.sh << 'EOF'
#!/bin/bash

set -euo pipefail

# Configuration
REGISTRY_HOST="${REGISTRY_HOST:-localhost:5000}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DRY_RUN="${DRY_RUN:-true}"
AUTH_USER="${AUTH_USER:-admin}"
AUTH_PASS="${AUTH_PASS:-labpassword123}"
LOG_FILE="/tmp/registry-cleanup-$(date +%Y%m%d-%H%M%S).log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function to make authenticated API calls
api_call() {
    local endpoint="$1"
    local method="${2:-GET}"
    
    curl -s -u "$AUTH_USER:$AUTH_PASS" \
         -X "$method" \
         -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
         "http://$REGISTRY_HOST$endpoint" 2>/dev/null || echo "{}"
}

# Get list of repositories
get_repositories() {
    api_call "/v2/_catalog" | jq -r '.repositories[]?' 2>/dev/null || true
}

# Get tags for a repository
get_tags() {
    local repo="$1"
    api_call "/v2/$repo/tags/list" | jq -r '.tags[]?' 2>/dev/null || true
}

# Get manifest digest
get_manifest_digest() {
    local repo="$1"
    local tag="$2"
    
    curl -s -u "$AUTH_USER:$AUTH_PASS" \
         -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
         -I "http://$REGISTRY_HOST/v2/$repo/manifests/$tag" 2>/dev/null | \
         grep -i docker-content-digest | cut -d' ' -f2 | tr -d '\r'
}

# Delete manifest by digest
delete_manifest() {
    local repo="$1"
    local digest="$2"
    
    if [ "$DRY_RUN" = "false" ]; then
        local response=$(api_call "/v2/$repo/manifests/$digest" "DELETE")
        log "Deleted $repo@$digest"
        return $?
    else
        log "Would delete $repo@$digest"
        return 0
    fi
}

# Get image creation date from manifest
get_image_date() {
    local repo="$1"
    local tag="$2"
    
    local manifest=$(api_call "/v2/$repo/manifests/$tag")
    local config_digest=$(echo "$manifest" | jq -r '.config.digest')
    
    if [ "$config_digest" != "null" ]; then
        local config=$(api_call "/v2/$repo/blobs/$config_digest")
        echo "$config" | jq -r '.created' 2>/dev/null || echo "1970-01-01T00:00:00Z"
    else
        echo "1970-01-01T00:00:00Z"
    fi
}

# Main cleanup function
main() {
    log "Starting registry cleanup"
    log "Registry: $REGISTRY_HOST"
    log "Retention: $RETENTION_DAYS days"
    log "Dry run: $DRY_RUN"
    
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%s)
    local total_processed=0
    local total_deleted=0
    
    # Process each repository
    get_repositories | while IFS= read -r repo; do
        if [ -n "$repo" ]; then
            log "Processing repository: $repo"
            local repo_processed=0
            local repo_deleted=0
            
            # Process each tag in repository
            get_tags "$repo" | while IFS= read -r tag; do
                if [ -n "$tag" ]; then
                    repo_processed=$((repo_processed + 1))
                    total_processed=$((total_processed + 1))
                    
                    local image_date=$(get_image_date "$repo" "$tag")
                    local image_timestamp=$(date -d "$image_date" +%s 2>/dev/null || echo 0)
                    
                    if [ $image_timestamp -lt $cutoff_date ]; then
                        log "  Tag $tag (created: $image_date) is older than $RETENTION_DAYS days"
                        local digest=$(get_manifest_digest "$repo" "$tag")
                        
                        if [ -n "$digest" ]; then
                            if delete_manifest "$repo" "$digest"; then
                                repo_deleted=$((repo_deleted + 1))
                                total_deleted=$((total_deleted + 1))
                            fi
                        fi
                    else
                        log "  Tag $tag (created: $image_date) is within retention period"
                    fi
                fi
            done
            
            log "Repository $repo: processed $repo_processed, deleted $repo_deleted"
        fi
    done
    
    # Run garbage collection if not dry run
    if [ "$DRY_RUN" = "false" ]; then
        log "Running garbage collection..."
        docker exec basic-registry registry garbage-collect /etc/docker/registry/config.yml
        log "Garbage collection completed"
    else
        log "Would run garbage collection"
    fi
    
    log "Cleanup completed: processed $total_processed, deleted $total_deleted"
    log "Log file: $LOG_FILE"
}

# Run main function
main "$@"
EOF

# Make script executable
chmod +x scripts/registry-cleanup.sh

# Test cleanup script (dry run)
./scripts/registry-cleanup.sh
```

#### Setup Automated Cleanup with Cron
```bash
# Create systemd service for registry cleanup
sudo tee /etc/systemd/system/registry-cleanup.service << 'EOF'
[Unit]
Description=Registry Cleanup Service
After=docker.service

[Service]
Type=oneshot
Environment=REGISTRY_HOST=localhost:5000
Environment=RETENTION_DAYS=30
Environment=DRY_RUN=false
Environment=AUTH_USER=admin
Environment=AUTH_PASS=labpassword123
ExecStart=/home/$(whoami)/registry-lab/scripts/registry-cleanup.sh
User=$(whoami)
Group=$(whoami)
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create timer for weekly cleanup
sudo tee /etc/systemd/system/registry-cleanup.timer << 'EOF'
[Unit]
Description=Weekly Registry Cleanup
Requires=registry-cleanup.service

[Timer]
OnCalendar=Sun 02:00
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF

# Enable and test the service
sudo systemctl daemon-reload
sudo systemctl enable registry-cleanup.timer
sudo systemctl start registry-cleanup.timer
sudo systemctl status registry-cleanup.timer

# Test manual execution
sudo systemctl start registry-cleanup.service
sudo journalctl -u registry-cleanup.service
```

## 🚀 Lab 5: Enterprise Registry Solutions

### Exercise 5.1: Harbor Registry Deployment

#### Deploy Harbor with Docker Compose
```bash
# Download Harbor installer
cd ~/registry-lab
wget https://github.com/goharbor/harbor/releases/download/v2.5.0/harbor-offline-installer-v2.5.0.tgz
tar xvf harbor-offline-installer-v2.5.0.tgz

# Configure Harbor
cd harbor
cp harbor.yml.tmpl harbor.yml

# Edit harbor.yml configuration
cat > harbor.yml << 'EOF'
hostname: harbor.lab.local

http:
  port: 80

https:
  port: 443
  certificate: /opt/harbor/certs/domain.crt
  private_key: /opt/harbor/certs/domain.key

harbor_admin_password: HarborAdmin123!

database:
  password: DatabasePassword123!
  max_idle_conns: 100
  max_open_conns: 900

data_volume: /opt/harbor/data

trivy:
  ignore_unfixed: false
  skip_update: false
  offline_scan: false
  security_check: vuln
  insecure: false

jobservice:
  max_job_workers: 10

notification:
  webhook_job_max_retry: 10

chart:
  absolute_url: disabled

log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor

_version: 2.5.0

proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy

upload_purging:
  enabled: true
  age: 168h
  interval: 24h
  dryrun: false
EOF

# Install Harbor
sudo ./install.sh --with-trivy --with-chartmuseum

# Verify Harbor installation
docker compose ps
curl -k https://harbor.lab.local
```

#### Configure Harbor Projects and Users
```bash
# Login to Harbor CLI (install harbor-cli first)
# Or use Harbor Web UI at https://harbor.lab.local
# Default credentials: admin / HarborAdmin123!

# Create Harbor configuration script
cat > scripts/harbor-setup.sh << 'EOF'
#!/bin/bash

HARBOR_URL="https://harbor.lab.local"
HARBOR_USER="admin"
HARBOR_PASSWORD="HarborAdmin123!"

# Function to make Harbor API calls
harbor_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    local auth_header="Authorization: Basic $(echo -n "$HARBOR_USER:$HARBOR_PASSWORD" | base64)"
    
    if [ -n "$data" ]; then
        curl -k -X "$method" \
             -H "Content-Type: application/json" \
             -H "$auth_header" \
             -d "$data" \
             "$HARBOR_URL/api/v2.0$endpoint"
    else
        curl -k -X "$method" \
             -H "$auth_header" \
             "$HARBOR_URL/api/v2.0$endpoint"
    fi
}

# Create projects
echo "Creating Harbor projects..."

# Development project
harbor_api "/projects" "POST" '{
  "project_name": "development",
  "public": false,
  "storage_limit": -1,
  "metadata": {
    "auto_scan": "true",
    "severity": "high",
    "reuse_sys_cve_allowlist": "true"
  }
}'

# Production project
harbor_api "/projects" "POST" '{
  "project_name": "production", 
  "public": false,
  "storage_limit": -1,
  "metadata": {
    "auto_scan": "true",
    "severity": "critical",
    "reuse_sys_cve_allowlist": "false"
  }
}'

# Create users
echo "Creating Harbor users..."

harbor_api "/users" "POST" '{
  "username": "developer",
  "email": "developer@example.com",
  "password": "DevPassword123!",
  "realname": "Developer User"
}'

harbor_api "/users" "POST" '{
  "username": "qa-user",
  "email": "qa@example.com", 
  "password": "QAPassword123!",
  "realname": "QA User"
}'

echo "Harbor setup completed!"
EOF

chmod +x scripts/harbor-setup.sh
./scripts/harbor-setup.sh
```

### Exercise 5.2: High Availability Registry Setup

#### Create Load Balanced Registry Cluster
```bash
# Create HA registry configuration
mkdir -p ha-registry/{node1,node2,node3,lb-config}

# Create shared storage configuration (using NFS for lab)
# In production, use proper shared storage like EFS, GCS, etc.

# Node 1 configuration
cat > ha-registry/node1/config.yml << 'EOF'
version: 0.1
log:
  level: info
storage:
  s3:
    accesskey: minioaccess
    secretkey: miniosecret
    region: us-east-1
    regionendpoint: http://minio:9000
    bucket: registry
    secure: false
    v4auth: true
    chunksize: 5242880
    rootdirectory: /
http:
  addr: :5000
  secret: shared-registry-secret-key
  debug:
    addr: :5001
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
redis:
  addr: redis:6379
  db: 0
EOF

# Create MinIO for shared storage (S3-compatible)
cat > docker-compose.ha-storage.yml << 'EOF'
version: '3.8'

services:
  minio:
    image: minio/minio:latest
    container_name: minio-storage
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ACCESS_KEY=minioaccess
      - MINIO_SECRET_KEY=miniosecret
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"
    networks:
      - registry-lab

  redis:
    image: redis:7-alpine
    container_name: redis-cache
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    networks:
      - registry-lab

volumes:
  minio-data:
  redis-data:

networks:
  registry-lab:
    external: true
EOF

# Create HA registry cluster
cat > docker-compose.ha-registry.yml << 'EOF'
version: '3.8'

services:
  registry-node1:
    image: registry:2.8
    container_name: registry-node1
    restart: unless-stopped
    ports:
      - "5001:5000"
    volumes:
      - ./ha-registry/node1/config.yml:/etc/docker/registry/config.yml
    depends_on:
      - minio
      - redis
    networks:
      - registry-lab

  registry-node2:
    image: registry:2.8
    container_name: registry-node2
    restart: unless-stopped
    ports:
      - "5002:5000"
    volumes:
      - ./ha-registry/node1/config.yml:/etc/docker/registry/config.yml
    depends_on:
      - minio
      - redis
    networks:
      - registry-lab

  registry-node3:
    image: registry:2.8
    container_name: registry-node3
    restart: unless-stopped
    ports:
      - "5003:5000"
    volumes:
      - ./ha-registry/node1/config.yml:/etc/docker/registry/config.yml
    depends_on:
      - minio
      - redis
    networks:
      - registry-lab

  nginx-lb:
    image: nginx:alpine
    container_name: registry-lb
    ports:
      - "5000:80"
    volumes:
      - ./ha-registry/lb-config/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - registry-node1
      - registry-node2
      - registry-node3
    networks:
      - registry-lab

networks:
  registry-lab:
    external: true
EOF

# Create nginx load balancer configuration
cat > ha-registry/lb-config/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream registry_backend {
        least_conn;
        server registry-node1:5000 max_fails=3 fail_timeout=30s;
        server registry-node2:5000 max_fails=3 fail_timeout=30s;
        server registry-node3:5000 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 80;
        client_max_body_size 0;
        chunked_transfer_encoding on;

        location / {
            proxy_pass http://registry_backend;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 900;
            proxy_request_buffering off;
        }

        location /v2/ {
            proxy_pass http://registry_backend;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 900;
            proxy_request_buffering off;
        }
    }
}
EOF

# Deploy HA registry setup
docker compose -f docker-compose.ha-storage.yml up -d
sleep 30  # Wait for storage to be ready

# Create bucket in MinIO
docker exec minio-storage mc alias set minio http://localhost:9000 minioaccess miniosecret
docker exec minio-storage mc mb minio/registry

# Deploy registry cluster
docker compose -f docker-compose.ha-registry.yml up -d

# Test HA setup
echo "Testing HA registry cluster..."
for i in {1..10}; do
    echo "Request $i:"
    curl -s http://localhost:5000/v2/ | head -1
    sleep 1
done
```

## 📊 Lab 6: Registry Monitoring and Analytics

### Exercise 6.1: Prometheus Monitoring Setup

#### Deploy Registry Monitoring Stack
```bash
# Create monitoring configuration
mkdir -p monitoring/{prometheus,grafana}

# Prometheus configuration
cat > monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'registry-basic'
    static_configs:
      - targets: ['basic-registry:5001']
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'registry-auth'
    static_configs:
      - targets: ['auth-registry:5001']
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'registry-ha-node1'
    static_configs:
      - targets: ['registry-node1:5001']
    scrape_interval: 30s

  - job_name: 'registry-ha-node2'
    static_configs:
      - targets: ['registry-node2:5001']
    scrape_interval: 30s

  - job_name: 'registry-ha-node3'
    static_configs:
      - targets: ['registry-node3:5001']
    scrape_interval: 30s

  - job_name: 'docker-mirror'
    static_configs:
      - targets: ['docker-mirror:5001']
    scrape_interval: 30s
EOF

# Grafana dashboard configuration
cat > monitoring/grafana/dashboard-registry.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Docker Registry Metrics",
    "tags": ["docker", "registry"],
    "timezone": "browser",
    "panels": [
      {
        "title": "HTTP Requests Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(registry_http_requests_total[5m])",
            "legendFormat": "{{job}} - {{method}} {{code}}"
          }
        ],
        "yAxes": [
          {
            "label": "Requests/sec"
          }
        ]
      },
      {
        "title": "Storage Size",
        "type": "singlestat",
        "targets": [
          {
            "expr": "registry_storage_bytes_total",
            "format": "bytes"
          }
        ]
      },
      {
        "title": "Repository Count",
        "type": "singlestat",
        "targets": [
          {
            "expr": "registry_storage_repositories_total"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF

# Deploy monitoring stack
cat > docker-compose.monitoring.yml << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    networks:
      - registry-lab

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=grafanapassword
      - GF_USERS_ALLOW_SIGN_UP=false
    networks:
      - registry-lab

volumes:
  prometheus-data:
  grafana-data:

networks:
  registry-lab:
    external: true
EOF

# Deploy monitoring
docker compose -f docker-compose.monitoring.yml up -d

echo "Monitoring stack deployed:"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/grafanapassword)"
```

## 🏆 Lab Validation and Assessment

### Comprehensive Testing Script
```bash
#!/bin/bash
# comprehensive-registry-test.sh

echo "🧪 Comprehensive Registry Lab Testing"
echo "===================================="

TESTS_PASSED=0
TESTS_TOTAL=0

# Test function
test_registry() {
    local name="$1"
    local endpoint="$2"
    local auth="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing $name... "
    
    local response
    if [ -n "$auth" ]; then
        response=$(curl -s -u "$auth" "$endpoint/v2/" 2>/dev/null)
    else
        response=$(curl -s "$endpoint/v2/" 2>/dev/null)
    fi
    
    if echo "$response" | grep -q "{}"; then
        echo "✅ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAIL"
    fi
}

# Test all registries
test_registry "Basic Registry" "http://localhost:5000" ""
test_registry "Auth Registry" "http://localhost:5000" "admin:labpassword123"
test_registry "Mirror Cache" "http://localhost:5002" ""
test_registry "Token Registry" "https://localhost:5005" ""
test_registry "HA Registry" "http://localhost:5000" ""

# Test Harbor if deployed
if docker ps | grep -q harbor; then
    test_registry "Harbor Registry" "https://harbor.lab.local" "admin:HarborAdmin123!"
fi

# Performance tests
echo ""
echo "🚀 Performance Testing"
echo "====================="

# Test mirror performance
echo "Testing mirror cache performance..."
docker pull nginx:alpine >/dev/null 2>&1
time_with_mirror=$(time (docker pull nginx:alpine >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}')
echo "Mirror cache pull time: $time_with_mirror"

# Test direct registry performance
echo "Testing direct registry performance..."
docker rmi nginx:alpine >/dev/null 2>&1
docker pull registry-1.docker.io/library/nginx:alpine >/dev/null 2>&1
time_direct=$(time (docker pull registry-1.docker.io/library/nginx:alpine >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}')
echo "Direct pull time: $time_direct"

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo "Tests passed: $TESTS_PASSED/$TESTS_TOTAL"
echo "Success rate: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Check your registry configurations."
    exit 1
fi
```

## 📚 Lab Summary

Upon completing this lab, you have:

1. **Deployed multiple registry types** - Basic, authenticated, mirrored, and enterprise registries
2. **Implemented authentication strategies** - Basic auth, token-based auth, and enterprise integration
3. **Configured registry mirroring** - Pull-through caches and multi-registry setups
4. **Automated lifecycle management** - Cleanup scripts, retention policies, and maintenance
5. **Deployed enterprise solutions** - Harbor registry with security scanning
6. **Implemented high availability** - Load-balanced registry clusters with shared storage
7. **Setup monitoring and alerting** - Prometheus metrics and Grafana dashboards

### Key Achievements

- ✅ **5+ different registry configurations** deployed and tested
- ✅ **Authentication and authorization** implemented and validated
- ✅ **Performance optimization** through caching and mirroring
- ✅ **Production-ready HA setup** with load balancing
- ✅ **Automated maintenance** with cleanup and monitoring
- ✅ **Enterprise integration** with Harbor and advanced features

These skills enable you to design and operate production-grade container registries that support enterprise development workflows with security, performance, and reliability.

---

💡 **Next Steps**: Apply these registry patterns to your organization's container infrastructure and explore advanced topics like cross-datacenter replication and disaster recovery strategies.