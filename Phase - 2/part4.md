# 📌 Phase 2 – Part 4: Writing Dockerfiles (Base Images, Layers, and Commands)

## 🎯 Goal:
Understand what a Dockerfile is, how to write one from scratch, and how it builds an image layer by layer.

---

## ✅ 4.1 What is a Dockerfile?

A **Dockerfile** is a plain-text script with instructions Docker uses to build an image.  
Think of it as a **recipe** for constructing your custom image.

- Docker reads this file from top to bottom  
- Each instruction creates a **new image layer**

---

## ✅ 4.2 Core Dockerfile Instructions

| Instruction   | Purpose                                      |
|---------------|----------------------------------------------|
| `FROM`        | Set the base image                           |
| `RUN`         | Execute shell commands (e.g., install packages) |
| `COPY`        | Copy files from local to image               |
| `WORKDIR`     | Set the working directory                    |
| `ENV`         | Define environment variables                 |
| `EXPOSE`      | Document which port app listens on           |
| `CMD`         | Default command when the container starts    |
| `ENTRYPOINT`  | Like CMD, but harder to override (used for scripts) |

---

## ✅ 4.3 Minimal Dockerfile Example (Node.js)

Create this in a folder (e.g., `my-node-app/`) with `app.js` inside:

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

---

## 🛠 Hands-on Task: Create & Build Your First Dockerfile

### 🔹 Step 1: Create a Simple Node.js App

**my-node-app/app.js**

```js
const http = require("http");

const server = http.createServer((req, res) => {
  res.end("Hello from Docker!");
});

server.listen(3000, () => console.log("Server running on port 3000"));
```

**my-node-app/package.json**

```json
{
  "name": "docker-test",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  }
}
```

---

### 🔹 Step 2: Write the Dockerfile in `my-node-app/`

Use the example Dockerfile from above ⬆️

---

### 🔹 Step 3: Build the Image

```bash
cd my-node-app
docker build -t my-node-app .
```

- `-t my-node-app`: tags your image with the name  
- `.`: current directory is the build context

---

### 🔹 Step 4: Run the Container

```bash
docker run -p 3000:3000 my-node-app
```

Visit 👉 [http://localhost:3000](http://localhost:3000)  
You should see: **"Hello from Docker!"**

---

## 🔄 How Docker Builds Layers

```dockerfile
FROM node:18-alpine      # Layer 1  
WORKDIR /app             # Layer 2  
COPY package*.json ./    # Layer 3  
RUN npm install          # Layer 4  
COPY . .                 # Layer 5  
EXPOSE 3000              # Layer 6  
CMD ["node", "app.js"]   # Layer 7  
```

Each instruction = a **layer**  
👉 Layers are **cached**, so if only your code changes, `npm install` isn’t re-run

---

## ⚠ Common Pitfalls

🔴 **COPY fails due to missing context**  
✔️ Always run `docker build` from the folder containing the Dockerfile.

🔴 **node_modules not found inside container**  
✔️ Be sure you copied `package*.json` before `RUN npm install`

🔴 **Port not working**  
✔️ Use `EXPOSE` in Dockerfile and `-p 3000:3000` at runtime

---

## 💡 Best Practices

✅ Use `.dockerignore` to avoid copying unwanted files (`node_modules`, `.git`)  
✅ Group `COPY` and `RUN` logically to optimize caching  
✅ Pin your base image version (`node:18-alpine`)  
✅ Use **multi-stage builds** for production (coming soon)
