# Micro-Lesson 04: Image Signing and Supply Chain Security

> **Duration**: 30 minutes  
> **Objective**: Implement container image signing, attestation, and supply chain security with Cosign and Sigstore  
> **Prerequisites**: Basic Docker knowledge, understanding of cryptographic signatures, OpenID Connect concepts

## 🎯 Learning Goal

Master container image signing and verification to establish trust in your supply chain, prevent tampering, and ensure only authenticated images are deployed in production environments.

## 📚 Concept Overview

**Container Image Signing** uses cryptographic signatures to verify the authenticity and integrity of container images. Modern approaches leverage keyless signing with OpenID Connect (OIDC) identity providers.

### Key Components
- **Cosign**: Tool for signing and verifying container images
- **Sigstore**: Public good infrastructure for software signing
- **Rekor**: Transparency log for signature records
- **Fulcio**: Certificate authority for code signing
- **Attestations**: Additional metadata (SBOM, provenance, vulnerability scans)

### Security Benefits
- **Authenticity**: Verify images come from trusted sources
- **Integrity**: Detect tampering or modifications
- **Non-repudiation**: Cryptographic proof of origin
- **Supply Chain Trust**: End-to-end verification pipeline
- **Compliance**: Meet security and regulatory requirements

### Signing Methods
1. **Key-based**: Traditional private/public key pairs
2. **Keyless**: OIDC identity-based signing (GitHub, Google, etc.)
3. **Hardware**: HSM or hardware security keys
4. **KMS**: Cloud key management services (AWS KMS, Azure Key Vault)

## 🔧 Hands-On Implementation

### Step 1: Environment Setup

Install Cosign and set up the environment:

```bash
# Install Cosign (Linux/macOS)
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Verify installation
cosign version

# Install additional tools
go install github.com/anchore/syft/cmd/syft@latest
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

### Step 2: Key-based Signing

Generate signing keys and sign an image:

```bash
# Generate a key pair
cosign generate-key-pair

# This creates cosign.key (private) and cosign.pub (public)
# You'll be prompted for a password to protect the private key

# Build a test image
cat > Dockerfile.signing-demo << 'EOF'
FROM alpine:latest

RUN apk add --no-cache curl

COPY << 'SCRIPT' /usr/local/bin/demo-app
#!/bin/sh
echo "Signed container application"
echo "Build time: $(date)"
echo "Image: $HOSTNAME"
curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name
SCRIPT

RUN chmod +x /usr/local/bin/demo-app

ENTRYPOINT ["/usr/local/bin/demo-app"]
EOF

# Build the image
docker build -f Dockerfile.signing-demo -t localhost:5000/demo-app:v1.0.0 .
docker push localhost:5000/demo-app:v1.0.0

# Sign the image
cosign sign --key cosign.key localhost:5000/demo-app:v1.0.0

# Verify the signature
cosign verify --key cosign.pub localhost:5000/demo-app:v1.0.0
```

### Step 3: Keyless Signing with GitHub Actions

Set up keyless signing using GitHub OIDC:

**.github/workflows/sign-image.yml**
```yaml
name: Build and Sign Image

on:
  push:
    tags: ['v*']

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-sign:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write  # Required for OIDC

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Cosign
        uses: sigstore/cosign-installer@v3

      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}

      - name: Build and push image
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile.signing-demo
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

      - name: Sign image with keyless signing
        run: |
          cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}

      - name: Generate SBOM
        run: |
          syft ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }} -o spdx-json=sbom.spdx.json

      - name: Attest SBOM
        run: |
          cosign attest --yes --predicate sbom.spdx.json --type spdx \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}

      - name: Generate provenance
        run: |
          cat > provenance.json << EOF
          {
            "buildType": "https://github.com/Attestations/GitHubActionsWorkflow@v1",
            "builder": {
              "id": "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            },
            "invocation": {
              "configSource": {
                "uri": "https://github.com/${{ github.repository }}",
                "digest": {
                  "sha1": "${{ github.sha }}"
                }
              }
            },
            "metadata": {
              "buildStartedOn": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
              "completeness": {
                "parameters": false,
                "environment": false,
                "materials": false
              },
              "reproducible": false
            }
          }
          EOF

      - name: Attest provenance
        run: |
          cosign attest --yes --predicate provenance.json --type slsaprovenance \
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build.outputs.digest }}
```

### Step 4: Local Keyless Signing (Development)

For local development with keyless signing:

```bash
# Keyless signing with GitHub identity (requires GitHub CLI)
gh auth login

