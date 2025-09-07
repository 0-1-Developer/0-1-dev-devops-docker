# Phase 06: Docker Compose

> **Master multi-container application orchestration with Docker Compose for development and production environments**

## 🎯 Learning Outcomes

After completing this phase, you will be able to:
- Design and implement multi-service application stacks using Docker Compose
- Create environment-specific configurations for development, staging, and production
- Manage service dependencies, health checks, and startup ordering
- Implement secure secrets management and configuration patterns
- Optimize Docker Compose for different deployment scenarios
- Troubleshoot common multi-container application issues

## 📚 Concept Map

```
Docker Compose Orchestration
├── Service Definition & Architecture
│   ├── Service Modeling (Web, API, Database, Cache)
│   ├── Container Configuration (Images, Ports, Volumes)
│   ├── Resource Management (CPU, Memory, Replicas)
│   └── Network Architecture (Custom Networks, Isolation)
├── Multi-Environment Management
│   ├── Environment Profiles (dev, staging, production)
│   ├── Configuration Override Patterns
│   ├── Variable Substitution & Templates
│   └── Secrets and Sensitive Data Management
├── Service Dependencies & Health
│   ├── Startup Ordering (depends_on, conditions)
│   ├── Health Check Integration
│   ├── Rolling Updates & Zero-Downtime Deployments
│   └── Service Discovery & Inter-service Communication
├── Production Deployment Patterns
│   ├── Load Balancing & Reverse Proxy
│   ├── Data Persistence & Backup Strategies
│   ├── Monitoring & Logging Integration
│   └── CI/CD Pipeline Integration
└── Advanced Orchestration
    ├── Service Scaling & Load Distribution
    ├── Blue/Green Deployments
    ├── External Service Integration
    └── Performance Optimization
```

## 🔬 Core Topics

### 1. Multi-Service Architecture Design

**Orchestrating Complex Applications**

Docker Compose enables definition of multi-container applications as code:

- **Service Modeling**: Breaking applications into logical service components
- **Network Design**: Isolating services while enabling necessary communication
- **Data Management**: Persistent storage and data sharing between services
- **Configuration Management**: Environment variables, secrets, and config files

**Key Benefits**:
- Single command deployment and teardown
- Reproducible multi-service environments
- Environment-specific configurations
- Service dependency management

### 2. Environment Management

**Multi-Environment Deployment Strategy**

Production applications require different configurations across environments:

- **Development**: Live reload, debugging tools, local databases
- **Staging**: Production-like configuration with test data
- **Production**: Optimized performance, security, monitoring

**Critical Patterns**:
- Override files for environment-specific settings
- Variable substitution for dynamic configuration
- Secrets management for sensitive data
- Resource allocation per environment

### 3. Service Dependencies and Health

**Reliable Service Startup and Communication**

Complex applications require coordinated service startup:

- **Dependency Management**: Ensuring services start in correct order
- **Health Monitoring**: Detecting and responding to service failures
- **Service Discovery**: Enabling inter-service communication
- **Graceful Degradation**: Handling partial service failures

**Production Considerations**:
- Health check implementation
- Restart policies for resilience
- Service-to-service communication patterns
- Load balancing and failover strategies

### 4. Secrets and Configuration Security

**Secure Multi-Service Configuration**

Production environments require secure handling of sensitive data:

- **Secrets Management**: Passwords, API keys, certificates
- **Configuration Security**: Read-only configs, principle of least privilege
- **Environment Isolation**: Preventing configuration leakage
- **Audit and Compliance**: Tracking configuration changes

**Security Best Practices**:
- External secrets management integration
- Encrypted configuration files
- Runtime secret injection
- Regular security audits

## 🛠 Prerequisites

- **Completed**: Phase 05 (Storage & Volumes) - understanding of data persistence
- **Docker Compose**: Version 2.0+ with Compose specification support
- **YAML Knowledge**: Basic understanding of YAML syntax and structure
- **Multi-tier Architecture**: Understanding of web application tiers

## ⏱ Time Investment

- **Reading & Understanding**: 90 minutes
- **Hands-on Labs**: 180 minutes
- **Verification & Practice**: 60 minutes
- **Total**: ~5.5 hours

## 🎓 Learning Strategy

