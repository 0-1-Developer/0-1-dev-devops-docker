# Phase 06: Docker Compose - Hands-on Labs

> **Practical exercises for mastering multi-container application orchestration with Docker Compose**

## 🎯 Lab Overview

This lab phase provides 180 minutes of hands-on experience with Docker Compose, covering service modeling, environment management, dependency orchestration, and secrets management. You'll build and deploy increasingly complex multi-service applications.

## ⏱ Time Allocation

- **Lab 1**: Service Modeling and Multi-Tier Architecture (45 minutes)
- **Lab 2**: Environment Profiles and Configuration Management (45 minutes)
- **Lab 3**: Dependencies, Health Checks, and Service Orchestration (45 minutes)
- **Lab 4**: Secrets Management and Production Security (45 minutes)

## 🔧 Lab Prerequisites

- Docker Compose 2.0+ installed
- Basic understanding of YAML syntax
- Text editor for configuration files
- Completed Phase 05 (Storage & Volumes)

---

## Lab 1: Service Modeling and Multi-Tier Architecture
**Duration**: 45 minutes | **Difficulty**: Intermediate

### 🎯 Objectives
- Design and implement multi-service application architecture
- Understand service separation and communication patterns
- Practice network isolation and service discovery
- Deploy a complete web application stack

### 📋 Lab Setup

```bash
# Create lab workspace
mkdir -p ~/docker-labs/compose-lab1 && cd ~/docker-labs/compose-lab1

# Clean any existing containers
docker compose down --volumes 2>/dev/null || true
```

### Task 1.1: Basic Web Application Stack (15 minutes)

**Build a classic 3-tier web application**

```bash
echo "=== Task 1.1: Basic Web Application Stack ==="

# Create application structure
mkdir -p frontend backend

# Frontend application (React-like)
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Compose Lab App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .api-result { background: #f0f0f0; padding: 20px; margin: 20px 0; }
        button { padding: 10px 20px; margin: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Docker Compose Lab Application</h1>
        <button onclick="testAPI()">Test API Connection</button>
        <button onclick="testDatabase()">Test Database</button>
        <div id="result" class="api-result">Click buttons to test services...</div>
    </div>
    
    <script>
        async function testAPI() {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                document.getElementById('result').innerHTML = 
                    '<strong>API Response:</strong><br>' + JSON.stringify(data, null, 2);
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<strong>API Error:</strong> ' + error.message;
            }
        }
        
        async function testDatabase() {
            try {
                const response = await fetch('/api/db-test');
                const data = await response.json();
                document.getElementById('result').innerHTML = 
                    '<strong>Database Test:</strong><br>' + JSON.stringify(data, null, 2);
            } catch (error) {
                document.getElementById('result').innerHTML = 
                    '<strong>Database Error:</strong> ' + error.message;
            }
        }
    </script>
</body>
</html>
EOF

# Backend API (Node.js-like)
cat > backend/server.js << 'EOF'
const http = require('http');
const { Client } = require('pg');

const port = process.env.PORT || 8000;
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'myapp',
    user: process.env.DB_USER || 'user',
    password: process.env.DB_PASSWORD || 'password',
};

const server = http.createServer(async (req, res) => {
    // Enable CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');
    
    try {
        if (req.url === '/api/health') {
            res.writeHead(200);
            res.end(JSON.stringify({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                service: 'backend-api'
            }));
            
        } else if (req.url === '/api/db-test') {
            const client = new Client(dbConfig);
            await client.connect();
            
            const result = await client.query('SELECT NOW() as current_time, version() as pg_version');
            await client.end();
            
            res.writeHead(200);
            res.end(JSON.stringify({
                status: 'database connected',
                data: result.rows[0],
                timestamp: new Date().toISOString()
            }));
            
        } else {
            res.writeHead(404);
            res.end(JSON.stringify({ error: 'Not found' }));
        }
    } catch (error) {
        res.writeHead(500);
        res.end(JSON.stringify({ error: error.message }));
    }
});

server.listen(port, () => {
    console.log(`Backend API listening on port ${port}`);
});
EOF

cat > backend/package.json << 'EOF'
{
    "name": "backend-api",
    "version": "1.0.0",
    "main": "server.js",
    "dependencies": {
        "pg": "^8.8.0"
    },
    "scripts": {
        "start": "node server.js"
    }
}
EOF

# Backend Dockerfile
cat > backend/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 8000
CMD ["npm", "start"]
EOF

# Nginx configuration for frontend
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:8000;
    }
    
    server {
        listen 80;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

# Docker Compose configuration
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Frontend (Nginx serving static files)
  frontend:
    image: nginx:alpine
    ports:
      - "3000:80"
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend
    networks:
      - web-tier

  # Backend API
  backend:
    build: ./backend
    environment:
      - DB_HOST=database
      - DB_NAME=myapp
      - DB_USER=user
      - DB_PASSWORD=secret123
    depends_on:
      - database
    networks:
      - web-tier
      - app-tier

  # PostgreSQL Database
  database:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=secret123
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

echo "✅ Application stack configuration created"
```

### Task 1.2: Deploy and Test the Stack (15 minutes)

