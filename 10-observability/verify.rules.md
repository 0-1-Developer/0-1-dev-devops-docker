# Phase 10 Verification Rules: Docker Observability

> **Purpose**: Validate Docker observability implementation including logging, metrics, tracing, and performance monitoring  
> **Scope**: Comprehensive verification of monitoring stack and observability practices

## 🔍 Verification Overview

This verification ensures mastery of:
- Docker logging drivers and centralized logging
- Metrics collection with Prometheus and Grafana
- Distributed tracing implementation
- Container performance analysis
- Log aggregation and correlation
- Production-ready observability stacks

## 📋 Rule 1: Logging Configuration

### Verification Criteria
- [ ] Multiple logging drivers configured
- [ ] Log rotation and compression enabled
- [ ] Centralized logging operational
- [ ] Structured logging implemented

### Validation Commands
```bash
# Check logging driver configuration
docker inspect json-logger | jq '.[0].HostConfig.LogConfig'

# Verify log rotation settings
docker inspect json-logger | jq '.[0].HostConfig.LogConfig.Config'

# Test Fluentd connectivity
docker logs fluentd | grep "listening"

# Verify structured logs
docker logs json-logger | head -5 | jq '.'
```

### Success Indicators
- JSON logging with size limits configured
- Fluentd receiving and processing logs
- Log files rotating at specified thresholds
- Structured JSON logs properly formatted

### Failure Remediation
```bash
# Fix logging driver issues
docker run -d \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp

# Restart Fluentd
docker restart fluentd

# Check log permissions
ls -la /var/lib/docker/containers/*/

# Verify Fluentd config
docker exec fluentd cat /fluentd/etc/fluent.conf
```

## 📋 Rule 2: Metrics Collection

### Verification Criteria
- [ ] Prometheus successfully scraping targets
- [ ] All exporters reporting metrics
- [ ] Service discovery working
- [ ] Custom metrics exposed

### Validation Commands
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .job, health: .health}'

# Verify metrics are being collected
curl http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {job: .metric.job, status: .value[1]}'

# Check cAdvisor metrics
curl http://localhost:8080/metrics | grep container_cpu

# Verify custom application metrics
curl http://localhost:8000/metrics | grep app_
```

### Success Indicators
- All targets showing "up" status
- Metrics queryable in Prometheus
- cAdvisor reporting container metrics
- Custom application metrics visible

### Failure Remediation
```bash
# Check Prometheus configuration
docker exec prometheus cat /etc/prometheus/prometheus.yml

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload

# Verify network connectivity
docker network inspect observability-lab

# Check exporter logs
docker logs node-exporter
docker logs cadvisor
```

## 📋 Rule 3: Grafana Dashboards

### Verification Criteria
- [ ] Grafana accessible and configured
- [ ] Data sources connected
- [ ] Dashboards displaying data
- [ ] Alerts configured

### Validation Commands
```bash
# Check Grafana status
curl -s http://localhost:3000/api/health | jq .

# Verify data sources
curl -s -u admin:admin123 http://localhost:3000/api/datasources | jq '.[].name'

# List dashboards
curl -s -u admin:admin123 http://localhost:3000/api/search | jq '.[].title'

# Check alert rules
curl -s -u admin:admin123 http://localhost:3000/api/ruler/grafana/api/v1/rules | jq .
```

### Success Indicators
- Grafana UI accessible at port 3000
- Prometheus data source connected
- Dashboards showing real-time data
- No data source errors

### Failure Remediation
```bash
# Reset Grafana admin password
docker exec grafana grafana-cli admin reset-admin-password admin123

# Verify data source connectivity
docker exec grafana wget -O- http://prometheus:9090/api/v1/query?query=up

# Check Grafana logs
docker logs grafana | grep ERROR

# Recreate provisioning
docker exec grafana ls -la /etc/grafana/provisioning/
```

## 📋 Rule 4: Distributed Tracing

### Verification Criteria
- [ ] Jaeger UI accessible
- [ ] Services sending traces
- [ ] Trace correlation working
- [ ] Sampling configured correctly

### Validation Commands
```bash
# Check Jaeger services
curl http://localhost:16686/api/services | jq '.data'

# Verify traces are being collected
curl "http://localhost:16686/api/traces?service=service-a&limit=5" | jq '.data | length'

# Check trace details
curl "http://localhost:16686/api/traces?service=service-a&limit=1" | \
  jq '.data[0].spans[] | {service: .process.serviceName, operation: .operationName}'

# Verify OpenTelemetry configuration
docker logs service-a | grep -i "jaeger"
```

### Success Indicators
- Jaeger UI accessible at port 16686
- Multiple services visible in Jaeger
- Traces showing complete request flow
- Span relationships correctly displayed

### Failure Remediation
```bash
# Check Jaeger is running
docker ps | grep jaeger

# Verify agent connectivity
docker exec service-a nc -zv jaeger 6831

