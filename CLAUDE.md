# CLAUDE.md — Tool Guardrails & Authorship Policy

## Authorship Rules (STRICT)

### Core Policy
* **Every PR must be authored by a human developer alone**
* **NO co-authorship** from tools, AI assistants, or other humans
* Tools may assist with research, suggestions, and planning but CANNOT be credited as co-authors
* Commit messages must NOT include co-author trailers

### PR Requirements
Every PR must include these confirmations:
- [ ] Confirmed: I am the sole author of this PR
- [ ] No co-author trailers in commit messages
- [ ] All code was written by me personally

## Tool Usage Guidelines

### Permitted Tool Usage
* Research and information gathering
* Syntax checking and linting
* Test execution and validation
* Build automation
* Documentation generation from code
* Dependency management

### Prohibited Tool Usage
* Direct code generation that gets committed without human authorship
* Automated PR creation
* Co-authorship credits in any form
* Bulk code transformations without human review and ownership

## Scope Boundaries

### In Scope
* Docker fundamentals to advanced concepts
* Container orchestration basics
* CI/CD integration patterns
* Security best practices
* Performance optimization
* Multi-platform considerations (Linux/macOS/Windows/WSL2)

### Out of Scope
* Kubernetes orchestration (beyond basic concepts)
* Cloud-specific implementations (AWS ECS, Azure ACI, GCP Cloud Run)
* Proprietary tooling
* Non-containerization topics

## Quality Standards

### Code Quality
* All examples must be tested and working
* Follow Docker best practices
* Include appropriate error handling
* Maintain consistent style across phases

### Documentation Quality
* Clear, scannable format (bullets > paragraphs)
* Practical, hands-on focus
* Platform-specific notes where needed
* Production-ready considerations

## Verification Requirements

### Per Phase
* All 5 required files present (README.md, lab.md, verify.rules.md, cleanup.rules.md, visuals.md)
* Minimum 3 micro-lessons with clear outcomes
* At least 1 production note and 1 pitfalls section
* Windows/WSL2 callouts where behavior differs
* Progress anchors updated in PROGRESS.json

### Testing
* All labs must be reproducible
* Verify rules must be automatable
* Cleanup must restore original state
* Cross-platform compatibility verified

## Commit Guidelines

### Message Format
```
<type>: <subject>

<body>

<footer>
```

### Types
* feat: New feature or phase
* fix: Bug fix or correction
* docs: Documentation only
* refactor: Code restructuring
* test: Test additions or fixes
* chore: Maintenance tasks

### Rules
* Subject line max 50 characters
* Body wrapped at 72 characters
* NO co-author trailers
* Reference issues/PRs where applicable

## PR Workflow

### Branch Naming
* Format: `revamp/p{phase}-{slug}`
* Example: `revamp/p04-networking`

### PR Titles
* Format: `Revamp: Phase {phase} — {short topic}`
* Example: `Revamp: Phase 04 — Networking`

### Review Checklist
- [ ] Follows lesson template exactly
- [ ] Includes all required files
- [ ] Platform notes included
- [ ] Visuals planned/included
- [ ] No code in planning documents
- [ ] Authorship confirmed
- [ ] Progress anchors updated

## Emergency Procedures

### Content Loss Prevention
* PROGRESS.json is source of truth
* Nightly CI captures last_green.json
* All plans stored in /docs
* Regular git commits during work

### Recovery Steps
1. Check PROGRESS.json for last known state
2. Review last_green.json from CI
3. Consult REVAMP_PLAN.md for requirements
4. Resume from last completed anchor

## Contact & Support

### Issue Types
* Bug Report: For errors in labs or documentation
* Feature Request: For curriculum suggestions
* Question: For clarification on content
* Visual Request: For diagram needs

### Labels
* `phase:p00` through `phase:p11`
* `kind:lesson`
* `kind:hands-on`
* `kind:visual`
* `curriculum`
* `bug`
* `enhancement`
* `question`

---

> This document governs all development on the Docker learning path. Adherence to these guidelines ensures consistency, quality, and proper attribution throughout the curriculum.