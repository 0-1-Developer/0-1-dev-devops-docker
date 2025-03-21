# 📌 Phase 2 – Part 7: Image Optimization Techniques (Size, Security, Prod-Readiness)

## 🎯 Goal:
Learn how to reduce image size, avoid unnecessary layers, eliminate security risks, and follow production best practices.

---

## ✅ 7.1 Why Optimize?

- ⬇️ **Smaller size** = faster build, pull, deploy  
- 🔐 **Fewer attack surfaces** = safer containers  
- 🚀 **Better performance** and **CI/CD efficiency**

---

## ✅ 7.2 Use Smaller Base Images

| Base Image | Size    |
|------------|---------|
| `ubuntu`   | ~29 MB  |
| `debian`   | ~22 MB  |
| `alpine`   | ~5 MB ✅✅✅ |

### 🔸 Example:

```dockerfile
FROM node:18-alpine
```

Alpine is a **minimal Linux distribution** — perfect for microservices.

💡 You may need to install packages with `apk` instead of `apt`.

---

## ✅ 7.3 Multi-Stage Builds 🏗️

A powerful technique to **separate build and runtime environments**.

### 🧱 Example: Node.js Multi-Stage Dockerfile

```dockerfile
# Stage 1: Builder
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Final Image
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm install --production

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### 🔍 Why it rocks:

- Keeps your **final image clean** (no source code or dev tools)  
- Avoids shipping unnecessary files  
- Smaller, safer production image

---

## ✅ 7.4 Use `.dockerignore`

Create a `.dockerignore` file (like `.gitignore`) to exclude unnecessary files from your image build context.

```text
node_modules
.git
Dockerfile
README.md
*.log
```

✅ Smaller build context  
✅ Faster builds  
✅ Better cache usage

---

## ✅ 7.5 Scan for Vulnerabilities

Use `docker scan` to check for security issues:

```bash
docker scan my-node-app
```

Or use tools like:

- **Snyk**  
- **Trivy**  
- **Grype**

---

## ✅ 7.6 Clean Up Temporary Files

Avoid leaving behind tools and cache.

### ❌ Don’t:

```dockerfile
RUN apk add build-base
```

### ✅ Do:

```dockerfile
RUN apk add --no-cache build-base && rm -rf /var/cache/apk/*
```

---

## 🛠 Hands-on Tasks

### ✅ Task 1: Convert to Alpine Base

- Switch your Dockerfile to use `node:18-alpine`  
- Test if everything still works

---

### ✅ Task 2: Create `.dockerignore`

- Add `node_modules`, `.git`, etc.  
- Rebuild and notice the faster context sending

---

### ✅ Task 3: Try Multi-Stage Build

- Add a simple `npm run build` to your app  
- Separate build from run stage in Dockerfile

---

## ⚠ Common Pitfalls

🔴 **Alpine missing packages**  
✔️ Use `apk` and install explicitly (e.g., `apk add curl`)

🔴 **Big image sizes**  
✔️ Use **multi-stage builds**, **slim base images**, and `.dockerignore`

🔴 **Dev-only dependencies in production**  
✔️ Use `npm install --production` or `pnpm install --prod`

---

## 💡 Best Practices

✅ Always use `.dockerignore`  
✅ Pin versions in `FROM` (e.g., `node:18.16-alpine`)  
✅ Clean up after installs  
✅ Scan images before pushing  
✅ Keep **production images minimal**
