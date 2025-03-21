# 📌 Phase 2 – Part 8: Dockerize a Real App (Mini Project)

## 🎯 Goal:
Apply everything you’ve learned by building, optimizing, and running a real-world containerized app using Docker.

---

## 🧱 Project Overview: Node.js API

Let’s go with a **Node.js Express API** for this walkthrough.  
We’ll:

- Write a basic app  
- Dockerize it  
- Optimize the Dockerfile  
- Add `.dockerignore`  
- Tag and run it locally  
- (Optional) Push it to Docker Hub

---

## ✅ 1. App Structure

```
my-api/
├── Dockerfile
├── .dockerignore
├── package.json
├── app.js
```

---

## ✅ 2. `app.js`

```js
const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.json({ message: "Hello from Dockerized API!" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

---

## ✅ 3. `package.json`

```json
{
  "name": "my-api",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

---

## ✅ 4. Dockerfile (Optimized with Alpine)

```dockerfile
# Stage 1: Base image
FROM node:18-alpine AS base

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

---

## ✅ 5. `.dockerignore`

```dockerignore
node_modules
npm-debug.log
Dockerfile
.dockerignore
.git
```

---

## 🛠 6. Build & Tag Image

```bash
docker build -t my-api:1.0.0 .
```

---

## ▶️ 7. Run the Container

```bash
docker run -d -p 3000:3000 my-api:1.0.0
```

Then visit 👉 [http://localhost:3000](http://localhost:3000)

You should see:

```json
{ "message": "Hello from Dockerized API!" }
```

---

## 🧪 8. Test & Explore

```bash
docker ps
docker logs <container_id>
docker exec -it <container_id> sh
```

---

## 🏁 Optional: Push to Docker Hub

```bash
docker tag my-api:1.0.0 rakeshreddynv/my-api:1.0.0
docker push rakeshreddynv/my-api:1.0.0
```

---

## ⚠ Common Pitfalls

🔴 **Port not exposed**  
✔️ Use `EXPOSE` in Dockerfile and `-p` when running

🔴 **Missing packages**  
✔️ Check `npm install` inside the container or use multi-stage if needed

🔴 **Too large image**  
✔️ Use **Alpine base**, `.dockerignore`, and clean layers

