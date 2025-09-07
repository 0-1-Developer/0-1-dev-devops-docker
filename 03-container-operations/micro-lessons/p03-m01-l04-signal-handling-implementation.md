# Micro-Lesson: Signal Handling Implementation

**Anchor**: `p03-m01-l04`  
**Duration**: 5 minutes  
**Objective**: Implement proper signal handling for graceful container shutdowns and clean resource cleanup

## 🎯 Core Concept

**Containers should shut down gracefully when asked, not when forced**. Proper signal handling allows applications to clean up resources, save state, and complete critical operations before terminating. This prevents data loss and ensures system reliability.

## 📡 Container Signal Flow

### The Docker Stop Sequence
1. **User runs**: `docker stop container`
2. **Docker sends**: `SIGTERM` to PID 1 in container
3. **Application has**: Grace period (default 10 seconds) to shut down
4. **Docker sends**: `SIGKILL` if still running (force terminate)

### Critical Signal Types
- **SIGTERM (15)**: Graceful shutdown request
- **SIGKILL (9)**: Immediate termination (cannot be caught)
- **SIGINT (2)**: Interrupt signal (Ctrl+C)
- **SIGUSR1/SIGUSR2**: Custom application signals

## ⚠️ The PID 1 Problem

### Why Signals Matter in Containers
```dockerfile
# ❌ Shell form - signals go to shell, not your app
CMD python app.py

# ✅ Exec form - signals go directly to your app  
CMD ["python", "app.py"]
```

**The Problem with Shell Form**:
- Shell becomes PID 1
- Shell doesn't forward signals properly
- Your app never receives SIGTERM
- Container gets killed with SIGKILL after timeout

## 🛠 Signal Handler Implementation Patterns

### Pattern 1: Basic Python Signal Handler
```python
import signal
import sys
import time

class GracefulApp:
    def __init__(self):
        self.running = True
        
    def signal_handler(self, signum, frame):
        print(f"Received signal {signum} - shutting down gracefully...")
        self.running = False
        
        # Perform cleanup
        self.cleanup()
        print("Graceful shutdown completed")
        sys.exit(0)
        
    def cleanup(self):
        # Close database connections
        # Flush logs
        # Save state
        # Close file handles
        time.sleep(2)  # Simulate cleanup time
        
    def start(self):
        # Register signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        # Main application loop
        while self.running:
            # Do work
            time.sleep(1)

if __name__ == '__main__':
    app = GracefulApp()
    app.start()
```

### Pattern 2: Web Server Graceful Shutdown
```python
import signal
import sys
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

class GracefulHTTPServer:
    def __init__(self):
        self.server = None
        self.shutting_down = False
        
    def signal_handler(self, signum, frame):
        print(f"Received signal {signum} - starting graceful shutdown")
        self.shutting_down = True
        
        if self.server:
            # Stop accepting new connections
            print("Stopping HTTP server...")
            
            # Give time for existing requests to complete
            shutdown_thread = threading.Thread(target=self.server.shutdown)
            shutdown_thread.start()
            shutdown_thread.join(timeout=8)  # Wait up to 8 seconds
            
        print("HTTP server shutdown completed")
        sys.exit(0)
        
    def start(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.server.shutting_down:
                    self.send_response(503)
                    self.end_headers()
                    self.wfile.write(b'Server shutting down')
                    return
                    
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'Hello World')
        
        Handler.server = self  # Reference for shutdown status
        self.server = HTTPServer(('', 8080), Handler)
        
        print("HTTP server starting on port 8080")
        try:
            self.server.serve_forever()
        except KeyboardInterrupt:
            self.signal_handler(signal.SIGINT, None)

if __name__ == '__main__':
    server = GracefulHTTPServer()
    server.start()
```

### Pattern 3: Database Connection Cleanup
```python
import signal
import sys
import psycopg2
import threading
import time

class DatabaseApp:
    def __init__(self):
        self.running = True
        self.connections = []
        self.active_transactions = 0
        
    def signal_handler(self, signum, frame):
        print(f"Received signal {signum} - starting database cleanup")
        self.running = False
        
        # Wait for active transactions to complete
        timeout = 10
        start_time = time.time()
        
        while self.active_transactions > 0 and (time.time() - start_time) < timeout:
            print(f"Waiting for {self.active_transactions} transactions to complete...")
            time.sleep(1)
            
        # Close all database connections
        print("Closing database connections...")
        for conn in self.connections:
            try:
                conn.close()
            except:
                pass
                
        print("Database cleanup completed")
        sys.exit(0)
        
    def execute_query(self, query):
        self.active_transactions += 1
        try:
            # Simulate database work
            time.sleep(2)
        finally:
            self.active_transactions -= 1
            
    def start(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        # Create database connections
        for i in range(5):
            try:
                conn = psycopg2.connect("dbname=test")
                self.connections.append(conn)
            except:
                pass  # Handle connection errors
                
        # Worker threads
        while self.running:
            self.execute_query("SELECT * FROM table")

if __name__ == '__main__':
    app = DatabaseApp()
    app.start()
```

