# Phase 06: Docker Compose - Verification Rules

> **Comprehensive validation of Docker Compose orchestration skills including service modeling, environment management, dependency coordination, and secrets management**

## 🎯 Verification Overview

These rules validate mastery of Docker Compose concepts including multi-service application design, environment-specific configurations, service dependency management, and production security patterns. All verification focuses on real-world orchestration scenarios and operational excellence.

## ✅ Verification Rules

### Rule 1: Service Modeling and Multi-Tier Architecture
**Anchor**: `p06-service-modeling`  
**Type**: Automated + Manual

**Automated Test Setup**:
```bash
mkdir -p verify-p06-services && cd verify-p06-services

# Create test application components
cat > docker-compose.test.yml << 'EOF'
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"
    depends_on:
      - backend
    volumes:
      - ./html:/usr/share/nginx/html:ro
    networks:
      - web-tier

  backend:
    image: node:18-alpine
    command: sh -c "echo 'const http = require(\"http\"); http.createServer((req,res) => { res.writeHead(200, {\"Content-Type\": \"application/json\"}); res.end(JSON.stringify({service: \"backend\", status: \"healthy\", timestamp: new Date().toISOString()})); }).listen(3000);' > app.js && node app.js"
    depends_on:
      - database
    networks:
      - web-tier
      - app-tier

  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=testapp
      - POSTGRES_USER=testuser
      - POSTGRES_PASSWORD=testpass
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - app-tier

volumes:
  db_data:

networks:
  web-tier:
    driver: bridge
  app-tier:
    driver: bridge
EOF

# Create simple HTML for frontend
mkdir -p html
cat > html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Test App</title></head>
<body>
    <h1>Multi-Tier Test Application</h1>
    <button onclick="testBackend()">Test Backend</button>
    <div id="result"></div>
    <script>
    async function testBackend() {
        try {
            const response = await fetch('/api/');
            const data = await response.json();
            document.getElementById('result').innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        } catch (error) {
            document.getElementById('result').innerHTML = '<p>Error: ' + error.message + '</p>';
        }
    }
    </script>
</body>
</html>
EOF

# Nginx configuration for API proxy
cat > nginx.conf << 'EOF'
events { worker_connections 1024; }
http {
    upstream backend { server backend:3000; }
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
        }
    }
}
EOF

# Update compose to use nginx config
cat >> docker-compose.test.yml << 'EOF'

  frontend:
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
EOF
```

**Student Task**: Demonstrate proper multi-tier service architecture design

**Automated Verification**:
```bash
# Test 1: Service deployment and connectivity
echo "=== Testing multi-tier service deployment ==="
docker compose -f docker-compose.test.yml up -d

# Wait for services to start
sleep 15

# Verify all services are running
RUNNING_SERVICES=$(docker compose -f docker-compose.test.yml ps --services --filter "status=running" | wc -l)
if [ "$RUNNING_SERVICES" -eq "3" ]; then
    echo "✅ All services deployed successfully"
    SERVICE_DEPLOYMENT=passed
else
    echo "❌ Service deployment incomplete ($RUNNING_SERVICES/3 running)"
    SERVICE_DEPLOYMENT=failed
fi

# Test 2: Network isolation verification
echo "=== Testing network isolation ==="

# Frontend should reach backend (same web-tier network)
if docker compose -f docker-compose.test.yml exec -T frontend ping -c 1 backend >/dev/null 2>&1; then
    echo "✅ Frontend can reach backend (expected)"
    FRONTEND_BACKEND_CONN=passed
else
    echo "❌ Frontend cannot reach backend"
    FRONTEND_BACKEND_CONN=failed
fi

# Frontend should NOT reach database directly (different network)
if docker compose -f docker-compose.test.yml exec -T frontend ping -c 1 database >/dev/null 2>&1; then
    echo "❌ SECURITY ISSUE: Frontend can reach database directly"
    NETWORK_ISOLATION=failed
else
    echo "✅ Network isolation working (frontend cannot reach database)"
    NETWORK_ISOLATION=passed
fi

# Backend should reach database (same app-tier network)
if docker compose -f docker-compose.test.yml exec -T backend ping -c 1 database >/dev/null 2>&1; then
    echo "✅ Backend can reach database (expected)"
    BACKEND_DATABASE_CONN=passed
else
    echo "❌ Backend cannot reach database"
    BACKEND_DATABASE_CONN=failed
fi

# Test 3: Service communication through application
echo "=== Testing application-level service communication ==="
BACKEND_RESPONSE=$(curl -s http://localhost:8080/api/ 2>/dev/null)
if echo "$BACKEND_RESPONSE" | grep -q "backend" && echo "$BACKEND_RESPONSE" | grep -q "healthy"; then
    echo "✅ Frontend-to-backend communication working"
    SERVICE_COMMUNICATION=passed
else
    echo "❌ Frontend-to-backend communication failed"
    SERVICE_COMMUNICATION=failed
fi

# Test 4: Volume persistence
echo "=== Testing volume persistence ==="
# Create test data in database
docker compose -f docker-compose.test.yml exec -T database psql -U testuser -d testapp -c "CREATE TABLE test_persistence (id SERIAL, data TEXT); INSERT INTO test_persistence (data) VALUES ('test-data-$(date +%s)');"

# Restart database service
docker compose -f docker-compose.test.yml restart database
sleep 10

# Check if data persists
PERSISTENCE_TEST=$(docker compose -f docker-compose.test.yml exec -T database psql -U testuser -d testapp -c "SELECT COUNT(*) FROM test_persistence;" | grep -E "^\s*1\s*$")
if [ -n "$PERSISTENCE_TEST" ]; then
    echo "✅ Volume persistence working"
    VOLUME_PERSISTENCE=passed
else
    echo "❌ Volume persistence failed"
    VOLUME_PERSISTENCE=failed
fi

# Cleanup
docker compose -f docker-compose.test.yml down --volumes
cd .. && rm -rf verify-p06-services
```

