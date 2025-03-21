# 📌 Phase 2 – Part 5: Building, Tagging & Naming Images

## 🎯 Goal:
Understand how to build Docker images properly, tag them effectively, and follow naming conventions for versioning, clarity, and CI/CD pipelines.

---

## ✅ 5.1 Building Docker Images

The most basic build command:

```bash
docker build -t myapp .
```

### 🔍 Breakdown:

- `docker build` – instructs Docker to start building  
- `-t myapp` – gives the image a name (tagged)  
- `.` – build context (the folder containing the Dockerfile and app files)

---

## ✅ 5.2 Image Naming Format

```bash
<registry>/<username_or_org>/<repo>:<tag>
```

### Examples:

```bash
my-node-app                      # local image  
my-node-app:1.0                  # local image with version tag  
rakeshreddynv/my-node-app        # Docker Hub repo format  
rakeshreddynv/my-node-app:prod-1.2
```

If you **don’t specify a tag**, Docker uses `:latest` by default.

---

## ✅ 5.3 Tagging Images

```bash
docker tag myapp rakeshreddynv/myapp:1.0.0
```

### ✅ Use tags to:

- Track versions  
- Differentiate between dev, test, and prod  
- Make CI/CD builds predictable and rollback-able

---

## ✅ 5.4 Listing & Inspecting Tags

### 🔸 See local images:

```bash
docker images
```

### 🔸 Inspect a specific image:

```bash
docker inspect myapp:1.0
```

---

## ✅ 5.5 Pushing to Docker Hub (Optional for now)

If you want to try pushing a custom image to your Docker Hub account:

### 🔸 Step 1: Login

```bash
docker login
```

### 🔸 Step 2: Tag & Push

```bash
docker tag my-node-app rakeshreddynv/my-node-app:1.0.0
docker push rakeshreddynv/my-node-app:1.0.0
```

Your image will be available at:  
👉 [https://hub.docker.com/r/rakeshreddynv/my-node-app](https://hub.docker.com/r/rakeshreddynv/my-node-app)

---

## 🛠 Hands-on Challenge

### ✅ Build a custom image with a versioned tag

```bash
docker build -t my-node-app:1.0.0 .
```

---

### ✅ Tag it for Docker Hub (even if you don’t push)

```bash
docker tag my-node-app:1.0.0 rakeshreddynv/my-node-app:prod-1.0
```

---

### ✅ List and inspect your images

```bash
docker images
docker inspect my-node-app:1.0.0
```

---

## ⚠ Common Pitfalls

🔴 **Using `latest` tag for everything**  
✔️ Avoid it in production — always use explicit tags

🔴 **Forgot to tag at build time**  
✔️ No problem — use `docker tag` afterward to fix it

🔴 **Wrong registry URL when pushing**  
✔️ Docker Hub images are tagged as `username/image:tag` (no domain needed)

---

## 💡 Best Practices

✅ Always tag your images with **version + environment** (`1.0.0`, `prod`, `dev`, etc.)  
✅ Automate tagging in CI pipelines (`build-<timestamp>`, `commit-hash`)  
✅ Keep `latest` only for local testing  
✅ Use **semantic versioning** if possible (`1.0.0`, `1.1.0`, etc.)
