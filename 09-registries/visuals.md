# Phase 09 Visuals: Container Registries Architecture

> **Purpose**: Visual diagrams and architecture overviews for Docker registry implementations  
> **Scope**: Comprehensive visual guide covering registry topologies, authentication flows, and enterprise architectures

## 📊 Visual Learning Overview

This visual guide provides:
- Registry architecture diagrams
- Authentication and authorization flows
- Mirroring and caching topologies
- Enterprise registry deployments
- High availability configurations
- Security and compliance visualizations

---

## 🏗️ Basic Registry Architecture

```mermaid
graph TB
    subgraph "Docker Client Environment"
        CLI[Docker CLI]
        ENGINE[Docker Engine]
        CLI --> ENGINE
    end
    
    subgraph "Registry Infrastructure"
        LB[Load Balancer<br/>nginx/haproxy]
        REG[Docker Registry<br/>registry:2.8]
        STORAGE[(Storage Backend<br/>Filesystem/S3/GCS)]
        
        LB --> REG
        REG --> STORAGE
    end
    
    subgraph "Security Layer"
        AUTH[Auth Service<br/>htpasswd/JWT/LDAP]
        CERTS[SSL/TLS<br/>Certificates]
        
        REG --> AUTH
        LB --> CERTS
    end
    
    ENGINE -.->|"docker push/pull<br/>HTTPS:5000"| LB
    
    style REG fill:#e1f5fe
    style STORAGE fill:#f3e5f5
    style AUTH fill:#fff3e0
    style CERTS fill:#e8f5e8
```

### Registry Component Breakdown
- **Docker Registry**: Core registry service handling push/pull operations
- **Storage Backend**: Persistent storage for image layers and metadata
- **Authentication**: Security layer for user access control
- **Load Balancer**: SSL termination and traffic distribution

---

## 🔐 Authentication Flow Architecture

```mermaid
sequenceDiagram
    participant Client as Docker Client
    participant LB as Load Balancer
    participant Registry as Registry Service
    participant Auth as Auth Service
    participant Storage as Storage Backend
    
    Note over Client,Storage: Pull Request Authentication Flow
    
    Client->>+LB: GET /v2/myapp/manifests/latest
    LB->>+Registry: Forward request
    Registry->>-LB: 401 Unauthorized + WWW-Authenticate header
    LB->>-Client: 401 + Auth challenge
    
    Client->>+Auth: POST /auth/token (username/password)
    Auth->>Auth: Validate credentials
    Auth->>-Client: JWT Token
    
    Client->>+LB: GET /v2/myapp/manifests/latest + Authorization: Bearer <token>
    LB->>+Registry: Forward with token
    Registry->>Registry: Validate JWT token
    Registry->>+Storage: Retrieve manifest
    Storage->>-Registry: Manifest data
    Registry->>-LB: 200 OK + Manifest
    LB->>-Client: Manifest response
    
    Note over Client,Storage: Push Request Flow (Similar with scope validation)
    
    style Auth fill:#fff3e0
    style Registry fill:#e1f5fe
    style Storage fill:#f3e5f5
```

### Authentication Components
- **Bearer Token**: JWT-based authentication for registry access
- **Scope Validation**: Fine-grained permissions for push/pull operations
- **Token Service**: Centralized authentication and authorization
- **Credential Store**: User database (htpasswd, LDAP, OAuth2)

---

## 🪞 Registry Mirror and Cache Architecture

