# Phase 01: Dockerfile Basics - Hands-On Labs

> **Build your first custom Docker images with optimized, production-ready Dockerfiles**

## 🎯 Lab Overview

These labs will guide you through creating efficient, secure, and maintainable Dockerfiles. You'll progress from simple single-file applications to more complex scenarios requiring optimization.

**Total Lab Time**: ~120 minutes  
**Difficulty**: Beginner to Intermediate  
**Prerequisites**: Phase 00 completed, Docker installed with BuildKit enabled

## 🚀 Lab Setup

Verify your environment and create workspace:

```bash
# Check Docker and BuildKit
docker version --format '{{.Server.Version}}'
# Should be 20.10+ for full BuildKit support

# Create lab workspace
mkdir -p dockerfile-labs && cd dockerfile-labs

# Verify BuildKit is enabled (should show buildx as default builder)
docker builder ls
```

---

## 🧪 Lab 1: Base Image Selection & First Dockerfile
**Time**: 25 minutes  
**Anchor**: `p01-m01-l01`

### Why It Matters
Base image choice affects security, size, performance, and maintainability. Learning to evaluate and select appropriate base images is fundamental to effective containerization.

### What You'll Learn
- How to evaluate different base image options
- The impact of base image choice on final image size
- Creating your first functional Dockerfile
- Understanding the FROM directive and image inheritance

### Try It

**Step 1: Compare Base Image Options**
```bash
# Pull different variants of the same base image
docker pull node:18-alpine
docker pull node:18-slim  
docker pull node:18

# Compare their sizes
docker image ls node --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Record the size differences:
# alpine: _____ MB
# slim: _____ MB  
# full: _____ MB
```

**Step 2: Create a Simple Node.js Application**
```bash
# Create app directory
mkdir simple-node-app && cd simple-node-app

# Create package.json
cat > package.json << 'EOF'
{
  "name": "dockerfile-lab-app",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.0"
  },
  "scripts": {
    "start": "node server.js"
  }
}
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({
        message: 'Hello from Dockerfile Lab!',
        timestamp: new Date().toISOString(),
        version: process.env.APP_VERSION || 'unknown'
    });
});

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
EOF
```

**Step 3: Create Your First Dockerfile**
```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Set environment variable
ENV APP_VERSION=1.0.0

# Expose port (documentation only)
EXPOSE 3000

# Define default command
CMD ["npm", "start"]
EOF
```

**Step 4: Build and Test Your First Image**
```bash
# Build the image
docker build -t my-node-app:v1 .

# Check the final image size
docker image ls my-node-app:v1

# Run and test the container
docker run -d --name lab1-app -p 3000:3000 my-node-app:v1

# Test the application
curl http://localhost:3000
curl http://localhost:3000/health

# Check the logs
docker logs lab1-app

# Clean up
docker rm -f lab1-app
cd ..
```

### Verify It
- [ ] Successfully built image without errors
- [ ] Application responds correctly on both endpoints
- [ ] Can explain why alpine base was chosen over full node image
- [ ] Understand each directive's purpose in the Dockerfile

---

## 🧪 Lab 2: Build Optimization & Caching Strategy
**Time**: 30 minutes  
**Anchor**: `p01-m01-l02`

### Why It Matters
Poor layer ordering can make builds unnecessarily slow. Understanding Docker's layer caching mechanism is crucial for efficient development workflows.

### What You'll Learn
- How Docker layer caching works
- Optimal ordering of Dockerfile directives
- Techniques to maximize cache reuse
- Measuring build performance improvements

### Try It

**Step 1: Create Sub-optimal Dockerfile (Cache-Busting)**
```bash
mkdir cache-demo && cd cache-demo

# Copy the same app files from Lab 1
cp ../simple-node-app/package.json .
cp ../simple-node-app/server.js .

# Create inefficient Dockerfile
cat > Dockerfile.bad << 'EOF'
FROM node:18-alpine

# Bad: Copy everything first (invalidates cache on any file change)
COPY . /app
WORKDIR /app

# This will run every time ANY file changes
RUN npm install

EXPOSE 3000
CMD ["npm", "start"]
EOF
```

