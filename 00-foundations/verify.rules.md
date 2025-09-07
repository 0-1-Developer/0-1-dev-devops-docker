# Phase 00: Foundations - Verification Rules

> **Automated and manual checks to confirm mastery of Docker fundamentals**

## 🎯 Verification Overview

These rules define what success looks like for Phase 00. Each rule can be checked automatically or manually to confirm understanding.

## ✅ Verification Rules

### Rule 1: Docker Environment Functional
**Anchor**: `p00-env-check`  
**Type**: Automated

```bash
# Check Docker is installed and daemon running
docker --version && docker ps > /dev/null
```

**Success Criteria**:
- [ ] Docker version 20.10+ reported
- [ ] Docker daemon accessible (no connection errors)
- [ ] Command completes without errors

---

### Rule 2: Image vs Container Distinction
**Anchor**: `p00-m01-l01-verify`  
**Type**: Manual + Automated

**Manual Check**:
- [ ] Can explain difference between image and container in own words
- [ ] Can describe what happens when multiple containers run from same image
- [ ] Understands that container changes don't affect the base image

**Automated Check**:
```bash
# This should show the same image used by multiple containers
docker run --name verify-container1 alpine:3.18 echo "test1"
docker run --name verify-container2 alpine:3.18 echo "test2"

# Both should reference the same image
docker inspect verify-container1 verify-container2 --format '{{.Image}}' | sort -u | wc -l
# Expected output: 1 (same image hash)

# Cleanup
docker rm verify-container1 verify-container2
```

**Success Criteria**:
- [ ] Automated check shows both containers use identical image
- [ ] Can verbally distinguish templates (images) from instances (containers)

---

### Rule 3: Container Lifecycle Navigation
**Anchor**: `p00-m01-l02-verify`  
**Type**: Automated

```bash
# Test complete lifecycle transitions
docker create --name lifecycle-test nginx:alpine
docker start lifecycle-test
docker pause lifecycle-test  
docker unpause lifecycle-test
docker stop lifecycle-test
docker start lifecycle-test
docker rm -f lifecycle-test

echo "Lifecycle test completed successfully"
```

**Success Criteria**:
- [ ] All lifecycle commands execute without errors
- [ ] Can predict container state after each command
- [ ] Understands difference between stop and remove

---

### Rule 4: Resource Mapping Comprehension
**Anchor**: `p00-m01-l03-verify`  
**Type**: Automated + Manual

**Automated Check**:
```bash
# Start service with port mapping
docker run -d --name port-verify -p 8899:80 nginx:alpine

# Should be accessible via published port
curl -s http://localhost:8899 | grep -q "nginx" 
PORT_TEST_RESULT=$?

# Should show port mapping
docker port port-verify | grep -q "8899"
MAPPING_TEST_RESULT=$?

# Cleanup
docker rm -f port-verify

# Verify both tests passed
if [ $PORT_TEST_RESULT -eq 0 ] && [ $MAPPING_TEST_RESULT -eq 0 ]; then
    echo "Port mapping verification passed"
else
    echo "Port mapping verification failed"
    exit 1
fi
```

**Manual Check**:
- [ ] Can draw a simple diagram showing host-container port relationship
- [ ] Understands why unpublished ports aren't accessible from host
- [ ] Can explain the difference between container IP and published port access

**Success Criteria**:
- [ ] Automated port accessibility test passes
- [ ] Can diagram host↔container resource boundaries
- [ ] Service accessible via localhost on published port

---

### Rule 5: Reference Format Selection
**Anchor**: `p00-m01-l04-verify`  
**Type**: Manual + Automated

**Manual Check**:
- [ ] Can explain when to use tags vs digests
- [ ] Knows how to get the digest for any image
- [ ] Can choose appropriate format for dev vs prod scenarios

**Automated Check**:
```bash
# Get digest for a tagged image
DIGEST=$(docker image inspect nginx:alpine --format '{{index .RepoDigests 0}}' 2>/dev/null)

if [ ! -z "$DIGEST" ]; then
    echo "Successfully retrieved digest: $DIGEST"
    
    # Both references should point to same image ID
    TAG_ID=$(docker image inspect nginx:alpine --format '{{.Id}}')
    DIGEST_ID=$(docker image inspect "$DIGEST" --format '{{.Id}}')
    
    if [ "$TAG_ID" = "$DIGEST_ID" ]; then
        echo "Tag and digest reference verification passed"
    else
        echo "Tag and digest reference verification failed"
        exit 1
    fi
else
    echo "Could not retrieve image digest"
    exit 1
fi
```

