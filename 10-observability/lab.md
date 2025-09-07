# Phase 10 Lab: Docker Observability Hands-on Exercises

> **Objective**: Gain practical experience with Docker observability through comprehensive monitoring, logging, tracing, and performance analysis exercises.

## Lab Overview

This lab provides hands-on experience with:
- Configuring and managing Docker logging drivers
- Deploying monitoring stacks with Prometheus and Grafana
- Implementing distributed tracing with Jaeger
- Analyzing container performance and resource usage
- Building production-ready observability solutions

## Prerequisites

- Docker Engine 24.0+
- Docker Compose 2.20+
- 4GB+ available RAM
- Basic understanding of metrics and logging concepts
- Text editor for configuration files

## Lab Environment Setup

### Initial Setup Script
```bash
#!/bin/bash
# setup-observability-lab.sh

# Create lab directory structure
mkdir -p ~/docker-observability-lab/{prometheus,grafana,loki,jaeger,alertmanager,apps}
cd ~/docker-observability-lab

# Create Docker network for observability
docker network create observability-lab \
  --driver bridge \
  --subnet 172.25.0.0/16 \
  --gateway 172.25.0.1

echo "✅ Lab environment initialized"
echo "📁 Working directory: $(pwd)"
echo "🌐 Network: observability-lab (172.25.0.0/16)"
```

---

## Exercise 1: Logging Driver Configuration and Management

### Objectives
- Configure different Docker logging drivers
- Implement log rotation and compression
- Set up centralized logging with Fluentd
- Query and analyze container logs

### Step 1: JSON File Logging with Rotation

```bash
# Create test application with logging
cat > app.py <<'EOF'
import time
import json
import random
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='{"timestamp":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}'
)

logger = logging.getLogger(__name__)

def generate_log():
    levels = [logging.INFO, logging.WARNING, logging.ERROR, logging.DEBUG]
    messages = [
        "Processing request",
        "Database query executed",
        "Cache miss detected",
        "API call completed",
        "Background job started"
    ]
    
    level = random.choice(levels)
    message = random.choice(messages)
    
    # Add structured data
    data = {
        "user_id": random.randint(1000, 9999),
        "request_id": f"req_{random.randint(100000, 999999)}",
        "duration_ms": random.randint(10, 500),
        "endpoint": f"/api/v1/{random.choice(['users', 'products', 'orders'])}"
    }
    
    logger.log(level, f"{message} - {json.dumps(data)}")

if __name__ == "__main__":
    logger.info("Application started")
    while True:
        generate_log()
        time.sleep(random.uniform(0.5, 2))
EOF

# Create Dockerfile
cat > Dockerfile <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
CMD ["python", "-u", "app.py"]
EOF

# Build application
docker build -t log-generator:latest .

# Run with JSON logging and rotation
docker run -d \
  --name json-logger \
  --log-driver json-file \
  --log-opt max-size=1m \
  --log-opt max-file=3 \
  --log-opt compress=true \
  --log-opt labels=app,version,environment \
  --label app=log-generator \
  --label version=1.0.0 \
  --label environment=development \
  --network observability-lab \
  log-generator:latest

echo "✅ JSON logger deployed"
```

### Step 2: Fluentd Centralized Logging

```bash
# Create Fluentd configuration
cat > fluentd/fluent.conf <<'EOF'
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Parse JSON logs
<filter docker.**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type json
  </parse>
</filter>

# Add Docker metadata
<filter docker.**>
  @type record_transformer
  <record>
    hostname ${hostname}
    container_id ${tag_parts[1]}
    container_name ${tag_parts[2]}
    timestamp ${time}
  </record>
</filter>

# Output to stdout for testing
<match docker.**>
  @type stdout
</match>

# Store logs to file
<match docker.**>
  @type file
  path /fluentd/log/docker
  append true
  <buffer>
    @type file
    path /fluentd/log/buffer
    flush_interval 10s
  </buffer>
  <format>
    @type json
  </format>
</match>
EOF

# Deploy Fluentd
docker run -d \
  --name fluentd \
  -p 24224:24224 \
  -p 24224:24224/udp \
  -v $(pwd)/fluentd:/fluentd/etc:ro \
  -v fluentd-logs:/fluentd/log \
  --network observability-lab \
  fluent/fluentd:latest

# Run application with Fluentd driver
docker run -d \
  --name fluentd-logger \
  --log-driver fluentd \
  --log-opt fluentd-address=localhost:24224 \
  --log-opt tag="docker.{{.ID}}.{{.Name}}" \
  --log-opt fluentd-async=true \
  --network observability-lab \
  log-generator:latest

echo "✅ Fluentd centralized logging configured"
```

