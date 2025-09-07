# Phase 10 Cleanup Rules: Docker Observability

> **Purpose**: Safely clean up observability infrastructure, monitoring stacks, and collected data  
> **Scope**: Complete removal of logging, metrics, tracing, and monitoring components

## 🧹 Cleanup Overview

This cleanup ensures:
- Safe removal of monitoring stack components
- Proper cleanup of collected metrics and logs
- Network and volume removal
- Configuration file cleanup
- Optional data preservation

## 🗑️ Rule 1: Logging Infrastructure Cleanup

### Components to Clean
- Logging driver configurations
- Fluentd containers and configurations
- Log aggregation services
- Log storage volumes

### Cleanup Commands
```bash
# Stop logging containers
docker stop json-logger fluentd-logger fluentd structured-logger 2>/dev/null
docker rm json-logger fluentd-logger fluentd structured-logger 2>/dev/null

# Remove Fluentd configuration
sudo rm -rf fluentd/
rm -f fluent.conf

# Clean up log volumes
docker volume rm fluentd-logs 2>/dev/null

# Remove test applications
docker rmi log-generator:latest structured-logger:latest 2>/dev/null

# Clean up log files
sudo rm -rf /var/log/docker-observability/
rm -f *.log
```

### Log Data Preservation (Optional)
```bash
# Backup logs before cleanup
mkdir -p ~/observability-backup/logs
docker logs json-logger > ~/observability-backup/logs/json-logger.log 2>&1
docker logs fluentd > ~/observability-backup/logs/fluentd.log 2>&1

# Export Fluentd collected logs
docker exec fluentd tar -czf /tmp/logs-backup.tar.gz /fluentd/log/
docker cp fluentd:/tmp/logs-backup.tar.gz ~/observability-backup/logs/

echo "✅ Logs backed up to ~/observability-backup/logs/"
```

### Verification Commands
```bash
# Verify container removal
docker ps -a | grep -E "(logger|fluentd)"

# Verify volume cleanup
docker volume ls | grep -E "(fluentd|logs)"

# Check for leftover configurations
ls -la fluentd/ 2>/dev/null
```

## 🗑️ Rule 2: Metrics Stack Cleanup

### Components to Clean
- Prometheus server
- Grafana dashboards
- Node exporter
- cAdvisor
- Custom metric exporters

### Cleanup Commands
```bash
# Stop monitoring stack
docker-compose -f monitoring-stack.yml down -v 2>/dev/null

# Remove individual containers
docker stop prometheus grafana node-exporter cadvisor metrics-app 2>/dev/null
docker rm prometheus grafana node-exporter cadvisor metrics-app 2>/dev/null

# Remove monitoring images
docker rmi prom/prometheus:latest \
           grafana/grafana:latest \
           prom/node-exporter:latest \
           gcr.io/cadvisor/cadvisor:latest \
           metrics-app:latest 2>/dev/null

# Clean up configuration directories
rm -rf prometheus/ grafana/
rm -f prometheus.yml alerts.yml
```

### Metrics Data Preservation (Optional)
```bash
# Backup Prometheus data
docker run --rm \
  -v prometheus-data:/data \
  -v $(pwd):/backup \
  alpine tar -czf /backup/prometheus-backup.tar.gz /data

# Backup Grafana dashboards
docker exec grafana tar -czf /tmp/grafana-backup.tar.gz \
  /var/lib/grafana/dashboards /etc/grafana/provisioning
docker cp grafana:/tmp/grafana-backup.tar.gz ~/observability-backup/

# Export current metrics
curl -s http://localhost:9090/api/v1/query?query=up > ~/observability-backup/final-metrics.json
```

### Cleanup Volumes
```bash
# Remove Prometheus and Grafana volumes
docker volume rm prometheus-data grafana-data 2>/dev/null

# Clean up metric export files
rm -f metrics.txt *.json
rm -rf performance-results/
```

