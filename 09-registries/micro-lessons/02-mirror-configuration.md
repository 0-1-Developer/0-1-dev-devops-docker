# Micro-Lesson 02: Registry Mirror and Pull-through Cache Configuration

> **Anchor**: `p09-m01-l02`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master registry mirroring and pull-through cache setup to optimize bandwidth usage, improve performance, and reduce external dependencies

## Why It Matters

Registry mirrors and pull-through caches dramatically improve container image pull performance while reducing bandwidth costs and external dependencies. They enable faster development workflows, support air-gapped environments, and provide resilience against external registry outages. Understanding mirror configuration is crucial for efficient container infrastructure.

## What to Learn

Master registry mirroring fundamentals:
- **Pull-through cache setup** - Automatic upstream caching
- **Mirror registry configuration** - Docker Hub and multi-registry mirrors
- **Cache optimization** - Performance and storage management
- **Upstream integration** - Multiple registry backend support

## Pull-through Cache Setup

### Docker Hub Mirror
```bash
# Create mirror configuration
sudo mkdir -p /opt/mirror/{config,data,certs}

# Mirror configuration file
sudo tee /opt/mirror/config/config.yml > /dev/null <<EOF
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
proxy:
  remoteurl: https://registry-1.docker.io
  username: dockerhub-username
  password: dockerhub-password
EOF

# Deploy Docker Hub mirror
docker run -d \
  --name docker-mirror \
  --restart always \
  -p 5000:5000 \
  -v /opt/mirror/data:/var/lib/registry \
  -v /opt/mirror/certs:/certs:ro \
  -v /opt/mirror/config/config.yml:/etc/docker/registry/config.yml:ro \
  registry:2.8
```

### Multi-Registry Mirror
```yaml
# config.yml - Multiple upstream registries
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
proxy:
  remoteurl: https://registry-1.docker.io
  username: dockerhub-username  
  password: dockerhub-password

# Additional proxy configurations for different namespaces
# Quay.io mirror
quay:
  proxy:
    remoteurl: https://quay.io
    username: quay-username
    password: quay-password

# Google Container Registry mirror  
gcr:
  proxy:
    remoteurl: https://gcr.io
    username: _json_key
    password: |
      {
        "type": "service_account",
        "project_id": "my-project"
      }
```

### Advanced Cache Configuration
```bash
# Enhanced mirror with caching optimizations
sudo tee /opt/mirror/config/optimized-config.yml > /dev/null <<EOF
version: 0.1
log:
  level: info
  formatter: json
storage:
  filesystem:
    rootdirectory: /var/lib/registry
    maxthreads: 100
  cache:
    blobdescriptor: inmemory
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
  headers:
    X-Content-Type-Options: [nosniff]
    Cache-Control: ['max-age=31536000']
proxy:
  remoteurl: https://registry-1.docker.io
  username: dockerhub-username
  password: dockerhub-password
  ttl: 168h
EOF
```

## Client Configuration

### Docker Daemon Configuration
```bash
# Configure Docker daemon to use mirror
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://mirror.registry.local:5000"
  ],
  "insecure-registries": [
    "mirror.registry.local:5000"
  ]
}
EOF

# Restart Docker daemon
sudo systemctl restart docker

# Verify mirror configuration
docker info | grep -A5 "Registry Mirrors"
```

### Docker Compose Mirror Usage
```yaml
# docker-compose.yml with mirror
version: '3.8'

services:
  app:
    # Image will be pulled through mirror
    image: nginx:alpine
    ports:
      - "80:80"
    environment:
      - REGISTRY_MIRROR=https://mirror.registry.local:5000

  cache-test:
    # Test pull-through cache
    image: redis:alpine
    ports:
      - "6379:6379"
```

## Testing Mirror Performance

