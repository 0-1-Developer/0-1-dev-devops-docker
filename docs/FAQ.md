# Frequently Asked Questions

> **Purpose**: Address common questions from learners progressing through the Docker learning path  
> **Scope**: Practical answers to real challenges encountered during hands-on exercises

## 🎯 Getting Started

### Q: What experience level is required to start this learning path?
**A:** Basic command-line familiarity is helpful but not required. The path starts from absolute beginner concepts and builds systematically. You should be comfortable:
- Opening a terminal/command prompt
- Running basic commands
- Editing text files
- Following step-by-step instructions

### Q: How long does it take to complete the entire learning path?
**A:** Plan for **30-40 focused hours** spread across several weeks:
- **Phases 00-03**: 8-10 hours (foundations)
- **Phases 04-07**: 12-15 hours (core skills)
- **Phases 08-11**: 15-20 hours (advanced topics)

Most learners complete 1-2 phases per week with consistent daily practice.

### Q: Can I skip phases if I already know some Docker concepts?
**A:** While possible, we recommend following the progression because:
- Each phase builds on previous concepts with specific terminology
- Later phases reference patterns from earlier ones
- The verification system ensures consistent knowledge gaps are filled
- You can move quickly through familiar content

Use the **Progress Anchors** in `PROGRESS.json` to track what you've mastered.

### Q: Which Docker version should I use?
**A:** Minimum requirements:
- **Docker Engine**: 20.10+ (for BuildKit features)
- **Docker Compose**: 2.0+ (for modern compose syntax)
- **BuildKit**: Enabled by default in recent versions

Use `docker version` and `docker compose version` to check. Update if needed.

## 🛠️ Platform and Setup

### Q: Which platforms are supported?
**A:** All major platforms with platform-specific guidance:
- **Linux**: Native Docker Engine (recommended)
- **macOS**: Docker Desktop with native performance
- **Windows**: Docker Desktop with WSL2 backend
- **WSL2**: Native Linux Docker inside Windows

Check `/docs/platform-notes.md` for OS-specific gotchas and optimizations.

### Q: Do I need Docker Desktop or can I use Docker Engine?
**A:** Either works:
- **Docker Desktop**: Easier setup, GUI management, integrated tools
- **Docker Engine**: Lightweight, command-line only, better performance on Linux
- **Recommendation**: Desktop for beginners, Engine for production-like experience

### Q: Can I use Docker Desktop on Windows?
**A:** Yes, Docker Desktop works on Windows 10/11 Pro, Enterprise, or Education (64-bit). For Windows Home, use WSL2 backend.

### Q: What about macOS with Apple Silicon?
**A:** Docker Desktop fully supports Apple Silicon (M1/M2/M3). Some images may require Rosetta 2 emulation.

### Q: Can I run this on a cloud instance instead of locally?
**A:** Yes! Cloud instances often provide better performance:
- **AWS EC2**: t3.medium or larger with Amazon Linux 2
- **Azure VM**: B2s or larger with Ubuntu 20.04+
- **Google Compute**: e2-medium or larger with Container-Optimized OS
- **DigitalOcean Droplet**: 2GB RAM minimum with Ubuntu

Ensure your cloud firewall allows the ports used in exercises.

### Q: How do I handle line ending issues on Windows?
**A:** Configure Git to use LF endings:
```bash
git config --global core.autocrlf input
```
The repository includes `.gitattributes` to enforce consistent line endings.

## 📚 Learning Process

### Q: What are "Progress Anchors" and how do I use them?
**A:** Progress Anchors are unique identifiers (like `p04-m01-l02`) for each lesson that track your advancement:
- **Check progress**: Review `docs/PROGRESS.json`
- **Resume learning**: Find your last completed anchor
- **Verify completion**: Use anchor-based verification scripts
- **Share progress**: Reference specific anchors when asking for help

### Q: What are "micro-lessons" and why are they separate?
**A:** Micro-lessons are focused 2-5 minute modules that teach one specific concept:
- **Just-in-time learning**: Learn exactly what you need when you need it
- **Bite-sized chunks**: Easier to fit into busy schedules
- **Reinforcement**: Review key concepts without full phase repetition
- **Reference**: Quick lookup for specific techniques

### Q: How do I know if I'm ready to move to the next phase?
**A:** Each phase includes verification criteria in `verify.rules.md`:
1. **Complete all exercises**: Every hands-on activity working
2. **Pass verification scripts**: Automated checks confirm understanding  
3. **Answer reflection questions**: Demonstrate conceptual grasp
4. **Clean environment**: Successfully run cleanup procedures

Don't rush—solid foundations accelerate later learning.

### Q: What if I get stuck on an exercise?
**A:** Follow this troubleshooting sequence:
1. **Re-read instructions**: Often missed steps or typos
2. **Check platform notes**: OS-specific behavior differences
3. **Review pitfalls section**: Common mistakes and solutions
4. **Verify prerequisites**: Earlier phase concepts properly understood
5. **Ask for help**: Include your specific error message and Progress Anchor

### Q: Can I skip phases?
**A:** Not recommended. Each phase builds on previous concepts. However, if you have prior Docker experience, review the learning objectives to assess your knowledge.

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

## 🚀 Career and Next Steps

### Q: What jobs can I apply for after completing this learning path?
**A:** This curriculum prepares you for:
- **DevOps Engineer**: Container orchestration and automation
- **Platform Engineer**: Internal developer tooling and infrastructure
- **Cloud Engineer**: Container-based cloud architectures
- **Site Reliability Engineer**: Production container operations
- **Software Developer**: Modern application deployment patterns

### Q: What should I learn next after completing all phases?
**A:** Natural progressions:
- **Kubernetes**: Container orchestration at scale
- **Service Mesh**: Advanced microservices networking (Istio, Linkerd)
- **Observability**: Prometheus, Grafana, Jaeger deep dives
- **GitOps**: Automated deployment patterns with ArgoCD, Flux
- **Security**: Container security scanning, policy engines

### Q: How do I stay current with Docker and container technology?
**A:** Recommended resources:
- **Official Docker Blog**: Latest features and best practices
- **Cloud Native Computing Foundation**: Industry trends and projects
- **Container conferences**: DockerCon, KubeCon, Container Days
- **Hands-on practice**: Build side projects using new features
- **Community**: Docker Community Slack, Reddit r/docker

## 💡 Can't Find Your Question?

### Search Tips
- **Check glossary**: `/docs/GLOSSARY.md` for term definitions
- **Platform notes**: `/docs/platform-notes.md` for OS-specific issues
- **Phase-specific**: Each phase has its own pitfalls and troubleshooting
- **Progress tracking**: Use anchors to ask specific questions

### Getting Help
- **GitHub Issues**: Technical problems with exercises
- **Discussions**: General questions and learning advice
- **Community**: Docker Community Slack and forums

### Improving This FAQ
This FAQ grows based on actual learner questions. If you don't find your answer here, please:
1. **Ask your question** via GitHub issues or discussions
2. **Help others**: Answer questions you've solved
3. **Suggest improvements**: Propose FAQ additions or clarifications

---

*Last updated: 2025-01-09 | Contributing: Add questions via GitHub issues*