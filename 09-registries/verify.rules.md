# Phase 09 Verification Rules: Container Registries

> **Purpose**: Validate Docker registry setup, authentication, mirroring, lifecycle management, and enterprise deployment  
> **Scope**: Comprehensive verification of registry infrastructure and operational excellence

## 🔍 Verification Overview

This verification ensures mastery of:
- Private Docker registry deployment and configuration
- Authentication and authorization mechanisms
- Registry mirroring and pull-through caching
- Lifecycle management and automated cleanup
- Enterprise registry solutions (Harbor, Artifactory)
- High availability and clustering configurations

## 📋 Rule 1: Basic Registry Setup

### Verification Criteria
- [ ] Docker Registry 2.x deployed and accessible
- [ ] Registry configured with persistent storage
- [ ] SSL/TLS certificates properly configured
- [ ] Registry health endpoint responding correctly

### Validation Commands
```bash
# Check registry availability
curl -k https://registry.local:5000/v2/

# Verify registry version
curl -k https://registry.local:5000/v2/ | jq .

# Test registry catalog endpoint
curl -k https://registry.local:5000/v2/_catalog

# Check registry health
curl -k https://registry.local:5000/debug/health
```

### Success Indicators
- Registry returns `{"repositories":[]}` for catalog endpoint
- Health endpoint returns status "up"
- SSL certificate valid and trusted
- Registry accepts push/pull operations

### Failure Remediation
```bash
# Check registry container status
docker ps | grep registry

# Inspect registry logs
docker logs registry-container

# Verify registry configuration
docker exec registry-container cat /etc/docker/registry/config.yml

# Test registry connectivity
telnet registry.local 5000
```

## 📋 Rule 2: Authentication and Authorization

### Verification Criteria
- [ ] Basic authentication configured and working
- [ ] Token-based authentication implemented
- [ ] User access controls properly enforced
- [ ] Registry denies unauthorized access

### Validation Commands
```bash
# Test unauthenticated access (should fail)
curl -k https://registry.local:5000/v2/myapp/tags/list

# Test authenticated access
curl -k -u testuser:testpass https://registry.local:5000/v2/_catalog

# Verify token-based auth
TOKEN=$(curl -k -u testuser:testpass "https://auth.registry.local/token?service=registry&scope=repository:myapp:pull" | jq -r .token)
curl -k -H "Authorization: Bearer $TOKEN" https://registry.local:5000/v2/myapp/manifests/latest

# Test push/pull with authentication
docker login registry.local:5000 -u testuser -p testpass
docker tag alpine:latest registry.local:5000/myapp:test
docker push registry.local:5000/myapp:test
```

### Success Indicators
- Unauthenticated requests return HTTP 401
- Valid credentials allow access to authorized resources
- Token-based authentication works correctly
- Push/pull operations succeed with proper credentials

### Failure Remediation
```bash
# Check auth configuration
docker exec registry-container cat /auth/htpasswd

# Verify auth service logs
docker logs auth-service

# Test auth service directly
curl -k https://auth.registry.local/token?service=registry

# Recreate htpasswd file
htpasswd -Bc /auth/htpasswd testuser
```

## 📋 Rule 3: Registry Mirroring and Caching

### Verification Criteria
- [ ] Pull-through cache configured for Docker Hub
- [ ] Mirror registry properly caches images
- [ ] Cache hit ratios are acceptable (>50%)
- [ ] Upstream connectivity failures handled gracefully

### Validation Commands
```bash
# Test pull-through cache functionality
docker pull mirror.registry.local:5000/library/alpine:latest

# Verify cached image exists
curl -k https://mirror.registry.local:5000/v2/library/alpine/tags/list

# Check cache statistics
curl -k https://mirror.registry.local:5000/debug/prometheus | grep registry_http_requests

# Test cache behavior with repeated pulls
time docker pull mirror.registry.local:5000/library/nginx:latest
docker rmi mirror.registry.local:5000/library/nginx:latest
time docker pull mirror.registry.local:5000/library/nginx:latest
```

