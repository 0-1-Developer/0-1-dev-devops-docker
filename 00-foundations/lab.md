# Phase 00: Foundations - Hands-On Labs

> **Learn by doing: Experience Docker fundamentals through practical exercises**

## 🎯 Lab Overview

These labs will give you hands-on experience with core Docker concepts. Complete them in order, as each builds understanding for the next.

**Total Lab Time**: ~90 minutes  
**Difficulty**: Beginner  
**Prerequisites**: Docker installed and running

## 🚀 Lab Setup

Before starting, verify your environment:

```bash
# Check Docker installation
docker --version
# Expected: Docker version 20.10.x or higher

# Check Docker daemon is running
docker ps
# Should show column headers, no errors

# Clean start (optional - removes all containers)
docker container prune -f
```

---

## 🧪 Lab 1: Image vs Container Exploration
**Time**: 20 minutes  
**Anchor**: `p00-m01-l01`

### Why It Matters
Understanding the relationship between images and containers is fundamental to everything else in Docker.

### What You'll Learn
- How to inspect images vs containers
- The relationship between templates and instances
- How containers add state to immutable images

### Try It

**Step 1: Pull and Inspect an Image**
```bash
# Pull a small image
docker pull alpine:3.18

# Inspect the image
docker image ls alpine:3.18
docker image inspect alpine:3.18 --format '{{.Size}}'

# How many layers does it have?
docker image history alpine:3.18
```

**Step 2: Create Multiple Containers**
```bash
# Create (but don't start) multiple containers from same image
docker create --name container1 alpine:3.18 echo "Hello from Container 1"
docker create --name container2 alpine:3.18 echo "Hello from Container 2"

# List all containers (including stopped)
docker ps -a

# Notice: same image, different container IDs
```

**Step 3: Start and Compare**
```bash
# Start both containers
docker start container1
docker start container2

# View their output
docker logs container1
docker logs container2

# Create a resource map (write this down!)
# Image: alpine:3.18 (size: ___ MB, layers: ___)
# Container1: ID=___, Status=___, Created=___
# Container2: ID=___, Status=___, Created=___
```

**Step 4: Modify Container State**
```bash
# Start an interactive container
docker run -it --name interactive alpine:3.18 sh

# Inside the container, create a file
echo "This file exists only in this container" > /tmp/myfile.txt
cat /tmp/myfile.txt
exit

# Start another container from the same image
docker run -it --name interactive2 alpine:3.18 sh

# Check if the file exists (it won't!)
cat /tmp/myfile.txt
# Expected: No such file or directory
exit
```

### Verify It
- [ ] You understand that images are templates, containers are instances
- [ ] You've seen that multiple containers can run from one image
- [ ] You've confirmed that container changes don't affect the image
- [ ] You've recorded the resource map in your notes

---

## 🧪 Lab 2: Lifecycle State Machine
**Time**: 25 minutes  
**Anchor**: `p00-m01-l02`

### Why It Matters
Knowing container states helps you troubleshoot issues and manage resources effectively.

### What You'll Learn
- The complete container lifecycle
- Legal state transitions
- How to move between states safely

### Try It

**Step 1: Create Without Starting**
```bash
# Create a container that will run for a while
docker create --name lifecycle-demo nginx:alpine

# Check its state
docker ps -a --filter name=lifecycle-demo
# Status should be "Created"
```

**Step 2: Progress Through States**
```bash
# Start the container
docker start lifecycle-demo
docker ps --filter name=lifecycle-demo
# Status should be "Up X seconds"

# Pause the container (freeze all processes)
docker pause lifecycle-demo
docker ps -a --filter name=lifecycle-demo
# Status should be "Up X seconds (Paused)"

# Unpause
docker unpause lifecycle-demo
docker ps --filter name=lifecycle-demo
# Status should be "Up X seconds" again

# Stop gracefully (sends SIGTERM, then SIGKILL)
docker stop lifecycle-demo
docker ps -a --filter name=lifecycle-demo
# Status should be "Exited (0) X seconds ago"

# Try to start again
docker start lifecycle-demo
docker ps --filter name=lifecycle-demo
# Should be running again
```

