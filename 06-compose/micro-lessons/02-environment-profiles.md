# Micro-Lesson 02: Environment Profiles and Configuration Management

> **Anchor**: `p06-m01-l02`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master environment-specific configurations using Docker Compose override files and variable substitution

## Why It Matters

Applications need different configurations for development, staging, and production environments. Hardcoded configurations lead to deployment errors, security issues, and maintenance nightmares. Environment profiles enable safe, repeatable deployments across different environments.

## What to Learn

Master environment-specific configuration patterns:
- **Base configuration with overrides** - Common configuration with environment-specific modifications
- **Environment variable substitution** - Dynamic configuration using variables
- **Profile-specific service modifications** - Different settings per environment
- **Configuration templating** - Reusable configuration patterns

## Base Configuration Pattern

### docker-compose.yml (Base)
```yaml
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

### docker-compose.dev.yml (Development Override)
```yaml
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

### docker-compose.prod.yml (Production Override)
```yaml
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

## Environment Files

### .env.dev
```bash
ENVIRONMENT=development
APP_VERSION=dev
APP_PORT=3000
DB_NAME=myapp_dev
LOG_LEVEL=debug
```

### .env.prod
```bash
ENVIRONMENT=production
APP_VERSION=v1.2.3
APP_PORT=80
DB_NAME=myapp_production
LOG_LEVEL=warn
DATABASE_URL=postgresql://produser:securepass@db:5432/myapp_production
```

## Practice Tasks

1. **Deploy development**: `docker compose --env-file .env.dev -f docker-compose.yml -f docker-compose.dev.yml up -d`
2. **Deploy production**: `docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d`
3. **Compare configurations**: `docker compose config`
4. **Test environment switching**: Switch between dev and prod configs

## Production Notes

- Never commit sensitive environment files to version control
- Use external secrets management for production secrets
- Implement configuration drift detection
- Use infrastructure as code for consistency

## Key Takeaway

Environment profiles with Docker Compose enable safe, consistent deployments across different environments using base configurations with environment-specific overrides.