### Verification Commands
```bash
# Check containers are removed
docker ps -a | grep -E "(prometheus|grafana|exporter|cadvisor)"

# Verify volumes are cleaned
docker volume ls | grep -E "(prometheus|grafana|metrics)"

# Check ports are freed
netstat -tlnp | grep -E "(9090|3000|9100|8080)"
```

## 🗑️ Rule 3: Tracing Infrastructure Cleanup

### Components to Clean
- Jaeger all-in-one
- Traced services
- OpenTelemetry agents
- Tempo instances

### Cleanup Commands
```bash
# Stop tracing stack
docker-compose -f jaeger-stack.yml down -v 2>/dev/null

# Remove tracing containers
docker stop jaeger service-a service-b tempo 2>/dev/null
docker rm jaeger service-a service-b tempo 2>/dev/null

# Remove tracing images
docker rmi jaegertracing/all-in-one:latest \
           grafana/tempo:latest \
           traced-service:latest 2>/dev/null

# Clean up tracing configurations
rm -rf jaeger/ tempo/
rm -f service-*.py
```

### Trace Data Preservation (Optional)
```bash
# Export traces from Jaeger
curl -s "http://localhost:16686/api/traces?service=service-a&limit=100" \
  > ~/observability-backup/traces.json

# Backup Tempo data
docker run --rm \
  -v tempo-data:/data \
  -v $(pwd):/backup \
  alpine tar -czf /backup/tempo-backup.tar.gz /data
```

### Verification Commands
```bash
# Verify container removal
docker ps -a | grep -E "(jaeger|tempo|service-)"

# Check tracing ports are freed
netstat -tlnp | grep -E "(16686|6831|14250|3200)"

# Verify volume cleanup
docker volume ls | grep -E "(jaeger|tempo|tracing)"
```

## 🗑️ Rule 4: Log Aggregation Cleanup

### Components to Clean
- Loki server
- Promtail agents
- Log storage
- Configuration files

### Cleanup Commands
```bash
# Stop Loki stack
docker-compose -f loki-stack.yml down -v 2>/dev/null

# Remove containers
docker stop loki promtail 2>/dev/null
docker rm loki promtail 2>/dev/null

# Remove images
docker rmi grafana/loki:latest \
           grafana/promtail:latest 2>/dev/null

# Clean up configurations
rm -rf loki/ promtail/
rm -f loki-config.yaml promtail-config.yaml

# Remove log data volume
docker volume rm loki-data 2>/dev/null
```

### Log Data Export (Optional)
```bash
# Export recent logs from Loki
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="containerlogs"}' \
  --data-urlencode 'limit=1000' \
  > ~/observability-backup/loki-logs.json

# Backup Loki storage
docker run --rm \
  -v loki-data:/data \
  -v $(pwd):/backup \
  alpine tar -czf /backup/loki-backup.tar.gz /data
```

### Verification Commands
```bash
# Check container removal
docker ps -a | grep -E "(loki|promtail)"

# Verify port cleanup
netstat -tlnp | grep -E "(3100|9080)"

# Check volume removal
docker volume ls | grep loki
```

## 🗑️ Rule 5: Complete Stack Cleanup

### Components to Clean
- Complete observability stack
- Alert manager
- All integrated services
- Networks and volumes

### Cleanup Commands
```bash
# Stop complete observability stack
docker-compose -f complete-observability.yml down -v 2>/dev/null

# Remove AlertManager
docker stop alertmanager 2>/dev/null
docker rm alertmanager 2>/dev/null
docker rmi prom/alertmanager:latest 2>/dev/null

# Clean up all test applications
docker stop perf-app 2>/dev/null
docker rm perf-app 2>/dev/null
docker rmi perf-app:latest 2>/dev/null

# Remove observability network
docker network rm observability-lab 2>/dev/null

# Clean up all configuration files
rm -rf alertmanager/
rm -f *.yml *.yaml *.json
```