### Step 3: Log Analysis and Queries

```bash
# Create log analysis script
cat > analyze-logs.sh <<'EOF'
#!/bin/bash

echo "=== Log Analysis Dashboard ==="

# Check log sizes
echo -e "\n📊 Log Storage Usage:"
docker inspect json-logger | jq -r '.[0].LogPath' | xargs ls -lh

# Parse and analyze JSON logs
echo -e "\n📈 Log Level Distribution:"
docker logs json-logger 2>&1 | grep -o '"level":"[^"]*"' | sort | uniq -c | sort -rn

# Extract error logs
echo -e "\n❌ Recent Errors:"
docker logs json-logger 2>&1 | jq -r 'select(.level == "ERROR") | "\(.timestamp) - \(.message)"' | tail -5

# Performance metrics from logs
echo -e "\n⚡ Performance Statistics:"
docker logs json-logger 2>&1 | jq -r '.duration_ms' | awk '{sum+=$1; count++} END {print "Average response time: " sum/count "ms"}'

# Top endpoints
echo -e "\n🔝 Top Endpoints:"
docker logs json-logger 2>&1 | jq -r '.endpoint' | sort | uniq -c | sort -rn | head -5
EOF

chmod +x analyze-logs.sh
./analyze-logs.sh
```

### Verification
```bash
# Verify logging configuration
docker inspect json-logger | jq '.[0].HostConfig.LogConfig'

# Check Fluentd is receiving logs
docker logs fluentd | tail -20

# Query specific time range
docker logs --since 5m --until 1m json-logger | jq '.level' | sort | uniq -c
```

---

## Exercise 2: Prometheus and Grafana Monitoring Stack

### Objectives
- Deploy Prometheus for metrics collection
- Configure service discovery for containers
- Create Grafana dashboards
- Implement custom metrics

### Step 1: Deploy Monitoring Stack

```yaml
# monitoring-stack.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    networks:
      - observability-lab

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_INSTALL_PLUGINS=redis-datasource,cloudflare-app
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-data:/var/lib/grafana
    networks:
      - observability-lab
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/host'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/host:ro
    networks:
      - observability-lab

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    networks:
      - observability-lab

volumes:
  prometheus-data:
  grafana-data:

networks:
  observability-lab:
    external: true
```

### Step 2: Configure Prometheus

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'docker-lab'
    environment: 'development'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          service: 'prometheus'

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          service: 'node-exporter'

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
        labels:
          service: 'cadvisor'

  # Docker service discovery
  - job_name: 'docker-containers'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 30s
    relabel_configs:
      # Keep only running containers
      - source_labels: [__meta_docker_container_state]
        regex: running
        action: keep
      # Extract container name
      - source_labels: [__meta_docker_container_name]
        regex: '/(.*)'
        target_label: container_name
      # Extract labels
      - source_labels: [__meta_docker_container_label_app]
        target_label: app
      - source_labels: [__meta_docker_container_label_version]
        target_label: version
```

### Step 3: Deploy Custom Application with Metrics

```python
# metrics-app.py
from prometheus_client import start_http_server, Counter, Histogram, Gauge
import time
import random

# Define metrics
request_count = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
request_duration = Histogram('app_request_duration_seconds', 'Request duration', ['endpoint'])
active_users = Gauge('app_active_users', 'Active users')
error_count = Counter('app_errors_total', 'Total errors', ['type'])

def process_request():
    endpoint = random.choice(['/api/users', '/api/products', '/api/orders'])
    method = random.choice(['GET', 'POST', 'PUT', 'DELETE'])
    
    # Record metrics
    request_count.labels(method=method, endpoint=endpoint).inc()
    
    # Simulate processing time
    duration = random.uniform(0.1, 2.0)
    with request_duration.labels(endpoint=endpoint).time():
        time.sleep(duration)
    
    # Random errors
    if random.random() < 0.1:
        error_type = random.choice(['timeout', 'validation', 'database'])
        error_count.labels(type=error_type).inc()
    
    # Update active users
    active_users.set(random.randint(50, 200))

if __name__ == '__main__':
    # Start metrics server
    start_http_server(8000)
    print("Metrics server started on port 8000")
    
    while True:
        process_request()
        time.sleep(random.uniform(0.5, 2))
```

```dockerfile
# Dockerfile.metrics
FROM python:3.11-slim
RUN pip install prometheus-client
WORKDIR /app
COPY metrics-app.py .
EXPOSE 8000
CMD ["python", "-u", "metrics-app.py"]
```

```bash
# Build and run metrics application
docker build -f Dockerfile.metrics -t metrics-app:latest .