```bash
echo "=== Task 1.2: Deploy and Test Stack ==="

# Build and start the stack
docker compose up -d --build

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 20

# Verify all services are running
echo "=== Service Status ==="
docker compose ps

# Test the application
echo "=== Testing Application ==="

# Test frontend accessibility
if curl -s http://localhost:3000 | grep -q "Docker Compose Lab"; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend test failed"
fi

# Test backend API health
API_RESPONSE=$(curl -s http://localhost:3000/api/health)
if echo "$API_RESPONSE" | grep -q "healthy"; then
    echo "✅ Backend API is healthy"
    echo "API Response: $API_RESPONSE"
else
    echo "❌ Backend API test failed"
fi

# Test database connectivity through API
DB_RESPONSE=$(curl -s http://localhost:3000/api/db-test)
if echo "$DB_RESPONSE" | grep -q "database connected"; then
    echo "✅ Database connectivity confirmed"
    echo "Database Response: $DB_RESPONSE"
else
    echo "❌ Database connectivity test failed"
fi

echo "✅ Stack deployment and testing completed"
echo "💡 Visit http://localhost:3000 in your browser to interact with the app"
```

### Task 1.3: Service Isolation and Network Analysis (15 minutes)

```bash
echo "=== Task 1.3: Service Isolation and Network Analysis ==="

# Analyze network configuration
echo "=== Network Configuration ==="
docker network ls | grep compose-lab1

# Inspect networks
echo "=== Web Tier Network ==="
docker network inspect compose-lab1_web-tier --format '{{json .Containers}}' | jq

echo "=== App Tier Network ==="
docker network inspect compose-lab1_app-tier --format '{{json .Containers}}' | jq

# Test network isolation
echo "=== Testing Network Isolation ==="

# Frontend can reach backend
if docker compose exec frontend ping -c 2 backend >/dev/null 2>&1; then
    echo "✅ Frontend can reach backend (expected)"
else
    echo "❌ Frontend cannot reach backend (network issue)"
fi

# Frontend cannot reach database directly
if docker compose exec frontend ping -c 2 database >/dev/null 2>&1; then
    echo "⚠️  Frontend can reach database (potential security issue)"
else
    echo "✅ Frontend cannot reach database directly (secure isolation)"
fi

# Backend can reach database
if docker compose exec backend ping -c 2 database >/dev/null 2>&1; then
    echo "✅ Backend can reach database (expected)"
else
    echo "❌ Backend cannot reach database (configuration issue)"
fi

# Add Redis cache to demonstrate scaling
echo "=== Adding Cache Service ==="
cat >> docker-compose.yml << 'EOF'

  # Redis Cache
  cache:
    image: redis:7-alpine
    networks:
      - app-tier
EOF

# Update backend to use cache (restart required)
docker compose up -d cache

echo "✅ Service isolation analysis completed"
```

### 🧪 Lab 1 Verification

```bash
echo "=== Lab 1 Verification ==="

# Check all services are running
RUNNING_SERVICES=$(docker compose ps --services --filter "status=running" | wc -l)
echo "Running services: $RUNNING_SERVICES/4"

# Check network isolation
echo "Network isolation test:"
docker compose exec --no-TTY frontend ping -c 1 database >/dev/null 2>&1 && echo "❌ Security issue: Frontend can reach database" || echo "✅ Network properly isolated"

# Check service communication
echo "Service communication test:"
docker compose exec --no-TTY backend ping -c 1 database >/dev/null 2>&1 && echo "✅ Backend can reach database" || echo "❌ Service communication failed"

# Test web application functionality
APP_TEST=$(curl -s http://localhost:3000/api/health | jq -r '.status' 2>/dev/null)
if [ "$APP_TEST" = "healthy" ]; then
    echo "✅ Application stack working correctly"
else
    echo "❌ Application stack has issues"
fi

echo "✅ Lab 1 verification completed"
```

---

## Lab 2: Environment Profiles and Configuration Management
**Duration**: 45 minutes | **Difficulty**: Advanced

### 🎯 Objectives
- Create environment-specific Docker Compose configurations
- Master variable substitution and template patterns
- Implement development vs production configuration strategies
- Practice configuration override patterns

### Task 2.1: Multi-Environment Setup (15 minutes)

```bash
echo "=== Task 2.1: Multi-Environment Configuration Setup ==="

# Create new lab directory
cd ~/docker-labs && mkdir -p compose-lab2 && cd compose-lab2

# Create base application structure
mkdir -p app config

# Simple web application
cat > app/server.js << 'EOF'
const http = require('http');
const port = process.env.PORT || 3000;
const env = process.env.NODE_ENV || 'development';

const config = {
    environment: env,
    database: {
        host: process.env.DB_HOST || 'localhost',
        name: process.env.DB_NAME || 'myapp',
        user: process.env.DB_USER || 'user'
    },
    features: {
        debug: process.env.DEBUG === 'true',
        logging_level: process.env.LOG_LEVEL || 'info',
        cache_ttl: parseInt(process.env.CACHE_TTL) || 300
    },
    version: process.env.APP_VERSION || '1.0.0'
};

const server = http.createServer((req, res) => {
    if (req.url === '/config') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(config, null, 2));
    } else if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'healthy',
            environment: env,
            uptime: process.uptime(),
            timestamp: new Date().toISOString()
        }));
    } else {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
            <html>
                <body>
                    <h1>Environment: ${env}</h1>
                    <p>Version: ${config.version}</p>
                    <p><a href="/config">View Configuration</a></p>
                    <p><a href="/health">Health Check</a></p>
                </body>
            </html>
        `);
    }
});

server.listen(port, () => {
    console.log(`Server running on port ${port} in ${env} mode`);
});
EOF

