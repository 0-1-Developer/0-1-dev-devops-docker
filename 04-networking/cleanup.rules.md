# Phase 04: Networking - Cleanup Rules

> **Automated cleanup procedures for Docker networking resources and configuration management**

## 🎯 Cleanup Overview

Phase 04 involves extensive networking testing including custom networks, service discovery, port mappings, and isolation strategies. Proper cleanup prevents network conflicts, port exhaustion, and ensures clean testing environments.

## 🧹 Automated Cleanup Script

Complete cleanup sequence for all Phase 04 activities:

```bash
#!/bin/bash
echo "=== Phase 04: Networking Cleanup ==="

# Track cleanup progress
CLEANUP_ITEMS=0
CLEANED_ITEMS=0

cleanup_item() {
    local item_name="$1"
    local cleanup_command="$2"
    CLEANUP_ITEMS=$((CLEANUP_ITEMS + 1))
    
    echo "Cleaning: $item_name..."
    if eval "$cleanup_command" >/dev/null 2>&1; then
        echo "✅ $item_name cleaned successfully"
        CLEANED_ITEMS=$((CLEANED_ITEMS + 1))
    else
        echo "⚠️  $item_name cleanup had issues (may not exist)"
        CLEANED_ITEMS=$((CLEANED_ITEMS + 1))
    fi
}

# 1. Remove lab-specific containers and images
echo "=== Lab Resource Cleanup ==="

# Lab 1: Network drivers containers
cleanup_item "Network drivers lab containers" "docker rm -f web1 web2 database backend frontend host-nginx isolated postgres api web 2>/dev/null"
cleanup_item "Bridge network test containers" "docker rm -f static-web dynamic-web local-only multi-port dns-server 2>/dev/null"

# Lab 2: Service discovery containers
cleanup_item "Service discovery containers" "docker rm -f api-1 api-2 api-3 client custom-dns cache database app cache-2 2>/dev/null"
cleanup_item "Communication test containers" "docker rm -f webserver apiserver testclient 2>/dev/null"

# Lab 3: Network isolation containers
cleanup_item "Network isolation containers" "docker rm -f postgres redis api1 api2 web reverse-proxy app-server public-service private-service admin-service gateway monitor secure-db secure-app 2>/dev/null"

# Lab 4: Port management containers
cleanup_item "Port management containers" "docker rm -f static-web dynamic-web local-only multi-port backend-1 backend-2 backend-3 loadbalancer health-monitor service-a service-a-proxy service-b service-b-proxy external-client restricted-client 2>/dev/null"

# Remove networking test images
cleanup_item "Networking lab images" "docker image rm network-test:v1 nginxdemos/hello:plain-text nicolaka/netshoot 2>/dev/null"

# 2. Remove custom networks
echo "=== Custom Network Cleanup ==="

# Lab networks
cleanup_item "Lab 1 networks" "docker network rm myapp-network frontend-net backend-net database-net 2>/dev/null"
cleanup_item "Lab 2 networks" "docker network rm discovery-lab microservices comm-test 2>/dev/null"
cleanup_item "Lab 3 networks" "docker network rm frontend backend database dmz internal secure public-api private-api admin-only secure-overlay 2>/dev/null"
cleanup_item "Lab 4 networks" "docker network rm lb-network service-mesh external-bridge 2>/dev/null"

# Verification networks
cleanup_item "Verification networks" "docker network rm test-bridge discovery-test port-test 2>/dev/null"

# Remove all custom networks (comprehensive)
cleanup_item "All custom networks" "docker network ls --filter driver=bridge --format '{{.Name}}' | grep -v bridge | xargs -r docker network rm 2>/dev/null"

# 3. Port cleanup and conflict resolution
echo "=== Port Cleanup ==="

# Kill processes that might be holding ports
cleanup_item "Port conflicts cleanup" "fuser -k 80/tcp 443/tcp 8080/tcp 8081/tcp 8082/tcp 9000/tcp 9001/tcp 9002/tcp 9003/tcp 5353/tcp 5353/udp 2>/dev/null || true"

# Release any bound ports
cleanup_item "Docker port cleanup" "docker container prune -f"

# 4. Clean temporary configuration files
echo "=== Configuration File Cleanup ==="

cleanup_item "Nginx configurations" "rm -f nginx-lb.conf nginx.conf proxy.conf mesh.conf 2>/dev/null"
cleanup_item "Application configurations" "rm -f app-config.env server.js package.json Dockerfile 2>/dev/null"
cleanup_item "Test files" "rm -f *.pcap capture.pcap 2>/dev/null"

# 5. DNS and hostname cleanup
echo "=== DNS Cleanup ==="

# Reset any DNS overrides
cleanup_item "DNS configuration reset" "docker run --rm alpine sh -c 'cat /etc/resolv.conf' >/dev/null 2>&1 || true"

# Clear any custom hostnames
cleanup_item "Custom hostname cleanup" "grep -v 'added-by-docker' /etc/hosts > /tmp/hosts-clean && mv /tmp/hosts-clean /etc/hosts 2>/dev/null || true"

# 6. Service discovery cleanup
echo "=== Service Discovery Cleanup ==="

# Remove any service discovery artifacts
cleanup_item "Service aliases cleanup" "docker network ls -q | xargs -I {} docker network inspect {} 2>/dev/null | grep -q 'Aliases' || true"

# Clear DNS caches if possible
cleanup_item "DNS cache flush" "systemctl flush-dns 2>/dev/null || dscacheutil -flushcache 2>/dev/null || true"

# 7. Swarm mode cleanup (if initialized)
echo "=== Swarm Mode Cleanup ==="

# Leave swarm if part of one
if docker info 2>/dev/null | grep -q "Swarm: active"; then
    cleanup_item "Leave Docker Swarm" "docker swarm leave --force"
fi

# Remove overlay networks
cleanup_item "Overlay networks" "docker network ls --filter driver=overlay -q | xargs -r docker network rm 2>/dev/null"

# 8. Verification test cleanup
echo "=== Verification Test Cleanup ==="

cleanup_item "Verification directories" "rm -rf verify-p04-* 2>/dev/null"
cleanup_item "Test working directories" "rm -rf ~/docker-labs/networking 2>/dev/null"

# 9. System network cleanup
echo "=== System Network Cleanup ==="

# Reset iptables rules created by Docker (if safe to do)
if [ "$(id -u)" = "0" ] && [ "$1" = "--reset-iptables" ]; then
    cleanup_item "Docker iptables rules" "iptables -t nat -F DOCKER && iptables -t filter -F DOCKER 2>/dev/null || true"
fi

# Clean up Docker network interfaces
cleanup_item "Docker bridge interfaces" "ip link show | grep docker | awk '{print \$2}' | sed 's/://g' | xargs -I {} ip link delete {} 2>/dev/null || true"

# 10. Advanced cleanup for persistent issues
echo "=== Advanced Cleanup (if needed) ==="

if [ "$1" = "--aggressive" ]; then
    echo "Running aggressive cleanup..."
    
    # Stop all Docker services
    cleanup_item "Stop all containers" "docker stop \$(docker ps -q) 2>/dev/null"
    cleanup_item "Remove all containers" "docker rm \$(docker ps -aq) 2>/dev/null"
    cleanup_item "Remove all networks" "docker network prune --force"
    cleanup_item "System-wide cleanup" "docker system prune --all -f"
    
    # Restart Docker daemon if needed (requires sudo)
    if [ "$(id -u)" = "0" ]; then
        cleanup_item "Docker daemon restart" "systemctl restart docker"
        sleep 10  # Wait for Docker to restart
    else
        echo "⚠️  Consider restarting Docker daemon manually for complete cleanup"
    fi
fi

# Final status report
echo ""
echo "=== Cleanup Summary ==="
echo "Cleaned: $CLEANED_ITEMS/$CLEANUP_ITEMS items"
echo ""

# Verify cleanup effectiveness
echo "=== Post-Cleanup Status ==="
echo "Custom networks:"
CUSTOM_NETWORKS=$(docker network ls --filter driver=bridge --format '{{.Name}}' | grep -v bridge | wc -l)
echo "  Count: $CUSTOM_NETWORKS"

if [ $CUSTOM_NETWORKS -gt 0 ]; then
    echo "  Remaining custom networks:"
    docker network ls --filter driver=bridge --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}' | grep -v bridge | head -5
fi

echo ""
echo "Running containers:"
RUNNING_COUNT=$(docker ps -q | wc -l)
echo "  Count: $RUNNING_COUNT"

if [ $RUNNING_COUNT -gt 0 ]; then
    echo "  Active containers:"
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' | head -5
fi

echo ""
echo "Network-related processes:"
NETWORK_PROCS=$(ps aux | grep -E 'docker|network' | grep -v grep | wc -l)
echo "  Count: $NETWORK_PROCS"

echo ""
echo "✅ Phase 04 networking cleanup completed"
echo ""
echo "💡 Tips:"
echo "  - Run with --aggressive for thorough cleanup"
echo "  - Use --reset-iptables if safe to reset firewall rules"
echo "  - Restart Docker daemon if persistent network issues"
```

