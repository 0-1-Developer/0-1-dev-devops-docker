# Phase 09 Cleanup Rules: Container Registries

> **Purpose**: Safely clean up registry infrastructure, test environments, and persistent data  
> **Scope**: Complete removal of registry components while preserving valuable data when needed

## 🧹 Cleanup Overview

This cleanup ensures:
- Safe removal of registry containers and services
- Proper cleanup of storage volumes and persistent data
- Network and security component removal
- Certificate and authentication cleanup
- Optional data preservation for future use

## 🗑️ Rule 1: Basic Registry Cleanup

### Components to Clean
- Docker registry containers
- Registry configuration files
- SSL certificates and keys
- Storage volumes and bind mounts

### Cleanup Commands
```bash
# Stop and remove registry container
docker stop registry-container
docker rm registry-container

# Remove registry image (optional)
docker rmi registry:2.8

# Clean up configuration files
sudo rm -rf /etc/docker/registry/
sudo rm -rf /opt/registry/config/

# Remove SSL certificates
sudo rm -rf /certs/registry/
sudo rm -f /etc/ssl/certs/registry.*

# Clean up authentication files
sudo rm -rf /auth/
sudo rm -f /etc/htpasswd/registry*

# Remove storage volumes (WARNING: Destroys all images!)
sudo rm -rf /var/lib/registry/
docker volume rm registry-storage 2>/dev/null || true
```

### Data Preservation (Optional)
```bash
# Backup registry data before cleanup
sudo tar -czf registry-backup-$(date +%Y%m%d).tar.gz /var/lib/registry/

# Backup configuration
sudo tar -czf registry-config-backup-$(date +%Y%m%d).tar.gz /etc/docker/registry/

# Store backups in safe location
sudo mv registry-*-backup-*.tar.gz /backup/registry/
```

### Verification Commands
```bash
# Verify container removal
docker ps -a | grep registry

# Verify image removal
docker images | grep registry

# Verify file cleanup
ls -la /var/lib/registry/
ls -la /etc/docker/registry/
ls -la /certs/registry/
```

## 🗑️ Rule 2: Authentication System Cleanup

### Components to Clean
- Authentication service containers
- User credential stores
- JWT signing keys
- LDAP/OAuth configurations

### Cleanup Commands
```bash
# Stop authentication services
docker stop auth-server
docker stop ldap-server
docker rm auth-server ldap-server

# Remove authentication images
docker rmi auth-server:latest
docker rmi osixia/openldap:latest

# Clean up credential stores
sudo rm -rf /auth/htpasswd/
sudo rm -rf /auth/users/
sudo rm -rf /auth/ldap/

# Remove JWT keys
sudo rm -f /auth/keys/jwt-key.pem
sudo rm -f /auth/keys/jwt-key.pub

# Clean up OAuth configurations
sudo rm -rf /auth/oauth/
sudo rm -f /etc/oauth2_proxy/oauth2_proxy.cfg
```

### Token Cleanup
```bash
# Clear issued tokens (if using token service)
curl -X DELETE http://localhost:5001/v1/tokens/cleanup

# Remove token database
sudo rm -f /var/lib/auth/tokens.db
sudo rm -rf /var/lib/auth/sessions/

# Clean up token service logs
sudo rm -f /var/log/auth/token-service.log
```

### Verification Commands
```bash
# Verify auth container removal
docker ps -a | grep auth

# Verify credential cleanup
ls -la /auth/
ls -la /var/lib/auth/

# Test registry access (should fail if auth removed)
curl -k https://registry.local:5000/v2/_catalog
```

## 🗑️ Rule 3: Registry Mirror and Cache Cleanup

### Components to Clean
- Mirror registry containers
- Pull-through cache data
- Proxy configurations
- Cache storage volumes

### Cleanup Commands
```bash
# Stop mirror and cache services
docker stop registry-mirror
docker stop registry-cache
docker stop registry-proxy

# Remove mirror containers
docker rm registry-mirror registry-cache registry-proxy

# Clean up mirror storage
sudo rm -rf /var/lib/registry-mirror/
sudo rm -rf /var/lib/registry-cache/

# Remove proxy configurations
sudo rm -f /etc/nginx/conf.d/registry-mirror.conf
sudo rm -f /etc/haproxy/haproxy.cfg

# Clean up cache volumes
docker volume rm mirror-cache 2>/dev/null || true
docker volume rm registry-proxy-cache 2>/dev/null || true
```

