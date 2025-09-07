# Phase 09: Registries

> **Focus**: Private registry setup, authentication, mirroring, and enterprise registry management  
> **Complexity**: Advanced  
> **Duration**: 4-6 hours

## 🎯 Learning Objectives

By the end of this phase, you will:

- **Deploy and configure private Docker registries** with secure authentication and authorization
- **Implement registry mirroring and caching** for improved performance and reliability
- **Master authentication strategies** including LDAP, OAuth, and certificate-based auth
- **Design retention policies and lifecycle management** for automated registry maintenance
- **Integrate registries with CI/CD pipelines** and development workflows
- **Implement high availability and disaster recovery** for production registry deployments

## 🏗️ Architecture Overview

Enterprise registry architecture enables:

```
┌─────────────────────────────────────────────────────────────────┐
│                Enterprise Registry Architecture                  │
└─────────────────────────────────────────────────────────────────┘

Internet ──────┐
               │
        ┌──────▼──────┐      ┌─────────────────┐      ┌─────────────┐
        │   Public    │      │    Private      │      │   Mirror    │
        │ Registries  │◀────▶│   Registry      │◀────▶│   Cache     │
        │             │      │                 │      │             │
        └─────────────┘      └─────────────────┘      └─────────────┘
                                      │
                             ┌────────▼────────┐
                             │  Authentication │
                             │    & Access     │
                             │    Control      │
                             └─────────────────┘
                                      │
        ┌─────────────────────────────────────────────────────────┐
        │                Development Teams                        │
        │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
        │  │   Dev   │  │  Prod   │  │   CI    │  │   QA    │   │
        │  │  Team   │  │ Deploy  │  │   CD    │  │  Team   │   │
        │  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
        └─────────────────────────────────────────────────────────┘
```

## 📚 Conceptual Foundation

### Registry Types and Use Cases

**Public Registries**:
- **Docker Hub** - Default public registry, rate limiting, official images
- **GitHub Container Registry** - Integrated with GitHub, package visibility
- **Quay.io** - Security scanning, build automation, team collaboration

**Private Registries**:
- **Docker Registry** - Lightweight, basic functionality, self-hosted
- **Harbor** - Enterprise features, replication, security scanning
- **Artifactory** - Multi-format support, enterprise integration
- **Cloud Registries** - AWS ECR, Google GCR, Azure ACR

### Registry Components

**Storage Backend**:
- **Local filesystem** - Simple setup, single node limitation
- **Object storage** - S3, GCS, Azure Blob, scalable and durable
- **Distributed storage** - Ceph, GlusterFS, high availability

**Authentication Methods**:
- **Basic auth** - Simple username/password authentication
- **Token-based** - JWT tokens, OAuth integration
- **Certificate auth** - Mutual TLS, PKI infrastructure
- **LDAP/AD integration** - Enterprise directory services

## 🚀 Private Registry Deployment

### Docker Registry Setup

#### Basic Registry Deployment
```bash
# Create registry storage directory
mkdir -p /opt/registry/{data,config,certs}

# Generate self-signed certificate (for testing)
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/domain.key \
  -x509 -days 365 \
  -out /opt/registry/certs/domain.crt \
  -subj "/C=US/ST=CA/L=San Francisco/O=MyOrg/CN=registry.example.com"

# Create registry configuration
cat > /opt/registry/config/config.yml << 'EOF'
version: 0.1
log:
  accesslog:
    disabled: false
  level: info
  formatter: text
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# Deploy registry with Docker Compose
cat > docker-compose.registry.yml << 'EOF'
version: '3.8'

services:
  registry:
    image: registry:2.8
    container_name: private-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - /opt/registry/data:/var/lib/registry
      - /opt/registry/config:/etc/docker/registry
      - /opt/registry/certs:/certs
    environment:
      - REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt
      - REGISTRY_HTTP_TLS_KEY=/certs/domain.key
      - REGISTRY_STORAGE_DELETE_ENABLED=true
    networks:
      - registry-network

networks:
  registry-network:
    driver: bridge
EOF

# Start the registry
docker-compose -f docker-compose.registry.yml up -d
```

