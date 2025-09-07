# Micro-Lesson 04: Performance Budgets and SLI/SLO Implementation

> **Anchor**: `p10-m01-l04`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master performance budgets and SLI/SLO implementation for Docker environments to ensure reliable, performant service delivery with data-driven reliability targets

## Why It Matters

Performance budgets and Service Level Objectives (SLOs) transform subjective "fast enough" into quantifiable reliability targets. They enable teams to make informed decisions about feature development versus reliability work, prevent performance regression, and maintain user satisfaction. In containerized environments, these metrics guide resource allocation, scaling decisions, and infrastructure investments.

## What to Learn

Master performance budget fundamentals:
- **SLI/SLO concepts** - Service Level Indicators and Objectives
- **Error budget management** - Balancing reliability and velocity
- **Performance monitoring** - Tracking and alerting on budget consumption
- **Automated governance** - Budget enforcement in CI/CD pipelines

## SLI/SLO Foundation

### Service Level Indicators (SLIs)
```bash
# Key SLIs for containerized applications

# 1. Availability SLI
# Percentage of successful requests
availability = successful_requests / total_requests

# 2. Latency SLI  
# Percentage of requests below threshold
latency = requests_under_500ms / total_requests

# 3. Throughput SLI
# Requests handled per second
throughput = total_requests / time_window

# 4. Error Rate SLI
# Percentage of requests without errors
error_rate = (total_requests - error_requests) / total_requests
```

### Service Level Objectives (SLOs)
```yaml
# slo-definitions.yml
slos:
  web-service:
    availability:
      target: 99.9%
      window: 30d
      description: "99.9% of requests return success"
      
    latency:
      target: 95%
      threshold: 500ms
      window: 30d
      description: "95% of requests complete under 500ms"
      
    error_rate:
      target: 99.9%
      window: 7d
      description: "99.9% of requests complete without error"

  database-service:
    availability:
      target: 99.95%
      window: 30d
      
    query_latency:
      target: 90%
      threshold: 100ms
      window: 7d
```

## Implementing SLI Collection

### Prometheus SLI Metrics
```python
# sli-collector.py
from prometheus_client import Counter, Histogram, start_http_server
import time
import random
from flask import Flask

app = Flask(__name__)

# SLI Metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')
ERROR_COUNT = Counter('http_errors_total', 'Total HTTP errors', ['type'])

@app.route('/api/data')
def get_data():
    start_time = time.time()
    
    # Simulate processing
    processing_time = random.uniform(0.1, 0.8)
    time.sleep(processing_time)
    
    # Simulate occasional errors
    if random.random() < 0.02:  # 2% error rate
        REQUEST_COUNT.labels(method='GET', status='500').inc()
        ERROR_COUNT.labels(type='internal').inc()
        return "Internal Server Error", 500
    
    # Record successful request
    REQUEST_COUNT.labels(method='GET', status='200').inc()
    REQUEST_LATENCY.observe(time.time() - start_time)
    
    return {"status": "success", "data": "sample"}

@app.route('/health')
def health():
    REQUEST_COUNT.labels(method='GET', status='200').inc()
    return {"status": "healthy"}

if __name__ == '__main__':
    # Start metrics server
    start_http_server(8001)
    app.run(host='0.0.0.0', port=8000)
```

### SLO Monitoring with PromQL
```yaml
# slo-recording-rules.yml
groups:
  - name: sli_recording_rules
    interval: 30s
    rules:
      # Availability SLI
      - record: sli:availability:ratio_rate5m
        expr: |
          sum(rate(http_requests_total{status!~"5.."}[5m])) /
          sum(rate(http_requests_total[5m]))

      # Latency SLI (requests under 500ms)
      - record: sli:latency:ratio_rate5m
        expr: |
          sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m])) /
          sum(rate(http_request_duration_seconds_count[5m]))

      # Error rate SLI
      - record: sli:error_rate:ratio_rate5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) /
          sum(rate(http_requests_total[5m]))

  - name: slo_alerting_rules
    rules:
      # Fast burn alert (2% budget in 1 hour)
      - alert: AvailabilitySLOBurnRateFast
        expr: |
          (
            sli:availability:ratio_rate5m < 0.998
            and
            sli:availability:ratio_rate5m < 0.998
          )
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast burn rate on availability SLO"

      # Slow burn alert (10% budget in 6 hours)  
      - alert: AvailabilitySLOBurnRateSlow
        expr: |
          (
            sli:availability:ratio_rate30m < 0.9983
            and
            sli:availability:ratio_rate6h < 0.9983
          )
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Slow burn rate on availability SLO"
```

