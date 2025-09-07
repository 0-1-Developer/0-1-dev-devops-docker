# Micro-Lesson 04: SBOM Generation and Supply Chain Security

> **Anchor**: `p08-m01-l04`  
> **Duration**: 5 minutes  
> **One Key Idea**: Master Software Bill of Materials (SBOM) generation for container supply chain security, compliance, and vulnerability management

## Why It Matters

Modern container images contain hundreds of components from multiple sources, creating complex supply chain risks. Without visibility into these components, organizations cannot assess vulnerabilities, ensure compliance, or respond to security incidents effectively. SBOM generation provides complete transparency into container composition, enabling proactive security management and regulatory compliance.

## What to Learn

Master SBOM fundamentals for container security:
- **SBOM formats and standards** - SPDX, CycloneDX, and SWID compliance
- **Automated SBOM generation** - Integration with build and CI/CD processes
- **Supply chain security** - Vulnerability tracking and dependency management
- **Compliance and attestation** - Regulatory requirements and audit trails

## SBOM Formats and Standards

### SPDX (Software Package Data Exchange)
```bash
# Generate SPDX-format SBOM
docker scout sbom myapp:latest --format spdx-json > myapp-sbom.spdx.json

# SPDX example structure
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "myapp:latest",
  "documentNamespace": "https://example.com/spdxdocs/myapp-latest",
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-alpine",
      "name": "alpine",
      "versionInfo": "3.18.4",
      "downloadLocation": "https://hub.docker.com/_/alpine",
      "filesAnalyzed": false,
      "licenseConcluded": "MIT",
      "licenseDeclared": "MIT"
    }
  ]
}
```

### CycloneDX Format
```bash
# Generate CycloneDX-format SBOM
syft packages myapp:latest -o cyclonedx-json > myapp-sbom.cyclonedx.json

# CycloneDX example structure
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:12345678-1234-1234-1234-123456789012",
  "version": 1,
  "metadata": {
    "timestamp": "2024-01-15T10:30:00Z",
    "component": {
      "type": "container",
      "name": "myapp",
      "version": "latest"
    }
  },
  "components": [
    {
      "type": "library",
      "name": "openssl",
      "version": "3.1.4",
      "purl": "pkg:apk/alpine/openssl@3.1.4?arch=x86_64",
      "licenses": [{"license": {"name": "OpenSSL"}}]
    }
  ]
}
```

## Automated SBOM Generation

### Docker BuildKit SBOM Integration
```bash
# Generate SBOM during build
docker buildx build \
  --sbom=true \
  --platform linux/amd64,linux/arm64 \
  --tag myapp:with-sbom \
  --push \
  .

# Extract SBOM from built image
docker buildx imagetools inspect myapp:with-sbom --format "{{ json .SBOM }}"
```

### Multi-Tool SBOM Generation
```dockerfile
# Multi-stage build with SBOM generation
FROM alpine:3.18 AS base
RUN apk add --no-cache curl git openssl

FROM base AS app
COPY app.py requirements.txt ./
RUN pip install -r requirements.txt

# SBOM generation stage
FROM aquasec/trivy:latest AS sbom-generator
COPY --from=app / /rootfs
RUN trivy rootfs --format spdx-json --output /sbom.spdx.json /rootfs

# Final stage with embedded SBOM
FROM app
COPY --from=sbom-generator /sbom.spdx.json /sbom/
LABEL org.opencontainers.image.sbom="/sbom/sbom.spdx.json"
```

### Comprehensive SBOM Workflow
```bash
#!/bin/bash
# comprehensive-sbom.sh

IMAGE="myregistry.com/myapp:v1.0.0"
SBOM_DIR="./sbom-reports"

mkdir -p $SBOM_DIR

echo "🔍 Generating comprehensive SBOM for $IMAGE"

# 1. Syft SBOM generation
echo "Generating Syft SBOM..."
syft packages $IMAGE -o spdx-json > $SBOM_DIR/syft-sbom.spdx.json
syft packages $IMAGE -o cyclonedx-json > $SBOM_DIR/syft-sbom.cyclonedx.json

# 2. Docker Scout SBOM
echo "Generating Docker Scout SBOM..."
docker scout sbom $IMAGE --format spdx-json > $SBOM_DIR/scout-sbom.spdx.json

# 3. Trivy SBOM
echo "Generating Trivy SBOM..."
trivy image --format spdx-json --output $SBOM_DIR/trivy-sbom.spdx.json $IMAGE

# 4. SBOM comparison and analysis
echo "Analyzing SBOM differences..."
jq '.packages | length' $SBOM_DIR/syft-sbom.spdx.json
jq '.packages | length' $SBOM_DIR/scout-sbom.spdx.json
jq '.packages | length' $SBOM_DIR/trivy-sbom.spdx.json

# 5. Generate SBOM summary
jq -r '.packages[] | "\(.name):\(.versionInfo)"' $SBOM_DIR/syft-sbom.spdx.json | \
  sort | uniq > $SBOM_DIR/package-list.txt

echo "✅ SBOM generation complete in $SBOM_DIR"
```