### Cache Performance Test
```bash
#!/bin/bash
# mirror-performance-test.sh

MIRROR_URL="https://mirror.registry.local:5000"
TEST_IMAGES=(
  "alpine:3.18"
  "nginx:alpine"
  "redis:alpine"
  "postgres:15-alpine"
  "node:18-alpine"
)

echo "🚀 Mirror Performance Test"
echo "========================="

# Test 1: First pull (cache miss)
echo "Test 1: Cache Miss Performance"
for image in "${TEST_IMAGES[@]}"; do
  echo "Pulling $image (first time)..."
  time docker pull $image
  docker rmi $image
done

# Test 2: Second pull (cache hit)
echo ""
echo "Test 2: Cache Hit Performance"
for image in "${TEST_IMAGES[@]}"; do
  echo "Pulling $image (cached)..."
  time docker pull $image
  docker rmi $image
done

# Test 3: Cache statistics
echo ""
echo "Test 3: Mirror Statistics"
curl -k https://mirror.registry.local:5000/v2/_catalog | jq .

# Test 4: Cache size analysis
echo ""
echo "Test 4: Storage Usage"
sudo du -sh /opt/mirror/data/
```

### Mirror Health Monitoring
```bash
#!/bin/bash
# mirror-health-check.sh

MIRROR_URL="https://mirror.registry.local:5000"

echo "🔍 Mirror Health Check"
echo "====================="

# Check mirror availability
echo "1. Mirror Availability:"
if curl -k -s $MIRROR_URL/v2/ | grep -q "{}"; then
  echo "✅ Mirror is responding"
else
  echo "❌ Mirror is not responding"
fi

# Check upstream connectivity
echo ""
echo "2. Upstream Connectivity:"
if curl -s https://registry-1.docker.io/v2/ | grep -q "unauthorized"; then
  echo "✅ Docker Hub accessible"
else
  echo "❌ Docker Hub not accessible"
fi

# Check cache hit rate (requires logs analysis)
echo ""
echo "3. Cache Performance:"
PULLS=$(docker logs docker-mirror 2>&1 | grep -c "GET /v2/.*/blobs/")
CACHE_HITS=$(docker logs docker-mirror 2>&1 | grep -c "served from cache")
if [ $PULLS -gt 0 ]; then
  HIT_RATE=$((CACHE_HITS * 100 / PULLS))
  echo "Cache Hit Rate: $HIT_RATE%"
else
  echo "No pull statistics available"
fi

# Check storage usage
echo ""
echo "4. Storage Usage:"
sudo du -sh /opt/mirror/data/
```

## Advanced Mirror Scenarios

### Selective Mirror Configuration
```yaml
# config.yml - Namespace-specific mirroring
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000

# Default proxy for Docker Hub
proxy:
  remoteurl: https://registry-1.docker.io
  username: dockerhub-username
  password: dockerhub-password

# Mirror specific namespaces differently
middleware:
  registry:
    - name: cloudfront
      options:
        baseurl: https://d1234567890.cloudfront.net/
        privatekey: /etc/docker/cloudfront-private-key.pem
        keypairid: APKAJIGBJ4EXAMPLE

  repository:
    - name: my-company
      options:
        remoteurl: https://private.company.com/registry
        username: company-user
        password: company-pass
```

### High-Performance Mirror Stack
```yaml
# docker-compose.yml - HA mirror setup
version: '3.8'

services:
  mirror-1:
    image: registry:2.8
    restart: always
    ports:
      - "5000:5000"
    volumes:
      - ./config:/etc/docker/registry:ro
      - ./certs:/certs:ro  
      - ./data-1:/var/lib/registry
    environment:
      - REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=redis
      - REGISTRY_REDIS_ADDR=redis:6379
    depends_on:
      - redis
    networks:
      - mirror-net

  mirror-2:
    image: registry:2.8
    restart: always
    ports:
      - "5001:5000"
    volumes:
      - ./config:/etc/docker/registry:ro
      - ./certs:/certs:ro
      - ./data-2:/var/lib/registry
    environment:
      - REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=redis
      - REGISTRY_REDIS_ADDR=redis:6379
    depends_on:
      - redis
    networks:
      - mirror-net

  redis:
    image: redis:alpine
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - mirror-net

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - mirror-1
      - mirror-2
    networks:
      - mirror-net

volumes:
  redis-data:

networks:
  mirror-net:
    driver: bridge
```

