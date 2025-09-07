# p04-m01-l02: Service Discovery Implementation

> **Duration**: 4 minutes | **Anchor**: `p04-m01-l02` | **Type**: Hands-on + Patterns

## 🎯 Learning Objective

Master Docker's built-in service discovery using DNS resolution, network aliases, and service communication patterns.

## 📋 Service Discovery Mechanisms

### 1. Container Name Resolution

```bash
# Automatic DNS in custom networks
docker network create app-net

docker run -d --name database --network app-net postgres:13
docker run -d --name backend --network app-net \
  -e DATABASE_URL=postgresql://user:pass@database:5432/app \
  node:18

# 'database' resolves to container IP automatically
```

### 2. Network Aliases (Multiple Names)

```bash
# One container, multiple DNS names
docker run -d --name postgres-main \
  --network app-net \
  --network-alias database \
  --network-alias db \
  --network-alias postgres \
  postgres:13

# All these work from other containers:
# ping database
# ping db  
# ping postgres
```

### 3. Round-Robin Load Balancing

```bash
# Multiple containers, same alias
docker network create lb-test

for i in 1 2 3; do
  docker run -d --name api-$i \
    --network lb-test \
    --network-alias api-service \
    nginx
done

# DNS returns different IPs in round-robin
docker run --rm --network lb-test alpine \
  nslookup api-service
```

## ⚡ Live Demo (3 minutes)

### Microservices Communication Pattern

```bash
echo "=== Service Discovery Demo ==="

# Create application network
docker network create microservices-demo

# 1. Database service
docker run -d --name postgres \
  --network microservices-demo \
  --network-alias database \
  -e POSTGRES_PASSWORD=demo123 \
  postgres:13

# 2. Redis cache
docker run -d --name redis \
  --network microservices-demo \
  --network-alias cache \
  redis:7-alpine

# 3. API service (connects to both)
docker run -d --name api-server \
  --network microservices-demo \
  --network-alias api \
  -e DATABASE_HOST=database \
  -e REDIS_HOST=cache \
  node:18 node -e "
    setInterval(() => {
      console.log('API connecting to:', process.env.DATABASE_HOST, process.env.REDIS_HOST);
    }, 5000);
  "

# 4. Test connectivity
echo "Testing service discovery..."
docker run --rm --network microservices-demo alpine sh -c "
  echo 'Database IP:' && nslookup database
  echo 'Cache IP:' && nslookup cache
  echo 'API IP:' && nslookup api
"

# Cleanup
docker rm -f postgres redis api-server
docker network rm microservices-demo
```

## 🔍 Advanced Service Discovery Patterns

### Pattern 1: Service Versioning

```bash
# Deploy multiple API versions
docker network create versioned-api

# v1 API instances
docker run -d --name api-v1-1 --network versioned-api --network-alias api-v1 api:1.0
docker run -d --name api-v1-2 --network versioned-api --network-alias api-v1 api:1.0

# v2 API instances  
docker run -d --name api-v2-1 --network versioned-api --network-alias api-v2 api:2.0

# Client can choose version
# curl http://api-v1/health  # Round-robin between v1 instances
# curl http://api-v2/health  # Routes to v2
```

### Pattern 2: Environment-Based Discovery

```bash
# Different aliases per environment
docker run -d --name postgres-prod \
  --network prod-net \
  --network-alias database \
  --network-alias postgres-primary \
  postgres:13

docker run -d --name postgres-staging \
  --network staging-net \
  --network-alias database \
  --network-alias postgres-staging \
  postgres:13

# Same application code, different resolved services
```

### Pattern 3: Health-Check Integration

```bash
# Service with health check
docker run -d --name healthy-api \
  --network app-net \
  --network-alias api \
  --health-cmd="curl -f http://localhost:8080/health || exit 1" \
  --health-interval=30s \
  --health-retries=3 \
  myapi:latest

# Only healthy containers participate in DNS
```

## 📊 DNS Resolution Deep Dive

### Testing DNS Behavior

```bash
# Create test environment
docker network create dns-test
docker run -d --name service1 --network dns-test --network-alias app nginx
docker run -d --name service2 --network dns-test --network-alias app nginx

# Test DNS resolution
docker run --rm --network dns-test alpine sh -c "
  echo 'Multiple A records for same alias:'
  nslookup app
  
  echo 'Direct container name resolution:'
  nslookup service1
  
  echo 'DNS search behavior:'
  cat /etc/resolv.conf
"
```

### Custom DNS Configuration

```bash
# Override DNS servers
docker run -d --name custom-dns \
  --network app-net \
  --dns 1.1.1.1 \
  --dns 8.8.8.8 \
  --dns-search company.local \
  myapp:latest

# Custom hostname and domain
docker run -d --name web-server \
  --network app-net \
  --hostname webapp \
  --domainname example.com \
  nginx
```

## 💡 Production Patterns

### External Service Discovery Integration

```bash
# Container with consul agent
docker run -d --name consul-agent \
  --network app-net \
  --network-alias consul \
  -p 8500:8500 \
  consul:latest

# Register services with external discovery
docker run -d --name api-with-consul \
  --network app-net \
  -e CONSUL_HOST=consul \
  myapi:latest
```

### DNS Caching Optimization

```bash
# Optimize DNS lookups
docker run -d --name optimized-app \
  --network app-net \
  --dns-opt ndots:1 \
  --dns-opt timeout:1 \
  --dns-opt attempts:2 \
  myapp:latest
```

## 🚨 Service Discovery Anti-Patterns

❌ **Hardcoding IP addresses**
```bash
# Fragile - IPs change when containers restart
docker run -d -e DATABASE_HOST=172.17.0.2 myapp
```

✅ **Use service names**
```bash
# Resilient - DNS resolves dynamically
docker run -d -e DATABASE_HOST=database myapp
```

❌ **Using default bridge network**
```bash
# No automatic DNS resolution
docker run -d --name api node:18
docker run -d --name web -e API_HOST=api nginx  # Won't resolve
```

## 🔗 Key Takeaways

1. **Always use custom networks** for automatic DNS resolution
2. **Network aliases enable multiple names** for the same service
3. **Round-robin DNS provides basic load balancing** for multiple containers
4. **Service discovery is network-scoped** - only works within same network
5. **External service discovery integrates** with DNS for hybrid architectures

---

**Next**: Network Isolation Strategies (`p04-m01-l03`)