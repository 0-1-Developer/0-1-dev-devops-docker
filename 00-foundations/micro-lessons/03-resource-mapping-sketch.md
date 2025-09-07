# Micro-Lesson 03: Resource Mapping Sketch

> **Anchor**: `p00-m01-l03`  
> **Duration**: 5 minutes  
> **One Key Idea**: Containers have their own isolated resources that can be selectively bridged to the host

## Why It Matters

Resource mapping confusion is the #1 cause of "Why can't I access my container?" issues. Understanding the boundaries helps you design accessible services.

## What to Learn

Containers get their own isolated:
- **Network stack** (IP address, ports, interfaces)
- **Process space** (PID 1, process tree)
- **Filesystem** (root filesystem, mount points)

Host access requires **explicit bridging** through:
- **Port publishing** (`-p host:container`)
- **Volume mounts** (`-v host:container`)
- **Network modes** (host, bridge, custom)

## Mental Model: Two Worlds

```
HOST WORLD                    CONTAINER WORLD
┌─────────────────────────┐    ┌─────────────────┐
│ IP: 192.168.1.100       │    │ IP: 172.17.0.2  │
│ Port 8080: [listening]  │◄──►│ Port 80: nginx  │
│                         │    │                 │
│ /home/user/html/        │◄──►│ /usr/share/html/│
│                         │    │                 │
│ PID 1: systemd         │    │ PID 1: nginx    │
│ PID 1234: firefox      │    │ PID 23: worker  │
└─────────────────────────┘    └─────────────────┘
        ▲                              ▲
        │                              │
    Host resources              Container resources
```

## Resource Mapping Examples

### Port Mapping
```bash
# Container port 80 → Host port 8080
docker run -p 8080:80 nginx

# Access: http://localhost:8080 → reaches nginx inside container
```

### Multiple Port Mapping  
```bash
# Map multiple ports
docker run -p 8080:80 -p 8443:443 nginx

# Host 8080 → Container 80 (HTTP)  
# Host 8443 → Container 443 (HTTPS)
```

### No Port Mapping (Internal Only)
```bash
# Container has IP but no published ports
docker run nginx

# Accessible only via container IP: 172.17.0.x:80
# NOT accessible via localhost
```

## Try It - Resource Sketch Exercise

**Step 1**: Run a container and gather resource info
```bash
docker run -d --name resource-demo -p 9090:80 nginx
```

**Step 2**: Fill in this sketch
```
HOST RESOURCES:
- Host IP: ___________
- Published Port: 9090
- Access URL: http://localhost:9090

CONTAINER RESOURCES:  
- Container IP: ___________ (find with: docker inspect)
- Internal Port: 80
- Process Tree: ___________ (find with: docker exec ... ps aux)

MAPPINGS:
- Host 9090 ↔ Container 80
- Host filesystem ↔ Container filesystem: ___________
```

**Step 3**: Test both access methods
```bash
# Method 1: Published port
curl http://localhost:9090

# Method 2: Container IP (find IP first)
CONTAINER_IP=$(docker inspect resource-demo --format '{{.NetworkSettings.IPAddress}}')
curl http://$CONTAINER_IP:80
```

## Common Boundary Confusion

❌ **Wrong assumption**: "Container port 80 is automatically available on host port 80"  
✅ **Reality**: Ports must be explicitly published with `-p`

❌ **Wrong assumption**: "Files I create in container persist on host"  
✅ **Reality**: Container filesystem is isolated unless volumes are mounted

❌ **Wrong assumption**: "Container sees all host processes"  
✅ **Reality**: Container only sees its own process tree

## The Mapping Rules

1. **Default**: Container resources are isolated
2. **Bridge with flags**: Use `-p`, `-v`, `--network` to connect worlds  
3. **Direction matters**: Host port → Container port (not bidirectional by default)
4. **One-to-one mapping**: Each host port can map to only one container port

## Production Note

In production:
- Use specific port mappings, avoid `-P` (publish all)
- Map only necessary ports to minimize attack surface
- Use health checks that test the mapped ports, not internal ones

## Quick Self-Test

Without running commands, predict what happens:

```bash
docker run -p 3000:8080 myapp
```

- Can you access via `localhost:3000`? **Yes/No**
- Can you access via `localhost:8080`? **Yes/No**  
- What port is the app listening on inside the container? **Answer**

<details>
<summary>Answers</summary>

- localhost:3000: **Yes** (host port 3000 maps to container port 8080)
- localhost:8080: **No** (no mapping from host 8080)
- Inside container: **8080** (app listens on container port 8080)

</details>

---

**Next**: Understanding when to use tags vs digests for image references.