## Error Budget Implementation

### Error Budget Calculator
```python
# error-budget-calculator.py
from datetime import datetime, timedelta
import json

class ErrorBudgetCalculator:
    def __init__(self, slo_target, time_window_days):
        self.slo_target = slo_target  # e.g., 0.999 for 99.9%
        self.time_window_days = time_window_days
        self.error_budget = 1 - slo_target  # e.g., 0.001 for 99.9% SLO
        
    def calculate_budget_minutes(self):
        """Calculate error budget in minutes"""
        total_minutes = self.time_window_days * 24 * 60
        return total_minutes * self.error_budget
        
    def calculate_current_error_rate(self, total_requests, error_requests):
        """Calculate current error rate"""
        if total_requests == 0:
            return 0
        return error_requests / total_requests
        
    def calculate_budget_consumption(self, total_requests, error_requests):
        """Calculate how much error budget has been consumed"""
        current_error_rate = self.calculate_current_error_rate(total_requests, error_requests)
        if self.error_budget == 0:
            return 0
        return current_error_rate / self.error_budget
        
    def calculate_burn_rate(self, current_error_rate):
        """Calculate current burn rate (how fast we're consuming budget)"""
        if self.error_budget == 0:
            return 0
        return current_error_rate / self.error_budget
        
    def time_to_exhaustion(self, current_burn_rate):
        """Estimate time until budget exhaustion at current burn rate"""
        if current_burn_rate <= 0:
            return float('inf')
        
        budget_remaining = 1.0  # Assuming we start with full budget
        hours_remaining = budget_remaining / current_burn_rate
        return timedelta(hours=hours_remaining)

# Example usage
if __name__ == '__main__':
    # 99.9% SLO over 30 days
    calculator = ErrorBudgetCalculator(slo_target=0.999, time_window_days=30)
    
    print(f"Error Budget: {calculator.error_budget:.1%}")
    print(f"Budget in minutes: {calculator.calculate_budget_minutes():.1f}")
    
    # Simulate current metrics
    total_requests = 1000000
    error_requests = 1500
    
    consumption = calculator.calculate_budget_consumption(total_requests, error_requests)
    burn_rate = calculator.calculate_burn_rate(error_requests / total_requests)
    
    print(f"Budget consumption: {consumption:.1%}")
    print(f"Current burn rate: {burn_rate:.2f}x")
    
    if burn_rate > 1:
        time_left = calculator.time_to_exhaustion(burn_rate)
        print(f"Budget exhaustion in: {time_left}")
```

### Error Budget Monitoring Dashboard
```json
{
  "dashboard": {
    "title": "SLO and Error Budget Monitoring",
    "panels": [
      {
        "title": "SLO Status",
        "type": "stat",
        "targets": [
          {
            "expr": "sli:availability:ratio_rate30d",
            "legendFormat": "30d Availability"
          }
        ],
        "thresholds": [
          {"color": "red", "value": 0.999},
          {"color": "green", "value": 0.9995}
        ]
      },
      {
        "title": "Error Budget Burn Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - sli:availability:ratio_rate1h) / (1 - 0.999) * 24",
            "legendFormat": "1h burn rate"
          },
          {
            "expr": "(1 - sli:availability:ratio_rate6h) / (1 - 0.999) * 4",
            "legendFormat": "6h burn rate"
          }
        ],
        "yAxes": [
          {"label": "Burn Rate (x normal)"}
        ]
      },
      {
        "title": "Error Budget Remaining",
        "type": "stat",
        "targets": [
          {
            "expr": "1 - ((1 - sli:availability:ratio_rate30d) / (1 - 0.999))",
            "legendFormat": "Budget Remaining"
          }
        ],
        "thresholds": [
          {"color": "red", "value": 0.1},
          {"color": "yellow", "value": 0.25},
          {"color": "green", "value": 0.5}
        ]
      }
    ]
  }
}
```

