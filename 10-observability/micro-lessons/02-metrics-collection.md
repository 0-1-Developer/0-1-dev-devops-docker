# Micro-Lesson 02: Prometheus Metrics Collection and Exporters

> **Anchor**: `p10-m01-l02`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master Prometheus metrics collection through exporters, custom metrics, and service discovery for comprehensive container monitoring

## Why It Matters

Metrics provide quantitative insights into system behavior, performance, and health. Prometheus, the de facto standard for container monitoring, offers powerful time-series data collection with flexible querying capabilities. Understanding metrics collection enables proactive monitoring, capacity planning, and automated alerting for production container environments.

## What to Learn

Master Prometheus metrics fundamentals:
- **Metric types** - Counters, gauges, histograms, and summaries
- **Exporters ecosystem** - Node exporter, cAdvisor, and custom exporters
- **Service discovery** - Automatic target detection and configuration
- **PromQL queries** - Extracting insights from time-series data

## Prometheus Architecture

### Core Components
```bash
# Deploy Prometheus server
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus:latest

# Basic Prometheus configuration
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
EOF
```

### Metric Types Explained
```bash
# Counter: Monotonically increasing value
# Example: http_requests_total
# Usage: Rate calculations, total counts

# Gauge: Current value that can go up/down
# Example: memory_usage_bytes
# Usage: Current state, resource levels

# Histogram: Distribution of measurements
# Example: http_request_duration_seconds
# Usage: Latency analysis, SLAs

# Summary: Similar to histogram with quantiles
# Example: response_time_quantiles
# Usage: Client-side quantile calculation
```

## Essential Exporters

### Node Exporter (Host Metrics)
```bash
# Deploy Node Exporter
docker run -d \
  --name node-exporter \
  -p 9100:9100 \
  --path.procfs=/host/proc \
  --path.sysfs=/host/sys \
  --path.rootfs=/host \
  --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc)($$|/)' \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /:/host:ro \
  prom/node-exporter:latest

# Key metrics from Node Exporter:
# - node_cpu_seconds_total: CPU usage
# - node_memory_MemAvailable_bytes: Available memory
# - node_filesystem_size_bytes: Disk space
# - node_network_receive_bytes_total: Network I/O
```

### cAdvisor (Container Metrics)
```bash
# Deploy cAdvisor for container metrics
docker run -d \
  --name cadvisor \
  -p 8080:8080 \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:latest

# Key metrics from cAdvisor:
# - container_cpu_usage_seconds_total: Container CPU
# - container_memory_usage_bytes: Container memory
# - container_network_receive_bytes_total: Container network
# - container_fs_reads_bytes_total: Container disk I/O
```

### Custom Application Metrics
```python
# Python application with Prometheus metrics
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
import random

# Define metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('app_request_duration_seconds', 'Request latency')
ACTIVE_CONNECTIONS = Gauge('app_active_connections', 'Active connections')

def process_request(method, endpoint):
    # Record request
    REQUEST_COUNT.labels(method=method, endpoint=endpoint).inc()
    
    # Measure latency
    with REQUEST_LATENCY.time():
        # Simulate processing
        time.sleep(random.uniform(0.1, 0.5))
    
    # Update active connections
    ACTIVE_CONNECTIONS.set(random.randint(10, 100))

if __name__ == '__main__':
    # Start metrics server
    start_http_server(8000)
    print("Metrics available at :8000/metrics")
    
    # Simulate application
    while True:
        method = random.choice(['GET', 'POST', 'PUT'])
        endpoint = random.choice(['/api/users', '/api/orders', '/health'])
        process_request(method, endpoint)
        time.sleep(1)
```

## Service Discovery

### Docker Service Discovery
```yaml
# prometheus.yml with Docker service discovery
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'docker'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 30s
    
    relabel_configs:
      # Only scrape containers with prometheus.scrape=true label
      - source_labels: [__meta_docker_container_label_prometheus_scrape]
        action: keep
        regex: true
      
      # Use prometheus.port label for port, default to 8080
      - source_labels: [__meta_docker_container_label_prometheus_port]
        action: replace
        target_label: __address__
        replacement: '${1}:${__meta_docker_port_private_8080}'
      
      # Extract container name
      - source_labels: [__meta_docker_container_name]
        regex: '/(.*)'
        target_label: instance
      
      # Add labels from container
      - source_labels: [__meta_docker_container_label_app]
        target_label: app
      - source_labels: [__meta_docker_container_label_version]
        target_label: version
```

### File-based Service Discovery
```yaml
# file_sd_config.json
[
  {
    "targets": ["app1:8080", "app2:8080"],
    "labels": {
      "job": "web-servers",
      "env": "production"
    }
  },
  {
    "targets": ["db1:9187", "db2:9187"],
    "labels": {
      "job": "databases",
      "env": "production"
    }
  }
]
```

## PromQL Query Examples