### Success Indicators
- First pull downloads from upstream and caches locally
- Subsequent pulls are served from cache (faster)
- Cache statistics show proper hit/miss ratios
- Mirror handles upstream failures gracefully

### Failure Remediation
```bash
# Check mirror configuration
docker exec mirror-registry cat /etc/docker/registry/config.yml

# Verify upstream connectivity
curl -I https://registry-1.docker.io/v2/

# Clear cache if corrupted
docker exec mirror-registry rm -rf /var/lib/registry/docker/registry/v2/repositories

# Restart mirror service
docker restart mirror-registry
```

## 📋 Rule 4: Lifecycle Management

### Verification Criteria
- [ ] Automated cleanup policies configured
- [ ] Old image versions properly removed
- [ ] Storage usage monitoring implemented
- [ ] Retention policies enforced correctly

### Validation Commands
```bash
# Upload multiple versions for testing
for i in {1..5}; do
  docker tag alpine:latest registry.local:5000/testapp:v1.$i
  docker push registry.local:5000/testapp:v1.$i
done

# Check current repository state
curl -k https://registry.local:5000/v2/testapp/tags/list

# Run garbage collection
docker exec registry-container registry garbage-collect /etc/docker/registry/config.yml

# Verify cleanup results
curl -k https://registry.local:5000/v2/testapp/tags/list

# Check storage usage
du -sh /var/lib/registry
```

### Success Indicators
- Cleanup policies remove old images according to rules
- Garbage collection reclaims disk space
- Repository maintains only specified number of versions
- Storage usage decreases after cleanup

### Failure Remediation
```bash
# Check cleanup script logs
docker logs cleanup-service

# Manually run garbage collection
docker exec registry-container registry garbage-collect --dry-run /etc/docker/registry/config.yml

# Verify filesystem permissions
ls -la /var/lib/registry

# Restart registry after cleanup
docker restart registry-container
```

## 📋 Rule 5: Enterprise Registry (Harbor)

### Verification Criteria
- [ ] Harbor successfully deployed and accessible
- [ ] Project management and RBAC configured
- [ ] Vulnerability scanning enabled and working
- [ ] Image replication configured between registries

### Validation Commands
```bash
# Check Harbor services status
curl -k https://harbor.local/api/v2.0/systeminfo

# Test Harbor authentication
curl -k -u admin:Harbor12345 https://harbor.local/api/v2.0/projects

# Verify vulnerability scanning
curl -k -u admin:Harbor12345 https://harbor.local/api/v2.0/projects/library/repositories/alpine/artifacts/latest/scan

# Test image replication
curl -k -u admin:Harbor12345 https://harbor.local/api/v2.0/replication/policies

# Push test image to Harbor
docker login harbor.local -u admin -p Harbor12345
docker tag alpine:latest harbor.local/library/alpine:test
docker push harbor.local/library/alpine:test
```

### Success Indicators
- Harbor web UI accessible and functional
- All Harbor services (core, jobservice, registry, portal) running
- Vulnerability scanning completes successfully
- Image replication works between registries

### Failure Remediation
```bash
# Check Harbor service logs
docker-compose -f harbor/docker-compose.yml logs

# Verify Harbor database connectivity
docker exec harbor-db psql -U postgres -d registry -c "\dt"

# Restart Harbor services
cd harbor && docker-compose restart

# Check Harbor configuration
cat harbor/harbor.yml
```

## 📋 Rule 6: High Availability Setup

### Verification Criteria
- [ ] Load balancer distributing registry traffic
- [ ] Multiple registry instances running
- [ ] Shared storage accessible by all instances
- [ ] Failover mechanisms working correctly

### Validation Commands
```bash
# Test load balancer distribution
for i in {1..10}; do
  curl -k https://registry-lb.local:5000/v2/ | grep -o "registry-[0-9]*"
done

# Verify all registry instances
curl -k https://registry-1.local:5000/v2/
curl -k https://registry-2.local:5000/v2/
curl -k https://registry-3.local:5000/v2/

# Test failover by stopping one instance
docker stop registry-1
curl -k https://registry-lb.local:5000/v2/_catalog

# Verify shared storage consistency
docker exec registry-1 ls -la /shared/registry/docker/registry/v2/repositories
docker exec registry-2 ls -la /shared/registry/docker/registry/v2/repositories
```

