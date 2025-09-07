# Micro-Lesson 01: Docker Logging Drivers Configuration

> **Anchor**: `p10-m01-l01`  
> **Duration**: 3 minutes  
> **One Key Idea**: Master Docker logging driver configuration for optimal log management, rotation, and centralized collection

## Why It Matters

Docker logging drivers determine how container logs are collected, stored, and processed. The default JSON file driver is suitable for development, but production environments require more sophisticated logging strategies. Understanding driver options enables efficient log management, prevents disk exhaustion, and supports centralized logging architectures.

## What to Learn

Master Docker logging fundamentals:
- **Logging driver types** - JSON file, Fluentd, syslog, and others
- **Driver configuration** - Options for rotation, compression, and labeling
- **Centralized logging** - Integration with log aggregation systems
- **Performance considerations** - Impact on container and system performance

## Logging Driver Overview

### Available Drivers
```bash
# List available logging drivers
docker info | grep -A 10 "Logging Driver"

# Common drivers:
# - json-file (default): Local JSON files
# - fluentd: Forward to Fluentd
# - syslog: System logging
# - journald: systemd journal
# - awslogs: AWS CloudWatch
# - splunk: Splunk logging
# - none: Disable logging
```

### JSON File Driver (Default)
```bash
# Basic JSON file logging
docker run -d \
  --name json-app \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  --log-opt compress=true \
  nginx:alpine

# Advanced JSON options
docker run -d \
  --name advanced-json \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=5 \
  --log-opt compress=true \
  --log-opt labels=app,version,environment \
  --log-opt env=SERVICE_NAME,LOG_LEVEL \
  --label app=web \
  --label version=1.2.0 \
  --label environment=production \
  -e SERVICE_NAME=nginx \
  -e LOG_LEVEL=info \
  nginx:alpine
```

## Centralized Logging with Fluentd

### Fluentd Driver Configuration
```bash
# Install Fluentd container
docker run -d \
  --name fluentd \
  -p 24224:24224 \
  -p 24224:24224/udp \
  -v $(pwd)/fluent.conf:/fluentd/etc/fluent.conf:ro \
  fluent/fluentd:latest

# Application with Fluentd logging
docker run -d \
  --name fluentd-app \
  --log-driver fluentd \
  --log-opt fluentd-address=localhost:24224 \
  --log-opt tag="docker.{{.Name}}" \
  --log-opt fluentd-async=true \
  --log-opt fluentd-buffer-limit=1MB \
  nginx:alpine
```

### Fluentd Configuration
```ruby
# fluent.conf
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

# Add metadata
<filter docker.**>
  @type record_transformer
  <record>
    hostname ${hostname}
    container_name ${tag_parts[1]}
    timestamp ${time}
  </record>
</filter>

# Output to file
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
```

## Docker Compose Logging

### Service-Level Logging Configuration
```yaml
# docker-compose.yml
version: '3.8'

x-logging: &default-logging
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
    compress: "true"

services:
  web:
    image: nginx:alpine
    logging: *default-logging
    
  api:
    image: myapp:latest
    logging:
      driver: fluentd
      options:
        fluentd-address: "fluentd:24224"
        tag: "docker.api"
        
  database:
    image: postgres:15
    logging:
      driver: syslog
      options:
        syslog-address: "udp://syslog-server:514"
        tag: "postgres"

  fluentd:
    image: fluent/fluentd:latest
    ports:
      - "24224:24224"
    volumes:
      - ./fluent.conf:/fluentd/etc/fluent.conf:ro
      - fluentd-logs:/fluentd/log
```

## Daemon-Level Logging Configuration

### Global Docker Daemon Settings
```json
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true",
    "labels": "production_status,geo",
    "env": "os,customer"
  }
}
```

### Override Per Container
```bash
# Container can override daemon settings
docker run -d \
  --name override-logging \
  --log-driver syslog \
  --log-opt syslog-address=udp://192.168.1.100:514 \
  --log-opt tag="myapp" \
  myapp:latest
```