### Cache Statistics Cleanup
```bash
# Remove cache metrics and logs
sudo rm -f /var/log/registry/mirror.log
sudo rm -f /var/log/registry/cache.log
sudo rm -rf /var/lib/prometheus/registry-metrics/

# Clean up cache configuration
sudo rm -rf /etc/registry-mirror/
sudo rm -f /opt/cache/config.yml
```

### Verification Commands
```bash
# Verify mirror container removal
docker ps -a | grep mirror

# Verify cache storage cleanup
ls -la /var/lib/registry-mirror/
ls -la /var/lib/registry-cache/

# Test mirror access (should fail)
curl -k https://mirror.registry.local:5000/v2/
```

## 🗑️ Rule 4: Lifecycle Management Cleanup

### Components to Clean
- Cleanup service containers
- Scheduled cleanup jobs
- Retention policy configurations
- Cleanup logs and metrics

### Cleanup Commands
```bash
# Stop cleanup services
docker stop registry-cleaner
docker stop lifecycle-manager
docker rm registry-cleaner lifecycle-manager

# Remove cleanup images
docker rmi registry-cleaner:latest
docker rmi lifecycle-manager:latest

# Clean up cleanup configurations
sudo rm -rf /etc/registry-cleanup/
sudo rm -f /opt/cleanup/policies.yml
sudo rm -f /etc/cron.d/registry-cleanup

# Remove cleanup logs
sudo rm -f /var/log/registry/cleanup.log
sudo rm -f /var/log/registry/lifecycle.log
```

### Scheduled Job Cleanup
```bash
# Remove cron jobs
sudo crontab -l | grep -v registry-cleanup | sudo crontab -
sudo rm -f /etc/cron.d/registry-*

# Stop and disable systemd services
sudo systemctl stop registry-cleanup.service
sudo systemctl disable registry-cleanup.service
sudo rm -f /etc/systemd/system/registry-cleanup.service

# Reload systemd
sudo systemctl daemon-reload
```

### Policy Configuration Cleanup
```bash
# Remove retention policies
sudo rm -rf /etc/registry/policies/
sudo rm -f /opt/registry/retention.yml

# Clean up policy templates
sudo rm -rf /usr/local/share/registry-policies/
sudo rm -f /etc/default/registry-cleanup
```

### Verification Commands
```bash
# Verify cleanup service removal
docker ps -a | grep cleanup
docker ps -a | grep lifecycle

# Verify scheduled job removal
sudo crontab -l | grep registry
sudo systemctl list-units | grep registry

# Verify policy cleanup
ls -la /etc/registry-cleanup/
ls -la /etc/registry/policies/
```

## 🗑️ Rule 5: Enterprise Registry (Harbor) Cleanup

### Components to Clean
- Harbor service containers
- Harbor database
- Harbor configuration
- Harbor storage volumes

### Cleanup Commands
```bash
# Stop Harbor services using docker-compose
cd /opt/harbor
docker-compose down

# Remove Harbor containers and volumes
docker-compose down -v

# Remove Harbor images
docker rmi $(docker images | grep goharbor | awk '{print $3}')

# Clean up Harbor data
sudo rm -rf /data/harbor/
sudo rm -rf /var/log/harbor/
sudo rm -rf /etc/harbor/

# Remove Harbor installation
sudo rm -rf /opt/harbor/
```

### Database Cleanup
```bash
# Backup Harbor database before cleanup (optional)
docker exec harbor-db pg_dump -U postgres registry > harbor-db-backup.sql

# Remove database files
sudo rm -rf /data/database/
sudo rm -rf /var/lib/postgresql/data/harbor/

# Clean up database configurations
sudo rm -f /etc/postgresql/*/main/harbor.conf
```

### Certificate and Secret Cleanup
```bash
# Remove Harbor SSL certificates
sudo rm -rf /data/cert/
sudo rm -f /etc/ssl/certs/harbor.*
sudo rm -f /etc/ssl/private/harbor.*

# Clean up Harbor secrets
sudo rm -rf /data/secret/
sudo rm -f /opt/harbor/harbor.yml.tmpl
sudo rm -f /opt/harbor/harbor.yml
```