**Success Criteria**:
- [ ] Can retrieve and use digests for precise image references
- [ ] Tag and digest references point to same underlying image
- [ ] Can articulate trade-offs between reference formats

---

### Rule 6: Production Notes Understanding
**Anchor**: `p00-production-notes`  
**Type**: Manual

**Knowledge Check**:
- [ ] Can explain why digest pinning improves reproducibility
- [ ] Understands impact of resource isolation on debugging
- [ ] Knows when container IP access is appropriate vs published ports
- [ ] Can identify scenarios where lifecycle management matters

**Success Criteria**:
- [ ] Demonstrates understanding of production implications
- [ ] Can give examples of when each concept matters in real systems

---

## 🔄 Full Verification Sequence

Run this complete sequence to verify all rules:

```bash
#!/bin/bash
echo "=== Phase 00 Foundations Verification ==="

# Rule 1: Environment check
echo "Checking Docker environment..."
docker --version && docker ps > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Rule 1: Docker environment functional"
else
    echo "❌ Rule 1: Docker environment check failed"
    exit 1
fi

# Rule 2: Image vs Container
echo "Testing image vs container concepts..."
docker run --rm alpine:3.18 echo "Image test passed"
if [ $? -eq 0 ]; then
    echo "✅ Rule 2: Basic image/container operations work"
else
    echo "❌ Rule 2: Image/container test failed"
    exit 1
fi

# Rule 3: Lifecycle
echo "Testing container lifecycle..."
docker create --name lifecycle-verify nginx:alpine > /dev/null
docker start lifecycle-verify > /dev/null
docker stop lifecycle-verify > /dev/null  
docker rm lifecycle-verify > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Rule 3: Container lifecycle navigation successful"
else
    echo "❌ Rule 3: Lifecycle test failed"
    exit 1
fi

# Rule 4: Port mapping
echo "Testing port mapping..."
docker run -d --name port-verify -p 8898:80 nginx:alpine > /dev/null
sleep 2
curl -s http://localhost:8898 > /dev/null
RESULT=$?
docker rm -f port-verify > /dev/null
if [ $RESULT -eq 0 ]; then
    echo "✅ Rule 4: Port mapping verification successful"
else
    echo "❌ Rule 4: Port mapping test failed"
fi

# Rule 5: Reference formats
echo "Testing image reference formats..."
docker pull nginx:alpine > /dev/null 2>&1
DIGEST=$(docker image inspect nginx:alpine --format '{{index .RepoDigests 0}}' 2>/dev/null)
if [ ! -z "$DIGEST" ]; then
    echo "✅ Rule 5: Image reference format understanding confirmed"
else
    echo "❌ Rule 5: Could not work with image references"
fi

echo ""
echo "=== Verification Summary ==="
echo "All automated checks completed."
echo "Manual verification items:"
echo "- [ ] Can explain image vs container difference"
echo "- [ ] Understands container lifecycle states"  
echo "- [ ] Can draw host-container resource boundaries"
echo "- [ ] Knows when to use tags vs digests"
echo "- [ ] Understands production implications"
echo ""
echo "Complete manual checks to finish Phase 00 verification."
```

## 📋 Manual Verification Checklist

Print this checklist and confirm each item:

### Conceptual Understanding
- [ ] **Images vs Containers**: Can explain the template/instance relationship
- [ ] **Immutability**: Understands why images don't change and what this enables
- [ ] **Layers**: Can describe how Docker builds images incrementally  
- [ ] **Lifecycle**: Knows all container states and legal transitions

### Practical Skills
- [ ] **Port Publishing**: Can make container services accessible from host
- [ ] **Resource Inspection**: Can find container IP, port mappings, resource limits
- [ ] **State Management**: Can move containers through lifecycle states safely
- [ ] **Reference Formats**: Can choose tags vs digests appropriately

### Production Readiness
- [ ] **Debugging**: Knows how to inspect running containers
- [ ] **Resource Mapping**: Can predict what's accessible from where
- [ ] **Reproducibility**: Understands digest pinning benefits
- [ ] **Troubleshooting**: Can identify common container startup issues

## 🎯 Success Criteria Summary

**Complete Phase 00 when:**
- [ ] All automated verification rules pass
- [ ] All manual checklist items confirmed
- [ ] Can complete hands-on labs without referring to instructions
- [ ] Ready to progress to building custom images in Phase 01

---

> **Note**: Some verification rules require manual assessment. The goal is understanding, not just passing tests. Take time to ensure you truly grasp each concept before moving forward.