## 🔧 Selective Cleanup Procedures

### Lab-Specific Cleanup

**Network Drivers Lab**:
```bash
# Remove network driver test resources
docker rm -f $(docker ps -aq --filter name=web) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=database) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=isolated) 2>/dev/null
docker network rm myapp-network frontend-net backend-net database-net 2>/dev/null
```

**Service Discovery Lab**:
```bash
# Clean service discovery resources
docker rm -f $(docker ps -aq --filter name=api-) 2>/dev/null
docker rm -f $(docker ps -aq --filter name=client) 2>/dev/null
docker network rm discovery-lab microservices comm-test 2>/dev/null
```

**Network Isolation Lab**:
```bash
# Remove isolation test resources
docker rm -f $(docker ps -aq --filter label=access) 2>/dev/null
docker network rm frontend backend database dmz internal secure 2>/dev/null
docker network rm public-api private-api admin-only 2>/dev/null
```

**Port Management Lab**:
```bash
# Clean port management resources
docker rm -f $(docker ps -aq --filter publish) 2>/dev/null
docker network rm lb-network service-mesh external-bridge 2>/dev/null

# Release specific ports
for port in 80 443 8080 8081 8082 9000 9001 9002 9003; do
    fuser -k $port/tcp 2>/dev/null || true
done
```