**Manual Assessment**:
- [ ] Can design logical service separation for multi-tier applications
- [ ] Understands network isolation principles and security implications
- [ ] Implements proper service communication patterns
- [ ] Uses appropriate volume strategies for data persistence

**Success Criteria**:
- [ ] All services deploy and run successfully
- [ ] Network isolation prevents unauthorized service communication
- [ ] Frontend-to-backend communication works through proper channels
- [ ] Data persists across service restarts

---

### Rule 2: Environment Profiles and Configuration Management
**Anchor**: `p06-environment-profiles`  
**Type**: Automated + Manual

**Test Setup**:
```bash
mkdir -p verify-p06-environments && cd verify-p06-environments

# Create base application
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  webapp:
    image: node:18-alpine
    command: sh -c "echo 'const http = require(\"http\"); const server = http.createServer((req,res) => { res.writeHead(200, {\"Content-Type\": \"application/json\"}); res.end(JSON.stringify({ environment: process.env.NODE_ENV || \"unknown\", debug: process.env.DEBUG === \"true\", database_host: process.env.DB_HOST || \"unknown\", app_version: process.env.APP_VERSION || \"unknown\" })); }); server.listen(3000);' > app.js && node app.js"
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - DEBUG=${DEBUG:-false}
      - DB_HOST=${DB_HOST:-database}
      - APP_VERSION=${APP_VERSION:-1.0.0}
    networks:
      - app-network

  database:
    image: postgres:${POSTGRES_VERSION:-14}-alpine
    environment:
      - POSTGRES_DB=${DB_NAME:-myapp}
      - POSTGRES_USER=${DB_USER:-user}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-defaultpass}
    networks:
      - app-network

networks:
  app-network:
EOF
```