# Sign image with keyless method
cosign sign localhost:5000/demo-app:v1.0.0

# Verify keyless signature
cosign verify \
  --certificate-identity-regexp ".*@users.noreply.github.com" \
  --certificate-oidc-issuer "https://github.com/login/oauth" \
  localhost:5000/demo-app:v1.0.0
```

### Step 5: SBOM Generation and Attestation

Generate and attach Software Bill of Materials:

```bash
# Generate SBOM with Syft
syft localhost:5000/demo-app:v1.0.0 -o spdx-json=demo-app.sbom.json

# View SBOM contents
jq '.packages[] | {name: .name, version: .versionInfo, type: .type}' demo-app.sbom.json | head -20

# Attest SBOM to image
cosign attest --key cosign.key --predicate demo-app.sbom.json --type spdx \
  localhost:5000/demo-app:v1.0.0

# Verify attestation
cosign verify-attestation --key cosign.pub --type spdx \
  localhost:5000/demo-app:v1.0.0 | jq '.payload' | base64 -d | jq .
```

### Step 6: Vulnerability Attestation

Attach vulnerability scan results:

```bash
# Scan image for vulnerabilities
grype localhost:5000/demo-app:v1.0.0 -o json > vulnerability-report.json

# Create vulnerability attestation
cat > vuln-predicate.json << EOF
{
  "invocation": {
    "uri": "https://github.com/anchore/grype",
    "producer_id": "grype-$(grype version | grep 'Application' | awk '{print $2}')"
  },
  "scanner": {
    "uri": "https://github.com/anchore/grype",
    "version": "$(grype version | grep 'Application' | awk '{print $2}')"
  },
  "metadata": {
    "scanStartedOn": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "scanFinishedOn": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "result": $(cat vulnerability-report.json)
}
EOF

# Attach vulnerability attestation
cosign attest --key cosign.key --predicate vuln-predicate.json --type vuln \
  localhost:5000/demo-app:v1.0.0

# Verify vulnerability attestation
cosign verify-attestation --key cosign.pub --type vuln \
  localhost:5000/demo-app:v1.0.0
```

## 🔍 Verification and Policy Enforcement

### Step 7: Policy-Based Verification

Create admission controller policies using Gatekeeper or OPA:

**supply-chain-policy.yaml**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-signed-images
spec:
  validationFailureAction: enforce
  background: false
  rules:
    - name: verify-signature
      match:
        any:
        - resources:
            kinds:
            - Pod
      verifyImages:
      - imageReferences:
        - "*"
        attestors:
        - entries:
          - keys:
              publicKeys: |-
                -----BEGIN PUBLIC KEY-----
                MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
                -----END PUBLIC KEY-----
        mutateDigest: true
        verifyDigest: true
        required: true
```

### Step 8: Continuous Verification

Set up continuous verification in deployment pipeline:

**verify-images.sh**
```bash
#!/bin/bash
set -e

IMAGE="$1"
if [[ -z "$IMAGE" ]]; then
    echo "Usage: $0 <image>"
    exit 1
fi

echo "🔍 Verifying image: $IMAGE"

# Verify signature
echo "Checking signature..."
if cosign verify --key cosign.pub "$IMAGE"; then
    echo "✅ Signature verified"
else
    echo "❌ Signature verification failed"
    exit 1
fi

# Check SBOM attestation
echo "Checking SBOM attestation..."
if cosign verify-attestation --key cosign.pub --type spdx "$IMAGE" > /dev/null; then
    echo "✅ SBOM attestation found"
    
    # Extract and analyze SBOM
    sbom_data=$(cosign verify-attestation --key cosign.pub --type spdx "$IMAGE" | jq '.payload' | base64 -d)
    package_count=$(echo "$sbom_data" | jq '.predicate.Data.packages | length')
    echo "📦 SBOM contains $package_count packages"
else
    echo "⚠️  SBOM attestation not found"
fi

# Check vulnerability attestation
echo "Checking vulnerability attestation..."
if cosign verify-attestation --key cosign.pub --type vuln "$IMAGE" > /dev/null; then
    echo "✅ Vulnerability attestation found"
    
    # Check critical vulnerabilities
    vuln_data=$(cosign verify-attestation --key cosign.pub --type vuln "$IMAGE" | jq '.payload' | base64 -d)
    critical_vulns=$(echo "$vuln_data" | jq '.predicate.result.matches[] | select(.vulnerability.severity == "Critical") | .vulnerability.id' | wc -l)
    
    if [[ $critical_vulns -eq 0 ]]; then
        echo "✅ No critical vulnerabilities found"
    else
        echo "⚠️  Found $critical_vulns critical vulnerabilities"
        # Optionally fail on critical vulnerabilities
        # exit 1
    fi
else
    echo "⚠️  Vulnerability attestation not found"
fi

echo "🎉 Image verification complete"
```

Make it executable and test:
```bash
chmod +x verify-images.sh
./verify-images.sh localhost:5000/demo-app:v1.0.0
```

## 🔒 Advanced Security Patterns

### Hardware Security Module (HSM) Integration

```bash
# Using PKCS#11 with HSM
cosign sign --pkcs11-token-label="YubiKey" \
  --pkcs11-pin-env="YUBIKEY_PIN" \
  localhost:5000/demo-app:v1.0.0

# Verify with HSM public key
cosign verify --key="pkcs11:token=YubiKey;object=signing-key" \
  localhost:5000/demo-app:v1.0.0
```

### Cloud KMS Integration

```bash
# AWS KMS signing
export AWS_REGION=us-east-1
export KMS_KEY_ID="alias/container-signing-key"

cosign sign --kms-key="awskms:///$KMS_KEY_ID" \
  localhost:5000/demo-app:v1.0.0

# Azure Key Vault signing
cosign sign --kms-key="azurekms://mykeyvault.vault.azure.net/signing-key" \
  localhost:5000/demo-app:v1.0.0

# Google Cloud KMS signing
cosign sign --kms-key="gcpkms://projects/myproject/locations/global/keyRings/cosign/cryptoKeys/signing-key" \
  localhost:5000/demo-app:v1.0.0
```

### Timestamp Authority Integration

```bash
# Sign with timestamp
cosign sign --key cosign.key --timestamp-server-url="http://timestamp.digicert.com" \
  localhost:5000/demo-app:v1.0.0

# Verify with timestamp validation
cosign verify --key cosign.pub --timestamp-certificate-chain=tsa-cert-chain.pem \
  localhost:5000/demo-app:v1.0.0
```

## 🧪 Testing and Validation

### Comprehensive Verification Script

```bash
#!/bin/bash
echo "🧪 Container Image Signing Validation"

IMAGE="localhost:5000/demo-app:v1.0.0"
TESTS_PASSED=0
TOTAL_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo "Test $TOTAL_TESTS: $test_name"
    if eval "$test_command" > /dev/null 2>&1; then
        echo "✅ PASSED"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAILED"
    fi
    echo
}

# Test 1: Basic signature verification
run_test "Signature Verification" \
    "cosign verify --key cosign.pub $IMAGE"

# Test 2: SBOM attestation verification
run_test "SBOM Attestation" \
    "cosign verify-attestation --key cosign.pub --type spdx $IMAGE"

# Test 3: Vulnerability attestation verification
run_test "Vulnerability Attestation" \
    "cosign verify-attestation --key cosign.pub --type vuln $IMAGE"

# Test 4: Image integrity check
run_test "Image Integrity" \
    "docker image inspect $IMAGE > /dev/null"

# Test 5: Signature in transparency log (if keyless)
if cosign verify --certificate-identity-regexp ".*" --certificate-oidc-issuer="https://github.com/login/oauth" "$IMAGE" > /dev/null 2>&1; then
    run_test "Transparency Log Entry" \
        "rekor-cli search --sha=$(cosign triangulate $IMAGE | cut -d: -f2)"
fi

# Test 6: Policy validation (if policy engine available)
if command -v conftest > /dev/null 2>&1; then
    run_test "Policy Validation" \
        "conftest verify --policy supply-chain-policy.rego $IMAGE"
fi

echo "Summary: $TESTS_PASSED/$TOTAL_TESTS tests passed"

if [[ $TESTS_PASSED -eq $TOTAL_TESTS ]]; then
    echo "🎉 All tests passed! Image signing is properly implemented."
    exit 0
else
    echo "⚠️  Some tests failed. Please review the implementation."
    exit 1
fi
```

### Performance Impact Analysis

```bash
#!/bin/bash
echo "📊 Signing Performance Analysis"

IMAGE="localhost:5000/demo-app:v1.0.0"

# Measure signing time
echo "Measuring signing performance..."
time cosign sign --key cosign.key --yes "$IMAGE"

# Measure verification time
echo "Measuring verification performance..."
time cosign verify --key cosign.pub "$IMAGE"

# Measure SBOM generation time
echo "Measuring SBOM generation performance..."
time syft "$IMAGE" -o spdx-json=perf-test.sbom.json

# Measure attestation time
echo "Measuring attestation performance..."
time cosign attest --key cosign.key --predicate perf-test.sbom.json --type spdx "$IMAGE"

# Clean up
rm -f perf-test.sbom.json

# Image size comparison
echo "Image size analysis:"
echo "Original image: $(docker images $IMAGE --format '{{.Size}}')"
echo "Signature overhead: ~1KB (metadata only)"
```

## 🚫 Common Pitfalls

### Key Management Issues
```bash
# Problem: Storing private keys in containers
# Solution: Use keyless signing or external key management

# Wrong
COPY cosign.key /etc/cosign/

# Right
# Use environment variables or mounted secrets
cosign sign --key env://COSIGN_PRIVATE_KEY
```

### Verification Bypass
```bash
# Problem: Not failing on verification errors
if cosign verify --key cosign.pub "$image"; then
    echo "Verified"
fi
# This continues even if verification fails!

# Solution: Use proper error handling
if ! cosign verify --key cosign.pub "$image"; then
    echo "Verification failed!"
    exit 1
fi
```

### Incomplete Attestations
```bash
# Problem: Signing without attestations
cosign sign --key cosign.key myimage

# Solution: Include SBOM and provenance
syft myimage -o spdx-json=sbom.json
cosign attest --key cosign.key --predicate sbom.json --type spdx myimage
```

## 🎓 Key Takeaways

1. **Keyless is Future**: OIDC-based keyless signing eliminates key management burden
2. **Attestations Matter**: Signatures alone aren't enough; include SBOM and provenance
3. **Transparency Logs**: Rekor provides public verifiability and non-repudiation
4. **Policy Enforcement**: Implement admission controllers for runtime verification
5. **End-to-End**: Sign at build time, verify at deploy time
6. **Performance**: Signing adds minimal overhead, verification is fast

## 📚 Next Steps

- Implement admission controllers (Gatekeeper, OPA, Kyverno)
- Set up Sigstore policy-controller for Kubernetes
- Explore Tekton Chains for pipeline attestations
- Implement supply chain security scanning with Scorecard
- Set up vulnerability database automation

---

💡 **Security Mastery**: You've achieved image signing mastery when your images are cryptographically signed, include comprehensive attestations, and are verified at deploy time with zero trust policies!