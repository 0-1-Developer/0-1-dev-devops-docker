# Micro-Lesson: Secret Lifecycle Mapping

**Anchor**: `p02-m01-l02`  
**Duration**: 4 minutes  
**Objective**: Map secret needs to secure BuildKit handling patterns

## 🎯 Core Concept

**Secrets have lifecycles**: Understand *when* and *where* you need secrets during build, then choose the right BuildKit mechanism to provide them without leakage.

## 🔄 Secret Lifecycle Phases

### 1. **Need Assessment**
- When do I need this secret? (Build-time vs Runtime)
- Where do I need it? (Which stage, which instruction)
- How long do I need it? (Single command vs multiple steps)

### 2. **Access Pattern**
- **File-based**: Secret as a file (keys, certificates)
- **Environment-based**: Secret as variable (API keys, tokens)
- **Command-based**: Secret passed to specific command

### 3. **Cleanup Requirement**
- Must never appear in image layers
- Must not persist after build instruction
- Must not leak through error messages or logs

## 🛠 BuildKit Secret Patterns

### Pattern 1: File-Based Secrets
```dockerfile
# ❌ Traditional (INSECURE)
COPY private.key /tmp/key
RUN curl --key /tmp/key https://private-repo.com/package.tar.gz
RUN rm /tmp/key  # TOO LATE - already in layer

# ✅ BuildKit (SECURE)  
RUN --mount=type=secret,id=private-key,target=/tmp/key \
    curl --key /tmp/key https://private-repo.com/package.tar.gz
# Secret disappears automatically after RUN
```

### Pattern 2: Environment Secrets
```dockerfile
# ❌ Traditional (INSECURE)
ENV API_KEY=super-secret-123  # Visible in history forever

# ✅ BuildKit (SECURE)
RUN --mount=type=secret,id=api-key,env=API_KEY \
    curl -H "Authorization: Bearer $API_KEY" https://api.private.com/data
# Environment variable exists only during RUN
```

### Pattern 3: SSH Agent Forwarding
```dockerfile
# For Git operations requiring authentication
RUN --mount=type=ssh \
    git clone git@github.com:private/repo.git
# SSH agent access, no keys in image
```

## 📋 Secret Mapping Worksheet

For each secret in your build:

| Secret | Type | When Needed | Pattern | Mount Target |
|--------|------|-------------|---------|--------------|
| DB Password | Env Var | Build config | `env=DB_PASS` | N/A |
| SSH Key | File | Git clone | `target=/root/.ssh/id_rsa` | File path |
| API Token | Env Var | Download deps | `env=TOKEN` | N/A |
| Certificate | File | TLS setup | `target=/tmp/cert.pem` | File path |

## 🔒 Security Verification

After implementing secret mounts, verify zero leakage:

```bash
# Check image history
docker history your-image | grep -i secret
# Should return nothing

# Check image layers  
docker save your-image | tar -tv | grep -i secret
# Should return nothing

# Check running container
docker run --rm your-image env | grep -i secret
# Should return nothing (unless intentionally set for runtime)
```

## ⚡ Quick Decision Tree

```
Do I need this secret?
├─ At build time only
│  ├─ As a file → --mount=type=secret,target=path
│  └─ As env var → --mount=type=secret,env=VAR
├─ At runtime only  
│  └─ Use docker run -e or ENV (separate from build secrets)
└─ Both build and runtime
   └─ Use BuildKit secret for build, separate runtime config
```

## 🚨 Common Anti-Patterns

❌ **Secret in ARG**:
```dockerfile
ARG SECRET_KEY  # Visible in docker history
```

❌ **Secret in ENV for build**:
```dockerfile  
ENV API_KEY=secret  # Persists in final image
```

❌ **COPY then RUN rm**:
```dockerfile
COPY .env .
RUN source .env && curl ...
RUN rm .env  # Secret already in layer
```

## 💡 Best Practices

✅ **Minimal scope**: Only mount secrets for instructions that need them  
✅ **Specific targets**: Use precise file paths or environment variable names  
✅ **External management**: Keep secrets outside the build context  
✅ **Verification**: Always verify no secret leakage after build

## 🎓 Practice Challenge

Identify secrets in your current build process:
1. List every secret, token, key, or password
2. Map each to build-time vs runtime need
3. Choose appropriate BuildKit secret pattern
4. Plan verification steps for each

Remember: **If a secret touches your build, it should never touch your image layers.**