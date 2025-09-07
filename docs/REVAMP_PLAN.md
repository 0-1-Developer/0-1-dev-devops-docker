# 0-1-dev-devops-docker — End‑to‑End Learning Plan (Revamp v4)

> Goal: Transform this repo into an engaging, hands‑on path from **zero → very advanced Docker**. **No code in this document**—only rules, directions, checklists, and lesson outlines. Code will be created later via phase PRs authored **only by you**; tools follow `/CLAUDE.md` but are **not** co‑authors.

---

## 0) Operating Model (Persistence, DR, Authorship, PR Flow)

### 0.1 Canonical Sources (so we never lose the plan)

* Store this file at **`/docs/REVAMP_PLAN.md`** and link from root `README.md`.
* Add **`/CLAUDE.md`** with tool guardrails, scope boundaries, authorship rules.
* Maintain **`/docs/CHANGELOG.md`** (curriculum changes per PR) and **`/docs/FAQ.md`** (common learner questions).
* Add **`/docs/GLOSSARY.md`** (Docker terms; concise definitions; cross‑links to phases).

### 0.2 Progress & Disaster Recovery

* Single source of truth: **`/docs/PROGRESS.json`** with `{ phase, module, lesson, status, updated_at, notes }`.
* Each lesson has a unique **Progress Anchor** `p{phase}-m{module}-l{lesson}` (e.g., `p06-m01-l02`).
* Nightly CI emits **`last_green.json`** (all anchors that passed verification in the last green run) as an artifact.
* Root **Roadmap badges** display phase completion using anchors.

### 0.3 Authorship Policy (strict)

* **Every PR authored by you alone.**
* **No co‑authors** (humans or tools). PR template includes:

  * `- [ ] Confirmed: I am the sole author of this PR.`
  * `- [ ] No co‑author trailers in commit messages.`

### 0.4 PR Strategy, Naming & Templates

* **One PR per Phase** (or per large module). Merge sequentially.
* Branch naming: `revamp/p{phase}-{slug}` (e.g., `revamp/p04-networking`).
* PR title: `Revamp: Phase {phase} — {short topic}`.
* PR template sections:

  1. Scope (phase/modules/anchors)
  2. Learning Objectives
  3. Micro‑lessons (names + anchors)
  4. Hands‑on (names + anchors)
  5. Verify Rules (assertions only)
  6. Windows/WSL2 Notes
  7. Visuals to include
  8. Out‑of‑scope / Deferred
  9. **Authorship Confirmation** (checkboxes above)

### 0.5 Lesson Style & Engagement Rules

* Keep text **scannable**: bullets > paragraphs; short, active sentences.
* Each **lesson** follows **exactly** this template:

  * **Why it matters**
  * **What to learn** (bullet list of concepts)
  * **Try it** (hands‑on outline; 5–10 min)
  * **Verify it** (assertions; what success looks like)
  * **Pitfalls** (3–5 sharp bullets)
  * **Production note** (how this impacts real systems)
  * **Visual cue** (diagram intent + alt‑text)
* **Micro‑lessons**: 2–5 minutes; 1 idea only; end with a single ready‑to‑apply rule.
* **Hands‑on**: single command to start; single command to stop; clear cleanup; no external accounts unless stated.

### 0.6 Windows/WSL2 & Platform Notes (applies across phases)

* Provide explicit callouts when behavior differs (paths, permissions, line endings, host networking).
* Enforce repo‑wide `.gitattributes` for line endings; centralize OS‑specific gotchas in **`/docs/platform-notes.md`** and link from lessons.

---

## 1) Target Repo Layout (Post‑Revamp)

```
/00-foundations/
/01-dockerfile-basics/
/02-buildkit-advanced/
/03-container-operations/
/04-networking/
/05-storage/
/06-compose/
/07-security/
/08-ci-cd-buildx/
/09-registries/
/10-observability/
/11-advanced-images/
/labs/
/solutions/            # optional
/scripts/
/docs/
/.github/workflows/
Makefile
```

**Per‑folder policy:** must contain `README.md` (concept map), `lab.md` (hands‑on outline), `verify.rules.md` (assertions), `cleanup.rules.md` (what to remove), `visuals.md` (diagram plan). **No code** here.

