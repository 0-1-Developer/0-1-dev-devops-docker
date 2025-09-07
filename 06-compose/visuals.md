# Phase 06: Docker Compose - Visual Learning Guide

## Overview
Visual representations and diagrams to understand Docker Compose orchestration, service relationships, and deployment patterns.

## Visual 1: Docker Compose Stack Architecture
**Anchor**: `p06-visual-stack-architecture`

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Frontend  │    │   Backend   │    │  Database   │         │
│  │  (React)    │    │  (Node.js)  │    │ (PostgreSQL)│         │
│  │   Port:3000 │◄──►│   Port:8080 │◄──►│   Port:5432 │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│         │                   │                   │              │
│         └───────────────────┼───────────────────┘              │
│                             │                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                Network: app-network                     │    │
│  │  - Frontend: web                                        │    │
│  │  - Backend: api                                         │    │
│  │  - Database: db                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Volumes                              │    │
│  │  - db-data: /var/lib/postgresql/data                    │    │
│  │  - app-logs: /var/log/app                               │    │
│  │  - uploads: /app/uploads                                │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Service communication through Docker networks
- Named volumes for data persistence
- Port mapping for external access
- Service interdependencies

## Visual 2: Environment Profile Management
**Anchor**: `p06-visual-environment-profiles`

```
┌──────────────────────────────────────────────────────────────────┐
│                    Environment Profiles                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Development Environment                                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ docker-compose.yml (base)                                  │  │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │ │     web     │  │     api     │  │     db      │         │  │
│  │ │  debug:on   │  │ hot-reload  │  │ local-data  │         │  │
│  │ └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                            │  │
│  │ + docker-compose.dev.yml (override)                       │  │
│  │   - Volume mounts for live editing                        │  │
│  │   - Debug ports exposed                                   │  │
│  │   - Development database                                  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Production Environment                                          │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ docker-compose.yml (base)                                  │  │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │ │     web     │  │     api     │  │     db      │         │  │
│  │ │  optimized  │  │ production  │  │ persistent  │         │  │
│  │ └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                            │  │
│  │ + docker-compose.prod.yml (override)                      │  │
│  │   - Resource limits                                       │  │
│  │   - Health checks                                         │  │
│  │   - Security hardening                                    │  │
│  │   - External secrets                                      │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Testing Environment                                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ docker-compose.yml (base)                                  │  │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │  │
│  │ │     web     │  │     api     │  │     db      │         │  │
│  │ │ test-mode   │  │ mock-apis   │  │ test-data   │         │  │
│  │ └─────────────┘  └─────────────┘  └─────────────┘         │  │
│  │                                                            │  │
│  │ + docker-compose.test.yml (override)                      │  │
│  │   - Test database fixtures                                │  │
│  │   - Mock external services                                │  │
│  │   - Coverage reporting                                    │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Base configuration with environment-specific overrides
- Variable substitution and templating
- Environment-specific resource allocation
- Configuration management strategies

## Visual 3: Service Dependencies and Health Checks
**Anchor**: `p06-visual-dependencies-health`

```
┌─────────────────────────────────────────────────────────────────┐
│                Service Startup Orchestration                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Startup Sequence (with depends_on)                            │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │ 1. Database │────▶│ 2. Backend  │────▶│ 3. Frontend │       │
│  │   (Start)   │     │  (Wait for  │     │  (Wait for  │       │
│  │             │     │   DB ready) │     │  API ready) │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│                                                                 │
│  Health Check Flow                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Database                               │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ Health Check: pg_isready -U postgres           │    │   │
│  │  │ Interval: 10s │ Timeout: 5s │ Retries: 3      │    │   │
│  │  │ Status: Starting ▶ Healthy ▶ Running           │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Backend                              │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ Health Check: curl -f http://localhost:8080/health │   │
│  │  │ Depends On: Database (healthy condition)        │    │   │
│  │  │ Status: Starting ▶ Healthy ▶ Running           │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Frontend                              │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ Health Check: curl -f http://localhost:3000/     │   │
│  │  │ Depends On: Backend (healthy condition)         │    │   │
│  │  │ Status: Starting ▶ Healthy ▶ Running           │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Service startup ordering with depends_on
- Health check configuration and monitoring
- Graceful service initialization
- Dependency failure handling

