# Micro-Lesson 02: Cache-Bust Scenarios

> **Anchor**: `p01-m01-l02`  
> **Duration**: 5 minutes  
> **One Key Idea**: Understanding when Docker layer cache is invalidated helps you optimize build performance

## Why It Matters

Poor cache strategy can turn a 5-second incremental build into a 5-minute full rebuild. Knowing what invalidates cache helps you structure Dockerfiles for maximum development velocity.

## What to Learn

Docker's layer caching rules:
- **Cache Hit**: When instruction and content are identical to previous build
- **Cache Miss**: When instruction changes or file content changes
- **Cache Invalidation**: Once cache misses, all subsequent layers rebuild
- **Optimal Ordering**: Place frequently changing content last

## Caching Rules Deep Dive

### Rule 1: Instruction Changes Bust Cache
```dockerfile
# Build 1
RUN npm install

# Build 2 - cache miss (instruction changed)
RUN npm install --only=production
```

### Rule 2: File Content Changes Bust Cache
```dockerfile
# Build 1
COPY package.json ./

# Build 2 - cache hit if package.json unchanged
COPY package.json ./

# Build 2 - cache miss if package.json changed
COPY package.json ./
```

### Rule 3: Cache Invalidation Cascades
```dockerfile
FROM node:18-alpine     # ← Always cached (unless base image updates)
COPY package.json ./    # ← Cache miss if package.json changed
RUN npm install         # ← Rebuilds (previous layer invalidated)
COPY . .               # ← Rebuilds (previous layer invalidated)  
CMD ["npm", "start"]    # ← Rebuilds (previous layer invalidated)
```

## Try It - Predict Cache Behavior

**Scenario**: You have this Dockerfile:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**Question 1**: You modify `src/app.js` (not package.json). Which layers rebuild?

<details>
<summary>Answer</summary>

- `FROM node:18-alpine` → **CACHED** (unchanged)
- `WORKDIR /app` → **CACHED** (unchanged)
- `COPY package.json ./` → **CACHED** (package.json unchanged)
- `RUN npm install` → **CACHED** (previous layer cached)
- `COPY . .` → **REBUILDS** (src/app.js changed)
- `EXPOSE 3000` → **REBUILDS** (cascade from previous)
- `CMD ["npm", "start"]` → **REBUILDS** (cascade from previous)

Result: Only 3 layers rebuild, npm install stays cached!

</details>

**Question 2**: You add a new dependency to package.json. Which layers rebuild?

<details>
<summary>Answer</summary>

- `FROM node:18-alpine` → **CACHED** (unchanged)
- `WORKDIR /app` → **CACHED** (unchanged)
- `COPY package.json ./` → **REBUILDS** (package.json changed)
- `RUN npm install` → **REBUILDS** (cascade + needs new package)
- `COPY . .` → **REBUILDS** (cascade)
- `EXPOSE 3000` → **REBUILDS** (cascade)
- `CMD ["npm", "start"]` → **REBUILDS** (cascade)

Result: 5 layers rebuild, but that's correct behavior!

</details>

## Anti-Pattern Recognition

### ❌ Anti-Pattern: "Copy Everything First"
```dockerfile
FROM node:18-alpine
COPY . /app           # ← Any file change busts cache
WORKDIR /app
RUN npm install       # ← Always rebuilds, even for src changes
CMD ["npm", "start"]
```

**Problem**: Changing a single comment in source code triggers npm install.

### ✅ Optimized Pattern: "Dependencies First"
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./  # ← Only package changes bust cache
RUN npm install        # ← Cached unless dependencies change
COPY . .              # ← Source changes only bust this layer
CMD ["npm", "start"]
```

**Benefit**: Source changes don't trigger dependency reinstall.

## Advanced Cache Scenarios

### Multi-File Copy Strategy
```dockerfile
# Good: Group files by change frequency
COPY package*.json ./                    # Rarely changes
RUN npm install
COPY config/ ./config/                   # Sometimes changes
COPY src/ ./src/                         # Frequently changes
```

### Build-time vs Runtime Configuration
```dockerfile
# Build-time config (affects installed packages)
ARG BUILD_ENV=production
RUN npm install --only=$BUILD_ENV        # Rebuilds when BUILD_ENV changes

# Runtime config (doesn't affect build)
ENV NODE_ENV=production                   # Cached unless instruction changes
```

## Try It - Optimization Challenge

**Given**: This inefficient Dockerfile:
```dockerfile
FROM python:3.11
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
RUN python setup.py build
EXPOSE 8000
CMD ["python", "app.py"]
```

**Challenge**: Reorder for optimal caching. Assume:
- `requirements.txt` changes rarely
- Source code in `src/` changes frequently  
- `setup.py` changes sometimes

<details>
<summary>Optimized Solution</summary>

```dockerfile
FROM python:3.11
WORKDIR /app

# Dependencies first (rarely change)
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Build config second (sometimes changes)  
COPY setup.py ./
RUN python setup.py build

# Source code last (frequently changes)
COPY src/ ./src/
COPY app.py ./

EXPOSE 8000
CMD ["python", "app.py"]
```

**Cache efficiency**: Source changes only rebuild the final COPY layer!

</details>

## The Caching Rules Summary

1. **Identical instruction + content = cache hit**
2. **Any change = cache miss + cascade invalidation**
3. **Order by change frequency**: stable → volatile
4. **Group related files** by their change patterns
5. **Separate build deps from source** for maximum cache reuse

## Quick Mental Model

Think of Docker layers like a **house of cards**:
- Each layer depends on the one below
- If any layer falls (cache miss), all layers above must be rebuilt
- Build your "foundation" with the most stable layers first

## Production Tip

In CI/CD environments:
- **Development**: Optimize for fast incremental builds
- **Production**: Consider using specific base image digests for reproducibility
- **Both**: Use `.dockerignore` to prevent unnecessary cache invalidation

---

**Next**: Learning how to control build context with `.dockerignore` for security and performance.