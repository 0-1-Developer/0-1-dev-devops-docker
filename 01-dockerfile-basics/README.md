# Phase 01: Dockerfile Basics

> **Master the art of building custom Docker images with optimized Dockerfiles**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Choose appropriate base images and understand image inheritance
- Write efficient Dockerfiles using proper directive ordering and caching strategies
- Implement `.dockerignore` files to control build context and improve security
- Apply the correct combination of `CMD` vs `ENTRYPOINT` for different scenarios
- Build deterministic, reproducible images with minimal size and maximum reusability

## 📚 Concept Map

```
Dockerfile Basics
├── Base Images & Inheritance
│   ├── Official vs Community Images
│   ├── Version Pinning Strategies
│   └── Security Considerations
├── Essential Directives
│   ├── FROM (Base Selection)
│   ├── WORKDIR (Working Directory)
│   ├── RUN (Build Commands)
│   ├── COPY/ADD (File Operations)
│   ├── ENV (Environment Variables)
│   └── EXPOSE (Port Documentation)
├── Execution & Entry Points
│   ├── CMD (Default Command)
│   ├── ENTRYPOINT (Fixed Entry Point)
│   └── Argument Handling
├── Build Optimization
│   ├── Layer Caching Strategy
│   ├── Context Management (.dockerignore)
│   ├── Deterministic Builds
│   └── Size Optimization Techniques
└── Best Practices
    ├── Security Guidelines
    ├── Maintainability Patterns
    └── Production Readiness
```

## 🔬 Core Topics

### 1. Base Image Selection
**Foundation of Your Container**

- **Official Images**: Docker Hub's verified, maintained images
- **Version Pinning**: Using specific tags vs `latest`
- **Size vs Features**: Alpine vs full distributions
- **Security Posture**: Regular updates and vulnerability scanning
- **Compatibility**: Architecture and dependency considerations

### 2. Dockerfile Directives
**The Building Blocks**

Each directive serves a specific purpose and affects the final image:

- `FROM`: Establishes the base layer and sets the foundation
- `WORKDIR`: Sets working directory for subsequent commands
- `RUN`: Executes commands during build, creates new layers
- `COPY`/`ADD`: Transfers files from build context to image
- `ENV`: Sets environment variables (build-time and runtime)
- `EXPOSE`: Documents which ports the container listens on
- `CMD`: Provides default execution command (overridable)
- `ENTRYPOINT`: Sets fixed execution entry point

### 3. Layer Caching & Optimization
**Speed and Efficiency**

- **Cache Strategy**: Order directives from least to most frequently changed
- **Layer Reuse**: How Docker determines cache hits and misses
- **Context Optimization**: Using `.dockerignore` to exclude unnecessary files
- **Multi-command Efficiency**: Combining vs separating RUN commands
- **Deterministic Builds**: Ensuring reproducible results

### 4. Build Context Management
**Control What Gets Built**

- **Context Scope**: Understanding what gets sent to Docker daemon
- **`.dockerignore` Patterns**: Excluding files, directories, and patterns
- **Security Implications**: Preventing sensitive files from entering images
- **Performance Impact**: Reducing build context size for faster builds

## 🛠 Prerequisites

- **Completed**: Phase 00 (Foundations) - understanding of images vs containers
- **Docker**: 20.10+ with BuildKit enabled (default in recent versions)
- **Text Editor**: For creating and editing Dockerfiles
- **Sample Applications**: We'll provide simple apps for containerization

## ⏱ Time Investment

- **Reading & Understanding**: 60 minutes
- **Hands-on Labs**: 120 minutes
- **Verification & Review**: 45 minutes
- **Total**: ~3.5 hours

## 🎓 Learning Strategy

1. **Understand Each Directive**: Learn purpose, syntax, and best practices
2. **Practice Build Optimization**: Experience caching and context control
3. **Complete Progressive Labs**: Build complexity gradually
4. **Master CMD vs ENTRYPOINT**: Critical for container behavior
5. **Apply Security Practices**: Build with production standards

## 📖 Topic Deep Dives

### Base Images: Your Foundation

**Official Images** are your safest bet:
```dockerfile
# Good: Official, maintained, secure
FROM node:18-alpine

# Better: Pinned version for reproducibility  
FROM node:18.19-alpine

# Best: Digest for immutability
FROM node:18.19-alpine@sha256:abc123...
```

**Size Considerations**:
- `alpine` variants: ~5-15MB, minimal packages
- `slim` variants: ~50-100MB, essential packages only
- Full variants: ~200-800MB, complete OS with all packages

### Dockerfile Directive Best Practices

**Order Matters for Caching**:
```dockerfile
# Bad: Invalidates cache frequently
COPY . /app
RUN npm install

# Good: Dependencies cached separately
COPY package*.json /app/
RUN npm install
COPY . /app
```