1. **Master Service Definition**: Learn to model applications as services
2. **Environment Management**: Create flexible multi-environment configs
3. **Dependency Orchestration**: Coordinate service startup and health
4. **Secrets Management**: Secure sensitive configuration data
5. **Production Deployment**: Apply compose patterns to real applications

## 📖 Topic Deep Dives

### Service Definition: Multi-Tier Application

**Classic Web Application Stack**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  # Frontend Load Balancer
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - frontend
    networks:
      - web-tier

  # Frontend Application
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
    environment:
      - API_URL=http://backend:8000/api
      - NODE_ENV=production
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - web-tier
      - app-tier

  # Backend API
  backend:
    build:
      context: ./backend
      target: production
    environment:
      - DATABASE_URL=postgresql://user:${DB_PASSWORD}@postgres:5432/app
      - REDIS_URL=redis://redis:6379
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - app-tier
      - data-tier

  # Database
  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    secrets:
      - db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - data-tier

  # Cache Layer
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - data-tier

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  web-tier:
    driver: bridge
  app-tier:
    driver: bridge
  data-tier:
    driver: bridge

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Environment-Specific Configurations

**Base Configuration + Environment Overrides**:

```yaml
# docker-compose.yml (base)
version: '3.8'

services:
  webapp:
    build: .
    environment:
      - ENV=development
    volumes:
      - .:/app
    networks:
      - app-network

  database:
    image: postgres:14
    environment:
      - POSTGRES_DB=myapp
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  db_data:

networks:
  app-network:
```

```yaml
# docker-compose.override.yml (development - applied automatically)
version: '3.8'

services:
  webapp:
    volumes:
      - .:/app:rw  # Live code reload
    environment:
      - DEBUG=true
      - LOG_LEVEL=debug
    ports:
      - "3000:3000"  # Expose for development

  database:
    ports:
      - "5432:5432"  # Direct database access for dev tools
    environment:
      - POSTGRES_PASSWORD=dev123  # Simple password for dev
```

```yaml
# docker-compose.prod.yml (production override)
version: '3.8'

services:
  webapp:
    restart: unless-stopped
    environment:
      - DEBUG=false
      - LOG_LEVEL=info
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  database:
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

  # Add production-specific services
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-prod.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - webapp

secrets:
  db_password:
    external: true
```

### Service Dependencies and Health Checks

**Dependency Orchestration Patterns**:
```yaml
version: '3.8'

services:
  # Database must be healthy before API starts
  api:
    build: ./api
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started  # Redis starts faster, doesn't need health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s  # Allow time for app initialization

  # Web frontend waits for API to be healthy
  web:
    build: ./frontend
    depends_on:
      api:
        condition: service_healthy
    ports:
      - "3000:3000"

  # Database with comprehensive health check
  postgres:
    image: postgres:14
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=secret
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # Cache service
  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  # Background worker depends on both database and message queue
  worker:
    build: ./worker
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    restart: unless-stopped

  # Message queue
  rabbitmq:
    image: rabbitmq:3-management-alpine
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
```

### Secrets Management Patterns

**Development Secrets (Simple)**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    environment:
      - DB_PASSWORD=dev123  # Simple for development
      - API_KEY=dev-key-123
```

**Production Secrets (Secure)**:
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password  # File-based secrets
      - API_KEY_FILE=/run/secrets/api_key
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt  # Local file (for single host)
    # OR
    external: true  # External secret management system
  
  api_key:
    external:
      name: production_api_key  # External secret name
```

**Environment Variable Substitution**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:${APP_VERSION:-latest}
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - LOG_LEVEL=${LOG_LEVEL:-info}
    ports:
      - "${APP_PORT:-3000}:3000"

  database:
    image: postgres:${POSTGRES_VERSION:-14}
    environment:
      - POSTGRES_DB=${DB_NAME:-myapp}
      - POSTGRES_USER=${DB_USER:-user}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
