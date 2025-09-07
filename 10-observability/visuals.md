# Phase 10 Visuals: Docker Observability Architecture

> **Purpose**: Visual diagrams and architecture overviews for Docker observability implementations  
> **Scope**: Comprehensive visual guide covering monitoring, logging, tracing, and alerting architectures

## 📊 Visual Learning Overview

This visual guide provides:
- Observability architecture diagrams
- Logging infrastructure layouts
- Metrics collection flows
- Distributed tracing patterns
- Performance monitoring dashboards
- Complete observability stack architectures

---

## 🔍 The Three Pillars of Observability

```mermaid
graph TB
    subgraph "Observability Pillars"
        subgraph "Metrics"
            M1[What is happening?]
            M2[System Performance]
            M3[Resource Usage]
            M4[Business KPIs]
        end
        
        subgraph "Logs"
            L1[Why is it happening?]
            L2[Event Details]
            L3[Error Messages]
            L4[Debug Information]
        end
        
        subgraph "Traces"
            T1[How are requests flowing?]
            T2[Service Dependencies]
            T3[Latency Breakdown]
            T4[Error Propagation]
        end
    end
    
    subgraph "Integration"
        CORRELATION[Data Correlation]
        CONTEXT[Rich Context]
        INSIGHTS[Actionable Insights]
    end
    
    M1 --> CORRELATION
    L1 --> CORRELATION
    T1 --> CORRELATION
    
    CORRELATION --> CONTEXT
    CONTEXT --> INSIGHTS
    
    style M1 fill:#e3f2fd
    style L1 fill:#f3e5f5
    style T1 fill:#e8f5e8
    style CORRELATION fill:#fff3e0
```

### Observability Data Types
- **Metrics**: Time-series numerical data
- **Logs**: Structured and unstructured event records
- **Traces**: Request journey across service boundaries
- **Events**: Discrete occurrences with context

---

## 📝 Docker Logging Architecture

```mermaid
graph TB
    subgraph "Container Layer"
        APP1[Application 1]
        APP2[Application 2]
        APP3[Application 3]
        
        APP1 --> STDOUT1[STDOUT/STDERR]
        APP2 --> STDOUT2[STDOUT/STDERR]
        APP3 --> STDOUT3[STDOUT/STDERR]
    end
    
    subgraph "Docker Logging Drivers"
        STDOUT1 --> JSON[json-file]
        STDOUT2 --> FLUENTD[fluentd]
        STDOUT3 --> SYSLOG[syslog]
        
        subgraph "Driver Options"
            ROTATE[Log Rotation]
            COMPRESS[Compression]
            LABELS[Custom Labels]
        end
        
        JSON --> ROTATE
        FLUENTD --> COMPRESS
        SYSLOG --> LABELS
    end
    
    subgraph "Log Aggregation"
        JSON --> PROMTAIL[Promtail]
        FLUENTD --> FLUENTD_SVC[Fluentd Service]
        SYSLOG --> RSYSLOG[Rsyslog]
        
        PROMTAIL --> LOKI[Grafana Loki]
        FLUENTD_SVC --> ELASTIC[Elasticsearch]
        RSYSLOG --> JOURNALD[Journald]
    end
    
    subgraph "Storage & Analysis"
        LOKI --> GRAFANA[Grafana Explore]
        ELASTIC --> KIBANA[Kibana]
        JOURNALD --> SYSTEMD[systemd-journald]
    end
    
    style JSON fill:#e1f5fe
    style FLUENTD fill:#f3e5f5
    style SYSLOG fill:#e8f5e8
    style LOKI fill:#fff3e0
```

### Logging Driver Comparison
```mermaid
graph LR
    subgraph "Performance"
        JSON_PERF[json-file: Fast]
        FLUENTD_PERF[fluentd: Medium]
        SYSLOG_PERF[syslog: Medium]
    end
    
    subgraph "Features"
        JSON_FEAT[Local Storage Only]
        FLUENTD_FEAT[Rich Processing]
        SYSLOG_FEAT[System Integration]
    end
    
    subgraph "Use Cases"
        JSON_USE[Development/Testing]
        FLUENTD_USE[Centralized Logging]
        SYSLOG_USE[System Services]
    end
    
    JSON_PERF --> JSON_FEAT --> JSON_USE
    FLUENTD_PERF --> FLUENTD_FEAT --> FLUENTD_USE
    SYSLOG_PERF --> SYSLOG_FEAT --> SYSLOG_USE
    
    style JSON_PERF fill:#c8e6c9
    style FLUENTD_FEAT fill:#ffecb3
    style SYSLOG_USE fill:#e1bee7
```