## Visual 4: Secrets Management and Security
**Anchor**: `p06-visual-secrets-security`

```
┌─────────────────────────────────────────────────────────────────┐
│                    Secrets Management Flow                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  External Secrets Source                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │    Vault    │  │   AWS KMS   │  │ Kubernetes  │     │   │
│  │  │  Secrets    │  │   Secrets   │  │   Secrets   │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Docker Compose Secrets Integration                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  secrets:                                               │   │
│  │    db_password:                                         │   │
│  │      external: true                                     │   │
│  │    api_key:                                             │   │
│  │      file: ./secrets/api_key.txt                        │   │
│  │    ssl_cert:                                            │   │
│  │      external:                                          │   │
│  │        name: production_ssl_cert                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  Container Secrets Mount                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Service: api                         │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ Mounted Secrets:                                │    │   │
│  │  │   /run/secrets/db_password                      │    │   │
│  │  │   /run/secrets/api_key                          │    │   │
│  │  │   /run/secrets/ssl_cert                         │    │   │
│  │  │                                                 │    │   │
│  │  │ Security Features:                              │    │   │
│  │  │   - Read-only filesystem                        │    │   │
│  │  │   - Non-root user                               │    │   │
│  │  │   - Dropped capabilities                        │    │   │
│  │  │   - Security headers                            │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Security Monitoring                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │   │
│  │  │   Log Scan   │ │  Port Scan   │ │ Vulnerability│    │   │
│  │  │   for Secrets│ │   Detection  │ │   Scanner    │    │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- External secrets integration
- Secure secret mounting in containers
- Security hardening configurations
- Secrets lifecycle management

## Visual 5: Production Deployment Pipeline
**Anchor**: `p06-visual-production-deployment`

```
┌─────────────────────────────────────────────────────────────────┐
│                Production Deployment Pipeline                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Development ▶ Staging ▶ Production                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Development Stage                        │   │
│  │  ┌─────────────┐   ┌──────────────────────────────┐     │   │
│  │  │ Developer   │──▶│     Docker Compose           │     │   │
│  │  │ Workstation │   │   docker-compose.dev.yml     │     │   │
│  │  │             │   │   - Hot reload               │     │   │
│  │  │             │   │   - Debug ports              │     │   │
│  │  │             │   │   - Volume mounts            │     │   │
│  │  └─────────────┘   └──────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Staging Stage                          │   │
│  │  ┌─────────────┐   ┌──────────────────────────────┐     │   │
│  │  │   CI/CD     │──▶│     Docker Compose           │     │   │
│  │  │  Pipeline   │   │   docker-compose.staging.yml │     │   │
│  │  │             │   │   - Production-like config   │     │   │
│  │  │             │   │   - Integration tests        │     │   │
│  │  │             │   │   - Security scanning        │     │   │
│  │  └─────────────┘   └──────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Production Stage                         │   │
│  │  ┌─────────────┐   ┌──────────────────────────────┐     │   │
│  │  │   Deploy    │──▶│     Docker Compose           │     │   │
│  │  │ Automation  │   │   docker-compose.prod.yml    │     │   │
│  │  │             │   │   - Resource limits          │     │   │
│  │  │             │   │   - Health checks            │     │   │
│  │  │             │   │   - Secrets management       │     │   │
│  │  │             │   │   - Logging & monitoring     │     │   │
│  │  └─────────────┘   └──────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Deployment Strategies                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Rolling Update                                         │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │   │
│  │  │   v1    │ │   v1    │ │   v2    │ │   v2    │       │   │
│  │  │(stopping│▶│(running)│▶│(starting│▶│(running)│       │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘       │   │
│  │                                                         │   │
│  │  Blue/Green Deployment                                  │   │
│  │  ┌─────────────────┐     ┌─────────────────┐           │   │
│  │  │   Blue (v1)     │     │   Green (v2)    │           │   │
│  │  │   ┌─────────┐   │     │   ┌─────────┐   │           │   │
│  │  │   │ Active  │   │────▶│   │ Testing │   │           │   │
│  │  │   │ Traffic │   │     │   │ Verify  │   │           │   │
│  │  │   └─────────┘   │     │   └─────────┘   │           │   │
│  │  └─────────────────┘     └─────────────────┘           │   │
│  │          │                       │                     │   │
│  │          └───────► Switch ◄──────┘                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Multi-environment deployment pipeline
- Environment-specific configurations
- Deployment strategies and rollback plans
- Continuous integration with Docker Compose

## Visual 6: Monitoring and Observability Stack
**Anchor**: `p06-visual-monitoring-observability`

```
┌─────────────────────────────────────────────────────────────────┐
│                   Monitoring Architecture                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Application Services                                           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  Frontend   │    │  Backend    │    │  Database   │         │
│  │   :3000     │    │   :8080     │    │   :5432     │         │
│  └─────┬───────┘    └─────┬───────┘    └─────┬───────┘         │
│        │                  │                  │                 │
│        │ metrics/logs     │ metrics/logs     │ metrics/logs    │
│        ▼                  ▼                  ▼                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Observability Stack                   │   │
│  │                                                         │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │   │
│  │  │  Prometheus  │ │    Grafana   │ │  Jaeger/Tempo│    │   │
│  │  │   Metrics    │ │  Dashboards  │ │   Tracing    │    │   │
│  │  │   :9090      │ │    :3001     │ │    :14268    │    │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘    │   │
│  │                                                         │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │   │
│  │  │     Loki     │ │ Node Exporter│ │  cAdvisor    │    │   │
│  │  │     Logs     │ │ Host Metrics │ │   Container  │    │   │
│  │  │    :3100     │ │    :9100     │ │   :8081      │    │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Alert Manager                         │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ Alert Rules:                                    │    │   │
│  │  │ - High CPU usage (>80%)                         │    │   │
│  │  │ - Memory consumption (>85%)                     │    │   │
│  │  │ - Service down (health check fails)            │    │   │
│  │  │ - Database connection errors                    │    │   │
│  │  │ - High response time (>500ms)                   │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  │                             │                           │   │
│  │                             ▼                           │   │
│  │  ┌─────────────────────────────────────────────────┐    │   │
│  │  │ Notification Channels:                          │    │   │
│  │  │ - Slack #alerts                                 │    │   │
│  │  │ - PagerDuty (critical)                          │    │   │
│  │  │ - Email (warnings)                              │    │   │
│  │  │ - Webhook (custom integrations)                 │    │   │
│  │  └─────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- Comprehensive monitoring stack deployment
- Metrics collection and visualization
- Centralized logging and alerting
- Container and host monitoring

## Deployment Commands Reference

### Quick Reference Commands
```bash
# Multi-environment deployment
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Health check verification
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Log aggregation
docker compose logs -f --tail=100

# Resource monitoring
docker stats $(docker compose ps -q)

# Security scanning
docker compose exec web curl -I http://localhost/health

# Backup creation
docker run --rm -v app_data:/data -v $(pwd):/backup alpine tar czf /backup/data-backup-$(date +%Y%m%d).tar.gz /data
```

### Environment Variables Template
```bash
# .env.production
COMPOSE_PROJECT_NAME=myapp-prod
POSTGRES_DB=production
POSTGRES_USER=produser
API_PORT=8080
WEB_PORT=80
LOG_LEVEL=warn
ENVIRONMENT=production
```

---

**Note**: These visuals represent conceptual diagrams. In production environments, customize configurations based on specific infrastructure requirements, security policies, and organizational standards.