# Micro-Lesson 03: Container Image Analysis and Optimization

> **Anchor**: `p10-m01-l03`  
> **Duration**: 3 minutes  
> **One Key Idea**: Master container image analysis techniques to understand image composition, identify optimization opportunities, and improve security posture

## Why It Matters

Container images are the foundation of containerized applications. Understanding image composition, layer structure, and resource utilization enables optimization for size, security, and performance. Image analysis helps identify vulnerabilities, unnecessary components, and optimization opportunities that directly impact deployment speed, storage costs, and security posture.

## What to Learn

Master container image analysis fundamentals:
- **Image layer inspection** - Understanding layer composition and history
- **Size analysis and optimization** - Identifying space-consuming components
- **Security scanning** - Vulnerability detection and assessment
- **Performance impact analysis** - Pull time and startup optimization

## Docker Image Inspection

### Basic Image Information
```bash
# Get image details
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Inspect specific image
docker inspect nginx:alpine | jq '.[0] | {
  Id: .Id,
  Size: .Size,
  Architecture: .Architecture,
  Os: .Os,
  Created: .Created,
  Author: .Author
}'

# Show image history
docker history nginx:alpine --format "table {{.CreatedBy}}\t{{.Size}}\t{{.CreatedAt}}"
```

### Layer Analysis with Dive
```bash
# Install and use Dive for layer inspection
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest myapp:latest

# Key insights from Dive:
# - Layer-by-layer size breakdown
# - Efficiency score
# - File changes per layer
# - Wasted space identification
```

## Advanced Image Analysis

### Comprehensive Analysis Script
```bash
#!/bin/bash
# image-analyzer.sh

IMAGE="$1"
REPORT_DIR="image-analysis-$(date +%Y%m%d-%H%M%S)"

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image:tag>"
  exit 1
fi

mkdir -p "$REPORT_DIR"

echo "🔍 Analyzing image: $IMAGE"
echo "=========================="

# Basic image info
echo "📊 Basic Information:" > "$REPORT_DIR/basic-info.txt"
docker inspect "$IMAGE" | jq '.[0] | {
  Id: .Id[0:12],
  Size: .Size,
  VirtualSize: .VirtualSize,
  Architecture: .Architecture,
  Os: .Os,
  Created: .Created,
  DockerVersion: .DockerVersion,
  Author: .Author
}' >> "$REPORT_DIR/basic-info.txt"

# Layer analysis
echo "🏗️  Layer Breakdown:" > "$REPORT_DIR/layers.txt"
docker history "$IMAGE" --format "{{.CreatedBy}}\t{{.Size}}\t{{.CreatedAt}}" >> "$REPORT_DIR/layers.txt"

# Export filesystem
echo "📁 Exporting filesystem..."
docker save "$IMAGE" | tar -xv -C "$REPORT_DIR" 2>/dev/null

# Find largest files
echo "📈 Largest Files:" > "$REPORT_DIR/large-files.txt"
find "$REPORT_DIR" -type f -exec ls -lh {} \; | sort -k5 -hr | head -20 >> "$REPORT_DIR/large-files.txt"

# Package analysis (if available)
if docker run --rm "$IMAGE" which apk >/dev/null 2>&1; then
  echo "📦 Installed Packages (Alpine):" > "$REPORT_DIR/packages.txt"
  docker run --rm "$IMAGE" apk list -I >> "$REPORT_DIR/packages.txt"
elif docker run --rm "$IMAGE" which dpkg >/dev/null 2>&1; then
  echo "📦 Installed Packages (Debian/Ubuntu):" > "$REPORT_DIR/packages.txt"
  docker run --rm "$IMAGE" dpkg -l >> "$REPORT_DIR/packages.txt"
elif docker run --rm "$IMAGE" which rpm >/dev/null 2>&1; then
  echo "📦 Installed Packages (RHEL/CentOS):" > "$REPORT_DIR/packages.txt"
  docker run --rm "$IMAGE" rpm -qa >> "$REPORT_DIR/packages.txt"
fi

# Security analysis
echo "🔒 Security Scan:" > "$REPORT_DIR/security.txt"
if command -v trivy >/dev/null 2>&1; then
  trivy image --severity HIGH,CRITICAL "$IMAGE" >> "$REPORT_DIR/security.txt"
else
  echo "Install Trivy for security scanning" >> "$REPORT_DIR/security.txt"
fi

echo "✅ Analysis complete: $REPORT_DIR"
```

## Size Optimization Analysis

### Image Size Comparison
```bash
# Compare similar images
images=("node:18-alpine" "node:18-slim" "node:18")
echo "Image Size Comparison:"
echo "======================"
for image in "${images[@]}"; do
  size=$(docker images "$image" --format "{{.Size}}")
  echo "$image: $size"
done

# Multi-stage build analysis
cat > Dockerfile.multistage <<EOF
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS final
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY . .
CMD ["node", "index.js"]
EOF

# Build and compare sizes
docker build -t myapp:full -f Dockerfile.full .
docker build -t myapp:multistage -f Dockerfile.multistage .
docker images | grep myapp
```

### File System Analysis
```bash
# Create container and analyze filesystem
docker run -d --name fs-analysis nginx:alpine
docker exec fs-analysis find / -type f -size +1M 2>/dev/null | head -20
docker exec fs-analysis du -sh /usr /var /etc /lib 2>/dev/null | sort -hr

# Export and analyze
docker export fs-analysis | tar -tv | awk '{print $3, $9}' | sort -nr | head -20

docker rm -f fs-analysis
```

## Security Scanning Integration

