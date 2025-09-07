# Micro-Lesson: Runtime vs Builder Contents

**Anchor**: `p02-m01-l01`  
**Duration**: 3 minutes  
**Objective**: Understand what belongs in builder vs runtime stages

## 🎯 Core Concept

**Multi-stage builds separate concerns**: Everything needed to *build* your application goes in the builder stage. Everything needed to *run* your application goes in the runtime stage.

## 🔍 The Key Question

For every file, package, or tool, ask: **"Is this needed at runtime or just during build?"**

### Builder Stage Contains:
- **Source code** (to compile/build)
- **Build tools** (compilers, npm, pip, maven)
- **Development dependencies** (test frameworks, linters)
- **Build artifacts** (intermediate files, temporary assets)

### Runtime Stage Contains:
- **Final executables** (compiled binaries, built assets)
- **Runtime dependencies** (libraries needed to run)
- **Configuration files** (needed during execution)
- **Minimal OS components** (just enough to run the app)

## 💡 Quick Example

```dockerfile
# Builder stage - has everything needed to build
FROM node:18 AS builder
COPY package.json .
RUN npm install          # Includes devDependencies
COPY src/ .
RUN npm run build        # Creates dist/ folder

# Runtime stage - only what's needed to run
FROM node:18-alpine AS runtime
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json .
RUN npm install --only=production  # No devDependencies
CMD ["node", "dist/server.js"]
```

**Result**: Builder stage might be 800MB, runtime stage only 50MB.

## ⚡ Decision Framework

```
Need this to compile/build? → Builder stage
Need this to run the app?   → Runtime stage  
Don't need it at all?       → Don't include it
```

## 🚨 Common Mistakes

❌ **Including build tools in runtime**:
```dockerfile
FROM node:18
RUN npm install  # Includes dev tools
COPY . .
RUN npm run build
CMD ["npm", "start"]  # Still has webpack, typescript, etc.
```

✅ **Proper separation**:
```dockerfile
# Build
FROM node:18 AS builder
RUN npm install && npm run build

# Runtime  
FROM node:18-alpine
COPY --from=builder /app/dist .
CMD ["node", "server.js"]  # Clean runtime
```

## 📊 Impact

- **Size reduction**: 70-90% smaller images
- **Security**: Fewer attack surface components  
- **Performance**: Faster startup, less memory usage
- **Maintenance**: Clearer separation of concerns

## 🎓 Practice Challenge

Look at your current Dockerfile. Identify:
1. What's only needed during build?
2. What's only needed at runtime?
3. What's needed for both?

This mental model is the foundation for all advanced BuildKit techniques.