---

## 📊 Metrics Collection Architecture

```mermaid
graph TB
    subgraph "Data Sources"
        subgraph "Host Metrics"
            NODE[Node Exporter]
            HOST_CPU[CPU Usage]
            HOST_MEM[Memory Usage]
            HOST_DISK[Disk I/O]
            HOST_NET[Network Stats]
            
            NODE --> HOST_CPU
            NODE --> HOST_MEM
            NODE --> HOST_DISK
            NODE --> HOST_NET
        end
        
        subgraph "Container Metrics"
            CADVISOR[cAdvisor]
            CONT_CPU[Container CPU]
            CONT_MEM[Container Memory]
            CONT_NET[Container Network]
            CONT_FS[Container Filesystem]
            
            CADVISOR --> CONT_CPU
            CADVISOR --> CONT_MEM
            CADVISOR --> CONT_NET
            CADVISOR --> CONT_FS
        end
        
        subgraph "Application Metrics"
            APP_METRICS[Custom Metrics]
            HTTP_REQ[HTTP Requests]
            ERROR_RATE[Error Rate]
            RESPONSE_TIME[Response Time]
            BUSINESS_KPI[Business KPIs]
            
            APP_METRICS --> HTTP_REQ
            APP_METRICS --> ERROR_RATE
            APP_METRICS --> RESPONSE_TIME
            APP_METRICS --> BUSINESS_KPI
        end
    end
    
    subgraph "Collection Layer"
        PROMETHEUS[Prometheus Server]
        
        NODE --> PROMETHEUS
        CADVISOR --> PROMETHEUS
        APP_METRICS --> PROMETHEUS
    end
    
    subgraph "Storage Layer"
        TSDB[Time Series Database]
        RETENTION[Data Retention]
        COMPRESSION[Data Compression]
        
        PROMETHEUS --> TSDB
        TSDB --> RETENTION
        TSDB --> COMPRESSION
    end
    
    subgraph "Visualization Layer"
        GRAFANA[Grafana]
        DASHBOARD[Dashboards]
        ALERTS[Alerts]
        
        PROMETHEUS --> GRAFANA
        GRAFANA --> DASHBOARD
        GRAFANA --> ALERTS
    end
    
    style PROMETHEUS fill:#ff6b35
    style GRAFANA fill:#f46800
    style CADVISOR fill:#326ce5
```

### Prometheus Scraping Flow
```mermaid
sequenceDiagram
    participant P as Prometheus
    participant T as Target Service
    participant E as Exporter
    
    Note over P,E: Service Discovery Process
    P->>P: Load configuration
    P->>P: Discover targets
    
    Note over P,E: Metrics Collection
    loop Every scrape_interval
        P->>T: HTTP GET /metrics
        T->>E: Generate metrics
        E->>T: Return metrics data
        T->>P: 200 OK + metrics
        P->>P: Store in TSDB
    end
    
    Note over P,E: Data Lifecycle
    P->>P: Apply recording rules
    P->>P: Evaluate alerts
    P->>P: Compact data
    P->>P: Apply retention
```

---

## 🔗 Distributed Tracing Architecture