## CI/CD SBOM Integration

### GitHub Actions SBOM Workflow
```yaml
name: SBOM Generation and Security

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  sbom-security:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Build image
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          push: true
          
      - name: Generate SBOM with Syft
        uses: anchore/sbom-action@v0
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: spdx-json
          output-file: sbom.spdx.json
          
      - name: Generate SBOM with Docker Scout
        run: |
          docker scout sbom ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
            --format spdx-json \
            --output scout-sbom.spdx.json
            
      - name: Upload SBOM artifacts
        uses: actions/upload-artifact@v3
        with:
          name: sbom-reports
          path: |
            sbom.spdx.json
            scout-sbom.spdx.json
            
      - name: Sign SBOM with Cosign
        uses: sigstore/cosign-installer@v3
        
      - name: Attach SBOM to image
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          cosign attest --predicate sbom.spdx.json \
            --type spdx \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

### GitLab CI SBOM Pipeline
```yaml
sbom-generation:
  stage: security
  image: aquasec/trivy:latest
  script:
    # Generate SBOM
    - trivy image --format spdx-json --output sbom.spdx.json $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    
    # Generate vulnerability report with SBOM context
    - trivy image --format json --output vuln-report.json $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    
    # Create combined security report
    - |
      jq -n \
        --argjson sbom "$(cat sbom.spdx.json)" \
        --argjson vulns "$(cat vuln-report.json)" \
        '{"sbom": $sbom, "vulnerabilities": $vulns, "timestamp": now | strftime("%Y-%m-%dT%H:%M:%SZ")}' \
        > security-report.json
        
  artifacts:
    reports:
      sast: security-report.json
    paths:
      - sbom.spdx.json
      - vuln-report.json
      - security-report.json
    expire_in: 1 month
```

## Supply Chain Security Integration

### Vulnerability Correlation with SBOM
```bash
#!/bin/bash
# sbom-vulnerability-analysis.sh

IMAGE="myapp:latest"
SBOM_FILE="sbom.spdx.json"

echo "🔒 Supply Chain Security Analysis"

# 1. Generate SBOM
syft packages $IMAGE -o spdx-json > $SBOM_FILE

# 2. Vulnerability scanning with SBOM context
grype sbom:$SBOM_FILE -o json > vulnerabilities.json

# 3. Cross-reference vulnerabilities with SBOM components
jq -r '.matches[] | 
  "Package: " + .artifact.name + 
  " Version: " + .artifact.version +
  " Vulnerability: " + .vulnerability.id +
  " Severity: " + .vulnerability.severity' vulnerabilities.json