```mermaid
graph TB
    subgraph "Corporate Network"
        subgraph "Development Environment"
            DEV1[Developer 1<br/>Docker Client]
            DEV2[Developer 2<br/>Docker Client]
            DEV3[Developer 3<br/>Docker Client]
        end
        
        subgraph "Registry Mirror Infrastructure"
            MIRROR[Registry Mirror<br/>Pull-through Cache]
            CACHE[(Local Cache<br/>Storage)]
            
            MIRROR --> CACHE
        end
        
        subgraph "Monitoring"
            METRICS[Prometheus<br/>Metrics]
            GRAFANA[Grafana<br/>Dashboard]
            
            MIRROR -.->|metrics| METRICS
            METRICS --> GRAFANA
        end
    end
    
    subgraph "External Registries"
        DOCKERHUB[Docker Hub<br/>registry-1.docker.io]
        QUAY[Quay.io<br/>quay.io]
        GCR[Google Container Registry<br/>gcr.io]
        PRIVATE[Private Registry<br/>private.company.com]
    end
    
    DEV1 -->|docker pull| MIRROR
    DEV2 -->|docker pull| MIRROR
    DEV3 -->|docker pull| MIRROR
    
    MIRROR -.->|Cache Miss<br/>Upstream Pull| DOCKERHUB
    MIRROR -.->|Cache Miss<br/>Upstream Pull| QUAY
    MIRROR -.->|Cache Miss<br/>Upstream Pull| GCR
    MIRROR -.->|Cache Miss<br/>Upstream Pull| PRIVATE
    
    style MIRROR fill:#e1f5fe
    style CACHE fill:#f3e5f5
    style METRICS fill:#fff3e0
    style GRAFANA fill:#e8f5e8
```

### Mirror Benefits Visualization
```mermaid
graph LR
    subgraph "Without Mirror"
        D1[Developer] -->|"Pull: 2min<br/>Bandwidth: 100MB"| EXT1[External Registry]
        D2[Developer] -->|"Pull: 2min<br/>Bandwidth: 100MB"| EXT2[External Registry]
        D3[Developer] -->|"Pull: 2min<br/>Bandwidth: 100MB"| EXT3[External Registry]
    end
    
    subgraph "With Mirror"
        DD1[Developer] -->|"First Pull: 2min<br/>Subsequent: 10sec"| MIRROR_SVC[Mirror]
        DD2[Developer] -->|"Cached Pull: 10sec"| MIRROR_SVC
        DD3[Developer] -->|"Cached Pull: 10sec"| MIRROR_SVC
        
        MIRROR_SVC -.->|"One-time Pull<br/>Bandwidth: 100MB"| EXT_REG[External Registry]
    end
    
    style MIRROR_SVC fill:#c8e6c9
    style EXT_REG fill:#ffecb3
```

---

## 🏢 Enterprise Registry (Harbor) Architecture

```mermaid
graph TB
    subgraph "Harbor Enterprise Registry"
        subgraph "Web Interface Tier"
            PORTAL[Harbor Portal<br/>Web UI]
            API[Harbor API<br/>REST Endpoints]
        end
        
        subgraph "Core Services Tier"
            CORE[Harbor Core<br/>Business Logic]
            REGISTRY[Registry Service<br/>Docker Distribution]
            JOBSVC[Job Service<br/>Background Tasks]
        end
        
        subgraph "Security Services"
            SCANNER[Vulnerability Scanner<br/>Trivy/Clair]
            NOTARY[Notary Server<br/>Image Signing]
            AUTH_SVC[Authentication<br/>LDAP/OIDC/DB]
        end
        
        subgraph "Data Tier"
            POSTGRES[(PostgreSQL<br/>Metadata)]
            REDIS[(Redis<br/>Cache/Sessions)]
            STORAGE[(Storage Backend<br/>Filesystem/S3)]
        end
        
        subgraph "External Integration"
            LDAP[LDAP/AD<br/>User Directory]
            OIDC[OIDC Provider<br/>OAuth2/SAML]
            WEBHOOK[Webhooks<br/>Notifications]
        end
    end
    
    PORTAL --> API
    API --> CORE
    CORE --> REGISTRY
    CORE --> JOBSVC
    CORE --> SCANNER
    CORE --> NOTARY
    CORE --> AUTH_SVC
    
    CORE --> POSTGRES
    CORE --> REDIS
    REGISTRY --> STORAGE
    
    AUTH_SVC -.-> LDAP
    AUTH_SVC -.-> OIDC
    CORE -.-> WEBHOOK
    
    style CORE fill:#e1f5fe
    style REGISTRY fill:#f3e5f5
    style SCANNER fill:#fff3e0
    style POSTGRES fill:#e8f5e8
```