docker run -d \
  --name metrics-app \
  -p 8000:8000 \
  --network observability-lab \
  metrics-app:latest

# Deploy the monitoring stack
docker-compose -f monitoring-stack.yml up -d
```

### Step 4: Create Grafana Dashboard

```json
# grafana/provisioning/dashboards/docker-metrics.json
{
  "dashboard": {
    "title": "Docker Metrics Dashboard",
    "panels": [
      {
        "title": "Container CPU Usage",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{container_name!=\"POD\"}[5m]) * 100",
            "legendFormat": "{{container_name}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Container Memory Usage",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "container_memory_usage_bytes{container_name!=\"POD\"} / 1024 / 1024",
            "legendFormat": "{{container_name}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Request Rate",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "rate(app_requests_total[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "rate(app_errors_total[5m])",
            "legendFormat": "{{type}}"
          }
        ],
        "type": "graph"
      }
    ],
    "refresh": "5s",
    "time": {"from": "now-1h", "to": "now"}
  }
}
```

### Verification
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .job, health: .health}'

# Query metrics
curl http://localhost:9090/api/v1/query?query=up | jq '.data.result'

# Access Grafana
echo "Access Grafana at http://localhost:3000 (admin/admin123)"

# Check custom metrics
curl http://localhost:8000/metrics | grep app_
```

---

## Exercise 3: Distributed Tracing with Jaeger

### Objectives
- Deploy Jaeger for distributed tracing
- Instrument applications with OpenTelemetry
- Trace requests across multiple services
- Analyze performance bottlenecks

### Step 1: Deploy Jaeger

```yaml
# jaeger-stack.yml
version: '3.8'

services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "5775:5775/udp"   # accept zipkin.thrift
      - "6831:6831/udp"   # accept jaeger.thrift
      - "6832:6832/udp"   # accept jaeger.thrift binary
      - "5778:5778"       # serve configs
      - "16686:16686"     # serve UI
      - "14268:14268"     # accept jaeger.thrift
      - "14250:14250"     # accept model.proto
      - "9411:9411"       # Zipkin compatible endpoint
      - "4317:4317"       # OTLP gRPC
      - "4318:4318"       # OTLP HTTP
    networks:
      - observability-lab

networks:
  observability-lab:
    external: true
```

### Step 2: Create Traced Microservices

```python
# service-a.py
from flask import Flask, request
import requests
from opentelemetry import trace
from opentelemetry.exporter.jaeger import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
import time
import random

# Configure tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

jaeger_exporter = JaegerExporter(
    agent_host_name='jaeger',
    agent_port=6831,
)

span_processor = BatchSpanProcessor(jaeger_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Create Flask app
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

@app.route('/api/process')
def process():
    with tracer.start_as_current_span("process_request") as span:
        span.set_attribute("user.id", request.args.get('user_id', 'unknown'))
        
        # Simulate processing
        with tracer.start_as_current_span("validate_input"):
            time.sleep(random.uniform(0.01, 0.05))
        
        # Call service B
        with tracer.start_as_current_span("call_service_b"):
            response = requests.get('http://service-b:5001/api/data')
        
        # Process response
        with tracer.start_as_current_span("process_response"):
            time.sleep(random.uniform(0.02, 0.08))
        
        return {"status": "success", "data": response.json()}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

```python
# service-b.py
from flask import Flask
from opentelemetry import trace
from opentelemetry.exporter.jaeger import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
import time
import random

# Configure tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

jaeger_exporter = JaegerExporter(
    agent_host_name='jaeger',
    agent_port=6831,
)