**RUN Command Optimization**:
```dockerfile
# Bad: Multiple layers, temporary files persist
RUN apt-get update
RUN apt-get install -y curl
RUN curl -O https://example.com/file.tar.gz
RUN rm -rf /var/lib/apt/lists/*

# Good: Single layer, cleanup included
RUN apt-get update && \
    apt-get install -y curl && \
    curl -O https://example.com/file.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### CMD vs ENTRYPOINT Decision Matrix

| Scenario | Use | Example |
|----------|-----|---------|
| **Default command, allow override** | `CMD` | `CMD ["npm", "start"]` |
| **Fixed entry point, accept arguments** | `ENTRYPOINT` | `ENTRYPOINT ["./app"]` |
| **Script that processes arguments** | `ENTRYPOINT` + `CMD` | `ENTRYPOINT ["./script.sh"]` + `CMD ["--default"]` |
| **Multiple possible commands** | `CMD` only | `CMD ["python", "app.py"]` |

### Build Context Optimization

**`.dockerignore` Essentials**:
```dockerignore
# Development files
node_modules/
npm-debug.log
.env
.env.local

# Version control
.git/
.gitignore

# Documentation
README.md
docs/

# Build artifacts  
dist/
build/
target/

# OS files
.DS_Store
Thumbs.db
```

## 🔍 Common Pitfalls & Solutions

### ❌ Context Bloat
**Problem**: Sending entire project directory including `node_modules`, `.git`, etc.
```dockerfile
# This sends EVERYTHING in current directory
COPY . /app
```

**✅ Solution**: Use `.dockerignore` and selective copying
```dockerignore
node_modules/
.git/
```
```dockerfile
COPY package*.json /app/
RUN npm install
COPY src/ /app/src/
```

### ❌ Cache Invalidation
**Problem**: Dependencies reinstall on every source change
```dockerfile
COPY . /app
RUN npm install  # Runs every time any file changes
```

**✅ Solution**: Copy dependencies first, source code last
```dockerfile
COPY package*.json /app/
RUN npm install     # Cached until package.json changes
COPY src/ /app/src/ # Only source changes invalidate this
```

### ❌ Credential Leakage
**Problem**: Secrets end up in image layers
```dockerfile
COPY secret-key.pem /app/
RUN configure-app --key=/app/secret-key.pem
# Secret is now in the image forever!
```

**✅ Solution**: Use build secrets (covered in Phase 02) or environment variables
```dockerfile
RUN --mount=type=secret,id=key configure-app --key=/run/secrets/key
```

### ❌ Non-deterministic Builds
**Problem**: Different results from same Dockerfile
```dockerfile
RUN apt-get update && apt-get install -y curl
# Package versions may differ between builds
```

**✅ Solution**: Pin package versions when possible
```dockerfile
RUN apt-get update && apt-get install -y curl=7.68.0-1ubuntu2.7
```

## 💡 Production Notes

### Security Considerations
- **Pin base image versions** to prevent unexpected changes
- **Use official images** from verified publishers when possible
- **Avoid running as root** (will cover in Phase 07)
- **Keep images updated** with security patches
- **Scan images regularly** for vulnerabilities

### Build Performance
- **Optimize layer ordering** for maximum cache reuse
- **Minimize build context** with effective `.dockerignore`
- **Use BuildKit** for advanced optimizations (covered in Phase 02)
- **Consider multi-stage builds** for complex applications (Phase 02)

### Maintainability
- **Document non-obvious directives** with comments
- **Use consistent formatting** and indentation
- **Group related operations** in single RUN commands
- **Make images configurable** with environment variables

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Create a Dockerfile that builds successfully without errors
- [ ] Choose appropriate base images based on requirements (size, security, features)
- [ ] Implement effective caching strategies that speed up iterative builds
- [ ] Use `.dockerignore` to control build context and improve security
- [ ] Select the correct combination of CMD/ENTRYPOINT for different use cases
- [ ] Build images that are deterministic and reproducible
- [ ] Apply security best practices in Dockerfile construction
- [ ] Explain the purpose and effect of each Dockerfile directive

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p01-m01-l01` - Directive→Purpose Flashcards
- `p01-m01-l02` - Cache-Bust Scenarios 
- `p01-m01-l03` - Context Scoping Exercise
- `p01-m01-l04` - CMD vs ENTRYPOINT Decision Tree

## 🎯 What's Next

After mastering Dockerfile basics:
- **Phase 02**: Advanced BuildKit techniques (multi-stage builds, cache mounts, build secrets)
- **Phase 03**: Container runtime management and operations
- **Phase 07**: Security hardening and best practices

---

> 💡 **Key Insight**: A well-crafted Dockerfile is like a recipe - it should be clear, efficient, and produce consistent results every time. The time spent optimizing your Dockerfile pays dividends in build speed, image size, and deployment reliability.