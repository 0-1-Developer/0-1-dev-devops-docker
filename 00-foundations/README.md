# Phase 00: Foundations

> **Master the core concepts that underpin all Docker operations**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Explain the difference between images and containers with concrete examples
- Understand Docker's layered filesystem and how immutability works
- Map resources between host and container (ports, CPU, memory, filesystem)
- Choose between tags and digests for different use cases
- Navigate the complete container lifecycle with confidence

## 📚 Concept Map

```
Docker Foundations
├── Images vs Containers
│   ├── Templates vs Running Instances
│   ├── Immutable vs Mutable State
│   └── Relationship & Lifecycle
├── Image References
│   ├── Registry/Repository/Tag Format
│   ├── Digest-based References
│   └── When to Use Each
├── Container Lifecycle
│   ├── Create → Start → Stop → Remove
│   ├── State Transitions
│   └── Idempotent Operations
└── Resource Boundaries
    ├── Port Mapping (Host ↔ Container)
    ├── Filesystem Boundaries
    └── Process Isolation
```

## 🔬 Core Topics

### 1. Images vs Containers
**The Foundation of Everything**

- **Images**: Read-only templates containing application code, dependencies, and configuration
- **Containers**: Running instances of images with their own filesystem, network, and process space
- **Layer Architecture**: How Docker builds images incrementally using copy-on-write
- **Immutability**: Why images never change and what this means for reproducibility

### 2. Image References & Identification
**Precision in Addressing**

- **Registry Anatomy**: `registry.com/namespace/repository:tag`
- **Tags**: Human-readable labels (`latest`, `v1.2.3`, `alpine`)
- **Digests**: SHA256 hashes providing immutable references
- **Best Practices**: When tags suffice vs when digests are essential

### 3. Container Lifecycle Management
**From Creation to Cleanup**

- **Lifecycle States**: Created, Running, Paused, Stopped, Removed
- **State Transitions**: Legal paths between states
- **Idempotent Operations**: Commands that safely repeat
- **Resource Cleanup**: Preventing accumulation of stopped containers

### 4. Host-Container Resource Mapping
**Bridging Two Worlds**

- **Port Publishing**: Making container services accessible (`-p 8080:80`)
- **Filesystem Boundaries**: Container filesystem vs host filesystem
- **Process Isolation**: How containers see processes vs host reality
- **Network Interfaces**: Container IP vs host IP concepts

## 🛠 Prerequisites

- Docker 20.10+ installed and daemon running
- Basic command-line familiarity
- Understanding of processes and networking (basic level)

## ⏱ Time Investment

- **Reading & Understanding**: 45 minutes
- **Hands-on Labs**: 90 minutes  
- **Verification & Review**: 30 minutes
- **Total**: ~3 hours

## 🎓 Learning Strategy

1. **Read Each Topic Section**: Focus on understanding, not memorizing
2. **Complete All Labs**: Hands-on experience is crucial
3. **Run Verification Tests**: Confirm your understanding
4. **Review Pitfalls**: Learn from common mistakes
5. **Read Production Notes**: See how concepts apply in real systems

## 📖 Topic Deep Dives

### Images: The Blueprint

Think of Docker images like **classes** in programming:
- They define what something should be
- They're immutable once created
- You can create multiple instances (containers) from them
- Each instance can have different runtime state

**Key Insight**: Images are built in layers, where each layer represents a change. This enables:
- Efficient storage (shared layers)
- Fast distribution (download only changed layers)
- Reproducible builds (same inputs → same output)

### Containers: The Running Instance

Containers are like **objects** instantiated from classes:
- They have their own memory and state
- They can be started, stopped, and removed
- Multiple containers can run from the same image
- Each container gets its own filesystem overlay

**Key Insight**: Containers add a thin read-write layer on top of read-only image layers.

### References: Finding Your Way

Just like web URLs, Docker images have addresses:

```bash
# Full reference format
docker.io/library/nginx:1.21-alpine

# Registry: docker.io (Docker Hub)
# Namespace: library (official images)
# Repository: nginx
# Tag: 1.21-alpine
```

**Digests provide immutability**:
```bash
# Tag (mutable - can point to different image over time)
nginx:latest

# Digest (immutable - always points to same image)
nginx@sha256:abc123...
```

## 🔍 Common Misconceptions

❌ **"Containers are lightweight VMs"**  
✅ Containers share the host kernel and isolate processes, not full OS

❌ **"Tags are permanent"**  
✅ Tags can be moved to point to different images; use digests for immutability

❌ **"Container filesystem changes persist"**  
✅ Changes are lost when container is removed unless stored in volumes

❌ **"Port 8080 inside container is automatically accessible"**  
✅ Ports must be published (`-p 8080:80`) to be accessible from host

## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Explain image layers using a concrete example
- [ ] Distinguish between stopping and removing containers
- [ ] Predict when published ports will be accessible
- [ ] Choose appropriate reference format for different scenarios
- [ ] Draw a simple diagram showing host-container boundaries

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p00-m01-l01` - Image Reference Anatomy
- `p00-m01-l02` - Lifecycle Ordering Game  
- `p00-m01-l03` - Resource Mapping Sketch
- `p00-m01-l04` - Tags vs Digests Decision

## 🎯 What's Next

After mastering these foundations:
- **Phase 01**: Learn to create custom images with Dockerfiles
- **Phase 02**: Advanced build techniques with BuildKit
- **Phase 03**: Container runtime management and operations

---

> 💡 **Remember**: Every advanced Docker concept builds on these foundations. Take time to really understand them.