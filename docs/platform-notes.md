# Platform-Specific Notes

> **Purpose**: Address platform-specific behaviors, gotchas, and optimizations across Linux, macOS, Windows, and WSL2  
> **Scope**: Centralized reference for OS-specific Docker differences and troubleshooting

## 🎯 Overview

Docker behavior varies across platforms due to fundamental differences in operating systems, virtualization approaches, and filesystem implementations. This guide consolidates platform-specific knowledge referenced throughout the learning path.

---

## 🐧 Linux (Native Docker Engine)

### Advantages
- **Native Performance**: Containers run directly on Linux kernel
- **Full Feature Set**: All Docker features available
- **Resource Efficiency**: Minimal overhead compared to virtualized platforms
- **Production Parity**: Same environment as most production deployments

### File System Behavior
```bash
# Linux file permissions work natively
docker run -v $(pwd):/app ubuntu ls -la /app
# Shows actual host user ownership

# SELinux considerations
docker run -v $(pwd):/app:Z ubuntu ls -la /app  # :Z for proper SELinux context
```

### Networking
- **Host network mode**: Direct access to host network stack
- **Bridge network**: Native Linux bridge implementation
- **Custom iptables**: Full control over network rules

### Common Gotchas
- **Permission Issues**: Add user to docker group
  ```bash
  sudo usermod -aG docker $USER
  # Log out and log back in
  ```
- **Systemd Integration**: Docker as systemd service
  ```bash
  sudo systemctl start docker
  sudo systemctl enable docker
  ```
- **Storage Driver**: Usually overlay2, device-specific optimizations available

### Troubleshooting
```bash
# Check Docker service status
sudo systemctl status docker

# View Docker daemon logs
sudo journalctl -u docker.service

# Check disk usage by storage driver
docker system df
df -h /var/lib/docker
```

---

## 🍎 macOS (Docker Desktop)

### Architecture Overview
- **Linux VM**: Docker runs inside HyperKit/QEMU virtual machine
- **File System**: VirtioFS or gRPC-FUSE for volume mounting
- **Networking**: VPN kit for port forwarding

### Performance Considerations
```bash
# File sync performance (avoid when possible)
docker run -v $(pwd):/app node npm install  # SLOW on macOS

# Use named volumes for better performance
docker volume create node_modules
docker run -v node_modules:/app/node_modules -v $(pwd):/app node npm install
```

### File System Specifics
- **Case Sensitivity**: macOS is case-insensitive, Linux containers are case-sensitive
- **File Watching**: Some file watchers don't work with bind mounts
- **Permissions**: No direct user/group mapping issues

### Docker Desktop Settings
```bash
# Resource allocation (via Docker Desktop preferences)
# - CPU: Default 2-4 cores
# - Memory: Default 2GB (increase for heavy workloads)
# - Disk: Default 64GB (increase for large images)

# Enable file sharing for specific directories
# Docker Desktop > Preferences > Resources > File Sharing
```

### Common Gotchas
- **Port Conflicts**: Check for services using same ports
  ```bash
  lsof -i :8080  # Check what's using port 8080
  ```
- **DNS Resolution**: `host.docker.internal` points to host
- **File Sync Delays**: Changes may not immediately reflect in containers

### Troubleshooting
```bash
# Reset Docker Desktop
# Docker Desktop > Preferences > Reset > Reset to factory defaults

# Check Docker Desktop logs
~/Library/Containers/com.docker.docker/Data/log/

# Resource usage
docker system df
```

---

## 🪟 Windows (Docker Desktop)

### Architecture Options
1. **WSL2 Backend** (Recommended): Linux containers in WSL2 VM
2. **Hyper-V Backend** (Legacy): Windows/Linux containers in Hyper-V

### WSL2 Backend (Recommended)
```powershell
# Enable WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Set WSL2 as default
wsl --set-default-version 2

# Install Ubuntu distribution
wsl --install -d Ubuntu
```

