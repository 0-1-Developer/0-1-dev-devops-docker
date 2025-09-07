# Phase 04: Networking - Verification Rules

> **Comprehensive validation of Docker networking skills including service communication, isolation, and port management**

## 🎯 Verification Overview

These rules validate mastery of Docker networking concepts including network drivers, service discovery, network isolation, and port management. All verification focuses on production networking patterns and security best practices.

## ✅ Verification Rules

### Rule 1: Network Driver Selection and Configuration
**Anchor**: `p04-network-drivers`  
**Type**: Automated + Manual

**Automated Test Setup**:
```bash
mkdir -p verify-p04-network && cd verify-p04-network

# Create test application
cat > server.js << 'EOF'
const http = require('http');
const os = require('os');

const server = http.createServer((req, res) => {
    const response = {
        hostname: os.hostname(),
        network: process.env.NETWORK_TYPE || 'unknown',
        timestamp: new Date().toISOString()
    };
    
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify(response));
});

server.listen(8080, () => {
    console.log('Server listening on port 8080');
});
EOF

cat > package.json << 'EOF'
{
    "name": "network-test",
    "version": "1.0.0",
    "main": "server.js",
    "dependencies": {}
}
EOF

cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json server.js ./
EXPOSE 8080
CMD ["node", "server.js"]
EOF

docker build -t network-test:v1 .
```

**Student Task**: Demonstrate proper network driver usage for different scenarios

**Automated Verification**:
```bash
# Test 1: Custom bridge network with DNS
echo "=== Testing custom bridge network ==="
docker network create test-bridge --driver bridge

docker run -d --name server1 --network test-bridge network-test:v1
docker run -d --name server2 --network test-bridge network-test:v1
docker run -d --name client --network test-bridge alpine sleep 300

# Test DNS resolution
if docker exec client ping -c 2 server1 >/dev/null 2>&1; then
    echo "✅ DNS resolution works in custom bridge network"
    BRIDGE_DNS=passed
else
    echo "❌ DNS resolution failed in custom bridge network"
    BRIDGE_DNS=failed
fi

# Test container-to-container communication
if docker exec client wget -qO- http://server1:8080 | grep -q "hostname"; then
    echo "✅ Container communication works"
    BRIDGE_COMM=passed
else
    echo "❌ Container communication failed"
    BRIDGE_COMM=failed
fi

# Test 2: Host network mode
echo "=== Testing host network mode ==="
docker run -d --name host-server --network host -e NETWORK_TYPE=host network-test:v1

# Verify service is accessible on host without port mapping
if curl -s localhost:8080 | grep -q "host"; then
    echo "✅ Host network mode working correctly"
    HOST_NETWORK=passed
else
    echo "❌ Host network mode not working"
    HOST_NETWORK=failed
fi

# Test 3: None network isolation
echo "=== Testing none network isolation ==="
docker run -d --name isolated --network none alpine sh -c 'ip addr show'

# Check that only loopback interface exists
INTERFACES=$(docker exec isolated ip addr | grep -c "inet ")
if [ "$INTERFACES" -eq "1" ]; then
    echo "✅ None network provides complete isolation"
    NONE_NETWORK=passed
else
    echo "❌ None network isolation incomplete"
    NONE_NETWORK=failed
fi

# Cleanup
docker rm -f server1 server2 client host-server isolated
docker network rm test-bridge
```

**Manual Assessment**:
- [ ] Can explain when to use each network driver type
- [ ] Understands performance implications of different drivers
- [ ] Knows security considerations for each network type
- [ ] Can troubleshoot network driver issues

**Success Criteria**:
- [ ] Custom bridge network enables DNS resolution
- [ ] Host network mode provides direct host access
- [ ] None network ensures complete isolation
- [ ] Appropriate driver selection for use cases

---

### Rule 2: Service Discovery Implementation
**Anchor**: `p04-service-discovery`  
**Type**: Automated

**Test Setup**:
```bash
mkdir -p verify-p04-discovery && cd verify-p04-discovery

# Create service discovery test environment
docker network create discovery-test

# Deploy multiple instances with network alias
for i in 1 2 3; do
    docker run -d --name api-$i \
        --network discovery-test \
        --network-alias api-service \
        network-test:v1
done

# Deploy client for testing
docker run -d --name discovery-client \
    --network discovery-test \
    nicolaka/netshoot sleep 300
```