# Check OpenTelemetry configuration
docker exec service-a env | grep JAEGER

# Restart tracing services
docker restart jaeger service-a service-b
```

## 📋 Rule 5: Log Aggregation

### Verification Criteria
- [ ] Loki operational and receiving logs
- [ ] Promtail collecting container logs
- [ ] LogQL queries working
- [ ] Log correlation with metrics

### Validation Commands
```bash
# Check Loki status
curl http://localhost:3100/ready

# Verify Promtail targets
curl http://localhost:9080/targets | grep -A5 "Ready Targets"

# Query logs via API
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="containerlogs"}' \
  --data-urlencode 'limit=5' | jq '.data.result | length'

# Test LogQL queries
curl -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query=rate({job="containerlogs"}[5m])' | jq '.data.result'
```

### Success Indicators
- Loki returning "ready" status
- Promtail showing active targets
- Logs queryable through API
- LogQL aggregations working

### Failure Remediation
```bash
# Check Loki configuration
docker exec loki cat /etc/loki/local-config.yaml

# Verify Promtail can read logs
docker exec promtail ls -la /var/lib/docker/containers/

# Check Promtail configuration
docker exec promtail cat /etc/promtail/config.yml

# Restart log aggregation stack
docker restart loki promtail
```

## 📋 Rule 6: Performance Monitoring

### Verification Criteria
- [ ] Resource metrics being collected
- [ ] Performance baselines established
- [ ] Resource limits enforced
- [ ] Performance dashboards operational

### Validation Commands
```bash
# Check container resource usage
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Verify resource limits
docker inspect perf-app | jq '.[0].HostConfig.Resources'

# Query performance metrics
curl -s http://localhost:9090/api/v1/query \
  --data-urlencode 'query=rate(container_cpu_usage_seconds_total[5m])' | \
  jq '.data.result[] | {container: .metric.container_name, cpu: .value[1]}'

# Check memory metrics
curl -s http://localhost:9090/api/v1/query \
  --data-urlencode 'query=container_memory_usage_bytes' | \
  jq '.data.result[] | {container: .metric.container_name, memory: (.value[1] | tonumber / 1024 / 1024)}'
```

### Success Indicators
- CPU and memory metrics available
- Resource limits properly configured
- Performance data trending over time
- No resource constraint violations

### Failure Remediation
```bash
# Fix cAdvisor permissions
docker run --privileged --rm cadvisor

# Update container resource limits
docker update --memory="512m" --cpus="1.0" myapp

# Verify metrics endpoint
curl http://localhost:8080/metrics | head -20

# Check for metric gaps
curl -s http://localhost:9090/api/v1/query_range \
  --data-urlencode 'query=up{job="cadvisor"}' \
  --data-urlencode 'start=1h' | jq '.data.result[0].values'
```

## 🔬 Advanced Verification Scenarios

### Scenario 1: End-to-End Observability Test
```bash
#!/bin/bash
echo "🔍 End-to-End Observability Test"

# Generate test load
for i in {1..10}; do
  curl http://localhost:5000/api/process &
done
wait

# Check metrics
echo "Metrics collected:"
curl -s http://localhost:9090/api/v1/query?query=app_requests_total | \
  jq '.data.result | length'

# Check logs
echo "Logs collected:"
curl -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={container_name="service-a"}' \
  --data-urlencode 'limit=10' | jq '.data.result | length'

# Check traces
echo "Traces collected:"
curl -s "http://localhost:16686/api/traces?service=service-a&limit=10" | \
  jq '.data | length'

echo "✅ Observability stack operational"
```

### Scenario 2: Alert Testing
```bash
#!/bin/bash
echo "🚨 Alert Testing Scenario"

# Trigger high CPU alert
docker run -d --name cpu-stress --rm alpine sh -c "while true; do :; done"
sleep 120

# Check if alert fired
curl -s http://localhost:9090/api/v1/alerts | \
  jq '.data.alerts[] | select(.labels.alertname=="HighCPUUsage")'

# Clean up
docker stop cpu-stress

echo "✅ Alert system verified"
```

### Scenario 3: Log Correlation Test
```bash
#!/bin/bash
echo "🔗 Log Correlation Test"

REQUEST_ID="test-$(date +%s)"

# Generate correlated events
curl -H "X-Request-ID: $REQUEST_ID" http://localhost:5000/api/process

# Query metrics for request
echo "Metrics for request $REQUEST_ID:"
curl -s http://localhost:9090/api/v1/query \
  --data-urlencode "query=app_request_duration_seconds{request_id=\"$REQUEST_ID\"}" | \
  jq '.data.result'

# Query logs for request
echo "Logs for request $REQUEST_ID:"
curl -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode "query={job=\"containerlogs\"} |= \"$REQUEST_ID\"" | \
  jq '.data.result[0].values'

# Query traces for request
echo "Traces for request $REQUEST_ID:"
curl -s "http://localhost:16686/api/traces?service=service-a&tags={\"request.id\":\"$REQUEST_ID\"}" | \
  jq '.data[0].spans | length'

