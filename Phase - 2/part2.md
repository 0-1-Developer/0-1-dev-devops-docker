# 📌 Phase 2 – Part 2: Image vs Container (Deep Dive & Lifecycle)

## 🎯 Goal:
Understand the difference between Docker images and containers, how they relate, and how the lifecycle of a container works — from creation to destruction.

---

## ✅ 2.1 Key Differences

| Feature     | Docker Image             | Docker Container                  |
|-------------|---------------------------|-----------------------------------|
| **Nature**  | Static / Read-only        | Dynamic / Runtime                 |
| **Purpose** | Blueprint for a container | Actual running app                |
| **Persistence** | Doesn’t change unless rebuilt | Can change (data, state)     |
| **Storage** | Stored in Docker registry or local | Lives on host while running |
| **State**   | Stateless                 | Has a running or exited state     |

---

## ✅ 2.2 Analogy

💡 Think of an image like a **movie file (.mp4)**, and a container like the **movie playing in a media player**.

- You can run multiple containers from the same image (like playing the same movie on different screens)  
- Containers can be **short-lived** (CLI tool) or **long-running** (web servers)

---

## ✅ 2.3 Container Lifecycle

Let’s understand how a container flows through its lifecycle with real commands:

```text
+-------------+     docker create     +-------------+     docker start     +-------------+
|    Image    |  ------------------>  |  Container  |  ------------------> |  Running    |
+-------------+                       +-------------+                     +-------------+
                                         |                                        |
                                         |      docker stop                       |
                                         v                                        |
                                   +-------------+     docker rm      <----------+
                                   |   Exited    |  ----------------->
                                   +-------------+
```

---

## 🛠 Hands-on Task: Lifecycle in Action

### 🔹 Step 1: Pull and Inspect Image

```bash
docker pull alpine
docker image inspect alpine
```

---

### 🔹 Step 2: Create a Container (but don’t start it)

```bash
docker create --name demo alpine
```

Check its status:

```bash
docker ps -a
```

---

### 🔹 Step 3: Start the Container

```bash
docker start demo
```

---

### 🔹 Step 4: Run a Command in It

```bash
docker exec demo echo "Hi from container"
```

---

### 🔹 Step 5: Stop the Container

```bash
docker stop demo
```

---

### 🔹 Step 6: Remove the Container

```bash
docker rm demo
```

---

### 🔹 Step 7: Create + Run (shortcut)

```bash
docker run --name quick-demo alpine echo "Quick run"
```

This runs, prints the message, and exits immediately.

---

## ✅ Bonus: Run Multiple Containers from the Same Image

```bash
docker run -dit --name web1 nginx
docker run -dit --name web2 nginx
```

Both use the same image, but are **independent containers**.

---

## ⚠ Common Pitfalls

🔴 **Trying to change an image by modifying a container**  
✔️ Changes made inside a container don’t affect the image unless you create a new image with `docker commit` (not recommended for most workflows)

🔴 **Container disappears after it exits**  
✔️ Use `docker ps -a` to see all containers, even stopped ones.

🔴 **Re-using container names**  
✔️ Container names must be unique unless you delete the old one.

---

## 💡 Best Practices

✅ Don’t modify containers directly — rebuild images instead  
✅ Use `--name` to give containers meaningful names  
✅ Use `docker inspect` to debug containers/images  
✅ Use `docker ps -a` to see the full picture