```

```bash
# .env file
APP_VERSION=v2.1.0
DATABASE_URL=postgresql://user:secret@localhost:5432/prod_db
LOG_LEVEL=warn
APP_PORT=8080
DB_NAME=production
DB_USER=produser
DB_PASSWORD=super-secret-password
```

## 🔍 Common Use Cases & Patterns

### Pattern 1: Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  # Development web server with hot reload
  webapp:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app:rw  # Source code volume for live reload
      - node_modules:/app/node_modules  # Prevent host node_modules conflicts
    environment:
      - NODE_ENV=development
      - DEBUG=true
    ports:
      - "3000:3000"  # Expose for browser access
      - "9229:9229"  # Debug port
    command: npm run dev

  # Development database with exposed port
  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=dev_db
      - POSTGRES_USER=dev_user
      - POSTGRES_PASSWORD=dev123
    ports:
      - "5432:5432"  # Expose for database tools
    volumes:
      - postgres_dev:/var/lib/postgresql/data
      - ./sql/seed.sql:/docker-entrypoint-initdb.d/seed.sql:ro

  # Redis for caching (development)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"  # Expose for Redis clients

volumes:
  node_modules:  # Named volume to avoid platform issues
  postgres_dev:
```

### Pattern 2: Production Deployment

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  # Production web application
  webapp:
    image: myapp:${TAG:-latest}
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL_FILE=/run/secrets/database_url
      - JWT_SECRET_FILE=/run/secrets/jwt_secret
    secrets:
      - database_url
      - jwt_secret
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
    networks:
      - app-tier

  # Production database
  postgres:
    image: postgres:14-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=production_db
      - POSTGRES_USER=prod_user
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_prod:/var/lib/postgresql/data
      - ./backups:/backups:rw
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U prod_user -d production_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - data-tier

  # Nginx reverse proxy
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-prod.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - webapp
    networks:
      - app-tier

  # Redis for production caching
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_prod:/data
    networks:
      - data-tier

volumes:
  postgres_prod:
    driver: local
    driver_opts:
      type: ext4
      device: /dev/sdb1
  redis_prod:
  nginx_logs:

networks:
  app-tier:
    driver: bridge
  data-tier:
    driver: bridge

secrets:
  database_url:
    external: true
  jwt_secret:
    external: true
  db_password:
    external: true
```

### Pattern 3: Microservices Architecture

```yaml
# docker-compose.microservices.yml
version: '3.8'

services:
  # API Gateway
  gateway:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./gateway.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - auth-service
      - user-service
      - order-service
    networks:
      - gateway-net

  # Authentication Service
  auth-service:
    build: ./services/auth
    environment:
      - JWT_SECRET=${JWT_SECRET}
      - DB_HOST=auth-db
    depends_on:
      auth-db:
        condition: service_healthy
    networks:
      - gateway-net
      - auth-net

  auth-db:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=auth
      - POSTGRES_USER=auth_user
      - POSTGRES_PASSWORD=${AUTH_DB_PASSWORD}
    volumes:
      - auth_db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U auth_user -d auth"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - auth-net

  # User Service
  user-service:
    build: ./services/users
    environment:
      - DB_HOST=user-db
      - AUTH_SERVICE_URL=http://auth-service:3000
    depends_on:
      user-db:
        condition: service_healthy
    networks:
      - gateway-net
      - user-net

  user-db:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=users
      - POSTGRES_USER=user_svc
      - POSTGRES_PASSWORD=${USER_DB_PASSWORD}
    volumes:
      - user_db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user_svc -d users"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - user-net

  # Order Service
  order-service:
    build: ./services/orders
    environment:
      - DB_HOST=order-db
      - USER_SERVICE_URL=http://user-service:3000
      - RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672
    depends_on:
      order-db:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    networks:
      - gateway-net
      - order-net
      - message-net

  order-db:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=orders
      - POSTGRES_USER=order_svc
      - POSTGRES_PASSWORD=${ORDER_DB_PASSWORD}
    volumes:
      - order_db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U order_svc -d orders"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - order-net

  # Message Queue
  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - message-net

volumes:
  auth_db:
  user_db:
  order_db:
  rabbitmq_data:

networks:
  gateway-net:
  auth-net:
  user-net:
  order-net:
  message-net:
```

## 💡 Production Considerations

### Resource Management and Scaling

```yaml
# Resource limits and reservations
version: '3.8'

services:
  webapp:
    image: myapp:latest
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

  database:
    image: postgres:14
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2.0'
        reservations:
          memory: 1G
          cpus: '1.0'
```

### Monitoring Integration

```yaml
version: '3.8'

