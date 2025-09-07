# Micro-Lesson: Restart Policy Selection Matrix

**Anchor**: `p03-m01-l02`  
**Duration**: 3 minutes  
**Objective**: Choose the optimal restart policy based on service type and operational requirements

## 🎯 Core Concept

**Different services need different restart strategies**. The restart policy should match your service's role, failure characteristics, and operational requirements. One size does not fit all.

## 🔄 The Four Restart Policies

### `no` - Manual Control
```bash
docker run --restart no my-app
```
**Behavior**: Never restart automatically
**When container stops**: It stays stopped until manually restarted

### `always` - Maximum Availability
```bash
docker run --restart always my-app
```
**Behavior**: Always restart, regardless of exit code
**When container stops**: Restarts immediately (any reason)

### `on-failure` - Smart Recovery
```bash
docker run --restart on-failure:5 my-app
```
**Behavior**: Only restart on non-zero exit codes
**When container stops**: Restarts only on crashes/errors, max 5 attempts

### `unless-stopped` - Production Balance
```bash
docker run --restart unless-stopped my-app
```
**Behavior**: Always restart except when manually stopped
**When container stops**: Restarts except after `docker stop`

## 📊 Selection Matrix

| Service Type | Recommended Policy | Reasoning |
|--------------|-------------------|-----------|
| **Web Application** | `unless-stopped` | Should survive crashes but respect maintenance stops |
| **Database** | `unless-stopped` | Critical service that should auto-recover |
| **Load Balancer** | `unless-stopped` | Infrastructure service requiring high availability |
| **Background Worker** | `on-failure:3` | Should retry failed jobs but not restart on normal completion |
| **Batch Job** | `on-failure:2` | Should retry on errors but stop on successful completion |
| **One-time Script** | `no` | Should run once and stop, no automatic restarts |
| **Development Container** | `no` | Manual control for debugging and development |
| **System Service** | `always` | Critical system component that must always be running |

## ⚡ Decision Tree

```
What type of workload is this?

├─ Long-running service (web app, database, API)
│  ├─ Should it respect manual stops? 
│  │  ├─ Yes → unless-stopped
│  │  └─ No → always
│  
├─ Job/Task processor
│  ├─ Should it retry on failure?
│  │  ├─ Yes → on-failure:N
│  │  └─ No → no
│  
├─ One-time task (migration, backup)
│  └─ no
│  
├─ Development/Testing
│  └─ no
│  
└─ Critical system component
   └─ always
```

## 🛠 Real-World Examples

### Web Service Configuration
```bash
# Production web application
docker run -d \
  --name web-app \
  --restart unless-stopped \
  -p 8080:8080 \
  my-web-app:latest
```
**Why `unless-stopped`**: 
- Survives crashes and system reboots
- Allows planned maintenance with `docker stop`
- Doesn't restart after deliberate shutdowns

### Background Worker Configuration  
```bash
# Job processing worker
docker run -d \
  --name job-worker \
  --restart on-failure:3 \
  job-processor:latest
```
**Why `on-failure:3`**:
- Retries failed jobs (network issues, temporary errors)
- Doesn't restart when shutting down gracefully  
- Limits retry attempts to prevent infinite loops

### Database Configuration
```bash
# Production database
docker run -d \
  --name postgres-db \
  --restart unless-stopped \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:13
```
**Why `unless-stopped`**:
- Database should survive crashes
- Allows controlled maintenance shutdowns
- Prevents data corruption from unexpected restarts

### Development Environment
```bash
# Development container
docker run -it \
  --name dev-env \
  --restart no \
  -v $(pwd):/workspace \
  node:18-alpine sh
```
**Why `no`**:
- Developer wants manual control
- Container exit often intentional
- Debugging requires predictable behavior

## 📈 Restart Policy Behavior Comparison

| Scenario | `no` | `always` | `on-failure` | `unless-stopped` |
|----------|------|----------|--------------|------------------|
| Exit code 0 (success) | Stop | ↻ Restart | Stop | Stop |
| Exit code 1 (error) | Stop | ↻ Restart | ↻ Restart | ↻ Restart |  
| `docker stop` | Stop | ↻ Restart | Stop | Stop |
| System reboot | Stop | ↻ Restart | ↻ Restart* | ↻ Restart |
| Docker daemon restart | Stop | ↻ Restart | ↻ Restart* | ↻ Restart |

*Only restarts if last exit was due to failure

## 🚨 Common Mistakes

❌ **Using `always` for everything**:
```bash
# This makes maintenance difficult
docker run --restart always batch-job
# Job finishes successfully but immediately restarts!
```

❌ **Using `no` for services**:
```bash
# Service dies and stays dead
docker run --restart no web-service
# One crash = total outage
```

❌ **Wrong retry limits**:
```bash
# Too many retries for flaky service
docker run --restart on-failure:50 unreliable-service
# This could restart for hours on a persistent issue
```

✅ **Better approach**:
```bash
# Match policy to service type
docker run --restart unless-stopped web-service    # Service
docker run --restart on-failure:3 batch-job       # Task  
docker run --restart no debug-container           # Development
```

## 🔧 Advanced Restart Configuration

### Exponential Backoff
Docker automatically implements exponential backoff:
- 1st restart: Immediate  
- 2nd restart: ~1 second delay
- 3rd restart: ~2 second delay
- 4th restart: ~4 second delay
- Maximum delay: ~1 minute

### Monitoring Restart Events
```bash
# Watch restart events
docker events --filter event=restart

# Check restart count
docker inspect container_name | jq '.RestartCount'

# Check restart policy
docker inspect container_name | jq '.HostConfig.RestartPolicy'
```

### Changing Restart Policy
```bash
# Update existing container's restart policy
docker update --restart unless-stopped container_name
```

## 💡 Production Tips

**Service Discovery Integration**:
- Use health checks with restart policies
- Ensure services re-register after restarts
- Consider startup time in dependency chains

**Monitoring and Alerting**:
- Alert on high restart counts
- Track restart reasons (exit codes)
- Monitor restart frequency patterns

**Container Orchestration**:
- Kubernetes/Swarm have their own restart policies
- Docker restart policies still apply at container level
- Orchestrator policies typically override Docker policies

## 🎓 Quick Assessment

For each scenario, choose the best restart policy:

1. **E-commerce API serving customer requests**
   - Answer: `unless-stopped` (service needs high availability but should respect maintenance)

2. **Image processing worker that processes uploaded files**
   - Answer: `on-failure:3` (should retry failed processing but stop on completion)

3. **Database migration script**
   - Answer: `no` (one-time task, shouldn't restart after completion)

4. **Redis cache server**
   - Answer: `unless-stopped` (infrastructure service needs high availability)

**Rule of thumb**: Services get `unless-stopped`, jobs get `on-failure:N`, one-time tasks get `no`.