**Step 2: Build and Measure Performance**
```bash
# First build (cold cache)
time docker build -f Dockerfile.bad -t cache-demo:bad .

# Make a trivial change to server.js
echo "// Added comment" >> server.js

# Second build - should reinstall all dependencies
time docker build -f Dockerfile.bad -t cache-demo:bad .
# Note: npm install runs again even though package.json didn't change
```

**Step 3: Create Optimized Dockerfile**
```bash
cat > Dockerfile.good << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Good: Copy dependency files first
COPY package*.json ./

# Install dependencies (cached unless package.json changes)
RUN npm install --only=production && \
    npm cache clean --force

# Copy source code last (most frequently changed)
COPY . .

EXPOSE 3000
CMD ["npm", "start"]
EOF
```

**Step 4: Compare Build Performance**
```bash
# Clean up previous builds
docker image rm cache-demo:bad

# Build optimized version
time docker build -f Dockerfile.good -t cache-demo:good .

# Make the same trivial change
echo "// Another comment" >> server.js

# Rebuild - should use cache for npm install
time docker build -f Dockerfile.good -t cache-demo:good .
# Note: "Using cache" for npm install step
```

**Step 5: Cache Analysis Exercise**
```bash
# Build with --progress=plain to see cache usage
docker build --progress=plain -f Dockerfile.good -t cache-demo:analysis .

# Expected output should show:
# CACHED [X/Y] COPY package*.json ./
# CACHED [X/Y] RUN npm install...
# [X/Y] COPY . .  (not cached - this layer changed)
```

### Verify It
- [ ] Optimized Dockerfile builds significantly faster on code changes
- [ ] Can identify which layers are cached vs rebuilt
- [ ] Understand the dependency → code copy ordering principle
- [ ] Can predict cache behavior for different file modifications

---

## 🧪 Lab 3: Context Control with .dockerignore
**Time**: 25 minutes  
**Anchor**: `p01-m01-l03`

### Why It Matters
Build context size affects build speed and security. Accidentally including sensitive files or unnecessary data is a common production issue.

### What You'll Learn
- How build context affects Docker builds
- Creating effective `.dockerignore` patterns
- Security implications of context control
- Performance impact of context optimization

### Try It

**Step 1: Demonstrate Context Bloat Problem**
```bash
mkdir context-demo && cd context-demo

# Create a realistic project structure with bloat
mkdir -p src tests docs node_modules .git logs

# Simulate various file types
echo "app code" > src/app.js
echo "# Documentation" > docs/README.md  
echo "test code" > tests/app.test.js
echo "secret-key-123" > .env
echo "password=admin123" > config.secret
touch logs/app.log logs/error.log
echo "fake node modules" > node_modules/fake-package.js
echo "git data" > .git/config

# Create large fake files to simulate real bloat
dd if=/dev/zero of=large-dataset.csv bs=1M count=10 2>/dev/null
dd if=/dev/zero of=node_modules/big-package.bin bs=1M count=5 2>/dev/null

# Show current directory size
du -sh .
```

**Step 2: Build Without .dockerignore**
```bash
cat > Dockerfile << 'EOF'
FROM alpine:latest
WORKDIR /app
COPY . .
CMD ["ls", "-la"]
EOF

# Build and note the context size warning
docker build -t context-demo:bloated . 2>&1 | head -5

# Check what ended up in the image
docker run --rm context-demo:bloated
```

**Step 3: Create Comprehensive .dockerignore**
```bash
cat > .dockerignore << 'EOF'
# Dependencies and build artifacts
node_modules/
npm-debug.log
dist/
build/
target/
*.log

# Development and testing
tests/
__tests__/
*.test.js
coverage/
.nyc_output/

# Documentation  
docs/
README.md
*.md

# Version control
.git/
.gitignore
.gitattributes

# Environment and secrets
.env*
*.secret
config.secret
secrets/

# OS and editor files
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# Large data files
*.csv
*.json.bak
*.sql
dataset*/
logs/
*.bin
EOF
```

