# Phase 07: Docker Security - Cleanup Rules

## Overview
Comprehensive cleanup procedures for Docker security implementations, focusing on secure cleanup practices, credential management, and security audit trail preservation.

## Rule 1: Secure Container and Image Cleanup
**Anchor**: `p07-cleanup-secure-containers`

### Cleanup Commands
```bash
# Secure container cleanup with verification
docker stop $(docker ps -q --filter "label=security-test") 2>/dev/null || echo "No security test containers running"

# Remove test containers with security verification
docker rm $(docker ps -aq --filter "label=security-test") 2>/dev/null || echo "No security test containers to remove"

# Remove security test images with confirmation
for image in nodeapp:secure nodeapp:insecure pyapp:vulnerable pyapp:secure pyapp:distroless pyapp:production fsapp:readonly captest secureapp:hardened; do
    if docker images -q "$image" &> /dev/null; then
        echo "Removing security test image: $image"
        docker rmi "$image" 2>/dev/null || echo "Could not remove $image (may be in use)"
    fi
done
```

### Security-Focused Verification Steps
1. **Container Security State Check**
   ```bash
   # Verify no privileged containers remain
   docker ps --format "table {{.Names}}\t{{.Status}}" --filter="privileged=true" | grep -v NAMES || echo "No privileged containers found"
   
   # Check for containers running as root
   for container in $(docker ps -q); do
       USER_CHECK=$(docker exec "$container" id -u 2>/dev/null || echo "N/A")
       if [[ "$USER_CHECK" == "0" ]]; then
           CONTAINER_NAME=$(docker inspect "$container" --format "{{.Name}}")
           echo "WARNING: Container $CONTAINER_NAME running as root (UID: 0)"
       fi
   done
   ```

2. **Image Security Cleanup Verification**
   ```bash
   # Check for remaining vulnerable images
   docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(vulnerable|insecure|test)" || echo "No vulnerable test images found"
   
   # Verify base image cleanup
   docker system df | grep Images
   ```

3. **Network Security State**
   ```bash
   # Clean security test networks
   docker network ls --format "{{.Name}}" | grep -E "(security|test)" | xargs docker network rm 2>/dev/null || echo "No test networks to remove"
   
   # Verify no bridge networks with security risks
   docker network inspect bridge | jq '.[] | .Options'
   ```

---

## Rule 2: Credential and Secret Cleanup
**Anchor**: `p07-cleanup-credentials`

### Cleanup Commands
```bash
# Clean Docker secrets (if using Swarm mode)
if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
    echo "Cleaning Docker secrets..."
    docker secret ls --format "{{.Name}}" | grep -E "(test|demo|temp)" | xargs docker secret rm 2>/dev/null || echo "No test secrets to remove"
fi

# Clean temporary credential files
find ~/security-lab -name "*.key" -o -name "*.pem" -o -name "*.crt" -delete 2>/dev/null || echo "No credential files to clean"
find ~/image-security-lab -name "cosign.*" -delete 2>/dev/null || echo "No signing keys to clean"

# Remove environment files with secrets
rm -f .env.local .env.staging .env.test .env.backup 2>/dev/null || echo "No environment files to clean"

# Clear Docker Content Trust keys (if enabled)
if [[ -d ~/.docker/trust ]]; then
    echo "Clearing Docker Content Trust keys..."
    rm -rf ~/.docker/trust/private/root_keys
    rm -rf ~/.docker/trust/private/tuf_keys
fi
```

### Credential Security Verification
1. **Secret Detection Scan**
   ```bash
   # Scan for remaining secrets in filesystem
   echo "Scanning for potential secrets..."
   grep -r -E "(password|secret|key|token)" ~/security-lab/ ~/image-security-lab/ 2>/dev/null | grep -v ".git" | head -5 || echo "No secrets detected"
   
   # Check for secrets in Docker environment
   docker ps -q | xargs docker inspect | jq -r '.[] | .Config.Env[]' | grep -i -E "(password|secret|key|token)" || echo "No secrets in container environment"
   ```

2. **Registry Authentication Cleanup**
   ```bash
   # Clean registry credentials
   docker logout 2>/dev/null || echo "No registry sessions to clean"
   
   # Verify credential store cleanup
   if [[ -f ~/.docker/config.json ]]; then
       echo "Docker config file present - checking for stored credentials"
       cat ~/.docker/config.json | jq '.auths // "No stored credentials"'
   fi
   ```