```mermaid
graph TB
    subgraph "Service Mesh"
        subgraph "Frontend Services"
            WEB[Web Service]
            API[API Gateway]
            AUTH[Auth Service]
        end
        
        subgraph "Backend Services"
            USER[User Service]
            ORDER[Order Service]
            PAYMENT[Payment Service]
            INVENTORY[Inventory Service]
        end
        
        subgraph "Data Layer"
            DB1[(User DB)]
            DB2[(Order DB)]
            CACHE[(Redis Cache)]
        end
    end
    
    subgraph "Tracing Infrastructure"
        subgraph "Instrumentation"
            OTEL[OpenTelemetry]
            SPANS[Span Generation]
            CONTEXT[Context Propagation]
        end
        
        subgraph "Collection"
            JAEGER_AGENT[Jaeger Agent]
            JAEGER_COLLECTOR[Jaeger Collector]
            TEMPO[Grafana Tempo]
        end
        
        subgraph "Storage"
            STORAGE[(Trace Storage)]
            INDEX[Trace Index]
            RETENTION_POLICY[Retention Policy]
        end
        
        subgraph "Analysis"
            JAEGER_UI[Jaeger UI]
            GRAFANA_EXPLORE[Grafana Explore]
            SERVICE_MAP[Service Map]
            DEPENDENCY_GRAPH[Dependency Graph]
        end
    end
    
    # Trace flow
    WEB --> API --> AUTH
    API --> USER --> DB1
    API --> ORDER --> DB2
    ORDER --> PAYMENT
    ORDER --> INVENTORY --> CACHE
    
    # Instrumentation
    WEB --> OTEL
    API --> OTEL
    USER --> OTEL
    ORDER --> OTEL
    
    # Collection
    OTEL --> SPANS
    SPANS --> CONTEXT
    SPANS --> JAEGER_AGENT
    JAEGER_AGENT --> JAEGER_COLLECTOR
    JAEGER_COLLECTOR --> STORAGE
    
    # Analysis
    STORAGE --> JAEGER_UI
    STORAGE --> SERVICE_MAP
    
    style OTEL fill:#4285f4
    style JAEGER_COLLECTOR fill:#326ce5
    style JAEGER_UI fill:#1976d2
```

### Trace Correlation with Logs and Metrics
```mermaid
graph LR
    subgraph "Request Journey"
        REQ[HTTP Request]
        TRACE_ID[Trace ID: abc123]
        SPAN1[Service A Span]
        SPAN2[Service B Span]
        SPAN3[Database Span]
    end
    
    subgraph "Logs Correlation"
        LOG1[Service A Log]
        LOG2[Service B Log]
        LOG3[Database Log]
        
        LOG1 --> TRACE_REF1[trace_id: abc123]
        LOG2 --> TRACE_REF2[trace_id: abc123]
        LOG3 --> TRACE_REF3[trace_id: abc123]
    end
    
    subgraph "Metrics Correlation"
        METRIC1[HTTP Request Count]
        METRIC2[Response Time]
        METRIC3[Error Rate]
        
        METRIC1 --> LABEL1[trace_id: abc123]
        METRIC2 --> LABEL2[trace_id: abc123]
        METRIC3 --> LABEL3[trace_id: abc123]
    end
    
    REQ --> TRACE_ID
    TRACE_ID --> SPAN1
    SPAN1 --> SPAN2
    SPAN2 --> SPAN3
    
    SPAN1 --> LOG1
    SPAN2 --> LOG2
    SPAN3 --> LOG3
    
    SPAN1 --> METRIC1
    SPAN2 --> METRIC2
    SPAN3 --> METRIC3
    
    style TRACE_ID fill:#4caf50
    style TRACE_REF1 fill:#4caf50
    style TRACE_REF2 fill:#4caf50
    style TRACE_REF3 fill:#4caf50
```

---

## 🚨 Alerting and Incident Response

