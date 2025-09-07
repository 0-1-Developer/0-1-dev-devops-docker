# Micro-Lesson 04: Image Security and Vulnerability Management

> **Anchor**: `p07-m01-l04`  
> **Duration**: 5 minutes  
> **One Key Idea**: Implement comprehensive image security through vulnerability scanning and supply chain security

## Why It Matters

Base images and dependencies contain vulnerabilities that attackers actively exploit. Without systematic vulnerability scanning, you deploy known security holes into production. Automated scanning and security gates prevent vulnerable containers from reaching production environments.

## What to Learn

Master image security fundamentals:
- **Secure base image selection criteria** - Choose images with minimal attack surface
- **Vulnerability scanning integration** - Automated security assessment
- **Multi-stage builds for security** - Minimize final image content
- **Image signing and verification** - Supply chain security

## Secure Base Image Selection

### Image Security Comparison
```dockerfile
# ❌ Vulnerable base image (DON'T USE)
FROM ubuntu:18.04  # 1000+ known vulnerabilities
RUN apt-get update && apt-get install -y python3 python3-pip curl wget git
COPY app.py /app.py
CMD ["python3", "/app.py"]

# ✅ Secure minimal base image (RECOMMENDED)
FROM python:3.11-alpine  # ~50 vulnerabilities
RUN adduser -D -u 1001 appuser
COPY --chown=appuser:appuser requirements.txt /app/
WORKDIR /app
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=appuser:appuser app.py .
USER appuser
CMD ["python", "app.py"]

# ⭐ Ultra-secure distroless image (BEST)
FROM python:3.11-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3  # ~5 vulnerabilities
COPY --from=builder /root/.local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY app.py /app/
WORKDIR /app
CMD ["app.py"]
```

## Vulnerability Scanning Pipeline

### Basic Scanning Commands
```bash
# Docker Scout (built-in)
docker scout cves myapp:latest --format json
docker scout recommendations myapp:latest

# Trivy scanning (comprehensive)
trivy image --severity HIGH,CRITICAL myapp:latest
trivy image --format sarif myapp:latest > scan-results.sarif

# Compare base image security
echo "=== Ubuntu 18.04 (BAD) ==="
docker scout cves ubuntu:18.04 --format sarif | jq '.runs[0].results | length'

echo "=== Alpine 3.18 (GOOD) ==="
docker scout cves alpine:3.18 --format sarif | jq '.runs[0].results | length'

echo "=== Distroless Python (BEST) ==="
docker scout cves gcr.io/distroless/python3 --format sarif | jq '.runs[0].results | length'
```

### Automated Security Gate
```bash
#!/bin/bash
# security-gate.sh - Automated vulnerability assessment
IMAGE=$1
CRITICAL_THRESHOLD=0
HIGH_THRESHOLD=5

if [[ -z "$IMAGE" ]]; then
    echo "Usage: $0 <image-name>"
    exit 1
fi

echo "🔍 Scanning image: $IMAGE"

# Scan image for vulnerabilities
SCAN_RESULTS=$(docker scout cves "$IMAGE" --format json 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo "❌ SCAN FAILED: Unable to scan image"
    exit 1
fi

# Extract vulnerability counts
CRITICAL=$(echo "$SCAN_RESULTS" | jq '.vulnerabilities | map(select(.severity == "CRITICAL")) | length' 2>/dev/null)
HIGH=$(echo "$SCAN_RESULTS" | jq '.vulnerabilities | map(select(.severity == "HIGH")) | length' 2>/dev/null)
MEDIUM=$(echo "$SCAN_RESULTS" | jq '.vulnerabilities | map(select(.severity == "MEDIUM")) | length' 2>/dev/null)

echo "📊 Vulnerabilities found:"
echo "   Critical: $CRITICAL"
echo "   High: $HIGH"
echo "   Medium: $MEDIUM"

# Security gate decision
if [[ $CRITICAL -gt $CRITICAL_THRESHOLD ]]; then
    echo "❌ REJECT: $CRITICAL critical vulnerabilities (max: $CRITICAL_THRESHOLD)"
    echo "🔧 Recommendation: Update base image or dependencies"
    exit 1
elif [[ $HIGH -gt $HIGH_THRESHOLD ]]; then
    echo "❌ REJECT: $HIGH high vulnerabilities (max: $HIGH_THRESHOLD)"
    echo "🔧 Recommendation: Review and patch high-severity issues"
    exit 1
else
    echo "✅ APPROVE: Security scan passed"
    echo "🚀 Image is ready for deployment"
    exit 0
fi
```

