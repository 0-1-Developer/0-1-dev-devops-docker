# p04-m01-l01: Network Driver Selection Guide

> **Duration**: 3 minutes | **Anchor**: `p04-m01-l01` | **Type**: Concept + Quick Practice

## 🎯 Learning Objective

Understand when to use each Docker network driver and make informed decisions based on application requirements.

## 📋 Quick Reference

### Network Driver Decision Matrix

| Use Case | Driver | Benefits | Trade-offs |
|----------|--------|----------|------------|
| **Development/Local** | Bridge (Custom) | DNS resolution, isolation | Single-host only |
| **High Performance** | Host | No NAT overhead | No port isolation |
| **Complete Isolation** | None | Zero network access | No connectivity |
| **Multi-Host Services** | Overlay | Cross-host communication | Requires Swarm |
| **Legacy Integration** | Macvlan | Direct MAC addressing | Complex setup |

## 🔍 Driver Comparison

### Bridge Network (Default vs Custom)

```bash
# ❌ Default bridge - limited DNS
docker run -d --name app1 nginx
docker run -d --name app2 alpine ping app1  # Fails

# ✅ Custom bridge - automatic DNS
docker network create myapp
docker run -d --name app1 --network myapp nginx
docker run -d --name app2 --network myapp alpine ping app1  # Works
```

**When to use**: 
- Single-host applications
- Need container-to-container communication
- Development environments
- Microservices on same machine

### Host Network

```bash
# Direct host network access
docker run -d --network host nginx
# nginx now listens on host's port 80 directly
curl localhost:80  # Direct access, no port mapping
```

**When to use**:
- Maximum performance required
- Network monitoring tools
- Need specific host interface binding
- Legacy apps with special network needs

### None Network

```bash
# Complete network isolation
docker run -it --network none alpine
# Only loopback interface available
```

**When to use**:
- Security-critical applications
- Batch processing jobs
- Applications that only process local files

## ⚡ Quick Practice (2 minutes)

```bash
# Test all network types quickly
echo "=== Testing Network Drivers ==="

# 1. Custom bridge
docker network create test-net
docker run -d --name web --network test-net nginx
echo "Bridge: $(docker exec web hostname -i)"

# 2. Host network  
docker run -d --name host-web --network host nginx
echo "Host: Direct host network"

# 3. None network
docker run -d --name isolated --network none alpine sleep 60
echo "None: $(docker exec isolated ip addr | grep -c inet)"

# Cleanup
docker rm -f web host-web isolated
docker network rm test-net
```

## 🎯 Decision Flowchart

```
Application Requirements?
├── Cross-host communication needed?
│   └── Yes → Overlay Network (requires Swarm)
├── Maximum performance critical?
│   └── Yes → Host Network
├── Complete isolation required?
│   └── Yes → None Network
├── Legacy MAC addressing needed?
│   └── Yes → Macvlan Network
└── Standard containerized app?
    └── Custom Bridge Network
```

## 💡 Production Tips

**Performance Ranking** (fastest to slowest):
1. Host (no NAT)
2. Macvlan (direct L2)
3. Bridge (NAT overhead)
4. Overlay (encryption + routing)

**Security Ranking** (most to least secure):
1. None (no network)
2. Custom Bridge (isolated DNS)
3. Overlay (encrypted)
4. Default Bridge (shared)
5. Host (no isolation)

## 🚨 Common Mistakes

❌ **Using default bridge for multi-container apps**
```bash
# No DNS resolution between containers
docker run -d --name api node:18
docker run -d --name web nginx  # Can't reach 'api' by name
```

✅ **Always use custom networks**
```bash
docker network create app-net
docker run -d --name api --network app-net node:18
docker run -d --name web --network app-net nginx  # DNS works
```

❌ **Host network in production without consideration**
```bash
# Exposes all host network interfaces
docker run -d --network host potentially-vulnerable-app
```

## 🔗 Key Takeaway

**Choose network drivers based on requirements, not convenience**:
- Custom Bridge for 90% of applications
- Host only when performance is critical
- None for security-sensitive workloads
- Overlay for distributed systems

---

**Next**: Service Discovery Implementation (`p04-m01-l02`)