### File System Behavior
```bash
# Windows paths in containers
docker run -v C:\Users\username\project:/app ubuntu ls -la /app

# WSL2 path mapping
docker run -v /mnt/c/Users/username/project:/app ubuntu ls -la /app

# Performance: Keep files in WSL2 filesystem for better performance
# Good: /home/user/project
# Slow: /mnt/c/Users/user/project
```

### Line Endings
```bash
# Configure git for consistent line endings
git config --global core.autocrlf input
git config --global core.eol lf

# .gitattributes in repository
echo "* text=auto eol=lf" > .gitattributes
echo "*.sh text eol=lf" >> .gitattributes
```

### Networking
- **Port Publishing**: Works similarly to other platforms
- **Host Networking**: Not available on Windows
- **localhost**: `host.docker.internal` for host access

### Common Gotchas
- **Drive Sharing**: Ensure drives are shared in Docker Desktop settings
- **Antivirus**: Exclude Docker directories from real-time scanning
- **Windows Defender**: Can interfere with container operations
- **PowerShell vs CMD**: Use PowerShell for better Docker experience

### Troubleshooting
```powershell
# Check Windows features
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

# Docker Desktop logs
# %LOCALAPPDATA%\Docker\log\

# WSL2 status
wsl --status
wsl --list --verbose
```

---

## 🔄 WSL2 (Windows Subsystem for Linux 2)

### Best Practices
- **File Location**: Keep Docker projects in WSL2 filesystem (`/home/user/`)
- **Resource Allocation**: Configure .wslconfig for memory limits
- **Performance**: Use WSL2 native filesystem for better performance

### Configuration
```bash
# ~/.wslconfig (Windows user directory)
[wsl2]
memory=8GB
processors=4
swap=2GB
localhostForwarding=true
```

### File System Performance
```bash
# Fast: Files in WSL2 filesystem
cd /home/username/project
docker build -t myapp .

# Slow: Files in Windows filesystem mounted in WSL2
cd /mnt/c/Users/username/project
docker build -t myapp .  # Much slower due to cross-filesystem operations
```

### Integration
```bash
# Docker Desktop integration with WSL2 distributions
# Docker Desktop > Settings > Resources > WSL Integration
# Enable integration with specific WSL2 distributions

# Access from Windows
\\wsl$\Ubuntu\home\username\project
```

### Common Gotchas
- **Memory Usage**: WSL2 can consume significant memory
- **File Permissions**: Different permission models between Windows and Linux
- **Network Access**: Some corporate networks block WSL2 networking

### Troubleshooting
```bash
# Restart WSL2
wsl --shutdown
# Start Docker Desktop again

# Check WSL2 Docker integration
docker version  # Should show both client and server

# Resource usage
wsl --list --verbose
Get-Process -Name "Vmmem"  # WSL2 memory usage in Windows
```

---

## 📊 Performance Comparison Matrix

| Operation | Linux | macOS | Windows (WSL2) | Windows (Hyper-V) |
|-----------|-------|-------|----------------|-------------------|
| Container Startup | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| File I/O (Bind Mounts) | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Network Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Resource Usage | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Build Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 🔧 Cross-Platform Development Tips

### Dockerfile Best Practices
```dockerfile
# Use consistent line endings
FROM ubuntu:20.04

# Avoid platform-specific paths
WORKDIR /app
COPY . .

# Use environment variables for paths
ENV DATA_PATH="/data"
VOLUME ["${DATA_PATH}"]

# Handle permissions explicitly
RUN adduser --disabled-password --gecos '' appuser
USER appuser
```

### Docker Compose Considerations
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    volumes:
      # Use named volumes for better cross-platform performance
      - node_modules:/app/node_modules
      - .:/app
    environment:
      # Use environment variables for platform-specific config
      - NODE_ENV=${NODE_ENV:-development}

volumes:
  node_modules:
