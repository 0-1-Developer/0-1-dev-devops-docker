# Micro-Lesson 04: Tags vs Digests Decision Tree

> **Anchor**: `p00-m01-l04`  
> **Duration**: 4 minutes  
> **One Key Idea**: Choose image references based on whether you need mutability or immutability

## Why It Matters

Wrong reference choice leads to:
- **Development**: Stale images that don't update
- **Production**: Unexpected changes that break deployments
- **Security**: Inability to pin exact versions for auditing

## What to Learn

**Tags** are mutable pointers:
- `nginx:latest` can point to different images over time
- Convenient for development
- Risky for production

**Digests** are immutable identifiers:
- `nginx@sha256:abc123...` always points to same image
- Required for reproducible deployments
- Harder to read but completely reliable

## Decision Tree

```
Do you need the EXACT same image every time?
    │
    ├── YES → Use Digest
    │   └── nginx@sha256:abc123def456...
    │
    └── NO → Use Tag
        └── nginx:1.21-alpine
```

## When to Use Tags

✅ **Development environment**
```bash
# Want to get updates automatically
docker pull nginx:latest
```

✅ **Version ranges**  
```bash
# Want patch updates but not major changes
docker pull node:18-alpine
```

✅ **Local experimentation**
```bash
# Convenience over precision
docker run -it python:3.11 bash
```

## When to Use Digests

✅ **Production deployments**
```bash
# Exactly reproducible
docker pull nginx@sha256:abc123def456...
```

✅ **Security scanning**
```bash  
# Scan specific image, not moving target
docker scan nginx@sha256:abc123def456...
```

✅ **Compliance requirements**
```bash
# Audit trail needs exact versions
docker run --name audit nginx@sha256:abc123def456...
```

## Try It - Tag to Digest Conversion

**Step 1**: Get digest for any tag
```bash
docker pull nginx:alpine
docker image inspect nginx:alpine --format '{{index .RepoDigests 0}}'
```

**Step 2**: Use the digest
```bash
# Copy the digest from above and use it
DIGEST="nginx@sha256:..." # paste actual digest here
docker run --rm $DIGEST nginx -v
```

## Real-World Example

**Development `docker-compose.yml`**:
```yaml
services:
  web:
    image: nginx:alpine  # Get updates
  db:  
    image: postgres:13   # Major version pinning
```

**Production `docker-compose.yml`**:
```yaml
services:
  web:
    image: nginx@sha256:abc123...  # Exact reproducibility  
  db:
    image: postgres@sha256:def456...  # No surprises
```

## The Hybrid Approach

Many teams use this workflow:

1. **Develop** with tags: `nginx:alpine`
2. **Test** by getting digest: `docker image inspect nginx:alpine`  
3. **Deploy** with digest: `nginx@sha256:abc123...`
4. **Update** by repeating the cycle

## Common Mistake

❌ Using `latest` in production
```yaml
# Dangerous - image can change anytime
image: nginx:latest
```

✅ Pin to specific version
```yaml  
# Better - semantic versioning
image: nginx:1.21-alpine

# Best - immutable digest
image: nginx@sha256:abc123def456...
```

## The Trade-offs

| Aspect | Tags | Digests |
|--------|------|---------|
| **Readability** | High (`nginx:alpine`) | Low (`nginx@sha256:abc...`) |
| **Convenience** | High | Low |
| **Reproducibility** | Low | Perfect |
| **Security** | Variable | Fixed |
| **Updates** | Automatic | Manual |

## The Rule to Remember

> **Development uses tags for convenience, production uses digests for reliability**

## Quick Decision Helper

Ask yourself:
- "If this image changes tomorrow, will it break things?" 
  - **Yes** → Use digest
  - **No** → Tag is fine

- "Do I need to audit exactly what's running?"
  - **Yes** → Use digest  
  - **No** → Tag is fine

## Pro Tip

Save commonly used digests:
```bash
# In your project's .env file
NGINX_DIGEST=nginx@sha256:abc123def456...
POSTGRES_DIGEST=postgres@sha256:def456abc123...
```

---

**Congratulations!** You've completed all Phase 00 micro-lessons. You now understand the foundational concepts that underpin all Docker operations.