echo "✅ Correlation verified"
```

## 📊 Verification Results Matrix

| Verification Rule | Status | Score | Notes |
|-------------------|---------|-------|-------|
| **Logging Configuration** | ⚪ Pending | 0/15 | Logging drivers and centralization |
| **Metrics Collection** | ⚪ Pending | 0/20 | Prometheus and exporters |
| **Grafana Dashboards** | ⚪ Pending | 0/15 | Visualization and dashboards |
| **Distributed Tracing** | ⚪ Pending | 0/20 | Jaeger and OpenTelemetry |
| **Log Aggregation** | ⚪ Pending | 0/15 | Loki and Promtail |
| **Performance Monitoring** | ⚪ Pending | 0/15 | Resource monitoring |
| **Total Score** | ⚪ Pending | 0/100 | Overall verification status |

### Scoring Criteria
- **90-100**: Excellent - Production-ready observability
- **80-89**: Good - Minor improvements needed
- **70-79**: Satisfactory - Some gaps to address
- **60-69**: Needs Work - Significant improvements required
- **Below 60**: Unsatisfactory - Major gaps in observability

## 🔧 Automated Verification Script

### Complete Verification Runner
```bash
#!/bin/bash
# verify-phase10.sh

echo "🔍 Phase 10: Observability Verification"
echo "========================================"

SCORE=0
TOTAL_TESTS=6

# Test 1: Logging Configuration (15 points)
echo "Test 1: Logging Configuration"
if docker inspect json-logger 2>/dev/null | jq -e '.[0].HostConfig.LogConfig.Type == "json-file"' > /dev/null; then
  echo "✅ Logging drivers configured"
  SCORE=$((SCORE + 15))
else
  echo "❌ Logging configuration missing"
fi

# Test 2: Metrics Collection (20 points)
echo "Test 2: Metrics Collection"
if curl -s http://localhost:9090/api/v1/targets | jq -e '.data.activeTargets | length > 0' > /dev/null 2>&1; then
  echo "✅ Prometheus collecting metrics"
  SCORE=$((SCORE + 20))
else
  echo "❌ Metrics collection not working"
fi

# Test 3: Grafana Dashboards (15 points)
echo "Test 3: Grafana Dashboards"
if curl -s http://localhost:3000/api/health | jq -e '.database == "ok"' > /dev/null 2>&1; then
  echo "✅ Grafana operational"
  SCORE=$((SCORE + 15))
else
  echo "❌ Grafana not accessible"
fi

# Test 4: Distributed Tracing (20 points)
echo "Test 4: Distributed Tracing"
if curl -s http://localhost:16686/api/services | jq -e '.data | length > 0' > /dev/null 2>&1; then
  echo "✅ Jaeger collecting traces"
  SCORE=$((SCORE + 20))
else
  echo "❌ Tracing not configured"
fi

# Test 5: Log Aggregation (15 points)
echo "Test 5: Log Aggregation"
if curl -s http://localhost:3100/ready | grep -q "ready" 2>/dev/null; then
  echo "✅ Loki aggregating logs"
  SCORE=$((SCORE + 15))
else
  echo "❌ Log aggregation not working"
fi

# Test 6: Performance Monitoring (15 points)
echo "Test 6: Performance Monitoring"
if curl -s http://localhost:8080/metrics | grep -q "container_memory_usage_bytes" 2>/dev/null; then
  echo "✅ Performance metrics available"
  SCORE=$((SCORE + 15))
else
  echo "❌ Performance monitoring missing"
fi

echo "========================================"
echo "Final Score: $SCORE/100"

if [ $SCORE -ge 90 ]; then
  echo "🎉 Excellent! Production-ready observability"
  exit 0
elif [ $SCORE -ge 70 ]; then
  echo "👍 Good progress, minor improvements needed"
  exit 0
else
  echo "⚠️  Significant improvements required"
  exit 1
fi
```

## 📝 Verification Checklist

### Pre-Verification Setup
- [ ] Docker daemon configured for metrics
- [ ] Network connectivity verified
- [ ] Storage space available for logs/metrics
- [ ] Time synchronization configured

### Core Functionality Tests
- [ ] Logging drivers operational
- [ ] Metrics being collected
- [ ] Dashboards displaying data
- [ ] Traces being captured
- [ ] Logs being aggregated
- [ ] Alerts firing correctly

### Advanced Feature Tests
- [ ] Log rotation working
- [ ] Service discovery operational
- [ ] Trace correlation functional
- [ ] Performance baselines established
- [ ] Alert routing configured

### Production Readiness
- [ ] High availability configured
- [ ] Backup procedures tested
- [ ] Security hardening applied
- [ ] Documentation complete
- [ ] Runbooks prepared

---

💡 **Verification Success**: Achieving 80+ points indicates production-ready Docker observability with comprehensive monitoring, logging, and tracing capabilities.