### Harbor Security Architecture
```mermaid
graph TB
    subgraph "Harbor Security Layers"
        subgraph "Access Control"
            RBAC[Role-Based Access Control<br/>Project Members/Admins]
            QUOTA[Resource Quotas<br/>Storage/Pull Limits]
        end
        
        subgraph "Content Security"
            VULN[Vulnerability Scanning<br/>CVE Detection]
            POLICY[Security Policies<br/>Deployment Rules]
            SIGN[Content Trust<br/>Image Signing]
        end
        
        subgraph "Compliance"
            AUDIT[Audit Logs<br/>Access Tracking]
            RETENTION[Retention Policies<br/>Lifecycle Management]
            REPLICATION[Content Replication<br/>Cross-Registry Sync]
        end
    end
    
    RBAC --> QUOTA
    VULN --> POLICY
    POLICY --> SIGN
    AUDIT --> RETENTION
    RETENTION --> REPLICATION
    
    style RBAC fill:#ffebee
    style VULN fill:#e8f5e8
    style AUDIT fill:#e3f2fd
```

---

## 🔄 High Availability Registry Architecture

```mermaid
graph TB
    subgraph "Load Balancer Tier"
        ELB[External Load Balancer<br/>AWS ALB/Azure LB/GCP LB]
        NGINX[Internal Load Balancer<br/>nginx/haproxy]
        
        ELB --> NGINX
    end
    
    subgraph "Registry Cluster"
        REG1[Registry Node 1<br/>registry:2.8]
        REG2[Registry Node 2<br/>registry:2.8]
        REG3[Registry Node 3<br/>registry:2.8]
        
        NGINX --> REG1
        NGINX --> REG2
        NGINX --> REG3
    end
    
    subgraph "Shared Storage Tier"
        NFS[NFS Share<br/>Shared Storage]
        S3[Object Storage<br/>S3/GCS/Azure Blob]
        
        REG1 --> NFS
        REG2 --> NFS
        REG3 --> NFS
        
        REG1 -.->|"Backup"| S3
        REG2 -.->|"Backup"| S3
        REG3 -.->|"Backup"| S3
    end
    
    subgraph "Service Discovery"
        CONSUL[Consul<br/>Service Discovery]
        ETCD[etcd<br/>Configuration Store]
        
        REG1 -.-> CONSUL
        REG2 -.-> CONSUL
        REG3 -.-> CONSUL
        
        CONSUL --> ETCD
    end
    
    subgraph "Monitoring & Alerting"
        PROMETHEUS[Prometheus<br/>Metrics Collection]
        GRAFANA[Grafana<br/>Visualization]
        ALERTMGR[AlertManager<br/>Notifications]
        
        REG1 -.->|metrics| PROMETHEUS
        REG2 -.->|metrics| PROMETHEUS
        REG3 -.->|metrics| PROMETHEUS
        
        PROMETHEUS --> GRAFANA
        PROMETHEUS --> ALERTMGR
    end
    
    style NGINX fill:#e1f5fe
    style REG1 fill:#f3e5f5
    style REG2 fill:#f3e5f5
    style REG3 fill:#f3e5f5
    style NFS fill:#fff3e0
    style CONSUL fill:#e8f5e8
```

### HA Failover Visualization
```mermaid
stateDiagram-v2
    [*] --> Healthy: All nodes operational
    Healthy --> Degraded: One node fails
    Degraded --> Healthy: Node recovered
    Degraded --> Critical: Second node fails
    Critical --> Degraded: Node recovered
    Critical --> Failed: All nodes down
    Failed --> Healthy: Nodes restored
    
    note right of Healthy
        3/3 nodes active
        Full redundancy
    end note
    
    note right of Degraded
        2/3 nodes active
        Reduced performance
    end note
    
    note right of Critical
        1/3 nodes active
        Limited capacity
    end note
    
    note right of Failed
        0/3 nodes active
        Service unavailable
    end note
```