### Complete Data Backup (Optional)
```bash
#!/bin/bash
# backup-observability.sh

BACKUP_DIR=~/observability-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

echo "📦 Creating complete observability backup..."

# Backup all configurations
tar -czf $BACKUP_DIR/configs.tar.gz \
  prometheus/ grafana/ loki/ promtail/ alertmanager/ 2>/dev/null

# Export all dashboards
curl -s -u admin:admin123 http://localhost:3000/api/dashboards/db/docker-metrics \
  > $BACKUP_DIR/dashboard.json 2>/dev/null

# Save docker-compose files
cp *.yml $BACKUP_DIR/ 2>/dev/null

echo "✅ Backup completed: $BACKUP_DIR"
```

### Network Cleanup
```bash
# List custom networks
docker network ls | grep observability

# Remove observability networks
docker network rm observability-lab monitoring tracing 2>/dev/null

# Verify network removal
docker network ls --format "table {{.Name}}\t{{.Driver}}"
```

### Verification Commands
```bash
# Check all containers are removed
docker ps -a | grep -E "(prometheus|grafana|loki|jaeger|alertmanager)"

# Verify all volumes are cleaned
docker volume ls | grep -E "(prometheus|grafana|loki|tempo|alertmanager)"

# Check all ports are freed
netstat -tlnp | grep -E "(9090|3000|3100|16686|9093)"

# Verify network cleanup
docker network ls | grep observability
```

## 🗑️ Rule 6: Performance Test Cleanup

### Components to Clean
- Performance test applications
- Test results and reports
- Load testing scripts
- Analysis outputs

### Cleanup Commands
```bash
# Remove performance test files
rm -f perf-app.py app.py structured-logger.py
rm -f metrics-app.py service-*.py
rm -f monitor-performance.sh load-test.sh
rm -f analyze-performance.py query-logs.sh

# Clean up test results
rm -rf performance-results/
rm -f stats.csv analysis.png
rm -f *.log *.txt

# Remove Dockerfiles
rm -f Dockerfile Dockerfile.* 

# Clean up Python cache
rm -rf __pycache__/
find . -name "*.pyc" -delete
```

### Test Data Preservation (Optional)
```bash
# Archive performance test results
if [ -d performance-results ]; then
  tar -czf ~/observability-backup/performance-results.tar.gz performance-results/
  echo "✅ Performance results archived"
fi

# Save analysis outputs
cp *.png *.csv ~/observability-backup/ 2>/dev/null
```

### Verification Commands
```bash
# Check for leftover files
ls -la *.py *.sh *.yml 2>/dev/null

# Verify result directories are removed
ls -la performance-results/ 2>/dev/null

# Check for running background processes
ps aux | grep -E "(python|node)" | grep -v grep
```

## 🧹 Complete Cleanup Script