services:
  # Application with monitoring
  webapp:
    image: myapp:latest
    environment:
      - METRICS_PORT=9090
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=9090"
      - "prometheus.io/path=/metrics"

  # Prometheus monitoring
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  # Grafana dashboards
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  prometheus_data:
  grafana_data:
```

### Backup and Recovery

```yaml
version: '3.8'

services:
  database:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups:rw

  # Automated backup service
  backup:
    image: postgres:14
    depends_on:
      - database
    volumes:
      - ./backups:/backups:rw
      - ./backup-scripts:/scripts:ro
    environment:
      - PGHOST=database
      - PGUSER=postgres
      - PGPASSWORD=${DB_PASSWORD}
    command: >
      sh -c "
        while true; do
          sleep 86400  # 24 hours
          pg_dump -h database -U postgres myapp > /backups/backup-$(date +%Y%m%d-%H%M%S).sql
          find /backups -name '*.sql' -mtime +7 -delete  # Keep 7 days
        done
      "
```

## 🚨 Common Compose Issues and Solutions

### Issue 1: Service Startup Race Conditions

**Problem**: Services fail because dependencies aren't ready
```yaml
# Problematic configuration
services:
  webapp:
    depends_on:
      - database  # Only waits for container to start, not be ready
```

**Solution**: Use health checks and conditions
```yaml
services:
  webapp:
    depends_on:
      database:
        condition: service_healthy
  
  database:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Issue 2: Environment Variable Conflicts

**Problem**: Variables not being substituted correctly
```bash
# Missing .env file or wrong variable names
docker-compose up  # Uses defaults or fails
```

**Solution**: Proper environment management
```yaml
# docker-compose.yml
services:
  webapp:
    image: myapp:${VERSION:-latest}
    environment:
      - API_URL=${API_URL:-http://localhost:8000}
```

```bash
# .env file
VERSION=v2.1.0
API_URL=https://api.production.com
```

### Issue 3: Volume Permission Issues

**Problem**: Permission denied errors in containers
```yaml
# Host volume mounted with wrong permissions
services:
  webapp:
    volumes:
      - ./app:/app  # May have permission issues
```

**Solution**: Use proper user mapping
```yaml
services:
  webapp:
    user: "1000:1000"  # Match host user
    volumes:
      - ./app:/app
    # OR use named volumes
    volumes:
      - app_data:/app/data
```

## Micro-Lessons

### Micro-Lesson 1: Service Modeling and Multi-Tier Architecture (3 minutes)
**Anchor**: `p06-m1-l1`

**Objective**: Design and deploy a multi-tier application stack using Docker Compose.

**Key Concepts**:
- Service definitions and dependencies
- Network isolation and communication
- Volume management across services
- Port mapping strategies

**Hands-On**:
```yaml
# docker-compose.yml - Multi-tier stack
version: '3.8'

services:
  # Frontend tier
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

  # Backend tier
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

  # Database tier
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

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access

volumes:
  db-data:
  app-logs:
```

**Practice Tasks**:
1. Deploy the multi-tier stack: `docker compose up -d`
2. Verify service communication: `docker compose exec api curl http://db:5432`
3. Test network isolation: `docker compose exec web ping db` (should fail)
4. Check volume persistence: `docker compose restart db && docker compose logs db`

**Production Notes**:
- Use internal networks to isolate database tier
- Implement proper health checks for all services
- Configure resource limits for production workloads
- Use named volumes for data persistence

---

### Micro-Lesson 2: Environment Profiles and Configuration Management (4 minutes)
**Anchor**: `p06-m2-l1`

**Objective**: Master environment-specific configurations using Docker Compose override files.

**Key Concepts**:
- Base configuration with overrides
- Environment variable substitution
- Profile-specific service modifications
- Configuration templating

**Hands-On**:
```yaml
# docker-compose.yml (base configuration)
version: '3.8'

services:
  app:
    image: myapp:${APP_VERSION:-latest}
    environment:
      - NODE_ENV=${ENVIRONMENT:-development}
      - DATABASE_URL=${DATABASE_URL}
      - LOG_LEVEL=${LOG_LEVEL:-info}
    ports:
      - "${APP_PORT:-3000}:3000"
    volumes:
      - app-data:/data

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: ${DB_NAME:-myapp}
      POSTGRES_USER: ${DB_USER:-user}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-password}
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  app-data:
  db-data:
```