**Automated Verification**:
```bash
# Test 1: DNS resolution returns multiple IPs
echo "=== Testing DNS-based service discovery ==="
IPS=$(docker exec discovery-client nslookup api-service | grep -c "Address.*172")

if [ "$IPS" -eq "3" ]; then
    echo "✅ DNS returns all service instances"
    DNS_DISCOVERY=passed
else
    echo "❌ DNS discovery incomplete (found $IPS/3 instances)"
    DNS_DISCOVERY=failed
fi

# Test 2: Round-robin load balancing
echo "=== Testing round-robin DNS ==="
HOSTS=""
for i in {1..6}; do
    HOST=$(docker exec discovery-client curl -s http://api-service:8080 | jq -r '.hostname')
    HOSTS="$HOSTS $HOST"
done

UNIQUE_HOSTS=$(echo $HOSTS | tr ' ' '\n' | sort -u | wc -l)
if [ "$UNIQUE_HOSTS" -eq "3" ]; then
    echo "✅ Round-robin DNS load balancing works"
    ROUND_ROBIN=passed
else
    echo "❌ Round-robin not working properly (hit $UNIQUE_HOSTS/3 hosts)"
    ROUND_ROBIN=failed
fi

# Test 3: Container name resolution
echo "=== Testing container name resolution ==="
if docker exec discovery-client curl -s http://api-1:8080 | grep -q "hostname"; then
    echo "✅ Direct container name resolution works"
    NAME_RESOLUTION=passed
else
    echo "❌ Container name resolution failed"
    NAME_RESOLUTION=failed
fi

# Test 4: Custom hostname and domainname
docker run -d --name custom-host \
    --network discovery-test \
    --hostname myapp \
    --domainname example.com \
    network-test:v1

if docker exec discovery-client nslookup myapp.example.com | grep -q "172"; then
    echo "✅ Custom hostname resolution works"
    CUSTOM_HOST=passed
else
    echo "❌ Custom hostname resolution failed"
    CUSTOM_HOST=failed
fi

# Cleanup
docker rm -f api-1 api-2 api-3 discovery-client custom-host
docker network rm discovery-test
cd .. && rm -rf verify-p04-discovery
```

**Success Criteria**:
- [ ] DNS returns all instances with same network alias
- [ ] Round-robin DNS provides basic load balancing
- [ ] Container names resolve correctly
- [ ] Custom hostnames work as expected

---

### Rule 3: Network Isolation and Security
**Anchor**: `p04-network-isolation`  
**Type**: Security-focused Automated + Manual

**Security Test Setup**:
```bash
mkdir -p verify-p04-isolation && cd verify-p04-isolation

# Create isolated network tiers
docker network create frontend --subnet 172.20.0.0/24
docker network create backend --subnet 172.21.0.0/24
docker network create database --subnet 172.22.0.0/24

# Deploy services in isolated tiers
docker run -d --name web --network frontend nginx:alpine
docker run -d --name api --network backend network-test:v1
docker run -d --name db --network database postgres:13-alpine
```

**Automated Security Verification**:
```bash
# Test 1: Network isolation between tiers
echo "=== Testing network isolation ==="

# Web cannot reach database (different networks)
docker exec web ping -c 2 db 2>/dev/null
if [ $? -ne 0 ]; then
    echo "✅ Frontend isolated from database"
    ISOLATION_1=passed
else
    echo "❌ SECURITY ISSUE: Frontend can reach database"
    ISOLATION_1=failed
fi

# API cannot reach database (not connected)
docker exec api ping -c 2 db 2>/dev/null
if [ $? -ne 0 ]; then
    echo "✅ Backend isolated from database"
    ISOLATION_2=passed
else
    echo "❌ SECURITY ISSUE: Backend can reach database without connection"
    ISOLATION_2=failed
fi

# Test 2: Controlled connectivity
echo "=== Testing controlled connectivity ==="

# Connect API to database network
docker network connect database api

# Now API can reach database
if docker exec api ping -c 2 db >/dev/null 2>&1; then
    echo "✅ Controlled connectivity works"
    CONTROLLED_CONN=passed
else
    echo "❌ Controlled connectivity failed"
    CONTROLLED_CONN=failed
fi

# Connect web to backend
docker network connect backend web

# Web can reach API but still not database
if docker exec web ping -c 2 api >/dev/null 2>&1; then
    echo "✅ Multi-tier connectivity established"
    MULTI_TIER=passed
else
    echo "❌ Multi-tier connectivity failed"
    MULTI_TIER=failed
fi

docker exec web ping -c 2 db 2>/dev/null
if [ $? -ne 0 ]; then
    echo "✅ Database remains isolated from frontend"
    DB_ISOLATION=passed
else
    echo "❌ SECURITY ISSUE: Frontend can reach database through backend"
    DB_ISOLATION=failed
fi

# Test 3: Network information leakage
echo "=== Testing network information security ==="

# Check if container on one network can discover services on another
NETWORKS_VISIBLE=$(docker exec web ip addr | grep -c "inet 172")
if [ "$NETWORKS_VISIBLE" -eq "2" ]; then  # Should see frontend and backend only
    echo "✅ Network information properly scoped"
    NETWORK_INFO=passed
else
    echo "❌ Network information leakage detected"
    NETWORK_INFO=failed
fi

# Cleanup
docker rm -f web api db
docker network rm frontend backend database
cd .. && rm -rf verify-p04-isolation
```