---

## Rule 3: Security Test Environment Reset
**Anchor**: `p07-cleanup-test-environment`

### Cleanup Commands
```bash
# Reset Docker daemon configuration (if modified)
if [[ -f /etc/docker/daemon.json.backup ]]; then
    echo "Restoring Docker daemon configuration..."
    sudo cp /etc/docker/daemon.json.backup /etc/docker/daemon.json
    sudo systemctl restart docker
    sleep 5
fi

# Clean AppArmor profiles (if created)
if [[ -f /etc/apparmor.d/docker-myapp ]]; then
    echo "Removing custom AppArmor profiles..."
    sudo apparmor_parser -R /etc/apparmor.d/docker-myapp 2>/dev/null || echo "AppArmor profile already removed"
    sudo rm -f /etc/apparmor.d/docker-myapp
fi

if [[ -f /etc/apparmor.d/docker-fsapp ]]; then
    sudo apparmor_parser -R /etc/apparmor.d/docker-fsapp 2>/dev/null || echo "AppArmor profile already removed"
    sudo rm -f /etc/apparmor.d/docker-fsapp
fi

# Clean user namespace configuration (if modified)
if grep -q "dockremap" /etc/subuid 2>/dev/null; then
    echo "Cleaning user namespace configuration..."
    sudo sed -i '/dockremap/d' /etc/subuid
    sudo sed -i '/dockremap/d' /etc/subgid
fi
```

### Environment Reset Verification
1. **Docker Daemon State Check**
   ```bash
   # Verify Docker daemon is running normally
   docker info | grep -E "(Server Version|Security Options|Storage Driver)"
   
   # Check daemon configuration
   if [[ -f /etc/docker/daemon.json ]]; then
       echo "Current daemon configuration:"
       cat /etc/docker/daemon.json | jq '.'
   else
       echo "No custom daemon configuration"
   fi
   ```

2. **System Security State**
   ```bash
   # Check AppArmor status
   if command -v aa-status &> /dev/null; then
       echo "AppArmor profiles:"
       sudo aa-status | grep docker || echo "No custom Docker AppArmor profiles"
   fi
   
   # Check user namespace status
   docker info | grep -i userns || echo "User namespace remapping disabled"
   ```

---

## Rule 4: Security Audit Trail Preservation
**Anchor**: `p07-cleanup-audit-preservation`

### Cleanup Commands
```bash
# Create security audit archive before cleanup
AUDIT_DIR="./security-audit-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$AUDIT_DIR"

# Preserve security scan results
if [[ -d ./scan-results ]]; then
    cp -r ./scan-results "$AUDIT_DIR/"
fi

# Preserve security reports
if [[ -f supply-chain-report.sh ]]; then
    ./supply-chain-report.sh > "$AUDIT_DIR/supply-chain-report.txt" 2>&1
fi

# Generate final security assessment
cat > "$AUDIT_DIR/security-assessment.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "system_info": {
    "docker_version": "$(docker --version)",
    "kernel_version": "$(uname -r)",
    "os_version": "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2)"
  },
  "security_tests_completed": [
    "user_management",
    "capabilities_management", 
    "filesystem_security",
    "image_vulnerability_scanning",
    "production_security_monitoring"
  ],
  "cleanup_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Clean temporary files but preserve audit trail
rm -rf ~/security-lab ~/image-security-lab 2>/dev/null || echo "Lab directories already clean"

echo "Security audit trail preserved in: $AUDIT_DIR"
```

### Audit Trail Verification
1. **Audit Archive Validation**
   ```bash
   # Verify audit archive integrity
   if [[ -d ./security-audit-* ]]; then
       AUDIT_DIR=$(ls -d ./security-audit-* | head -1)
       echo "Audit archive: $AUDIT_DIR"
       ls -la "$AUDIT_DIR"
       
       # Verify key audit files
       [[ -f "$AUDIT_DIR/security-assessment.json" ]] && echo "✓ Security assessment preserved"
       [[ -d "$AUDIT_DIR/scan-results" ]] && echo "✓ Scan results preserved" || echo "⚠ No scan results found"
   fi
   ```

