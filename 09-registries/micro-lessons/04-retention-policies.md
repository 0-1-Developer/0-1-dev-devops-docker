# Micro-Lesson 04: Registry Retention Policies and Lifecycle Management

> **Anchor**: `p09-m01-l04`  
> **Duration**: 4 minutes  
> **One Key Idea**: Master automated registry retention policies and lifecycle management to optimize storage usage, ensure compliance, and maintain registry performance through intelligent cleanup strategies

## Why It Matters

Registry storage grows rapidly with continuous deployments, leading to increased costs and performance degradation. Without proper lifecycle management, registries become cluttered with unused images, consuming valuable resources. Retention policies enable automated cleanup, cost optimization, and compliance with data retention requirements while maintaining operational efficiency.

## What to Learn

Master registry lifecycle management:
- **Retention policy design** - Age-based and count-based cleanup strategies
- **Automated garbage collection** - Storage reclamation and optimization
- **Policy implementation** - Harbor policies, custom scripts, and CI/CD integration
- **Compliance management** - Audit trails and regulatory requirements

## Basic Retention Policies

### Age-Based Retention
```bash
#!/bin/bash
# age-based-cleanup.sh

REGISTRY_URL="https://registry.local:5000"
RETENTION_DAYS=30
DRY_RUN=false

echo "🗑️  Age-based Registry Cleanup"
echo "============================="

# Get all repositories
repos=$(curl -sk "$REGISTRY_URL/v2/_catalog" | jq -r '.repositories[]')

for repo in $repos; do
    echo "Processing repository: $repo"
    
    # Get all tags
    tags=$(curl -sk "$REGISTRY_URL/v2/$repo/tags/list" | jq -r '.tags[]')
    
    for tag in $tags; do
        # Get image creation date
        manifest=$(curl -sk -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            "$REGISTRY_URL/v2/$repo/manifests/$tag")
        
        config_digest=$(echo "$manifest" | jq -r '.config.digest')
        config=$(curl -sk "$REGISTRY_URL/v2/$repo/blobs/$config_digest")
        created=$(echo "$config" | jq -r '.created')
        
        # Calculate age in days
        created_timestamp=$(date -d "$created" +%s)
        current_timestamp=$(date +%s)
        age_days=$(( (current_timestamp - created_timestamp) / 86400 ))
        
        if [ $age_days -gt $RETENTION_DAYS ]; then
            echo "  Tag $tag is $age_days days old (> $RETENTION_DAYS days)"
            
            if [ "$DRY_RUN" = false ]; then
                # Delete the tag
                curl -sk -X DELETE "$REGISTRY_URL/v2/$repo/manifests/$tag"
                echo "  ✅ Deleted $repo:$tag"
            else
                echo "  🔍 Would delete $repo:$tag (dry run)"
            fi
        fi
    done
done

echo "Age-based cleanup completed"
```

### Count-Based Retention
```bash
#!/bin/bash
# count-based-cleanup.sh

REGISTRY_URL="https://registry.local:5000"
MAX_TAGS_PER_REPO=5

echo "📦 Count-based Registry Cleanup"
echo "==============================="

# Get all repositories
repos=$(curl -sk "$REGISTRY_URL/v2/_catalog" | jq -r '.repositories[]')

for repo in $repos; do
    echo "Processing repository: $repo"
    
    # Get tags with creation timestamps
    tags=$(curl -sk "$REGISTRY_URL/v2/$repo/tags/list" | jq -r '.tags[]')
    
    # Create temporary file for tag timestamps
    temp_file=$(mktemp)
    
    for tag in $tags; do
        manifest=$(curl -sk -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
            "$REGISTRY_URL/v2/$repo/manifests/$tag")
        
        config_digest=$(echo "$manifest" | jq -r '.config.digest')
        config=$(curl -sk "$REGISTRY_URL/v2/$repo/blobs/$config_digest")
        created=$(echo "$config" | jq -r '.created')
        
        echo "$created $tag" >> "$temp_file"
    done
    
    # Sort by creation time (newest first) and skip the newest N tags
    tags_to_delete=$(sort -r "$temp_file" | tail -n +$((MAX_TAGS_PER_REPO + 1)) | awk '{print $2}')
    
    for tag in $tags_to_delete; do
        echo "  Deleting old tag: $repo:$tag"
        curl -sk -X DELETE "$REGISTRY_URL/v2/$repo/manifests/$tag"
    done
    
    rm "$temp_file"
done

echo "Count-based cleanup completed"
```

