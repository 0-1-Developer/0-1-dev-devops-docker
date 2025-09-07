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