**Step 4: Build with Context Control**
```bash
# Build with .dockerignore
docker build -t context-demo:clean .

# Compare what's in the final image
docker run --rm context-demo:clean
# Should be much cleaner - no secrets, logs, or large files

# Check build context size difference
echo "=== Build context analysis ==="
echo "Files without .dockerignore:"
find . -type f | wc -l

echo "Files that would be sent with .dockerignore:"
# Simulate what Docker sees with .dockerignore  
tar --exclude-from=.dockerignore -cf - . | tar -tf - | wc -l
```

**Step 5: Security Verification**
```bash
# Verify secrets didn't make it into the image
docker run --rm context-demo:clean find /app -name "*.secret" -o -name ".env*"
# Should return nothing

# Verify large files were excluded
docker image ls context-demo --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
# clean should be significantly smaller than bloated

cd ..
```

### Verify It
- [ ] `.dockerignore` significantly reduced build context size
- [ ] Sensitive files (secrets, .env) were excluded from final image
- [ ] Build performance improved with smaller context
- [ ] Can create effective ignore patterns for different project types

---

## 🧪 Lab 4: CMD vs ENTRYPOINT Mastery
**Time**: 30 minutes  
**Anchor**: `p01-m01-l04`

### Why It Matters
Choosing the wrong execution method leads to containers that don't behave as expected. Understanding when to use CMD vs ENTRYPOINT is crucial for creating flexible, reusable images.

### What You'll Learn
- Functional differences between CMD and ENTRYPOINT
- How argument handling differs between approaches
- When to use each approach based on use case
- Combining ENTRYPOINT and CMD effectively

### Try It

**Step 1: CMD Behavior Analysis**
```bash
mkdir cmd-vs-entrypoint && cd cmd-vs-entrypoint

# Create script that shows arguments
cat > show-args.sh << 'EOF'
#!/bin/sh
echo "Script: $0"
echo "Arguments received: $@"
echo "Number of arguments: $#"
echo "Process ID: $$"
echo "Current time: $(date)"

# Show environment
echo "Environment variables:"
env | grep -E '^(PATH|USER|HOME)=' | sort
EOF

chmod +x show-args.sh
```

**Step 2: Test CMD Only**
```bash
cat > Dockerfile.cmd << 'EOF'
FROM alpine:latest
WORKDIR /app
COPY show-args.sh .
CMD ["./show-args.sh", "default", "args"]
EOF

# Build and test default behavior
docker build -f Dockerfile.cmd -t cmd-demo .
docker run --rm cmd-demo

# Test command override (CMD gets completely replaced)
docker run --rm cmd-demo echo "I replaced the CMD completely"
docker run --rm cmd-demo ./show-args.sh custom arguments here
```

**Step 3: Test ENTRYPOINT Only**
```bash
cat > Dockerfile.entrypoint << 'EOF'
FROM alpine:latest
WORKDIR /app
COPY show-args.sh .
ENTRYPOINT ["./show-args.sh"]
EOF

# Build and test
docker build -f Dockerfile.entrypoint -t entrypoint-demo .
docker run --rm entrypoint-demo

# Test with additional arguments (appended to ENTRYPOINT)
docker run --rm entrypoint-demo these args are appended
docker run --rm entrypoint-demo --flag1 --flag2 value

# Try to override (won't work as expected)
docker run --rm entrypoint-demo echo "This becomes an argument"
```

**Step 4: Test ENTRYPOINT + CMD Combination**
```bash
cat > Dockerfile.combined << 'EOF'
FROM alpine:latest
WORKDIR /app
COPY show-args.sh .
ENTRYPOINT ["./show-args.sh"]
CMD ["default", "arguments"]
EOF

# Build and test
docker build -f Dockerfile.combined -t combined-demo .

# Default behavior (ENTRYPOINT + CMD)
docker run --rm combined-demo

# Override CMD arguments
docker run --rm combined-demo custom override arguments

# Show how this differs from CMD-only
echo "=== Comparison ==="
echo "CMD-only with override:"
docker run --rm cmd-demo ./show-args.sh overridden

echo "ENTRYPOINT+CMD with override:"  
docker run --rm combined-demo overridden
```