### Verification Commands
```bash
# Verify Harbor container removal
docker ps -a | grep harbor
docker ps -a | grep goharbor

# Verify Harbor data cleanup
ls -la /data/harbor/
ls -la /opt/harbor/

# Test Harbor access (should fail)
curl -k https://harbor.local/
```

## 🗑️ Rule 6: High Availability Setup Cleanup

### Components to Clean
- Load balancer configurations
- Multiple registry instances
- Shared storage mounts
- Cluster coordination services

### Cleanup Commands
```bash
# Stop all registry cluster nodes
docker stop registry-node-1 registry-node-2 registry-node-3
docker rm registry-node-1 registry-node-2 registry-node-3

# Stop load balancer
docker stop haproxy-lb nginx-lb
docker rm haproxy-lb nginx-lb

# Remove load balancer images
docker rmi haproxy:latest nginx:latest

# Clean up load balancer configurations
sudo rm -f /etc/haproxy/haproxy.cfg
sudo rm -f /etc/nginx/conf.d/registry-lb.conf
```

### Shared Storage Cleanup
```bash
# Unmount shared storage (be very careful!)
sudo umount /shared/registry
sudo umount /nfs/registry

# Remove NFS configurations
sudo rm -f /etc/exports
sudo sed -i '/registry/d' /etc/fstab

# Clean up shared storage directories
sudo rm -rf /shared/registry/
sudo rm -rf /nfs/registry/
```

### Cluster Service Cleanup
```bash
# Stop coordination services
docker stop consul etcd zookeeper
docker rm consul etcd zookeeper

# Remove service discovery images
docker rmi consul:latest
docker rmi quay.io/coreos/etcd:latest
docker rmi zookeeper:latest

# Clean up service configurations
sudo rm -rf /etc/consul/
sudo rm -rf /etc/etcd/
sudo rm -rf /var/lib/consul/
sudo rm -rf /var/lib/etcd/
```

### Network Cleanup
```bash
# Remove custom networks
docker network rm registry-cluster
docker network rm registry-backend
docker network rm registry-frontend

# Clean up network configurations
sudo rm -f /etc/systemd/network/registry-*.network
sudo rm -f /etc/netplan/registry-*.yaml
```

### Verification Commands
```bash
# Verify cluster node removal
docker ps -a | grep registry-node

# Verify load balancer cleanup
docker ps -a | grep -E "(haproxy|nginx)"

# Verify network cleanup
docker network ls | grep registry

# Verify shared storage cleanup
mount | grep registry
ls -la /shared/ /nfs/
```

## 🧹 Complete Cleanup Script