## Harbor Retention Policies

### Harbor Policy Configuration
```json
{
  "rules": [
    {
      "id": 1,
      "priority": 1,
      "disabled": false,
      "action": "retain",
      "template": "latestPushedK",
      "params": {
        "latestPushedK": 10
      },
      "tag_selectors": [
        {
          "kind": "doublestar",
          "decoration": "matches",
          "pattern": "release-**"
        }
      ],
      "scope_selectors": {
        "repository": [
          {
            "kind": "doublestar",
            "decoration": "matches", 
            "pattern": "**"
          }
        ]
      }
    },
    {
      "id": 2,
      "priority": 2,
      "disabled": false,
      "action": "retain",
      "template": "nDaysAfter",
      "params": {
        "nDaysAfter": 30
      },
      "tag_selectors": [
        {
          "kind": "doublestar",
          "decoration": "matches",
          "pattern": "dev-**"
        }
      ],
      "scope_selectors": {
        "repository": [
          {
            "kind": "doublestar",
            "decoration": "matches",
            "pattern": "myproject/**"
          }
        ]
      }
    }
  ],
  "algorithm": "or",
  "trigger": {
    "kind": "Schedule",
    "settings": {
      "cron": "0 2 * * *"
    }
  }
}
```

### Harbor API Retention Management
```bash
#!/bin/bash
# harbor-retention-management.sh

HARBOR_URL="https://harbor.local"
HARBOR_USER="admin"
HARBOR_PASS="Harbor12345"
PROJECT_NAME="myproject"

echo "🚢 Harbor Retention Policy Management"
echo "===================================="

# Get authentication token
TOKEN=$(curl -sk -X POST "$HARBOR_URL/c/login" \
    -H "Content-Type: application/json" \
    -d "{\"principal\":\"$HARBOR_USER\",\"password\":\"$HARBOR_PASS\"}" \
    | jq -r '.token // empty')

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to authenticate with Harbor"
    exit 1
fi

# Create retention policy
POLICY_JSON='{
  "algorithm": "or",
  "rules": [
    {
      "action": "retain",
      "disabled": false,
      "params": {"nDaysAfter": 7},
      "priority": 1,
      "scope_selectors": {
        "repository": [
          {"decoration": "matches", "kind": "doublestar", "pattern": "**"}
        ]
      },
      "tag_selectors": [
        {"decoration": "matches", "kind": "doublestar", "pattern": "dev-**"}
      ],
      "template": "nDaysAfter"
    }
  ],
  "trigger": {
    "kind": "Schedule",
    "settings": {"cron": "0 2 * * 6"}
  }
}'

# Apply retention policy to project
curl -sk -X POST "$HARBOR_URL/api/v2.0/projects/$PROJECT_NAME/repositories/retention" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$POLICY_JSON"

echo "✅ Retention policy applied to project $PROJECT_NAME"

# Execute retention policy immediately
curl -sk -X POST "$HARBOR_URL/api/v2.0/projects/$PROJECT_NAME/repositories/retention/executions" \
    -H "Authorization: Bearer $TOKEN"

echo "🚀 Retention policy execution triggered"
```

## Advanced Lifecycle Strategies

