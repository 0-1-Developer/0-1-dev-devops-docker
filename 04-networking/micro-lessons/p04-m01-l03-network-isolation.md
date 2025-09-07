# p04-m01-l03: Network Isolation Strategies

> **Duration**: 5 minutes | **Anchor**: `p04-m01-l03` | **Type**: Security-focused + Architecture

## 🎯 Learning Objective

Implement network segmentation and isolation patterns to create secure multi-tier architectures with controlled communication paths.

## 🔒 Network Isolation Fundamentals

### Core Principle: Defense in Depth
- **Default Deny**: Networks are isolated by default
- **Explicit Allow**: Only connect networks that need communication
- **Least Privilege**: Minimal necessary connectivity
- **Layered Security**: Multiple isolation boundaries

## 🏗 Multi-Tier Architecture Pattern

### Classic 3-Tier Isolation

```bash
# Create isolated network tiers
docker network create frontend --subnet 172.20.0.0/24
docker network create backend --subnet 172.21.0.0/24  
docker network create database --subnet 172.22.0.0/24

echo "=== Tier Isolation Demo ==="

# Tier 1: Frontend (public-facing)
docker run -d --name web \
  --network frontend \
  -p 80:80 \
  nginx

# Tier 2: Backend (internal API)
docker run -d --name api \
  --network backend \
  node:18 node -e "
    require('http').createServer((req,res) => {
      res.writeHead(200, {'Content-Type': 'application/json'});
      res.end(JSON.stringify({service: 'api', tier: 'backend'}));
    }).listen(8080, () => console.log('API listening on 8080'));
  "

# Tier 3: Database (most protected)
docker run -d --name postgres \
  --network database \
  -e POSTGRES_PASSWORD=secure123 \
  postgres:13

# Test initial isolation
echo "Testing isolation (should fail):"
docker exec web ping -c 2 postgres 2>/dev/null && echo "❌ SECURITY BREACH" || echo "✅ Database isolated"
```

### Controlled Connectivity

```bash
# Allow specific cross-tier communication
echo "=== Adding Controlled Connections ==="

# Connect API to both backend and database networks
docker network connect backend api
docker network connect database api

# Connect web to frontend and backend networks  
docker network connect backend web

# Now test controlled access
echo "Testing controlled connectivity:"
docker exec web ping -c 2 api >/dev/null && echo "✅ Web can reach API"
docker exec api ping -c 2 postgres >/dev/null && echo "✅ API can reach database"
docker exec web ping -c 2 postgres 2>/dev/null && echo "❌ SECURITY ISSUE" || echo "✅ Web cannot reach database directly"
```

## 🛡 Security-First Network Patterns

### Pattern 1: DMZ Architecture

```bash
# DMZ for external-facing services
docker network create dmz --subnet 10.0.1.0/24
docker network create internal --subnet 10.0.2.0/24
docker network create secure --subnet 10.0.3.0/24

# DMZ: Load balancer (public)
docker run -d --name loadbalancer \
  --network dmz \
  -p 443:443 \
  nginx

# Internal: Application services
docker run -d --name app1 --network internal myapp:latest
docker run -d --name app2 --network internal myapp:latest

# Secure: Sensitive data services
docker run -d --name secure-db --network secure postgres:13

# Gateway: Controlled access between zones
docker run -d --name gateway \
  --network dmz \
  --network internal \
  api-gateway:latest

echo "✅ DMZ architecture: public → dmz → internal → secure"
```

### Pattern 2: Zero-Trust Micro-Segmentation

```bash
# Each service gets its own network
docker network create auth-net
docker network create user-net  
docker network create order-net
docker network create payment-net

# Deploy services in isolation
docker run -d --name auth-service --network auth-net auth:latest
docker run -d --name user-service --network user-net users:latest
docker run -d --name order-service --network order-net orders:latest
docker run -d --name payment-service --network payment-net payments:latest

# API Gateway connects to all (controlled access point)
docker run -d --name api-gateway \
  --network auth-net \
  --network user-net \
  --network order-net \
  --network payment-net \
  -p 8080:8080 \
  gateway:latest

echo "✅ Zero-trust: Each service isolated, gateway controls access"
```

## 🔍 Network Security Verification

### Automated Security Testing

```bash
#!/bin/bash
echo "=== Network Security Audit ==="

audit_network_isolation() {
    local container1=$1
    local container2=$2
    local expected_result=$3
    
    docker exec $container1 ping -c 1 -W 1 $container2 >/dev/null 2>&1
    local result=$?
    
    if [ "$expected_result" = "allow" ] && [ $result -eq 0 ]; then
        echo "✅ $container1 → $container2: Allowed (expected)"
    elif [ "$expected_result" = "deny" ] && [ $result -ne 0 ]; then
        echo "✅ $container1 → $container2: Blocked (expected)"
    else
        echo "❌ $container1 → $container2: SECURITY VIOLATION"
        return 1
    fi
    return 0
}

# Test isolation rules
audit_network_isolation web api allow
audit_network_isolation api postgres allow  
audit_network_isolation web postgres deny

echo "Security audit completed"
```