# 4. Generate security summary
CRITICAL=$(jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length' vulnerabilities.json)
HIGH=$(jq '[.matches[] | select(.vulnerability.severity == "High")] | length' vulnerabilities.json)
TOTAL_PACKAGES=$(jq '.packages | length' $SBOM_FILE)

echo "Security Summary:"
echo "  Total packages: $TOTAL_PACKAGES"
echo "  Critical vulnerabilities: $CRITICAL"
echo "  High vulnerabilities: $HIGH"

# 5. Security gate decision
if [ $CRITICAL -gt 0 ]; then
  echo "❌ CRITICAL vulnerabilities found - blocking deployment"
  exit 1
elif [ $HIGH -gt 5 ]; then
  echo "⚠️  Too many HIGH vulnerabilities - review required"
  exit 1
else
  echo "✅ Security check passed"
fi
```

### SBOM-Based Dependency Tracking
```bash
#!/bin/bash
# dependency-tracking.sh

SBOM_FILE="sbom.spdx.json"

echo "📦 Dependency Tracking and Analysis"

# Extract all dependencies
jq -r '.packages[] | "\(.name)@\(.versionInfo)"' $SBOM_FILE | \
  sort > current-dependencies.txt

# Compare with previous version
if [ -f previous-dependencies.txt ]; then
  echo "New dependencies:"
  comm -23 current-dependencies.txt previous-dependencies.txt
  
  echo "Removed dependencies:"  
  comm -13 current-dependencies.txt previous-dependencies.txt
  
  echo "Updated dependencies:"
  comm -12 current-dependencies.txt previous-dependencies.txt | \
    while read dep; do
      # Check for version changes
      OLD_VERSION=$(grep "^${dep%@*}@" previous-dependencies.txt | cut -d@ -f2)
      NEW_VERSION=$(echo $dep | cut -d@ -f2)
      if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
        echo "$dep (was $OLD_VERSION)"
      fi
    done
fi

# Save current dependencies for next comparison
cp current-dependencies.txt previous-dependencies.txt
```

## SBOM Verification and Attestation

### Cosign SBOM Attestation
```bash
#!/bin/bash
# sbom-attestation.sh

IMAGE="myregistry.com/myapp:v1.0.0"
SBOM_FILE="sbom.spdx.json"

# Generate SBOM
syft packages $IMAGE -o spdx-json > $SBOM_FILE

# Sign and attach SBOM as attestation
cosign attest --predicate $SBOM_FILE \
  --type spdx \
  $IMAGE

# Verify SBOM attestation
cosign verify-attestation \
  --type spdx \
  --certificate-identity-regexp=".*@example.com" \
  --certificate-oidc-issuer="https://github.com/login/oauth" \
  $IMAGE
```

### SBOM Compliance Reporting
```bash
#!/bin/bash
# sbom-compliance-report.sh

SBOM_FILE="sbom.spdx.json"
REPORT_FILE="compliance-report.json"

echo "📋 SBOM Compliance Analysis"

# Extract license information
LICENSES=$(jq -r '.packages[].licenseDeclared // .packages[].licenseConcluded' $SBOM_FILE | \
  sort | uniq -c | sort -nr)

# Check for compliance issues
GPL_PACKAGES=$(echo "$LICENSES" | grep -i gpl | wc -l)
UNKNOWN_LICENSES=$(echo "$LICENSES" | grep -i "noassertion\|unknown" | wc -l)

# Generate compliance report
jq -n \
  --arg timestamp "$(date -Iseconds)" \
  --argjson gpl_count "$GPL_PACKAGES" \
  --argjson unknown_count "$UNKNOWN_LICENSES" \
  --arg licenses "$LICENSES" \
  '{
    "timestamp": $timestamp,
    "compliance_status": (if $gpl_count > 0 then "REVIEW_REQUIRED" elif $unknown_count > 0 then "INCOMPLETE" else "COMPLIANT" end),
    "gpl_packages": $gpl_count,
    "unknown_licenses": $unknown_count,
    "license_summary": $licenses
  }' > $REPORT_FILE

echo "Compliance report generated: $REPORT_FILE"
cat $REPORT_FILE | jq .
```

## Practice Tasks

1. **Generate basic SBOM**:
   ```bash
   syft packages myapp:latest -o spdx-json > sbom.spdx.json
   ```

2. **Build with embedded SBOM**:
   ```bash
   docker buildx build --sbom=true --tag myapp:with-sbom .
   ```

3. **Vulnerability correlation**:
   ```bash
   grype sbom:sbom.spdx.json -o table
   ```

4. **SBOM attestation**:
   ```bash
   cosign attest --predicate sbom.spdx.json --type spdx myapp:latest
   ```

## Production Best Practices

### SBOM Management Strategy
- **Automated generation**: Integrate SBOM creation into CI/CD pipelines
- **Version control**: Track SBOM changes alongside code changes
- **Compliance monitoring**: Regular license and security compliance checks
- **Historical tracking**: Maintain SBOM history for incident response

### Security Integration
- **Vulnerability correlation**: Link SBOM components to vulnerability databases
- **Supply chain monitoring**: Track upstream dependency changes
- **Security gates**: Use SBOM data for deployment decisions
- **Incident response**: Leverage SBOM for rapid vulnerability assessment

### Compliance and Auditing
- **Regulatory requirements**: Meet SBOM mandates (NTIA, EU regulations)
- **Audit trails**: Maintain complete SBOM provenance
- **License compliance**: Automated license conflict detection
- **Third-party verification**: Independent SBOM validation

## Key Takeaway

SBOM generation provides essential visibility into container supply chains, enabling proactive vulnerability management, regulatory compliance, and secure software delivery through comprehensive component tracking and attestation.