### Success Indicators
- Load balancer distributes requests across all healthy instances
- Registry remains available when individual instances fail
- All instances show consistent repository catalogs
- Shared storage accessible from all registry nodes

### Failure Remediation
```bash
# Check load balancer configuration
nginx -t && nginx -s reload

# Verify shared storage mounts
mount | grep registry

# Check network connectivity between nodes
ping registry-1.local
ping registry-2.local

# Restart failed registry instances
docker restart registry-1
```

## 🔬 Advanced Verification Scenarios

### Scenario 1: Registry Performance Testing
```bash
#!/bin/bash
echo "🚀 Registry Performance Test"

# Create test images of various sizes
dd if=/dev/zero of=test-10mb bs=1M count=10
dd if=/dev/zero of=test-100mb bs=1M count=100

# Build test images
docker build -t perf-test:small - <<EOF
FROM alpine:3.18
COPY test-10mb /test-file
EOF

docker build -t perf-test:large - <<EOF
FROM alpine:3.18
COPY test-100mb /test-file
EOF

# Performance benchmarks
echo "Small image push performance:"
time docker tag perf-test:small registry.local:5000/perf-test:small
time docker push registry.local:5000/perf-test:small

echo "Large image push performance:"
time docker tag perf-test:large registry.local:5000/perf-test:large
time docker push registry.local:5000/perf-test:large

# Pull performance tests
docker rmi perf-test:small perf-test:large
time docker pull registry.local:5000/perf-test:small
time docker pull registry.local:5000/perf-test:large

echo "✅ Performance test completed"
```

### Scenario 2: Multi-Registry Sync Verification
```bash
#!/bin/bash
echo "🔄 Multi-Registry Sync Test"

registries=("registry-1.local:5000" "registry-2.local:5000" "registry-3.local:5000")

# Push to primary registry
docker tag alpine:latest ${registries[0]}/sync-test:v1.0
docker push ${registries[0]}/sync-test:v1.0

# Wait for replication
sleep 30

# Verify sync across all registries
for registry in "${registries[@]}"; do
  echo "Checking $registry..."
  if curl -k https://$registry/v2/sync-test/tags/list | grep -q "v1.0"; then
    echo "✅ $registry has synced image"
  else
    echo "❌ $registry missing synced image"
  fi
done

echo "🔄 Sync verification completed"
```

### Scenario 3: Disaster Recovery Testing
```bash
#!/bin/bash
echo "🆘 Disaster Recovery Test"

# Backup registry data
tar -czf registry-backup.tar.gz /var/lib/registry/

# Simulate disaster by stopping registry
docker stop registry-container
rm -rf /var/lib/registry/*

# Attempt to access registry (should fail)
curl -k https://registry.local:5000/v2/_catalog

# Restore from backup
tar -xzf registry-backup.tar.gz -C /

# Restart registry
docker start registry-container

# Verify recovery
sleep 10
if curl -k https://registry.local:5000/v2/_catalog | grep -q "repositories"; then
  echo "✅ Disaster recovery successful"
else
  echo "❌ Disaster recovery failed"
fi

echo "🆘 Disaster recovery test completed"
```

## 📊 Verification Results Matrix

| Verification Rule | Status | Score | Notes |
|-------------------|---------|-------|-------|
| **Basic Registry Setup** | ⚪ Pending | 0/15 | Registry deployment and configuration |
| **Authentication** | ⚪ Pending | 0/20 | Auth mechanisms and access control |
| **Mirroring/Caching** | ⚪ Pending | 0/20 | Pull-through cache and performance |
| **Lifecycle Management** | ⚪ Pending | 0/15 | Cleanup policies and storage management |
| **Enterprise Registry** | ⚪ Pending | 0/20 | Harbor deployment and features |
| **High Availability** | ⚪ Pending | 0/10 | HA setup and failover capabilities |
| **Total Score** | ⚪ Pending | 0/100 | Overall verification status |