### Authentication Configuration

#### Basic Authentication Setup
```bash
# Create htpasswd file
mkdir -p /opt/registry/auth

# Add users (replace with secure passwords)
docker run --rm --entrypoint htpasswd \
  httpd:2.4-alpine -Bbn admin secretpassword > /opt/registry/auth/htpasswd

docker run --rm --entrypoint htpasswd \
  httpd:2.4-alpine -Bbn developer devpassword >> /opt/registry/auth/htpasswd

# Update registry configuration
cat > /opt/registry/config/config.yml << 'EOF'
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

# Update Docker Compose with auth volume
cat >> docker-compose.registry.yml << 'EOF'
    volumes:
      - /opt/registry/data:/var/lib/registry
      - /opt/registry/config:/etc/docker/registry
      - /opt/registry/certs:/certs
      - /opt/registry/auth:/auth
EOF
```

#### Token-Based Authentication
```bash
# Generate JWT signing keys
mkdir -p /opt/registry/tokens
openssl genpkey -algorithm RSA -out /opt/registry/tokens/private_key.pem -pkcs8
openssl pkey -in /opt/registry/tokens/private_key.pem -pubout -out /opt/registry/tokens/public_key.pem

# Create token service configuration
cat > /opt/registry/config/auth-config.yml << 'EOF'
server:
  addr: ":5001"
token:
  issuer: "Auth Service"
  expiration: 900
users:
  admin:
    password: "$2y$05$LO.vzwpWtQGqyPUHc.tcrmloD6kjVWpUl0v4W0CUG4UeSJJEYGqJe"
    actions: ["*"]
  developer:
    password: "$2y$05$J8CHLEhQj5Q6FPZyLVU8ku5pLgT7T1T0K8LmCnU5kRxGgfX8ZqFLm"
    actions: ["pull", "push"]
acl:
  - match: {account: "admin"}
    actions: ["*"]
  - match: {account: "developer"}
    actions: ["pull", "push"]
    name: "library/*"
EOF

# Deploy token auth service
cat > docker-compose.auth.yml << 'EOF'
version: '3.8'

services:
  auth:
    image: cesanta/docker_auth:1.7
    container_name: registry-auth
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - /opt/registry/config/auth-config.yml:/config/auth_config.yml
      - /opt/registry/tokens:/config/tokens
    command: ["/config/auth_config.yml"]
    networks:
      - registry-network

networks:
  registry-network:
    external: true
EOF
```

## 🔄 Registry Mirroring and Caching

### Pull-Through Cache Setup

#### Docker Hub Mirror Configuration
```bash
# Create mirror configuration
cat > /opt/registry/config/mirror-config.yml << 'EOF'
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
proxy:
  remoteurl: https://registry-1.docker.io
  username: your-dockerhub-username
  password: your-dockerhub-token
  ttl: 168h
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# Deploy pull-through cache
cat > docker-compose.mirror.yml << 'EOF'
version: '3.8'

services:
  docker-mirror:
    image: registry:2.8
    container_name: docker-mirror
    restart: unless-stopped
    ports:
      - "5001:5000"
    volumes:
      - /opt/registry/mirror-data:/var/lib/registry
      - /opt/registry/config/mirror-config.yml:/etc/docker/registry/config.yml
    environment:
      - REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
    networks:
      - registry-network

networks:
  registry-network:
    driver: bridge
EOF

# Configure Docker daemon to use mirror
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": ["https://mirror.example.com:5001"],
  "insecure-registries": ["mirror.example.com:5001"],
  "max-concurrent-downloads": 6,
  "max-concurrent-uploads": 5
}
EOF

# Restart Docker daemon
sudo systemctl restart docker
```