**Step 5: Real-world Application Example**
```bash
# Create a configurable web server example
cat > web-server.sh << 'EOF'
#!/bin/sh

# Default values
PORT=8080
MESSAGE="Hello from configurable server!"

# Parse arguments
while [ $# -gt 0 ]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --message)
            MESSAGE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--port PORT] [--message MESSAGE]"
            exit 1
            ;;
    esac
done

echo "Starting server on port $PORT with message: $MESSAGE"

# Simple HTTP server using netcat
while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Length: ${#MESSAGE}\r\n\r\n$MESSAGE" | nc -l -p $PORT -q 1
done
EOF

chmod +x web-server.sh

cat > Dockerfile.webapp << 'EOF'
FROM alpine:latest
RUN apk add --no-cache netcat-openbsd
WORKDIR /app
COPY web-server.sh .
EXPOSE 8080
ENTRYPOINT ["./web-server.sh"]
CMD ["--port", "8080", "--message", "Default message!"]
EOF

# Build and test flexibility
docker build -f Dockerfile.webapp -t webapp-demo .

# Test default behavior
docker run -d --name webapp1 -p 8081:8080 webapp-demo
sleep 2
curl http://localhost:8081
docker rm -f webapp1

# Test custom configuration
docker run -d --name webapp2 -p 8082:9000 webapp-demo --port 9000 --message "Custom message!"
sleep 2
curl http://localhost:8082
docker rm -f webapp2
```

### Verify It
- [ ] Understand how CMD gets completely replaced by docker run arguments
- [ ] Know that ENTRYPOINT arguments get appended to, not replaced
- [ ] Can choose the right approach based on container's intended use
- [ ] Successfully built a configurable application using ENTRYPOINT+CMD

---

## 🧪 Lab 5: Build Determinism & Size Optimization
**Time**: 30 minutes  
**Anchor**: `p01-bonus`

### Why It Matters
Non-deterministic builds cause deployment inconsistencies. Large images slow down deployment and increase attack surface.

### What You'll Learn
- Techniques for creating reproducible builds
- Image size optimization strategies
- How to avoid common non-determinism sources
- Multi-command RUN optimization

### Try It

**Step 1: Create Size-Optimized Python Application**
```bash
mkdir optimization-demo && cd optimization-demo

cat > requirements.txt << 'EOF'
flask==2.3.2
gunicorn==21.2.0
requests==2.31.0
EOF

cat > app.py << 'EOF'
from flask import Flask, jsonify
import requests
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Optimized Flask app',
        'version': os.environ.get('APP_VERSION', 'unknown')
    })

@app.route('/external')
def external():
    # Demo external API call capability
    try:
        resp = requests.get('https://httpbin.org/json', timeout=5)
        return jsonify(resp.json())
    except:
        return jsonify({'error': 'External service unavailable'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
EOF
```

**Step 2: Create Naive Dockerfile (Non-optimized)**
```bash
cat > Dockerfile.naive << 'EOF'
FROM python:3.11

# Install system dependencies (creates large layer)
RUN apt-get update
RUN apt-get install -y curl wget git build-essential
RUN apt-get install -y python3-dev

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . /app
WORKDIR /app

EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Build naive version
docker build -f Dockerfile.naive -t flask-app:naive .
```

**Step 3: Create Optimized Dockerfile**
```bash
cat > Dockerfile.optimized << 'EOF'
FROM python:3.11-slim

# Install system dependencies in single layer with cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        build-essential \
        python3-dev && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Set working directory
WORKDIR /app

# Install Python dependencies (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    pip uninstall -y pip setuptools

# Copy application (changes frequently)
COPY app.py .

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Build optimized version
docker build -f Dockerfile.optimized -t flask-app:optimized .
```

