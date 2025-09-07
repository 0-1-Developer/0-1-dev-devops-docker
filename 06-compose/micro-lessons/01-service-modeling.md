# Micro-Lesson 01: Service Modeling and Multi-Tier Architecture

> **Anchor**: `p06-m01-l01`  
> **Duration**: 3 minutes  
> **One Key Idea**: Design multi-tier applications with proper service separation and network isolation

## Why It Matters

Multi-service applications require careful service modeling to ensure proper separation of concerns, secure communication, and maintainable architecture. Poor service design leads to tight coupling, security vulnerabilities, and operational complexity.

## What to Learn

Master multi-tier service design principles:
- **Service definitions and dependencies** - Define clear service boundaries
- **Network isolation and communication** - Secure inter-service communication
- **Volume management across services** - Shared and isolated data storage
- **Port mapping strategies** - Expose only necessary ports

## Multi-Tier Stack Implementation

### Frontend Tier
```yaml
web:
  image: nginx:alpine
  ports:
    - "80:80"
  depends_on:
    - api
  networks:
    - frontend
    - backend
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
```

### Backend Tier
```yaml
api:
  build: ./api
  environment:
    - DATABASE_URL=postgresql://user:pass@db:5432/app
  depends_on:
    db:
      condition: service_healthy
  networks:
    - backend
  volumes:
    - app-logs:/var/log/app
```

### Database Tier
```yaml
db:
  image: postgres:15
  environment:
    POSTGRES_DB: app
    POSTGRES_USER: user
    POSTGRES_PASSWORD: pass
  volumes:
    - db-data:/var/lib/postgresql/data
  networks:
    - backend
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U user"]
    interval: 10s
    timeout: 5s
    retries: 3
```

### Network Configuration
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

## Practice Tasks

1. **Deploy the multi-tier stack**: `docker compose up -d`
2. **Verify service communication**: `docker compose exec api curl http://db:5432`
3. **Test network isolation**: `docker compose exec web ping db` (should fail)
4. **Check volume persistence**: `docker compose restart db && docker compose logs db`

## Production Notes

- Use internal networks to isolate database tier
- Implement proper health checks for all services
- Configure resource limits for production workloads
- Use named volumes for data persistence

## Key Takeaway

Multi-tier architecture with Docker Compose enables secure, scalable service separation with proper network isolation and dependency management.