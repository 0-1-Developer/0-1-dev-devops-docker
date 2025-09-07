# Docker Glossary

## A

**ADD** — Dockerfile instruction that copies files/directories or URLs into the image. See [Phase 01](../01-dockerfile-basics).

**Alpine** — Minimal Linux distribution (~5MB) commonly used as base image. Security-focused, uses musl libc.

**Anchor** — Progress tracking identifier in format `p{phase}-m{module}-l{lesson}`. See [PROGRESS.json](./PROGRESS.json).

**ARG** — Build-time variable in Dockerfile. Not persisted in final image unless used in ENV. See [Phase 02](../02-buildkit-advanced).

**Artifact** — Output from build process (image, SBOM, attestation). See [Phase 08](../08-ci-cd-buildx).

## B

**Base Image** — Starting point for Dockerfile specified by FROM instruction. See [Phase 01](../01-dockerfile-basics).

**Bind Mount** — Host directory mounted into container. Changes reflected bidirectionally. See [Phase 05](../05-storage-volumes).

**Bridge Network** — Default network driver providing isolated network namespace. See [Phase 04](../04-networking).

**Build Context** — Directory sent to Docker daemon during build. Controlled by .dockerignore. See [Phase 01](../01-dockerfile-basics).

**BuildKit** — Modern Docker build backend with advanced features (cache mounts, secrets, parallel builds). See [Phase 02](../02-buildkit-advanced).

**Buildx** — Docker CLI plugin for extended build capabilities including multi-platform builds. See [Phase 08](../08-ci-cd-buildx).

## C

**Cache** — Reusable layers from previous builds to speed up subsequent builds. See [Phase 01](../01-dockerfile-basics).

**Capability** — Linux kernel privilege that can be granted/dropped from containers. See [Phase 07](../07-security).

**CMD** — Default command executed when container starts. Overridable at runtime. See [Phase 01](../01-dockerfile-basics).

**Compose** — Tool for defining multi-container applications using YAML. See [Phase 06](../06-compose).

**Container** — Running instance of an image with isolated process, network, and filesystem. See [Phase 00](../00-foundations).

**Container ID** — Unique 64-character hex string identifying a container. Short form uses first 12 characters.

**COPY** — Dockerfile instruction for copying files from build context. Preferred over ADD. See [Phase 01](../01-dockerfile-basics).

## D

**Daemon** — Background service (dockerd) managing containers, images, networks, volumes.

**Dangling Image** — Image without repository:tag, usually from intermediate build stages.

**Digest** — SHA256 hash uniquely identifying specific image version. Immutable unlike tags. See [Phase 00](../00-foundations).

**Distroless** — Minimal images containing only application and runtime dependencies. No shell or package manager. See [Phase 11](../11-advanced-images).

**DNS** — Docker's embedded DNS server for service discovery within user-defined networks. See [Phase 04](../04-networking).

**Dockerfile** — Text file with instructions for building Docker image. See [Phase 01](../01-dockerfile-basics).

## E

**Entrypoint** — Command that always executes when container starts. Not easily overridden. See [Phase 01](../01-dockerfile-basics).

**ENV** — Environment variable set in Dockerfile, persisted in image. See [Phase 01](../01-dockerfile-basics).

**EXPOSE** — Documentation of ports the container listens on. Doesn't publish ports. See [Phase 01](../01-dockerfile-basics).

## F

**FROM** — First instruction in Dockerfile specifying base image. See [Phase 01](../01-dockerfile-basics).

## H

**Health Check** — Command to verify container is functioning correctly. Affects container state. See [Phase 03](../03-container-ops).

**Host Network** — Network mode where container uses host's network stack directly. See [Phase 04](../04-networking).

## I

**Image** — Read-only template for creating containers. Built from Dockerfile. See [Phase 00](../00-foundations).

**Image ID** — Unique SHA256 hash identifying an image.

## L

**Label** — Key-value metadata attached to images, containers, volumes, networks. See [Phase 01](../01-dockerfile-basics).

**Layer** — Read-only filesystem delta created by Dockerfile instruction. Stacked to form image. See [Phase 00](../00-foundations).

**Logging Driver** — Plugin determining how container logs are handled (json-file, syslog, etc.). See [Phase 10](../10-observability).

## M

**Manifest** — JSON document describing image layers, config, and platform variants. See [Phase 08](../08-ci-cd-buildx).