**Automated Verification**:
```bash
# Test 1: Development environment configuration
echo "=== Testing development environment ==="

# Create development environment
cat > .env.dev << 'EOF'
NODE_ENV=development
DEBUG=true
DB_HOST=database
DB_NAME=myapp_dev
DB_USER=dev_user
DB_PASSWORD=dev123
APP_VERSION=dev-latest
POSTGRES_VERSION=14
EOF

# Create development override
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  webapp:
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DEBUG=true
    
  database:
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=dev123
EOF

cp .env.dev .env
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

sleep 10

# Test development configuration
DEV_CONFIG=$(curl -s http://localhost:3000)
DEV_ENV=$(echo "$DEV_CONFIG" | grep -o '"environment":"[^"]*"' | cut -d'"' -f4)
DEV_DEBUG=$(echo "$DEV_CONFIG" | grep -o '"debug":[^,}]*' | cut -d':' -f2)

if [ "$DEV_ENV" = "development" ] && [ "$DEV_DEBUG" = "true" ]; then
    echo "✅ Development environment configured correctly"
    DEV_ENVIRONMENT=passed
else
    echo "❌ Development environment configuration failed"
    DEV_ENVIRONMENT=failed
fi

docker compose down

# Test 2: Production environment configuration
echo "=== Testing production environment ==="

# Create production environment
cat > .env.prod << 'EOF'
NODE_ENV=production
DEBUG=false
DB_HOST=database
DB_NAME=myapp_production
DB_USER=prod_user
DB_PASSWORD=super-secure-production-password
APP_VERSION=v2.1.0
POSTGRES_VERSION=14
EOF

# Create production override
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  webapp:
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DEBUG=false
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  database:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    depends_on:
      - webapp
    volumes:
      - ./nginx-prod.conf:/etc/nginx/nginx.conf:ro
EOF

# Create nginx config
cat > nginx-prod.conf << 'EOF'
events { worker_connections 1024; }
http {
    upstream webapp { server webapp:3000; }
    server {
        listen 80;
        location / {
            proxy_pass http://webapp;
            proxy_set_header Host $host;
        }
    }
}
EOF

cp .env.prod .env
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

sleep 15

# Test production configuration
PROD_CONFIG=$(curl -s http://localhost:80)
PROD_ENV=$(echo "$PROD_CONFIG" | grep -o '"environment":"[^"]*"' | cut -d'"' -f4)
PROD_DEBUG=$(echo "$PROD_CONFIG" | grep -o '"debug":[^,}]*' | cut -d':' -f2)

if [ "$PROD_ENV" = "production" ] && [ "$PROD_DEBUG" = "false" ]; then
    echo "✅ Production environment configured correctly"
    PROD_ENVIRONMENT=passed
else
    echo "❌ Production environment configuration failed"
    PROD_ENVIRONMENT=failed
fi

# Test 3: Variable substitution
echo "=== Testing variable substitution ==="
PROD_VERSION=$(echo "$PROD_CONFIG" | grep -o '"app_version":"[^"]*"' | cut -d'"' -f4)
if [ "$PROD_VERSION" = "v2.1.0" ]; then
    echo "✅ Variable substitution working"
    VARIABLE_SUBSTITUTION=passed
else
    echo "❌ Variable substitution failed"
    VARIABLE_SUBSTITUTION=failed
fi

# Cleanup
docker compose down --volumes
cd .. && rm -rf verify-p06-environments
```

**Manual Assessment**:
- [ ] Can create environment-specific configuration strategies
- [ ] Understands variable substitution and template patterns
- [ ] Implements secure production vs development configurations
- [ ] Uses override files effectively for multi-environment management

**Success Criteria**:
- [ ] Development environment enables debug mode and exposes ports
- [ ] Production environment disables debug and implements security measures
- [ ] Variable substitution works correctly across environments
- [ ] Environment switching changes application behavior appropriately

---

### Rule 3: Dependencies, Health Checks, and Service Orchestration
**Anchor**: `p06-dependencies-orchestration`  
**Type**: Automated + Manual

**Test Setup**:
```bash
mkdir -p verify-p06-dependencies && cd verify-p06-dependencies

# Create complex service dependency test
cat > docker-compose.deps.yml << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    depends_on:
      api:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - frontend

  api:
    image: node:18-alpine
    command: sh -c "echo 'const http = require(\"http\"); const { Client } = require(\"pg\"); let dbConnected = false; const client = new Client({host: \"database\", database: \"testdb\", user: \"testuser\", password: \"testpass\"}); client.connect().then(() => { dbConnected = true; console.log(\"DB connected\"); }).catch(err => console.error(\"DB error:\", err)); const server = http.createServer(async (req, res) => { if (req.url === \"/health\") { res.writeHead(dbConnected ? 200 : 500, {\"Content-Type\": \"application/json\"}); res.end(JSON.stringify({status: dbConnected ? \"healthy\" : \"unhealthy\", database: dbConnected})); } else { res.writeHead(200, {\"Content-Type\": \"application/json\"}); res.end(JSON.stringify({api: \"running\", database: dbConnected})); } }); server.listen(3000);' > app.js && npm init -y && npm install pg && node app.js"
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 30s
    networks:
      - frontend
      - backend

  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=testdb
      - POSTGRES_USER=testuser
      - POSTGRES_PASSWORD=testpass
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U testuser -d testdb"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    networks:
      - backend

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    networks:
      - backend

networks:
  frontend:
  backend:
EOF
```

