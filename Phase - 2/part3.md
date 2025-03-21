# 📌 Phase 2 – Part 3: Pulling & Exploring Images from Docker Hub

## 🎯 Goal:
Learn how to pull, explore, and understand public Docker images from Docker Hub — the central registry where most container images live.

---

## ✅ 3.1 What is Docker Hub?

Docker Hub is like **GitHub for container images**.

📌 It’s the **default registry** Docker pulls from when you run:

```bash
docker run nginx
```

That actually pulls:

```bash
docker pull docker.io/library/nginx:latest
```

### 🔹 Types of Images on Docker Hub:

- **Official Images** (maintained by Docker or trusted maintainers): `nginx`, `mysql`, `python`  
- **Community Images** (by users/organizations): `bitnami/nginx`, `rakeshreddynv/myapp`  
- **Private Repositories** (you can host your own)

👉 Visit: [https://hub.docker.com](https://hub.docker.com)

---

## ✅ 3.2 Pulling an Image Manually

```bash
docker pull node:18
```

You can also pull the Alpine variant:

```bash
docker pull node:18-alpine
```

💡 This downloads the image **without running it**.

---

## ✅ 3.3 Exploring Image Metadata

### 🔸 List All Local Images

```bash
docker images
```

---

### 🔸 Inspect Image (Detailed Metadata)

```bash
docker inspect node:18-alpine
```

Check fields like:

- `Architecture`  
- `Os`  
- `RootFS`  
- `Env`  
- `ContainerConfig`

---

### 🔸 View Image History (Layer Breakdown)

```bash
docker history node:18-alpine
```

You’ll see:

- Commands that created each layer (`RUN`, `COPY`)  
- Layer sizes  
- Layer timestamps  

---

### 🔸 Check for Vulnerabilities (Optional)

```bash
docker scan node:18-alpine
```

👉 Docker Desktop includes `docker scan` using **Snyk** to check for security issues

---

## 🛠 Hands-on Tasks

### ✅ Task 1: Pull 3 Images

```bash
docker pull ubuntu
docker pull nginx
docker pull redis
```

---

### ✅ Task 2: Explore One of Them (e.g. nginx)

```bash
docker inspect nginx
docker history nginx
docker image ls
```

---

### ✅ Task 3: Run & Explore Inside

```bash
docker run -it nginx bash
```

📝 Some minimal images (like Alpine or Nginx) may not include bash. Try `sh` if needed:

```bash
docker run -it nginx sh
```

Then run:

```bash
ls
cat /etc/nginx/nginx.conf
```

---

## ⚠ Common Pitfalls

🔴 **Image already exists? Still tries to pull?**  
✔️ Use `--pull always` if you want the freshest copy, or remove the old one with:

```bash
docker rmi nginx
```

🔴 **Missing shell in minimal images**  
✔️ Use `sh` instead of `bash`, or test with Alpine-based variants

---

## 💡 Best Practices

✅ Prefer **official images** for production and learning  
✅ Use **tags** to pin exact versions (e.g., `nginx:1.25.0` instead of `latest`)  
✅ Always review the **Dockerfile** and documentation on Docker Hub