## Advanced Logging Patterns

### Structured Logging Application
```python
# structured-logger.py
import logging
import json
import sys

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            'timestamp': self.formatTime(record),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'funcName': record.funcName,
            'lineno': record.lineno
        }
        
        # Add extra fields if present
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
        if hasattr(record, 'request_id'):
            log_entry['request_id'] = record.request_id
            
        return json.dumps(log_entry)

# Configure logger
logger = logging.getLogger(__name__)
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JSONFormatter())
logger.addHandler(handler)
logger.setLevel(logging.INFO)

# Usage
logger.info("User login", extra={'user_id': 12345, 'request_id': 'req_789'})
```

### Log Aggregation with Labels
```bash
# Run application with rich labeling
docker run -d \
  --name rich-logging \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt labels=app,version,component,team,environment \
  --log-opt env=SERVICE_NAME,INSTANCE_ID,BUILD_NUMBER \
  --label app=user-service \
  --label version=2.1.0 \
  --label component=authentication \
  --label team=backend \
  --label environment=production \
  -e SERVICE_NAME=user-auth \
  -e INSTANCE_ID=auth-001 \
  -e BUILD_NUMBER=1234 \
  user-service:2.1.0
```

## Performance Considerations

### Logging Impact Analysis
```bash
# Monitor logging performance impact
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Compare with and without logging
docker run -d --name no-logs --log-driver none nginx
docker run -d --name with-logs --log-driver json-file nginx

# Check disk usage
du -sh /var/lib/docker/containers/*/
```

### Optimization Strategies
```yaml
# Optimized logging configuration
logging:
  driver: json-file
  options:
    max-size: "10m"      # Prevent large files
    max-file: "3"        # Limit file count
    compress: "true"     # Save disk space
    labels: "app,env"    # Only essential labels
```

## Practice Tasks

1. **Configure JSON logging with rotation**:
   ```bash
   docker run -d --log-driver json-file --log-opt max-size=5m --log-opt max-file=2 nginx
   ```

2. **Set up Fluentd centralized logging**:
   ```bash
   # Deploy Fluentd, configure application logging
   ```

3. **Implement structured logging**:
   ```bash
   # Create application with JSON log output
   ```

4. **Test logging performance**:
   ```bash
   # Compare resource usage with different drivers
   ```

## Common Issues and Solutions

### Large Log Files
```bash
# Check log file sizes
find /var/lib/docker/containers -name "*-json.log" -exec ls -lh {} \;

# Configure proper rotation
docker run -d --log-opt max-size=10m --log-opt max-file=3 myapp
```

### Fluentd Connection Issues
```bash
# Test Fluentd connectivity
telnet localhost 24224

# Check Fluentd logs
docker logs fluentd

# Verify network connectivity
docker network ls
docker network inspect bridge
```

### Log Parsing Problems
```bash
# Validate log format
docker logs myapp | head -5 | jq .

# Check for malformed JSON
docker logs myapp 2>&1 | grep -v "^{.*}$"
```

## Production Best Practices

### Essential Configurations
- **Always set log rotation** to prevent disk exhaustion
- **Use structured logging** for better parsing and analysis
- **Include correlation IDs** for request tracing
- **Set appropriate log levels** based on environment
- **Monitor log volume** and adjust retention accordingly

### Security Considerations
- **Sanitize sensitive data** before logging
- **Use secure transport** for centralized logging
- **Implement log retention policies** for compliance
- **Control access** to log aggregation systems

### Performance Optimization
- **Choose appropriate drivers** for your use case
- **Minimize log volume** in high-throughput applications
- **Use asynchronous logging** when possible
- **Monitor logging overhead** on application performance

## Key Takeaway

Docker logging drivers provide flexible log management capabilities, from simple local files to sophisticated centralized logging systems, enabling comprehensive observability while maintaining optimal performance and resource utilization.