---

## 🔒 Registry Security Architecture

```mermaid
graph TB
    subgraph "Security Perimeter"
        subgraph "Network Security"
            WAF[Web Application Firewall<br/>OWASP Protection]
            FW[Firewall<br/>Port Control]
            VPN[VPN/Private Network<br/>Access Control]
        end
        
        subgraph "Transport Security"
            TLS[TLS 1.3<br/>Encryption in Transit]
            CERTS[Certificate Authority<br/>PKI Management]
            HSTS[HSTS Headers<br/>Security Headers]
        end
        
        subgraph "Application Security"
            AUTH[Authentication<br/>Multi-factor/SSO]
            AUTHZ[Authorization<br/>RBAC/ABAC]
            AUDIT[Audit Logging<br/>Security Events]
        end
        
        subgraph "Content Security"
            SCAN[Vulnerability Scanning<br/>Container Security]
            SIGN[Image Signing<br/>Content Trust]
            POLICY[Admission Policies<br/>Governance]
        end
        
        subgraph "Data Security"
            ENCRYPT[Encryption at Rest<br/>Storage Encryption]
            BACKUP[Secure Backup<br/>Disaster Recovery]
            SECRETS[Secret Management<br/>Key Rotation]
        end
    end
    
    WAF --> TLS
    TLS --> AUTH
    AUTH --> SCAN
    SCAN --> ENCRYPT
    
    FW --> CERTS
    CERTS --> AUTHZ
    AUTHZ --> SIGN
    SIGN --> BACKUP
    
    VPN --> HSTS
    HSTS --> AUDIT
    AUDIT --> POLICY
    POLICY --> SECRETS
    
    style WAF fill:#ffebee
    style AUTH fill:#e8f5e8
    style SCAN fill:#fff3e0
    style ENCRYPT fill:#e3f2fd
```

### Security Event Flow
```mermaid
sequenceDiagram
    participant Attacker as Potential Threat
    participant WAF as Web App Firewall
    participant Registry as Registry Service
    participant Scanner as Vulnerability Scanner
    participant SIEM as Security System
    
    Attacker->>+WAF: Malicious request
    WAF->>WAF: Analyze request patterns
    WAF->>-Attacker: Block/Rate limit
    WAF->>SIEM: Log security event
    
    Attacker->>+Registry: Push malicious image
    Registry->>+Scanner: Trigger security scan
    Scanner->>Scanner: Analyze image for vulnerabilities
    Scanner->>-Registry: Security report (vulnerabilities found)
    Registry->>Attacker: Reject push (policy violation)
    Registry->>SIEM: Log policy violation
    
    SIEM->>SIEM: Correlate security events
    SIEM->>SIEM: Generate alert if threshold exceeded
    
    style WAF fill:#ffebee
    style Scanner fill:#fff3e0
    style SIEM fill:#e8f5e8
```

---

## 📊 Registry Performance Metrics

```mermaid
graph TB
    subgraph "Registry Performance Dashboard"
        subgraph "Request Metrics"
            RPS[Requests per Second<br/>📈 Push/Pull Rate]
            LATENCY[Response Latency<br/>⏱️ P95/P99 Times]
            ERRORS[Error Rate<br/>❌ 4xx/5xx Responses]
        end
        
        subgraph "Storage Metrics"
            SIZE[Storage Usage<br/>💾 Total Size/Growth]
            IOPS[Storage IOPS<br/>⚡ Read/Write Operations]
            BANDWIDTH[Network Bandwidth<br/>🌐 Upload/Download]
        end
        
        subgraph "Cache Metrics"
            HITRATE[Cache Hit Rate<br/>🎯 Cache Efficiency]
            EVICTIONS[Cache Evictions<br/>🗑️ LRU/TTL Removals]
            MEMORY[Memory Usage<br/>🧠 Cache Size/Utilization]
        end
        
        subgraph "Health Metrics"
            CPU[CPU Utilization<br/>🔥 Process Load]
            MEMORY_SYS[System Memory<br/>💿 Available/Used]
            DISK[Disk Usage<br/>💽 Free Space/Growth]
        end
    end
    
    RPS -.-> SIZE
    LATENCY -.-> IOPS
    ERRORS -.-> HITRATE
    BANDWIDTH -.-> CPU
    
    style RPS fill:#e3f2fd
    style SIZE fill:#f3e5f5
    style HITRATE fill:#fff3e0
    style CPU fill:#e8f5e8
```

