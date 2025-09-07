# Phase 04: Networking

> **Master Docker networking concepts, service communication, and network isolation strategies**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Design and implement network architectures using Docker's network drivers
- Configure service discovery and inter-container communication
- Apply network isolation and segmentation for security
- Manage port mappings and expose services safely
- Troubleshoot common networking issues effectively
- Implement production networking patterns for microservices

## 📚 Concept Map

```
Docker Networking
├── Network Drivers
│   ├── Bridge (Default, Single Host)
│   ├── Host (Direct Host Network Access)
│   ├── None (No Network Access)
│   ├── Overlay (Multi-Host Swarm)
│   └── Custom Drivers (3rd Party Plugins)
├── Network Concepts
│   ├── Container-to-Container Communication
│   ├── Service Discovery & DNS Resolution
│   ├── Port Publishing & Mapping
│   └── Network Namespaces & Isolation
├── Security & Isolation
│   ├── Network Segmentation
│   ├── Inter-Network Routing Rules
│   ├── Firewall Integration
│   └── Encrypted Overlay Networks
└── Production Patterns
    ├── Microservices Communication
    ├── Load Balancing Strategies
    ├── External Access Management
    └── Multi-Tier Architecture
```

## 🔬 Core Topics

### 1. Docker Network Drivers

**Understanding Network Types and Their Use Cases**

Docker provides multiple network drivers, each designed for specific scenarios:

- **Bridge Network**: Default network for standalone containers
- **Host Network**: Removes network isolation, uses host network directly
- **None Network**: Complete network isolation
- **Overlay Network**: Multi-host networking for Docker Swarm
- **Macvlan Network**: Assigns MAC addresses for legacy applications

**Key Benefits**:
- Flexible networking options for different architectures
- Built-in service discovery within custom networks
- Network isolation for security
- Cross-host communication capabilities

### 2. Service Discovery and DNS

**Automatic Service Resolution**

Docker provides built-in DNS resolution for containers:

- **Container Name Resolution**: Containers can reach each other by name
- **Network-Scoped DNS**: Isolated DNS per network
- **Custom DNS Configuration**: Override DNS servers and search domains
- **Round-Robin DNS**: Basic load balancing through DNS

**Critical Patterns**:
- Service names as connection endpoints
- Environment-specific DNS configuration
- External DNS integration
- Service mesh compatibility

### 3. Port Management

**Exposing Services to the Outside World**

Port management controls external access to containerized services:

- **Port Publishing**: Map container ports to host ports
- **Dynamic Port Allocation**: Let Docker choose host ports
- **Port Ranges**: Map multiple ports efficiently
- **Protocol Selection**: TCP vs UDP port handling

**Security Considerations**:
- Minimize exposed ports
- Use reverse proxies for web services
- Implement proper firewall rules
- Monitor port usage and conflicts

### 4. Network Isolation and Security

**Protecting Services Through Network Segmentation**

Network isolation is crucial for security:

- **Network Segmentation**: Separate services into different networks
- **Inter-Network Communication**: Controlled routing between networks
- **Encrypted Overlays**: TLS encryption for overlay networks
- **Network Policies**: Fine-grained access control

**Production Patterns**:
- Frontend/Backend/Database tier separation
- DMZ implementation for external services
- Service mesh integration
- Zero-trust networking principles

## 🛠 Prerequisites

- **Completed**: Phase 03 (Container Operations) - understanding of container lifecycle
- **Docker**: 20.10+ with networking capabilities
- **Networking Knowledge**: Basic understanding of TCP/IP, DNS, and ports
- **Linux Networking**: Familiarity with network interfaces and routing (helpful)

## ⏱ Time Investment

- **Reading & Understanding**: 75 minutes
- **Hands-on Labs**: 150 minutes
- **Verification & Practice**: 45 minutes
- **Total**: ~4.5 hours

## 🎓 Learning Strategy

1. **Understand Network Drivers**: Learn when to use each network type
2. **Master Service Discovery**: Enable container-to-container communication
3. **Practice Port Management**: Expose services securely
4. **Implement Isolation**: Create secure network architectures
5. **Build Multi-Tier Apps**: Apply networking in real scenarios

## 📖 Topic Deep Dives

### Network Drivers: Choosing the Right Type

**Bridge Network (Default)**:
```bash
# Default bridge network
docker run -d --name web nginx

# Custom bridge network (recommended)
docker network create myapp-network
docker run -d --name web --network myapp-network nginx
docker run -d --name api --network myapp-network node:18
```