## Performance Budget Enforcement

### CI/CD Performance Gates
```yaml
# .github/workflows/performance-gate.yml
name: Performance Budget Gate

on:
  pull_request:
    branches: [main]

jobs:
  performance-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build application
        run: docker build -t test-app .
        
      - name: Start application
        run: |
          docker run -d --name app -p 8080:8080 test-app
          sleep 30
          
      - name: Run performance tests
        run: |
          # Load testing with k6
          docker run --rm -v $(pwd)/k6:/scripts \
            loadimpact/k6 run --out json=/scripts/results.json /scripts/performance-test.js
            
      - name: Evaluate performance budget
        run: |
          python scripts/evaluate-budget.py k6/results.json
          
      - name: Comment PR with results
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('budget-results.json'));
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Performance Budget Results:\n${results.summary}`
            });
```

### Performance Budget Evaluation Script
```python
# evaluate-budget.py
import json
import sys

def evaluate_performance_budget(results_file):
    # Performance budgets
    budgets = {
        'response_time_p95': 500,  # ms
        'response_time_p99': 1000,  # ms
        'error_rate': 0.01,  # 1%
        'throughput_min': 100,  # requests/second
    }
    
    # Load test results
    with open(results_file) as f:
        results = json.load(f)
    
    # Extract metrics
    metrics = {
        'response_time_p95': results['metrics']['http_req_duration']['p(95)'],
        'response_time_p99': results['metrics']['http_req_duration']['p(99)'],
        'error_rate': results['metrics']['http_req_failed']['rate'],
        'throughput': results['metrics']['http_reqs']['rate'],
    }
    
    # Evaluate budget
    violations = []
    for metric, value in metrics.items():
        budget = budgets.get(metric)
        if budget is None:
            continue
            
        if metric == 'throughput_min':
            if value < budget:
                violations.append(f"{metric}: {value:.1f} < {budget} (budget)")
        elif metric == 'error_rate':
            if value > budget:
                violations.append(f"{metric}: {value:.3f} > {budget} (budget)")
        else:
            if value > budget:
                violations.append(f"{metric}: {value:.1f}ms > {budget}ms (budget)")
    
    # Generate report
    report = {
        'metrics': metrics,
        'budgets': budgets,
        'violations': violations,
        'passed': len(violations) == 0
    }
    
    # Save report
    with open('budget-results.json', 'w') as f:
        json.dump(report, f, indent=2)
    
    # Generate summary
    summary = "✅ Performance budget passed" if report['passed'] else "❌ Performance budget violated"
    if violations:
        summary += "\n\nViolations:\n" + "\n".join(f"- {v}" for v in violations)
    
    report['summary'] = summary
    
    # Exit with error code if budget violated
    if not report['passed']:
        print(summary)
        sys.exit(1)
    else:
        print(summary)
        sys.exit(0)

if __name__ == '__main__':
    evaluate_performance_budget(sys.argv[1])
```

## Container Resource Budgets

### Resource Limit Enforcement
```yaml
# resource-budgets.yml
version: '3.8'

services:
  web:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.1'
          memory: 128M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  database:
    image: postgres:15
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.2'
          memory: 256M
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
```

### Resource Budget Monitoring
```python
# resource-monitor.py
import docker
import time
import json
from datetime import datetime

client = docker.from_env()

