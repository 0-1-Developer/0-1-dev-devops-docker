# Phase 01: Dockerfile Basics - Verification Rules

> **Comprehensive validation of Dockerfile creation skills and best practices**

## 🎯 Verification Overview

These rules validate mastery of Dockerfile fundamentals including syntax, optimization, security practices, and production readiness. All rules must pass to complete Phase 01 successfully.

## ✅ Verification Rules

### Rule 1: Basic Dockerfile Creation
**Anchor**: `p01-basic-creation`  
**Type**: Automated + Manual

**Automated Check**:
```bash
# Create test application
mkdir -p verify-p01 && cd verify-p01
cat > app.js << 'EOF'
const http = require('http');
const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({message: 'Verification app', status: 'running'}));
});
server.listen(3000, () => console.log('Server running on port 3000'));
EOF

cat > package.json << 'EOF'
{
    "name": "verify-app",
    "version": "1.0.0",
    "main": "app.js",
    "scripts": {"start": "node app.js"},
    "dependencies": {}
}
EOF

# Student creates Dockerfile here (manual step)
# Test build success
if docker build -t verify-basic . >/dev/null 2>&1; then
    echo "✅ Basic Dockerfile builds successfully"
else
    echo "❌ Dockerfile build failed"
    exit 1
fi

# Test runtime functionality
docker run -d --name verify-basic-run -p 3001:3000 verify-basic
sleep 2

if curl -s http://localhost:3001 | grep -q "Verification app"; then
    echo "✅ Container runs and serves content"
    BASIC_TEST=passed
else
    echo "❌ Container not responding correctly"
    BASIC_TEST=failed
fi

docker rm -f verify-basic-run
cd .. && rm -rf verify-p01
```

**Manual Assessment**:
- [ ] Dockerfile uses appropriate base image (official, properly tagged)
- [ ] Contains required directives: FROM, WORKDIR, COPY, CMD/ENTRYPOINT
- [ ] Follows basic syntax conventions
- [ ] Image builds without errors or warnings

**Success Criteria**:
- [ ] Image builds successfully
- [ ] Container starts and serves expected content
- [ ] Dockerfile demonstrates understanding of basic directives

---

### Rule 2: Build Optimization & Caching
**Anchor**: `p01-caching-verification`  
**Type**: Automated

**Automated Check**:
```bash
mkdir -p cache-verify && cd cache-verify

# Create test app with dependencies
cat > package.json << 'EOF'
{
    "name": "cache-test",
    "version": "1.0.0",
    "dependencies": {
        "express": "^4.18.0"
    }
}
EOF

cat > app.js << 'EOF'
const express = require('express');
const app = express();
app.get('/', (req, res) => res.json({cache: 'test'}));
app.listen(3000);
EOF

# Student creates optimized Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# First build
echo "First build (cold cache):"
docker build -t cache-test:v1 . 2>&1 | grep -E "(COPY|RUN)" | head -4

# Modify source file (not dependencies)
echo "// Cache test modification" >> app.js

# Second build should show caching
echo "Second build (after source change):"
BUILD_OUTPUT=$(docker build -t cache-test:v2 . 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "CACHED.*package.*json"; then
    echo "✅ Dependencies properly cached"
    CACHE_TEST=passed
else
    echo "❌ Dependencies not cached - check Dockerfile order"
    CACHE_TEST=failed
fi

if echo "$BUILD_OUTPUT" | grep -q "COPY \. \."; then
    echo "✅ Source copy layer correctly rebuilds"
else
    echo "❌ Source copy layer caching issue"
    CACHE_TEST=failed
fi

docker image rm cache-test:v1 cache-test:v2
cd .. && rm -rf cache-verify
```

**Success Criteria**:
- [ ] Dependency installation step shows "CACHED" on source code changes
- [ ] Source copy layer rebuilds when files change
- [ ] Dockerfile follows optimal directive ordering (dependencies before source)

---

### Rule 3: Context Control with .dockerignore
**Anchor**: `p01-context-control`  
**Type**: Manual + Automated

**Automated Setup**:
```bash
mkdir -p context-verify && cd context-verify

# Create project with sensitive and unnecessary files
mkdir -p src tests docs .git node_modules
echo "app code" > src/app.js
echo "test code" > tests/app.test.js
echo "SECRET_KEY=super-secret-123" > .env
echo "password=admin123" > config.secret
echo "# Documentation" > README.md
echo "logs" > app.log
touch .git/config node_modules/package.js

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM alpine:latest
WORKDIR /app
COPY . .
CMD ["find", "/app", "-name", "*secret*", "-o", "-name", ".env*", "-o", "-name", "*.log"]
EOF

echo "Before .dockerignore - files that would be in image:"
docker build -t context-before . >/dev/null 2>&1
docker run --rm context-before 2>/dev/null || true
```

