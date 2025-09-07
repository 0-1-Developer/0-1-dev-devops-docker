# Phase 04: Networking - Hands-on Labs

> **Practical exercises for mastering Docker networking, service communication, and network isolation**

## 🎯 Lab Overview

These labs provide hands-on experience with Docker networking concepts including network drivers, service discovery, port management, and network isolation. Each lab builds practical skills essential for production container networking.

**Total Time**: ~150 minutes across 4 progressive labs

## 📋 Lab Environment Setup

### Prerequisites Check
```bash
# Verify Docker version
docker version --format '{{.Server.Version}}'

# Check current networks
docker network ls

# Clean up any existing test networks
docker network prune -f
```

### Lab Working Directory
```bash
mkdir -p ~/docker-labs/networking
cd ~/docker-labs/networking
```

---

## 🌐 Lab 1: Network Drivers and Communication

**Duration**: 35 minutes  
**Objective**: Understand different network drivers and container-to-container communication

### Lab 1.1: Exploring Default Bridge Network

Understand the limitations of the default bridge:

```bash
# Run containers on default bridge
docker run -d --name web1 nginx:alpine
docker run -d --name web2 nginx:alpine

# Check network settings
docker network inspect bridge

# Try to communicate by container name (will fail)
docker exec web1 ping web2
# Error: ping: bad address 'web2'

# Communication works with IP address
WEB2_IP=$(docker inspect web2 --format '{{.NetworkSettings.IPAddress}}')
docker exec web1 ping -c 3 $WEB2_IP

# Cleanup
docker rm -f web1 web2
```

### Lab 1.2: Custom Bridge Networks

Create and use custom bridge networks with DNS:

```bash
# Create custom network
docker network create --driver bridge myapp-network

# Inspect the network
docker network inspect myapp-network

# Run containers on custom network
docker run -d --name database --network myapp-network postgres:13-alpine
docker run -d --name backend --network myapp-network alpine sleep 3600
docker run -d --name frontend --network myapp-network nginx:alpine

# Test DNS resolution (this works!)
docker exec backend ping -c 3 database
docker exec backend ping -c 3 frontend

# Check DNS configuration
docker exec backend cat /etc/resolv.conf
docker exec backend nslookup database

# Test connectivity from frontend to database
docker exec frontend ping -c 3 database
```

### Lab 1.3: Host and None Networks

Explore special network modes:

```bash
# Host network mode
docker run -d --name host-nginx --network host nginx:alpine

# Check that nginx is directly on host network
curl localhost:80  # Works without port mapping!

# Check network interfaces (same as host)
docker exec host-nginx ip addr

# None network mode (isolated)
docker run -d --name isolated --network none alpine sleep 3600

# Check network (no network interfaces except loopback)
docker exec isolated ip addr
docker exec isolated ping google.com  # Fails - no network

# Cleanup
docker rm -f host-nginx isolated
```

### Lab 1.4: Connecting Containers to Multiple Networks

Multi-network connectivity patterns:

```bash
# Create multiple networks
docker network create frontend-net
docker network create backend-net
docker network create database-net

# Deploy database (only on database network)
docker run -d --name postgres \
  --network database-net \
  -e POSTGRES_PASSWORD=secret \
  postgres:13-alpine

# Deploy backend (connected to backend and database networks)
docker run -d --name api \
  --network backend-net \
  alpine sleep 3600

# Connect API to database network
docker network connect database-net api

# Deploy frontend (only on frontend network)
docker run -d --name web \
  --network frontend-net \
  nginx:alpine

# Connect web to backend network for API access
docker network connect backend-net web

# Verify multi-network connectivity
docker exec api ping -c 2 postgres  # Works
docker exec web ping -c 2 api       # Works
docker exec web ping -c 2 postgres  # Fails - not connected

# List networks for each container
for container in postgres api web; do
  echo "=== $container networks ==="
  docker inspect $container --format '{{range $net, $v := .NetworkSettings.Networks}}{{$net}} {{end}}'
done

# Cleanup
docker rm -f postgres api web database backend frontend
docker network rm frontend-net backend-net database-net myapp-network
```