**Automated Verification**:
```bash
# Test 1: Service startup ordering
echo "=== Testing service startup ordering ==="

# Start services and monitor startup sequence
docker compose -f docker-compose.deps.yml up -d

# Monitor startup sequence for 60 seconds
for i in {1..12}; do
    echo "--- Check $i ($(date)) ---"
    SERVICES_STATUS=$(docker compose -f docker-compose.deps.yml ps --format "{{.Service}}: {{.Status}} ({{.Health}})")
    echo "$SERVICES_STATUS"
    
    # Count healthy services
    HEALTHY_COUNT=$(echo "$SERVICES_STATUS" | grep -c "healthy" || echo "0")
    
    if [ "$HEALTHY_COUNT" -eq "3" ]; then  # web, api, database should be healthy
        echo "✅ All services healthy"
        STARTUP_ORDERING=passed
        break
    fi
    
    sleep 5
done

if [ "$HEALTHY_COUNT" -lt "3" ]; then
    echo "❌ Service startup ordering failed"
    STARTUP_ORDERING=failed
fi

# Test 2: Health check effectiveness
echo "=== Testing health check effectiveness ==="

# Verify API health endpoint
API_HEALTH=$(curl -s http://localhost:8080/api/health 2>/dev/null || echo '{"status":"unreachable"}')
API_STATUS=$(echo "$API_HEALTH" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

if [ "$API_STATUS" = "healthy" ]; then
    echo "✅ Health checks working correctly"
    HEALTH_CHECKS=passed
else
    echo "❌ Health checks not working"
    HEALTH_CHECKS=failed
fi

# Test 3: Dependency failure handling
echo "=== Testing dependency failure handling ==="

# Stop database to test dependency handling
docker compose -f docker-compose.deps.yml stop database

# Wait for health checks to detect failure
sleep 30

# Check if API becomes unhealthy
API_HEALTH_AFTER_DB_STOP=$(docker compose -f docker-compose.deps.yml ps api --format "{{.Health}}")
if [ "$API_HEALTH_AFTER_DB_STOP" != "healthy" ]; then
    echo "✅ Dependency failure detection working"
    DEPENDENCY_FAILURE=passed
else
    echo "❌ Dependency failure not detected"
    DEPENDENCY_FAILURE=failed
fi

# Test 4: Service recovery
echo "=== Testing service recovery ==="

# Restart database
docker compose -f docker-compose.deps.yml start database

# Wait for recovery
sleep 45

# Check if services recover
RECOVERED_HEALTHY_COUNT=$(docker compose -f docker-compose.deps.yml ps --format "{{.Health}}" | grep -c "healthy" || echo "0")
if [ "$RECOVERED_HEALTHY_COUNT" -ge "2" ]; then  # At least database and API should recover
    echo "✅ Service recovery working"
    SERVICE_RECOVERY=passed
else
    echo "❌ Service recovery failed"
    SERVICE_RECOVERY=failed
fi

# Cleanup
docker compose -f docker-compose.deps.yml down --volumes
cd .. && rm -rf verify-p06-dependencies
```

**Manual Assessment**:
- [ ] Implements proper service dependency chains
- [ ] Uses health checks effectively for service coordination
- [ ] Understands service startup timing and orchestration
- [ ] Handles service failures and recovery gracefully

**Success Criteria**:
- [ ] Services start in correct dependency order
- [ ] Health checks accurately reflect service status
- [ ] Service failures are detected and propagated correctly
- [ ] Services recover automatically when dependencies are restored

---

### Rule 4: Secrets Management and Production Security
**Anchor**: `p06-secrets-security`  
**Type**: Security-focused Automated + Manual

**Security Test Setup**:
```bash
mkdir -p verify-p06-secrets && cd verify-p06-secrets
mkdir -p secrets

# Create secrets
echo "super-secret-db-password-$(date +%s)" > secrets/db_password.txt
echo "jwt-secret-$(openssl rand -hex 32)" > secrets/jwt_secret.txt
echo "api-key-$(openssl rand -hex 16)" > secrets/api_key.txt
```