---

## 2) Global Onboarding (Root README expectations)

* What you'll learn; estimated effort (~30–40 focused hours).
* Platform matrix: Linux/macOS/Windows/WSL2 quick chart.
* **"5‑minute tour"** (described only): a tiny stack, a verify pass, and a cleanup.
* How to track progress with **anchors** and **`PROGRESS.json`**.
* How badges are earned; how visuals are organized.

---

## 3) Phase‑by‑Phase Curriculum (Rules, Directions, Topics)

> For every phase: **Outcomes ▸ Topics ▸ Micro‑lessons ▸ Hands‑on (outline) ▸ Verify Rules ▸ Visuals ▸ Pitfalls ▸ Production Note ▸ Windows/WSL2 Notes**.

### Phase 00 — Foundations

**Outcomes**

* Explain image vs container; tag vs digest; container lifecycle and resource mapping.

**Topics**

* Layered filesystems; immutability; image references.
* Lifecycle states (create/start/stop/rm) and idempotence.
* Host↔container boundaries: ports, CPUs, memory, filesystem (conceptual only).

**Micro‑lessons**

1. Image reference anatomy (registry/repo/tag/digest).
2. Lifecycle ordering game (cards to timeline).
3. Resource mapping sketch for a toy service.
4. Tags vs digests (when to use which).

**Hands‑on (outline)**

* Start a simple service; publish a port; stop and remove; capture a resource map.

**Verify Rules**

* Service reachable via published port.
* Mandatory metadata present (labels/env, conceptually stated).
* Resource map written in lesson notes.

**Visuals**

* Layer cake; lifecycle swimlane; host↔container port diagram.

**Pitfalls**

* Treating tags as immutable; confusing container IP with host.

**Production Note**

* Prefer digest pinning for reproducibility.

**Windows/WSL2 Notes**

* CRLF vs LF; path expectations; Docker Desktop vs Engine on WSL2.

---

### Phase 01 — Dockerfile Basics

**Outcomes**

* Choose base images; understand caching; use `.dockerignore`; correctly apply `CMD` vs `ENTRYPOINT`.

**Topics**

* Directives: FROM, WORKDIR, RUN, COPY/ADD, ENV, EXPOSE, CMD, ENTRYPOINT.
* Cache invalidation patterns; deterministic builds; context hygiene.

**Micro‑lessons**

1. Directive→purpose flashcards.
2. Cache‑bust scenarios (predict which step rebuilds).
3. Context scoping (what must never enter the build context).
4. `CMD` vs `ENTRYPOINT` decision tree.

**Hands‑on (outline)**

* Design a minimal Dockerfile for static content; compare single‑layer vs layered strategies.

**Verify Rules**

* Only intended files are in the image; base pinned; size target documented.

**Visuals**

* Cache tree; context before/after.

**Pitfalls**

* Context bloat; leaking credentials; misusing `ADD`.

**Production Note**

* Apply build labels (build time, VCS revision, source URL).

**Windows/WSL2 Notes**

* LF endings in Dockerfiles; glob patterns parity.

---

### Phase 02 — BuildKit Advanced

**Outcomes**

* Use multi‑stage builds; cache mounts; safe build secrets; build args; understand Bake graphs conceptually.

**Topics**

* Builder→runtime staging; target selection.
* `cache` mounts for dependency managers; avoiding cache leakage.
* Build secrets vs runtime secrets; zero‑leakage policy.
* Build args; parameterized targets; Bake mental model.

**Micro‑lessons**

1. Runtime vs builder contents (what belongs where).
2. Secret lifecycle map (where secrets may reside during build).
3. Cache strategies that shave minutes.
4. Naming conventions for stages and targets.

**Hands‑on (outline)**

* Convert single‑stage→multi‑stage; add cache; introduce a one‑time secret safely.

**Verify Rules**

* No secrets in final image; faster build than baseline; conventional stage names present.

**Visuals**

* Multi‑stage conveyor; secret lifecycle diagram.

**Pitfalls**

* Toolchain leakage; ARG persistence confusion.

**Production Note**