def collect_resource_metrics():
    metrics = []
    
    for container in client.containers.list():
        try:
            stats = container.stats(stream=False)
            
            # Calculate CPU percentage
            cpu_delta = stats['cpu_stats']['cpu_usage']['total_usage'] - \
                       stats['precpu_stats']['cpu_usage']['total_usage']
            system_delta = stats['cpu_stats']['system_cpu_usage'] - \
                          stats['precpu_stats']['system_cpu_usage']
            
            cpu_percent = 0
            if system_delta > 0:
                cpu_percent = (cpu_delta / system_delta) * 100
            
            # Memory usage
            memory_usage = stats['memory_stats'].get('usage', 0)
            memory_limit = stats['memory_stats'].get('limit', 0)
            memory_percent = (memory_usage / memory_limit) * 100 if memory_limit > 0 else 0
            
            # Network I/O
            network_rx = network_tx = 0
            networks = stats.get('networks', {})
            for net in networks.values():
                network_rx += net.get('rx_bytes', 0)
                network_tx += net.get('tx_bytes', 0)
            
            metrics.append({
                'container': container.name,
                'cpu_percent': cpu_percent,
                'memory_usage_mb': memory_usage / (1024 * 1024),
                'memory_percent': memory_percent,
                'network_rx_mb': network_rx / (1024 * 1024),
                'network_tx_mb': network_tx / (1024 * 1024),
                'timestamp': datetime.utcnow().isoformat()
            })
            
        except Exception as e:
            print(f"Error collecting stats for {container.name}: {e}")
    
    return metrics

# Resource budget violations
def check_budget_violations(metrics):
    violations = []
    
    for metric in metrics:
        if metric['cpu_percent'] > 80:
            violations.append({
                'container': metric['container'],
                'type': 'cpu',
                'value': metric['cpu_percent'],
                'threshold': 80
            })
            
        if metric['memory_percent'] > 85:
            violations.append({
                'container': metric['container'],
                'type': 'memory',
                'value': metric['memory_percent'],
                'threshold': 85
            })
    
    return violations

if __name__ == '__main__':
    while True:
        metrics = collect_resource_metrics()
        violations = check_budget_violations(metrics)
        
        if violations:
            print(f"⚠️  Resource budget violations detected:")
            for violation in violations:
                print(f"  {violation['container']}: {violation['type']} = {violation['value']:.1f}% > {violation['threshold']}%")
        
        # Export metrics
        with open('resource-metrics.json', 'w') as f:
            json.dump(metrics, f, indent=2)
        
        time.sleep(60)
```

## Practice Tasks

1. **Define SLOs for your service**:
   ```yaml
   # Create SLO definitions with targets and windows
   ```

2. **Implement SLI collection**:
   ```python
   # Add Prometheus metrics to track SLIs
   ```

3. **Create error budget dashboard**:
   ```json
   # Build Grafana dashboard for budget monitoring
   ```

4. **Set up performance gates**:
   ```yaml
   # Add CI/CD pipeline performance validation
   ```

## Alerting Strategy

### Multi-Window Alerting
```yaml
# Multi-window SLO alerts
- alert: ErrorBudgetBurnRateFast
  expr: |
    (
      (1 - sli:availability:ratio_rate1h) > (14.4 * (1 - 0.999))
      and
      (1 - sli:availability:ratio_rate5m) > (14.4 * (1 - 0.999))
    )
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "High burn rate will exhaust 2% of error budget in 1h"

- alert: ErrorBudgetBurnRateSlow
  expr: |
    (
      (1 - sli:availability:ratio_rate6h) > (6 * (1 - 0.999))
      and
      (1 - sli:availability:ratio_rate30m) > (6 * (1 - 0.999))
    )
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "Moderate burn rate will exhaust 10% of error budget in 6h"
```

## Key Takeaway

Performance budgets and SLI/SLO implementation provide quantifiable reliability targets that enable data-driven decisions about feature velocity versus reliability investment, ensuring sustainable service delivery with measurable user experience guarantees.