## 🐳 Dockerfile Signal Best Practices

### Correct Dockerfile Patterns
```dockerfile
# ✅ Use exec form for proper signal handling
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .

# Exec form ensures signals reach your application
CMD ["python", "app.py"]
```

### Custom Stop Timeout
```bash
# Give application more time to shut down gracefully
docker run --stop-timeout 30 my-app

# Or set in Dockerfile
# STOPSIGNAL SIGTERM  # This is the default
```

### Init System for Complex Applications
```dockerfile
# Use tini as PID 1 for signal handling
FROM python:3.9-slim
RUN apt-get update && apt-get install -y tini
ENTRYPOINT ["tini", "--"]
CMD ["python", "app.py"]
```

## 🔧 Testing Signal Handling

### Manual Testing
```bash
# Start container
docker run -d --name signal-test my-app

# Test graceful shutdown
docker stop --time 15 signal-test

# Check logs for graceful shutdown messages
docker logs signal-test

# Test immediate kill
docker kill signal-test
```

### Automated Testing Script
```bash
#!/bin/bash
# Test signal handling behavior

echo "Testing graceful shutdown..."
docker run -d --name signal-test my-app

sleep 5
echo "Sending SIGTERM..."
start_time=$(date +%s)
docker stop --time 20 signal-test
end_time=$(date +%s)

shutdown_time=$((end_time - start_time))
echo "Shutdown took: ${shutdown_time} seconds"

# Check for graceful shutdown in logs
if docker logs signal-test | grep -q "graceful"; then
    echo "✅ Graceful shutdown detected"
else
    echo "❌ No graceful shutdown detected"
fi

docker rm signal-test
```

## 🚨 Common Signal Handling Mistakes

❌ **Shell form in Dockerfile**:
```dockerfile
# Shell becomes PID 1, doesn't forward signals
CMD python app.py
```

❌ **No signal handlers**:
```python
# Application doesn't handle SIGTERM
while True:
    do_work()  # Gets killed abruptly
```

❌ **Blocking cleanup operations**:
```python
def signal_handler(signum, frame):
    # This blocks the shutdown
    time.sleep(30)  # Too long!
    cleanup()
```

❌ **No timeout protection**:
```python
def signal_handler(signum, frame):
    # Waits forever for cleanup
    while active_connections > 0:
        time.sleep(1)  # No timeout!
```

✅ **Correct approach**:
```dockerfile
CMD ["python", "app.py"]  # Exec form
```

```python
def signal_handler(signum, frame):
    print("Starting graceful shutdown...")
    self.running = False
    
    # Timeout protection
    cleanup_timeout = 10
    start_time = time.time()
    
    while active_work > 0 and (time.time() - start_time) < cleanup_timeout:
        time.sleep(0.5)
        
    if active_work > 0:
        print(f"Force shutdown - {active_work} operations incomplete")
        
    cleanup_resources()
    sys.exit(0)
```

## 💡 Production Signal Handling Tips

### Monitoring Signal Handling
```bash
# Monitor container stops and starts
docker events --filter event=stop --filter event=start

# Check exit codes
docker inspect container | jq '.State.ExitCode'
# 0 = Normal exit
# 137 = SIGKILL (9)  
# 143 = SIGTERM (15)
```

### Integration with Orchestrators
- **Kubernetes**: Uses `terminationGracePeriodSeconds`
- **Docker Swarm**: Uses stop grace period
- **Docker Compose**: Uses `stop_grace_period`

### Health Checks During Shutdown
```python
@app.route('/health')
def health_check():
    if shutting_down:
        return {'status': 'shutting_down'}, 503
    return {'status': 'healthy'}, 200
```

## 🎓 Signal Handling Checklist

- [ ] **Use exec form** in Dockerfile CMD/ENTRYPOINT
- [ ] **Register signal handlers** for SIGTERM and SIGINT
- [ ] **Implement cleanup logic** (close connections, save state)
- [ ] **Add timeout protection** to prevent hanging shutdowns
- [ ] **Test graceful shutdown** behavior regularly
- [ ] **Log shutdown events** for debugging
- [ ] **Update health checks** during shutdown phase

## 🔍 Quick Validation

Test your signal handling with this command:
```bash
# Should show graceful shutdown logs, not abrupt termination
docker run --rm my-app &
sleep 2
docker stop $(docker ps -q | head -1)
```

**Good signals** = Clean logs, proper cleanup, expected shutdown time
**Bad signals** = Abrupt termination, no cleanup logs, timeout kills