# Micro-Lesson 01: Local Registry Setup and Configuration

> **Anchor**: `p09-m01-l01`  
> **Duration**: 3 minutes  
> **One Key Idea**: Master local Docker registry deployment with SSL, authentication, and basic push/pull operations for development environments

## Why It Matters

Local Docker registries are essential for development workflows, air-gapped environments, and testing scenarios. They provide complete control over image storage, reduce external dependencies, and enable secure, high-performance image distribution within private networks. Understanding local registry setup is fundamental to container infrastructure management.

## What to Learn

Master local registry fundamentals:
- **Basic registry deployment** - Core Docker Registry 2.x setup
- **SSL/TLS configuration** - Secure communication setup
- **Authentication integration** - User access control
- **Storage backend configuration** - Persistent and scalable storage

## Quick Local Registry Setup

### Basic Registry Deployment
```bash
# Pull official registry image
docker pull registry:2.8

# Run basic registry (insecure for testing only)
docker run -d \
  --name local-registry \
  --restart always \
  -p 5000:5000 \
  registry:2.8

# Test registry availability
curl http://localhost:5000/v2/

# Expected response: {}
```

### SSL-Enabled Registry
```bash
# Create directory structure
sudo mkdir -p /opt/registry/{certs,auth,data}

# Generate self-signed certificate (for testing)
sudo openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/domain.key \
  -x509 -days 365 \
  -out /opt/registry/certs/domain.crt \
  -subj "/CN=registry.local"

# Add to system trust (Ubuntu/Debian)
sudo cp /opt/registry/certs/domain.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Run SSL-enabled registry
docker run -d \
  --name secure-registry \
  --restart always \
  -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  -v /opt/registry/certs:/certs:ro \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2.8
```

### Registry with Authentication
```bash
# Create htpasswd file with test user
sudo htpasswd -Bc /opt/registry/auth/htpasswd testuser

# Registry configuration file
sudo tee /opt/registry/config.yml > /dev/null <<EOF
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
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd
EOF

# Run authenticated registry
docker run -d \
  --name auth-registry \
  --restart always \
  -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  -v /opt/registry/certs:/certs:ro \
  -v /opt/registry/auth:/auth:ro \
  -v /opt/registry/config.yml:/etc/docker/registry/config.yml:ro \
  registry:2.8
```

## Registry Testing and Validation

### Push/Pull Operations
```bash
# Login to registry
docker login registry.local:5000 -u testuser

# Tag and push test image
docker tag alpine:latest registry.local:5000/myapp:v1.0
docker push registry.local:5000/myapp:v1.0

# Verify repository creation
curl -k -u testuser:password https://registry.local:5000/v2/_catalog

# Pull image from registry
docker rmi registry.local:5000/myapp:v1.0
docker pull registry.local:5000/myapp:v1.0
```

### Registry API Exploration
```bash
# List repositories
curl -k -u testuser:password https://registry.local:5000/v2/_catalog

# List tags for repository
curl -k -u testuser:password https://registry.local:5000/v2/myapp/tags/list

# Get image manifest
curl -k -u testuser:password \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  https://registry.local:5000/v2/myapp/manifests/v1.0

# Check registry health
curl -k https://registry.local:5000/debug/health
```

## Advanced Configuration Options

### Storage Backend Configuration
```yaml
# config.yml - S3 storage backend
version: 0.1
log:
  level: info
storage:
  s3:
    accesskey: AKIAIOSFODNN7EXAMPLE
    secretkey: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    region: us-east-1
    bucket: my-registry-bucket
    encrypt: true
    secure: true
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd
```

### Registry with Redis Cache
```bash
# Start Redis for caching
docker run -d \
  --name registry-redis \
  --restart always \
  redis:alpine

# Registry with Redis cache configuration
cat > /opt/registry/config-with-cache.yml <<EOF
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  cache:
    blobdescriptor: redis
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
redis:
  addr: registry-redis:6379
  db: 0
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd
EOF

# Run registry with cache
docker run -d \
  --name cached-registry \
  --restart always \
  --link registry-redis \
  -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  -v /opt/registry/certs:/certs:ro \
  -v /opt/registry/auth:/auth:ro \
  -v /opt/registry/config-with-cache.yml:/etc/docker/registry/config.yml:ro \
  registry:2.8
```

## Docker Compose Setup

### Complete Registry Stack
```yaml
# docker-compose.yml
version: '3.8'

services:
  registry:
    image: registry:2.8
    container_name: local-registry
    restart: always
    ports:
      - "5000:5000"
    environment:
      REGISTRY_HTTP_TLS_CERTIFICATE: /certs/domain.crt
      REGISTRY_HTTP_TLS_KEY: /certs/domain.key
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
    volumes:
      - registry-data:/var/lib/registry
      - ./certs:/certs:ro
      - ./auth:/auth:ro
    networks:
      - registry-net

  redis:
    image: redis:alpine
    container_name: registry-cache
    restart: always
    networks:
      - registry-net

volumes:
  registry-data:

networks:
  registry-net:
    driver: bridge
```

### Deployment Commands
```bash
# Deploy registry stack
docker-compose up -d

# Check service status
docker-compose ps

# View registry logs
docker-compose logs registry

# Scale registry (if needed)
docker-compose up -d --scale registry=2
```

## Practice Tasks

1. **Deploy basic registry**:
   ```bash
   docker run -d -p 5000:5000 --name test-registry registry:2.8
   ```

2. **Configure SSL registry**:
   ```bash
   # Generate certs, create config, deploy with TLS
   ```

3. **Add authentication**:
   ```bash
   htpasswd -Bc auth/htpasswd myuser
   ```

4. **Test push/pull operations**:
   ```bash
   docker tag alpine:latest localhost:5000/alpine:test
   docker push localhost:5000/alpine:test
   ```

## Common Issues and Solutions

### Certificate Trust Issues
```bash
# Add registry cert to Docker daemon
sudo mkdir -p /etc/docker/certs.d/registry.local:5000
sudo cp /opt/registry/certs/domain.crt /etc/docker/certs.d/registry.local:5000/ca.crt
sudo systemctl restart docker
```

### Permission Problems
```bash
# Fix registry data permissions
sudo chown -R 1000:1000 /opt/registry/data
sudo chmod -R 755 /opt/registry
```

### DNS Resolution
```bash
# Add registry to /etc/hosts
echo "127.0.0.1 registry.local" | sudo tee -a /etc/hosts
```

## Production Considerations

### Security Best Practices
- **Use valid SSL certificates** from trusted CA
- **Implement proper authentication** (LDAP/OAuth preferred over htpasswd)
- **Regular security updates** of registry software
- **Network isolation** with proper firewall rules

### Performance Optimization
- **Use SSD storage** for registry data
- **Configure appropriate cache** settings
- **Monitor resource usage** and scale accordingly
- **Implement backup strategy** for registry data

### Monitoring and Logging
- **Enable debug endpoints** for metrics
- **Configure structured logging** for analysis
- **Set up health checks** for availability monitoring
- **Implement alerting** for critical issues

## Key Takeaway

Local Docker registry setup provides complete control over container image storage and distribution, enabling secure development workflows and private infrastructure deployment with proper SSL, authentication, and storage configuration.