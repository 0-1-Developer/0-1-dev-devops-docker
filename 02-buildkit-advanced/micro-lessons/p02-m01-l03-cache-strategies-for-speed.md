# Micro-Lesson: Cache Strategies for Speed

**Anchor**: `p02-m01-l03`  
**Duration**: 3 minutes  
**Objective**: Select optimal cache mount targets for maximum build speed improvement

## 🎯 Core Concept

**Cache mounts accelerate builds by persisting directories between builds**. The key is identifying which directories contain reusable artifacts that are expensive to recreate.

## 🔍 Cache Target Discovery

### High-Impact Cache Targets

**Package Managers** (Biggest wins):
- **npm**: `/root/.npm` (or `~/.npm`)
- **pip**: `/root/.cache/pip` 
- **maven**: `/root/.m2/repository`
- **gradle**: `/root/.gradle/caches`
- **cargo**: `/usr/local/cargo/registry`
- **go**: `/go/pkg/mod`

**Build Tools**:
- **webpack**: `node_modules/.cache`
- **babel**: `node_modules/.cache/babel`
- **typescript**: `node_modules/.cache/typescript`
- **pytest**: `.pytest_cache`

## 🛠 Cache Mount Syntax

```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm install

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
    
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
```

## 🚀 Speed Impact Examples

### Node.js Project
```dockerfile
# Without cache: 45s every build
COPY package.json .
RUN npm install

# With cache: 45s first build, 3s subsequent builds
COPY package.json .
RUN --mount=type=cache,target=/root/.npm \
    npm install
```

### Python Project  
```dockerfile
# Without cache: 60s every build
RUN pip install tensorflow pandas numpy

# With cache: 60s first build, 5s subsequent builds
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install tensorflow pandas numpy
```

## 🎯 Cache Strategy Selection

### 1. **Identify Package Managers**
What tools download dependencies?
- Language package managers (npm, pip, cargo)  
- System package managers (apt, apk, yum)
- Build tools (webpack, gradle, maven)

### 2. **Find Cache Directories**
Where do these tools store downloads?
```bash
# Find npm cache location
npm config get cache

# Find pip cache location  
pip cache dir

# Find gradle cache location
gradle --version  # Shows gradle user home
```

### 3. **Estimate Impact**
- **High impact**: Large dependencies, network downloads
- **Medium impact**: Compilation artifacts, processed assets  
- **Low impact**: Small configs, local files

## 📊 Performance Measurement

Measure cache effectiveness:

```dockerfile  
# Time the build
time docker build -t test-cache .

# Check cache size growth
docker system df
```

Expected improvements:
- **First build**: Same time (building cache)
- **Subsequent builds**: 5-15x faster for dependency steps
- **Code changes**: Fast rebuilds (dependencies cached)

## 🔧 Advanced Cache Patterns

### Multi-Tool Caching
```dockerfile
# Cache multiple package managers
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/root/.cache/pip \
    npm install && pip install -r requirements.txt
```

### Scoped Caching
```dockerfile
# Different cache per project/branch
RUN --mount=type=cache,target=/cache,id=myproject-npm \
    npm install
```

### Conditional Caching
```dockerfile
# Only cache in development builds
ARG ENABLE_CACHE=false
RUN --mount=type=cache,target=/root/.npm,enabled=$ENABLE_CACHE \
    npm install
```

## ⚠️ Cache Considerations

### Security
- Cache directories shouldn't contain secrets
- Cache is shared across all builds using same target
- Use cache IDs to isolate sensitive projects

### Scope
- Cache persists beyond individual builds  
- Different projects can share cache (good for shared dependencies)
- Cache doesn't increase final image size

### Performance
- Cache mounts add slight overhead for small operations
- Network-downloaded dependencies have highest ROI
- Local file operations see minimal benefit

## 🚨 Common Mistakes

❌ **Caching source code directories**:
```dockerfile
# Don't cache your changing source code
RUN --mount=type=cache,target=/app/src \
    process-source-files
```

❌ **Wrong cache target**:
```dockerfile  
# This caches node_modules, not the npm cache
RUN --mount=type=cache,target=/app/node_modules \
    npm install
```

❌ **Caching one-time operations**:
```dockerfile
# apt-get update is always fresh, don't cache
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update
```

## 🎓 Quick Assessment

For your project, identify:
1. **What package managers do you use?**
2. **Where do they cache downloads?**
3. **How long do dependency installations take?**
4. **Which steps would benefit most from caching?**

Start with your slowest, most network-dependent operations first.