### Comprehensive Cleanup Runner
```bash
#!/bin/bash
# cleanup-phase09.sh

echo "🧹 Phase 09: Container Registries Cleanup"
echo "=========================================="

# Function to ask for confirmation
confirm() {
    read -p "$1 (y/N): " response
    [[ $response =~ ^[Yy]$ ]]
}

# Function to backup data
backup_data() {
    if confirm "Create backup of registry data before cleanup?"; then
        echo "📦 Creating backups..."
        sudo mkdir -p /backup/registry-$(date +%Y%m%d)/
        
        # Backup registry data
        if [ -d "/var/lib/registry" ]; then
            sudo tar -czf /backup/registry-$(date +%Y%m%d)/registry-data.tar.gz /var/lib/registry/
        fi
        
        # Backup configurations
        if [ -d "/etc/docker/registry" ]; then
            sudo tar -czf /backup/registry-$(date +%Y%m%d)/registry-config.tar.gz /etc/docker/registry/
        fi
        
        echo "✅ Backups created in /backup/registry-$(date +%Y%m%d)/"
    fi
}

# Backup data before cleanup
backup_data

echo "🛑 Stopping all registry services..."

# Stop all registry-related containers
docker stop $(docker ps -q --filter "name=registry") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=harbor") 2>/dev/null || true
docker stop $(docker ps -q --filter "name=auth") 2>/dev/null || true

echo "🗑️  Removing containers..."

# Remove all registry-related containers
docker rm $(docker ps -aq --filter "name=registry") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=harbor") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=auth") 2>/dev/null || true

if confirm "Remove Docker images?"; then
    echo "🗑️  Removing images..."
    docker rmi registry:2.8 2>/dev/null || true
    docker rmi $(docker images | grep goharbor | awk '{print $3}') 2>/dev/null || true
    docker rmi $(docker images | grep registry | awk '{print $3}') 2>/dev/null || true
fi

if confirm "Remove storage volumes and data? (WARNING: This destroys all registry data!)"; then
    echo "🗑️  Removing storage data..."
    
    # Remove volumes
    docker volume rm registry-storage 2>/dev/null || true
    docker volume rm harbor-data 2>/dev/null || true
    docker volume rm registry-cache 2>/dev/null || true
    
    # Remove data directories
    sudo rm -rf /var/lib/registry/
    sudo rm -rf /data/harbor/
    sudo rm -rf /var/lib/registry-mirror/
fi

if confirm "Remove configuration files?"; then
    echo "🗑️  Removing configurations..."
    
    sudo rm -rf /etc/docker/registry/
    sudo rm -rf /etc/harbor/
    sudo rm -rf /opt/harbor/
    sudo rm -rf /auth/
    sudo rm -rf /certs/registry/
fi

if confirm "Remove networks?"; then
    echo "🗑️  Removing networks..."
    
    docker network rm registry-lab 2>/dev/null || true
    docker network rm registry-cluster 2>/dev/null || true
    docker network rm harbor-net 2>/dev/null || true
fi

if confirm "Clean up scheduled jobs and services?"; then
    echo "🗑️  Removing scheduled jobs..."
    
    sudo crontab -l | grep -v registry | sudo crontab - 2>/dev/null || true
    sudo rm -f /etc/cron.d/registry-* 2>/dev/null || true
    sudo systemctl stop registry-*.service 2>/dev/null || true
    sudo systemctl disable registry-*.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/registry-*.service 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
fi

echo "🧹 Cleaning up logs..."
sudo rm -rf /var/log/registry/ 2>/dev/null || true
sudo rm -rf /var/log/harbor/ 2>/dev/null || true

echo "🧼 Running Docker system cleanup..."
docker system prune -f

# Final verification
echo "🔍 Verification - Remaining registry components:"
echo "Containers:"
docker ps -a | grep -E "(registry|harbor|auth)" || echo "  None found"
echo "Images:"
docker images | grep -E "(registry|harbor|auth)" || echo "  None found"
echo "Volumes:"
docker volume ls | grep -E "(registry|harbor|auth)" || echo "  None found"
echo "Networks:"
docker network ls | grep -E "(registry|harbor|auth)" || echo "  None found"

echo "=========================================="
echo "✅ Phase 09 cleanup completed!"

if [ -d "/backup/registry-$(date +%Y%m%d)" ]; then
    echo "📦 Backups available in: /backup/registry-$(date +%Y%m%d)/"
fi

echo ""
echo "To restore from backup (if needed):"
echo "  sudo tar -xzf /backup/registry-$(date +%Y%m%d)/registry-data.tar.gz -C /"
echo "  sudo tar -xzf /backup/registry-$(date +%Y%m%d)/registry-config.tar.gz -C /"
```

## 📝 Cleanup Checklist

### Pre-Cleanup Verification
- [ ] List all running registry containers
- [ ] Check for dependent services
- [ ] Verify backup requirements
- [ ] Document current configuration

### Data Safety
- [ ] Create backup of registry data
- [ ] Export important configurations
- [ ] Document image inventory
- [ ] Save authentication credentials

### Container Cleanup
- [ ] Stop all registry containers
- [ ] Remove registry containers
- [ ] Remove registry images (optional)
- [ ] Clean up container logs

### Storage Cleanup
- [ ] Remove registry volumes
- [ ] Clean up bind mounts
- [ ] Remove shared storage mounts
- [ ] Clean up database files

### Configuration Cleanup
- [ ] Remove configuration directories
- [ ] Clean up SSL certificates
- [ ] Remove authentication files
- [ ] Clean up network configurations

### System Cleanup
- [ ] Remove scheduled jobs
- [ ] Clean up system services
- [ ] Remove custom networks
- [ ] Run docker system prune

### Final Verification
- [ ] Verify no registry containers remain
- [ ] Check for residual configuration files
- [ ] Confirm storage cleanup
- [ ] Validate network cleanup
- [ ] Test that services are inaccessible

---

💡 **Cleanup Success**: Complete removal of all registry components while maintaining the option to restore from backups if needed.