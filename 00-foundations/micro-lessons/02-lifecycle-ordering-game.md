# Micro-Lesson 02: Lifecycle Ordering Game

> **Anchor**: `p00-m01-l02`  
> **Duration**: 4 minutes  
> **One Key Idea**: Container states follow predictable transitions with specific allowed paths

## Why It Matters

Knowing the container lifecycle helps you debug issues, manage resources effectively, and avoid commands that will fail.

## What to Learn

Container states and their allowed transitions:
- **Created** → Can start or remove
- **Running** → Can stop, pause, or force remove  
- **Paused** → Can unpause or force remove
- **Stopped** → Can start or remove

## The State Machine

```
    Created ──start──→ Running ──stop──→ Stopped
       │                 │                │
       │                 │                │
    remove            pause            start
       │                 │                │
       ▼                 ▼                │
    Removed            Paused ────────────┘
                          │
                       unpause
                          │
                          ▼
                       Running
```

## Try It - Ordering Challenge

**Scenario**: You want to go from "nonexistent" to "running" to "cleaned up"

Put these commands in the correct order:
- `docker rm mycontainer`
- `docker create --name mycontainer nginx`  
- `docker start mycontainer`

<details>
<summary>Correct Order</summary>

1. `docker create --name mycontainer nginx` (nonexistent → created)
2. `docker start mycontainer` (created → running)
3. `docker rm -f mycontainer` (running → removed)

</details>

## Legal vs Illegal Transitions

✅ **Legal Paths**:
- Created → Running (`start`)
- Running → Paused (`pause`)
- Paused → Running (`unpause`)
- Running → Stopped (`stop`)
- Stopped → Running (`start`)

❌ **Illegal Direct Paths**:
- Created → Paused (must run first)
- Paused → Stopped (must unpause first)
- Running → Removed without force (must stop first)

## Try It (1 minute)

```bash
# Create and watch state transitions
docker create --name lifecycle nginx
docker ps -a --filter name=lifecycle
# Status: Created

docker start lifecycle  
docker ps --filter name=lifecycle
# Status: Running

docker pause lifecycle
docker ps --filter name=lifecycle  
# Status: Paused

# Cleanup
docker rm -f lifecycle
```

## Idempotent Commands

Some commands are **idempotent** (safe to repeat):
- `docker stop stopped-container` ✅ (no error)
- `docker start running-container` ✅ (no error)

Others are **not idempotent**:
- `docker create --name same-name ...` ❌ (name conflict)
- `docker rm running-container` ❌ (must stop first or use `-f`)

## The Rule to Remember

> **Always know your container's current state before issuing commands**

Use `docker ps -a` to check state before acting.

## Production Note

In production, always use health checks and restart policies rather than manual state management. The lifecycle knowledge helps when debugging issues.

## Quick Mental Model

Think of containers like **TV states**:
- Created = TV plugged in but off
- Running = TV on and playing
- Paused = TV on but frozen  
- Stopped = TV off but plugged in
- Removed = TV unplugged and put away

---

**Next**: Learning how containers map resources to the host system.