2. **Compliance Documentation**
   ```bash
   # Generate compliance summary
   echo "Security Training Completion Summary"
   echo "=================================="
   echo "Date: $(date)"
   echo "User: $(whoami)"
   echo "System: $(hostname)"
   echo ""
   echo "Completed Security Controls:"
   echo "- ✓ Non-root user configuration"
   echo "- ✓ Linux capabilities management"
   echo "- ✓ Read-only filesystem implementation"
   echo "- ✓ Image vulnerability scanning"
   echo "- ✓ Production security monitoring"
   ```

---

## Rule 5: Security Monitoring Cleanup
**Anchor**: `p07-cleanup-security-monitoring`

### Cleanup Commands
```bash
# Stop security monitoring containers
SECURITY_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "(falco|security|monitor)")
if [[ -n "$SECURITY_CONTAINERS" ]]; then
    echo "Stopping security monitoring containers..."
    echo "$SECURITY_CONTAINERS" | xargs docker stop
    echo "$SECURITY_CONTAINERS" | xargs docker rm
fi

# Clean security monitoring volumes
SECURITY_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -E "(security|monitor|falco)")
if [[ -n "$SECURITY_VOLUMES" ]]; then
    echo "Removing security monitoring volumes..."
    echo "$SECURITY_VOLUMES" | xargs docker volume rm 2>/dev/null || echo "Some volumes in use"
fi

# Clean security monitoring networks
SECURITY_NETWORKS=$(docker network ls --format "{{.Name}}" | grep -E "(security|monitor)" | grep -v bridge)
if [[ -n "$SECURITY_NETWORKS" ]]; then
    echo "Removing security monitoring networks..."
    echo "$SECURITY_NETWORKS" | xargs docker network rm 2>/dev/null || echo "Some networks in use"
fi

# Remove Docker Compose security configurations
rm -f docker-compose.security.yml docker-compose.tmpfs.yml 2>/dev/null || echo "No security compose files to clean"
```

### Monitoring Cleanup Verification
1. **Security Service Status**
   ```bash
   # Verify no security monitoring services remain
   docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(falco|security|monitor)" || echo "No security monitoring containers running"
   
   # Check for security-related volumes
   docker volume ls | grep -E "(security|monitor|falco)" || echo "No security monitoring volumes found"
   ```

2. **Log Cleanup Verification**
   ```bash
   # Check for security logs that should be preserved
   if [[ -d /var/log/docker ]]; then
       echo "Docker logs directory exists - checking size:"
       du -sh /var/log/docker
   fi
   
   # Verify audit logs are preserved
   journalctl -u docker --no-pager --since "1 hour ago" | tail -5 || echo "No recent Docker logs"
   ```

---

## Rule 6: Complete System Security Reset
**Anchor**: `p07-cleanup-system-reset`

### Cleanup Commands
```bash
# Complete Docker system cleanup with security focus
echo "Performing complete Docker system security cleanup..."

# Stop all containers
docker stop $(docker ps -aq) 2>/dev/null || echo "No containers to stop"

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null || echo "No containers to remove"

# Remove all custom networks (preserve default networks)
docker network ls --format "{{.Name}}" | grep -v -E "^(bridge|host|none)$" | xargs docker network rm 2>/dev/null || echo "No custom networks to remove"

# Remove all volumes (WARNING: This removes all data)
echo "WARNING: About to remove all Docker volumes"
read -p "Continue with volume cleanup? (y/N): " confirm
if [[ $confirm == [yY] ]]; then
    docker volume rm $(docker volume ls -q) 2>/dev/null || echo "No volumes to remove"
fi

# Remove all images
echo "WARNING: About to remove all Docker images" 
read -p "Continue with image cleanup? (y/N): " confirm
if [[ $confirm == [yY] ]]; then
    docker rmi $(docker images -aq) 2>/dev/null || echo "No images to remove"
fi

# System-wide cleanup
docker system prune -af --volumes

# Reset Docker daemon to defaults (if backup exists)
if [[ -f /etc/docker/daemon.json.original ]]; then
    sudo cp /etc/docker/daemon.json.original /etc/docker/daemon.json
    sudo systemctl restart docker
fi
```