span_processor = BatchSpanProcessor(jaeger_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Create Flask app
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

@app.route('/api/data')
def get_data():
    with tracer.start_as_current_span("fetch_data") as span:
        # Simulate database query
        with tracer.start_as_current_span("database_query"):
            time.sleep(random.uniform(0.05, 0.15))
            span.set_attribute("db.query", "SELECT * FROM users")
        
        # Simulate data processing
        with tracer.start_as_current_span("transform_data"):
            time.sleep(random.uniform(0.02, 0.06))
        
        return {"users": 100, "active": 85}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
```

### Step 3: Deploy Traced Services

```dockerfile
# Dockerfile.traced
FROM python:3.11-slim
RUN pip install flask opentelemetry-api opentelemetry-sdk \
    opentelemetry-instrumentation-flask opentelemetry-instrumentation-requests \
    opentelemetry-exporter-jaeger requests
WORKDIR /app
COPY service-*.py ./
CMD ["python", "-u", "service-a.py"]
```

```bash
# Deploy Jaeger
docker-compose -f jaeger-stack.yml up -d

# Build traced services
docker build -f Dockerfile.traced -t traced-service:latest .

# Run Service A
docker run -d \
  --name service-a \
  -p 5000:5000 \
  -v $(pwd)/service-a.py:/app/service-a.py:ro \
  -e JAEGER_SERVICE_NAME=service-a \
  --network observability-lab \
  traced-service:latest python -u service-a.py

# Run Service B
docker run -d \
  --name service-b \
  -p 5001:5001 \
  -v $(pwd)/service-b.py:/app/service-b.py:ro \
  -e JAEGER_SERVICE_NAME=service-b \
  --network observability-lab \
  traced-service:latest python -u service-b.py
```

### Step 4: Generate and Analyze Traces

```bash
# Generate traces
for i in {1..20}; do
  curl "http://localhost:5000/api/process?user_id=$((RANDOM % 1000))"
  sleep 1
done

# View traces in Jaeger UI
echo "Open Jaeger UI at http://localhost:16686"

# Query traces via API
curl "http://localhost:16686/api/traces?service=service-a&limit=10" | jq '.data[0]'
```

### Verification
```bash
# Check services are running
docker ps | grep -E "(service-a|service-b|jaeger)"

# Verify traces are being collected
curl http://localhost:16686/api/services | jq '.data'

# Check trace details
curl "http://localhost:16686/api/traces?service=service-a&limit=1" | \
  jq '.data[0].spans[] | {service: .process.serviceName, operation: .operationName, duration: .duration}'
```

---

## Exercise 4: Container Performance Analysis

### Objectives
- Monitor container resource usage
- Identify performance bottlenecks
- Implement performance testing
- Optimize container configurations

### Step 1: Deploy Performance Monitoring

```bash
# Create performance test application
cat > perf-app.py <<'EOF'
from flask import Flask, request
import time
import hashlib
import random
import psutil
import threading

app = Flask(__name__)

# Memory-intensive endpoint
@app.route('/memory/<int:mb>')
def memory_test(mb):
    data = []
    for _ in range(mb):
        data.append('x' * 1024 * 1024)  # 1MB string
    time.sleep(1)
    return {"allocated_mb": mb, "process_memory_mb": psutil.Process().memory_info().rss / 1024 / 1024}

# CPU-intensive endpoint
@app.route('/cpu/<int:iterations>')
def cpu_test(iterations):
    start = time.time()
    for i in range(iterations):
        hashlib.sha256(str(i).encode()).hexdigest()
    duration = time.time() - start
    return {"iterations": iterations, "duration_seconds": duration}

# I/O-intensive endpoint
@app.route('/io/<int:files>')
def io_test(files):
    for i in range(files):
        with open(f'/tmp/test_{i}.txt', 'w') as f:
            f.write('x' * 1024 * 1024)  # 1MB file
    return {"files_written": files}

# Background load generator
def background_load():
    while True:
        time.sleep(random.uniform(1, 5))
        # Generate some CPU load
        sum(i**2 for i in range(10000))

@app.route('/health')
def health():
    return {
        "status": "healthy",
        "cpu_percent": psutil.cpu_percent(),
        "memory_percent": psutil.virtual_memory().percent,
        "disk_usage": psutil.disk_usage('/').percent
    }

if __name__ == '__main__':
    # Start background load
    thread = threading.Thread(target=background_load, daemon=True)
    thread.start()
    
    app.run(host='0.0.0.0', port=5000)
EOF

# Create Dockerfile
cat > Dockerfile.perf <<'EOF'
FROM python:3.11-slim
RUN pip install flask psutil
WORKDIR /app
COPY perf-app.py .
CMD ["python", "-u", "perf-app.py"]
EOF

# Build and run performance test app
docker build -f Dockerfile.perf -t perf-app:latest .

docker run -d \
  --name perf-app \
  -p 5002:5000 \
  --memory="256m" \
  --cpus="0.5" \
  --network observability-lab \
  perf-app:latest
```

### Step 2: Performance Monitoring Script

```bash
# Create monitoring script
cat > monitor-performance.sh <<'EOF'
#!/bin/bash

CONTAINER="perf-app"
DURATION=60
INTERVAL=2

echo "📊 Container Performance Monitor"
echo "================================"
echo "Container: $CONTAINER"
echo "Duration: ${DURATION}s"
echo ""

# Create results directory
mkdir -p performance-results

# Start monitoring
echo "Time,CPU%,Memory(MB),Memory%,NetRX(KB),NetTX(KB),DiskRead(KB),DiskWrite(KB)" > performance-results/stats.csv

END=$(($(date +%s) + DURATION))

while [ $(date +%s) -lt $END ]; do
    STATS=$(docker stats $CONTAINER --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}")
    
    # Parse stats
    CPU=$(echo $STATS | cut -d',' -f1 | tr -d '%')
    MEM=$(echo $STATS | cut -d',' -f2 | cut -d'/' -f1 | tr -d ' MiB')
    MEM_PERC=$(echo $STATS | cut -d',' -f3 | tr -d '%')
    NET=$(echo $STATS | cut -d',' -f4)
    DISK=$(echo $STATS | cut -d',' -f5)
    
    # Log to CSV
    echo "$(date +%H:%M:%S),$CPU,$MEM,$MEM_PERC,$NET,$DISK" >> performance-results/stats.csv
    
    # Display current stats
    printf "\r⏱️  %s | CPU: %5s%% | Mem: %6s MB (%5s%%) | Net: %15s | Disk: %15s" \
           "$(date +%H:%M:%S)" "$CPU" "$MEM" "$MEM_PERC" "$NET" "$DISK"
    
    sleep $INTERVAL
done

echo -e "\n\n📈 Performance Summary"
echo "====================="

# Calculate averages
AVG_CPU=$(awk -F',' 'NR>1 {sum+=$2; count++} END {print sum/count}' performance-results/stats.csv)
AVG_MEM=$(awk -F',' 'NR>1 {sum+=$3; count++} END {print sum/count}' performance-results/stats.csv)
MAX_CPU=$(awk -F',' 'NR>1 {if($2>max) max=$2} END {print max}' performance-results/stats.csv)
MAX_MEM=$(awk -F',' 'NR>1 {if($3>max) max=$3} END {print max}' performance-results/stats.csv)

echo "Average CPU: ${AVG_CPU}%"
echo "Average Memory: ${AVG_MEM} MB"
echo "Peak CPU: ${MAX_CPU}%"
echo "Peak Memory: ${MAX_MEM} MB"

echo -e "\n📁 Results saved to: performance-results/stats.csv"
EOF

chmod +x monitor-performance.sh
```

### Step 3: Load Testing

```bash
# Create load test script
cat > load-test.sh <<'EOF'
#!/bin/bash

TARGET="http://localhost:5002"
echo "🚀 Starting Load Test"
echo "===================="

# Test memory usage
echo -e "\n💾 Memory Load Test:"
for mb in 10 25 50 75 100; do
    echo -n "Allocating ${mb}MB... "
    RESPONSE=$(curl -s "$TARGET/memory/$mb")
    echo $RESPONSE | jq -r '"Process Memory: \(.process_memory_mb)MB"'
    sleep 2
done

# Test CPU usage
echo -e "\n🔥 CPU Load Test:"
for iterations in 100000 500000 1000000; do
    echo -n "Running $iterations iterations... "
    RESPONSE=$(curl -s "$TARGET/cpu/$iterations")
    echo $RESPONSE | jq -r '"Duration: \(.duration_seconds)s"'
    sleep 2
done

# Test I/O operations
echo -e "\n💾 I/O Load Test:"
for files in 5 10 20; do
    echo -n "Writing $files files... "
    RESPONSE=$(curl -s "$TARGET/io/$files")
    echo $RESPONSE | jq -r '"Files written: \(.files_written)"'
    sleep 2
done

# Concurrent requests test
echo -e "\n🔄 Concurrent Requests Test:"
echo "Sending 50 concurrent requests..."

for i in {1..50}; do
    curl -s "$TARGET/cpu/10000" > /dev/null &
done
wait

echo "Load test completed!"
EOF

chmod +x load-test.sh

# Run monitoring in background
./monitor-performance.sh &
MONITOR_PID=$!

# Run load test
sleep 5
./load-test.sh

# Wait for monitoring to complete
wait $MONITOR_PID
```

### Step 4: Analyze Results

```python
# analyze-performance.py
import pandas as pd
import matplotlib.pyplot as plt

# Read performance data
df = pd.read_csv('performance-results/stats.csv')

# Create visualizations
fig, axes = plt.subplots(2, 2, figsize=(12, 8))

# CPU usage over time
axes[0, 0].plot(df.index, df['CPU%'])
axes[0, 0].set_title('CPU Usage Over Time')
axes[0, 0].set_xlabel('Time (samples)')
axes[0, 0].set_ylabel('CPU %')

# Memory usage over time
axes[0, 1].plot(df.index, df['Memory(MB)'])
axes[0, 1].set_title('Memory Usage Over Time')
axes[0, 1].set_xlabel('Time (samples)')
axes[0, 1].set_ylabel('Memory (MB)')

# Resource distribution
axes[1, 0].boxplot([df['CPU%'], df['Memory%']], labels=['CPU %', 'Memory %'])
axes[1, 0].set_title('Resource Usage Distribution')

# Correlation heatmap
import seaborn as sns
corr_data = df[['CPU%', 'Memory(MB)', 'Memory%']].corr()
sns.heatmap(corr_data, annot=True, ax=axes[1, 1])
axes[1, 1].set_title('Resource Correlation')

plt.tight_layout()
plt.savefig('performance-results/analysis.png')
print("Analysis saved to performance-results/analysis.png")

# Print statistics
print("\nPerformance Statistics:")
print(df[['CPU%', 'Memory(MB)', 'Memory%']].describe())
```

### Verification
```bash
# Check container resource limits
docker inspect perf-app | jq '.[0].HostConfig.Resources'

# Monitor real-time stats
docker stats perf-app

# Check application health
curl http://localhost:5002/health | jq .

# View performance results
cat performance-results/stats.csv | column -t -s','
```

---

## Exercise 5: Log Aggregation with Loki and Promtail

### Objectives
- Deploy Grafana Loki for log aggregation
- Configure Promtail for log collection
- Create log queries and dashboards
- Correlate logs with metrics

### Step 1: Deploy Loki Stack

```yaml
# loki-stack.yml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./loki/loki-config.yaml:/etc/loki/local-config.yaml:ro
      - loki-data:/loki
    networks:
      - observability-lab

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - ./promtail/promtail-config.yaml:/etc/promtail/config.yml:ro
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - observability-lab
    depends_on:
      - loki

volumes:
  loki-data:

networks:
  observability-lab:
    external: true
```

### Step 2: Configure Loki and Promtail

```yaml
# loki/loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://alertmanager:9093

analytics:
  reporting_enabled: false
```

```yaml
# promtail/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Docker container logs
  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*log
    
    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            time: time
            container_id: container_id
      
      - regex:
          expression: '^/var/lib/docker/containers/(?P<container_id>[^/]+)/.*'
          source: filename
      
      - labels:
          container_id:
      
      - timestamp:
          format: RFC3339Nano
          source: time
      
      - output:
          source: output

  # System logs
  - job_name: syslog
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/syslog
```

### Step 3: Deploy Log-Generating Applications

```python
# structured-logger.py
import logging
import json
import time
import random
from datetime import datetime

# Configure structured logging
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_obj = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # Add extra fields
        if hasattr(record, 'user_id'):
            log_obj['user_id'] = record.user_id
        if hasattr(record, 'request_id'):
            log_obj['request_id'] = record.request_id
        if hasattr(record, 'duration'):
            log_obj['duration'] = record.duration
            
        return json.dumps(log_obj)

# Setup logger
logger = logging.getLogger('app')
handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)
logger.setLevel(logging.INFO)