**Step 4: Size Comparison & Analysis**
```bash
# Compare image sizes
docker image ls flask-app --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Analyze layer composition
echo "=== Naive version layers ==="
docker history flask-app:naive --format "table {{.CreatedBy}}\t{{.Size}}"

echo "=== Optimized version layers ==="
docker history flask-app:optimized --format "table {{.CreatedBy}}\t{{.Size}}"

# Test both versions work
docker run -d --name naive-app -p 5001:5000 flask-app:naive
docker run -d --name optimized-app -p 5002:5000 flask-app:optimized

sleep 3

curl http://localhost:5001/
curl http://localhost:5002/

docker rm -f naive-app optimized-app
```

**Step 5: Deterministic Build Verification**
```bash
# Create Dockerfile with deterministic elements
cat > Dockerfile.deterministic << 'EOF'
FROM python:3.11-slim@sha256:2455c7b7b892e6f4fe7b99b4b85d42c6c7b2f5e3a9f9b6f6f1b0b2f3f4f5f6f7

# Pin package versions and use specific dates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl=7.88.1-10+deb12u4 \
        build-essential=12.9 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Pin all Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt==2.3.2

COPY app.py .

# Set build metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF

USER 1000:1000

EXPOSE 5000
CMD ["python", "app.py"]
EOF

# Build with build args for reproducibility
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD || echo "unknown")

docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VCS_REF="$VCS_REF" \
    -f Dockerfile.deterministic \
    -t flask-app:deterministic .

# Verify metadata
docker inspect flask-app:deterministic --format '{{json .Config.Labels}}' | jq .
```

### Verify It
- [ ] Optimized image is significantly smaller than naive version
- [ ] Can identify which techniques provided the most size reduction
- [ ] Understand the trade-offs between size and determinism
- [ ] Built a production-ready image with proper security practices

---

## 🧹 Lab Cleanup

After completing all labs:

```bash
# Remove containers
docker rm -f $(docker ps -aq --filter "name=lab1-app") 2>/dev/null

# Remove images created in labs
docker image rm \
    my-node-app:v1 \
    cache-demo:good cache-demo:bad \
    context-demo:bloated context-demo:clean \
    cmd-demo entrypoint-demo combined-demo webapp-demo \
    flask-app:naive flask-app:optimized flask-app:deterministic \
    2>/dev/null

# Clean up directories
cd .. && rm -rf dockerfile-labs

# Clean dangling images
docker image prune -f
```

## 📝 Lab Summary

**What you accomplished:**
1. ✅ Built your first custom Docker images from scratch
2. ✅ Optimized build performance using layer caching strategies
3. ✅ Secured builds by controlling context with `.dockerignore`
4. ✅ Mastered the differences between CMD and ENTRYPOINT
5. ✅ Applied size optimization and deterministic build techniques

**Key insights gained:**
- Base image choice significantly impacts final image size and security
- Proper Dockerfile directive ordering dramatically improves build performance
- Build context control is essential for security and performance
- CMD vs ENTRYPOINT choice affects container flexibility and reusability
- Small optimizations compound to create production-ready images

**Real-world applications:**
- **Development**: Fast iterative builds through effective caching
- **Security**: Preventing credential leakage and minimizing attack surface
- **Production**: Deterministic, reproducible deployments
- **Operations**: Configurable containers that work across environments

**Best practices learned:**
- Pin base image versions for reproducibility
- Order Dockerfile directives from least to most frequently changed
- Use `.dockerignore` to exclude unnecessary and sensitive files
- Choose CMD for flexibility, ENTRYPOINT for fixed behavior
- Combine commands in RUN directives to minimize layer count
- Clean up temporary files within the same RUN command
- Use non-root users for security (covered more in Phase 07)

---

> 🎯 **Next**: With solid Dockerfile fundamentals, you're ready for **Phase 02: BuildKit Advanced** where you'll learn multi-stage builds, cache mounts, and build secrets.