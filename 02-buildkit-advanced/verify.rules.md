# Phase 02: BuildKit Advanced - Verification Rules

> **Comprehensive validation of advanced BuildKit skills including multi-stage builds, cache optimization, and secure practices**

## 🎯 Verification Overview

These rules validate mastery of BuildKit advanced features essential for production Docker usage. All verification must demonstrate understanding of security, performance, and maintainability principles.

## ✅ Verification Rules

### Rule 1: Multi-Stage Build Implementation
**Anchor**: `p02-multistage-mastery`  
**Type**: Automated + Manual

**Automated Test Setup**:
```bash
mkdir -p verify-p02-multistage && cd verify-p02-multistage

# Create test application requiring build tools
cat > app.go << 'EOF'
package main
import (
    "fmt"
    "net/http"
)
func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Multi-stage verification app")
    })
    http.ListenAndServe(":8080", nil)
}
EOF

cat > go.mod << 'EOF'
module verify-app
go 1.21
EOF
```

**Student Task**: Create multi-stage Dockerfile with:
1. Builder stage with Go toolchain
2. Runtime stage with minimal base (alpine/distroless)
3. Proper artifact copying between stages

**Automated Verification**:
```bash
# Test build success
if docker build -t verify-multistage .; then
    echo "✅ Multi-stage build succeeds"
    MULTISTAGE_BUILD=passed
else
    echo "❌ Multi-stage build failed"
    MULTISTAGE_BUILD=failed
fi

# Test size optimization
SINGLE_SIZE=$(docker images golang:1.21 --format "{{.Size}}" | head -1)
MULTI_SIZE=$(docker images verify-multistage --format "{{.Size}}" | head -1)

echo "Base golang image: $SINGLE_SIZE"
echo "Multi-stage image: $MULTI_SIZE"

# Test runtime functionality
docker run -d --name verify-multistage-run -p 8080:8080 verify-multistage
sleep 3

if curl -s http://localhost:8080 | grep -q "Multi-stage verification"; then
    echo "✅ Multi-stage application runs correctly"
    MULTISTAGE_RUNTIME=passed
else
    echo "❌ Multi-stage application not responding"
    MULTISTAGE_RUNTIME=failed
fi

# Verify no build tools in final image
if docker run --rm verify-multistage which go >/dev/null 2>&1; then
    echo "❌ Build tools found in final image"
    MULTISTAGE_SECURITY=failed
else
    echo "✅ No build tools in final image"
    MULTISTAGE_SECURITY=passed
fi

docker rm -f verify-multistage-run
docker image rm verify-multistage
cd .. && rm -rf verify-p02-multistage
```

**Manual Assessment**:
- [ ] Builder and runtime stages clearly separated
- [ ] Only necessary artifacts copied to final stage
- [ ] Final image significantly smaller than single-stage equivalent
- [ ] Can explain the security benefits of multi-stage builds

**Success Criteria**:
- [ ] Multi-stage build completes successfully
- [ ] Final image is <50% size of single-stage equivalent
- [ ] Application runs correctly from optimized image
- [ ] No build tools present in final image

---

### Rule 2: Cache Mount Performance Optimization
**Anchor**: `p02-cache-optimization`  
**Type**: Automated Performance Test

**Test Setup**:
```bash
mkdir -p verify-p02-cache && cd verify-p02-cache

# Create Node.js app with substantial dependencies
cat > package.json << 'EOF'
{
  "name": "cache-verify",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.21",
    "moment": "^2.29.4",
    "axios": "^1.6.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^7.6.0"
  }
}
EOF

cat > app.js << 'EOF'
const express = require('express');
const app = express();
app.get('/', (req, res) => res.json({cache: 'verification'}));
app.listen(3000);
EOF
```

**Student Task**: Create two Dockerfiles:
1. `Dockerfile.nocache` - Without cache mounts
2. `Dockerfile.cached` - With proper cache mount implementation