```

### Build Context Optimization
```dockerfile
# .dockerignore - works consistently across platforms
node_modules
*.log
.git
.DS_Store
Thumbs.db
.env
```

---

## 🚨 Common Cross-Platform Issues

### File Path Issues
```bash
# Problem: Windows paths in scripts
COPY scripts\build.bat /app/  # Fails on Linux/macOS

# Solution: Use forward slashes consistently
COPY scripts/build.sh /app/
```

### Line Ending Problems
```bash
# Problem: Windows CRLF line endings in shell scripts
#!/bin/bash^M  # ^M indicates CRLF
echo "Hello"^M

# Solution: Configure git and use .gitattributes
git config --global core.autocrlf input
echo "*.sh text eol=lf" >> .gitattributes
```

### Permission Issues
```bash
# Problem: Different user ID mappings
docker run -v $(pwd):/app ubuntu ls -la /app
# May show different owners on different platforms

# Solution: Use numeric user IDs when possible
docker run --user $(id -u):$(id -g) -v $(pwd):/app ubuntu ls -la /app
```

### Performance Optimization
```bash
# Slow: Bind mount with node_modules on macOS/Windows
docker run -v $(pwd):/app node npm install

# Fast: Use volumes for dependencies
docker volume create node_modules
docker run -v node_modules:/app/node_modules -v $(pwd):/app node npm install
```

---

## 🔍 Platform-Specific Debugging

### Linux Debugging
```bash
# Container namespace inspection
docker run --rm -it --pid container:myapp --net container:myapp --cap-add SYS_PTRACE alpine
ps aux  # See processes in target container

# System resource monitoring
docker stats
htop
iotop
```

### macOS Debugging
```bash
# Docker Desktop VM access
screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty

# File system performance analysis
fs_usage -w | grep docker

# Network debugging
netstat -an | grep LISTEN
```

### Windows Debugging
```powershell
# Docker Desktop logs
Get-EventLog -LogName Application -Source Docker*

# WSL2 resource usage
Get-Process Vmmem
Get-Counter "\Memory\Available Bytes"

# Network troubleshooting
netstat -an | findstr LISTENING
Test-NetConnection localhost -Port 8080
```

---

## 📚 Platform Migration Guide

### Moving from Windows to Linux
1. **File paths**: Convert backslashes to forward slashes
2. **Line endings**: Ensure LF line endings for shell scripts
3. **Permissions**: Review user/group mappings
4. **Networking**: Host network mode now available
5. **Performance**: Expect significant performance improvements

### Moving from macOS to Linux
1. **File system**: Case sensitivity differences
2. **DNS**: Different localhost resolution behavior
3. **Resource limits**: Native Docker has different defaults
4. **File watching**: Native file system events work better

### Optimizing for Multiple Platforms
```bash
# Use multi-platform builds
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .

# Test on multiple platforms
docker run --platform linux/amd64 myapp
docker run --platform linux/arm64 myapp

# Use platform-specific optimizations
docker buildx build --platform linux/amd64 --build-arg GOARCH=amd64 -t myapp .
```

---

## 🆘 Emergency Troubleshooting

### Universal Commands
```bash
# Reset Docker completely (nuclear option)
docker system prune -a --volumes
docker builder prune -a

# Check Docker daemon
docker version
docker system info

# Resource cleanup
docker container prune
docker image prune
docker volume prune
docker network prune
```

### Platform-Specific Resets
```bash
# Linux: Restart Docker service
sudo systemctl restart docker

# macOS/Windows: Restart Docker Desktop
# Or reset to factory defaults through GUI

# WSL2: Restart WSL
wsl --shutdown
# Start Docker Desktop again
```

---

💡 **Pro Tip**: When reporting issues, always include your platform information:
```bash
docker version
docker system info | head -20
uname -a  # Linux/macOS
systeminfo | findstr /B /C:"OS Name"  # Windows
```