### Multi-Registry Mirror Setup
```bash
# Create configuration for multiple registry mirrors
cat > /opt/registry/config/multi-mirror.yml << 'EOF'
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
middleware:
  registry:
    - name: cloudfront
      options:
        baseurl: https://d1234567890123.cloudfront.net/
        privatekey: /etc/docker/registry/cloudfront-private-key.pem
        keypairid: ABCDEFGHIJKLMNOPQR
proxy:
  remoteurl: https://registry-1.docker.io
  ttl: 168h
  health:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# Configure Docker for multiple mirrors
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://primary-mirror.example.com:5000",
    "https://backup-mirror.example.com:5000",
    "https://regional-mirror.example.com:5000"
  ],
  "max-concurrent-downloads": 8,
  "max-concurrent-uploads": 6,
  "storage-driver": "overlay2"
}
EOF
```

## 🔐 Advanced Authentication and Authorization

### LDAP Integration

#### LDAP Authentication Configuration
```yaml
# registry-config-ldap.yml
version: 0.1
log:
  level: info
storage:
  s3:
    accesskey: myaccesskey
    secretkey: mysecretkey
    region: us-west-2
    bucket: my-registry-bucket
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
auth:
  ldap:
    realm: ldap-realm
    host: ldap.example.com
    port: 389
    insecure: false
    starttls: true
    base: dc=example,dc=com
    s: uid
    mail: mail
    bind: cn=admin,dc=example,dc=com
    password: adminpassword
    filter: "(&(objectClass=person)(uid={username}))"
    group_search:
      base_dn: ou=groups,dc=example,dc=com
      filter: "(memberUid={username})"
      name_attribute: cn
notifications:
  events:
    includereferences: true
  endpoints:
    - name: webhook
      url: https://webhook.example.com/registry
      headers:
        Authorization: [Bearer token123]
```

### OAuth2 Integration
```yaml
# OAuth2 with GitHub
version: 0.1
auth:
  oauth:
    realm: oauth-realm
    service: registry
    issuer: https://auth.example.com
    rootcertbundle: /certs/oauth-ca.crt
  token:
    realm: https://auth.example.com/auth
    service: registry
    issuer: github-oauth
    rootcertbundle: /certs/github-ca.crt
```

## 📦 Registry Lifecycle Management

### Automated Retention Policies

#### Cleanup Script for Registry
```bash
#!/bin/bash
# registry-cleanup.sh

REGISTRY_HOST="registry.example.com:5000"
RETENTION_DAYS=30
DRY_RUN=${DRY_RUN:-true}

echo "🧹 Registry Cleanup Script"
echo "Registry: $REGISTRY_HOST"
echo "Retention: $RETENTION_DAYS days"
echo "Dry run: $DRY_RUN"

# Function to get repositories
get_repositories() {
    curl -s -u admin:password "https://$REGISTRY_HOST/v2/_catalog" | \
    jq -r '.repositories[]'
}

# Function to get tags for a repository
get_tags() {
    local repo=$1
    curl -s -u admin:password "https://$REGISTRY_HOST/v2/$repo/tags/list" | \
    jq -r '.tags[]?' 2>/dev/null || echo ""
}

# Function to get manifest creation date
get_manifest_date() {
    local repo=$1
    local tag=$2
    local manifest_headers=$(curl -s -I -u admin:password \
        -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
        "https://$REGISTRY_HOST/v2/$repo/manifests/$tag")
    echo "$manifest_headers" | grep -i "docker-content-digest" | cut -d' ' -f2 | tr -d '\r'
}

# Function to delete manifest
delete_manifest() {
    local repo=$1
    local digest=$2
    if [ "$DRY_RUN" = "false" ]; then
        curl -X DELETE -u admin:password \
            "https://$REGISTRY_HOST/v2/$repo/manifests/$digest"
        echo "Deleted $repo:$digest"
    else
        echo "Would delete $repo:$digest"
    fi
}

# Main cleanup logic
main() {
    local cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%s)
    
    get_repositories | while read repo; do
        echo "Processing repository: $repo"
        
        get_tags "$repo" | while read tag; do
            if [ -n "$tag" ]; then
                local digest=$(get_manifest_date "$repo" "$tag")
                local manifest_date=$(date -d "$(echo $digest | cut -c8-27)" +%s 2>/dev/null || echo 0)
                
                if [ $manifest_date -lt $cutoff_date ]; then
                    echo "  Tag $tag is older than $RETENTION_DAYS days"
                    delete_manifest "$repo" "$digest"
                else
                    echo "  Tag $tag is within retention period"
                fi
            fi
        done
    done
    
    # Run garbage collection
    if [ "$DRY_RUN" = "false" ]; then
        echo "Running garbage collection..."
        docker exec registry-container registry garbage-collect /etc/docker/registry/config.yml
    else
        echo "Would run garbage collection"
    fi
}

main
```