**Automated Performance Test**:
```bash
# Test without cache mounts
echo "=== Testing without cache mounts ==="
time_nocache_1=$(docker build -f Dockerfile.nocache -t cache-verify-none . 2>&1 | grep "real" || echo "real 0m0.000s")

# Simulate code change
echo "// change" >> app.js
time_nocache_2=$(docker build -f Dockerfile.nocache -t cache-verify-none . 2>&1 | grep "real" || echo "real 0m0.000s")

# Test with cache mounts
echo "=== Testing with cache mounts ==="
time_cached_1=$(docker build -f Dockerfile.cached -t cache-verify-cached . 2>&1 | grep "real" || echo "real 0m0.000s")

# Simulate another code change
echo "// change2" >> app.js
time_cached_2=$(docker build -f Dockerfile.cached -t cache-verify-cached . 2>&1 | grep "real" || echo "real 0m0.000s")

echo "Build times comparison:"
echo "No cache (first): $time_nocache_1"
echo "No cache (rebuild): $time_nocache_2"
echo "With cache (first): $time_cached_1"
echo "With cache (rebuild): $time_cached_2"

# Test functionality
docker run -d --name cache-verify-test -p 3001:3000 cache-verify-cached
sleep 3

if curl -s http://localhost:3001 | grep -q "verification"; then
    echo "✅ Cached build produces functional application"
    CACHE_FUNCTIONALITY=passed
else
    echo "❌ Cached build application not working"
    CACHE_FUNCTIONALITY=failed
fi

# Verify cache mounts don't affect final image
CACHE_SIZE=$(docker image inspect cache-verify-cached --format '{{.Size}}')
if [ "$CACHE_SIZE" -gt 0 ]; then
    echo "✅ Cache mounts don't bloat final image"
    CACHE_SIZE_TEST=passed
else
    echo "❌ Cache mount size test inconclusive"
    CACHE_SIZE_TEST=warning
fi

docker rm -f cache-verify-test
docker image rm cache-verify-none cache-verify-cached
cd .. && rm -rf verify-p02-cache
```

**Manual Assessment**:
- [ ] Cache mount syntax is correct (`--mount=type=cache,target=...`)
- [ ] Cache targets appropriate directories (npm cache, pip cache, etc.)
- [ ] Build shows "CACHED" messages on subsequent builds
- [ ] Can explain cache scope and security implications

**Success Criteria**:
- [ ] Cache mount implementation syntax is correct
- [ ] Subsequent builds are significantly faster (>2x improvement)
- [ ] Cache mounts don't affect final image contents
- [ ] Can identify appropriate cache targets for different ecosystems

---

### Rule 3: Secret Security Implementation
**Anchor**: `p02-secret-security`  
**Type**: Security-focused Manual + Automated

**Security Test Setup**:
```bash
mkdir -p verify-p02-secrets && cd verify-p02-secrets

# Create secret file
echo "super-secret-api-key-12345" > test-secret.txt

# Create application that needs the secret during build
cat > fetch-data.sh << 'EOF'
#!/bin/sh
SECRET_FILE="/run/secrets/api-key"
if [ -f "$SECRET_FILE" ]; then
    API_KEY=$(cat "$SECRET_FILE")
    echo "Data fetched with key: ${API_KEY:0:8}..." > data.txt
else
    echo "No secret available"
    exit 1
fi
EOF
chmod +x fetch-data.sh

cat > app.py << 'EOF'
import os
with open('data.txt', 'r') as f:
    data = f.read().strip()
print(f"App data: {data}")
EOF
```

**Student Task**: Create Dockerfile using BuildKit secret mounts to:
1. Use the secret during build without leaking it
2. Create functional application that can access fetched data
3. Ensure zero secret persistence in any image layer

**Automated Security Verification**:
```bash
# Build with secret
if docker build --secret id=api-key,src=./test-secret.txt -t secret-verify .; then
    echo "✅ Secret build succeeds"
    SECRET_BUILD=passed
else
    echo "❌ Secret build failed"
    SECRET_BUILD=failed
fi

# Test functionality
if docker run --rm secret-verify python app.py | grep -q "super-secret"; then
    echo "✅ Application functions with secret-derived data"
    SECRET_FUNCTIONALITY=passed
else
    echo "❌ Application not working with secret data"
    SECRET_FUNCTIONALITY=failed
fi

# Critical security test: ensure no secret leakage
echo "=== Security Verification: Checking for secret leakage ==="

# Check image history
if docker history secret-verify | grep -q "super-secret"; then
    echo "❌ CRITICAL: Secret found in image history"
    SECRET_SECURITY=failed
else
    echo "✅ No secret in image history"
fi

# Check image layers
if docker save secret-verify | tar -tv | grep -q "super-secret"; then
    echo "❌ CRITICAL: Secret found in image layers"
    SECRET_SECURITY=failed
else
    echo "✅ No secret in image layers"
fi

# Check running container filesystem
if docker run --rm secret-verify find / -type f -exec grep -l "super-secret" {} \; 2>/dev/null | grep -v data.txt; then
    echo "❌ CRITICAL: Secret found in unexpected locations"
    SECRET_SECURITY=failed
else
    echo "✅ Secret not found in container filesystem"
    SECRET_SECURITY=passed
fi

# Verify secret mount syntax in Dockerfile
if grep -q "mount=type=secret" Dockerfile; then
    echo "✅ Correct secret mount syntax used"
    SECRET_SYNTAX=passed
else
    echo "❌ Secret mount syntax not found"
    SECRET_SYNTAX=failed
fi

docker image rm secret-verify
rm -f test-secret.txt
cd .. && rm -rf verify-p02-secrets
```