def simulate_application():
    actions = ['login', 'search', 'purchase', 'logout', 'api_call']
    levels = [logging.INFO, logging.WARNING, logging.ERROR]
    
    while True:
        action = random.choice(actions)
        level = random.choice(levels)
        user_id = random.randint(1000, 9999)
        request_id = f"req_{random.randint(100000, 999999)}"
        duration = random.uniform(0.1, 2.0)
        
        extra = {
            'user_id': user_id,
            'request_id': request_id,
            'duration': duration
        }
        
        if level == logging.ERROR:
            logger.error(f"Error processing {action}", extra=extra)
        elif level == logging.WARNING:
            logger.warning(f"Slow {action} detected", extra=extra)
        else:
            logger.info(f"Successfully completed {action}", extra=extra)
        
        time.sleep(random.uniform(0.5, 2))

if __name__ == '__main__':
    simulate_application()
```

```bash
# Deploy Loki stack
docker-compose -f loki-stack.yml up -d

# Build and run structured logger
cat > Dockerfile.logger <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY structured-logger.py .
CMD ["python", "-u", "structured-logger.py"]
EOF

docker build -f Dockerfile.logger -t structured-logger:latest .

docker run -d \
  --name structured-logger \
  --label app=structured-logger \
  --label version=1.0.0 \
  --network observability-lab \
  structured-logger:latest