#### Automated Cleanup with Cron
```bash
# Create systemd service for registry cleanup
cat > /etc/systemd/system/registry-cleanup.service << 'EOF'
[Unit]
Description=Registry Cleanup Service
After=docker.service

[Service]
Type=oneshot
Environment=REGISTRY_HOST=registry.example.com:5000
Environment=RETENTION_DAYS=30
Environment=DRY_RUN=false
ExecStart=/opt/registry/scripts/registry-cleanup.sh
User=registry
Group=registry

[Install]
WantedBy=multi-user.target
EOF

# Create timer for weekly cleanup
cat > /etc/systemd/system/registry-cleanup.timer << 'EOF'
[Unit]
Description=Weekly Registry Cleanup
Requires=registry-cleanup.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
sudo systemctl enable registry-cleanup.timer
sudo systemctl start registry-cleanup.timer
```

## 🔧 Enterprise Registry Solutions

### Harbor Deployment

#### Harbor with Docker Compose
```yaml
# harbor-docker-compose.yml
version: '3.8'

services:
  registry:
    image: goharbor/registry-photon:v2.5.0
    container_name: registry
    restart: always
    volumes:
      - registry_data:/storage
      - ./config/registry/:/etc/registry/
    networks:
      - harbor
    dns_search: .
    depends_on:
      - log

  registryctl:
    image: goharbor/harbor-registryctl:v2.5.0
    container_name: registryctl
    env_file:
      - ./config/registryctl/env
    restart: always
    volumes:
      - registry_data:/storage
      - ./config/registry/:/etc/registry/
      - type: bind
        source: ./config/registryctl/config.yml
        target: /etc/registryctl/config.yml
    networks:
      - harbor
    dns_search: .
    depends_on:
      - log

  postgresql:
    image: goharbor/harbor-db:v2.5.0
    container_name: harbor-db
    restart: always
    volumes:
      - database:/var/lib/postgresql/data
    networks:
      harbor:
    dns_search: .
    env_file:
      - ./config/db/env
    depends_on:
      - log

  core:
    image: goharbor/harbor-core:v2.5.0
    container_name: harbor-core
    env_file:
      - ./config/core/env
    restart: always
    volumes:
      - config_data:/etc/core/
      - job_logs:/var/log/jobs
      - registry_data:/storage
    networks:
      harbor:
    dns_search: .
    depends_on:
      - log
      - registry
      - redis
      - postgresql

  portal:
    image: goharbor/harbor-portal:v2.5.0
    container_name: harbor-portal
    restart: always
    networks:
      - harbor
    dns_search: .
    depends_on:
      - log

  jobservice:
    image: goharbor/harbor-jobservice:v2.5.0
    container_name: harbor-jobservice
    env_file:
      - ./config/jobservice/env
    restart: always
    volumes:
      - job_logs:/var/log/jobs
      - registry_data:/storage
    networks:
      - harbor
    dns_search: .
    depends_on:
      - log
      - redis

  redis:
    image: goharbor/redis-photon:v2.5.0
    container_name: redis
    restart: always
    volumes:
      - redis_data:/var/lib/redis
    networks:
      harbor:
    dns_search: .
    depends_on:
      - log

  proxy:
    image: goharbor/nginx-photon:v2.5.0
    container_name: nginx
    restart: always
    volumes:
      - ./config/nginx:/etc/nginx:z
    networks:
      - harbor
    dns_search: .
    ports:
      - 80:8080
      - 443:8443
    depends_on:
      - registry
      - core
      - portal

  log:
    image: goharbor/harbor-log:v2.5.0
    container_name: harbor-log
    restart: always
    volumes:
      - log_data:/var/log/docker/

networks:
  harbor:
    external: false

volumes:
  registry_data:
  database:
  config_data:
  job_logs:
  redis_data:
  log_data:
```