```yaml
# docker-compose.dev.yml (development overrides)
version: '3.8'

services:
  app:
    build: .  # Build locally in development
    volumes:
      - ./src:/app/src:ro  # Live code reloading
      - ./public:/app/public:ro
    environment:
      - DEBUG=true
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port

  db:
    ports:
      - "5432:5432"  # Expose DB port for development tools
    environment:
      POSTGRES_DB: myapp_dev
```

```yaml
# docker-compose.prod.yml (production overrides)
version: '3.8'

services:
  app:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  db:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 512M
```

**Environment Files**:
```bash
# .env.dev
ENVIRONMENT=development
APP_VERSION=dev
APP_PORT=3000
DB_NAME=myapp_dev
LOG_LEVEL=debug

# .env.prod
ENVIRONMENT=production
APP_VERSION=v1.2.3
APP_PORT=80
DB_NAME=myapp_production
LOG_LEVEL=warn
DATABASE_URL=postgresql://produser:securepass@db:5432/myapp_production
```

**Practice Tasks**:
1. Deploy development: `docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml up -d`
2. Deploy production: `docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d`
3. Compare configurations: `docker compose config`
4. Test environment switching: Switch between dev and prod configs

**Production Notes**:
- Use external secrets management for sensitive values
- Validate environment files before deployment
- Implement configuration drift detection
- Use infrastructure as code for consistency

---

### Micro-Lesson 3: Dependencies, Health Checks, and Service Orchestration (5 minutes)
**Anchor**: `p06-m3-l1`

**Objective**: Implement robust service orchestration with dependency management and health monitoring.

**Key Concepts**:
- Service startup ordering
- Health check implementation
- Dependency condition handling
- Graceful shutdown procedures

**Hands-On**:
```yaml
# Advanced dependency management
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

**Advanced Health Check Strategies**:
```yaml
# Custom health check script
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

# Database with connection pool health
postgres:
  healthcheck:
    test: [
      "CMD-SHELL",
      "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB && \
       psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT 1' > /dev/null"
    ]
```

**Graceful Shutdown Configuration**:
```yaml
api:
  stop_signal: SIGTERM
  stop_grace_period: 30s
  init: true  # Handle zombie processes
```

**Practice Tasks**:
1. Deploy with dependency order: `docker compose up -d`
2. Monitor startup sequence: `docker compose logs -f --tail=0`
3. Test health checks: `docker compose ps` (check health status)
4. Simulate failure: `docker compose stop postgres` and observe cascade
5. Test recovery: `docker compose start postgres` and verify restoration

**Production Notes**:
- Implement circuit breaker patterns in application code
- Use proper signal handling for graceful shutdowns
- Monitor health check performance impact
- Configure appropriate timeouts for production latency

---

### Micro-Lesson 4: Secrets Management and Production Security (4 minutes)
**Anchor**: `p06-m4-l1`

**Objective**: Implement comprehensive secrets management and security hardening for production deployments.

**Key Concepts**:
- Docker secrets integration
- Security context configuration
- Runtime security hardening
- Secrets rotation strategies

**Hands-On**:
```yaml
# Production-hardened configuration with secrets
version: '3.8'

services:
  app:
    image: myapp:${APP_VERSION}
    user: "1001:1001"  # Non-root user
    read_only: true    # Read-only filesystem
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if binding to privileged ports
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/tmp:noexec,nosuid,size=50m
    volumes:
      - app-cache:/app/cache  # Writable cache directory
      - app-logs:/app/logs    # Writable logs directory
    environment:
      - NODE_ENV=production
      - PORT=8080
    secrets:
      - db_password
      - api_key
      - jwt_secret
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      - app-network

  db:
    image: postgres:15
    user: "999:999"  # Postgres user
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run/postgresql:noexec,nosuid,size=10m
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    command: [
      "postgres",
      "-c", "shared_preload_libraries=pg_stat_statements",
      "-c", "pg_stat_statements.track=all",
      "-c", "log_statement=mod",
      "-c", "log_min_duration_statement=1000"
    ]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - app-network

  # Security monitoring sidecar
  security-monitor:
    image: nginx:alpine
    read_only: true
    volumes:
      - ./security-headers.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "443:443"
      - "80:80"
    depends_on:
      - app
    networks:
      - app-network
    environment:
      - NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
    command: >
      sh -c "nginx -g 'daemon off;' & 
             while true; do 
               nginx -s reload; 
               sleep 3600; 
             done"

