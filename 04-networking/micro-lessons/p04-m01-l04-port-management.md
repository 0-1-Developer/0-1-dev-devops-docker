# p04-m01-l04: Port Management Best Practices

> **Duration**: 4 minutes | **Anchor**: `p04-m01-l04` | **Type**: Security + Operations

## 🎯 Learning Objective

Master secure port exposure, dynamic allocation, and production port management strategies to minimize attack surface while maintaining operational flexibility.

## 🚪 Port Exposure Fundamentals

### The Port Security Hierarchy

```
Most Secure → Least Secure
┌─────────────────┬──────────────────┬────────────────────┐
│ No Ports        │ Localhost Only   │ All Interfaces     │
│ (Internal only) │ (-p 127.0.0.1:*) │ (-p *:*)          │
└─────────────────┴──────────────────┴────────────────────┘
```

## 🔒 Secure Port Patterns

### Pattern 1: Localhost-Only Development

```bash
# Secure development setup
echo "=== Localhost-Only Services ==="

# Database: Only accessible from host
docker run -d --name postgres-dev \
  -p 127.0.0.1:5432:5432 \
  -e POSTGRES_PASSWORD=dev123 \
  postgres:13

# Redis cache: Localhost binding
docker run -d --name redis-dev \
  -p 127.0.0.1:6379:6379 \
  redis:7-alpine

# Application: Public access
docker run -d --name webapp \
  -p 8080:3000 \
  myapp:latest

echo "✅ Database/Cache: localhost only"
echo "✅ Web app: public access on 8080"

# Test security
curl localhost:5432 2>/dev/null && echo "❌ DB exposed" || echo "🛡️ DB secured"
```

### Pattern 2: Dynamic Port Allocation

```bash
# Let Docker choose ports automatically
echo "=== Dynamic Port Management ==="

# Multiple instances with auto-assigned ports
for i in 1 2 3; do
  docker run -d --name api-$i \
    -P \
    -e INSTANCE_ID=$i \
    myapi:latest
  
  # Get assigned port
  PORT=$(docker port api-$i 8080 | cut -d: -f2)
  echo "API instance $i: localhost:$PORT"
done

# Service discovery via docker port command
docker port api-1
```

### Pattern 3: Port Range Management

```bash
# Allocate port ranges for service types
echo "=== Port Range Strategy ==="

# Web services: 8000-8099
docker run -d --name web-1 -p 8001:80 nginx
docker run -d --name web-2 -p 8002:80 nginx

# API services: 8100-8199  
docker run -d --name api-1 -p 8101:8080 myapi:latest
docker run -d --name api-2 -p 8102:8080 myapi:latest

# Database services: 8200-8299 (localhost only)
docker run -d --name db-1 -p 127.0.0.1:8201:5432 postgres:13
docker run -d --name db-2 -p 127.0.0.1:8202:5432 postgres:13

echo "✅ Organized port allocation by service type"
```

## ⚡ Production Port Strategies

### Load Balancer Pattern

```bash
# Hide multiple backends behind single port
echo "=== Load Balancer Port Management ==="

docker network create lb-network

# Backend services (no external ports)
for i in 1 2 3; do
  docker run -d --name backend-$i \
    --network lb-network \
    myapp:latest  # No -p flag = internal only
done

# Load balancer configuration
cat > nginx-lb.conf << 'EOF'
upstream backends {
    server backend-1:8080;
    server backend-2:8080; 
    server backend-3:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://backends;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Single external port for load balancer
docker run -d --name loadbalancer \
  --network lb-network \
  -p 80:80 \
  -v $(pwd)/nginx-lb.conf:/etc/nginx/conf.d/default.conf \
  nginx

echo "✅ Single public port (80), multiple internal backends"
```

### Health Check Integration

```bash
# Port management with health monitoring
echo "=== Health-Aware Port Management ==="

# Service with health endpoint
docker run -d --name monitored-api \
  -p 8080:8080 \
  --health-cmd="curl -f http://localhost:8080/health || exit 1" \
  --health-interval=30s \
  --health-retries=3 \
  --health-start-period=40s \
  myapi:latest

# Monitoring port (internal network only)
docker network create monitoring
docker run -d --name health-monitor \
  --network monitoring \
  -p 127.0.0.1:9090:9090 \
  prometheus:latest

echo "✅ Main API: public, Health monitor: localhost only"
```

## 🔍 Port Conflict Resolution

### Automated Port Discovery

```bash
#!/bin/bash
echo "=== Smart Port Allocation ==="

find_available_port() {
    local start_port=$1
    local max_attempts=${2:-100}
    
    for ((port=start_port; port<start_port+max_attempts; port++)); do
        if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo $port
            return 0
        fi
    done
    return 1
}

# Find available ports automatically
WEB_PORT=$(find_available_port 8000)
API_PORT=$(find_available_port 8100) 
DB_PORT=$(find_available_port 5432)

echo "Allocating ports: Web=$WEB_PORT, API=$API_PORT, DB=$DB_PORT"

# Deploy with discovered ports
docker run -d --name smart-web -p $WEB_PORT:80 nginx
docker run -d --name smart-api -p $API_PORT:8080 myapi:latest  
docker run -d --name smart-db -p 127.0.0.1:$DB_PORT:5432 postgres:13

echo "✅ Services deployed with conflict-free ports"
```

