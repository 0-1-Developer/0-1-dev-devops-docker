# 📌 Part 4: Running Your First Docker Containers & Exploring CLI Commands

## 🎯 Goal:
Get comfortable using the Docker CLI to run containers, inspect them, interact with them, and manage their lifecycle.

---

## ✅ 4.1 Running a Simple Container

Start with the classic “Hello World” container:

```bash
docker run hello-world
```

### 🔍 What’s happening?

- Docker pulls the `hello-world` image from Docker Hub.
- Creates a new container from it.
- Runs the container.
- The container prints a message and exits.

✅ You just ran your first Docker container 🎉

---

## ✅ 4.2 Running an Ubuntu Container

Let’s launch a full Linux shell inside a container.

```bash
docker run -it ubuntu bash
```

### 🔍 What this does:

- `-it`: interactive terminal  
- `ubuntu`: image name  
- `bash`: the shell we want to start inside the container

You are now inside a running container! Try commands like:

```bash
ls
pwd
cat /etc/os-release
```

Exit the container by typing:

```bash
exit
```

---

## ✅ 4.3 Listing Containers

### 🔹 List running containers:

```bash
docker ps
```

### 🔹 List all containers (including stopped):

```bash
docker ps -a
```

Each container has:

- A unique Container ID  
- An Image name  
- Status (running, exited, etc.)

---

## ✅ 4.4 Stopping, Starting, Removing Containers

### 🔹 Stop a running container:

```bash
docker stop <container_id_or_name>
```

### 🔹 Start a stopped container:

```bash
docker start <container_id_or_name>
```

### 🔹 Remove a container:

```bash
docker rm <container_id_or_name>
```

💡 Use `docker ps -a` to get IDs or names.

---

## ✅ 4.5 Detached Containers

Run a container in the background using `-d` (detached mode):

```bash
docker run -d -p 8080:80 nginx
```

- `-p 8080:80`: maps your `localhost:8080` to the container’s port 80  
- `nginx`: lightweight web server image

Now visit:  
👉 [http://localhost:8080](http://localhost:8080)  
You should see the default Nginx welcome page.

Stop the container:

```bash
docker ps
docker stop <container_id>
```

---

## ✅ 4.6 Viewing Logs

To view logs of a running (or stopped) container:

```bash
docker logs <container_id_or_name>
```

---

## ✅ 4.7 Executing Commands in a Running Container

To run a command inside a running container:

```bash
docker exec -it <container_id_or_name> bash
```

This gives you a shell into the container (like SSH but for containers).

---

## 🧠 Hands-on Challenge

Try this mini workflow:

1. Run a new container from the alpine image (very small Linux):

```bash
docker run -it alpine sh
```

2. Install curl inside the container:

```sh
apk add curl
```

3. Use curl to fetch a page:

```sh
curl https://example.com
```

4. Exit the container:

```sh
exit
```

5. Check container history:

```bash
docker ps -a
docker logs <container_id>
```

---

## ⚠ Common Pitfalls

🔴 **"Port already in use" when using -p**  
✔ Use a different host port or stop conflicting services.

🔴 **"Command not found" inside minimal containers like alpine**  
✔ Use package managers like `apk`, `apt`, or `yum` depending on base image.

🔴 **Exited immediately after running**  
✔ You probably didn’t use an interactive shell (e.g., ran without `-it`).

---

## 🌍 Best Practices & Real-World Tips

✅ Use `--name <custom_name>` to give containers readable names.  
✅ Avoid using the `latest` tag in production unless you're sure.  
✅ Always clean up unused containers/images:

```bash
docker container prune
docker image prune
```