### Performance Optimization Flow
```mermaid
flowchart TD
    START([Performance Issue Detected]) --> IDENTIFY{Identify Bottleneck}
    
    IDENTIFY -->|High Latency| CACHE[Optimize Caching]
    IDENTIFY -->|Storage Full| CLEANUP[Run Garbage Collection]
    IDENTIFY -->|High CPU| SCALE[Scale Horizontally]
    IDENTIFY -->|Network Slow| MIRROR[Deploy Mirrors]
    
    CACHE --> VALIDATE{Performance Improved?}
    CLEANUP --> VALIDATE
    SCALE --> VALIDATE
    MIRROR --> VALIDATE
    
    VALIDATE -->|Yes| MONITOR[Continue Monitoring]
    VALIDATE -->|No| DEEPER[Deeper Analysis Required]
    
    DEEPER --> IDENTIFY
    MONITOR --> START
    
    style START fill:#e1f5fe
    style IDENTIFY fill:#fff3e0
    style VALIDATE fill:#e8f5e8
    style MONITOR fill:#f3e5f5
```

---

## 🔄 Registry Lifecycle Management

```mermaid
graph TB
    subgraph "Image Lifecycle Pipeline"
        subgraph "Development Stage"
            BUILD[Image Build<br/>🔨 CI/CD Pipeline]
            TEST[Security Scan<br/>🔍 Vulnerability Check]
            SIGN[Image Signing<br/>✍️ Content Trust]
        end
        
        subgraph "Registry Storage"
            STAGING[Staging Repository<br/>🚧 Development Images]
            PROD[Production Repository<br/>✅ Approved Images]
            ARCHIVE[Archive Repository<br/>📦 Historical Images]
        end
        
        subgraph "Lifecycle Policies"
            RETENTION[Retention Policy<br/>⏰ Age-based Cleanup]
            PROMOTION[Promotion Policy<br/>⬆️ Stage Advancement]
            CLEANUP[Cleanup Policy<br/>🗑️ Unused Removal]
        end
    end
    
    BUILD --> TEST
    TEST --> SIGN
    SIGN --> STAGING
    
    STAGING -->|Approved| PROD
    PROD -->|Superseded| ARCHIVE
    
    RETENTION --> STAGING
    PROMOTION --> PROD
    CLEANUP --> ARCHIVE
    
    style BUILD fill:#e1f5fe
    style STAGING fill:#fff3e0
    style PROD fill:#e8f5e8
    style ARCHIVE fill:#f3e5f5
```

### Retention Policy Visualization
```mermaid
gantt
    title Registry Image Retention Timeline
    dateFormat X
    axisFormat %d days
    
    section Development Images
    Keep Latest 10 Versions    :done, dev1, 0, 30
    Cleanup Older Versions     :crit, dev2, 30, 31
    
    section Staging Images
    Keep Latest 5 Versions     :done, stage1, 0, 60
    Cleanup Older Versions     :crit, stage2, 60, 61
    
    section Production Images
    Keep Latest 3 Versions     :done, prod1, 0, 90
    Archive Older Versions     :done, prod2, 90, 365
    Delete Ancient Versions    :crit, prod3, 365, 366
    
    section Security Updates
    Immediate Cleanup          :crit, sec1, 0, 1
    Force Update Required      :crit, sec2, 1, 7
```

---

## 🌐 Multi-Registry Federation