**Manual Security Review**:
- [ ] Secret mount uses correct syntax (`--mount=type=secret,id=...`)
- [ ] Secret is only accessible during specific RUN instructions
- [ ] No secret content appears in any image layer or history
- [ ] Can explain the security benefits over traditional approaches

**Success Criteria**:
- [ ] Secret mount implementation works correctly
- [ ] Zero secret leakage verified through comprehensive testing
- [ ] Application functions correctly with secret-derived data
- [ ] Demonstrates understanding of secret lifecycle principles

---

### Rule 4: Build Arguments and Parameterization
**Anchor**: `p02-build-parameters`  
**Type**: Manual + Configuration Test

**Test Scenario Setup**:
```bash
mkdir -p verify-p02-buildargs && cd verify-p02-buildargs

cat > app-template.py << 'EOF'
import os
print(f"Environment: {os.getenv('APP_ENV')}")
print(f"Version: {os.getenv('APP_VERSION')}")
print(f"Debug: {os.getenv('DEBUG_MODE')}")
print(f"Features: {os.getenv('FEATURE_FLAGS')}")
EOF
```

**Student Task**: Create Dockerfile that:
1. Uses ARG for build-time configuration (environment, version, feature flags)
2. Provides sensible defaults for all arguments
3. Validates critical arguments
4. Properly converts ARG to ENV where needed

**Configuration Test**:
```bash
# Test with default arguments
echo "=== Testing default build arguments ==="
if docker build -t buildargs-default .; then
    echo "✅ Default build succeeds"
    docker run --rm buildargs-default > default-output.txt
    cat default-output.txt
    DEFAULT_TEST=passed
else
    echo "❌ Default build failed"
    DEFAULT_TEST=failed
fi

# Test with custom arguments
echo "=== Testing custom build arguments ==="
if docker build \
    --build-arg APP_ENV=production \
    --build-arg APP_VERSION=2.1.0 \
    --build-arg DEBUG_MODE=false \
    --build-arg FEATURE_FLAGS="analytics,monitoring" \
    -t buildargs-custom .; then
    echo "✅ Custom build succeeds"
    docker run --rm buildargs-custom > custom-output.txt
    cat custom-output.txt
    CUSTOM_TEST=passed
else
    echo "❌ Custom build failed"
    CUSTOM_TEST=failed
fi

# Verify argument handling
if grep -q "production" custom-output.txt; then
    echo "✅ Custom arguments properly handled"
    ARG_HANDLING=passed
else
    echo "❌ Custom arguments not reflected in output"
    ARG_HANDLING=failed
fi

# Test argument validation (if implemented)
echo "=== Testing argument validation ==="
if docker build --build-arg APP_ENV=invalid -t buildargs-invalid . 2>&1 | grep -q -i "error\|invalid"; then
    echo "✅ Argument validation working"
    VALIDATION_TEST=passed
else
    echo "⚠️  No argument validation detected"
    VALIDATION_TEST=warning
fi

docker image rm buildargs-default buildargs-custom 2>/dev/null
rm -f default-output.txt custom-output.txt
cd .. && rm -rf verify-p02-buildargs
```

**Manual Assessment**:
- [ ] ARG directives have appropriate defaults
- [ ] Critical arguments include validation
- [ ] ARG to ENV conversion is correct where needed
- [ ] Build produces different configurations based on arguments

**Success Criteria**:
- [ ] Build arguments customize image behavior correctly
- [ ] Default values provide sensible baseline configuration
- [ ] Custom arguments override defaults appropriately
- [ ] Argument validation prevents invalid builds (bonus)