**Benefits of Custom Bridge Networks**:
- Automatic DNS resolution between containers
- Better isolation from default bridge
- Network-scoped configuration
- Easy to connect/disconnect containers

**Host Network**:
```bash
# Container uses host network directly
docker run -d --network host nginx

# Same as: nginx listening directly on host's port 80
# No port mapping needed, but less isolation
```

**When to Use Host Network**:
- High-performance requirements (no NAT overhead)
- Need to bind to specific host interfaces
- Network monitoring tools
- Legacy applications requiring specific network behavior

**Overlay Network (Swarm)**:
```bash
# Create encrypted overlay network
docker network create --driver overlay --opt encrypted myapp-overlay

# Deploy services to overlay
docker service create --name web --network myapp-overlay nginx
docker service create --name api --network myapp-overlay node:18
```

### Service Discovery: DNS Resolution in Docker

**Automatic DNS in Custom Networks**:
```bash
# Create network
docker network create webapp

# Run containers
docker run -d --name database --network webapp postgres:13
docker run -d --name backend --network webapp -e DB_HOST=database node:18

# Backend can reach database by name "database"
# Docker provides DNS resolution: database → container IP
```

**DNS Configuration**:
```bash
# Custom DNS servers
docker run --dns 8.8.8.8 --dns 1.1.1.1 nginx

# DNS search domains
docker run --dns-search example.com --dns-search internal.local nginx

# Hostname and domain
docker run --hostname myapp --domainname example.com nginx
```

### Port Publishing: External Access Patterns

**Static Port Mapping**:
```bash
# Map container port 80 to host port 8080
docker run -d -p 8080:80 nginx

# Map to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx

# Map UDP port
docker run -d -p 5353:5353/udp dns-server
```

**Dynamic Port Allocation**:
```bash
# Let Docker choose host port
docker run -d -P nginx  # Maps all exposed ports

# Or specify container port only
docker run -d -p 80 nginx  # Docker chooses host port

# Find assigned port
docker port container_name 80
```

**Port Range Mapping**:
```bash
# Map port range
docker run -d -p 8080-8090:8080-8090 multi-port-app

# Different host and container ranges
docker run -d -p 9000-9010:8080-8090 multi-port-app
```

### Network Isolation: Security Architecture

**Multi-Tier Application Architecture**:
```bash
# Create isolated networks
docker network create frontend --subnet 172.20.0.0/24
docker network create backend --subnet 172.21.0.0/24
docker network create database --subnet 172.22.0.0/24

# Web tier (exposed to internet)
docker run -d --name web \
  --network frontend \
  -p 80:80 \
  nginx

# API tier (internal only)
docker run -d --name api \
  --network backend \
  node:18

# Database tier (most isolated)
docker run -d --name db \
  --network database \
  postgres:13

# Connect API to both backend and database networks
docker network connect database api

# Web can't reach database directly (isolated)
```

## 🔍 Common Use Cases & Patterns

### Pattern 1: Microservices Communication
```bash
# Create application network
docker network create microservices

# Deploy services
docker run -d --name auth-service --network microservices auth:latest
docker run -d --name user-service --network microservices users:latest
docker run -d --name order-service --network microservices orders:latest

# API Gateway with external access
docker run -d --name api-gateway \
  --network microservices \
  -p 8080:8080 \
  gateway:latest

# Services communicate by name internally
# Only gateway is exposed externally
```

### Pattern 2: Development Database Access
```bash
# Database on custom network
docker network create dev-network
docker run -d --name postgres-dev \
  --network dev-network \
  -e POSTGRES_PASSWORD=dev123 \
  postgres:13

# Application on same network
docker run -d --name app-dev \
  --network dev-network \
  -e DATABASE_URL=postgresql://postgres:dev123@postgres-dev:5432/app \
  -p 3000:3000 \
  myapp:dev

# Developer access from host
docker run -d --name postgres-dev \
  --network dev-network \
  -p 127.0.0.1:5432:5432 \  # Local access only
  postgres:13
```

### Pattern 3: Load Balancing with Multiple Backends
```bash
# Create network
docker network create lb-network

# Run multiple backend instances
for i in 1 2 3; do
  docker run -d --name backend-$i \
    --network lb-network \
    myapp:latest
done

# Configure load balancer (nginx)
cat > nginx.conf << 'EOF'
upstream backends {
    server backend-1:8080;
    server backend-2:8080;
    server backend-3:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://backends;
    }
}
EOF

docker run -d --name loadbalancer \
  --network lb-network \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf \
  nginx
```

