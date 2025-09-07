# Micro-Lesson 01: Directive→Purpose Flashcards

> **Anchor**: `p01-m01-l01`  
> **Duration**: 4 minutes  
> **One Key Idea**: Each Dockerfile directive has a specific purpose and optimal usage pattern

## Why It Matters

Using the wrong directive or using directives in the wrong order leads to broken builds, security issues, and poor performance. Knowing each directive's purpose helps you write effective Dockerfiles.

## What to Learn

Master the purpose and syntax of essential Dockerfile directives:
- **FROM**: Sets the base image foundation
- **WORKDIR**: Establishes working directory for subsequent commands
- **COPY/ADD**: Transfers files from host to image
- **RUN**: Executes commands during build (creates layers)
- **ENV**: Sets environment variables
- **EXPOSE**: Documents ports (doesn't publish them)
- **CMD**: Provides default execution command
- **ENTRYPOINT**: Sets fixed execution entry point

## Directive Flashcards

### Card 1: FROM
**Purpose**: Establishes the base image  
**When to use**: First directive in every Dockerfile  
**Example**: `FROM node:18-alpine`

<details>
<summary>Why alpine over full node?</summary>
Alpine is smaller (~5MB vs ~200MB), more secure (fewer packages), and faster to download. Use full versions only when you need specific system tools.
</details>

### Card 2: WORKDIR
**Purpose**: Sets working directory for all subsequent commands  
**When to use**: Before copying files or running commands  
**Example**: `WORKDIR /app`

<details>
<summary>Why not use RUN cd /app?</summary>
`RUN cd /app` only affects that single RUN layer. WORKDIR persists for all subsequent layers and the running container.
</details>

### Card 3: COPY vs ADD
**Purpose**: Transfer files from host to image  
**When to use**: 
- **COPY**: 99% of the time (simple, predictable)
- **ADD**: Only when you need URL downloads or auto-extraction  
**Example**: `COPY package*.json ./`

<details>
<summary>Why package*.json first?</summary>
Copying package files first allows npm install to be cached when only source code changes, dramatically speeding up builds.
</details>

### Card 4: RUN
**Purpose**: Execute commands during image build  
**When to use**: Installing packages, building code, system configuration  
**Example**: `RUN npm install --only=production`

<details>
<summary>Single RUN vs multiple RUN commands?</summary>
Multiple RUN commands create multiple layers. Combine related commands with && to reduce layers and enable cleanup in the same layer.
</details>

### Card 5: ENV
**Purpose**: Set environment variables (build-time and runtime)  
**When to use**: Configuration that affects both build and running container  
**Example**: `ENV NODE_ENV=production`

<details>
<summary>ENV vs ARG difference?</summary>
ENV persists into the running container. ARG only exists during build. Use ARG for build-time secrets, ENV for runtime configuration.
</details>

### Card 6: EXPOSE
**Purpose**: Document which ports the application uses  
**When to use**: Always document your application's ports  
**Example**: `EXPOSE 3000`

<details>
<summary>Does EXPOSE publish the port?</summary>
No! EXPOSE only documents. Use `docker run -p 3000:3000` to actually publish ports.
</details>

## Try It - Quick Pattern Recognition

**Match the need with the directive:**

1. Install system packages → **?**
2. Set working directory → **?**  
3. Copy dependency files → **?**
4. Set runtime configuration → **?**
5. Default container command → **?**

<details>
<summary>Answers</summary>

1. Install system packages → **RUN**
2. Set working directory → **WORKDIR**  
3. Copy dependency files → **COPY**
4. Set runtime configuration → **ENV**
5. Default container command → **CMD**

</details>

## Common Directive Mistakes

❌ **Wrong**: 
```dockerfile
RUN cd /app
COPY . .
```
**Problem**: cd only affects that RUN layer

✅ **Right**: 
```dockerfile
WORKDIR /app
COPY . .
```

❌ **Wrong**: 
```dockerfile
ADD https://example.com/file.tar.gz .
```
**Problem**: ADD for URLs is unpredictable, use RUN + wget/curl

✅ **Right**: 
```dockerfile
RUN wget https://example.com/file.tar.gz
```

❌ **Wrong**: 
```dockerfile
RUN apt-get update
RUN apt-get install curl
RUN rm -rf /var/lib/apt/lists/*
```
**Problem**: Cleanup in separate layer doesn't reduce image size

✅ **Right**: 
```dockerfile
RUN apt-get update && \
    apt-get install curl && \
    rm -rf /var/lib/apt/lists/*
```

## The Rule to Remember

> **Every directive should have a clear purpose, and similar purposes should be grouped together**

## Quick Self-Test

Without looking, can you explain:
- When to use COPY vs ADD?
- Why WORKDIR is better than RUN cd?
- What's the difference between EXPOSE and port publishing?
- When would you use multiple RUN vs single RUN?

## Production Pattern

**Typical well-ordered Dockerfile structure**:
```dockerfile
FROM [base-image]          # Foundation
WORKDIR [work-directory]   # Set context
COPY [dependency-files]    # Cache-friendly dependencies
RUN [install-dependencies] # Build step
COPY [source-code]         # Application code (changes frequently)  
ENV [runtime-config]       # Runtime configuration
EXPOSE [port]              # Documentation
CMD [default-command]      # Execution
```

## Memory Device

**"Friendly Workers Copy Resources Everywhere, Eventually Completing"**
- **F**ROM
- **W**ORKDIR  
- **C**OPY
- **R**UN
- **E**NV
- **E**XPOSE
- **C**MD

---

**Next**: Learning to predict and optimize Docker's layer caching behavior.