**Automated Security Verification**:
```bash
# Test 1: Docker secrets implementation
echo "=== Testing Docker secrets implementation ==="

# Create compose file with secrets
cat > docker-compose.secrets.yml << 'EOF'
version: '3.8'

services:
  webapp:
    image: node:18-alpine
    command: sh -c "echo 'const fs = require(\"fs\"); const http = require(\"http\"); const readSecret = (path) => { try { return fs.readFileSync(path, \"utf8\").trim(); } catch(e) { return null; } }; const server = http.createServer((req, res) => { res.writeHead(200, {\"Content-Type\": \"application/json\"}); res.end(JSON.stringify({ secrets_loaded: { db_password: !!readSecret(\"/run/secrets/db_password\"), jwt_secret: !!readSecret(\"/run/secrets/jwt_secret\"), api_key: !!readSecret(\"/run/secrets/api_key\") }, security_test: \"passed\" })); }); server.listen(3000);' > app.js && node app.js"
    secrets:
      - db_password
      - jwt_secret
      - api_key
    ports:
      - "3000:3000"

  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=secureapp
      - POSTGRES_USER=secureuser
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U secureuser -d secureapp"]
      interval: 10s
      timeout: 5s
      retries: 3

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
  api_key:
    file: ./secrets/api_key.txt
EOF

docker compose -f docker-compose.secrets.yml up -d

sleep 15

# Test secrets loading
SECRETS_TEST=$(curl -s http://localhost:3000)
DB_SECRET_LOADED=$(echo "$SECRETS_TEST" | grep -o '"db_password":[^,}]*' | cut -d':' -f2)
JWT_SECRET_LOADED=$(echo "$SECRETS_TEST" | grep -o '"jwt_secret":[^,}]*' | cut -d':' -f2)
API_SECRET_LOADED=$(echo "$SECRETS_TEST" | grep -o '"api_key":[^,}]*' | cut -d':' -f2)

if [ "$DB_SECRET_LOADED" = "true" ] && [ "$JWT_SECRET_LOADED" = "true" ] && [ "$API_SECRET_LOADED" = "true" ]; then
    echo "✅ Docker secrets loaded correctly"
    SECRETS_LOADING=passed
else
    echo "❌ Docker secrets loading failed"
    SECRETS_LOADING=failed
fi

# Test 2: Secret file security
echo "=== Testing secret file security ==="

# Check that secrets are not visible in environment variables
ENV_VARS=$(docker compose -f docker-compose.secrets.yml exec -T webapp env)
if echo "$ENV_VARS" | grep -q "secret\|password"; then
    echo "❌ SECURITY ISSUE: Secrets visible in environment variables"
    SECRET_SECURITY=failed
else
    echo "✅ Secrets not visible in environment variables"
    SECRET_SECURITY=passed
fi

# Test 3: Production security configurations
echo "=== Testing production security configurations ==="

# Create production security compose
cat > docker-compose.secure.yml << 'EOF'
version: '3.8'

services:
  webapp:
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    user: "1000:1000"

  database:
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
      - /var/run/postgresql
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - FOWNER
      - SETGID
      - SETUID

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx-security.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - webapp
    security_opt:
      - no-new-privileges:true
EOF

# Create nginx security configuration
cat > nginx-security.conf << 'EOF'
events { worker_connections 1024; }
http {
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    upstream webapp { server webapp:3000; }
    server {
        listen 80;
        location / {
            proxy_pass http://webapp;
            proxy_set_header Host $host;
        }
    }
}
EOF

docker compose -f docker-compose.secrets.yml -f docker-compose.secure.yml up -d

sleep 20

# Test security headers
SECURITY_HEADERS=$(curl -I -s http://localhost:80)
X_FRAME_OPTIONS=$(echo "$SECURITY_HEADERS" | grep -i "x-frame-options" || echo "")
X_CONTENT_TYPE_OPTIONS=$(echo "$SECURITY_HEADERS" | grep -i "x-content-type-options" || echo "")

if [ -n "$X_FRAME_OPTIONS" ] && [ -n "$X_CONTENT_TYPE_OPTIONS" ]; then
    echo "✅ Security headers implemented"
    SECURITY_HEADERS_TEST=passed
else
    echo "❌ Security headers missing"
    SECURITY_HEADERS_TEST=failed
fi

# Test 4: Read-only filesystem security
echo "=== Testing read-only filesystem security ==="

# Try to write to filesystem (should fail)
READONLY_TEST=$(docker compose -f docker-compose.secrets.yml -f docker-compose.secure.yml exec -T webapp touch /test-readonly 2>&1 || echo "readonly-success")

if echo "$READONLY_TEST" | grep -q "readonly-success\|Read-only"; then
    echo "✅ Read-only filesystem security working"
    READONLY_FILESYSTEM=passed
else
    echo "❌ Read-only filesystem security not working"
    READONLY_FILESYSTEM=failed
fi

# Cleanup
docker compose -f docker-compose.secrets.yml -f docker-compose.secure.yml down --volumes
cd .. && rm -rf verify-p06-secrets
```