**Lab 1 Summary Questions**:
1. Why does DNS resolution fail on the default bridge network?
2. When would you use host network mode?
3. How do multiple networks provide security isolation?

---

## 🔍 Lab 2: Service Discovery and DNS

**Duration**: 40 minutes  
**Objective**: Master service discovery patterns and DNS configuration

### Lab 2.1: DNS Resolution and Service Discovery

Implement service discovery patterns:

```bash
# Create application network
docker network create discovery-lab

# Run multiple instances of a service
for i in 1 2 3; do
  docker run -d --name api-$i \
    --network discovery-lab \
    --network-alias api \
    nginxdemos/hello:plain-text
done

# Run a client container
docker run -d --name client \
  --network discovery-lab \
  alpine sleep 3600

# Test DNS resolution (returns all IPs)
docker exec client nslookup api

# Test round-robin DNS load balancing
for i in {1..10}; do
  docker exec client wget -qO- http://api | grep "Server name"
done

# Create database with custom hostname
docker run -d --name db \
  --network discovery-lab \
  --hostname primary-db \
  --network-alias postgres \
  --network-alias database \
  postgres:13-alpine

# Test multiple aliases
docker exec client nslookup postgres
docker exec client nslookup database
docker exec client nslookup primary-db
```

### Lab 2.2: Custom DNS Configuration

Configure DNS servers and search domains:

```bash
# Run container with custom DNS servers
docker run -d --name custom-dns \
  --network discovery-lab \
  --dns 8.8.8.8 \
  --dns 1.1.1.1 \
  --dns-search example.com \
  --dns-search internal.local \
  alpine sleep 3600

# Check DNS configuration
docker exec custom-dns cat /etc/resolv.conf

# Test external DNS resolution
docker exec custom-dns nslookup google.com

# Test search domains
docker exec custom-dns ping api  # Resolves without domain
```

### Lab 2.3: Service Discovery Implementation

Build a practical service discovery example:

```bash
# Create microservices network
docker network create microservices

# Deploy Redis cache
docker run -d --name cache \
  --network microservices \
  redis:alpine

# Deploy PostgreSQL database
docker run -d --name database \
  --network microservices \
  -e POSTGRES_PASSWORD=secret \
  postgres:13-alpine

# Create configuration for application
cat > app-config.env << 'EOF'
REDIS_HOST=cache
REDIS_PORT=6379
DB_HOST=database
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=secret
EOF

# Deploy application that uses service discovery
docker run -d --name app \
  --network microservices \
  --env-file app-config.env \
  alpine sh -c 'while true; do
    echo "Checking services..."
    nc -zv cache 6379 && echo "✓ Redis available"
    nc -zv database 5432 && echo "✓ Database available"
    sleep 5
  done'

# Monitor service discovery
docker logs -f app

# Scale the cache service
docker run -d --name cache-2 \
  --network microservices \
  --network-alias cache \
  redis:alpine

# DNS now returns both cache instances
docker exec app nslookup cache
```

### Lab 2.4: Cross-Container Communication Testing

Test various communication patterns:

```bash
# Create test network
docker network create comm-test

# Deploy web server
docker run -d --name webserver \
  --network comm-test \
  -e MESSAGE="Hello from webserver" \
  nginxdemos/hello:plain-text

# Deploy API server
docker run -d --name apiserver \
  --network comm-test \
  -e PORT=8080 \
  nginxdemos/hello:plain-text

# Deploy test client
docker run -d --name testclient \
  --network comm-test \
  nicolaka/netshoot sleep 3600

# Test HTTP communication
docker exec testclient curl -s http://webserver
docker exec testclient curl -s http://apiserver:8080

# Test TCP connectivity
docker exec testclient nc -zv webserver 80
docker exec testclient nc -zv apiserver 8080

# Test DNS resolution timing
docker exec testclient time nslookup webserver

# Trace network path
docker exec testclient traceroute webserver

# Cleanup
docker rm -f $(docker ps -aq)
docker network rm discovery-lab microservices comm-test
```