### Network Information Leakage Test

```bash
# Check what networks containers can see
check_network_visibility() {
    local container=$1
    echo "=== Network visibility for $container ==="
    
    # Check network interfaces
    docker exec $container ip addr | grep "inet " | grep -v "127.0.0.1"
    
    # Check routing table
    docker exec $container ip route 2>/dev/null || echo "No routing info available"
    
    # DNS enumeration test
    docker exec $container nslookup _tcp.local 2>/dev/null || echo "No service discovery"
}

check_network_visibility web
check_network_visibility api
```

## ⚡ Live Security Demo (2 minutes)

```bash
echo "=== Real-World Isolation Scenario ==="

# Simulate web application with database
docker network create web-tier
docker network create app-tier  
docker network create data-tier

# Web server (nginx reverse proxy)
docker run -d --name nginx-proxy \
  --network web-tier \
  -p 8080:80 \
  nginx

# Application server
docker run -d --name app-server \
  --network app-tier \
  node:18 node -e "
    require('http').createServer((req,res) => {
      res.end('App server response: ' + new Date().toISOString());
    }).listen(3000);
  "

# Database server
docker run -d --name database-server \
  --network data-tier \
  postgres:13

# Attack simulation: Try to reach database from web tier
echo "🔍 Attack Test 1: Web → Database (should fail)"
docker exec nginx-proxy ping -c 1 database-server 2>/dev/null && echo "💥 BREACH!" || echo "🛡️ Blocked"

# Connect app to multiple tiers (controlled)
docker network connect web-tier app-server
docker network connect data-tier app-server

echo "🔍 Attack Test 2: Web → App → Database"
docker exec nginx-proxy ping -c 1 app-server >/dev/null && echo "✅ Web can reach app"
docker exec app-server ping -c 1 database-server >/dev/null && echo "✅ App can reach database"  
docker exec nginx-proxy ping -c 1 database-server 2>/dev/null && echo "💥 BREACH!" || echo "🛡️ Database still isolated"

# Cleanup
docker rm -f nginx-proxy app-server database-server
docker network rm web-tier app-tier data-tier
```

## 🎯 Advanced Isolation Techniques

### 1. Network Namespace Sharing

```bash
# Share network namespace (same network stack)
docker run -d --name primary alpine sleep 300
docker run -d --name secondary --network container:primary alpine sleep 300

# Both containers share the same network interfaces
# Useful for sidecar patterns
```

### 2. Read-Only Network Configuration

```bash
# Prevent network configuration changes
docker run -d --name locked-network \
  --network app-net \
  --cap-drop NET_ADMIN \
  --cap-drop NET_RAW \
  myapp:latest

# Container cannot modify network settings
```

### 3. Host Network Filtering

```bash
# Limit host network access with iptables integration
docker run -d --name filtered-host \
  --network host \
  --cap-add NET_ADMIN \
  --security-opt apparmor:docker-default \
  myapp:latest
```

## 💡 Production Isolation Strategies

### Compliance-Ready Architecture

```bash
# PCI DSS compliant network segmentation
docker network create cardholder-data --subnet 192.168.10.0/24    # CDE
docker network create trusted --subnet 192.168.20.0/24             # Trusted systems  
docker network create untrusted --subnet 192.168.30.0/24           # DMZ

# Deploy with strict isolation
docker run -d --name payment-processor \
  --network cardholder-data \
  --read-only \
  --tmpfs /tmp \
  payment:secure

docker run -d --name web-frontend \
  --network untrusted \
  -p 443:443 \
  webapp:latest
```

### Container Security Scanning

```bash
# Network-aware security scanning
docker run --rm \
  --network none \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image myapp:latest

# Isolated vulnerability assessment
```

## 🚨 Common Isolation Failures

❌ **Default bridge network usage**
```bash
# All containers can communicate
docker run -d --name app1 myapp
docker run -d --name app2 myapp  # Can reach app1
```

✅ **Proper network segmentation**
```bash
docker network create app1-net
docker network create app2-net
docker run -d --name app1 --network app1-net myapp
docker run -d --name app2 --network app2-net myapp  # Isolated
```

❌ **Over-privileged network connections**
```bash
# API connected to all networks (unnecessary)
docker network connect frontend api
docker network connect backend api  
docker network connect database api
docker network connect monitoring api  # Too much access
```

## 🔗 Key Security Principles

1. **Network Isolation is Default** - Start with complete isolation
2. **Explicit Connectivity** - Only connect what must communicate
3. **Layered Defense** - Multiple network boundaries
4. **Principle of Least Privilege** - Minimal necessary access
5. **Regular Security Audits** - Verify isolation effectiveness
6. **Zero-Trust Architecture** - Never trust, always verify

---

**Next**: Port Management Best Practices (`p04-m01-l04`)