```

### Step 4: Query Logs with LogQL

```bash
# Create LogQL query script
cat > query-logs.sh <<'EOF'
#!/bin/bash

LOKI_URL="http://localhost:3100"

echo "📋 Loki Log Queries"
echo "=================="

# Query recent logs
echo -e "\n1. Recent container logs:"
curl -s "$LOKI_URL/loki/api/v1/query_range" \
  --data-urlencode 'query={job="containerlogs"}' \
  --data-urlencode 'limit=5' | jq '.data.result[0].values[]'

# Query by container name
echo -e "\n2. Logs from structured-logger:"
curl -s "$LOKI_URL/loki/api/v1/query_range" \
  --data-urlencode 'query={job="containerlogs"} |= "structured-logger"' \
  --data-urlencode 'limit=5' | jq '.data.result[0].values[]'

# Query errors
echo -e "\n3. Error logs:"
curl -s "$LOKI_URL/loki/api/v1/query_range" \
  --data-urlencode 'query={job="containerlogs"} |= "ERROR"' \
  --data-urlencode 'limit=5' | jq '.data.result[0].values[]'

# Aggregate logs by level
echo -e "\n4. Log count by level:"
curl -s "$LOKI_URL/loki/api/v1/query" \
  --data-urlencode 'query=sum(rate({job="containerlogs"} [5m])) by (level)' | \
  jq '.data.result'