```mermaid
graph TB
    subgraph "Data Sources"
        PROMETHEUS[Prometheus]
        LOKI[Loki]
        JAEGER[Jaeger]
    end
    
    subgraph "Alert Rules"
        PROM_RULES[Prometheus Rules]
        LOKI_RULES[Loki Rules]
        CUSTOM_RULES[Custom Rules]
        
        subgraph "Rule Types"
            THRESHOLD[Threshold Alerts]
            ANOMALY[Anomaly Detection]
            SLO[SLO Violations]
        end
        
        PROM_RULES --> THRESHOLD
        LOKI_RULES --> ANOMALY
        CUSTOM_RULES --> SLO
    end
    
    subgraph "Alert Manager"
        ALERTMGR[AlertManager]
        GROUPING[Alert Grouping]
        ROUTING[Routing Rules]
        SUPPRESSION[Suppression]
        
        ALERTMGR --> GROUPING
        ALERTMGR --> ROUTING
        ALERTMGR --> SUPPRESSION
    end
    
    subgraph "Notification Channels"
        EMAIL[Email]
        SLACK[Slack]
        PAGERDUTY[PagerDuty]
        WEBHOOK[Webhooks]
        SMS[SMS]
    end
    
    subgraph "Incident Response"
        ONCALL[On-Call Rotation]
        ESCALATION[Escalation Policy]
        RUNBOOK[Runbooks]
        POSTMORTEM[Post-Mortem]
    end
    
    # Flow
    PROMETHEUS --> PROM_RULES
    LOKI --> LOKI_RULES
    
    PROM_RULES --> ALERTMGR
    LOKI_RULES --> ALERTMGR
    CUSTOM_RULES --> ALERTMGR
    
    ALERTMGR --> EMAIL
    ALERTMGR --> SLACK
    ALERTMGR --> PAGERDUTY
    ALERTMGR --> WEBHOOK
    ALERTMGR --> SMS
    
    PAGERDUTY --> ONCALL
    ONCALL --> ESCALATION
    ESCALATION --> RUNBOOK
    RUNBOOK --> POSTMORTEM
    
    style ALERTMGR fill:#ff5722
    style ONCALL fill:#f44336
    style ESCALATION fill:#e91e63
```

### Alert Severity and Response Matrix
```mermaid
graph TB
    subgraph "Alert Severity Levels"
        subgraph "Critical"
            CRIT_DESC[Service Down<br/>Data Loss Risk<br/>Security Breach]
            CRIT_RESPONSE[Immediate Response<br/>< 5 minutes]
            CRIT_CHANNELS[PagerDuty + SMS<br/>+ Phone Calls]
        end
        
        subgraph "High"
            HIGH_DESC[Performance Degraded<br/>Error Rate Spike<br/>Resource Exhaustion]
            HIGH_RESPONSE[Quick Response<br/>< 15 minutes]
            HIGH_CHANNELS[PagerDuty + Slack<br/>+ Email]
        end
        
        subgraph "Warning"
            WARN_DESC[Threshold Exceeded<br/>Capacity Planning<br/>Maintenance Needed]
            WARN_RESPONSE[Business Hours<br/>< 4 hours]
            WARN_CHANNELS[Slack + Email]
        end
        
        subgraph "Info"
            INFO_DESC[Deployment Events<br/>Scaling Events<br/>Config Changes]
            INFO_RESPONSE[No Immediate Action<br/>Logging Only]
            INFO_CHANNELS[Logs + Dashboard]
        end
    end
    
    CRIT_DESC --> CRIT_RESPONSE --> CRIT_CHANNELS
    HIGH_DESC --> HIGH_RESPONSE --> HIGH_CHANNELS
    WARN_DESC --> WARN_RESPONSE --> WARN_CHANNELS
    INFO_DESC --> INFO_RESPONSE --> INFO_CHANNELS
    
    style CRIT_DESC fill:#ff5252
    style HIGH_DESC fill:#ff9800
    style WARN_DESC fill:#ffeb3b
    style INFO_DESC fill:#4caf50
```

---

## 📊 Performance Monitoring Dashboard