**Manual Security Assessment**:
- [ ] Implements proper network segmentation strategy
- [ ] Uses least-privilege network connectivity
- [ ] Understands attack surface implications
- [ ] Can design DMZ patterns for external services

**Success Criteria**:
- [ ] Networks provide proper isolation by default
- [ ] Controlled connectivity works as expected
- [ ] No unintended network information leakage
- [ ] Security boundaries are maintained

---

### Rule 4: Port Management and External Access
**Anchor**: `p04-port-management`  
**Type**: Manual + Automated

**Test Setup**:
```bash
mkdir -p verify-p04-ports && cd verify-p04-ports

# Create test network
docker network create port-test
```

**Automated Port Management Test**:
```bash
# Test 1: Static port mapping
echo "=== Testing static port mapping ==="
docker run -d --name static-port \
    --network port-test \
    -p 8080:8080 \
    network-test:v1

if curl -s localhost:8080 | grep -q "hostname"; then
    echo "✅ Static port mapping works"
    STATIC_PORT=passed
else
    echo "❌ Static port mapping failed"
    STATIC_PORT=failed
fi

# Test 2: Dynamic port allocation
echo "=== Testing dynamic port allocation ==="
docker run -d --name dynamic-port \
    --network port-test \
    -P \
    network-test:v1

DYNAMIC=$(docker port dynamic-port 8080 | cut -d: -f2)
if curl -s localhost:$DYNAMIC | grep -q "hostname"; then
    echo "✅ Dynamic port allocation works (port $DYNAMIC)"
    DYNAMIC_PORT=passed
else
    echo "❌ Dynamic port allocation failed"
    DYNAMIC_PORT=failed
fi

# Test 3: Interface-specific binding
echo "=== Testing interface-specific binding ==="
docker run -d --name local-only \
    --network port-test \
    -p 127.0.0.1:8081:8080 \
    network-test:v1

# Should work on localhost
if curl -s localhost:8081 | grep -q "hostname"; then
    echo "✅ Local interface binding works"
    LOCAL_BIND=passed
else
    echo "❌ Local interface binding failed"
    LOCAL_BIND=failed
fi

# Should not be accessible externally (security test)
EXTERNAL_IP=$(hostname -I | awk '{print $1}')
curl -s --connect-timeout 2 $EXTERNAL_IP:8081 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "✅ Local-only binding provides security"
    LOCAL_SECURITY=passed
else
    echo "❌ SECURITY ISSUE: Local-only port accessible externally"
    LOCAL_SECURITY=failed
fi

# Test 4: Port range mapping
echo "=== Testing port range mapping ==="
docker run -d --name port-range \
    --network port-test \
    -p 9000-9003:9000-9003 \
    alpine sh -c 'for p in 9000 9001 9002 9003; do nc -l -p $p & done; sleep 300'

SUCCESS=0
for PORT in 9000 9001 9002 9003; do
    nc -zv localhost $PORT >/dev/null 2>&1 && SUCCESS=$((SUCCESS + 1))
done

if [ "$SUCCESS" -eq "4" ]; then
    echo "✅ Port range mapping works"
    PORT_RANGE=passed
else
    echo "❌ Port range mapping incomplete ($SUCCESS/4 ports)"
    PORT_RANGE=failed
fi

# Cleanup
docker rm -f static-port dynamic-port local-only port-range
docker network rm port-test
cd .. && rm -rf verify-p04-ports
```