### Complete Reset Verification
1. **System State Verification**
   ```bash
   # Verify clean Docker state
   echo "=== Docker System State After Cleanup ==="
   echo "Containers: $(docker ps -aq | wc -l)"
   echo "Images: $(docker images -q | wc -l)"
   echo "Volumes: $(docker volume ls -q | wc -l)"
   echo "Networks: $(docker network ls --format "{{.Name}}" | grep -v -E "^(bridge|host|none)$" | wc -l)"
   
   # Check system resource usage
   docker system df
   ```

2. **Security Configuration Status**
   ```bash
   # Verify security configurations are reset
   echo "=== Security Configuration Status ==="
   
   # Check Docker daemon configuration
   if [[ -f /etc/docker/daemon.json ]]; then
       echo "Docker daemon config: Present"
       cat /etc/docker/daemon.json | jq '.'
   else
       echo "Docker daemon config: Default (no custom config)"
   fi
   
   # Check AppArmor profiles
   if command -v aa-status &> /dev/null; then
       DOCKER_PROFILES=$(sudo aa-status | grep docker | wc -l)
       echo "Docker AppArmor profiles: $DOCKER_PROFILES"
   fi
   
   # Check user namespace configuration
   USERNS_STATUS=$(docker info | grep -i userns || echo "disabled")
   echo "User namespace: $USERNS_STATUS"
   ```

---

## Emergency Security Cleanup Procedures

### Immediate Security Incident Response
```bash
#!/bin/bash
# emergency-security-cleanup.sh

echo "EMERGENCY SECURITY CLEANUP - IMMEDIATE RESPONSE"
echo "=============================================="

# Stop all containers immediately
docker kill $(docker ps -q) 2>/dev/null
echo "All containers stopped"

# Remove potentially compromised containers
docker rm -f $(docker ps -aq) 2>/dev/null
echo "All containers removed"

# Disconnect from external networks
docker network disconnect bridge $(docker ps -q) 2>/dev/null || echo "Containers already disconnected"

# Check for suspicious processes
echo "Checking for suspicious Docker processes..."
ps aux | grep docker | grep -v grep

# Generate security incident report
cat > security-incident-$(date +%Y%m%d-%H%M%S).log << EOF
SECURITY INCIDENT REPORT
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
System: $(hostname)
User: $(whoami)
Action: Emergency security cleanup executed
Docker Version: $(docker --version)
System Load: $(uptime)
EOF

echo "Emergency cleanup completed - incident report generated"
```

### Recovery Verification
```bash
# Verify system is secure after emergency cleanup
docker info | grep -E "(Security|Storage|Network)"
netstat -tlnp | grep docker || echo "No Docker processes listening"
docker ps -a || echo "No containers present"
```

## Pre-Cleanup Security Checklist

### Data Safety Verification
- [ ] Security audit data backed up
- [ ] Important container configurations documented
- [ ] Credential files identified and secured
- [ ] Custom security policies documented
- [ ] Monitoring data preserved

### System State Documentation
- [ ] Current security configuration captured
- [ ] Running container inventory completed
- [ ] Network topology documented
- [ ] Volume and data mapping recorded
- [ ] User and permission state documented

### Recovery Planning
- [ ] Security configuration restore procedures tested
- [ ] Key personnel notified of cleanup
- [ ] Rollback procedures documented
- [ ] Security monitoring re-deployment plan ready
- [ ] Incident response procedures activated (if needed)

## Post-Cleanup Security Verification

### System Security State
```bash
# Comprehensive post-cleanup security check
echo "=== Post-Cleanup Security Verification ==="

# System resource status
free -h
df -h
docker system df

# Docker daemon status
systemctl status docker
docker version

# Network security status
iptables -L DOCKER-USER 2>/dev/null || echo "DOCKER-USER chain not present"
```

### Security Configuration Validation
```bash
# Validate security configuration is properly reset
docker info | grep -A 5 "Security Options"

# Test basic security functionality
docker run --rm hello-world || echo "Basic Docker functionality test failed"

# Verify no privilege escalation paths remain
docker run --rm alpine:latest id | grep "uid=0" && echo "WARNING: Container running as root" || echo "✓ Non-root execution verified"
```

---

**Note**: Always preserve security audit trails and incident reports for compliance and forensic analysis. Never delete security logs during cleanup procedures unless specifically required by data retention policies.