```mermaid
graph TB
    subgraph "Performance Metrics Dashboard"
        subgraph "Infrastructure Layer"
            CPU_PANEL[CPU Utilization<br/>📊 Time Series]
            MEM_PANEL[Memory Usage<br/>📊 Gauge]
            DISK_PANEL[Disk I/O<br/>📊 Graph]
            NET_PANEL[Network Traffic<br/>📊 Area Chart]
        end
        
        subgraph "Container Layer"
            CONT_CPU[Container CPU<br/>📊 Heatmap]
            CONT_MEM[Container Memory<br/>📊 Bar Chart]
            CONT_COUNT[Container Count<br/>📊 Stat Panel]
            CONT_RESTART[Restart Rate<br/>📊 Single Stat]
        end
        
        subgraph "Application Layer"
            REQ_RATE[Request Rate<br/>📊 Line Graph]
            RESPONSE_TIME[Response Time<br/>📊 Histogram]
            ERROR_RATE[Error Rate<br/>📊 Threshold]
            THROUGHPUT[Throughput<br/>📊 Counter]
        end
        
        subgraph "Business Layer"
            ACTIVE_USERS[Active Users<br/>📊 Gauge]
            TRANSACTIONS[Transactions<br/>📊 Bar Chart]
            REVENUE[Revenue<br/>📊 Trend]
            SLA[SLA Compliance<br/>📊 Status Panel]
        end
    end
    
    subgraph "Alert Panels"
        FIRING[Firing Alerts<br/>🚨 Alert List]
        INCIDENTS[Active Incidents<br/>📋 Table]
        SLO_STATUS[SLO Status<br/>✅ Green/Red]
    end
    
    subgraph "Drill-Down Navigation"
        LOGS_LINK[View Logs<br/>🔗 Link to Loki]
        TRACES_LINK[View Traces<br/>🔗 Link to Jaeger]
        DETAIL_DASH[Detailed Dashboard<br/>🔗 Link to Details]
    end
    
    # Relationships
    CPU_PANEL -.->|Drill Down| CONT_CPU
    CONT_CPU -.->|Drill Down| REQ_RATE
    REQ_RATE -.->|Context| LOGS_LINK
    REQ_RATE -.->|Context| TRACES_LINK
    
    ERROR_RATE --> FIRING
    FIRING --> INCIDENTS
    
    style CPU_PANEL fill:#e3f2fd
    style REQ_RATE fill:#f3e5f5
    style ERROR_RATE fill:#ffebee
    style FIRING fill:#ff5252
```

### Performance Monitoring Flow
```mermaid
sequenceDiagram
    participant User as User
    participant Dashboard as Grafana Dashboard
    participant Prometheus as Prometheus
    participant cAdvisor as cAdvisor
    participant Container as Container
    
    Note over User,Container: Performance Monitoring Flow
    
    User->>Dashboard: View performance metrics
    Dashboard->>Prometheus: Query metrics
    
    loop Every 15 seconds
        Prometheus->>cAdvisor: Scrape container metrics
        cAdvisor->>Container: Collect resource usage
        Container->>cAdvisor: Return CPU, memory, I/O stats
        cAdvisor->>Prometheus: Provide metrics
    end
    
    Prometheus->>Dashboard: Return time series data
    Dashboard->>User: Display charts and graphs
    
    alt Alert Condition Met
        Dashboard->>Dashboard: Trigger alert
        Dashboard->>User: Show alert notification
    end
```

---

## 🏗️ Complete Observability Stack

```mermaid
graph TB
    subgraph "Application Layer"
        subgraph "Microservices"
            SVC_A[Service A]
            SVC_B[Service B]
            SVC_C[Service C]
            
            SVC_A --> SVC_B
            SVC_B --> SVC_C
        end
        
        subgraph "Instrumentation"
            OTEL_A[OpenTelemetry<br/>Agent A]
            OTEL_B[OpenTelemetry<br/>Agent B]
            OTEL_C[OpenTelemetry<br/>Agent C]
        end
        
        SVC_A --> OTEL_A
        SVC_B --> OTEL_B
        SVC_C --> OTEL_C
    end
    
    subgraph "Data Collection Layer"
        subgraph "Metrics"
            PROMETHEUS[Prometheus<br/>📊 Metrics]
            NODE_EXP[Node Exporter<br/>🖥️ Host Metrics]
            CADVISOR[cAdvisor<br/>🐳 Container Metrics]
        end
        
        subgraph "Logs"
            LOKI[Loki<br/>📝 Logs]
            PROMTAIL[Promtail<br/>📥 Log Collection]
        end
        
        subgraph "Traces"
            TEMPO[Tempo<br/>🔗 Traces]
            JAEGER[Jaeger<br/>🔍 Tracing UI]
        end
        
        OTEL_A --> PROMETHEUS
        OTEL_A --> LOKI
        OTEL_A --> TEMPO
    end
    
    subgraph "Storage Layer"
        PROM_STORAGE[(Prometheus<br/>TSDB)]
        LOKI_STORAGE[(Loki<br/>Storage)]
        TEMPO_STORAGE[(Tempo<br/>Storage)]
        
        PROMETHEUS --> PROM_STORAGE
        LOKI --> LOKI_STORAGE
        TEMPO --> TEMPO_STORAGE
    end
    
    subgraph "Visualization Layer"
        GRAFANA[Grafana<br/>📈 Dashboards]
        
        PROMETHEUS --> GRAFANA
        LOKI --> GRAFANA
        TEMPO --> GRAFANA
        JAEGER --> GRAFANA
    end
    
    subgraph "Alerting Layer"
        ALERTMGR[AlertManager<br/>🚨 Alerts]
        NOTIFICATIONS[Notifications<br/>📧 Email, Slack, PagerDuty]
        
        PROMETHEUS --> ALERTMGR
        LOKI --> ALERTMGR
        ALERTMGR --> NOTIFICATIONS
    end
    
    subgraph "Operations Layer"
        ONCALL[On-Call<br/>👥 Engineers]
        RUNBOOKS[Runbooks<br/>📚 Procedures]
        INCIDENTS[Incident<br/>Management]
        
        NOTIFICATIONS --> ONCALL
        ONCALL --> RUNBOOKS
        RUNBOOKS --> INCIDENTS
    end
    
    style PROMETHEUS fill:#e6522c
    style LOKI fill:#f46800
    style TEMPO fill:#f46800
    style GRAFANA fill:#f46800
    style ALERTMGR fill:#ff5722
```