cat > app/package.json << 'EOF'
{
    "name": "multi-env-app",
    "version": "1.0.0",
    "main": "server.js",
    "scripts": {
        "start": "node server.js",
        "dev": "NODE_ENV=development node server.js"
    }
}
EOF

cat > app/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
COPY server.js .
EXPOSE 3000
CMD ["npm", "start"]
EOF

echo "✅ Application structure created"
```

### Task 2.2: Base Configuration (10 minutes)

```bash
echo "=== Task 2.2: Base Docker Compose Configuration ==="

# Base docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  webapp:
    build: ./app
    environment:
      - NODE_ENV=${ENVIRONMENT:-development}
      - APP_VERSION=${APP_VERSION:-1.0.0}
      - DB_HOST=${DB_HOST:-database}
      - DB_NAME=${DB_NAME:-myapp}
      - DB_USER=${DB_USER:-user}
      - DEBUG=${DEBUG:-false}
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - CACHE_TTL=${CACHE_TTL:-300}
    networks:
      - app-network

  database:
    image: postgres:${POSTGRES_VERSION:-14}-alpine
    environment:
      - POSTGRES_DB=${DB_NAME:-myapp}
      - POSTGRES_USER=${DB_USER:-user}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-defaultpass}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  db_data:

networks:
  app-network:
    driver: bridge
EOF

echo "✅ Base configuration created with variable substitution"
```

### Task 2.3: Development Environment (10 minutes)

```bash
echo "=== Task 2.3: Development Environment Configuration ==="

# Development environment variables
cat > .env.dev << 'EOF'
# Development Environment Configuration
ENVIRONMENT=development
APP_VERSION=dev-latest
DB_HOST=database
DB_NAME=myapp_dev
DB_USER=dev_user
DB_PASSWORD=dev123
DEBUG=true
LOG_LEVEL=debug
CACHE_TTL=60
POSTGRES_VERSION=14
EOF

# Development override file (automatically loaded)
cat > docker-compose.override.yml << 'EOF'
version: '3.8'

services:
  webapp:
    volumes:
      - ./app:/app:rw  # Live code reload
    ports:
      - "3000:3000"    # Expose for development
    environment:
      - NODE_ENV=development
      - DEBUG=true
      - LOG_LEVEL=debug
    command: sh -c "npm run dev"

  database:
    ports:
      - "5432:5432"    # Direct database access for dev tools
    environment:
      - POSTGRES_PASSWORD=dev123  # Simple password for development
    volumes:
      - ./config/init-dev.sql:/docker-entrypoint-initdb.d/init.sql:ro

  # Development-only services
  adminer:
    image: adminer:latest
    ports:
      - "8080:8080"    # Database admin interface
    networks:
      - app-network
    depends_on:
      - database
EOF

# Development database initialization
mkdir -p config
cat > config/init-dev.sql << 'EOF'
-- Development database initialization
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert test data for development
INSERT INTO users (name, email) VALUES 
    ('Dev User 1', 'dev1@example.com'),
    ('Dev User 2', 'dev2@example.com'),
    ('Test Admin', 'admin@example.com');
EOF

# Test development environment
echo "Testing development environment..."
cp .env.dev .env

docker compose up -d --build

# Wait for services
sleep 15

