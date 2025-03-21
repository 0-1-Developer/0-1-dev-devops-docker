# 📌 Part 2: Introduction to Docker & Its Architecture

## 🎯 Goal:
Understand how Docker works under the hood—what it’s made of, how it runs containers, and what role each part of the architecture plays.

---

## ✅ 2.1 What is Docker?

Docker is an open-source platform that enables developers to build, package, and run applications in containers.

🔹 **Think of it as**:  
A lightweight shipping container system for your code — it includes your app, libraries, configs, and dependencies in one package, so it runs anywhere, anytime, the same way.

---

## ✅ 2.2 Docker Components

Docker's architecture follows a client-server model, made up of 3 main components:

### 🔸 1. Docker CLI (Client)
The command-line interface (`docker`) that sends commands to the Docker daemon.

**Example:**
```bash
docker run ubuntu
```
➡️ This tells Docker daemon to pull the `ubuntu` image (if not already available) and run a container from it.

---

### 🔸 2. Docker Daemon (`dockerd`)
A background service running on your machine.  
It listens to requests from the Docker CLI and manages containers, images, volumes, and networks.

- Accepts REST API requests from the CLI  
- Creates, runs, stops containers  
- Communicates with other Docker daemons (for Swarm mode)

---

### 🔸 3. Docker Images & Containers

#### 🧱 Docker Image:
A read-only template with everything your app needs (code, dependencies, OS packages).  
**Think of an image as a blueprint.**

#### 📦 Docker Container:
A runtime instance of an image. It’s where your app actually runs.  
**Think of a container as a running house built from the blueprint (image).**

---

### 🔸 4. Docker Hub (or Registry)

A cloud-based repository for Docker images.  
You can push and pull images (just like GitHub for code).

**Example:**
```bash
docker pull nginx
```

---

### 🔸 5. Docker Engine

The core of Docker, includes the Docker daemon, REST API, and CLI tools.  
It is responsible for the full lifecycle of containers:

- Building  
- Running  
- Distributing

---

## 🧠 Simplified Architecture Flow

```text
You (CLI)
   |
   v
Docker Client ------> Docker Daemon ------> Container Runtime (runs containers)
                             |
                             v
                       Docker Hub / Registry
```

---

## 🛠 Hands-on Tasks

### 🔹 Task 1: Check Docker Version

```bash
docker --version
docker info
```

You’ll see details about your Docker Engine and system.

---

### 🔹 Task 2: Run & Observe Docker Daemon

Run a container and observe what happens:

```bash
docker run -it ubuntu bash
```

Then in a new terminal:

```bash
docker ps
```

This shows active containers – Docker daemon is keeping track of them.

---

### 🔹 Task 3: Visualize Architecture with Commands

```bash
docker images      # List all downloaded images
docker ps -a       # Show all containers
docker network ls  # View Docker networks
docker volume ls   # View Docker volumes
```

---

## ⚠ Common Pitfalls & Debugging Tips

🔴 **“Cannot connect to the Docker daemon”**  
✔️ Ensure it’s running:

```bash
systemctl status docker
```

🔴 **“Permission denied” (Linux only)**  
✔️ Add yourself to the docker group:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

🔴 **Confused between image and container?**  
✔️ Remember:

- Image = Blueprint  
- Container = Running instance

---

## 🌍 Best Practices & Real-World Use Cases

✅ Use Docker CLI daily to interact with containers.  
✅ Learn to inspect images, logs, and running containers using CLI.  
✅ Most CI/CD pipelines use Docker (GitHub Actions, GitLab CI).  
✅ Microservices are built using containerized applications.