**Lab 2 Summary Questions**:
1. How does Docker implement DNS-based load balancing?
2. What are network aliases used for?
3. How do search domains simplify service discovery?

---

## 🔒 Lab 3: Network Isolation and Security

**Duration**: 40 minutes  
**Objective**: Implement network segmentation and isolation strategies

### Lab 3.1: Network Segmentation

Create isolated network tiers:

```bash
# Create three-tier architecture networks
docker network create frontend --subnet 172.20.0.0/24
docker network create backend --subnet 172.21.0.0/24
docker network create database --subnet 172.22.0.0/24

# Deploy database tier
docker run -d --name postgres \
  --network database \
  --ip 172.22.0.10 \
  -e POSTGRES_PASSWORD=secret \
  postgres:13-alpine

docker run -d --name redis \
  --network database \
  --ip 172.22.0.11 \
  redis:alpine

# Deploy backend tier
docker run -d --name api1 \
  --network backend \
  --ip 172.21.0.10 \
  nginxdemos/hello:plain-text

docker run -d --name api2 \
  --network backend \
  --ip 172.21.0.11 \
  nginxdemos/hello:plain-text

# Deploy frontend tier
docker run -d --name web \
  --network frontend \
  --ip 172.20.0.10 \
  -p 80:80 \
  nginx:alpine

# Connect API to database network (backend needs database access)
docker network connect database api1
docker network connect database api2

# Connect web to backend network (frontend needs API access)
docker network connect backend web

# Test isolation
docker exec web ping -c 2 api1        # Works (connected to backend)
docker exec web ping -c 2 postgres    # Fails (not connected to database)
docker exec api1 ping -c 2 postgres   # Works (connected to database)

# Show network topology
for container in web api1 api2 postgres redis; do
  echo "=== $container ==="
  docker inspect $container --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}: {{.IPAddress}} {{end}}'
done
```

### Lab 3.2: Implementing DMZ Pattern

Create DMZ for external-facing services:

```bash
# Create networks
docker network create dmz --subnet 172.30.0.0/24
docker network create internal --subnet 172.31.0.0/24
docker network create secure --subnet 172.32.0.0/24

# Deploy reverse proxy in DMZ
docker run -d --name reverse-proxy \
  --network dmz \
  -p 443:443 -p 80:80 \
  nginx:alpine

# Deploy application in internal network
docker run -d --name app-server \
  --network internal \
  nginxdemos/hello:plain-text

# Deploy database in secure network
docker run -d --name database \
  --network secure \
  -e POSTGRES_PASSWORD=verysecret \
  postgres:13-alpine

# Connect reverse proxy to internal (one-way access)
docker network connect internal reverse-proxy

# Connect app to secure network
docker network connect secure app-server

# Configure reverse proxy
docker exec reverse-proxy sh -c 'cat > /etc/nginx/conf.d/proxy.conf << EOF
server {
    listen 80;
    location / {
        proxy_pass http://app-server;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF'

docker exec reverse-proxy nginx -s reload

# Test access patterns
# External access through proxy works
curl localhost

# Direct access to internal services blocked (no port mapping)
# Only reverse-proxy has external ports exposed
```

### Lab 3.3: Network Policies and Access Control

Implement fine-grained network access:

```bash
# Create application networks
docker network create public-api
docker network create private-api  
docker network create admin-only

# Deploy public API
docker run -d --name public-service \
  --network public-api \
  -l access=public \
  nginxdemos/hello:plain-text

# Deploy private API
docker run -d --name private-service \
  --network private-api \
  -l access=private \
  nginxdemos/hello:plain-text

# Deploy admin service
docker run -d --name admin-service \
  --network admin-only \
  -l access=admin \
  nginxdemos/hello:plain-text

# Deploy API gateway with controlled access
docker run -d --name gateway \
  --network public-api \
  -p 8080:80 \
  nginx:alpine

# Connect gateway to private API (authorized access)
docker network connect private-api gateway

# Deploy monitoring that needs access to all
docker run -d --name monitor \
  --network admin-only \
  alpine sleep 3600

# Connect monitor to all networks
docker network connect public-api monitor
docker network connect private-api monitor

# Test access patterns
docker exec gateway wget -qO- http://public-service    # Works
docker exec gateway wget -qO- http://private-service   # Works
docker exec gateway wget -qO- http://admin-service     # Fails

docker exec monitor wget -qO- http://public-service    # Works
docker exec monitor wget -qO- http://private-service   # Works  
docker exec monitor wget -qO- http://admin-service     # Works
```

### Lab 3.4: Encrypted Overlay Networks (Swarm Mode)

Set up encrypted communication:

```bash
# Initialize swarm mode (required for overlay)
docker swarm init

# Create encrypted overlay network
docker network create \
  --driver overlay \
  --opt encrypted \
  --attachable \
  secure-overlay

# Deploy services on encrypted network
docker service create \
  --name secure-db \
  --network secure-overlay \
  postgres:13-alpine

docker service create \
  --name secure-app \
  --network secure-overlay \
  --replicas 3 \
  nginxdemos/hello:plain-text

# Verify encryption is enabled
docker network inspect secure-overlay --format '{{.Options}}'

# Leave swarm mode
docker swarm leave --force

# Cleanup all networks
docker network prune -f
```

**Lab 3 Summary Questions**:
1. How does network segmentation improve security?
2. What is the purpose of a DMZ in containerized applications?
3. When should you use encrypted overlay networks?

---

## 🚪 Lab 4: Port Management and External Access

**Duration**: 35 minutes  
**Objective**: Master port publishing, mapping strategies, and external service access

### Lab 4.1: Port Publishing Strategies

Explore different port publishing methods:

```bash
# Static port mapping
docker run -d --name static-web \
  -p 8080:80 \
  nginx:alpine

# Dynamic port allocation
docker run -d --name dynamic-web \
  -P \
  nginx:alpine

# Find dynamic port
DYNAMIC_PORT=$(docker port dynamic-web 80 | cut -d: -f2)
echo "Dynamic port: $DYNAMIC_PORT"
curl localhost:$DYNAMIC_PORT

# Specific interface binding
docker run -d --name local-only \
  -p 127.0.0.1:8081:80 \
  nginx:alpine

# Test local-only binding
curl localhost:8081          # Works
curl $(hostname -I | awk '{print $1}'):8081  # Fails (not bound to external IP)

# UDP port mapping
docker run -d --name dns-server \
  -p 5353:53/udp \
  -p 5353:53/tcp \
  alpine sleep 3600

# Port range mapping
docker run -d --name multi-port \
  -p 9000-9003:9000-9003 \
  alpine sh -c 'for p in 9000 9001 9002 9003; do nc -l -p $p & done; sleep 3600'

# Verify port mappings
docker port static-web
docker port dynamic-web
docker port local-only
docker port multi-port
```

### Lab 4.2: Load Balancer Configuration

Set up load balancing with port management:

```bash
# Create network for load balancing
docker network create lb-network

# Deploy multiple backend instances
for i in 1 2 3; do
  docker run -d --name backend-$i \
    --network lb-network \
    -e SERVER_NAME="Backend-$i" \
    nginxdemos/hello:plain-text
done

# Create nginx load balancer configuration
cat > nginx-lb.conf << 'EOF'
upstream backend_servers {
    server backend-1:80;
    server backend-2:80;
    server backend-3:80;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Deploy load balancer
docker run -d --name loadbalancer \
  --network lb-network \
  -p 80:80 \
  -v $(pwd)/nginx-lb.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:alpine

# Test load balancing
for i in {1..10}; do
  curl -s localhost | grep "Server name"
done

# Add health check monitoring
docker run -d --name health-monitor \
  --network lb-network \
  alpine sh -c 'while true; do
    for i in 1 2 3; do
      nc -zv backend-$i 80 && echo "✓ Backend-$i healthy" || echo "✗ Backend-$i down"
    done
    echo "---"
    sleep 5
  done'

docker logs -f health-monitor
```