**Step 3: Test Idempotent Operations**
```bash
# Stop an already stopped container (should not error)
docker stop lifecycle-demo
docker stop lifecycle-demo
echo "No error - stop is idempotent"

# Start an already started container
docker start lifecycle-demo
docker start lifecycle-demo  
echo "No error - start is idempotent"

# Try to remove a running container
docker rm lifecycle-demo
# Expected: Error - cannot remove running container

# Force remove
docker rm -f lifecycle-demo
docker ps -a --filter name=lifecycle-demo
# Should show no results - container is gone
```

**Step 4: Lifecycle Timing**
```bash
# Create a container that runs briefly then exits
docker run --name short-lived alpine:3.18 echo "I run briefly"

# Check its final state
docker ps -a --filter name=short-lived
# Status should be "Exited (0)"

# Clean up
docker rm short-lived
```

### Verify It
- [ ] You can move containers through all lifecycle states
- [ ] You understand which operations are idempotent
- [ ] You know the difference between stop and remove
- [ ] You've seen graceful vs forced removal

---

## 🧪 Lab 3: Port Mapping & Network Boundaries  
**Time**: 25 minutes  
**Anchor**: `p00-m01-l03`

### Why It Matters
Port mapping is how containerized services communicate with the outside world.

### What You'll Learn
- How container networking differs from host networking
- Port publishing vs exposing
- Accessing services from inside vs outside containers

### Try It

**Step 1: Service Without Port Publishing**
```bash
# Start nginx without publishing ports
docker run -d --name no-ports nginx:alpine

# Try to access it from host
curl http://localhost:80
# Expected: Connection refused or similar

# Check what ports the container is using
docker port no-ports
# Should show no port mappings

# Check container's internal IP
docker inspect no-ports --format '{{.NetworkSettings.IPAddress}}'
# Note this IP (something like 172.17.0.x)

# Access via container IP (this works!)
CONTAINER_IP=$(docker inspect no-ports --format '{{.NetworkSettings.IPAddress}}')
curl http://$CONTAINER_IP:80
# Should show nginx welcome page
```

**Step 2: Service With Port Publishing**
```bash
# Remove the previous container
docker rm -f no-ports

# Start nginx with port publishing
docker run -d --name with-ports -p 8080:80 nginx:alpine

# Now access from host
curl http://localhost:8080
# Should show nginx welcome page

# Check port mappings
docker port with-ports
# Should show "80/tcp -> 0.0.0.0:8080"

# Try multiple mappings
docker run -d --name multi-ports -p 8081:80 -p 8443:443 nginx:alpine
docker port multi-ports
```

**Step 3: Resource Mapping Exercise**
```bash
# Start a more complex service
docker run -d --name resource-map \
  -p 9090:80 \
  -e NGINX_PORT=80 \
  --memory=128m \
  --cpus=0.5 \
  nginx:alpine

# Inspect resource allocations
docker stats --no-stream resource-map
docker inspect resource-map --format '{{.HostConfig.Memory}}'
docker inspect resource-map --format '{{.HostConfig.CpuShares}}'

# Create your resource map (write this down!):
# Host Port: 9090 → Container Port: 80
# Memory Limit: ___
# CPU Limit: ___
# Container IP: ___
# Host Access: http://localhost:9090
```

**Step 4: Network Boundary Testing**
```bash
# From inside the container, what can we see?
docker exec resource-map ps aux
# Should show nginx processes, not host processes

docker exec resource-map cat /proc/1/cgroup
# Shows container's process isolation

# From host, what can we see?
docker exec resource-map hostname
CONTAINER_HOSTNAME=$(docker exec resource-map hostname)
echo "Container hostname: $CONTAINER_HOSTNAME"
echo "Host hostname: $(hostname)"
# Should be different
```

