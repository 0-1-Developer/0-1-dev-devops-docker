# 📌 Phase 2 – Part 1: What Are Docker Images?

## 🎯 Goal:
Understand what a Docker image is, how it's structured, and why it forms the foundation of every container.

---

## ✅ 1.1 What is a Docker Image?

A Docker image is a **read-only template** that contains:

- Your application code  
- Dependencies and libraries  
- Environment configuration  
- A minimal OS layer (like Alpine, Debian, Ubuntu)  

**Think of it as a blueprint for containers.**

💡 _"An image is to a container what a class is to an object in OOP."_

---

## 📦 Image to Container Flow

1. You build an image (or pull one from Docker Hub)  
2. Docker uses that image to start a container  
3. The container is a live, running instance of the image  

---

## ✅ 1.2 What's Inside an Image?

A Docker image is made up of **stacked layers**:

- Each command in a `Dockerfile` creates a new layer  
- Layers are cached and shared between images  
- This makes image building efficient and fast

### Example layer breakdown:

```dockerfile
FROM node:18-alpine         ← base layer  
COPY . /app                 ← adds files  
RUN npm install             ← installs deps  
CMD ["node", "index.js"]    ← default command  
```

Each of those is a **filesystem layer**, stacked on top of the previous.

---

## ✅ 1.3 Docker Image Properties

| Property     | Description                                      |
|--------------|--------------------------------------------------|
| Immutable    | Once built, it doesn’t change                    |
| Portable     | Can run on any machine with Docker               |
| Reusable     | Share via Docker Hub or registries              |
| Versioned    | Can tag and maintain multiple versions           |

---

## 🛠 Hands-on Tasks

### 🔹 Task 1: Pull an Image

```bash
docker pull node:18-alpine
```

---

### 🔹 Task 2: Explore the Image

```bash
docker image ls
docker image inspect node:18-alpine
```

Look at the JSON output — it includes:

- Layers  
- Created  
- Size  
- Env  
- Architecture  

---

### 🔹 Task 3: History of an Image

```bash
docker history node:18-alpine
```

This shows the **layer-by-layer build steps**.

---

### 🔹 Task 4: Create a Container from Image

```bash
docker run -it node:18-alpine sh
```

You’re now **inside the image's file system as a container!**

---

## ⚠ Common Pitfalls

🔴 **Confusing image vs container**  
✔ Remember:  
- Image = code + environment + OS snapshot  
- Container = a live instance of an image

🔴 **Huge images due to unnecessary base layers**  
✔ We'll cover how to fix this in later parts (optimization)

---

## 💡 Best Practices

✅ Use official images when possible (`python`, `node`, `alpine`, etc.)  
✅ Prefer slim or alpine variants for production  
✅ Always check the image size and history  
✅ Avoid unnecessary layers when writing Dockerfiles

---

## 🔄 Real-World Use Cases

- CI/CD pipelines build and push images on every commit  
- Kubernetes pods run containers from these images  
- Production workloads are version-controlled and isolated through images

---

## ✅ Summary

| Term       | You should now know:                        |
|------------|---------------------------------------------|
| Image      | Read-only app blueprint                     |
| Container  | Running instance of an image                |
| Layers     | Stackable file system layers                |
| Inspect / History | Explore metadata and build steps     |
