# Micro-Lesson 01: Image Reference Anatomy

> **Anchor**: `p00-m01-l01`  
> **Duration**: 3 minutes  
> **One Key Idea**: Docker image references follow a hierarchical naming pattern

## Why It Matters

Understanding image reference anatomy prevents confusion when pulling images, enables you to find the right images quickly, and helps you understand where images come from.

## What to Learn

Docker image references have up to 4 components:
- **Registry**: Where the image is stored
- **Namespace/User**: Who owns the image  
- **Repository**: The image name
- **Tag**: The specific version

## The Pattern

```
[registry]/[namespace]/repository[:tag]
```

## Examples Breakdown

### Official Image (Short Form)
```bash
nginx:alpine
```
- Registry: `docker.io` (implied)
- Namespace: `library` (implied for official images)
- Repository: `nginx`
- Tag: `alpine`

**Full form**: `docker.io/library/nginx:alpine`

### User Image
```bash
myusername/myapp:latest
```
- Registry: `docker.io` (implied)
- Namespace: `myusername`
- Repository: `myapp`  
- Tag: `latest`

### Private Registry
```bash
myregistry.com/team/backend:v2.1.0
```
- Registry: `myregistry.com`
- Namespace: `team`
- Repository: `backend`
- Tag: `v2.1.0`

## Try It (30 seconds)

```bash
# Pull an image and see the full reference
docker pull nginx:alpine
docker image ls nginx
# Notice how Docker shows the full reference
```

## The Rule to Remember

> **When registry or namespace is missing, Docker assumes Docker Hub official images**

## Common Pitfall

❌ Thinking `nginx` and `nginx:latest` are different  
✅ They're the same - `:latest` is implied when no tag specified

## Quick Quiz

What's the full reference for `ubuntu`?

<details>
<summary>Answer</summary>
`docker.io/library/ubuntu:latest`
</details>

---

**Next**: Understanding how multiple containers can run from the same image template.