### Port Conflict Diagnostics

```bash
# Diagnose port conflicts
echo "=== Port Conflict Analysis ==="

check_port_conflict() {
    local port=$1
    echo "Checking port $port:"
    
    # Check what's using the port
    if command -v lsof >/dev/null; then
        lsof -i :$port
    elif command -v netstat >/dev/null; then
        netstat -tuln | grep ":$port "
    elif command -v ss >/dev/null; then
        ss -tuln | grep ":$port "
    fi
    
    # Check Docker port usage
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":$port"
}

# Check common ports
for port in 80 443 8080 5432 3306; do
    check_port_conflict $port
    echo "---"
done
```

## 🎯 Advanced Port Techniques

### IPv6 and Dual-Stack Support

```bash
# IPv6 port binding
docker run -d --name ipv6-web \
  -p "[::1]:8080:80" \
  nginx

# Dual-stack (IPv4 + IPv6)
docker run -d --name dual-stack-api \
  -p "8080:8080" \
  -p "[::]:8080:8080" \
  myapi:latest
```

### Protocol-Specific Port Management

```bash
# TCP and UDP on same port
docker run -d --name dns-server \
  -p 5353:5353/tcp \
  -p 5353:5353/udp \
  dns:latest

# Multiple protocols for same service
docker run -d --name game-server \
  -p 7777:7777/tcp \
  -p 7777:7777/udp \
  -p 7778:7778/tcp \
  gameserver:latest
```

### Proxy Protocol Integration

```bash
# HAProxy with PROXY protocol
cat > haproxy.cfg << 'EOF'
global
    daemon

frontend web_frontend
    bind :80
    mode http
    default_backend web_servers

backend web_servers
    mode http
    server web1 backend-1:8080 send-proxy
    server web2 backend-2:8080 send-proxy
EOF

docker run -d --name haproxy \
  -p 80:80 \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg \
  haproxy:2.8
```

## 🚨 Port Security Anti-Patterns

❌ **Exposing all ports with -P in production**
```bash
# Dangerous: Exposes all EXPOSE directives
docker run -d -P myapp:latest  # Could expose debug ports, admin interfaces
```

✅ **Explicit port mapping**
```bash
# Safe: Only expose what's needed
docker run -d -p 8080:8080 myapp:latest  # Only main service port
```

❌ **Binding sensitive services to all interfaces**
```bash
# Database accessible from anywhere
docker run -d -p 5432:5432 postgres:13  # ❌ Security risk
```

✅ **Localhost binding for internal services**
```bash
# Database only accessible from host
docker run -d -p 127.0.0.1:5432:5432 postgres:13  # ✅ Secure
```

❌ **Hardcoded port conflicts**
```bash
# Multiple services fighting for port 8080
docker run -d -p 8080:8080 api-v1:latest
docker run -d -p 8080:8080 api-v2:latest  # ❌ Conflict
```

## 💡 Production Port Management

### Port Documentation Strategy

```bash
# Create port allocation documentation
cat > PORTS.md << 'EOF'
# Port Allocation Strategy

## Port Ranges
- 8000-8099: Web services (public)
- 8100-8199: API services (public)  
- 8200-8299: Database services (localhost only)
- 8300-8399: Monitoring services (localhost only)
- 9000-9099: Development/testing (localhost only)

## Current Allocations
- 8080: Main web application
- 8101: User API service
- 8102: Order API service  
- 8201: PostgreSQL (localhost)
- 8202: Redis (localhost)
- 8301: Prometheus (localhost)

## Security Rules
- Database ports: MUST bind to 127.0.0.1
- Monitoring ports: MUST bind to 127.0.0.1  
- Public services: Document and justify external exposure
EOF
```

### Automated Port Management

```bash
# Port management script for CI/CD
#!/bin/bash
DOCKER_COMPOSE_FILE="docker-compose.yml"
PORT_REGISTRY="deployed-ports.json"

allocate_ports() {
    # Read current allocations
    # Assign new ports automatically
    # Update port registry
    # Generate docker-compose with correct ports
    echo "Port allocation automated"
}

release_ports() {
    # Clean up port allocations for stopped services
    # Update port registry
    echo "Port cleanup automated"
}
```

## 🔗 Key Port Management Principles

1. **Minimal Exposure**: Only expose ports that must be accessible externally
2. **Localhost Binding**: Use 127.0.0.1 for development and internal services
3. **Dynamic Allocation**: Let Docker choose ports when possible
4. **Range Organization**: Group ports by service type and security level
5. **Conflict Avoidance**: Implement port discovery and conflict resolution
6. **Documentation**: Maintain clear port allocation records
7. **Security First**: Always consider the security implications of port exposure

---

**Phase 04 Networking Complete** - Ready for Phase 05: Storage and Volumes