### Lab 4.3: Service Mesh Simulation

Implement service mesh patterns:

```bash
# Create service mesh network
docker network create service-mesh

# Deploy service A with sidecar proxy
docker run -d --name service-a \
  --network service-mesh \
  nginxdemos/hello:plain-text

docker run -d --name service-a-proxy \
  --network service-mesh \
  -p 8001:80 \
  nginx:alpine

# Deploy service B with sidecar proxy
docker run -d --name service-b \
  --network service-mesh \
  nginxdemos/hello:plain-text

docker run -d --name service-b-proxy \
  --network service-mesh \
  -p 8002:80 \
  nginx:alpine

# Configure proxies for service communication
docker exec service-a-proxy sh -c 'cat > /etc/nginx/conf.d/mesh.conf << EOF
server {
    listen 80;
    
    location /service-a {
        proxy_pass http://service-a;
    }
    
    location /service-b {
        proxy_pass http://service-b-proxy;
    }
}
EOF'

docker exec service-a-proxy nginx -s reload

# Test service mesh communication
curl localhost:8001/service-a
curl localhost:8001/service-b
```

### Lab 4.4: External Service Integration

Connect containers to external services:

```bash
# Create bridge to external services
docker network create external-bridge

# Run container that needs external access
docker run -d --name external-client \
  --network external-bridge \
  alpine sh -c 'while true; do
    echo "Testing external connectivity..."
    wget -qO- http://api.ipify.org && echo
    sleep 10
  done'

# Monitor external access
docker logs -f external-client

# Create container with restricted external access
docker run -d --name restricted-client \
  --network external-bridge \
  --dns 8.8.8.8 \
  --add-host blocked.example.com:127.0.0.1 \
  --add-host allowed.example.com:93.184.216.34 \
  alpine sh -c 'while true; do
    echo "Testing restricted access..."
    ping -c 1 allowed.example.com
    ping -c 1 blocked.example.com
    sleep 5
  done'

docker logs -f restricted-client

# Cleanup
docker rm -f $(docker ps -aq)
docker network prune -f
```

**Lab 4 Summary Questions**:
1. When should you use dynamic vs static port allocation?
2. How does interface binding improve security?
3. What are the benefits of a service mesh architecture?

---

## 🧹 Lab Cleanup

Clean up all lab resources:

```bash
# Stop and remove all containers
docker rm -f $(docker ps -aq)

# Remove all custom networks
docker network prune -f

# Remove lab directory
cd ~
rm -rf ~/docker-labs/networking

# Verify cleanup
docker network ls
docker ps -a

echo "Lab cleanup completed!"
```

## 🎯 Lab Summary & Next Steps

### Key Skills Acquired:
- ✅ Network driver selection and configuration
- ✅ Service discovery and DNS resolution
- ✅ Network isolation and segmentation
- ✅ Port management and external access control

### Production Readiness Checklist:
- [ ] Understand when to use each network driver type
- [ ] Implement service discovery for microservices
- [ ] Design secure network architectures with proper isolation
- [ ] Configure appropriate port mappings for external access
- [ ] Troubleshoot network connectivity issues

### Advanced Topics to Explore:
- Container orchestration networking (Kubernetes/Swarm)
- Service mesh implementations (Istio/Linkerd)
- Network policies and security groups
- Advanced load balancing strategies

These networking skills form the foundation for building secure, scalable containerized applications.