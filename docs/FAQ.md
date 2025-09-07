# Frequently Asked Questions (FAQ)

## General Questions

### Q: How long will it take to complete this course?
**A:** The full curriculum is designed for approximately 30-40 focused hours of learning. This includes:
- Reading and understanding concepts
- Completing hands-on labs
- Running verification tests
- Reviewing production notes

Most learners complete 1-2 phases per week with consistent practice.

### Q: What prerequisites do I need?
**A:** 
- Basic command-line familiarity (cd, ls, mkdir)
- Text editor usage
- Docker installed on your system
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space

### Q: Which Docker version should I use?
**A:** Docker 20.10+ is required. Latest stable version recommended. Check with:
```bash
docker --version
```

## Platform-Specific Questions

### Q: Can I use Docker Desktop on Windows?
**A:** Yes, Docker Desktop works on Windows 10/11 Pro, Enterprise, or Education (64-bit). For Windows Home, use WSL2 backend.

### Q: What about macOS with Apple Silicon?
**A:** Docker Desktop fully supports Apple Silicon (M1/M2/M3). Some images may require Rosetta 2 emulation.

### Q: Should I use Docker Desktop or Docker Engine on Linux?
**A:** Either works. Docker Engine is lighter weight; Docker Desktop provides GUI and additional tools.

### Q: How do I handle line ending issues on Windows?
**A:** Configure Git to use LF endings:
```bash
git config --global core.autocrlf input
```
The repository includes `.gitattributes` to enforce consistent line endings.

## Learning Path Questions

### Q: Can I skip phases?
**A:** Not recommended. Each phase builds on previous concepts. However, if you have prior Docker experience, review the learning objectives to assess your knowledge.

### Q: What if I get stuck on a lab?
**A:** 
1. Check the `verify.rules.md` for success criteria
2. Review the pitfalls section
3. Consult platform-specific notes
4. Check existing issues on GitHub
5. Open a new issue with details

### Q: How do I track my progress?
**A:** Progress is tracked via:
- `/docs/PROGRESS.json` - manual tracking
- Progress anchors (e.g., `p04-m01-l02`)
- Phase completion badges
- Git commits showing completed work

### Q: Are solutions provided?
**A:** Key concepts are demonstrated, but exact solutions are intentionally omitted to encourage learning through exploration. The `/solutions` directory may contain reference implementations for complex scenarios.

## Technical Questions

### Q: Why are my containers not accessible from the host?
**A:** Check:
- Port publishing (`-p` flag or `ports:` in Compose)
- Firewall rules
- Network mode (bridge vs host)
- Container health status

### Q: How do I clean up after labs?
**A:** Each phase includes `cleanup.rules.md`. Generally:
```bash
docker system prune -a --volumes  # WARNING: Removes all unused resources
```

### Q: Why is my build not using cache?
**A:** Common causes:
- Changed files in build context
- Modified Dockerfile instructions
- Different build arguments
- Cache explicitly disabled

### Q: How do I debug container startup failures?
**A:** 
```bash
docker logs <container-name>
docker inspect <container-name>
docker run -it <image> /bin/sh  # Interactive debug
```

## Best Practices Questions

### Q: Should I use latest tags in production?
**A:** No. Always pin specific versions or digests for reproducibility:
```dockerfile
# Bad
FROM node:latest

# Good
FROM node:18.19.0

# Better
FROM node:18.19.0@sha256:abc123...
```

### Q: When should I use multi-stage builds?
**A:** Use multi-stage builds to:
- Reduce final image size
- Separate build and runtime dependencies
- Improve build cache efficiency
- Enhance security by excluding build tools

### Q: How many layers should my image have?
**A:** Optimize for:
- Logical grouping of changes
- Cache efficiency
- Final size
- Generally 10-20 layers is reasonable

### Q: Should I run containers as root?
**A:** No. Always use non-root users when possible:
```dockerfile
USER node:node  # Switch to non-root user
```

## Troubleshooting Questions

### Q: Docker commands hang on Windows
**A:** 
- Restart Docker Desktop
- Check WSL2 integration
- Verify Hyper-V is enabled
- Check antivirus exclusions

### Q: "No space left on device" errors
**A:** 
```bash
docker system df  # Check disk usage
docker system prune -a  # Clean up
```

### Q: Network timeouts during builds
**A:** 
- Check proxy settings
- Verify DNS configuration
- Use build-time network diagnostics
- Consider registry mirrors

### Q: Permission denied errors
**A:** 
- Linux: Add user to docker group
- Windows: Run as Administrator
- Check file ownership in volumes
- Verify SELinux/AppArmor policies

## Contributing Questions

### Q: How can I contribute to this course?
**A:** 
- Report issues with clear reproduction steps
- Suggest improvements via discussions
- Submit PRs following CLAUDE.md guidelines
- Create visual diagrams
- Share your learning experience

### Q: What's the authorship policy?
**A:** See `/CLAUDE.md` for details. Key points:
- Single author per PR
- No co-authorship credits
- Human authorship required
- Tools assist but don't author

### Q: How are visual diagrams created?
**A:** 
- Mermaid for simple diagrams
- PNG exports for complex visuals
- Each phase has `visuals.md` planning file
- Alt-text required for accessibility

## Advanced Questions

### Q: How do I implement blue-green deployments with Docker?
**A:** This is beyond the course scope, but principles from Phase 04 (Networking) and Phase 06 (Compose) provide foundation. Consider container orchestrators for production deployments.

### Q: What about Kubernetes integration?
**A:** This course focuses on Docker fundamentals. Kubernetes orchestration is a separate learning path that builds on these concepts.

### Q: How do I optimize for ARM architectures?
**A:** Phase 08 covers multi-architecture builds using buildx. Key considerations:
- Base image availability
- Native vs emulated builds
- Testing on target architecture

---

> Can't find your question? Check existing [GitHub Issues](../issues) or open a new one with the `question` label.