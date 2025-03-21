# 📌 Part 6: Docker CLI Essentials (Summary & Cheat Sheet)

## 🎯 Goal:
Reinforce your understanding of Docker's core commands and concepts. This will serve as your go-to cheat sheet as you continue into more advanced topics.

---

## ✅ 6.1 Essential Docker Commands

### 🔹 📦 Images

| Command                        | Description                          |
|-------------------------------|--------------------------------------|
| `docker pull <image>`         | Download an image from Docker Hub    |
| `docker images`               | List all images on your system       |
| `docker rmi <image_id>`       | Remove an image                      |

---

### 🔹 🚀 Containers

| Command                          | Description                          |
|----------------------------------|--------------------------------------|
| `docker run <image>`            | Run a container from an image        |
| `docker run -it <image>`        | Run interactively with terminal      |
| `docker run -d <image>`         | Run in detached/background mode      |
| `docker ps`                     | Show running containers              |
| `docker ps -a`                  | Show all containers                  |
| `docker stop <id>`              | Stop a container                     |
| `docker start <id>`             | Start a stopped container            |
| `docker rm <id>`                | Remove a container                   |

---

### 🔹 🧠 Inside Containers

| Command                              | Description                            |
|--------------------------------------|----------------------------------------|
| `docker exec -it <id> bash`         | Run a shell inside a container         |
| `docker attach <id>`               | Attach to running container            |
| `docker logs <id>`                 | Show container logs                    |

---

### 🔹 🧼 Cleanup

| Command                    | Description                            |
|---------------------------|----------------------------------------|
| `docker container prune` | Remove stopped containers              |
| `docker image prune`     | Remove unused images                   |

---

## ✅ 6.2 Key Concepts Recap

| Concept       | Meaning                                         |
|---------------|-------------------------------------------------|
| **Image**     | Read-only template used to create containers    |
| **Container** | A runnable instance of an image                 |
| **Dockerfile**| File to define how to build an image            |
| **Docker Hub**| Public image registry                           |
| **Daemon**    | Docker service running in the background        |
| **CLI**       | The command-line interface for Docker           |

---

## ✅ 6.3 What You've Mastered in Phase 1

✅ What containerization is and why it matters  
✅ Docker architecture: client, daemon, images, containers  
✅ Installed and verified Docker  
✅ Ran containers in interactive and detached modes  
✅ Used Docker CLI to manage containers  
✅ Explored logs, networking, terminal access, and cleanup