### Comprehensive Cleanup Runner
```bash
#!/bin/bash
# cleanup-phase10.sh

echo "🧹 Phase 10: Observability Cleanup"
echo "==================================="

# Function to ask for confirmation
confirm() {
    read -p "$1 (y/N): " response
    [[ $response =~ ^[Yy]$ ]]
}

# Backup option
if confirm "Create backup before cleanup?"; then
    BACKUP_DIR=~/observability-backup-$(date +%Y%m%d-%H%M%S)
    mkdir -p $BACKUP_DIR
    
    echo "📦 Creating backups..."
    
    # Export metrics
    curl -s http://localhost:9090/api/v1/query?query=up > $BACKUP_DIR/metrics.json 2>/dev/null
    
    # Export logs
    curl -s "http://localhost:3100/loki/api/v1/query_range" \
      --data-urlencode 'query={job="containerlogs"}' \
      > $BACKUP_DIR/logs.json 2>/dev/null
    
    # Export traces
    curl -s "http://localhost:16686/api/traces?limit=100" > $BACKUP_DIR/traces.json 2>/dev/null
    
    echo "✅ Backups saved to $BACKUP_DIR"
fi

echo "🛑 Stopping all observability services..."

# Stop all compose stacks
for compose_file in monitoring-stack.yml jaeger-stack.yml loki-stack.yml complete-observability.yml; do
    if [ -f $compose_file ]; then
        docker-compose -f $compose_file down -v 2>/dev/null
    fi
done

# Stop individual containers
CONTAINERS="json-logger fluentd-logger fluentd structured-logger \
            prometheus grafana node-exporter cadvisor metrics-app \
            jaeger service-a service-b tempo \
            loki promtail alertmanager perf-app"

for container in $CONTAINERS; do
    docker stop $container 2>/dev/null
    docker rm $container 2>/dev/null
done

if confirm "Remove Docker images?"; then
    echo "🗑️  Removing images..."
    
    IMAGES="log-generator metrics-app traced-service perf-app structured-logger \
            prom/prometheus grafana/grafana prom/node-exporter \
            gcr.io/cadvisor/cadvisor jaegertracing/all-in-one \
            grafana/loki grafana/promtail grafana/tempo prom/alertmanager"
    
    for image in $IMAGES; do
        docker rmi $image:latest 2>/dev/null
    done
fi

if confirm "Remove volumes and networks?"; then
    echo "🗑️  Removing volumes and networks..."
    
    # Remove volumes
    docker volume rm prometheus-data grafana-data loki-data tempo-data \
                    alertmanager-data fluentd-logs 2>/dev/null
    
    # Remove network
    docker network rm observability-lab monitoring tracing 2>/dev/null
fi

if confirm "Remove configuration files and test data?"; then
    echo "🗑️  Removing files..."
    
    # Remove directories
    rm -rf prometheus/ grafana/ loki/ promtail/ jaeger/ tempo/ \
           alertmanager/ fluentd/ performance-results/
    
    # Remove files
    rm -f *.yml *.yaml *.json *.py *.sh *.log *.txt *.csv *.png
    rm -f Dockerfile Dockerfile.*
fi

echo "🧼 Running Docker cleanup..."
docker system prune -f

# Final verification
echo ""
echo "🔍 Cleanup Verification:"
echo "Remaining containers:"
docker ps -a | grep -E "(prometheus|grafana|loki|jaeger)" || echo "  None found"

echo "Remaining images:"
docker images | grep -E "(prometheus|grafana|loki|jaeger)" || echo "  None found"

echo "Remaining volumes:"
docker volume ls | grep -E "(prometheus|grafana|loki|tempo)" || echo "  None found"

echo "Remaining networks:"
docker network ls | grep observability || echo "  None found"

echo ""
echo "==================================="
echo "✅ Phase 10 cleanup completed!"

if [ -d "$BACKUP_DIR" ]; then
    echo "📦 Backups available at: $BACKUP_DIR"
fi
```

## 📝 Cleanup Checklist

### Pre-Cleanup Tasks
- [ ] Export important metrics data
- [ ] Save Grafana dashboards
- [ ] Backup alert configurations
- [ ] Document current setup

### Container Cleanup
- [ ] Stop all monitoring containers
- [ ] Remove logging infrastructure
- [ ] Clean up tracing services
- [ ] Delete test applications

### Data Cleanup
- [ ] Remove or backup Prometheus data
- [ ] Clean up Loki log storage
- [ ] Export Jaeger traces
- [ ] Archive performance results

### Configuration Cleanup
- [ ] Remove configuration directories
- [ ] Delete compose files
- [ ] Clean up scripts and tests
- [ ] Remove temporary files

### System Cleanup
- [ ] Remove Docker volumes
- [ ] Delete custom networks
- [ ] Clean up unused images
- [ ] Free up disk space

### Final Verification
- [ ] No observability containers running
- [ ] All volumes removed
- [ ] Networks cleaned up
- [ ] Ports available
- [ ] Disk space recovered

---

💡 **Cleanup Success**: Complete removal of all observability components while maintaining the option to restore from backups if needed.