**Mount** — Mechanism for accessing host or volume filesystem from container. See [Phase 05](../05-storage-volumes).

**Multi-stage Build** — Dockerfile pattern using multiple FROM statements to optimize final image size. See [Phase 02](../02-buildkit-advanced).

## N

**Named Volume** — Docker-managed storage with lifecycle independent of containers. See [Phase 05](../05-storage-volumes).

**Namespace** — Linux kernel feature providing process isolation (PID, network, mount, etc.).

**Network** — Virtual network for container communication. Types: bridge, host, overlay, macvlan. See [Phase 04](../04-networking).

## O

**OCI** — Open Container Initiative. Standards for container format and runtime.

**Overlay** — Union filesystem enabling layered image storage.

## P

**Port Publishing** — Mapping container port to host port for external access. `-p HOST:CONTAINER`. See [Phase 04](../04-networking).

**Profile** — Compose feature for conditional service inclusion based on environment. See [Phase 06](../06-compose).

**Prune** — Remove unused resources (containers, images, networks, volumes).

## R

**Registry** — Server storing and distributing Docker images. Docker Hub is default public registry. See [Phase 09](../09-registries).

**Repository** — Collection of related images identified by name, containing multiple tags/versions.

**Restart Policy** — Configuration determining container behavior after exit (no, always, unless-stopped, on-failure). See [Phase 03](../03-container-ops).

**Rootless** — Running Docker daemon and containers without root privileges. See [Phase 07](../07-security).

**RUN** — Dockerfile instruction executing commands during build, creating new layer. See [Phase 01](../01-dockerfile-basics).

## S

**SBOM** — Software Bill of Materials. Inventory of components in an image. See [Phase 08](../08-ci-cd-buildx).

**Scratch** — Empty base image for statically compiled binaries. Ultimate minimal image. See [Phase 11](../11-advanced-images).

**Secret** — Sensitive data (passwords, tokens) requiring special handling. See [Phase 02](../02-buildkit-advanced) and [Phase 06](../06-compose).

**Service** — In Compose, a container configuration that can be scaled. See [Phase 06](../06-compose).

**Stage** — Named FROM instruction in multi-stage build. See [Phase 02](../02-buildkit-advanced).

**Swarm** — Docker's native clustering and orchestration solution (not covered in this course).

## T

**Tag** — Human-readable image version identifier (e.g., `nginx:1.21`). Mutable unlike digest. See [Phase 00](../00-foundations).

**Tmpfs** — Temporary filesystem mount stored in memory, not persisted. See [Phase 05](../05-storage-volumes).

## U

**Union Filesystem** — Filesystem service layering multiple directories into single view.

**USER** — Dockerfile instruction setting user/group for subsequent instructions and runtime. See [Phase 07](../07-security).

## V

**Volume** — Persistent data storage mechanism managed by Docker. See [Phase 05](../05-storage-volumes).

**Volume Driver** — Plugin providing volume functionality (local, nfs, etc.).

## W

**WORKDIR** — Dockerfile instruction setting working directory for subsequent instructions. See [Phase 01](../01-dockerfile-basics).

---

## Special Terms

**Builder Pattern** — Two-Dockerfile approach predating multi-stage builds. Now obsolete.

**Container Runtime** — Low-level component executing containers (runc, containerd).

**Dangling Volume** — Volume not referenced by any container.

**Docker-in-Docker (DinD)** — Running Docker daemon inside container. Complex security implications.

**Garbage Collection** — Automatic removal of unused resources. See `docker system prune`.

**Init Process** — PID 1 process in container responsible for signal handling and zombie reaping.

**Layer Caching** — Reusing unchanged layers from previous builds to improve performance.

**Moby** — Open-source project Docker is based on.

**Overlay Network** — Multi-host network for Swarm services (not covered).

**Podman** — Alternative container engine with Docker-compatible CLI.

**Shim** — Process managing container lifecycle after daemon restart.

**Socket** — Unix socket (`/var/run/docker.sock`) or TCP endpoint for Docker API communication.

**Squash** — Experimental feature combining image layers into single layer.

**Storage Driver** — Backend for image and container filesystem (overlay2, devicemapper, etc.).

---

> Terms are linked to their primary phase of introduction. For detailed explanations, refer to the specific phase documentation.