## Supply Chain Security

### Software Bill of Materials (SBOM)
```bash
# Generate SBOM for compliance and tracking
docker scout sbom myapp:latest --format json > myapp-sbom.json
docker scout sbom myapp:latest --format spdx > myapp-sbom.spdx

# Analyze SBOM for specific packages
jq '.packages[] | select(.name | contains("openssl"))' myapp-sbom.json
```

### Image Signing with Docker Content Trust
```bash
# Enable Docker Content Trust for image signing
export DOCKER_CONTENT_TRUST=1

# Push signed image
docker push myregistry.com/myapp:v1.0.0

# Verify signed image
docker pull myregistry.com/myapp:v1.0.0  # Will verify signature automatically
```

### Advanced Signing with Cosign
```bash
# Generate key pair for signing
cosign generate-key-pair

# Sign container image
cosign sign --key cosign.key myregistry.com/myapp:v1.0.0

# Verify signature
cosign verify --key cosign.pub myregistry.com/myapp:v1.0.0

# Sign with keyless (OIDC)
cosign sign myregistry.com/myapp:v1.0.0  # Uses ephemeral keys

# Attach attestation
cosign attest --predicate sbom.json --key cosign.key myregistry.com/myapp:v1.0.0
```

## CI/CD Integration

### GitHub Actions Security Pipeline
```yaml
# .github/workflows/security.yml
name: Container Security Scan

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
        
      - name: Run security scan
        run: |
          docker scout cves myapp:${{ github.sha }} \
            --format sarif \
            --output results.sarif
            
      - name: Security gate
        run: ./scripts/security-gate.sh myapp:${{ github.sha }}
        
      - name: Generate SBOM
        run: |
          docker scout sbom myapp:${{ github.sha }} \
            --format spdx \
            --output myapp-sbom.spdx
            
      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v3
        with:
          name: sbom
          path: myapp-sbom.spdx
```

## Practice Tasks

1. **Compare base image security**:
   ```bash
   # Scan different base images
   docker scout cves ubuntu:18.04
   docker scout cves alpine:3.18
   docker scout cves gcr.io/distroless/python3
   ```

2. **Implement security gate**:
   ```bash
   chmod +x security-gate.sh
   ./security-gate.sh myapp:latest
   ```

3. **Generate SBOM**:
   ```bash
   docker scout sbom myapp:latest --format json > sbom.json
   jq '.packages | length' sbom.json
   ```

4. **Test image signing**:
   ```bash
   export DOCKER_CONTENT_TRUST=1
   docker build -t localhost:5000/myapp:signed .
   docker push localhost:5000/myapp:signed
   ```

## Production Security Policy

### Vulnerability Thresholds
- **Critical**: 0 allowed (block deployment)
- **High**: ≤5 allowed (requires approval)
- **Medium**: ≤20 allowed (warning only)
- **Low**: No limit (informational)

### Base Image Guidelines
1. **Prefer distroless images** for production
2. **Use Alpine** for smaller attack surface
3. **Pin specific versions** (not `latest`)
4. **Regular base image updates** (monthly)
5. **Monitor upstream vulnerabilities**

### Scanning Schedule
- **Every PR**: Security gate scan
- **Daily**: Scheduled vulnerability scan
- **Weekly**: Base image update check
- **Monthly**: Full security audit

## Production Notes

- Use minimal base images (Alpine, Distroless) to reduce attack surface
- Automate vulnerability scanning in CI/CD pipeline
- Set security gates: 0 critical, ≤5 high vulnerabilities
- Regularly update base images and dependencies
- Implement image signing for supply chain security
- Generate and maintain SBOM for compliance and incident response
- Monitor vulnerability databases for newly disclosed issues

## Key Takeaway

Image security requires continuous vulnerability scanning, secure base image selection, and supply chain security measures to prevent known vulnerabilities from reaching production.