secrets:
  # External secrets (managed by Docker Swarm or external system)
  db_password:
    external: true
    name: myapp_db_password_v2
  
  api_key:
    external: true
    name: myapp_api_key_v1
  
  # File-based secrets (for development/testing)
  jwt_secret:
    file: ./secrets/jwt_secret.txt

networks:
  app-network:
    driver: bridge
    driver_opts:
      encrypted: "true"
    ipam:
      config:
        - subnet: 172.20.0.0/24

volumes:
  postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /secure/postgres-data
  app-cache:
  app-logs:
```

**Security Headers Configuration (nginx)**:
```nginx
# security-headers.conf
server {
    listen 80;
    listen 443 ssl;
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Remove server tokens
    server_tokens off;
    
    # Proxy to app
    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Security proxy headers
        proxy_hide_header X-Powered-By;
        proxy_hide_header Server;
    }
}
```

**Secrets Management Script**:
```bash
#!/bin/bash
# setup-secrets.sh

# Create secrets directory
mkdir -p ./secrets
chmod 700 ./secrets

# Generate secrets
echo "Creating production secrets..."
echo $(openssl rand -base64 32) > ./secrets/jwt_secret.txt
echo $(openssl rand -base64 16) > ./secrets/db_password.txt
echo $(openssl rand -hex 32) > ./secrets/api_key.txt

# Set proper permissions
chmod 600 ./secrets/*

# Create Docker secrets (if using Swarm)
if docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
    echo "Setting up Docker Swarm secrets..."
    docker secret create myapp_db_password_v2 ./secrets/db_password.txt
    docker secret create myapp_api_key_v1 ./secrets/api_key.txt
fi

echo "Secrets setup complete!"
```

**Practice Tasks**:
1. Setup secrets: `chmod +x setup-secrets.sh && ./setup-secrets.sh`
2. Deploy secure stack: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d`
3. Verify security: `docker compose exec app ls -la /run/secrets/`
4. Test read-only filesystem: `docker compose exec app touch /test` (should fail)
5. Check security headers: `curl -I http://localhost/`
6. Verify non-root user: `docker compose exec app whoami`

**Secrets Rotation Procedure**:
```bash
# 1. Generate new secret
echo $(openssl rand -base64 32) > ./secrets/jwt_secret_new.txt

# 2. Update secret reference
docker secret create myapp_jwt_secret_v2 ./secrets/jwt_secret_new.txt

# 3. Update compose file to reference new version
# 4. Rolling update
docker compose up -d --no-deps app

# 5. Remove old secret after verification
docker secret rm myapp_jwt_secret_v1
```

**Production Notes**:
- Integrate with enterprise secret management systems (Vault, AWS Secrets Manager)
- Implement secret rotation automation
- Use read-only filesystems and non-root users consistently
- Monitor for security violations and unauthorized access attempts
- Regular security audits and vulnerability scanning
## 🏁 Success Criteria

By the end of this phase, you should be able to:

- [ ] Design multi-service applications with proper service separation
- [ ] Create environment-specific Docker Compose configurations
- [ ] Implement proper service dependencies and health checking
- [ ] Manage secrets and sensitive configuration securely
- [ ] Deploy production-ready applications using Docker Compose
- [ ] Troubleshoot common multi-container application issues

## 📈 Progress Tracking

This phase contains 4 micro-lessons with anchors:
- `p06-m01-l01` - Service Modeling and Architecture Design
- `p06-m01-l02` - Environment Profiles and Configuration Management
- `p06-m01-l03` - Dependencies, Health Checks, and Service Orchestration
- `p06-m01-l04` - Secrets Management and Production Security

## 🎯 What's Next

After mastering Docker Compose:
- **Phase 07**: Security hardening and container security best practices
- **Phase 08**: CI/CD integration and build automation
- **Phase 09**: Registry management and image distribution

---

> 💡 **Key Insight**: Docker Compose transforms complex multi-container applications into manageable, reproducible deployments. Mastering service orchestration, environment management, and dependency coordination enables reliable application deployment across development, staging, and production environments. These skills form the foundation for container orchestration platforms like Kubernetes.