### Basic Queries
```bash
# Current CPU usage per container
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memory usage percentage
(container_memory_usage_bytes / container_memory_limit_bytes) * 100

# Request rate
rate(app_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(app_request_duration_seconds_bucket[5m]))

# Error rate
rate(app_requests_total{status=~"5.."}[5m]) / rate(app_requests_total[5m])
```

### Advanced Queries
```bash
# Top 5 containers by CPU usage
topk(5, rate(container_cpu_usage_seconds_total[5m]))

# Predict disk full time (4 hours ahead)
predict_linear(node_filesystem_free_bytes[1h], 4*3600)

# Application availability SLA
(
  sum(rate(app_requests_total{status!~"5.."}[5m])) /
  sum(rate(app_requests_total[5m]))
) * 100

# Alert on high memory usage
(
  container_memory_usage_bytes / container_memory_limit_bytes
) > 0.85
```

## Complete Monitoring Stack

### Docker Compose Monitoring Setup
```yaml
# monitoring-stack.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/host:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/host'

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    privileged: true

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

  # Sample application with metrics
  demo-app:
    build: .
    ports:
      - "8000:8000"
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=8000"
      - "app=demo"
      - "version=1.0"

volumes:
  prometheus-data:
  grafana-data:
```

## Recording Rules and Alerts

### Recording Rules for Performance
```yaml
# rules.yml
groups:
  - name: container.rules
    interval: 30s
    rules:
      # Pre-calculate expensive queries
      - record: container:cpu_usage_rate
        expr: rate(container_cpu_usage_seconds_total[5m])
        
      - record: container:memory_usage_percent
        expr: (container_memory_usage_bytes / container_memory_limit_bytes) * 100
        
      - record: app:request_rate
        expr: rate(app_requests_total[5m])
        
      - record: app:error_rate_percent
        expr: |
          (
            rate(app_requests_total{status=~"5.."}[5m]) /
            rate(app_requests_total[5m])
          ) * 100

  - name: alerts
    rules:
      - alert: HighCPUUsage
        expr: container:cpu_usage_rate * 100 > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          
      - alert: HighErrorRate
        expr: app:error_rate_percent > 5
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High error rate: {{ $value }}%"
```

## Performance Optimization

### Scrape Interval Optimization
```yaml
# Different intervals for different job types
scrape_configs:
  # Fast metrics for critical services
  - job_name: 'critical-services'
    scrape_interval: 5s
    static_configs:
      - targets: ['api:8080']
        
  # Standard interval for most services
  - job_name: 'standard-services'
    scrape_interval: 15s
    static_configs:
      - targets: ['web:8080']
      
  # Slow metrics for batch jobs
  - job_name: 'batch-jobs'
    scrape_interval: 60s
    static_configs:
      - targets: ['batch:8080']
```

### Label Optimization
```bash
# Good: Low cardinality labels
app_requests_total{method="GET", status="200"}

# Bad: High cardinality labels (avoid)
app_requests_total{user_id="12345", session_id="abc123"}

# Alternative: Use separate metric or log correlation
app_active_users{} # Count active users separately
# Log with correlation: user_id=12345, trace_id=xyz789
```

## Practice Tasks

1. **Deploy basic monitoring stack**:
   ```bash
   docker-compose -f monitoring-stack.yml up -d
   ```

2. **Create custom metrics**:
   ```python
   # Implement Counter and Histogram metrics
   ```

3. **Configure service discovery**:
   ```yaml
   # Set up Docker SD with proper relabeling
   ```

4. **Write PromQL queries**:
   ```bash
   # Query top CPU consumers, error rates, latency percentiles
   ```

## Common Issues and Solutions

### Missing Metrics
```bash
# Check target status
curl http://localhost:9090/api/v1/targets

# Verify exporter is running
curl http://localhost:9100/metrics

# Check network connectivity
docker network inspect bridge
```

### High Cardinality
```bash
# Identify high cardinality series
curl http://localhost:9090/api/v1/label/__name__/values

# Check series count per metric
curl http://localhost:9090/api/v1/series?match[]={__name__=~".+"}
```

### Query Performance
```bash
# Use recording rules for expensive queries
# Limit time ranges in queries
# Avoid regex matching on high-cardinality labels
# Use rate() instead of increase() for alerting
```

## Production Best Practices

### Metric Design
- **Follow naming conventions** (prometheus.io/docs/practices/naming)
- **Use appropriate metric types** based on data characteristics
- **Keep labels low cardinality** to prevent memory issues
- **Include units in metric names** (bytes, seconds, total)

### Collection Strategy
- **Set appropriate scrape intervals** based on change frequency
- **Use service discovery** for dynamic environments
- **Implement health checks** for critical exporters
- **Monitor Prometheus itself** with federation or remote monitoring

### Query Optimization
- **Use recording rules** for frequently accessed complex queries
- **Limit query time ranges** to reduce computational load
- **Create dashboards efficiently** with reusable queries
- **Set up proper alerts** with appropriate thresholds and timing

## Key Takeaway

Prometheus metrics collection provides comprehensive monitoring capabilities through exporters and service discovery, enabling data-driven decisions with powerful time-series querying and alerting for production container environments.