**Manual Security Assessment**:
- [ ] Implements Docker secrets for sensitive data management
- [ ] Avoids storing secrets in environment variables or volumes
- [ ] Uses production security hardening (read-only, capabilities, etc.)
- [ ] Implements security headers and secure proxy configurations

**Success Criteria**:
- [ ] Secrets are loaded from files, not environment variables
- [ ] Secrets are not visible in container environment or process lists
- [ ] Production security configurations prevent privilege escalation
- [ ] Security headers are implemented for web-facing services

---

### Rule 5: Production Deployment Integration
**Anchor**: `p06-production-deployment`  
**Type**: Comprehensive Manual Assessment

**Production Scenario**: Student demonstrates complete production-ready Docker Compose deployment.

**Assessment Requirements**:

**Architecture Design**:
- [ ] Proper service separation and network isolation
- [ ] Environment-specific configurations for dev/staging/production
- [ ] Comprehensive health checks and dependency management
- [ ] Secure secrets management implementation

**Security Implementation**:
- [ ] Docker secrets for sensitive data
- [ ] Security hardening configurations (read-only, capabilities)
- [ ] Network segmentation and access controls
- [ ] Security headers and reverse proxy configuration

**Operational Excellence**:
- [ ] Automated deployment procedures
- [ ] Health monitoring and failure recovery
- [ ] Resource limits and scaling considerations
- [ ] Backup and disaster recovery planning

**Integration Capabilities**:
- [ ] CI/CD pipeline compatibility
- [ ] Monitoring and logging integration
- [ ] External service integration patterns
- [ ] Multi-environment deployment strategies

---

## 🔄 Comprehensive Verification Script

Complete verification sequence for all rules:

```bash
#!/bin/bash
echo "=== Phase 06 Docker Compose Verification ==="

TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_result="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$test_result" = "passed" ]; then
        echo "✅ $test_name: PASSED"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ $test_name: FAILED"
    fi
}

# Rule 1: Service Modeling
echo "Testing Rule 1: Service Modeling..."
# ... (service modeling tests)

# Rule 2: Environment Management
echo "Testing Rule 2: Environment Profiles..."
# ... (environment tests)

# Rule 3: Dependencies & Orchestration
echo "Testing Rule 3: Dependencies & Orchestration..."
# ... (orchestration tests)

# Rule 4: Secrets & Security
echo "Testing Rule 4: Secrets & Security..."
# ... (security tests)

echo ""
echo "=== Verification Results ==="
echo "Automated Tests: $PASSED_TESTS/$TOTAL_TESTS passed"
echo ""
echo "Manual verification required for:"
echo "- [ ] Service architecture design rationale"
echo "- [ ] Environment management strategy"
echo "- [ ] Dependency orchestration approach"
echo "- [ ] Security implementation patterns"
echo "- [ ] Production deployment readiness"
echo ""
echo "Complete manual assessments to finish Phase 06 verification."
```

## 📋 Manual Verification Checklist

### Compose Concepts
- [ ] **Service Modeling**: Designs logical multi-tier application architectures
- [ ] **Environment Management**: Creates flexible multi-environment configurations
- [ ] **Dependency Orchestration**: Implements proper service startup coordination
- [ ] **Secrets Management**: Handles sensitive data securely

### Production Skills
- [ ] **Security Hardening**: Applies production security configurations
- [ ] **Performance Optimization**: Implements resource limits and scaling strategies
- [ ] **Monitoring Integration**: Enables comprehensive application observability
- [ ] **Deployment Automation**: Creates reproducible deployment procedures

### Integration Capabilities
- [ ] **Multi-Service Orchestration**: Coordinates complex application stacks
- [ ] **External Integration**: Connects to external services and dependencies
- [ ] **CI/CD Compatibility**: Designs Compose files for automation pipelines
- [ ] **Operational Excellence**: Implements monitoring, logging, and recovery procedures

## 🎯 Success Criteria Summary

**Complete Phase 06 when:**
- [ ] All automated verification tests pass
- [ ] Manual assessment confirms Docker Compose orchestration expertise
- [ ] Can design and deploy production-ready multi-service applications
- [ ] Demonstrates troubleshooting skills for complex service interactions
- [ ] Ready to progress to security hardening in Phase 07

---

> **Critical Success Indicator**: Can design and implement complete multi-service application stacks using Docker Compose with proper service separation, environment management, dependency coordination, and production security patterns suitable for real-world deployments.