# Micro-Lesson 03: Registry Authentication and Authorization Strategies

> **Anchor**: `p09-m01-l03`  
> **Duration**: 5 minutes  
> **One Key Idea**: Master comprehensive registry authentication strategies including Basic Auth, JWT tokens, LDAP integration, and OAuth2 for secure, scalable container image access control

## Why It Matters

Registry authentication is critical for protecting container images, controlling access permissions, and ensuring compliance with security policies. Modern container environments require flexible authentication that integrates with existing identity systems while supporting automated CI/CD workflows. Understanding authentication strategies enables secure, scalable registry deployments.

## What to Learn

Master registry authentication fundamentals:
- **Basic authentication methods** - htpasswd, token-based auth
- **Enterprise authentication** - LDAP, Active Directory, OAuth2
- **Token service architecture** - JWT tokens and scope management
- **Authorization patterns** - RBAC, namespace-based permissions

## Basic Authentication Setup

### htpasswd Authentication
```bash
# Create authentication directory
sudo mkdir -p /opt/registry/auth

# Generate htpasswd file with users
sudo htpasswd -Bc /opt/registry/auth/htpasswd admin
sudo htpasswd -B /opt/registry/auth/htpasswd developer
sudo htpasswd -B /opt/registry/auth/htpasswd readonly

# Registry configuration with Basic Auth
sudo tee /opt/registry/config/config.yml > /dev/null <<EOF
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
auth:
  htpasswd:
    realm: "Registry Authentication"
    path: /auth/htpasswd
EOF

# Deploy authenticated registry
docker run -d \
  --name auth-registry \
  --restart always \
  -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  -v /opt/registry/certs:/certs:ro \
  -v /opt/registry/auth:/auth:ro \
  -v /opt/registry/config/config.yml:/etc/docker/registry/config.yml:ro \
  registry:2.8
```

### Testing Basic Authentication
```bash
# Test unauthenticated access (should fail)
curl -k https://registry.local:5000/v2/_catalog

# Test authenticated access
curl -k -u admin:password https://registry.local:5000/v2/_catalog

# Docker client authentication
docker login registry.local:5000 -u admin
docker tag alpine:latest registry.local:5000/myapp:v1.0
docker push registry.local:5000/myapp:v1.0
```

## Token-Based Authentication

### JWT Token Service Setup
```bash
# Create token service directory
sudo mkdir -p /opt/token-service/{config,keys}

# Generate RSA key pair for JWT signing
sudo openssl genrsa -out /opt/token-service/keys/jwt-key.pem 2048
sudo openssl rsa -in /opt/token-service/keys/jwt-key.pem -pubout -out /opt/token-service/keys/jwt-key.pub

# Token service configuration
sudo tee /opt/token-service/config/config.yml > /dev/null <<EOF
server:
  addr: :5001
  certificate: /certs/auth.crt
  key: /certs/auth.key

token:
  issuer: "registry-auth-service"
  expiration: 900
  certificate: /keys/jwt-key.pem

users:
  admin:
    password: "\$2y\$10\$..."  # bcrypt hash
    permissions:
      - "registry:catalog:*"
      - "repository:*:*"
  developer:
    password: "\$2y\$10\$..."
    permissions:
      - "repository:myproject/*:pull,push"
  readonly:
    password: "\$2y\$10\$..."
    permissions:
      - "repository:*:pull"
EOF

# Deploy token authentication service
docker run -d \
  --name token-auth \
  --restart always \
  -p 5001:5001 \
  -v /opt/token-service/config:/config:ro \
  -v /opt/token-service/keys:/keys:ro \
  -v /opt/registry/certs:/certs:ro \
  cesanta/docker_auth:latest /config/config.yml
```

### Registry with Token Authentication
```yaml
# Registry configuration for token auth
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
auth:
  token:
    realm: "https://auth.registry.local:5001/auth"
    service: "registry"
    issuer: "registry-auth-service"
    rootcertbundle: /keys/jwt-key.pub
```

### Token Authentication Flow
```bash
#!/bin/bash
# token-auth-test.sh

AUTH_URL="https://auth.registry.local:5001"
REGISTRY_URL="https://registry.local:5000"

echo "🔐 Token Authentication Test"
echo "=========================="

# Step 1: Get token for specific repository
echo "1. Requesting access token..."
TOKEN=$(curl -sk -u developer:devpass \
  "${AUTH_URL}/auth?service=registry&scope=repository:myproject/webapp:pull,push" \
  | jq -r .token)

echo "Token received: ${TOKEN:0:20}..."

# Step 2: Use token for registry access
echo ""
echo "2. Accessing registry with token..."
curl -k -H "Authorization: Bearer $TOKEN" \
  "$REGISTRY_URL/v2/myproject/webapp/tags/list"

# Step 3: Test scope limitations
echo ""
echo "3. Testing scope limitations..."
curl -k -H "Authorization: Bearer $TOKEN" \
  "$REGISTRY_URL/v2/other-project/app/tags/list"
```