### Data Flow and Integration
```mermaid
graph LR
    subgraph "Source Systems"
        APPS[Applications]
        CONTAINERS[Containers]
        HOSTS[Host Systems]
    end
    
    subgraph "Telemetry Data"
        METRICS[Metrics<br/>Time Series]
        LOGS[Logs<br/>Events]
        TRACES[Traces<br/>Requests]
    end
    
    subgraph "Correlation Engine"
        CORRELATION[Data Correlation]
        CONTEXT[Context Enrichment]
        ANALYSIS[Pattern Analysis]
    end
    
    subgraph "Intelligence Layer"
        ANOMALY[Anomaly Detection]
        PREDICTION[Predictive Analysis]
        RECOMMENDATION[Recommendations]
    end
    
    subgraph "Action Layer"
        ALERTS[Automated Alerts]
        SCALING[Auto-scaling]
        REMEDIATION[Self-healing]
    end
    
    APPS --> METRICS
    CONTAINERS --> LOGS
    HOSTS --> TRACES
    
    METRICS --> CORRELATION
    LOGS --> CORRELATION
    TRACES --> CORRELATION
    
    CORRELATION --> CONTEXT
    CONTEXT --> ANALYSIS
    
    ANALYSIS --> ANOMALY
    ANALYSIS --> PREDICTION
    ANALYSIS --> RECOMMENDATION
    
    ANOMALY --> ALERTS
    PREDICTION --> SCALING
    RECOMMENDATION --> REMEDIATION
    
    style CORRELATION fill:#4caf50
    style ANALYSIS fill:#2196f3
    style ALERTS fill:#ff9800
```

---

## 🎯 SLI/SLO Monitoring