### Scoring Criteria
- **90-100**: Excellent - Production-ready registry infrastructure
- **80-89**: Good - Minor optimizations needed
- **70-79**: Satisfactory - Some improvements required
- **60-69**: Needs Work - Significant issues to address
- **Below 60**: Unsatisfactory - Major remediation required

## 🔧 Automated Verification Script

### Complete Verification Runner
```bash
#!/bin/bash
# verify-phase09.sh

echo "🔍 Phase 09: Container Registries Verification"
echo "==============================================="

SCORE=0
TOTAL_TESTS=6

# Test 1: Basic Registry Setup (15 points)
echo "Test 1: Basic Registry Setup"
if curl -k -s https://registry.local:5000/v2/ | grep -q "repositories"; then
  echo "✅ Registry accessible and responding"
  SCORE=$((SCORE + 15))
else
  echo "❌ Registry not accessible"
fi

# Test 2: Authentication (20 points)
echo "Test 2: Authentication System"
if curl -k -s https://registry.local:5000/v2/_catalog | grep -q "401"; then
  echo "✅ Authentication properly configured"
  SCORE=$((SCORE + 20))
else
  echo "❌ Authentication not working"
fi

# Test 3: Mirroring/Caching (20 points)
echo "Test 3: Registry Mirroring"
if curl -k -s https://mirror.registry.local:5000/v2/ | grep -q "repositories"; then
  echo "✅ Mirror registry operational"
  SCORE=$((SCORE + 20))
else
  echo "❌ Mirror registry not working"
fi

# Test 4: Lifecycle Management (15 points)
echo "Test 4: Lifecycle Management"
if docker exec registry-container registry garbage-collect --dry-run /etc/docker/registry/config.yml > /dev/null 2>&1; then
  echo "✅ Garbage collection configured"
  SCORE=$((SCORE + 15))
else
  echo "❌ Lifecycle management not configured"
fi

# Test 5: Enterprise Registry (20 points)
echo "Test 5: Enterprise Registry (Harbor)"
if curl -k -s https://harbor.local/api/v2.0/systeminfo | grep -q "harbor_version"; then
  echo "✅ Harbor successfully deployed"
  SCORE=$((SCORE + 20))
else
  echo "❌ Harbor not accessible"
fi

# Test 6: High Availability (10 points)
echo "Test 6: High Availability Setup"
if curl -k -s https://registry-lb.local:5000/v2/ | grep -q "repositories"; then
  echo "✅ Load balanced registry working"
  SCORE=$((SCORE + 10))
else
  echo "❌ HA setup not working"
fi

echo "==============================================="
echo "Final Score: $SCORE/100"

if [ $SCORE -ge 90 ]; then
  echo "🎉 Excellent! Production-ready registry infrastructure"
  exit 0
elif [ $SCORE -ge 70 ]; then
  echo "👍 Good progress, minor improvements needed"
  exit 0
else
  echo "⚠️  Significant improvements required"
  exit 1
fi
```

## 📝 Verification Checklist

### Pre-Verification Setup
- [ ] Docker daemon running and accessible
- [ ] Registry domain names configured in /etc/hosts
- [ ] SSL certificates generated and installed
- [ ] Network connectivity between components verified

### Core Functionality Tests
- [ ] Registry deployment and basic connectivity
- [ ] Authentication and authorization mechanisms
- [ ] Image push/pull operations
- [ ] Registry catalog and tag listing
- [ ] Health and debug endpoints

### Advanced Feature Tests
- [ ] Pull-through cache functionality
- [ ] Image lifecycle and cleanup policies
- [ ] Multi-registry replication
- [ ] Vulnerability scanning integration
- [ ] High availability and load balancing

### Production Readiness
- [ ] Performance benchmarking completed
- [ ] Disaster recovery procedures tested
- [ ] Monitoring and alerting configured
- [ ] Backup and restore procedures validated
- [ ] Documentation and runbooks prepared

---

💡 **Verification Success**: Achieving 80+ points indicates readiness for production registry operations with proper security, performance, and reliability characteristics.