## LDAP Authentication Integration

### LDAP Authentication Service
```yaml
# ldap-auth-config.yml
server:
  addr: :5001
  certificate: /certs/auth.crt
  key: /certs/auth.key

token:
  issuer: "registry-ldap-auth"
  expiration: 1800
  certificate: /keys/jwt-key.pem

ldap_auth:
  addr: "ldaps://ldap.company.com:636"
  tls: always
  insecure_tls_skip_verify: false
  
  # Service account for LDAP queries
  bind_dn: "cn=registry-service,ou=services,dc=company,dc=com"
  bind_password: "service-password"
  
  # User search configuration
  base: "ou=users,dc=company,dc=com"
  filter: "(&(objectClass=person)(uid=%s))"
  
  # Group-based permissions
  group_base: "ou=groups,dc=company,dc=com"
  group_filter: "(&(objectClass=groupOfNames)(member=%s))"
  group_attribute: "cn"

# Group-based access control
acl:
  - match:
      account: "/.+/"
      name: "public/*"
    actions: ["pull"]
    
  - match:
      account: "/.+/"
      name: "${account}/*"
    actions: ["*"]
    
  - match:
      account: "/.+/"
      groups: ["docker-admins"]
    actions: ["*"]
    
  - match:
      account: "/.+/"
      groups: ["developers"]
      name: "dev/*"
    actions: ["pull", "push"]
```

### LDAP Test Setup
```bash
# Deploy OpenLDAP for testing
docker run -d \
  --name test-ldap \
  --restart always \
  -p 389:389 \
  -p 636:636 \
  -e LDAP_ORGANISATION="Test Company" \
  -e LDAP_DOMAIN="company.com" \
  -e LDAP_ADMIN_PASSWORD="admin123" \
  -e LDAP_CONFIG_PASSWORD="config123" \
  -e LDAP_TLS_VERIFY_CLIENT=never \
  osixia/openldap:latest

# Add test users and groups
docker exec test-ldap ldapadd -x -D "cn=admin,dc=company,dc=com" -w admin123 <<EOF
dn: ou=users,dc=company,dc=com
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=company,dc=com
objectClass: organizationalUnit
ou: groups

dn: uid=alice,ou=users,dc=company,dc=com
objectClass: person
objectClass: inetOrgPerson
uid: alice
cn: Alice Developer
sn: Developer
userPassword: alice123

dn: cn=developers,ou=groups,dc=company,dc=com
objectClass: groupOfNames
cn: developers
member: uid=alice,ou=users,dc=company,dc=com
EOF
```

## OAuth2 and OIDC Integration

### OAuth2 Proxy Setup
```yaml
# oauth2-proxy configuration
provider: "github"
client_id: "your-github-oauth-app-id"
client_secret: "your-github-oauth-app-secret"
redirect_url: "https://registry.local/oauth2/callback"

cookie_secret: "generated-random-string"
cookie_secure: true
cookie_httponly: true

email_domains: ["company.com"]
github_org: "your-organization"
github_team: "docker-users"

upstreams: ["https://registry.local:5000"]
http_address: ":4180"
```

### GitHub OAuth Integration
```bash
# Deploy OAuth2 proxy
docker run -d \
  --name oauth2-proxy \
  --restart always \
  -p 4180:4180 \
  -v /opt/oauth2/oauth2_proxy.cfg:/etc/oauth2_proxy.cfg:ro \
  quay.io/oauth2-proxy/oauth2-proxy:latest \
  --config=/etc/oauth2_proxy.cfg

# Configure nginx for OAuth2 integration
sudo tee /opt/nginx/auth.conf > /dev/null <<EOF
server {
    listen 443 ssl http2;
    server_name registry.local;

    ssl_certificate /certs/domain.crt;
    ssl_certificate_key /certs/domain.key;

    # OAuth2 authentication
    location /oauth2/ {
        proxy_pass http://oauth2-proxy:4180;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Auth-Request-Redirect \$request_uri;
    }

    location = /oauth2/auth {
        proxy_pass http://oauth2-proxy:4180;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI \$request_uri;
    }

    # Registry with OAuth2 auth
    location /v2/ {
        auth_request /oauth2/auth;
        auth_request_set \$user   \$upstream_http_x_auth_request_user;
        auth_request_set \$email  \$upstream_http_x_auth_request_email;
        
        proxy_pass https://registry:5000;
        proxy_set_header X-Forwarded-User \$user;
        proxy_set_header X-Forwarded-Email \$email;
    }
}
EOF
```