* CI with cache‑to/from; predictable Bake targets.

**Windows/WSL2 Notes**

* Path case/timestamp caveats.

---

### Phase 03 — Container Operations

**Outcomes**

* Apply health checks, restart policies, resource limits; reason about logs/metrics/events; handle graceful shutdown.

**Topics**

* Health semantics (initial delay, interval, timeout, retries, start‑period).
* Restart taxonomy; flapping prevention; backoff thinking.
* CPU/memory limits; ulimits concept; termination signals.

**Micro‑lessons**

1. Design a resilient health probe.
2. Choose restart policy per failure mode.
3. Budget CPU/mem per service profile.
4. SIGTERM→graceful stop expectations.

**Hands‑on (outline)**

* Add health; set limits; simulate crash; observe restarts; capture shutdown timeline.

**Verify Rules**

* Health becomes `healthy` within a window; no restart flapping; limits visible by inspection.

**Visuals**

* Health timeline; restart state machine.

**Pitfalls**

* Over‑eager probes; missing signal handling.

**Production Note**

* Gate rollout on health; favor gradual restarts.

**Windows/WSL2 Notes**

* Time and DNS quirks; Desktop log locations.

---

### Phase 04 — Networking

**Outcomes**

* Design internal networks; service discovery by name; isolate tiers; compare host vs bridge vs user‑defined networks.

**Topics**

* Default bridge vs user‑defined; embedded DNS; name resolution rules.
* Public edge vs private app/data; egress patterns and restrictions.
* Host networking trade‑offs and constraints.

**Micro‑lessons**

1. Choose network type per use case.
2. Name‑resolution quiz (who can reach whom?).
3. Public/private topology draft.
4. Expose vs publish conceptual distinction.

**Hands‑on (outline)**

* Two services on a user network; add gateway; validate private isolation.

**Verify Rules**

* Internal DNS works; private components are unreachable from public network.

**Visuals**

* Dual‑network topology; DNS lookup flow.

**Pitfalls**

* Expecting static IPs; over‑publishing ports.

**Production Note**

* Network segmentation to limit blast radius.

**Windows/WSL2 Notes**

* Published port behavior; `host.docker.internal` nuances.

---

### Phase 05 — Storage & Volumes

**Outcomes**

* Select bind vs named volumes; design backup/restore; handle permissions; leverage tmpfs for ephemeral paths.

**Topics**

* Mount types and performance implications by OS.
* Database storage rules; restoration as a first‑class test.
* UID/GID mapping; SELinux/AppArmor considerations.

**Micro‑lessons**

1. Mount decision matrix (bind/named/tmpfs).
2. Backup/restore rehearsal plan.
3. Ownership mapping checklist.
4. Avoiding "bind DB dir on Desktop" antipattern.

**Hands‑on (outline)**

* DB with named volume; backup; restore to new instance; verify continuity.

**Verify Rules**

* Data persists across replacement; backup artifact valid; no host path leakage on non‑Linux.

**Visuals**

* App↔volume↔backup flow; restore chain.

**Pitfalls**

* Ownership mismatch; performance traps.

**Production Note**

* Schedule restores; test disasters quarterly.

**Windows/WSL2 Notes**

* NTFS mapping; case sensitivity; performance expectations.

---

### Phase 06 — Compose

**Outcomes**

* Model a multi‑service stack; use profiles for envs; secrets/env files; readiness via health.

**Topics**

* Services, networks, volumes; profiles (`dev/test/prod`).
* `depends_on` vs readiness; health‑gating.
* Secrets & env‑file boundaries.

**Micro‑lessons**

1. Per‑profile diffs (hot reload vs read‑only root).
2. Readiness truth table.
3. Secret placement checklist.
4. Compose anti‑patterns to avoid.

**Hands‑on (outline)**

* One stack, three profiles: dev/test/prod, each with distinct acceptance criteria.

**Verify Rules**

* Each profile meets criteria; readiness is health‑based, not order‑only.

**Visuals**

* Profile topology overlays.

**Pitfalls**

* Assuming `depends_on` implies ready; leaking secrets via env files.

**Production Note**

* Single‑command bring‑up to reduce drift.

**Windows/WSL2 Notes**