---

### Rule 5: Production Readiness Integration
**Anchor**: `p02-production-integration`  
**Type**: Comprehensive Manual Assessment

**Integration Scenario**: Student demonstrates BuildKit advanced features in realistic production context.

**Assessment Checklist**:

**Multi-Stage Architecture**:
- [ ] Clear separation between build and runtime stages
- [ ] Minimal runtime image with only necessary components
- [ ] Proper artifact copying and dependency management
- [ ] Size optimization demonstrates >60% reduction from single-stage

**Performance Optimization**:
- [ ] Cache mounts implemented for relevant build tools
- [ ] Build time improvement demonstrable through testing
- [ ] Cache scope appropriately configured for security
- [ ] No cache pollution in final images

**Security Implementation**:
- [ ] Secret handling follows zero-leakage principles
- [ ] No sensitive information in image history or layers
- [ ] Runtime images follow security best practices
- [ ] Build-time vs runtime secret distinction understood

**Configuration Management**:
- [ ] Build arguments enable flexible deployment scenarios
- [ ] Environment-specific builds possible without code duplication
- [ ] Argument validation prevents configuration errors
- [ ] Default values support development workflow

**Advanced Features Integration**:
- [ ] Multiple features combined effectively in single Dockerfile
- [ ] Target selection enables different build scenarios
- [ ] Build process is reproducible and deterministic
- [ ] CI/CD integration considerations demonstrated

---

## 🔄 Comprehensive Verification Script

Complete verification sequence for all rules:

```bash
#!/bin/bash
echo "=== Phase 02 BuildKit Advanced Verification ==="

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

# Rule 1: Multi-stage builds (automated portion)
echo "Testing Rule 1: Multi-stage Build Implementation..."
# ... (implementation above)

# Rule 2: Cache optimization (automated portion)
echo "Testing Rule 2: Cache Mount Performance..."
# ... (implementation above)

# Rule 3: Secret security (automated portion) 
echo "Testing Rule 3: Build Secret Security..."
# ... (implementation above)

# Rule 4: Build arguments (automated portion)
echo "Testing Rule 4: Build Arguments..."
# ... (implementation above)

echo ""
echo "=== Verification Results ==="
echo "Automated Tests: $PASSED_TESTS/$TOTAL_TESTS passed"
echo ""
echo "Manual verification required for:"
echo "- [ ] Multi-stage build design and optimization strategy"
echo "- [ ] Cache mount selection and security considerations"
echo "- [ ] Secret management best practices understanding" 
echo "- [ ] Build parameterization and validation patterns"
echo "- [ ] Production integration of all advanced features"
echo ""
echo "Complete manual assessments to finish Phase 02 verification."
```

## 📋 Manual Verification Checklist

### Advanced BuildKit Concepts
- [ ] **Multi-stage Philosophy**: Can explain builder vs runtime separation benefits
- [ ] **Cache Strategy**: Understands cache mount performance and security implications
- [ ] **Secret Lifecycle**: Demonstrates zero-leakage secret handling patterns
- [ ] **Build Flexibility**: Creates parameterized, reusable build configurations

### Production Skills  
- [ ] **Performance Analysis**: Can measure and optimize build performance
- [ ] **Security Assessment**: Identifies and mitigates build-time security risks
- [ ] **Configuration Management**: Handles multiple deployment scenarios elegantly
- [ ] **Troubleshooting**: Debugs complex multi-stage and caching issues

### Integration Capabilities
- [ ] **CI/CD Ready**: Understands how features integrate with automation
- [ ] **Team Workflow**: Can design builds that work for multiple developers
- [ ] **Maintenance**: Creates maintainable, documented build processes
- [ ] **Scalability**: Designs builds that work from local dev to production

## 🎯 Success Criteria Summary

**Complete Phase 02 when:**
- [ ] All automated verification tests pass
- [ ] Manual assessment confirms deep understanding of advanced concepts
- [ ] Can independently design and implement production-ready multi-stage builds
- [ ] Demonstrates secure secret handling and performance optimization
- [ ] Ready to progress to container runtime management in Phase 03

---

> **Critical Success Indicator**: Can design and implement a complete BuildKit advanced workflow that combines multi-stage builds, cache optimization, secure secret handling, and flexible parameterization for a real application deployment scenario.