**Manual Assessment**:
- [ ] Understands security implications of port exposure
- [ ] Can implement appropriate port management strategies
- [ ] Knows when to use dynamic vs static ports
- [ ] Implements interface binding for security

**Success Criteria**:
- [ ] Static and dynamic port mapping work correctly
- [ ] Interface-specific binding provides security
- [ ] Port ranges can be mapped efficiently
- [ ] No unnecessary ports exposed

---

### Rule 5: Production Networking Integration
**Anchor**: `p04-production-networking`  
**Type**: Comprehensive Manual Assessment

**Integration Scenario**: Student demonstrates production-ready networking architecture.

**Assessment Requirements**:

**Network Architecture**:
- [ ] Appropriate network driver selection for services
- [ ] Proper network segmentation and isolation
- [ ] Service discovery implementation
- [ ] Secure port exposure strategy

**Security Implementation**:
- [ ] Network isolation between tiers
- [ ] Minimal port exposure
- [ ] Interface-specific bindings where appropriate
- [ ] No sensitive services on default bridge

**Performance Optimization**:
- [ ] Efficient DNS resolution
- [ ] Appropriate network driver for performance needs
- [ ] Minimal network hops between services
- [ ] Load balancing considerations

**Operational Excellence**:
- [ ] Clear network naming conventions
- [ ] Documented network topology
- [ ] Monitoring and troubleshooting capability
- [ ] Disaster recovery considerations

---

## 🔄 Comprehensive Verification Script

Complete verification sequence for all rules:

```bash
#!/bin/bash
echo "=== Phase 04 Networking Verification ==="

TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_result="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$test_result" = "passed" ]; then
        echo "✅ $test_name: PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ $test_name: FAILED"
    fi
}

# Rule 1: Network Drivers
echo "Testing Rule 1: Network Driver Configuration..."
# ... (driver tests)

# Rule 2: Service Discovery
echo "Testing Rule 2: Service Discovery..."
# ... (discovery tests)

# Rule 3: Network Isolation
echo "Testing Rule 3: Network Security..."
# ... (isolation tests)

# Rule 4: Port Management
echo "Testing Rule 4: Port Configuration..."
# ... (port tests)

echo ""
echo "=== Verification Results ==="
echo "Automated Tests: $PASSED_TESTS/$TOTAL_TESTS passed"
echo ""
echo "Manual verification required for:"
echo "- [ ] Network driver selection rationale"
echo "- [ ] Service discovery architecture design"
echo "- [ ] Security isolation implementation"
echo "- [ ] Port management strategy"
echo "- [ ] Production networking patterns"
echo ""
echo "Complete manual assessments to finish Phase 04 verification."
```

## 📋 Manual Verification Checklist

### Networking Concepts
- [ ] **Driver Selection**: Chooses appropriate network driver for use case
- [ ] **Service Discovery**: Implements DNS-based service discovery effectively
- [ ] **Network Isolation**: Creates secure network boundaries
- [ ] **Port Management**: Exposes services safely with minimal attack surface

### Production Skills
- [ ] **Architecture Design**: Creates scalable network architectures
- [ ] **Security Implementation**: Applies defense-in-depth networking
- [ ] **Performance Optimization**: Minimizes network latency
- [ ] **Troubleshooting**: Diagnoses and resolves networking issues

### Integration Capabilities
- [ ] **Microservices Ready**: Designs networks for microservices
- [ ] **Load Balancing**: Implements traffic distribution patterns
- [ ] **External Integration**: Connects to external services safely
- [ ] **Monitoring**: Enables network observability

## 🎯 Success Criteria Summary

**Complete Phase 04 when:**
- [ ] All automated verification tests pass
- [ ] Manual assessment confirms networking expertise
- [ ] Can design and implement production network architectures
- [ ] Demonstrates troubleshooting skills for network issues
- [ ] Ready to progress to storage and volumes in Phase 05

---

> **Critical Success Indicator**: Can design and implement a complete networking architecture that provides service discovery, proper isolation, secure external access, and production-ready communication patterns for containerized applications.