```mermaid
graph TB
    subgraph "Service Level Indicators (SLIs)"
        subgraph "Golden Signals"
            LATENCY[Latency<br/>Response Time<br/>P95 < 500ms]
            TRAFFIC[Traffic<br/>Requests/sec<br/>> 1000 RPS]
            ERRORS[Errors<br/>Error Rate<br/>< 0.1%]
            SATURATION[Saturation<br/>CPU/Memory<br/>< 80%]
        end
        
        subgraph "Custom SLIs"
            AVAILABILITY[Availability<br/>Uptime %<br/>> 99.9%]
            FRESHNESS[Data Freshness<br/>Update Lag<br/>< 5 minutes]
            QUALITY[Data Quality<br/>Valid Records<br/>> 99%]
        end
    end
    
    subgraph "Service Level Objectives (SLOs)"
        SLO_AVAILABILITY[99.9% Availability<br/>Over 30 days]
        SLO_LATENCY[95% of requests<br/>< 500ms response time]
        SLO_ERROR[Error rate < 0.1%<br/>Over rolling 7 days]
    end
    
    subgraph "Error Budget"
        BUDGET_CALC[Error Budget<br/>Calculation]
        BUDGET_BURN[Burn Rate<br/>Monitoring]
        BUDGET_ALERT[Budget Alerts<br/>When < 10%]
    end
    
    subgraph "SLO Dashboards"
        SLO_DASH[SLO Dashboard<br/>📊 Real-time Status]
        ERROR_BUDGET_DASH[Error Budget<br/>📈 Burn Rate]
        TREND_ANALYSIS[Trend Analysis<br/>📉 Historical Data]
    end
    
    # Relationships
    LATENCY --> SLO_LATENCY
    ERRORS --> SLO_ERROR
    AVAILABILITY --> SLO_AVAILABILITY
    
    SLO_LATENCY --> BUDGET_CALC
    SLO_ERROR --> BUDGET_CALC
    SLO_AVAILABILITY --> BUDGET_CALC
    
    BUDGET_CALC --> BUDGET_BURN
    BUDGET_BURN --> BUDGET_ALERT
    
    SLO_AVAILABILITY --> SLO_DASH
    BUDGET_CALC --> ERROR_BUDGET_DASH
    SLO_DASH --> TREND_ANALYSIS
    
    style SLO_AVAILABILITY fill:#4caf50
    style BUDGET_ALERT fill:#ff5722
    style SLO_DASH fill:#2196f3
```

### SLO Alerting Strategy
```mermaid
graph TD
    subgraph "Multi-Window Alerting"
        subgraph "Fast Burn"
            FAST_1H[1 hour window<br/>Burn rate > 14.4x<br/>🚨 Page immediately]
            FAST_5M[5 minute window<br/>Burn rate > 14.4x<br/>🔥 Critical alert]
        end
        
        subgraph "Slow Burn"
            SLOW_6H[6 hour window<br/>Burn rate > 6x<br/>⚠️ Warning alert]
            SLOW_30M[30 minute window<br/>Burn rate > 6x<br/>📧 Email notification]
        end
        
        subgraph "Budget Depletion"
            BUDGET_10[Error budget < 10%<br/>📢 Team notification]
            BUDGET_5[Error budget < 5%<br/>🛑 Freeze deployments]
        end
    end
    
    subgraph "Alert Actions"
        PAGE[Page On-Call<br/>👨‍💻 Immediate response]
        NOTIFY[Notify Team<br/>💬 Slack/Email]
        FREEZE[Freeze Changes<br/>🚫 Block deployments]
        INVESTIGATE[Start Investigation<br/>🔍 Root cause analysis]
    end
    
    FAST_1H --> PAGE
    FAST_5M --> PAGE
    SLOW_6H --> NOTIFY
    SLOW_30M --> NOTIFY
    BUDGET_10 --> NOTIFY
    BUDGET_5 --> FREEZE
    
    PAGE --> INVESTIGATE
    NOTIFY --> INVESTIGATE
    
    style FAST_1H fill:#ff5252
    style FAST_5M fill:#ff5252
    style BUDGET_5 fill:#ff9800
    style PAGE fill:#f44336
```

---

## 📋 Visual Summary Checklist

### Architecture Understanding
- [ ] Three pillars of observability (metrics, logs, traces)
- [ ] Docker logging drivers and aggregation
- [ ] Metrics collection and time-series databases
- [ ] Distributed tracing and correlation

### Infrastructure Components
- [ ] Prometheus metrics architecture
- [ ] Grafana visualization layers
- [ ] Loki log aggregation
- [ ] Jaeger/Tempo tracing systems

### Integration Patterns
- [ ] Data correlation strategies
- [ ] Context propagation methods
- [ ] Alert routing and escalation
- [ ] SLI/SLO monitoring frameworks

### Operational Excellence
- [ ] Performance monitoring dashboards
- [ ] Incident response workflows
- [ ] Error budget management
- [ ] Automation and self-healing

---

💡 **Visual Learning Success**: These diagrams provide comprehensive understanding of Docker observability architectures, from basic logging setups to complete production-ready monitoring stacks with metrics, logs, traces, and alerting.