### Network-Specific Cleanup

**Bridge Networks**:
```bash
# Remove all custom bridge networks
docker network ls --filter driver=bridge --format '{{.Name}}' | grep -v bridge | \
while read network; do
    echo "Removing network: $network"
    docker network rm $network 2>/dev/null || true
done
```

**Overlay Networks** (if using Swarm):
```bash
# Remove overlay networks
docker network ls --filter driver=overlay -q | xargs -r docker network rm

# Leave swarm mode
docker swarm leave --force 2>/dev/null || true
```

**Port Bindings**:
```bash
# Find and release conflicting ports
netstat -tulpn | grep LISTEN | grep -E ":(80|443|8080)" | awk '{print $7}' | \
cut -d'/' -f1 | xargs -I {} kill {} 2>/dev/null || true
```

### Security Cleanup

**Network Information Cleanup**:
```bash
# Remove network inspection artifacts
rm -f /tmp/network-*.json
rm -f network-inspect-*.log

# Clear any exposed network secrets
unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH 2>/dev/null || true
```

**DNS Security Cleanup**:
```bash
# Reset DNS to system defaults
docker run --rm alpine cat /etc/resolv.conf > /tmp/dns-default

# Remove custom DNS configurations
find /etc -name "*dns*" -name "*resolve*" -type f -exec grep -l "docker\|custom" {} \; 2>/dev/null | \
head -5  # Identify files but don't auto-modify system configs
```

## 🚨 Emergency Network Cleanup

When standard cleanup fails or network becomes unstable:

```bash
#!/bin/bash
echo "=== EMERGENCY PHASE 04 NETWORK CLEANUP ==="

# Nuclear option - reset all Docker networking
echo "WARNING: This will reset all Docker networking!"
read -p "Continue? (y/N): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Stop all containers
docker stop $(docker ps -q) 2>/dev/null

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null

# Remove all networks
docker network ls -q | xargs docker network rm 2>/dev/null

# Remove all custom networks (force)
docker network prune --force

# Reset to default bridge network
docker network create --driver bridge bridge 2>/dev/null || true

# Restart Docker daemon (requires sudo)
if [ "$(id -u)" = "0" ]; then
    echo "Restarting Docker daemon..."
    systemctl restart docker
    sleep 15
    
    # Verify default networks exist
    docker network ls
else
    echo "Please restart Docker daemon manually: sudo systemctl restart docker"
fi

echo "Emergency network cleanup completed."
```

## 📋 Pre-Lab Cleanup Checklist

Run before starting any Phase 04 lab:

- [ ] No custom networks exist (`docker network ls`)
- [ ] No containers running on custom networks
- [ ] Required ports available (80, 443, 8080, etc.)
- [ ] No conflicting network interfaces
- [ ] Working directory is clean of network configs

## 📊 Post-Lab Verification

After each lab completion:

```bash
# Quick verification of network cleanup
echo "=== Network Cleanup Check ==="
echo "Custom networks: $(docker network ls --filter driver=bridge --format '{{.Name}}' | grep -v bridge | wc -l)"
echo "Running containers: $(docker ps -q | wc -l)"
echo "Port conflicts:"
netstat -tulpn 2>/dev/null | grep -E ":(80|443|8080|9000)" | wc -l

echo ""
echo "=== Network Health Check ==="
echo "Default bridge exists: $(docker network ls | grep bridge | head -1 | awk '{print $2}')"
echo "Docker daemon responsive: $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'ERROR')"

echo ""
echo "=== System Network Status ==="
echo "Network interfaces: $(ip link show | grep -c 'state UP')"
echo "DNS resolution: $(nslookup google.com >/dev/null 2>&1 && echo 'OK' || echo 'FAIL')"
```

## ⚠️ Cleanup Warnings

**Network Dependencies**:
- Containers must be stopped before removing networks they're connected to
- Some networks may have external dependencies (load balancers, etc.)
- Overlay networks require leaving Swarm mode first

**Port Conflicts**:
- Check for services using common ports before cleanup
- Some ports may be bound by system services
- Port cleanup may require sudo privileges

**DNS and Service Discovery**:
- DNS cache may need manual flushing
- Custom DNS configurations persist across container restarts
- Service aliases are network-scoped

**System Integration**:
- Docker creates iptables rules that may persist
- Bridge interfaces may remain after network removal
- System DNS may be affected by Docker DNS changes

## 🔄 Automated Cleanup Integration

**Pre-commit Hook**:
```bash
# Add to .git/hooks/pre-commit
if [ -d "04-networking" ]; then
    echo "Running Phase 04 network cleanup before commit..."
    bash 04-networking/cleanup.sh --conservative
fi
```

**Makefile Integration**:
```makefile
# Add to project Makefile
.PHONY: clean-networks
clean-networks:
	@echo "Cleaning up Phase 04 network resources..."
	@bash 04-networking/cleanup.sh

.PHONY: clean-networks-aggressive  
clean-networks-aggressive:
	@echo "Aggressive cleanup of all network resources..."
	@bash 04-networking/cleanup.sh --aggressive
```

**Cron Job for Regular Cleanup**:
```bash
# Add to crontab for regular network cleanup
# Run every day at 2 AM
0 2 * * * /path/to/docker/04-networking/cleanup.sh >/dev/null 2>&1
```

## 📈 Cleanup Monitoring

Track cleanup effectiveness and network health:

```bash
# Create network cleanup log
echo "$(date): Phase 04 network cleanup completed" >> ~/.docker-network-cleanup.log
echo "  - Custom networks removed: $(docker network ls --filter driver=bridge | grep -v bridge | wc -l)" >> ~/.docker-network-cleanup.log
echo "  - Containers cleaned: $(docker ps -a | wc -l)" >> ~/.docker-network-cleanup.log
echo "  - Port conflicts: $(netstat -tulpn | grep -E ':(80|443|8080)' | wc -l)" >> ~/.docker-network-cleanup.log
echo "  - Network interfaces: $(ip link show | wc -l)" >> ~/.docker-network-cleanup.log
```

## 🔍 Troubleshooting Cleanup Issues

**Common Problems and Solutions**:

1. **Network in use error**:
   ```bash
   # Find containers using the network
   docker network inspect network_name | jq '.[0].Containers'
   
   # Remove containers first
   docker rm -f container_name
   docker network rm network_name
   ```

2. **Port already in use**:
   ```bash
   # Find process using port
   lsof -i :8080
   netstat -tulpn | grep :8080
   
   # Kill process or change port
   fuser -k 8080/tcp
   ```

3. **Cannot remove default networks**:
   ```bash
   # Don't try to remove bridge, host, none networks
   # Only remove custom networks
   docker network ls --filter driver=bridge --format '{{.Name}}' | grep -v bridge
   ```

4. **DNS resolution fails after cleanup**:
   ```bash
   # Restart Docker daemon
   sudo systemctl restart docker
   
   # Flush DNS cache
   sudo systemd-resolve --flush-caches  # Ubuntu/Debian
   sudo dscacheutil -flushcache         # macOS
   ```

---

> 💡 **Cleanup Philosophy**: Phase 04 networking creates complex interconnections that can persist across sessions. Thorough cleanup prevents port conflicts, network namespace pollution, and ensures each lab starts with a clean networking environment essential for reliable testing.