```mermaid
graph TB
    subgraph "Multi-Cloud Registry Federation"
        subgraph "Region 1 - US East"
            REG_US[Harbor US<br/>🇺🇸 Primary Registry]
            CACHE_US[Pull-through Cache<br/>🚀 Local Performance]
        end
        
        subgraph "Region 2 - EU West"
            REG_EU[Harbor EU<br/>🇪🇺 Regional Registry]
            CACHE_EU[Pull-through Cache<br/>🚀 Local Performance]
        end
        
        subgraph "Region 3 - Asia Pacific"
            REG_ASIA[Harbor APAC<br/>🌏 Regional Registry]
            CACHE_ASIA[Pull-through Cache<br/>🚀 Local Performance]
        end
        
        subgraph "External Registries"
            DOCKERHUB[Docker Hub<br/>🐳 Public Images]
            QUAY[Quay.io<br/>🚢 RedHat Images]
            GCR[Google GCR<br/>☁️ Google Images]
        end
    end
    
    REG_US <==>|"Bi-directional<br/>Replication"| REG_EU
    REG_EU <==>|"Bi-directional<br/>Replication"| REG_ASIA
    REG_ASIA <==>|"Bi-directional<br/>Replication"| REG_US
    
    CACHE_US -.->|"Pull-through"| DOCKERHUB
    CACHE_EU -.->|"Pull-through"| QUAY
    CACHE_ASIA -.->|"Pull-through"| GCR
    
    REG_US --> CACHE_US
    REG_EU --> CACHE_EU
    REG_ASIA --> CACHE_ASIA
    
    style REG_US fill:#e1f5fe
    style REG_EU fill:#e1f5fe
    style REG_ASIA fill:#e1f5fe
    style CACHE_US fill:#f3e5f5
    style CACHE_EU fill:#f3e5f5
    style CACHE_ASIA fill:#f3e5f5
```

### Federation Synchronization Flow
```mermaid
sequenceDiagram
    participant Dev as Developer (US)
    participant RegUS as Registry US
    participant RegEU as Registry EU
    participant RegAsia as Registry APAC
    participant DevAsia as Developer (APAC)
    
    Dev->>+RegUS: Push myapp:v1.0
    RegUS->>RegUS: Store image locally
    RegUS->>-Dev: Push successful
    
    Note over RegUS,RegEU: Replication Trigger
    RegUS->>+RegEU: Replicate myapp:v1.0
    RegEU->>RegEU: Store replicated image
    RegEU->>-RegUS: Replication complete
    
    Note over RegEU,RegAsia: Chain Replication
    RegEU->>+RegAsia: Replicate myapp:v1.0
    RegAsia->>RegAsia: Store replicated image
    RegAsia->>-RegEU: Replication complete
    
    Note over RegAsia,DevAsia: Local Pull (Fast)
    DevAsia->>+RegAsia: Pull myapp:v1.0
    RegAsia->>-DevAsia: Serve from local storage
    
    style RegUS fill:#e1f5fe
    style RegEU fill:#e1f5fe
    style RegAsia fill:#e1f5fe
```

---

## 📋 Visual Summary Checklist

### Architecture Understanding
- [ ] Basic registry components and interactions
- [ ] Authentication and authorization flows
- [ ] Mirror and caching architectures
- [ ] Enterprise registry features and services

### Security Visualization
- [ ] Multi-layered security architecture
- [ ] Content trust and image signing flows
- [ ] Vulnerability scanning integration
- [ ] Audit and compliance tracking

### Performance and Scaling
- [ ] High availability configurations
- [ ] Load balancing and distribution
- [ ] Performance metrics and monitoring
- [ ] Scaling patterns and bottlenecks

### Operational Workflows
- [ ] Image lifecycle management
- [ ] Retention and cleanup policies
- [ ] Multi-registry federation
- [ ] Disaster recovery scenarios

---

💡 **Visual Learning Success**: These diagrams provide comprehensive understanding of registry architectures, from basic setups to complex enterprise deployments with security, performance, and operational excellence.