**Manual Assessment**:
Student must create `.dockerignore` file with appropriate patterns.

**Automated Verification**:
```bash
# After student creates .dockerignore
if [ -f .dockerignore ]; then
    echo "✅ .dockerignore file exists"
    
    # Check if sensitive files are properly ignored
    docker build -t context-after . >/dev/null 2>&1
    FOUND_SECRETS=$(docker run --rm context-after 2>/dev/null | wc -l)
    
    if [ "$FOUND_SECRETS" -eq 0 ]; then
        echo "✅ Sensitive files properly excluded"
        CONTEXT_TEST=passed
    else
        echo "❌ Sensitive files found in image: $FOUND_SECRETS"
        docker run --rm context-after
        CONTEXT_TEST=failed
    fi
    
    # Check build context size reduction
    echo "Context files sent to Docker daemon:"
    docker build --progress=plain -t context-final . 2>&1 | grep -E "COPY \. \." -A 5
else
    echo "❌ .dockerignore file not found"
    CONTEXT_TEST=failed
fi

docker image rm context-before context-after context-final 2>/dev/null
cd .. && rm -rf context-verify
```

**Success Criteria**:
- [ ] `.dockerignore` file present with appropriate patterns
- [ ] Sensitive files (`.env`, `*.secret`) excluded from final image
- [ ] Development files (tests, docs, logs) properly ignored
- [ ] Build context size visibly reduced

---

### Rule 4: CMD vs ENTRYPOINT Understanding
**Anchor**: `p01-cmd-entrypoint`  
**Type**: Manual + Automated

**Test Scenario Creation**:
```bash
mkdir -p cmd-entrypoint-verify && cd cmd-entrypoint-verify

# Create test script
cat > test-script.sh << 'EOF'
#!/bin/sh
echo "Script executed with args: $@"
echo "Number of arguments: $#"
exit 0
EOF
chmod +x test-script.sh
```

**Manual Assessment**: Student creates three Dockerfiles:

1. **CMD-only version**:
```dockerfile
FROM alpine:latest
COPY test-script.sh /
CMD ["/test-script.sh", "default"]
```

2. **ENTRYPOINT-only version**:
```dockerfile  
FROM alpine:latest
COPY test-script.sh /
ENTRYPOINT ["/test-script.sh"]
```

3. **ENTRYPOINT + CMD version**:
```dockerfile
FROM alpine:latest
COPY test-script.sh /
ENTRYPOINT ["/test-script.sh"]
CMD ["default"]
```

**Automated Behavioral Testing**:
```bash
# Test CMD-only behavior
docker build -f Dockerfile.cmd -t cmd-test .
echo "CMD-only with default:"
docker run --rm cmd-test

echo "CMD-only with override:"
docker run --rm cmd-test /test-script.sh overridden

# Test ENTRYPOINT-only behavior  
docker build -f Dockerfile.entrypoint -t entrypoint-test .
echo "ENTRYPOINT-only with default:"
docker run --rm entrypoint-test

echo "ENTRYPOINT-only with args:"
docker run --rm entrypoint-test appended args

# Test combined behavior
docker build -f Dockerfile.combined -t combined-test .
echo "Combined with default:"
docker run --rm combined-test

echo "Combined with override:"
docker run --rm combined-test overridden args

docker image rm cmd-test entrypoint-test combined-test
cd .. && rm -rf cmd-entrypoint-verify
```

**Success Criteria**:
- [ ] CMD version allows complete command override
- [ ] ENTRYPOINT version appends arguments to fixed entry point
- [ ] Combined version provides default arguments that can be overridden
- [ ] Can explain when to use each approach

---

### Rule 5: Production Readiness
**Anchor**: `p01-production-ready`  
**Type**: Manual Assessment

**Dockerfile Quality Checklist**:
- [ ] **Base Image**: Uses official, properly tagged base image (not `latest`)
- [ ] **Security**: Runs as non-root user (or acknowledges root requirement)
- [ ] **Size**: Uses appropriate base image size for requirements
- [ ] **Caching**: Optimized layer ordering for build performance
- [ ] **Context**: Includes `.dockerignore` with appropriate patterns
- [ ] **Metadata**: Includes relevant labels or environment variables
- [ ] **Health**: Application exposes health check endpoint (if applicable)
- [ ] **Configuration**: Properly handles environment variables and configuration

