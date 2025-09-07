# Phase 06: Docker Compose - Cleanup Rules

## Overview
Comprehensive cleanup procedures for Docker Compose environments, focusing on multi-service stack teardown, data preservation strategies, and environment restoration.

## Rule 1: Multi-Service Stack Teardown
**Anchor**: `p06-cleanup-stacks`

### Cleanup Commands
```bash
# Complete stack teardown with volumes
docker compose down -v --remove-orphans

# Verify all services stopped
docker compose ps -a

# Remove associated images (optional)
docker compose down --rmi all

# Force removal of persistent volumes
docker volume prune -f
```

### Verification Steps
1. **Service Status Check**
   ```bash
   docker compose ps
   # Should show: no services running
   ```

2. **Network Cleanup Verification**
   ```bash
   docker network ls | grep "compose"
   # Should show: no compose networks remaining
   ```

3. **Volume Cleanup Verification**
   ```bash
   docker volume ls | grep "compose"
   # Should show: no compose volumes (if -v used)
   ```

## Rule 2: Selective Service Management
**Anchor**: `p06-cleanup-selective`

### Cleanup Commands
```bash
# Stop specific services
docker compose stop <service_name>

# Remove specific service containers
docker compose rm <service_name>

# Restart specific services
docker compose restart <service_name>

# Scale down services
docker compose up -d --scale <service_name>=0
```

### Data Preservation
```bash
# Create backup before cleanup
docker run --rm -v <volume_name>:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# Verify backup integrity
tar -tzf backup.tar.gz | head -10
```

## Rule 3: Environment-Specific Cleanup
**Anchor**: `p06-cleanup-environments`

### Development Environment
```bash
# Development cleanup (preserve data)
docker compose -f docker-compose.yml -f docker-compose.dev.yml down

# Remove development containers only
docker compose -f docker-compose.dev.yml rm -f
```

### Production Environment
```bash
# Production cleanup (with backup verification)
docker compose -f docker-compose.yml -f docker-compose.prod.yml down --timeout 30

# Verify critical data backup exists
ls -la backups/ | grep $(date +%Y-%m-%d)

# Clean production logs
docker system prune -f --filter "until=24h"
```

### Testing Environment
```bash
# Complete testing environment reset
docker compose -f docker-compose.test.yml down -v --remove-orphans

# Remove test data volumes
docker volume rm $(docker volume ls -q | grep test)

# Clean test images
docker rmi $(docker images | grep test | awk '{print $3}')
```

## Rule 4: Network and Resource Cleanup
**Anchor**: `p06-cleanup-resources`

### Network Cleanup
```bash
# Remove compose networks
docker network rm $(docker network ls | grep compose | awk '{print $1}')

# Clean unused networks
docker network prune -f

# Verify network isolation
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
```

### Resource Cleanup
```bash
# System-wide cleanup
docker system prune -a -f --volumes

# Check disk space recovery
df -h /var/lib/docker

# Monitor resource usage
docker system df
```

## Rule 5: Secrets and Security Cleanup
**Anchor**: `p06-cleanup-security`

### Secrets Management
```bash
# Remove Docker secrets
docker secret ls | grep -v NAME | awk '{print $1}' | xargs docker secret rm

# Clean environment files
rm -f .env.local .env.staging .env.backup

# Verify no secrets in logs
docker compose logs 2>&1 | grep -i "password\|secret\|token" || echo "No secrets found in logs"
```

### Security Verification
```bash
# Check for exposed ports
netstat -tlnp | grep -E ':80|:443|:3306|:5432'

# Verify no running containers
docker ps -q | wc -l  # Should output: 0

# Check for sensitive files
find . -name "*.key" -o -name "*.pem" -o -name "*.p12" | head -5
```

## Rule 6: Database and Persistent Data Cleanup
**Anchor**: `p06-cleanup-data`

### Database Cleanup
```bash
# Export database before cleanup
docker compose exec db mysqldump -u root -p --all-databases > backup.sql

# Graceful database shutdown
docker compose stop db
docker compose rm db

# Verify database backup
head -20 backup.sql | grep "-- MySQL dump"
```

### Volume Management
```bash
# List all compose volumes
docker volume ls --filter name=compose

# Backup critical volumes
for vol in $(docker volume ls --filter name=compose -q); do
    docker run --rm -v $vol:/data -v $(pwd):/backup alpine tar czf /backup/$vol.tar.gz /data
done

# Remove non-critical volumes
docker volume rm $(docker volume ls -q | grep tmp)
```

## Rule 7: Log and Monitoring Cleanup
**Anchor**: `p06-cleanup-monitoring`

### Log Management
```bash
# Export recent logs
docker compose logs --since 1h > compose-logs-$(date +%Y%m%d).log

# Clear container logs
echo "" | sudo tee $(docker inspect --format='{{.LogPath}}' $(docker compose ps -q))

# Rotate log files
find /var/log -name "*.log" -size +100M -delete
```

### Monitoring Cleanup
```bash
# Clean monitoring data
docker volume rm $(docker volume ls -q | grep monitoring)

# Reset metrics collection
docker compose -f monitoring/docker-compose.yml down -v

# Verify monitoring stack removed
docker ps --filter "label=monitoring" --format "table {{.Names}}\t{{.Status}}"
```

## Pre-Cleanup Checklist

### Data Safety
- [ ] Critical data backed up
- [ ] Database exports completed
- [ ] Configuration files preserved
- [ ] SSL certificates backed up
- [ ] Environment variables documented

### Service Dependencies
- [ ] External services notified
- [ ] Load balancer updated
- [ ] DNS records adjusted (if needed)
- [ ] Monitoring alerts disabled
- [ ] Scheduled jobs stopped

### Recovery Planning
- [ ] Recovery procedures documented
- [ ] Rollback plan prepared
- [ ] Key personnel notified
- [ ] Maintenance window scheduled
- [ ] Testing environment verified

## Post-Cleanup Verification

### System State
```bash
# Verify clean state
docker compose ps
docker container ls -a
docker volume ls
docker network ls
docker image ls | grep compose

# Check system resources
docker system df
free -h
df -h
```

### Recovery Test
```bash
# Test rapid redeployment
docker compose up -d --build

# Verify service connectivity
docker compose exec web curl -f http://localhost:8080/health

# Check data restoration
docker compose exec db mysql -u root -p -e "SHOW DATABASES;"
```

## Emergency Cleanup Procedures

### Force Cleanup (Use with Caution)
```bash
# Nuclear option - removes everything
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -q)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q | grep -v bridge | grep -v host | grep -v none)
docker system prune -a -f --volumes
```

### System Recovery
```bash
# Restart Docker service
sudo systemctl restart docker

# Verify Docker functionality
docker run --rm hello-world

# Recreate default networks
docker network create bridge --driver bridge
```

---

**Note**: Always test cleanup procedures in development environments before applying to production. Maintain recent backups and have rollback plans ready.