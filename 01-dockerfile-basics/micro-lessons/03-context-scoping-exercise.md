# Micro-Lesson 03: Context Scoping Exercise

> **Anchor**: `p01-m01-l03`  
> **Duration**: 4 minutes  
> **One Key Idea**: Build context control with `.dockerignore` is essential for security, performance, and maintainability

## Why It Matters

Build context determines what gets sent to Docker daemon. Including unnecessary files causes:
- **Security risks**: Secrets accidentally copied to images
- **Performance issues**: Large context slows builds
- **Reproducibility problems**: Different files → different builds

## What to Learn

Build context scope control:
- **Context**: All files sent to Docker daemon for building
- **`.dockerignore`**: Controls what's included/excluded from context
- **Security principle**: Only include what's absolutely necessary
- **Performance benefit**: Smaller context = faster builds

## Context Scoping Rules

### Rule 1: Everything in Directory Gets Sent
```bash
# Your project directory
myproject/
├── src/                 # ← Gets sent
├── tests/               # ← Gets sent  
├── node_modules/        # ← Gets sent (500MB!)
├── .git/                # ← Gets sent
├── .env                 # ← Gets sent (DANGER!)
├── docker-compose.yml   # ← Gets sent
└── Dockerfile           # ← Gets sent
```

**Without `.dockerignore`**: Docker daemon receives ~500MB+ including secrets!

### Rule 2: .dockerignore Controls Inclusion
```dockerignore
# .dockerignore file
node_modules/
.git/
.env*
tests/
docs/
*.md
```

**With `.dockerignore`**: Docker daemon receives ~2MB of essential files only.

## Try It - Scoping Challenge

**Scenario**: Your project has these files:
```
webapp/
├── src/
│   ├── app.js          # Essential
│   └── config.js       # Essential
├── tests/
│   └── app.test.js     # Not needed in production
├── docs/
│   └── README.md       # Not needed in production
├── node_modules/       # 200MB, not needed (will npm install)
├── .git/              # 50MB, never needed in images
├── .env.production    # Secret keys - DANGER!
├── logs/              # Old log files
│   └── app.log
├── package.json       # Essential
└── Dockerfile
```

**Challenge**: Create `.dockerignore` to include only essential files.

<details>
<summary>Solution</summary>

```dockerignore
# Dependencies (will install fresh)
node_modules/
npm-debug.log

# Version control
.git/
.gitignore

# Environment files (security risk)  
.env*
*.env

# Testing and development
tests/
test/
__tests__/
*.test.js
coverage/

# Documentation
docs/
*.md
README*

# Logs and temporary files
logs/
*.log
tmp/
temp/

# OS and editor files
.DS_Store
Thumbs.db
*.swp
*~
```

**Result**: Only `src/`, `package.json`, and `Dockerfile` get sent to Docker daemon.

</details>

## Security-First Patterns

### Pattern 1: Secrets Exclusion
```dockerignore
# Environment files
.env*
*.env
.env.local
.env.production

# Config files with secrets
config.secret
secrets/
credentials/
keys/
*.pem
*.key
```

### Pattern 2: Development Exclusion  
```dockerignore
# Testing
tests/
__tests__/
*.test.*
*.spec.*
coverage/

# Development tools
.vscode/
.idea/
*.swp
*~
```

### Pattern 3: Build Artifacts Exclusion
```dockerignore
# Dependencies (install fresh)
node_modules/
vendor/
target/
dist/
build/

# Version control
.git/
.svn/
.hg/
```

## Advanced Context Patterns

### Language-Specific Templates

**Node.js `.dockerignore`**:
```dockerignore
node_modules/
npm-debug.log*
.env*
tests/
coverage/
.nyc_output/
```

**Python `.dockerignore`**:
```dockerignore
__pycache__/
*.pyc
venv/
.pytest_cache/
.env*
tests/
```

**Go `.dockerignore`**:
```dockerignore
vendor/
*.test
.env*
bin/
pkg/
```

## Try It - Context Size Analysis

**Exercise**: Compare context sizes:

```bash
# Check current directory size
du -sh .

# Simulate context without .dockerignore
tar --exclude=.dockerignore -cf - . | wc -c

# Simulate context with .dockerignore  
tar --exclude-from=.dockerignore -cf - . | wc -c
```

Expected results:
- Without: 200MB+ (includes node_modules, .git, logs)
- With: 2MB (only essential source code)

## Common .dockerignore Mistakes

### ❌ Mistake 1: Forgetting Security Files
```dockerignore
# Missing sensitive patterns
node_modules/
.git/
# ← Missing .env*, secrets/, *.key
```

**Risk**: Secrets leak into Docker image layers permanently.

### ❌ Mistake 2: Including Build Artifacts
```dockerignore
# Only excluding obvious large directories
node_modules/
.git/
# ← Missing dist/, build/, target/
```

**Problem**: Stale build artifacts cause inconsistent images.

### ❌ Mistake 3: Overly Restrictive
```dockerignore
# Too restrictive - excludes needed files
*
!src/
# ← Might exclude package.json, config files needed for build
```

**Problem**: Build fails due to missing required files.

## The Inclusion Rule

> **When in doubt, exclude. Only include files that are absolutely necessary for the running application.**

## Quick Validation Test

After creating `.dockerignore`:

```bash
# Test 1: Check what gets sent to Docker
docker build --progress=plain . 2>&1 | grep "transferring context"

# Test 2: Build and inspect final image
docker build -t test-image .
docker run --rm test-image find /app -name ".env*" -o -name "node_modules"
# Should return nothing if properly excluded
```

## Production Checklist

Before deploying, verify your `.dockerignore`:
- [ ] Excludes all secret files (.env*, *.key, etc.)
- [ ] Excludes development/test files
- [ ] Excludes large dependencies that will be installed fresh
- [ ] Excludes version control directories
- [ ] Includes all files needed for the application to run
- [ ] Results in reasonable context size (<10MB for typical apps)

---

**Next**: Making the crucial CMD vs ENTRYPOINT decision for different container scenarios.