**Sample Production-Ready Dockerfile**:
```dockerfile
FROM node:18-alpine@sha256:specific-digest

# Create app directory and user
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files and install dependencies
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

EXPOSE 3000
CMD ["node", "server.js"]
```

**Manual Verification Points**:
- [ ] Student can explain each directive's purpose
- [ ] Demonstrates understanding of security implications
- [ ] Shows awareness of production deployment considerations
- [ ] Can identify and fix common Dockerfile anti-patterns

---

### Rule 6: Comprehensive Knowledge Check
**Anchor**: `p01-knowledge-synthesis`  
**Type**: Manual

**Practical Scenario**: Given a broken/suboptimal Dockerfile, student can identify and fix:

```dockerfile
# BROKEN DOCKERFILE - Student must identify issues
FROM ubuntu:latest
COPY . /app
RUN apt-get update
RUN apt-get install -y python3 python3-pip git curl wget
WORKDIR /app
RUN pip3 install flask requests numpy pandas
COPY requirements.txt .
RUN pip3 install -r requirements.txt
CMD python3 app.py
```

**Expected Issues to Identify**:
- [ ] Using `latest` tag (non-deterministic)
- [ ] Wrong base image choice (ubuntu vs python)
- [ ] Copy order inefficiency (cache busting)
- [ ] Multiple RUN commands (layer bloat)  
- [ ] No cleanup after package installation
- [ ] Missing EXPOSE directive
- [ ] No .dockerignore context control
- [ ] Running as root user
- [ ] Inefficient dependency management

**Corrected Version** (student should produce similar):
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies and clean up in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Copy requirements and install Python dependencies  
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
```

---

## 🔄 Full Verification Script

Complete automated verification sequence:

```bash
#!/bin/bash
echo "=== Phase 01 Dockerfile Basics Verification ==="

TOTAL_TESTS=0
PASSED_TESTS=0

# Rule 1: Basic Creation (automated portion)
echo "Testing Rule 1: Basic Dockerfile Creation..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
# ... (implementation above)

# Rule 2: Caching
echo "Testing Rule 2: Build Optimization..."  
TOTAL_TESTS=$((TOTAL_TESTS + 1))
# ... (implementation above)

# Rule 3: Context Control
echo "Testing Rule 3: .dockerignore Usage..."
TOTAL_TESTS=$((TOTAL_TESTS + 1))
# ... (implementation above)

# Manual assessments reminder
echo ""
echo "=== Manual Verification Required ==="
echo "Please confirm the following skills:"
echo "- [ ] Can explain differences between CMD and ENTRYPOINT"
echo "- [ ] Understands production security implications"  
echo "- [ ] Can identify and fix Dockerfile anti-patterns"
echo "- [ ] Demonstrates build optimization strategies"
echo ""

echo "Automated Tests: $PASSED_TESTS/$TOTAL_TESTS passed"
echo "Complete manual assessments to finish Phase 01 verification."
```

## 📋 Verification Completion Checklist

### Technical Skills Demonstrated
- [ ] Successfully builds custom Docker images
- [ ] Implements effective layer caching strategies
- [ ] Uses `.dockerignore` for context control and security
- [ ] Correctly applies CMD vs ENTRYPOINT based on use case
- [ ] Creates production-ready Dockerfiles with security considerations

### Conceptual Understanding
- [ ] Explains the purpose of each Dockerfile directive
- [ ] Understands build context and its security implications
- [ ] Can predict cache behavior based on Dockerfile structure
- [ ] Knows when to use different base image types (alpine, slim, full)
- [ ] Demonstrates awareness of production deployment considerations

### Best Practices Applied
- [ ] Pins base image versions for reproducibility
- [ ] Orders directives for optimal caching
- [ ] Excludes sensitive and unnecessary files
- [ ] Minimizes final image size appropriately
- [ ] Follows security best practices (non-root users, minimal attack surface)

## 🎯 Success Criteria Summary

**Complete Phase 01 when:**
- [ ] All automated verification tests pass
- [ ] Manual assessment confirms understanding of key concepts
- [ ] Can independently create production-ready Dockerfiles
- [ ] Demonstrates troubleshooting skills with broken Dockerfiles
- [ ] Ready to progress to advanced BuildKit techniques in Phase 02

---

> **Note**: Phase 01 focuses on practical skills that form the foundation for all subsequent Docker development. Ensure solid understanding before advancing to multi-stage builds and advanced BuildKit features.