## 💡 Production Considerations

### Network Security Best Practices

**Minimize Attack Surface**:
- Only expose necessary ports
- Use specific interface bindings (127.0.0.1 for local only)
- Implement network segmentation
- Regular security audits of exposed services

**Network Isolation Strategy**:
```bash
# Separate networks by function
docker network create dmz        # External-facing services
docker network create internal   # Internal services
docker network create data       # Database tier

# Only connect services that need to communicate
# Use multiple networks for services that bridge tiers
```

### Performance Optimization

**Network Driver Performance**:
- Bridge: Standard performance, NAT overhead
- Host: Best performance, no isolation
- Overlay: Encryption overhead, necessary for Swarm
- Macvlan: Near-native performance, complex setup

**DNS Optimization**:
```bash
# Cache DNS lookups
docker run --dns-opt ndots:1 myapp

# Use specific DNS servers for performance
docker run --dns 1.1.1.1 --dns 8.8.8.8 myapp
```

### Troubleshooting Network Issues

**Common Diagnostic Commands**:
```bash
# List networks
docker network ls

# Inspect network details
docker network inspect bridge

# Show container network settings
docker inspect container_name | jq '.[0].NetworkSettings'

# Test connectivity between containers
docker exec container1 ping container2

# Check port mappings
docker port container_name

# View network interfaces in container
docker exec container_name ip addr

# Check routing table
docker exec container_name ip route

# DNS troubleshooting
docker exec container_name nslookup other_container
docker exec container_name cat /etc/resolv.conf
```

**Network Debugging Container**:
```bash
# Run network tools container
docker run -it --rm --network container:target_container \
  nicolaka/netshoot

# Now you can use tools like:
# - tcpdump
# - netstat
# - dig/nslookup
# - curl/wget
# - iperf
```

## 🚨 Common Networking Problems

### Container Can't Reach Another Container

**Check network membership**:
```bash
# Verify both containers are on same network
docker inspect container1 | jq '.[0].NetworkSettings.Networks'
docker inspect container2 | jq '.[0].NetworkSettings.Networks'

# Connect to network if needed
docker network connect mynetwork container1
```

### Port Already in Use

**Find what's using the port**:
```bash
# On Linux/Mac
lsof -i :8080

# On Windows
netstat -ano | findstr :8080

# Use different port or stop conflicting service
docker run -d -p 8081:80 nginx  # Use different host port
```

### DNS Resolution Failures

**Verify DNS configuration**:
```bash
# Check container DNS settings
docker exec container cat /etc/resolv.conf

# Test DNS resolution
docker exec container nslookup google.com
docker exec container nslookup other_container

# Use specific DNS server
docker run --dns 8.8.8.8 myapp
```

## 📊 Monitoring Network Traffic

### Network Statistics
```bash
# Container network statistics
docker exec container netstat -tuln

# Network usage per container
docker stats --no-stream

# Detailed network inspection
docker network inspect bridge | jq '.[0].Containers'
```

### Traffic Analysis
```bash
# Capture traffic with tcpdump
docker exec container tcpdump -i eth0 -w capture.pcap

# Monitor real-time traffic
docker exec container tcpdump -i any -n host other_container

# Bandwidth testing between containers
# Terminal 1 (server)
docker exec container1 iperf3 -s

# Terminal 2 (client)
docker exec container2 iperf3 -c container1
```

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Create and manage different types of Docker networks
- [ ] Configure service discovery and DNS resolution between containers
- [ ] Implement secure network architectures with proper isolation
- [ ] Manage port publishing and external service access
- [ ] Troubleshoot common networking issues using appropriate tools
- [ ] Design production-ready network architectures for microservices

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p04-m01-l01` - Network Driver Selection Guide
- `p04-m01-l02` - Service Discovery Implementation
- `p04-m01-l03` - Network Isolation Strategies
- `p04-m01-l04` - Port Management Best Practices

## 🎯 What's Next

After mastering Docker networking:
- **Phase 05**: Storage and volume management
- **Phase 06**: Docker Compose for multi-container applications
- **Phase 07**: Security hardening and best practices

---

> 💡 **Key Insight**: Docker networking is the foundation for microservices architecture. Understanding how containers communicate, how to isolate services, and how to expose them safely is crucial for building production-ready distributed systems. These networking patterns form the basis for container orchestration and service mesh implementations.