* Hot‑reload file‑watching; path mapping.

---

### Phase 07 — Security

**Outcomes**

* Minimize attack surface: non‑root, caps, read‑only root, profiles; understand scanning & policy exceptions.

**Topics**

* Non‑root strategy; writable dirs; tmpfs mounts.
* Capabilities: drop by default; add back least‑privilege.
* Seccomp/AppArmor (conceptual); rootless Docker posture.
* Image scanning; severity gates; time‑bound allow‑lists.

**Micro‑lessons**

1. Identify necessary write paths.
2. Decide caps to drop/keep for a sample service.
3. Define a CVE severity gate & exception lifecycle.
4. Rootless Docker: when it helps.

**Hands‑on (outline)**

* Harden a sample app: user switch, read‑only root, cap drop; conceptual scan step.

**Verify Rules**

* Non‑root confirmed; read‑only root; minimal caps; scan results within threshold.

**Visuals**

* Defense‑in‑depth onion; capability reduction chart.

**Pitfalls**

* Forgetting tmpfs for writable paths; blanket allow‑lists.

**Production Note**

* Keep a documented `-debug` variant for on‑call.

**Windows/WSL2 Notes**

* Desktop security feature parity caveats.

---

### Phase 08 — CI/CD & Buildx

**Outcomes**

* Reproducible builds; cache to/from; publish multi‑arch; attach SBOM; CI validates labs (conceptually).

**Topics**

* Buildx builders; emulation trade‑offs; cache strategies.
* Registry auth basics; provenance; release management.
* SBOM generation/storage; comparing SBOMs over time.

**Micro‑lessons**

1. Cache key strategy.
2. CI matrix (OS/arch/labs) selection.
3. Release checklist & artifact inventory.
4. Attestation and provenance basics (conceptual).

**Hands‑on (outline)**

* CI performs builds, scans, (optionally) publishes, and stores SBOM artifacts.

**Verify Rules**

* Warm cache improves build time; multi‑arch manifest exists; SBOM stored.

**Visuals**

* CI swimlane with gates; artifact flow.

**Pitfalls**

* Emulation slowness; cold caches.

**Production Note**

* Publish only from protected branches/tags.

**Windows/WSL2 Notes**

* Runner limitations; path normalization.

---

### Phase 09 — Registries

**Outcomes**

* Operate a local registry; proxy cache; auth flows; rate limits; mirrors.

**Topics**

* Local vs remote registries; mirror decisions; reliability/latency benefits.
* Auth flows; credential rotation; trust boundaries and risk notes.

**Micro‑lessons**

1. Mirror decision tree.
2. Human vs machine auth flows.
3. Degradation fallback plan.
4. Tag retention & cleanup policy sketch.

**Hands‑on (outline)**

* Local registry round‑trip; proxy cache configuration; validate cache hits.

**Verify Rules**

* Push/pull success; cache hit observed; auth scoped correctly.

**Visuals**

* Client↔mirror↔upstream diagram.

**Pitfalls**

* Insecure HTTP registries; stale layers in cache.

**Production Note**

* State trust boundaries & rotation cadence.

**Windows/WSL2 Notes**

* Certificates; Desktop registry settings.

---

### Phase 10 — Observability

**Outcomes**

* Choose logging drivers; surface metrics; analyze images (size/layers); enforce budgets.

**Topics**

* Logs vs events; driver trade‑offs; centralization strategies (conceptual).
* Metrics: CPU/mem/restarts/health; SLO sketching; alerting principles.
* Image analysis: budgets; regression prevention.

**Micro‑lessons**

1. Logging strategy per workload.
2. Healthy ranges and alerts (CPU, mem, restarts, health fail rates).
3. Image budget + exception policy.
4. Avoid double shipping; control volumes.

**Hands‑on (outline)**

* Bring up monitored mini‑stack; inspect metrics; define budgets.

**Verify Rules**

* Metrics accessible; size under budget; regressions conceptually flagged.

**Visuals**

* Minimal dashboard mock; layer chart.

**Pitfalls**

* Noisy logs; unbounded storage.

**Production Note**

* Add image budgets to CI checks.

**Windows/WSL2 Notes**