### Multi-Environment Retention
```yaml
# retention-policies.yml
environments:
  development:
    max_tags: 3
    max_age_days: 7
    patterns:
      - "dev-*"
      - "feature-*"
      - "pr-*"
  
  staging:
    max_tags: 5
    max_age_days: 30
    patterns:
      - "staging-*"
      - "test-*"
      - "rc-*"
  
  production:
    max_tags: 10
    max_age_days: 365
    patterns:
      - "v*"
      - "release-*"
      - "stable-*"
    
  archives:
    max_age_days: 2555  # 7 years
    patterns:
      - "archive-*"
      - "backup-*"

# Special retention rules
special_rules:
  security_patches:
    never_delete: true
    patterns:
      - "*-security-*"
      - "*-hotfix-*"
  
  latest_releases:
    keep_minimum: 3
    patterns:
      - "latest"
      - "*-stable"
```

### Intelligent Retention Script
```python
#!/usr/bin/env python3
# intelligent-retention.py

import re
import json
import requests
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Dict

@dataclass
class RetentionRule:
    pattern: str
    max_tags: int = None
    max_age_days: int = None
    never_delete: bool = False
    keep_minimum: int = 1

class IntelligentRetention:
    def __init__(self, registry_url: str, config_file: str):
        self.registry_url = registry_url
        self.config = self.load_config(config_file)
        
    def load_config(self, config_file: str) -> Dict:
        with open(config_file) as f:
            return json.load(f)
    
    def get_repositories(self) -> List[str]:
        response = requests.get(f"{self.registry_url}/v2/_catalog")
        return response.json().get('repositories', [])
    
    def get_tags_with_metadata(self, repo: str) -> List[Dict]:
        tags_response = requests.get(f"{self.registry_url}/v2/{repo}/tags/list")
        tags = tags_response.json().get('tags', [])
        
        tag_metadata = []
        for tag in tags:
            manifest_response = requests.get(
                f"{self.registry_url}/v2/{repo}/manifests/{tag}",
                headers={"Accept": "application/vnd.docker.distribution.manifest.v2+json"}
            )
            manifest = manifest_response.json()
            
            config_response = requests.get(
                f"{self.registry_url}/v2/{repo}/blobs/{manifest['config']['digest']}"
            )
            config = config_response.json()
            
            tag_metadata.append({
                'tag': tag,
                'created': config.get('created'),
                'size': sum(layer['size'] for layer in manifest.get('layers', [])),
                'digest': manifest_response.headers.get('Docker-Content-Digest')
            })
        
        return sorted(tag_metadata, key=lambda x: x['created'], reverse=True)
    
    def apply_retention_rules(self, repo: str, tags: List[Dict]) -> List[str]:
        """Apply retention rules and return list of tags to delete"""
        to_delete = []
        
        for env, rules in self.config['environments'].items():
            env_tags = [t for t in tags if self.matches_patterns(t['tag'], rules['patterns'])]
            
            if not env_tags:
                continue
            
            # Apply count-based retention
            if rules.get('max_tags') and len(env_tags) > rules['max_tags']:
                to_delete.extend([t['tag'] for t in env_tags[rules['max_tags']:]])
            
            # Apply age-based retention
            if rules.get('max_age_days'):
                cutoff_date = datetime.now() - timedelta(days=rules['max_age_days'])
                for tag_info in env_tags:
                    if datetime.fromisoformat(tag_info['created'].rstrip('Z')) < cutoff_date:
                        to_delete.append(tag_info['tag'])
        
        # Apply special rules
        for rule_name, rule_config in self.config.get('special_rules', {}).items():
            special_tags = [t for t in tags if self.matches_patterns(t['tag'], rule_config['patterns'])]
            
            if rule_config.get('never_delete'):
                to_delete = [t for t in to_delete if t not in [st['tag'] for st in special_tags]]
            
            if rule_config.get('keep_minimum'):
                protected_tags = [t['tag'] for t in special_tags[:rule_config['keep_minimum']]]
                to_delete = [t for t in to_delete if t not in protected_tags]
        
        return list(set(to_delete))
    
    def matches_patterns(self, tag: str, patterns: List[str]) -> bool:
        for pattern in patterns:
            if re.match(pattern.replace('*', '.*'), tag):
                return True
        return False
    
    def delete_tags(self, repo: str, tags_to_delete: List[str], dry_run: bool = True):
        for tag in tags_to_delete:
            if dry_run:
                print(f"Would delete: {repo}:{tag}")
            else:
                response = requests.delete(f"{self.registry_url}/v2/{repo}/manifests/{tag}")
                if response.status_code == 202:
                    print(f"✅ Deleted: {repo}:{tag}")
                else:
                    print(f"❌ Failed to delete: {repo}:{tag}")

def main():
    retention = IntelligentRetention("https://registry.local:5000", "retention-policies.json")
    
    for repo in retention.get_repositories():
        print(f"\n📦 Processing repository: {repo}")
        
        tags = retention.get_tags_with_metadata(repo)
        tags_to_delete = retention.apply_retention_rules(repo, tags)
        
        if tags_to_delete:
            print(f"Found {len(tags_to_delete)} tags to delete")
            retention.delete_tags(repo, tags_to_delete, dry_run=True)
        else:
            print("No tags to delete")

if __name__ == "__main__":
    main()
```