# Test development features
echo "=== Development Environment Tests ==="
DEV_CONFIG=$(curl -s http://localhost:3000/config)
echo "Development config: $DEV_CONFIG" | jq

# Check debug mode
if echo "$DEV_CONFIG" | grep -q '"debug": true'; then
    echo "✅ Debug mode enabled in development"
else
    echo "❌ Debug mode not enabled"
fi

# Check database admin interface
if curl -s http://localhost:8080 | grep -q "Adminer"; then
    echo "✅ Database admin interface accessible"
else
    echo "❌ Database admin interface not working"
fi

echo "✅ Development environment configured and tested"
```

### Task 2.4: Production Environment (10 minutes)

```bash
echo "=== Task 2.4: Production Environment Configuration ==="

# Production environment variables
cat > .env.prod << 'EOF'
# Production Environment Configuration
ENVIRONMENT=production
APP_VERSION=v1.2.0
DB_HOST=database
DB_NAME=myapp_production
DB_USER=prod_user
DB_PASSWORD=super-secure-prod-password-change-me
DEBUG=false
LOG_LEVEL=warn
CACHE_TTL=3600
POSTGRES_VERSION=14
EOF

# Production override file
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  webapp:
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DEBUG=false
      - LOG_LEVEL=warn
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  database:
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_prod:/var/lib/postgresql/data
      - ./config/init-prod.sql:/docker-entrypoint-initdb.d/init.sql:ro
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U prod_user -d myapp_production"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Production reverse proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./config/nginx-prod.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      webapp:
        condition: service_healthy
    restart: unless-stopped

volumes:
  postgres_prod:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt
EOF

# Production database initialization (minimal)
cat > config/init-prod.sql << 'EOF'
-- Production database initialization
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
EOF

# Production nginx configuration
cat > config/nginx-prod.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream webapp {
        server webapp:3000;
    }
    
    server {
        listen 80;
        
        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        
        location / {
            proxy_pass http://webapp;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Health check endpoint
        location /health {
            proxy_pass http://webapp/health;
        }
    }
}
EOF

# Create secrets directory
mkdir -p secrets
echo "super-secure-prod-password-change-me" > secrets/db_password.txt

echo "✅ Production environment configured"

# Test production deployment
echo "=== Testing Production Environment ==="
cp .env.prod .env

# Stop development environment
docker compose down

# Deploy production environment
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Wait for health checks
echo "Waiting for production services to be healthy..."
sleep 30

# Test production configuration
PROD_CONFIG=$(curl -s http://localhost/config)
echo "Production config: $PROD_CONFIG" | jq

# Check production security settings
if echo "$PROD_CONFIG" | grep -q '"debug": false'; then
    echo "✅ Debug mode disabled in production"
else
    echo "❌ Debug mode still enabled in production"
fi

if echo "$PROD_CONFIG" | grep -q '"logging_level": "warn"'; then
    echo "✅ Production logging level set correctly"
else
    echo "❌ Production logging level incorrect"
fi

echo "✅ Production environment tested"
```

### 🧪 Lab 2 Verification

```bash
echo "=== Lab 2 Verification ==="

# Test environment switching
echo "=== Testing Environment Switching ==="

# Development environment
cp .env.dev .env
docker compose down
docker compose up -d
sleep 10

DEV_DEBUG=$(curl -s http://localhost:3000/config | jq -r '.features.debug')
echo "Development debug mode: $DEV_DEBUG"

# Production environment  
cp .env.prod .env
docker compose down
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
sleep 15

PROD_DEBUG=$(curl -s http://localhost/config | jq -r '.features.debug')
echo "Production debug mode: $PROD_DEBUG"

# Verify different configurations
if [ "$DEV_DEBUG" = "true" ] && [ "$PROD_DEBUG" = "false" ]; then
    echo "✅ Environment-specific configurations working correctly"
else
    echo "❌ Environment configurations not switching properly"
fi

# Check production health checks
HEALTH_STATUS=$(docker compose ps --format json | jq -r '.[] | select(.Service=="webapp") | .Health')
echo "Production webapp health: $HEALTH_STATUS"

echo "✅ Lab 2 verification completed"
```

---

## Lab 3: Dependencies, Health Checks, and Service Orchestration
**Duration**: 45 minutes | **Difficulty**: Advanced

### 🎯 Objectives
- Implement proper service dependency management
- Create comprehensive health check strategies
- Understand service startup orchestration
- Practice failure recovery and resilience patterns

### Task 3.1: Complex Service Dependencies (15 minutes)

```bash
echo "=== Task 3.1: Complex Service Dependencies Setup ==="

# Create new lab directory
cd ~/docker-labs && mkdir -p compose-lab3 && cd compose-lab3
mkdir -p services/{web,api,worker} config

# Web frontend service
cat > services/web/app.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send(`
        <html>
            <body>
                <h1>Service Orchestration Demo</h1>
                <p>Testing service dependencies and health checks</p>
                <button onclick="testAPI()">Test API</button>
                <button onclick="testDatabase()">Test Database</button>
                <button onclick="testQueue()">Test Message Queue</button>
                <div id="result"></div>
                
                <script>
                async function testAPI() {
                    try {
                        const response = await fetch('/api/status');
                        const data = await response.json();
                        document.getElementById('result').innerHTML = 
                            '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                    } catch (error) {
                        document.getElementById('result').innerHTML = 
                            '<p style="color: red;">API Error: ' + error.message + '</p>';
                    }
                }
                
                async function testDatabase() {
                    const response = await fetch('/api/db-status');
                    const data = await response.json();
                    document.getElementById('result').innerHTML = 
                        '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                }
                
                async function testQueue() {
                    const response = await fetch('/api/queue-status');
                    const data = await response.json();
                    document.getElementById('result').innerHTML = 
                        '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                }
                </script>
            </body>
        </html>
    `);
});

// Proxy to API
app.get('/api/*', (req, res) => {
    const http = require('http');
    const options = {
        hostname: 'api',
        port: 8000,
        path: req.path,
        method: req.method
    };
    
    const proxy = http.request(options, (apiRes) => {
        res.writeHead(apiRes.statusCode, apiRes.headers);
        apiRes.pipe(res);
    });
    
    proxy.on('error', (err) => {
        res.status(500).json({ error: 'API unavailable', message: err.message });
    });
    
    proxy.end();
});

app.listen(port, () => {
    console.log(`Web service listening on port ${port}`);
});
EOF

cat > services/web/package.json << 'EOF'
{
    "name": "web-service",
    "version": "1.0.0",
    "main": "app.js",
    "dependencies": {
        "express": "^4.18.0"
    },
    "scripts": {
        "start": "node app.js"
    }
}
EOF

cat > services/web/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

# API service
cat > services/api/server.js << 'EOF'
const express = require('express');
const { Client } = require('pg');
const redis = require('redis');
const amqp = require('amqplib');

const app = express();
const port = 8000;

// Database configuration
const dbConfig = {
    host: process.env.DB_HOST || 'postgres',
    port: 5432,
    database: 'myapp',
    user: 'user',
    password: 'secret123',
};

let dbClient = null;
let redisClient = null;
let rabbitConnection = null;

// Initialize connections
async function initializeConnections() {
    try {
        // Database
        dbClient = new Client(dbConfig);
        await dbClient.connect();
        console.log('✅ Database connected');
        
        // Redis
        redisClient = redis.createClient({
            host: 'redis',
            port: 6379
        });
        await redisClient.connect();
        console.log('✅ Redis connected');
        
        // RabbitMQ
        rabbitConnection = await amqp.connect('amqp://rabbitmq');
        console.log('✅ RabbitMQ connected');
        
    } catch (error) {
        console.error('Connection initialization failed:', error.message);
        throw error;
    }
}

// Health check endpoint
app.get('/api/health', async (req, res) => {
    const health = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        checks: {
            database: 'unknown',
            redis: 'unknown',
            rabbitmq: 'unknown'
        }
    };
    
    try {
        // Check database
        if (dbClient) {
            await dbClient.query('SELECT 1');
            health.checks.database = 'healthy';
        }
        
        // Check Redis
        if (redisClient && redisClient.isReady) {
            await redisClient.ping();
            health.checks.redis = 'healthy';
        }
        
        // Check RabbitMQ
        if (rabbitConnection && !rabbitConnection.connection.serverProperties) {
            health.checks.rabbitmq = 'healthy';
        }
        
        res.json(health);
    } catch (error) {
        health.status = 'unhealthy';
        health.error = error.message;
        res.status(500).json(health);
    }
});

app.get('/api/status', (req, res) => {
    res.json({
        service: 'api',
        status: 'running',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        timestamp: new Date().toISOString()
    });
});

app.get('/api/db-status', async (req, res) => {
    try {
        const result = await dbClient.query('SELECT NOW() as current_time, version() as db_version');
        res.json({
            status: 'connected',
            data: result.rows[0]
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/queue-status', async (req, res) => {
    try {
        const channel = await rabbitConnection.createChannel();
        const queueInfo = await channel.checkQueue('test-queue');
        await channel.close();
        
        res.json({
            status: 'connected',
            queue: queueInfo
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Initialize and start server
initializeConnections().then(() => {
    app.listen(port, () => {
        console.log(`API service listening on port ${port}`);
    });
}).catch((error) => {
    console.error('Failed to start API service:', error.message);
    process.exit(1);
});
EOF

cat > services/api/package.json << 'EOF'
{
    "name": "api-service",
    "version": "1.0.0",
    "main": "server.js",
    "dependencies": {
        "express": "^4.18.0",
        "pg": "^8.8.0",
        "redis": "^4.5.0",
        "amqplib": "^0.10.0"
    },
    "scripts": {
        "start": "node server.js"
    }
}
EOF

cat > services/api/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 8000
CMD ["npm", "start"]
EOF

echo "✅ Complex service dependencies configured"
```

### Task 3.2: Comprehensive Health Checks (15 minutes)

```bash
echo "=== Task 3.2: Comprehensive Health Check Implementation ==="

# Background worker service
cat > services/worker/worker.js << 'EOF'
const amqp = require('amqplib');
const { Client } = require('pg');

const dbConfig = {
    host: 'postgres',
    port: 5432,
    database: 'myapp',
    user: 'user',
    password: 'secret123',
};

let isHealthy = false;
let lastProcessedJob = null;

async function processJobs() {
    try {
        const connection = await amqp.connect('amqp://rabbitmq');
        const channel = await connection.createChannel();
        
        const queueName = 'job-queue';
        await channel.assertQueue(queueName, { durable: true });
        
        console.log('Worker started, waiting for jobs...');
        isHealthy = true;
        
        channel.consume(queueName, async (message) => {
            if (message) {
                const job = JSON.parse(message.content.toString());
                console.log('Processing job:', job);
                
                // Simulate job processing
                await new Promise(resolve => setTimeout(resolve, 1000));
                
                lastProcessedJob = {
                    id: job.id,
                    processedAt: new Date().toISOString()
                };
                
                channel.ack(message);
            }
        });
        
    } catch (error) {
        console.error('Worker error:', error.message);
        isHealthy = false;
        setTimeout(processJobs, 5000); // Retry in 5 seconds
    }
}

// Health check HTTP server
const http = require('http');
const server = http.createServer((req, res) => {
    if (req.url === '/health') {
        const healthStatus = {
            status: isHealthy ? 'healthy' : 'unhealthy',
            lastProcessedJob,
            uptime: process.uptime(),
            timestamp: new Date().toISOString()
        };
        
        res.writeHead(isHealthy ? 200 : 500, {'Content-Type': 'application/json'});
        res.end(JSON.stringify(healthStatus));
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(9000, () => {
    console.log('Worker health server listening on port 9000');
});

// Start processing jobs
processJobs();
EOF

cat > services/worker/package.json << 'EOF'
{
    "name": "worker-service",
    "version": "1.0.0",
    "main": "worker.js",
    "dependencies": {
        "pg": "^8.8.0",
        "amqplib": "^0.10.0"
    },
    "scripts": {
        "start": "node worker.js"
    }
}
EOF

cat > services/worker/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 9000
CMD ["npm", "start"]
EOF

# Comprehensive Docker Compose with health checks
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Web Frontend
  web:
    build: ./services/web
    ports:
      - "3000:3000"
    depends_on:
      api:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    networks:
      - frontend

  # API Service
  api:
    build: ./services/api
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 15s
      retries: 5
      start_period: 60s
    restart: unless-stopped
    networks:
      - frontend
      - backend

  # Background Worker
  worker:
    build: ./services/worker
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 45s
    restart: unless-stopped
    networks:
      - backend

  # PostgreSQL Database
  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=secret123
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./config/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    networks:
      - backend

  # Redis Cache
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 10s
    networks:
      - backend

  # RabbitMQ Message Queue
  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=secret
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    networks:
      - backend

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
EOF

# Database initialization
cat > config/init.sql << 'EOF'
CREATE TABLE IF NOT EXISTS jobs (
    id SERIAL PRIMARY KEY,
    payload JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS health_checks (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100),
    status VARCHAR(50),
    checked_at TIMESTAMP DEFAULT NOW()
);
EOF

echo "✅ Comprehensive health checks implemented"
```

### Task 3.3: Service Startup Orchestration Testing (15 minutes)

```bash
echo "=== Task 3.3: Service Startup Orchestration Testing ==="

# Deploy the stack and monitor startup sequence
echo "Starting orchestrated deployment..."
docker compose up -d --build

# Monitor service startup sequence
echo "=== Monitoring Service Startup Sequence ==="

monitor_services() {
    for i in {1..30}; do
        echo "--- Check $i ($(date)) ---"
        docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Health}}"
        echo ""
        sleep 10
        
        # Check if all services are healthy
        HEALTHY_COUNT=$(docker compose ps --format json | jq -r '.[] | select(.Health=="healthy") | .Service' | wc -l)
        TOTAL_SERVICES=6
        
        if [ "$HEALTHY_COUNT" -eq "$TOTAL_SERVICES" ]; then
            echo "✅ All services are healthy!"
            break
        fi
        
        echo "Healthy services: $HEALTHY_COUNT/$TOTAL_SERVICES"
    done
}

# Run monitoring in background
monitor_services &
MONITOR_PID=$!

# Wait for services to be ready
echo "Waiting for all services to become healthy..."
sleep 60

# Kill monitoring
kill $MONITOR_PID 2>/dev/null || true

# Test the complete application stack
echo "=== Testing Complete Application Stack ==="

# Test web frontend
if curl -s http://localhost:3000 | grep -q "Service Orchestration Demo"; then
    echo "✅ Web frontend is accessible"
else
    echo "❌ Web frontend not accessible"
fi

# Test API health
API_HEALTH=$(curl -s http://localhost:3000/api/health)
echo "API Health Check:"
echo "$API_HEALTH" | jq

# Check all service dependencies
DB_CHECK=$(echo "$API_HEALTH" | jq -r '.checks.database')
REDIS_CHECK=$(echo "$API_HEALTH" | jq -r '.checks.redis')
RABBIT_CHECK=$(echo "$API_HEALTH" | jq -r '.checks.rabbitmq')

echo "Dependency Status:"
echo "  Database: $DB_CHECK"
echo "  Redis: $REDIS_CHECK"  
echo "  RabbitMQ: $RABBIT_CHECK"

if [ "$DB_CHECK" = "healthy" ] && [ "$REDIS_CHECK" = "healthy" ] && [ "$RABBIT_CHECK" = "healthy" ]; then
    echo "✅ All service dependencies are healthy"
else
    echo "❌ Some service dependencies are unhealthy"
fi

echo "✅ Service orchestration testing completed"
```

### 🧪 Lab 3 Verification

```bash
echo "=== Lab 3 Verification ==="

# Check startup order compliance
echo "=== Startup Order Verification ==="
docker compose logs --timestamps | head -50

# Check health status of all services
echo "=== Health Status Check ==="
docker compose ps

# Test failure recovery
echo "=== Testing Failure Recovery ==="

# Kill a service and watch it restart
echo "Stopping API service to test dependency handling..."
docker compose stop api

sleep 10
echo "API Status after stop:"
docker compose ps api

# Check if dependent services are affected
echo "Web service status:"
docker compose ps web

# Restart API and verify recovery
echo "Restarting API service..."
docker compose start api

sleep 20
echo "Services after API restart:"
docker compose ps

# Verify application functionality after recovery
RECOVERY_TEST=$(curl -s http://localhost:3000/api/health | jq -r '.status' 2>/dev/null)
if [ "$RECOVERY_TEST" = "healthy" ]; then
    echo "✅ Service recovery successful"
else
    echo "❌ Service recovery failed"
fi

echo "✅ Lab 3 verification completed"
```

---

## Lab 4: Secrets Management and Production Security
**Duration**: 45 minutes | **Difficulty**: Advanced

### 🎯 Objectives
- Implement secure secrets management patterns
- Practice production security configurations
- Learn external secrets integration
- Create audit-ready security configurations

### Task 4.1: Basic Secrets Implementation (15 minutes)

```bash
echo "=== Task 4.1: Basic Secrets Management Setup ==="

# Create new lab directory
cd ~/docker-labs && mkdir -p compose-lab4 && cd compose-lab4
mkdir -p secrets config app

# Secure web application
cat > app/server.js << 'EOF'
const express = require('express');
const fs = require('fs');
const { Client } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Read secrets from files (Docker secrets pattern)
function readSecret(secretPath) {
    try {
        return fs.readFileSync(secretPath, 'utf8').trim();
    } catch (error) {
        console.warn(`Could not read secret from ${secretPath}:`, error.message);
        return null;
    }
}

// Configuration with secrets
const config = {
    database: {
        host: process.env.DB_HOST || 'postgres',
        port: 5432,
        database: process.env.DB_NAME || 'secure_app',
        user: process.env.DB_USER || 'app_user',
        password: readSecret('/run/secrets/db_password') || process.env.DB_PASSWORD
    },
    jwt: {
        secret: readSecret('/run/secrets/jwt_secret') || process.env.JWT_SECRET || 'fallback-secret'
    },
    api: {
        key: readSecret('/run/secrets/api_key') || process.env.API_KEY
    }
};

let dbClient;

// Initialize database connection
async function initDB() {
    try {
        dbClient = new Client(config.database);
        await dbClient.connect();
        console.log('✅ Database connected securely');
        
        // Create users table
        await dbClient.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        `);
        
    } catch (error) {
        console.error('Database initialization failed:', error.message);
        throw error;
    }
}

// Middleware to check API key
function requireApiKey(req, res, next) {
    const providedKey = req.header('X-API-Key');
    if (!providedKey || providedKey !== config.api.key) {
        return res.status(401).json({ error: 'Invalid or missing API key' });
    }
    next();
}

// Routes
app.get('/', (req, res) => {
    res.json({
        service: 'Secure Application',
        status: 'running',
        security: {
            secrets_loaded: {
                db_password: !!config.database.password,
                jwt_secret: !!config.jwt.secret,
                api_key: !!config.api.key
            }
        },
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        database: dbClient ? 'connected' : 'disconnected',
        secrets: {
            db_password: config.database.password ? 'loaded' : 'missing',
            jwt_secret: config.jwt.secret !== 'fallback-secret' ? 'loaded' : 'fallback',
            api_key: config.api.key ? 'loaded' : 'missing'
        }
    });
});

// Protected route requiring API key
app.get('/secure-data', requireApiKey, async (req, res) => {
    try {
        const result = await dbClient.query('SELECT * FROM users ORDER BY created_at DESC LIMIT 10');
        res.json({
            message: 'Secure data accessed successfully',
            data: result.rows,
            access_time: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Create user endpoint (protected)
app.post('/users', requireApiKey, express.json(), async (req, res) => {
    try {
        const { username, email } = req.body;
        const result = await dbClient.query(
            'INSERT INTO users (username, email) VALUES ($1, $2) RETURNING *',
            [username, email]
        );
        res.json({ success: true, user: result.rows[0] });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Start server
initDB().then(() => {
    app.listen(port, () => {
        console.log(`Secure application listening on port ${port}`);
        console.log('Secrets status:', {
            db_password: config.database.password ? '✅ loaded' : '❌ missing',
            jwt_secret: config.jwt.secret !== 'fallback-secret' ? '✅ loaded' : '⚠️ fallback',
            api_key: config.api.key ? '✅ loaded' : '❌ missing'
        });
    });
}).catch(error => {
    console.error('Failed to start secure application:', error);
    process.exit(1);
});
EOF

cat > app/package.json << 'EOF'
{
    "name": "secure-app",
    "version": "1.0.0",
    "main": "server.js",
    "dependencies": {
        "express": "^4.18.0",
        "pg": "^8.8.0"
    },
    "scripts": {
        "start": "node server.js"
    }
}
EOF

cat > app/Dockerfile << 'EOF'
FROM node:18-alpine

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 appuser -G appgroup

WORKDIR /app
COPY package.json .
RUN npm install --only=production

COPY server.js .

# Run as non-root user
USER appuser

EXPOSE 3000
CMD ["npm", "start"]
EOF

echo "✅ Secure application created"
```

### Task 4.2: Docker Secrets Configuration (15 minutes)

```bash
echo "=== Task 4.2: Docker Secrets Configuration ==="

# Create secret files
echo "super-secure-database-password-$(date +%s)" > secrets/db_password.txt
echo "jwt-secret-key-$(openssl rand -hex 32)" > secrets/jwt_secret.txt
echo "api-key-$(openssl rand -hex 16)" > secrets/api_key.txt

# Docker Compose with secrets
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Secure application
  webapp:
    build: ./app
    ports:
      - "3000:3000"
    environment:
      - DB_HOST=postgres
      - DB_NAME=secure_app
      - DB_USER=app_user
    secrets:
      - db_password
      - jwt_secret
      - api_key
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - secure-network

  # PostgreSQL with secrets
  postgres:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=secure_app
      - POSTGRES_USER=app_user
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app_user -d secure_app"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - secure-network

volumes:
  postgres_data:

networks:
  secure-network:
    driver: bridge

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
  api_key:
    file: ./secrets/api_key.txt
EOF

# Deploy and test secrets
echo "Deploying secure application..."
docker compose up -d --build

# Wait for services to be ready
sleep 20

# Test application status
echo "=== Testing Secrets Implementation ==="
APP_STATUS=$(curl -s http://localhost:3000/)
echo "Application Status:"
echo "$APP_STATUS" | jq

# Check if secrets are loaded
SECRETS_STATUS=$(echo "$APP_STATUS" | jq '.security.secrets_loaded')
echo "Secrets loaded status: $SECRETS_STATUS"

# Test health endpoint
HEALTH_STATUS=$(curl -s http://localhost:3000/health)
echo "Health Status:"
echo "$HEALTH_STATUS" | jq

echo "✅ Docker secrets implementation tested"
```

### Task 4.3: Production Security Configuration (15 minutes)

```bash
echo "=== Task 4.3: Production Security Configuration ==="

# Production-hardened configuration
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  webapp:
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  postgres:
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
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'

  # Nginx reverse proxy with security headers
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx-security.conf:/etc/nginx/nginx.conf:ro
      - ./config/ssl:/etc/nginx/ssl:ro
    depends_on:
      webapp:
        condition: service_healthy
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - secure-network

  # Security monitoring (optional)
  fail2ban:
    image: crazymax/fail2ban:latest
    volumes:
      - fail2ban_data:/data
      - /var/log:/var/log:ro
    environment:
      - TZ=UTC
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - NET_RAW
    networks:
      - secure-network

volumes:
  fail2ban_data:
EOF

# Secure nginx configuration
cat > config/nginx-security.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Hide nginx version
    server_tokens off;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=web:10m rate=30r/s;
    
    upstream webapp {
        server webapp:3000;
        keepalive 32;
    }
    
    server {
        listen 80;
        
        # Rate limiting
        limit_req zone=web burst=20 nodelay;
        
        # Security headers for API endpoints
        location /secure-data {
            limit_req zone=api burst=5 nodelay;
            proxy_pass http://webapp;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        location / {
            proxy_pass http://webapp;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# Create SSL certificate directory (self-signed for demo)
mkdir -p config/ssl

# Generate self-signed certificate for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout config/ssl/nginx.key \
    -out config/ssl/nginx.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=localhost"

echo "✅ Production security configuration created"

# Test production deployment
echo "=== Testing Production Security Deployment ==="

# Deploy with production overrides
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Wait for services
sleep 30

# Test security headers
echo "=== Testing Security Headers ==="
curl -I http://localhost/ | grep -E "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection)"

# Test API with security
API_KEY=$(cat secrets/api_key.txt)
echo "=== Testing API Security ==="

# Test without API key (should fail)
curl -s http://localhost/secure-data | jq

# Test with API key (should succeed)  
curl -s -H "X-API-Key: $API_KEY" http://localhost/secure-data | jq

echo "✅ Production security testing completed"
```

### 🧪 Lab 4 Verification

```bash
echo "=== Lab 4 Verification ==="

# Verify secrets are properly loaded
echo "=== Secrets Verification ==="
HEALTH_CHECK=$(curl -s http://localhost:3000/health)
echo "Health check response:"
echo "$HEALTH_CHECK" | jq '.secrets'

# Check all secrets are loaded (not missing or fallback)
DB_SECRET=$(echo "$HEALTH_CHECK" | jq -r '.secrets.db_password')
JWT_SECRET=$(echo "$HEALTH_CHECK" | jq -r '.secrets.jwt_secret')
API_SECRET=$(echo "$HEALTH_CHECK" | jq -r '.secrets.api_key')

echo "Secrets status: DB=$DB_SECRET, JWT=$JWT_SECRET, API=$API_SECRET"

if [ "$DB_SECRET" = "loaded" ] && [ "$JWT_SECRET" = "loaded" ] && [ "$API_SECRET" = "loaded" ]; then
    echo "✅ All secrets loaded correctly"
else
    echo "❌ Some secrets not loaded properly"
fi

# Test security features
echo "=== Security Features Verification ==="

# Test read-only filesystem
docker compose exec webapp touch /test-readonly 2>&1 | grep -q "Read-only" && echo "✅ Read-only filesystem working" || echo "❌ Read-only filesystem not working"

# Test API key protection
echo "Testing API key protection:"
curl -s http://localhost/secure-data | jq -r '.error' | grep -q "Invalid or missing API key" && echo "✅ API key protection working" || echo "❌ API key protection failed"

# Test with valid API key
API_KEY=$(cat secrets/api_key.txt)
SECURE_RESPONSE=$(curl -s -H "X-API-Key: $API_KEY" http://localhost/secure-data)
if echo "$SECURE_RESPONSE" | grep -q "Secure data accessed successfully"; then
    echo "✅ API key authentication working"
else
    echo "❌ API key authentication failed"
fi

# Verify security headers
echo "=== Security Headers Check ==="
HEADERS=$(curl -I -s http://localhost/)
echo "$HEADERS" | grep -q "X-Frame-Options: DENY" && echo "✅ X-Frame-Options header present" || echo "❌ X-Frame-Options header missing"
echo "$HEADERS" | grep -q "X-Content-Type-Options: nosniff" && echo "✅ X-Content-Type-Options header present" || echo "❌ X-Content-Type-Options header missing"

echo "✅ Lab 4 verification completed"
```

## 🎓 Lab Summary and Cleanup

### Key Concepts Demonstrated

1. **Service Modeling**: Multi-tier application architecture with proper service separation
2. **Environment Management**: Development vs production configurations with override patterns
3. **Dependency Orchestration**: Health checks, startup ordering, and failure recovery
4. **Secrets Management**: Secure handling of sensitive data with Docker secrets
5. **Production Security**: Security hardening, read-only filesystems, and security headers
6. **Network Isolation**: Proper network segmentation and service communication

### Production Patterns Learned

- Multi-environment Docker Compose configurations
- Service dependency management with health checks
- Secure secrets management patterns
- Production security hardening techniques
- Network isolation and communication strategies
- Monitoring and failure recovery procedures

### Optional Cleanup

```bash
# Clean up all lab resources
echo "=== Lab Cleanup ==="

# Stop all compose projects
cd ~/docker-labs/compose-lab1 && docker compose down --volumes 2>/dev/null || true
cd ~/docker-labs/compose-lab2 && docker compose down --volumes 2>/dev/null || true
cd ~/docker-labs/compose-lab3 && docker compose down --volumes 2>/dev/null || true
cd ~/docker-labs/compose-lab4 && docker compose down --volumes 2>/dev/null || true

# Remove lab directories
rm -rf ~/docker-labs/compose-lab*

# Clean up Docker resources
docker system prune -f
docker volume prune -f

echo "✅ Lab cleanup completed"
```

---

> 💡 **Key Takeaway**: Docker Compose transforms complex multi-container applications into manageable, reproducible deployments. These labs demonstrated service orchestration, environment management, dependency coordination, and security patterns essential for production Docker deployments.