EOF

chmod +x query-logs.sh
./query-logs.sh
```

### Verification
```bash
# Check Loki is running
curl http://localhost:3100/ready

# Check Promtail targets
curl http://localhost:9080/targets

# View logs in Grafana
echo "Add Loki datasource in Grafana: http://localhost:3000"
echo "URL: http://loki:3100"
```

---

## Exercise 6: Complete Observability Platform

### Objectives
- Integrate all observability components
- Create unified dashboards
- Implement alerting rules
- Demonstrate troubleshooting workflows

### Step 1: Deploy Complete Stack

```yaml
# complete-observability.yml
version: '3.8'

services:
  # Metrics
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
    networks:
      - observability-lab

  # Visualization
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_INSTALL_PLUGINS=redis-datasource
    volumes:
      - ./grafana:/etc/grafana/provisioning:ro
      - grafana-data:/var/lib/grafana
    networks:
      - observability-lab

  # Logs
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki:/etc/loki:ro
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - observability-lab

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - ./promtail:/etc/promtail:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - observability-lab

  # Traces
  tempo:
    image: grafana/tempo:latest
    container_name: tempo
    command: ["-config.file=/etc/tempo.yaml"]
    volumes:
      - ./tempo/tempo.yaml:/etc/tempo.yaml:ro
      - tempo-data:/tmp/tempo
    ports:
      - "3200:3200"   # tempo
      - "4317:4317"   # otlp grpc
    networks:
      - observability-lab

  # Alerts
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager:ro
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
    networks:
      - observability-lab

volumes:
  prometheus-data:
  grafana-data:
  loki-data:
  tempo-data:
  alertmanager-data:

networks:
  observability-lab:
    external: true
```

### Step 2: Configure Alert Rules

```yaml
# prometheus/alerts.yml
groups:
  - name: container_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) * 100 > 80
        for: 2m
        labels:
          severity: warning
          component: container
        annotations:
          summary: "High CPU usage in {{ $labels.container_name }}"
          description: "Container {{ $labels.container_name }} CPU usage is {{ $value }}%"

      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 90
        for: 2m
        labels:
          severity: critical
          component: container
        annotations:
          summary: "High memory usage in {{ $labels.container_name }}"
          description: "Container {{ $labels.container_name }} memory usage is {{ $value }}%"

      - alert: ContainerRestarting
        expr: rate(container_restart_count[5m]) > 0
        for: 1m
        labels:
          severity: warning
          component: container
        annotations:
          summary: "Container {{ $labels.container_name }} is restarting"
          description: "Container has restarted {{ $value }} times in the last 5 minutes"

      - alert: HighErrorRate
        expr: rate(app_errors_total[5m]) > 0.05
        for: 2m
        labels:
          severity: critical
          component: application
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"
```

### Step 3: Create Unified Dashboard

```json
# grafana/dashboards/unified-observability.json
{
  "dashboard": {
    "title": "Unified Observability Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "datasource": "Prometheus",
        "targets": [{
          "expr": "rate(app_requests_total[5m])"
        }]
      },
      {
        "title": "Error Logs",
        "datasource": "Loki",
        "targets": [{
          "expr": "{job=\"containerlogs\"} |= \"ERROR\""
        }]
      },
      {
        "title": "Trace Duration",
        "datasource": "Tempo",
        "targets": [{
          "query": "{ .service.name = \"service-a\" }"
        }]
      },
      {
        "title": "Active Alerts",
        "datasource": "Prometheus",
        "targets": [{
          "expr": "ALERTS{alertstate=\"firing\"}"
        }]
      }
    ]
  }
}
```

### Step 4: Troubleshooting Workflow

```bash
# Create troubleshooting script
cat > troubleshoot.sh <<'EOF'
#!/bin/bash