## Automated Garbage Collection

### Registry Garbage Collection
```bash
#!/bin/bash
# registry-garbage-collection.sh

REGISTRY_CONTAINER="registry-container"
CONFIG_PATH="/etc/docker/registry/config.yml"

echo "🗑️  Registry Garbage Collection"
echo "=============================="

# Step 1: Put registry in read-only mode
echo "1. Setting registry to read-only mode..."
docker exec "$REGISTRY_CONTAINER" \
    sed -i 's/readonly: false/readonly: true/' "$CONFIG_PATH"
docker restart "$REGISTRY_CONTAINER"

# Wait for registry to restart
sleep 10

# Step 2: Run garbage collection
echo "2. Running garbage collection..."
docker exec "$REGISTRY_CONTAINER" \
    registry garbage-collect "$CONFIG_PATH"

# Step 3: Remove read-only mode
echo "3. Restoring read-write mode..."
docker exec "$REGISTRY_CONTAINER" \
    sed -i 's/readonly: true/readonly: false/' "$CONFIG_PATH"
docker restart "$REGISTRY_CONTAINER"

# Step 4: Check storage reclaimed
echo "4. Storage analysis..."
STORAGE_USED=$(docker exec "$REGISTRY_CONTAINER" du -sh /var/lib/registry | cut -f1)
echo "Registry storage usage: $STORAGE_USED"

echo "✅ Garbage collection completed"
```

### Automated Cleanup Cron Job
```bash
# Create cleanup service
sudo tee /etc/systemd/system/registry-cleanup.service > /dev/null <<EOF
[Unit]
Description=Registry Cleanup Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/opt/registry/scripts/intelligent-cleanup.sh
User=registry
Group=registry

[Install]
WantedBy=multi-user.target
EOF

# Create cleanup timer
sudo tee /etc/systemd/system/registry-cleanup.timer > /dev/null <<EOF
[Unit]
Description=Registry Cleanup Timer
Requires=registry-cleanup.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF

# Enable and start timer
sudo systemctl daemon-reload
sudo systemctl enable registry-cleanup.timer
sudo systemctl start registry-cleanup.timer
```

## Compliance and Auditing

### Audit Trail Implementation
```bash
#!/bin/bash
# retention-audit.sh

AUDIT_LOG="/var/log/registry/retention-audit.log"
REGISTRY_URL="https://registry.local:5000"

log_action() {
    local action="$1"
    local repo="$2"
    local tag="$3"
    local reason="$4"
    
    echo "$(date -Iseconds) [RETENTION] $action $repo:$tag - $reason" >> "$AUDIT_LOG"
}

# Example retention action with audit logging
delete_with_audit() {
    local repo="$1"
    local tag="$2"
    local reason="$3"
    
    # Log before deletion
    log_action "DELETE_INITIATED" "$repo" "$tag" "$reason"
    
    # Perform deletion
    response=$(curl -sk -w "%{http_code}" -X DELETE "$REGISTRY_URL/v2/$repo/manifests/$tag")
    
    if [ "$response" = "202" ]; then
        log_action "DELETE_SUCCESS" "$repo" "$tag" "$reason"
        echo "✅ Successfully deleted $repo:$tag"
    else
        log_action "DELETE_FAILED" "$repo" "$tag" "HTTP $response"
        echo "❌ Failed to delete $repo:$tag (HTTP $response)"
    fi
}

# Generate compliance report
generate_compliance_report() {
    local start_date="$1"
    local end_date="$2"
    
    echo "Registry Retention Compliance Report"
    echo "==================================="
    echo "Period: $start_date to $end_date"
    echo ""
    
    # Count deletions by reason
    grep -E "\[$start_date.*\].*DELETE_SUCCESS" "$AUDIT_LOG" | \
    awk -F' - ' '{print $2}' | sort | uniq -c | \
    while read count reason; do
        echo "  $reason: $count deletions"
    done
    
    echo ""
    echo "Total storage reclaimed: $(calculate_storage_reclaimed "$start_date" "$end_date")"
}
```