### Trivy Security Analysis
```bash
# Install Trivy scanner
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Comprehensive security scan
trivy image --severity HIGH,CRITICAL \
  --format table \
  --output security-report.txt \
  myapp:latest

# JSON format for processing
trivy image --format json \
  --output vulnerabilities.json \
  myapp:latest

# Generate SBOM
trivy image --format spdx-json \
  --output sbom.spdx.json \
  myapp:latest
```

### Docker Scout Analysis
```bash
# Enable Docker Scout (if available)
docker scout quickview myapp:latest

# Detailed vulnerability analysis
docker scout cves myapp:latest

# Compare with base image
docker scout compare --to myapp:base myapp:latest

# SBOM generation with Docker Scout
docker scout sbom myapp:latest --format spdx-json > scout-sbom.json
```

## Performance Impact Analysis

### Pull Time Measurement
```bash
#!/bin/bash
# pull-time-test.sh

images=("alpine:3.18" "ubuntu:22.04" "node:18-alpine" "node:18")

echo "Pull Time Analysis:"
echo "=================="

for image in "${images[@]}"; do
  # Remove image if exists
  docker rmi "$image" 2>/dev/null
  
  # Measure pull time
  echo -n "Pulling $image: "
  start_time=$(date +%s)
  docker pull "$image" >/dev/null 2>&1
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  
  size=$(docker images "$image" --format "{{.Size}}")
  echo "${duration}s (Size: $size)"
done
```

### Startup Performance
```python
# startup-benchmark.py
import docker
import time
import statistics

client = docker.from_env()

def measure_startup_time(image, command="echo 'hello'", runs=5):
    times = []
    
    for _ in range(runs):
        start = time.time()
        container = client.containers.run(
            image, 
            command, 
            detach=True, 
            remove=True
        )
        container.wait()
        end = time.time()
        times.append(end - start)
    
    return {
        'mean': statistics.mean(times),
        'median': statistics.median(times),
        'min': min(times),
        'max': max(times)
    }

# Test different images
images = ['alpine:3.18', 'ubuntu:22.04', 'python:3.11-alpine', 'python:3.11']

print("Startup Time Benchmark:")
print("======================")

for image in images:
    stats = measure_startup_time(image)
    print(f"{image}:")
    print(f"  Mean: {stats['mean']:.3f}s")
    print(f"  Median: {stats['median']:.3f}s")
    print(f"  Range: {stats['min']:.3f}s - {stats['max']:.3f}s")
    print()
```

## Optimization Recommendations

### Size Optimization Checklist
```dockerfile
# Optimized Dockerfile example
FROM python:3.11-alpine AS build

# Install build dependencies in single layer
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    libffi-dev

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Remove build dependencies
RUN apk del .build-deps

FROM python:3.11-alpine AS final
WORKDIR /app

# Copy only necessary files
COPY --from=build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=build /usr/local/bin /usr/local/bin

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

COPY --chown=appuser:appgroup app.py .

USER appuser
CMD ["python", "app.py"]
```

### Security Hardening
```dockerfile
# Security-focused Dockerfile
FROM python:3.11-alpine

# Update packages and remove package manager
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Create non-root user early
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup -s /bin/false

WORKDIR /app

# Set strict permissions
COPY --chown=appuser:appgroup requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt

COPY --chown=appuser:appgroup app.py .
RUN chmod 555 /app && \
    chmod 444 /app/app.py

USER appuser

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["python", "app.py"]
```

## Practice Tasks

1. **Analyze an image with Dive**:
   ```bash
   docker run --rm -it wagoodman/dive:latest nginx:alpine
   ```

2. **Create size comparison report**:
   ```bash
   # Compare alpine vs ubuntu based images
   ```

3. **Run security scan**:
   ```bash
   trivy image --severity HIGH,CRITICAL myapp:latest
   ```

4. **Measure startup performance**:
   ```bash
   # Time container creation and startup
   ```

## Common Optimization Patterns

### Remove Package Managers
```dockerfile
# Remove after installation
RUN apk add --no-cache curl && \
    curl -o /tmp/file https://example.com/file && \
    apk del curl
```

### Multi-stage Builds
```dockerfile
# Build stage
FROM golang:1.21-alpine AS build
COPY . .
RUN go build -o app

# Final stage
FROM alpine:3.18
COPY --from=build /app/app /usr/local/bin/
```

### Layer Optimization
```dockerfile
# Combine commands to reduce layers
RUN apt-get update && \
    apt-get install -y package1 package2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

## Monitoring and Alerting

### Image Size Monitoring
```python
# image-size-monitor.py
import docker
import json
from datetime import datetime

client = docker.from_env()

def collect_image_metrics():
    metrics = []
    for image in client.images.list():
        for tag in image.tags:
            metrics.append({
                'image': tag,
                'size_bytes': image.attrs['Size'],
                'created': image.attrs['Created'],
                'timestamp': datetime.utcnow().isoformat()
            })
    return metrics

# Export metrics
metrics = collect_image_metrics()
with open('image-metrics.json', 'w') as f:
    json.dump(metrics, f, indent=2)

# Alert on large images
large_images = [m for m in metrics if m['size_bytes'] > 500 * 1024 * 1024]  # 500MB
if large_images:
    print(f"⚠️ Found {len(large_images)} large images:")
    for img in large_images:
        size_mb = img['size_bytes'] / (1024 * 1024)
        print(f"  {img['image']}: {size_mb:.1f}MB")
```

## Key Takeaway

Container image analysis provides critical insights into composition, security, and performance characteristics, enabling targeted optimization for size reduction, security hardening, and improved deployment efficiency in production environments.