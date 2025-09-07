# Micro-Lesson: Health Check Design Patterns

**Anchor**: `p03-m01-l01`  
**Duration**: 4 minutes  
**Objective**: Design effective health checks that test actual application functionality

## 🎯 Core Concept

**Health checks should verify application functionality, not just process existence**. A running process doesn't mean your application is working correctly. Design health checks that test the actual capabilities your users depend on.

## 🔍 The Health Check Hierarchy

### Level 1: Process Health (Basic)
```dockerfile
# ❌ Not recommended - only checks if process exists
HEALTHCHECK CMD pgrep python || exit 1
```
**Problem**: Process might be running but application could be deadlocked, out of memory, or otherwise broken.

### Level 2: Port Availability (Better)
```dockerfile
# ⚠️ Better but still limited
HEALTHCHECK CMD curl -f http://localhost:8080 || exit 1
```
**Problem**: Port might be open but application logic could be failing.

### Level 3: Application Logic (Good)
```dockerfile
# ✅ Tests actual application functionality
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

## 🛠 Health Endpoint Design Patterns

### Pattern 1: Simple Status Check
```python
@app.route('/health')
def health_check():
    return {'status': 'healthy', 'timestamp': time.time()}
```

### Pattern 2: Dependency Verification
```python
@app.route('/health')
def health_check():
    try:
        # Test database connection
        db.execute('SELECT 1')
        
        # Test external API
        response = requests.get('https://api.external.com/ping', timeout=2)
        
        return {'status': 'healthy', 'dependencies': {'db': True, 'api': True}}
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}, 503
```

### Pattern 3: Comprehensive Health (Production)
```python
@app.route('/health')
def health_check():
    health_data = {
        'status': 'healthy',
        'checks': {},
        'timestamp': time.time(),
        'version': app.config['VERSION']
    }
    
    # Database health
    try:
        db.execute('SELECT COUNT(*) FROM users LIMIT 1')
        health_data['checks']['database'] = 'healthy'
    except:
        health_data['checks']['database'] = 'unhealthy'
        health_data['status'] = 'unhealthy'
    
    # Cache health
    try:
        cache.set('health_check', 'ok', timeout=1)
        cache.get('health_check')
        health_data['checks']['cache'] = 'healthy'
    except:
        health_data['checks']['cache'] = 'unhealthy'
        health_data['status'] = 'degraded'  # Cache failure might not be critical
    
    # Disk space check
    disk_usage = shutil.disk_usage('/tmp')
    if disk_usage.free / disk_usage.total < 0.1:  # Less than 10% free
        health_data['checks']['disk'] = 'unhealthy'
        health_data['status'] = 'unhealthy'
    else:
        health_data['checks']['disk'] = 'healthy'
    
    status_code = 200 if health_data['status'] == 'healthy' else 503
    return health_data, status_code
```

## ⚡ Health Check Configuration Best Practices

### Timing Configuration
```dockerfile
HEALTHCHECK \
    --interval=30s    # Check every 30 seconds (not too frequent)
    --timeout=10s     # Allow 10 seconds for health check to complete
    --start-period=60s # Give app 60 seconds to start before checking
    --retries=3       # Retry 3 times before marking unhealthy
    CMD curl -f http://localhost:8080/health || exit 1
```

**Timing Guidelines**:
- **interval**: 15-60 seconds (balance responsiveness vs load)
- **timeout**: 3-10 seconds (must be less than interval)
- **start-period**: Account for your app's startup time
- **retries**: 2-5 attempts (avoid false positives from temporary issues)

### Health Check vs Readiness Check

```python
# Health check - "Is the app working?"
@app.route('/health')
def health():
    if critical_component_working():
        return {'status': 'healthy'}
    return {'status': 'unhealthy'}, 503

# Readiness check - "Is the app ready for traffic?"
@app.route('/ready')
def ready():
    if app_fully_initialized() and dependencies_available():
        return {'status': 'ready'}
    return {'status': 'not_ready'}, 503
```

**Key Differences**:
- **Health**: Should container be restarted?
- **Readiness**: Should container receive traffic?

## 🚨 Common Anti-Patterns

❌ **Heavy health checks**:
```python
# Don't do expensive operations in health checks
@app.route('/health')
def bad_health_check():
    # ❌ This is too expensive for a health check
    users = User.query.all()  # Loads all users from database
    return {'status': 'healthy', 'user_count': len(users)}
```

❌ **External dependency failures causing restarts**:
```python
# Health check should distinguish critical vs non-critical failures
@app.route('/health')
def problematic_health_check():
    try:
        # If external service is down, this fails
        external_api_status = requests.get('https://external.com/status', timeout=30)
        return {'status': 'healthy'}
    except:
        # ❌ This will cause container restarts when external service is down
        return {'status': 'unhealthy'}, 503
```

✅ **Better approach**:
```python
@app.route('/health')
def better_health_check():
    health = {'status': 'healthy', 'checks': {}}
    
    # Critical: Database (app can't work without this)
    try:
        db.execute('SELECT 1')
        health['checks']['database'] = 'up'
    except:
        health['status'] = 'unhealthy'
        health['checks']['database'] = 'down'
    
    # Non-critical: External API (app can work without this)
    try:
        requests.get('https://external.com/status', timeout=2)
        health['checks']['external_api'] = 'up'
    except:
        health['checks']['external_api'] = 'down'
        # Don't change overall status - this isn't critical
    
    return health, 200 if health['status'] == 'healthy' else 503
```

## 🎯 Decision Framework

**For each dependency, ask**:
1. **Is this critical for basic app functionality?**
   - Yes → Include in health check
   - No → Include in readiness check or separate monitoring

2. **Can this check complete quickly (<5 seconds)?**
   - Yes → Safe for health checks
   - No → Use async monitoring instead

3. **Does failure here mean the container should restart?**
   - Yes → Return unhealthy status
   - No → Log error but return healthy

## 💡 Production Tips

**Load Balancer Integration**:
- Use `/ready` for load balancer health checks
- Use `/health` for container orchestrator health checks

**Monitoring Integration**:
- Expose detailed health data for monitoring systems
- Include metrics like response time, dependency status

**Security Considerations**:
- Don't expose sensitive information in health endpoints
- Consider authentication for detailed health data

## 🎓 Practice Challenge

Design health checks for these scenarios:
1. **Web API** with database and cache dependencies
2. **Background worker** that processes queued jobs
3. **Microservice** that depends on 3 other services

Remember: Health checks should be **fast**, **reliable**, and test **actual functionality** your users depend on.