echo "🔍 Observability Troubleshooting Workflow"
echo "========================================"

# 1. Check system health
echo -e "\n1️⃣ System Health Check:"
curl -s http://localhost:9090/api/v1/query?query=up | \
  jq -r '.data.result[] | "\(.metric.job): \(.value[1])"'

# 2. Recent errors
echo -e "\n2️⃣ Recent Errors (last 5 minutes):"
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="containerlogs"} |= "ERROR"' \
  --data-urlencode 'limit=5' \
  --data-urlencode 'since=5m' | \
  jq -r '.data.result[0].values[][1]' | head -5

# 3. High resource usage
echo -e "\n3️⃣ Top Resource Consumers:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}" | \
  sort -k2 -rn | head -5

# 4. Active alerts
echo -e "\n4️⃣ Active Alerts:"
curl -s http://localhost:9090/api/v1/alerts | \
  jq -r '.data.alerts[] | "\(.labels.alertname): \(.state)"'

# 5. Slow traces
echo -e "\n5️⃣ Slowest Operations (if Jaeger is running):"
if curl -s http://localhost:16686/api/services > /dev/null 2>&1; then
  curl -s "http://localhost:16686/api/traces?service=service-a&limit=5" | \
    jq -r '.data[]?.spans[]? | select(.duration > 100000) | "\(.operationName): \(.duration/1000)ms"' | head -5
else
  echo "Jaeger not available"
fi

echo -e "\n✅ Troubleshooting scan complete"
EOF

chmod +x troubleshoot.sh
./troubleshoot.sh
```

### Verification
```bash
# Check all services are running
docker-compose -f complete-observability.yml ps

# Verify data sources in Grafana
curl -s -u admin:admin123 http://localhost:3000/api/datasources | jq '.[].name'

# Test alert firing
curl -X POST http://localhost:9090/-/reload  # Reload Prometheus config

# Check unified dashboard
echo "Access Grafana at http://localhost:3000"
echo "Username: admin, Password: admin123"
```

---

## Lab Cleanup

### Complete Cleanup Script
```bash
#!/bin/bash
# cleanup-observability-lab.sh

echo "🧹 Cleaning up Observability Lab"
echo "================================"

# Stop all containers
echo "Stopping containers..."
docker-compose -f monitoring-stack.yml down -v
docker-compose -f jaeger-stack.yml down -v
docker-compose -f loki-stack.yml down -v
docker-compose -f complete-observability.yml down -v

# Remove individual containers
docker stop json-logger fluentd-logger fluentd metrics-app \
            service-a service-b perf-app structured-logger 2>/dev/null
docker rm json-logger fluentd-logger fluentd metrics-app \
          service-a service-b perf-app structured-logger 2>/dev/null

# Remove images
docker rmi log-generator:latest metrics-app:latest \
           traced-service:latest perf-app:latest \
           structured-logger:latest 2>/dev/null

# Remove network
docker network rm observability-lab 2>/dev/null

# Clean up files
rm -rf performance-results/
rm -f *.py *.sh Dockerfile* *.yml *.yaml

# Remove volumes
docker volume prune -f

echo "✅ Cleanup complete!"
```

---

## Lab Summary

### What You Learned

1. **Logging Drivers**
   - Configured JSON, Fluentd, and other logging drivers
   - Implemented log rotation and compression
   - Set up centralized logging

2. **Metrics Collection**
   - Deployed Prometheus and Grafana
   - Created custom metrics and dashboards
   - Configured service discovery

3. **Distributed Tracing**
   - Implemented Jaeger tracing
   - Instrumented applications with OpenTelemetry
   - Analyzed request flows

4. **Performance Analysis**
   - Monitored container resource usage
   - Conducted load testing
   - Identified performance bottlenecks

5. **Log Aggregation**
   - Deployed Loki and Promtail
   - Wrote LogQL queries
   - Correlated logs with metrics

6. **Complete Platform**
   - Integrated all observability components
   - Created unified dashboards
   - Implemented alerting and troubleshooting

### Best Practices Demonstrated

- ✅ Structured logging for better parsing
- ✅ Appropriate metric types and labels
- ✅ Sampling strategies for tracing
- ✅ Resource limits for containers
- ✅ Centralized configuration management
- ✅ Automated alerting and response
- ✅ Correlation across metrics, logs, and traces
- ✅ Performance baseline establishment

### Next Steps

1. Explore advanced Prometheus queries
2. Create custom Grafana plugins
3. Implement SLI/SLO monitoring
4. Add machine learning for anomaly detection
5. Integrate with incident management systems

---

*Congratulations! You've mastered Docker observability!* 🎉