* Log path differences; Desktop metrics availability.

---

### Phase 11 — Advanced Images

**Outcomes**

* Use distroless/scratch; weigh static linking; minimize CVE surface without losing debuggability.

**Topics**

* Distroless vs scratch; interface expectations (no shell); when to avoid.
* Static vs dynamic linking; size and security trade‑offs.
* Debug strategy for minimal images.

**Micro‑lessons**

1. Base strategy per language/runtime.
2. Debug plan for minimal images.
3. CVE surface comparison across bases.
4. Pairing minimal and debug variants.

**Hands‑on (outline)**

* Convert a service to distroless/scratch; keep a documented debug counterpart.

**Verify Rules**

* Minimal image runs; debug image available; CVE count reduced vs baseline.

**Visuals**

* Dependency onion; minimal vs debug side‑by‑side.

**Pitfalls**

* No shell/tools for hotfixing; opaque error paths.

**Production Note**

* Maintain slim + debug pairs catalog.

**Windows/WSL2 Notes**

* Execution/path constraints; debugging without shell.

---

## 4) Cross‑Cutting Systems

### 4.1 Visuals Kit

* Every `visuals.md` must specify: **Title • Purpose • Rough sketch • Type (Mermaid/PNG) • Placement • Alt‑text**.
* Prefer **single‑idea** diagrams over large composites.

### 4.2 Badges & Motivation

* Per‑module PNG badge when all `verify.rules.md` assertions are satisfied.
* Maintain `/docs/badges/README.md` gallery.

### 4.3 Quality Bar (Definition of Done per Phase)

* `README.md`, `lab.md`, `verify.rules.md`, `cleanup.rules.md`, `visuals.md` complete.
* ≥ **3 micro‑lessons** with outcomes.
* At least **1 Production note** and **1 Pitfalls** section.
* Windows/WSL2 callouts where relevant.
* Anchors updated in `PROGRESS.json`.
* PR authorship confirmed (you only).

### 4.4 Contribution Kit

* Issue templates: **Phase PR**, **New Lesson**, **Visuals Request**.
* Labels: `phase:p00…p11`, `kind:lesson`, `kind:hands-on`, `kind:visual`, `curriculum`.
* Commit message convention (no trailers for co‑authors).

### 4.5 Learner Experience Enhancers

* **Micro‑quizzes** (single question) at the end of key lessons (stored as plain Q/A in lesson docs, no code).
* **Reflection prompts** ("What did you change in your mental model?") to deepen retention.
* **Checkpoint summaries** at phase ends (one page, scannable).

---

## 5) Execution Plan

### Step 1 — Revamp Scaffold PR

* Normalize directories; drop in this plan; add `/CLAUDE.md`, `/docs/PROGRESS.json`, `/docs/FAQ.md`, `/docs/GLOSSARY.md` (skeletons only).
* Add PR/Issue templates and labels; update root `README.md` to reference plan and roadmap.

### Step 2 — Migrate Existing Content

* Map `Phase - 1/2` assets into the new structure.
* Convert free‑form notes into: **micro‑lessons**, **pitfalls**, **production notes**, **visuals**.
* Track migrations and deprecations in a checklist issue.

### Step 3 — Phase PRs (sequential, small, complete slices)

* **Phase 00 PR → merge**
* **Phase 01 PR → merge**
* Proceed through **Phase 11**, keeping repo green.

### Step 4 — CI Gradualism (Concept only in this doc)

* Start with structural checks (presence of required files per module).
* Add lab verification gates later (implementation doc will live elsewhere).
* Nightly snapshot of `PROGRESS.json` → `last_green.json`.

---

## 6) Acceptance Criteria for "Revamp Complete"

* All **11 phases** have the required five files and meet the **Quality Bar**.
* Root README shows roadmap, anchors, badges, and platform matrix.
* `PROGRESS.json` + `last_green.json` provide session continuity.
* Authorship policy consistently enforced; no co‑authors appear in history.

> **Next Action:** Open **Revamp‑Scaffold** PR implementing **Step 1**. Then go phase‑by‑phase with focused PRs, maintaining engagement, clarity, and hands‑on rigor throughout.