## 🚀 High Availability and Disaster Recovery

### Multi-Node Registry Setup
```bash
# Load balancer configuration for HA registry
cat > /etc/nginx/sites-available/registry-lb << 'EOF'
upstream registry_backend {
    server registry1.example.com:5000 max_fails=3 fail_timeout=30s;
    server registry2.example.com:5000 max_fails=3 fail_timeout=30s;
    server registry3.example.com:5000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name registry.example.com;

    ssl_certificate /etc/ssl/certs/registry.crt;
    ssl_certificate_key /etc/ssl/private/registry.key;

    location / {
        proxy_pass https://registry_backend;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 900s;
        proxy_request_buffering off;
        client_max_body_size 0;
    }
}
EOF

# Enable the configuration
sudo ln -s /etc/nginx/sites-available/registry-lb /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### Registry Replication Setup
```yaml
# registry-replication.yml
version: 0.1
log:
  level: info
storage:
  s3:
    accesskey: myaccesskey
    secretkey: mysecretkey
    region: us-west-2
    bucket: registry-primary
    regionendpoint: https://s3.us-west-2.amazonaws.com
http:
  addr: :5000
middleware:
  registry:
    - name: replication
      options:
        endpoints:
          - name: replica-east
            url: https://registry-east.example.com
            username: replication-user
            password: replication-pass
            insecure: false
          - name: replica-eu
            url: https://registry-eu.example.com
            username: replication-user
            password: replication-pass
            insecure: false
notifications:
  events:
    includereferences: true
  endpoints:
    - name: replication-webhook
      url: https://replication-service.example.com/webhook
      headers:
        Authorization: [Bearer replication-token]
```

## 📊 Registry Monitoring and Analytics

### Prometheus Monitoring
```yaml
# registry-monitoring.yml
version: 0.1
log:
  level: info
http:
  addr: :5000
  debug:
    addr: :5001
    prometheus:
      enabled: true
      path: /metrics
storage:
  filesystem:
    rootdirectory: /var/lib/registry
reporting:
  prometheus:
    enabled: true
```

### Grafana Dashboard Configuration
```json
{
  "dashboard": {
    "title": "Docker Registry Metrics",
    "panels": [
      {
        "title": "Registry HTTP Requests",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(registry_http_requests_total[5m])",
            "legendFormat": "{{method}} {{code}}"
          }
        ]
      },
      {
        "title": "Storage Usage",
        "type": "singlestat",
        "targets": [
          {
            "expr": "registry_storage_bytes_total",
            "format": "bytes"
          }
        ]
      }
    ]
  }
}
```

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Deploy and configure private Docker registries with authentication
- [ ] Implement registry mirroring and pull-through caching
- [ ] Set up enterprise authentication (LDAP, OAuth2) 
- [ ] Configure automated retention policies and lifecycle management
- [ ] Deploy high-availability registry clusters with load balancing
- [ ] Monitor registry performance and usage with metrics and alerting
- [ ] Implement disaster recovery and backup strategies for registry data
- [ ] Integrate registries securely with CI/CD pipelines and development workflows

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p09-m01-l01` - Local Registries
- `p09-m01-l02` - Mirror Configuration
- `p09-m01-l03` - Authentication
- `p09-m01-l04` - Retention Policies

## 🎯 What's Next

After mastering registries:

→ **Phase 10**: Observability - Logging, monitoring, and performance optimization  
→ **Phase 11**: Advanced Images - Distroless containers, static linking, and minimal images  
→ **Phase 12**: Production Patterns - Scaling, security, and operational excellence

---

💡 **Key Insight**: Enterprise registry management requires balancing performance, security, and operational complexity while providing reliable container distribution infrastructure for development and production environments.