## Advanced Authorization Patterns

### Namespace-based Permissions
```python
# Python ACL service example
import jwt
import hashlib
from flask import Flask, request, jsonify

app = Flask(__name__)

class RegistryACL:
    def __init__(self):
        self.permissions = {
            'admin': ['registry:catalog:*', 'repository:*:*'],
            'developer': [
                'repository:dev/*:*',
                'repository:{user}/*:*'
            ],
            'readonly': ['repository:*:pull']
        }
    
    def check_permission(self, user, action, resource):
        user_perms = self.permissions.get(user['role'], [])
        
        for perm in user_perms:
            if self._match_permission(perm, action, resource, user):
                return True
        return False
    
    def _match_permission(self, perm, action, resource, user):
        perm_parts = perm.split(':')
        resource_parts = resource.split(':')
        
        # Expand template variables
        perm_expanded = perm.replace('{user}', user['name'])
        
        # Implement wildcard matching logic
        return self._wildcard_match(perm_expanded, f"{action}:{resource}")

@app.route('/auth', methods=['POST'])
def authenticate():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    
    try:
        payload = jwt.decode(token, verify=False)  # Verify in production!
        user = payload.get('sub')
        action = request.json.get('action')
        resource = request.json.get('name')
        
        acl = RegistryACL()
        if acl.check_permission(user, action, resource):
            return jsonify({'access': True})
        else:
            return jsonify({'access': False}), 403
            
    except jwt.InvalidTokenError:
        return jsonify({'error': 'Invalid token'}), 401
```

### Registry Webhook Authentication
```bash
# Webhook authentication validator
sudo tee /opt/webhook-auth/validate.sh > /dev/null <<'EOF'
#!/bin/bash

# Webhook payload validation
PAYLOAD="$1"
SIGNATURE="$2"
SECRET="webhook-secret-key"

# Calculate expected signature
EXPECTED=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)

# Compare signatures
if [ "$SIGNATURE" = "sha256=$EXPECTED" ]; then
    echo "Valid webhook signature"
    exit 0
else
    echo "Invalid webhook signature"
    exit 1
fi
EOF

chmod +x /opt/webhook-auth/validate.sh
```

## Practice Tasks

1. **Setup basic authentication**:
   ```bash
   htpasswd -Bc auth/htpasswd testuser
   # Configure registry with htpasswd auth
   ```

2. **Deploy token service**:
   ```bash
   # Generate JWT keys and configure token auth
   ```

3. **Test LDAP integration**:
   ```bash
   # Deploy test LDAP and configure authentication
   ```

4. **Configure OAuth2**:
   ```bash
   # Setup GitHub OAuth integration
   ```

## Security Best Practices

### Token Security
- **Short token expiration** times (15-30 minutes)
- **Secure key storage** with proper permissions
- **Regular key rotation** for JWT signing keys
- **Scope-based access control** for fine-grained permissions

### Authentication Hardening
```bash
# Secure authentication setup
sudo chmod 600 /opt/registry/auth/htpasswd
sudo chown registry:registry /opt/registry/auth/

# Strong password policy
sudo tee /opt/registry/password-policy.txt <<EOF
Minimum 12 characters
Must include uppercase, lowercase, numbers, symbols
No dictionary words
Regular rotation every 90 days
EOF

# Rate limiting for auth endpoints
sudo tee /opt/nginx/rate-limit.conf <<EOF
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

location /auth {
    limit_req zone=auth burst=3 nodelay;
    proxy_pass http://auth-service;
}
EOF
```

### Audit and Monitoring
```bash
# Authentication audit logging
docker logs auth-service 2>&1 | grep -E "(LOGIN|FAILED|TOKEN)" > /var/log/registry-auth.log

# Monitor failed authentication attempts
tail -f /var/log/registry-auth.log | grep FAILED | \
while read line; do
  echo "$(date): Auth failure detected: $line" | \
  mail -s "Registry Auth Alert" admin@company.com
done
```

## Troubleshooting Authentication

### Common Issues
```bash
# Debug authentication flow
curl -v -k https://registry.local:5000/v2/_catalog

# Check token validity
echo "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9..." | base64 -d | jq .

# Verify LDAP connectivity
ldapsearch -x -H ldaps://ldap.company.com -b "dc=company,dc=com" -D "cn=admin,dc=company,dc=com" -W

# Test OAuth2 callback
curl -I https://registry.local/oauth2/callback?code=test&state=test
```

## Key Takeaway

Registry authentication strategies provide secure, scalable access control through multiple methods including Basic Auth, JWT tokens, LDAP integration, and OAuth2, enabling enterprise-grade security with flexible user management and fine-grained authorization policies.