### Verify It
- [ ] You understand the difference between container IP and published ports
- [ ] You can access services both ways (container IP and published port)
- [ ] You've documented the resource mapping for a complex container
- [ ] You understand host vs container namespace separation

---

## 🧪 Lab 4: Tags vs Digests in Practice
**Time**: 20 minutes  
**Anchor**: `p00-m01-l04`

### Why It Matters
Choosing the right image reference format affects reproducibility and security in production.

### What You'll Learn
- How tags can change over time
- When digests provide necessary immutability
- Practical scenarios for each approach

### Try It

**Step 1: Tag Mutability Demo**
```bash
# Pull nginx with different tags
docker pull nginx:latest
docker pull nginx:1.21
docker pull nginx:alpine

# Inspect their creation dates and digests
docker image ls nginx --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.Digest}}"

# Get the digest for nginx:latest
LATEST_DIGEST=$(docker image inspect nginx:latest --format '{{index .RepoDigests 0}}')
echo "nginx:latest digest: $LATEST_DIGEST"
```

**Step 2: Reference Format Comparison**
```bash
# Same image, different reference formats
docker run --name tag-ref nginx:alpine echo "Using tag"
docker run --name digest-ref $LATEST_DIGEST echo "Using digest"

# Both should work, but digest is immutable
docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"
```

**Step 3: Production Scenario Simulation**
```bash
# Simulate a production deployment
echo "# Production deployment using digest" > deployment.txt
echo "IMAGE_REF=$LATEST_DIGEST" >> deployment.txt
echo "# This will always pull the exact same image" >> deployment.txt

echo "" >> deployment.txt
echo "# Development deployment using tag" >> deployment.txt  
echo "IMAGE_REF=nginx:alpine" >> deployment.txt
echo "# This might pull a newer version over time" >> deployment.txt

cat deployment.txt
```

**Step 4: Digest Resolution**
```bash
# Show how tags resolve to digests
docker pull nginx:1.21 --quiet

# Get digest for this specific version
SPECIFIC_DIGEST=$(docker image inspect nginx:1.21 --format '{{index .RepoDigests 0}}')
echo "nginx:1.21 resolves to: $SPECIFIC_DIGEST"

# Demonstrate that digest pulls are faster (already have the layers)
time docker pull $SPECIFIC_DIGEST
# Should be very fast since we already have the image
```

### Verify It
- [ ] You understand that tags can change over time
- [ ] You know how to get the digest for any image
- [ ] You can choose the appropriate reference format for different scenarios
- [ ] You've created example deployment configs using both approaches

---

## 🧹 Lab Cleanup

After completing all labs:

```bash
# Remove all containers created in labs
docker rm -f container1 container2 interactive interactive2
docker rm -f lifecycle-demo with-ports multi-ports resource-map
docker rm -f tag-ref digest-ref short-lived no-ports

# Optional: Remove pulled images to save space
docker image rm alpine:3.18 nginx:alpine nginx:latest nginx:1.21

# Verify cleanup
docker ps -a
docker image ls
```

## 📝 Lab Summary

**What you accomplished:**
1. ✅ Explored the relationship between images and containers
2. ✅ Navigated the complete container lifecycle  
3. ✅ Mapped resources between host and container
4. ✅ Compared tags vs digests in practical scenarios

**Key insights gained:**
- Images are immutable templates; containers add mutable state
- Container lifecycle has predictable states and transitions
- Network boundaries require explicit port publishing
- Reference format choice affects reproducibility

**Real-world applications:**
- Debugging container startup issues (lifecycle knowledge)
- Designing service architectures (port mapping)
- Creating reproducible deployments (digest usage)
- Managing development vs production environments (tag vs digest strategy)

---

> 🎯 **Next**: With these foundations solid, you're ready for **Phase 01: Dockerfile Basics** where you'll learn to create your own images.