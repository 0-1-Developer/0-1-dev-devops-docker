# Micro-Lesson 04: Secrets Management and Production Security

> **Anchor**: `p06-m01-l04`  
> **Duration**: 4 minutes  
> **One Key Idea**: Implement comprehensive secrets management and security hardening for production deployments

## Why It Matters

Secrets (passwords, API keys, certificates) in environment variables or plain text files are major security vulnerabilities. Proper secrets management prevents credential exposure, enables rotation, and provides audit trails. Production deployments require comprehensive security hardening.

## What to Learn

Master production security patterns:
- **Docker secrets integration** - Secure secret distribution
- **Security context configuration** - Runtime security controls
- **Runtime security hardening** - Defense-in-depth strategies
- **Secrets rotation strategies** - Automated credential management

## Production-Hardened Configuration

### Secure Service Definition
```yaml
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
```

### Secrets Configuration
```yaml
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
```

### Secure Network Configuration
```yaml
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

## Secrets Management Script

### Setup Script
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

## Secrets Rotation Procedure

### Rotation Script
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

## Practice Tasks

1. **Setup secrets**: `chmod +x setup-secrets.sh && ./setup-secrets.sh`
2. **Deploy secure stack**: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d`
3. **Verify security**: `docker compose exec app ls -la /run/secrets/`
4. **Test read-only filesystem**: `docker compose exec app touch /test` (should fail)
5. **Check security headers**: `curl -I http://localhost/`
6. **Verify non-root user**: `docker compose exec app whoami`

## Production Notes

- Integrate with enterprise secret management systems (Vault, AWS Secrets Manager)
- Implement secret rotation automation
- Use read-only filesystems and non-root users consistently
- Monitor for security violations and unauthorized access attempts
- Regular security audits and vulnerability scanning

## Key Takeaway

Production security requires comprehensive secrets management, security hardening, and runtime protections to defend against multiple attack vectors.