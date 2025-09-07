# Micro-Lesson: Build Args and Target Naming

**Anchor**: `p02-m01-l04`  
**Duration**: 4 minutes  
**Objective**: Create flexible builds with arguments and selective stage targeting

## 🎯 Core Concept

**Build arguments** make Dockerfiles configurable at build time, while **target naming** allows building different stages for different purposes. Together, they create flexible, reusable build configurations.

## 🔧 Build Arguments Fundamentals

### Basic Syntax
```dockerfile
ARG ENVIRONMENT=development  # Default value
ARG APP_VERSION             # No default (must be provided)
ARG ENABLE_FEATURES=false    # Boolean argument

FROM node:18-alpine
ENV NODE_ENV=$ENVIRONMENT    # Convert ARG to ENV for runtime
```

### Build-Time Usage
```bash
# Use defaults
docker build -t app .

# Override values
docker build \
  --build-arg ENVIRONMENT=production \
  --build-arg APP_VERSION=v2.1.0 \
  --build-arg ENABLE_FEATURES=true \
  -t app:prod .
```

## 🎯 Target Naming Strategy

### Multi-Stage with Named Targets
```dockerfile
# Development target - includes dev tools
FROM node:18 AS development
COPY package.json .
RUN npm install  # Includes devDependencies
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Test target - runs tests
FROM development AS testing  
RUN npm run test
RUN npm run lint

# Production target - optimized runtime
FROM node:18-alpine AS production
COPY --from=development /app/dist ./
COPY --from=development /app/package.json .
RUN npm install --only=production
USER node
CMD ["node", "server.js"]
```

### Selective Building
```bash
# Build development image
docker build --target development -t app:dev .

# Build and run tests (doesn't create final image)
docker build --target testing .

# Build production image
docker build --target production -t app:prod .
```

## 🔄 Combined Patterns

### Environment-Driven Configuration
```dockerfile
ARG BUILD_ENV=development
ARG ENABLE_DEBUG=true
ARG INSTALL_DEV_TOOLS=true

FROM node:18-alpine AS base
WORKDIR /app

# Conditional operations based on arguments
FROM base AS dependencies
COPY package*.json ./
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
        npm install; \
    else \
        npm install --only=production; \
    fi

FROM dependencies AS application
COPY . .

# Build step - only in production
FROM application AS build
RUN if [ "$BUILD_ENV" = "production" ]; then \
        npm run build; \
    fi

# Final stage selection based on argument
FROM ${BUILD_ENV:-development} AS final
ENV DEBUG_MODE=$ENABLE_DEBUG
EXPOSE 3000
CMD ["npm", "start"]
```

### Build Matrix Examples
```bash
# Development build with all tools
docker build \
  --build-arg BUILD_ENV=development \
  --build-arg ENABLE_DEBUG=true \
  --build-arg INSTALL_DEV_TOOLS=true \
  --target final \
  -t app:dev .

# Production build optimized  
docker build \
  --build-arg BUILD_ENV=production \
  --build-arg ENABLE_DEBUG=false \
  --build-arg INSTALL_DEV_TOOLS=false \
  --target final \
  -t app:prod .

# Test runner
docker build --target testing -t app:test .
```

## 🛠 Advanced Patterns

### Argument Validation
```dockerfile
ARG ENVIRONMENT
RUN if [ "$ENVIRONMENT" != "development" ] && \
       [ "$ENVIRONMENT" != "staging" ] && \
       [ "$ENVIRONMENT" != "production" ]; then \
        echo "Invalid ENVIRONMENT: $ENVIRONMENT" && exit 1; \
    fi
```

### Multi-Architecture Support
```dockerfile
ARG TARGETARCH
ARG BUILDPLATFORM

FROM --platform=$BUILDPLATFORM golang:1.21 AS builder
RUN GOOS=linux GOARCH=$TARGETARCH go build -o app .

FROM alpine:latest
COPY --from=builder /app/app .
```

### Dynamic Base Images
```dockerfile
ARG BASE_IMAGE=node:18-alpine
ARG BASE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_TAG}
# Rest of Dockerfile adapts to base image choice
```

## 📋 Design Patterns

### Pattern 1: Environment Matrix
```dockerfile
ARG ENV=dev
FROM base AS dependencies-dev
RUN npm install

FROM base AS dependencies-prod  
RUN npm install --only=production

FROM dependencies-${ENV} AS final
```

### Pattern 2: Feature Flags
```dockerfile
ARG ENABLE_MONITORING=false
ARG ENABLE_DEBUG=false

# Conditional layers based on features
FROM base AS monitoring
RUN if [ "$ENABLE_MONITORING" = "true" ]; then \
        npm install prometheus-client; \
    fi

FROM monitoring AS debug-tools
RUN if [ "$ENABLE_DEBUG" = "true" ]; then \
        npm install --save-dev nodemon; \
    fi
```

### Pattern 3: CI/CD Integration
```dockerfile
ARG GIT_COMMIT
ARG BUILD_DATE
ARG VERSION

LABEL git.commit=$GIT_COMMIT
LABEL build.date=$BUILD_DATE  
LABEL version=$VERSION

ENV APP_VERSION=$VERSION
```

## ⚡ Quick Decision Framework

**When to use ARG**:
- ✅ Build-time configuration (environment, versions, features)
- ✅ Conditional build logic
- ✅ CI/CD parameter passing

**When to use targets**:
- ✅ Multiple deployment scenarios (dev/test/prod)
- ✅ Different image purposes (runtime vs testing)
- ✅ Build optimization (skip unnecessary stages)

**When to combine both**:
- ✅ Complex build matrices
- ✅ Feature flag management
- ✅ Multi-environment deployments

## 🚨 Common Pitfalls

❌ **ARG after FROM without redeclaration**:
```dockerfile
ARG VERSION=1.0
FROM node:18
RUN echo $VERSION  # Empty! ARG not available after FROM
```

✅ **Redeclare ARG in stage**:
```dockerfile
ARG VERSION=1.0
FROM node:18
ARG VERSION  # Redeclare to use in this stage
RUN echo $VERSION
```

❌ **Using ENV for build-time config**:
```dockerfile
ENV BUILD_MODE=development  # Persists in final image
```

✅ **Use ARG for build-time, ENV for runtime**:
```dockerfile
ARG BUILD_MODE=development
ENV NODE_ENV=$BUILD_MODE  # Only if needed at runtime
```

## 🎓 Practice Challenge

Design a build configuration for your application that supports:
1. **Development mode**: All tools, debugging enabled
2. **Testing mode**: Run tests, include coverage tools
3. **Production mode**: Minimal runtime, optimized
4. **Feature flags**: Enable/disable optional components

Use ARG for configuration and targets for different build outputs.