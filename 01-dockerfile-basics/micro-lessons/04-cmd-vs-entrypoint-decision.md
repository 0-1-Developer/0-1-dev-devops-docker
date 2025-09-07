# Micro-Lesson 04: CMD vs ENTRYPOINT Decision Tree

> **Anchor**: `p01-m01-l04`  
> **Duration**: 5 minutes  
> **One Key Idea**: Choose CMD for flexibility, ENTRYPOINT for fixed behavior, combine both for configurable applications

## Why It Matters

Wrong execution directive choice leads to containers that don't behave as expected. Understanding CMD vs ENTRYPOINT is crucial for creating reusable, predictable container images.

## What to Learn

Execution directive behaviors:
- **CMD**: Provides default command, completely replaceable
- **ENTRYPOINT**: Fixed entry point, arguments get appended
- **Both Combined**: Fixed entry point with default arguments
- **Use Cases**: When to use each approach based on container purpose

## Decision Tree

```
What type of container are you building?
│
├─ FLEXIBLE TOOL (multiple possible commands)
│  └─ Use CMD only
│     └─ Example: Development environment, base image
│
├─ FIXED TOOL (always runs same program)
│  └─ Use ENTRYPOINT only  
│     └─ Example: CLI tool, single-purpose app
│
└─ CONFIGURABLE APP (fixed app, variable config)
   └─ Use ENTRYPOINT + CMD
      └─ Example: Web server with default ports/settings
```

## Behavior Comparison

### CMD Only
```dockerfile
CMD ["python", "app.py", "--port", "8000"]
```

**Behavior**:
```bash
docker run myapp                    # ← Runs: python app.py --port 8000
docker run myapp echo "hello"      # ← Runs: echo "hello"
docker run myapp python debug.py   # ← Runs: python debug.py
```

**When to use**: Development images, base images, flexible containers.

### ENTRYPOINT Only
```dockerfile
ENTRYPOINT ["python", "app.py"]
```

**Behavior**:
```bash
docker run myapp                    # ← Runs: python app.py
docker run myapp --port 9000       # ← Runs: python app.py --port 9000
docker run myapp --help            # ← Runs: python app.py --help
```

**When to use**: CLI tools, single-purpose applications, when users should only configure the app, not replace it.

### ENTRYPOINT + CMD Combined
```dockerfile
ENTRYPOINT ["python", "app.py"]
CMD ["--port", "8000"]
```

**Behavior**:
```bash
docker run myapp                    # ← Runs: python app.py --port 8000
docker run myapp --port 9000       # ← Runs: python app.py --port 9000
docker run myapp --debug           # ← Runs: python app.py --debug
```

**When to use**: Applications with sensible defaults that users might want to override.

## Try It - Match the Use Case

**Scenario 1**: Database container that should always run the same database but allow configuration
```dockerfile
# Your choice: CMD, ENTRYPOINT, or both?
```

<details>
<summary>Best Choice</summary>

```dockerfile
ENTRYPOINT ["postgres"]
CMD ["-c", "max_connections=100"]
```

**Why**: Users should always get postgres, but might want different config flags.

</details>

**Scenario 2**: Development environment where users run various commands
```dockerfile
# Your choice: CMD, ENTRYPOINT, or both?
```

<details>
<summary>Best Choice</summary>

```dockerfile
CMD ["bash"]
```

**Why**: Developers need complete flexibility - sometimes bash, sometimes python, sometimes build commands.

</details>

**Scenario 3**: CLI tool that processes files with various options
```dockerfile
# Your choice: CMD, ENTRYPOINT, or both?
```

<details>
<summary>Best Choice</summary>

```dockerfile
ENTRYPOINT ["./process-files"]
CMD ["--help"]
```

**Why**: Tool should always run, but users need to specify what to process. Default help is useful.

</details>

## Real-World Examples

### Web Application (ENTRYPOINT + CMD)
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

ENTRYPOINT ["node", "server.js"]
CMD ["--port", "3000", "--env", "production"]
```

**Usage**:
```bash
docker run webapp                           # Default: port 3000, production
docker run webapp --port 8080              # Custom port
docker run webapp --port 8080 --env dev    # Custom port and environment
```

### CLI Utility (ENTRYPOINT Only)
```dockerfile
FROM alpine:latest
RUN apk add --no-cache curl jq
COPY process-api.sh /usr/local/bin/
ENTRYPOINT ["process-api.sh"]
```

**Usage**:
```bash
docker run api-tool https://api.example.com/data    # Process specific API
docker run api-tool --help                          # Show help
docker run api-tool --format json https://...       # Custom format
```

### Development Environment (CMD Only)
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    python3 nodejs npm git vim curl
WORKDIR /workspace
CMD ["bash"]
```

**Usage**:
```bash
docker run -it devenv                    # Interactive bash session  
docker run devenv python3 script.py     # Run Python script
docker run devenv npm test               # Run tests
docker run devenv git status             # Git commands
```

## Advanced Pattern: Script Wrapper

**Common pattern**: Use shell script as ENTRYPOINT for complex logic
```dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--default-mode"]
```

**entrypoint.sh**:
```bash
#!/bin/bash
# Initialization logic
setup_environment()
configure_app()

# Pass all arguments to the main application  
exec python app.py "$@"
```

## Decision Framework

Ask these questions:

1. **Should users be able to run completely different commands?**
   - Yes → Use **CMD only**
   - No → Continue to question 2

2. **Is your application always the same, just with different arguments?**
   - Yes → Use **ENTRYPOINT only**
   - No → Continue to question 3

3. **Do you want to provide sensible defaults that users can override?**
   - Yes → Use **ENTRYPOINT + CMD**

## Common Mistakes

### ❌ Mistake 1: Using CMD for Fixed Applications
```dockerfile
# Bad: Database that could accidentally be overridden
CMD ["postgres", "-c", "max_connections=100"]
```
```bash
# Accidentally breaks the container
docker run db-container echo "hello"  # No database runs!
```

### ❌ Mistake 2: Using ENTRYPOINT for Flexible Tools  
```dockerfile
# Bad: Development container that's too restrictive
ENTRYPOINT ["python"]
```
```bash
# Can't run other tools easily
docker run dev-container npm install  # Runs: python npm install (error!)
```

### ❌ Mistake 3: Shell Form vs Exec Form
```dockerfile
# Bad: Shell form doesn't handle signals properly
CMD python app.py

# Good: Exec form allows proper signal handling  
CMD ["python", "app.py"]
```

## The Selection Rules

1. **CMD**: For maximum flexibility (development, base images)
2. **ENTRYPOINT**: For fixed-purpose containers (CLI tools, specialized services)
3. **ENTRYPOINT + CMD**: For configurable applications (web apps, databases)
4. **Always use exec form** (`["cmd"]`) for proper signal handling

## Quick Memory Aid

- **CMD**: **C**ompletely **M**alleable **D**efault
- **ENTRYPOINT**: **Entry** point is **P**ermanent, **O**nly arguments **I**nterchangeable **N**ow **T**
- **Both**: **B**est **O**f **T**wo **H**andling approaches

---

**Congratulations!** You've mastered the four essential Dockerfile concepts. You're now ready to build efficient, secure, and maintainable Docker images.