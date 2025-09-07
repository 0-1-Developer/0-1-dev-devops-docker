# Micro-Lesson 03: Dependencies, Health Checks, and Service Orchestration

> **Anchor**: `p06-m01-l03`  
> **Duration**: 5 minutes  
> **One Key Idea**: Implement robust service orchestration with dependency management and health monitoring

## Why It Matters

Services in multi-container applications often depend on each other. Without proper dependency management and health checks, services start in wrong order, fail unpredictably, and create cascading failures. Proper orchestration ensures reliable, predictable deployments.

## What to Learn

Master service orchestration fundamentals:
- **Service startup ordering** - Control initialization sequence
- **Health check implementation** - Monitor service readiness
- **Dependency condition handling** - Wait for services to be truly ready
- **Graceful shutdown procedures** - Handle service termination properly

## Advanced Dependency Management

### Complete Stack Configuration
```yaml
version: '3.8'

services:
  # Database - foundational service
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: securepass
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    networks:
      - backend

  # Redis cache - parallel dependency
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    networks:
      - backend

  # Migration service - runs once
  migrate:
    build: .
    command: npm run migrate
    environment:
      DATABASE_URL: postgresql://appuser:securepass@postgres:5432/myapp
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - backend
    restart: "no"  # Run once only

  # API service - depends on DB and cache
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgresql://appuser:securepass@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      migrate:
        condition: service_completed_successfully
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 15s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - backend
      - frontend
    restart: unless-stopped

  # Worker service - background processing
  worker:
    build: .
    command: npm run worker
    environment:
      DATABASE_URL: postgresql://appuser:securepass@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      api:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/worker/health"]
      interval: 30s
      timeout: 10s
      retries: 2
    networks:
      - backend
    restart: unless-stopped

  # Frontend - depends on API
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      api:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - frontend
    restart: unless-stopped

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  postgres-data:
  redis-data:
```

## Advanced Health Check Strategies

### Multi-Stage Health Verification
```yaml
api:
  healthcheck:
    test: [
      "CMD-SHELL",
      "curl -f http://localhost:8080/health && \
       curl -f http://localhost:8080/ready && \
       [ $(curl -s http://localhost:8080/metrics | grep 'app_healthy 1' | wc -l) -eq 1 ]"
    ]
    interval: 15s
    timeout: 10s
    retries: 3
    start_period: 60s
```

### Database Connection Pool Health
```yaml
postgres:
  healthcheck:
    test: [
      "CMD-SHELL",
      "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB && \
       psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT 1' > /dev/null"
    ]
```

## Graceful Shutdown Configuration
```yaml
api:
  stop_signal: SIGTERM
  stop_grace_period: 30s
  init: true  # Handle zombie processes
```

## Practice Tasks

1. **Deploy with dependency order**: `docker compose up -d`
2. **Monitor startup sequence**: `docker compose logs -f --tail=0`
3. **Test health checks**: `docker compose ps` (check health status)
4. **Simulate failure**: `docker compose stop postgres` and observe cascade
5. **Test recovery**: `docker compose start postgres` and verify restoration

## Production Notes

- Implement circuit breaker patterns in application code
- Use proper signal handling for graceful shutdowns
- Monitor health check performance impact
- Configure appropriate timeouts for production latency

## Key Takeaway

Proper dependency management with health checks ensures reliable service orchestration and prevents cascading failures in multi-container applications.