### Load Balancer Configuration
```nginx
# nginx.conf - Mirror load balancing
events {
    worker_connections 1024;
}

http {
    upstream mirror_backend {
        server mirror-1:5000 weight=1 max_fails=3 fail_timeout=30s;
        server mirror-2:5000 weight=1 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 443 ssl http2;
        server_name mirror.registry.local;

        ssl_certificate /etc/nginx/certs/domain.crt;
        ssl_certificate_key /etc/nginx/certs/domain.key;
        ssl_protocols TLSv1.2 TLSv1.3;

        # Docker registry specific settings
        client_max_body_size 0;
        chunked_transfer_encoding on;
        
        location /v2/ {
            proxy_pass http://mirror_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Registry-specific headers
            proxy_set_header Docker-Content-Digest $upstream_http_docker_content_digest;
            proxy_buffering off;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
        }
    }
}
```

## Monitoring and Maintenance

### Mirror Metrics Collection
```bash
# Prometheus metrics configuration
sudo tee /opt/mirror/config/metrics-config.yml > /dev/null <<EOF
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  debug:
    addr: :5001
    prometheus:
      enabled: true
      path: /metrics
proxy:
  remoteurl: https://registry-1.docker.io
  username: dockerhub-username
  password: dockerhub-password
EOF

# Query mirror metrics
curl http://localhost:5001/metrics | grep registry_
```

### Automated Cache Management
```bash
#!/bin/bash
# cache-maintenance.sh

MIRROR_DATA="/opt/mirror/data"
MAX_SIZE_GB=100
RETENTION_DAYS=30

echo "🧹 Mirror Cache Maintenance"
echo "=========================="

# Check current cache size
CURRENT_SIZE=$(du -s "$MIRROR_DATA" | awk '{print $1/1024/1024}')
echo "Current cache size: ${CURRENT_SIZE}GB"

# Clean old cache entries if over limit
if (( $(echo "$CURRENT_SIZE > $MAX_SIZE_GB" | bc -l) )); then
  echo "Cache size exceeded limit, cleaning old entries..."
  
  # Remove cache entries older than retention period
  find "$MIRROR_DATA" -type f -mtime +$RETENTION_DAYS -delete
  
  # Clean empty directories
  find "$MIRROR_DATA" -type d -empty -delete
  
  NEW_SIZE=$(du -s "$MIRROR_DATA" | awk '{print $1/1024/1024}')
  echo "Cache cleaned. New size: ${NEW_SIZE}GB"
fi

# Log maintenance activity
echo "$(date): Cache maintenance completed" >> /var/log/mirror-maintenance.log
```

## Practice Tasks

1. **Deploy basic mirror**:
   ```bash
   # Configure Docker Hub mirror
   docker run -d -p 5000:5000 -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io registry:2.8
   ```

2. **Test cache performance**:
   ```bash
   # Time first pull vs second pull
   time docker pull nginx:alpine
   ```

3. **Configure client mirror**:
   ```bash
   # Update /etc/docker/daemon.json
   sudo systemctl restart docker
   ```

4. **Monitor cache metrics**:
   ```bash
   # Check mirror statistics and performance
   ```

## Troubleshooting Common Issues

### Cache Miss Problems
```bash
# Check upstream connectivity
curl -I https://registry-1.docker.io/v2/

# Verify mirror configuration
docker exec mirror-container cat /etc/docker/registry/config.yml

# Check mirror logs
docker logs mirror-container | grep -i error
```

### Authentication Issues
```bash
# Test upstream authentication
docker login registry-1.docker.io

# Verify mirror credentials
docker exec mirror-container env | grep REGISTRY_PROXY
```

### Performance Problems
```bash
# Monitor cache hit rate
docker logs mirror-container | grep -c "served from cache"

# Check storage performance
iostat -x 1 5

# Verify network connectivity
ping -c 5 registry-1.docker.io
```

## Key Takeaway

Registry mirrors and pull-through caches dramatically improve container image pull performance and reduce bandwidth usage through intelligent upstream caching, automated synchronization, and optimized local storage management.