### Compliance Verification
```python
#!/usr/bin/env python3
# compliance-checker.py

import json
import logging
from datetime import datetime, timedelta

class ComplianceChecker:
    def __init__(self, audit_log_path: str):
        self.audit_log_path = audit_log_path
        self.setup_logging()
    
    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def check_retention_compliance(self, days: int = 30) -> Dict:
        """Check if retention policies are being followed"""
        
        compliance_report = {
            'compliant': True,
            'violations': [],
            'recommendations': []
        }
        
        # Check for old images that should have been deleted
        cutoff_date = datetime.now() - timedelta(days=days)
        
        # Implementation would check registry for old images
        # and verify they were properly deleted according to policy
        
        return compliance_report
    
    def generate_retention_metrics(self) -> Dict:
        """Generate metrics for retention policy effectiveness"""
        
        metrics = {
            'images_deleted_last_30_days': 0,
            'storage_reclaimed_gb': 0,
            'policy_violations': 0,
            'average_retention_period': 0
        }
        
        # Parse audit logs to calculate metrics
        with open(self.audit_log_path) as f:
            for line in f:
                if 'DELETE_SUCCESS' in line:
                    metrics['images_deleted_last_30_days'] += 1
        
        return metrics

def main():
    checker = ComplianceChecker('/var/log/registry/retention-audit.log')
    
    # Check compliance
    compliance = checker.check_retention_compliance()
    print("Compliance Status:", "✅ Compliant" if compliance['compliant'] else "❌ Non-compliant")
    
    # Generate metrics
    metrics = checker.generate_retention_metrics()
    print(f"Images deleted (30 days): {metrics['images_deleted_last_30_days']}")

if __name__ == "__main__":
    main()
```

## Practice Tasks

1. **Implement age-based cleanup**:
   ```bash
   # Create script to delete images older than 30 days
   ```

2. **Setup Harbor retention**:
   ```bash
   # Configure Harbor retention policies via API
   ```

3. **Deploy garbage collection**:
   ```bash
   # Setup automated registry garbage collection
   ```

4. **Create compliance audit**:
   ```bash
   # Implement audit trail for retention actions
   ```

## Monitoring and Alerts

### Storage Monitoring
```bash
#!/bin/bash
# storage-monitor.sh

REGISTRY_PATH="/var/lib/registry"
THRESHOLD_GB=80
ALERT_EMAIL="admin@company.com"

CURRENT_SIZE_GB=$(du -s "$REGISTRY_PATH" | awk '{print $1/1024/1024}')

if (( $(echo "$CURRENT_SIZE_GB > $THRESHOLD_GB" | bc -l) )); then
    echo "Registry storage exceeded threshold: ${CURRENT_SIZE_GB}GB > ${THRESHOLD_GB}GB" | \
    mail -s "Registry Storage Alert" "$ALERT_EMAIL"
    
    # Trigger emergency cleanup
    /opt/registry/scripts/emergency-cleanup.sh
fi
```

## Key Takeaway

Registry retention policies and lifecycle management enable automated storage optimization, compliance adherence, and operational efficiency through intelligent cleanup strategies that balance resource conservation with availability requirements.