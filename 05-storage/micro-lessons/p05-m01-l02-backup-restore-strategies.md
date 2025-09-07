# p05-m01-l02: Backup and Restore Strategies

> **Duration**: 5 minutes | **Anchor**: `p05-m01-l02` | **Type**: Hands-on + Strategy

## 🎯 Learning Objective

Master production-ready backup and restore procedures for Docker volumes, including automated strategies, disaster recovery planning, and data integrity verification.

## 📦 Backup Strategy Framework

### The 3-2-1 Backup Rule for Docker
- **3** copies of important data
- **2** different storage media types
- **1** offsite/cloud backup

```bash
# Production backup implementation
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PRIMARY   │───▶│    LOCAL    │───▶│   OFFSITE   │
│  Volume     │    │   Backup    │    │  (S3/NFS)   │
│   (Live)    │    │ (Secondary) │    │ (Tertiary)  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## 🔄 Core Backup Patterns

### Pattern 1: Live Backup (Zero Downtime)

```bash
# Backup running volume without stopping container
backup_live_volume() {
    local volume_name=$1
    local backup_name="${volume_name}-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    echo "Creating live backup of $volume_name..."
    docker run --rm \
        -v $volume_name:/data:ro \
        -v $(pwd)/backups:/backup \
        alpine tar czf /backup/$backup_name -C /data .
    
    echo "✅ Backup created: $backup_name"
    return $?
}

# Usage example
docker volume create app-data
docker run -d --name webapp -v app-data:/app/data nginx

# Create live backup while container runs
mkdir -p backups
backup_live_volume app-data
```

### Pattern 2: Consistent Snapshot (Application-Aware)

```bash
# Database backup with consistency
backup_database() {
    local container_name=$1
    local backup_dir=$2
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    echo "Creating consistent database backup..."
    
    # Application-level backup (SQL dump)
    docker exec $container_name pg_dump -U postgres mydb \
        > "$backup_dir/db-dump-$timestamp.sql"
    
    # Volume-level backup (binary)
    docker run --rm \
        -v $(docker inspect $container_name --format='{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}'):/data:ro \
        -v $backup_dir:/backup \
        alpine tar czf /backup/db-volume-$timestamp.tar.gz -C /data .
    
    echo "✅ Consistent backup completed: db-dump-$timestamp.sql + db-volume-$timestamp.tar.gz"
}
```

### Pattern 3: Automated Scheduled Backup

```bash
# Production backup automation script
cat > backup-automation.sh << 'EOF'
#!/bin/bash

# Configuration
BACKUP_DIR="/backup/docker-volumes"
RETENTION_DAYS=30
LOG_FILE="/var/log/docker-backup.log"
VOLUMES_TO_BACKUP=("app-data" "postgres-data" "config-data")

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Backup function with error handling
backup_volume_safe() {
    local volume=$1
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/${volume}-${timestamp}.tar.gz"
    
    log "Starting backup of volume: $volume"
    
    if docker run --rm \
        -v $volume:/data:ro \
        -v $BACKUP_DIR:/backup \
        alpine tar czf /backup/$(basename $backup_file) -C /data . 2>/dev/null; then
        
        # Verify backup integrity
        if tar -tzf "$backup_file" > /dev/null 2>&1; then
            log "✅ Backup successful: $backup_file"
            echo $backup_file  # Return backup path for cleanup
        else
            log "❌ Backup corrupted: $backup_file"
            rm -f "$backup_file"
            return 1
        fi
    else
        log "❌ Backup failed for volume: $volume"
        return 1
    fi
}

# Main backup process
main() {
    log "=== Docker Volume Backup Started ==="
    
    local backup_count=0
    local success_count=0
    
    for volume in "${VOLUMES_TO_BACKUP[@]}"; do
        if docker volume inspect $volume >/dev/null 2>&1; then
            backup_count=$((backup_count + 1))
            if backup_volume_safe $volume; then
                success_count=$((success_count + 1))
            fi
        else
            log "⚠️ Volume not found: $volume"
        fi
    done
    
    # Cleanup old backups
    find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    log "🧹 Cleaned up backups older than $RETENTION_DAYS days"
    
    log "=== Backup Summary: $success_count/$backup_count successful ==="
}

# Execute main function
main
EOF

chmod +x backup-automation.sh

# Add to crontab for daily execution
echo "0 2 * * * /path/to/backup-automation.sh" | crontab -
```

## ⚡ Live Backup Demo (2 minutes)

```bash
echo "=== Live Backup Demonstration ==="

# 1. Setup test environment
docker volume create demo-data
docker run -d --name demo-app \
  -v demo-data:/app/data \
  alpine sh -c '
    while true; do
      echo "$(date): Application data" >> /app/data/app.log
      sleep 2
    done
  '

echo "Demo app writing continuous data..."
sleep 5

# 2. Create backup while app is running
mkdir -p demo-backups
echo "Creating backup while application runs..."

docker run --rm \
  -v demo-data:/source:ro \
  -v $(pwd)/demo-backups:/backup \
  alpine tar czf /backup/demo-live-backup.tar.gz -C /source .

# 3. Verify backup contents
echo "=== Backup Contents ==="
tar -tzf demo-backups/demo-live-backup.tar.gz

echo "=== Live data continues ==="
docker exec demo-app tail -3 /app/data/app.log

# 4. Cleanup
docker stop demo-app
docker rm demo-app
docker volume rm demo-data
rm -rf demo-backups

echo "✅ Live backup demonstration completed"
```

## 🔄 Disaster Recovery Procedures

### Complete Disaster Recovery Workflow

```bash
# Disaster Recovery Script
disaster_recovery() {
    local backup_file=$1
    local volume_name=$2
    local container_name=$3
    local container_image=$4
    
    echo "🚨 DISASTER RECOVERY INITIATED"
    echo "Backup: $backup_file"
    echo "Target Volume: $volume_name"
    echo "Target Container: $container_name"
    
    # Step 1: Verify backup integrity
    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
        echo "❌ CRITICAL: Backup file corrupted - $backup_file"
        return 1
    fi
    echo "✅ Backup integrity verified"
    
    # Step 2: Stop existing container if running
    if docker ps -q -f name=$container_name | grep -q .; then
        echo "Stopping existing container..."
        docker stop $container_name
        docker rm $container_name
    fi
    
    # Step 3: Remove damaged volume
    if docker volume inspect $volume_name >/dev/null 2>&1; then
        echo "Removing damaged volume..."
        docker volume rm $volume_name
    fi
    
    # Step 4: Create new volume
    echo "Creating new volume..."
    docker volume create $volume_name
    
    # Step 5: Restore data from backup
    echo "Restoring data from backup..."
    docker run --rm \
        -v $volume_name:/target \
        -v $(dirname $backup_file):/backup \
        alpine tar xzf /backup/$(basename $backup_file) -C /target
    
    # Step 6: Start new container with restored data
    echo "Starting container with restored data..."
    docker run -d --name $container_name \
        -v $volume_name:/app/data \
        $container_image
    
    # Step 7: Verify recovery
    echo "Verifying recovery..."
    sleep 5
    if docker ps -q -f name=$container_name | grep -q .; then
        echo "✅ RECOVERY SUCCESSFUL"
        echo "Container $container_name is running with restored data"
        return 0
    else
        echo "❌ RECOVERY FAILED - Container not running"
        return 1
    fi
}

# Example usage
# disaster_recovery "/backup/app-data-20231201-120000.tar.gz" "app-data" "webapp" "nginx:alpine"
```

### Recovery Testing Protocol

```bash
# Backup Testing and Validation
test_backup_recovery() {
    local backup_file=$1
    local test_volume="test-recovery-$(date +%s)"
    
    echo "=== Testing Backup Recovery ==="
    echo "Backup file: $backup_file"
    
    # Create test volume and restore
    docker volume create $test_volume
    
    if docker run --rm \
        -v $test_volume:/target \
        -v $(dirname $backup_file):/backup \
        alpine tar xzf /backup/$(basename $backup_file) -C /target; then
        
        echo "✅ Restore successful"
        
        # Verify data integrity
        local file_count=$(docker run --rm -v $test_volume:/check alpine find /check -type f | wc -l)
        echo "Files restored: $file_count"
        
        # Cleanup test volume
        docker volume rm $test_volume
        
        echo "✅ Backup validation complete"
        return 0
    else
        echo "❌ Restore failed"
        docker volume rm $test_volume 2>/dev/null
        return 1
    fi
}

# Test all recent backups
for backup in backups/*.tar.gz; do
    test_backup_recovery "$backup"
done
```

## 🔒 Security-Aware Backup Patterns

### Encrypted Backup Strategy

```bash
# Encrypted backup with GPG
backup_encrypted() {
    local volume_name=$1
    local recipient="backup@company.com"
    local backup_dir="./encrypted-backups"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    mkdir -p $backup_dir
    
    echo "Creating encrypted backup of $volume_name..."
    
    # Create and encrypt backup in one step
    docker run --rm \
        -v $volume_name:/data:ro \
        -v $backup_dir:/backup \
        alpine sh -c '
            tar cz -C /data . | gpg --cipher-algo AES256 --compress-algo 1 --recipient '$recipient' --encrypt > /backup/'$volume_name'-'$timestamp'.tar.gz.gpg
        '
    
    echo "✅ Encrypted backup created: $volume_name-$timestamp.tar.gz.gpg"
}

# Decrypt and restore
restore_encrypted() {
    local encrypted_backup=$1
    local volume_name=$2
    
    echo "Restoring from encrypted backup..."
    
    docker volume create $volume_name
    
    # Decrypt and restore in one step
    docker run --rm \
        -v $volume_name:/target \
        -v $(dirname $encrypted_backup):/backup \
        alpine sh -c '
            gpg --decrypt /backup/'$(basename $encrypted_backup)' | tar xz -C /target
        '
    
    echo "✅ Encrypted backup restored to $volume_name"
}
```

### Database-Specific Backup Patterns

```bash
# PostgreSQL consistent backup
backup_postgres() {
    local container_name=$1
    local backup_dir=$2
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    mkdir -p $backup_dir
    
    # SQL dump (logical backup)
    docker exec $container_name pg_dumpall -U postgres \
        > "$backup_dir/postgres-dump-$timestamp.sql"
    
    # Volume backup (physical backup)
    local volume_name=$(docker inspect $container_name \
        --format='{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}')
    
    docker run --rm \
        -v $volume_name:/data:ro \
        -v $backup_dir:/backup \
        alpine tar czf /backup/postgres-volume-$timestamp.tar.gz -C /data .
    
    echo "✅ PostgreSQL backup completed:"
    echo "  - SQL dump: postgres-dump-$timestamp.sql"
    echo "  - Volume backup: postgres-volume-$timestamp.tar.gz"
}

# MySQL consistent backup
backup_mysql() {
    local container_name=$1
    local backup_dir=$2
    local mysql_root_password=$3
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    mkdir -p $backup_dir
    
    # Create SQL dump
    docker exec $container_name mysqldump -u root -p$mysql_root_password --all-databases \
        > "$backup_dir/mysql-dump-$timestamp.sql"
    
    echo "✅ MySQL backup completed: mysql-dump-$timestamp.sql"
}
```

## 📊 Backup Monitoring and Reporting

```bash
# Backup health monitoring
monitor_backup_health() {
    local backup_dir=$1
    local report_file="backup-health-report.txt"
    
    echo "=== Docker Backup Health Report ===" > $report_file
    echo "Generated: $(date)" >> $report_file
    echo "" >> $report_file
    
    # Check backup directory
    if [ -d "$backup_dir" ]; then
        local backup_count=$(find $backup_dir -name "*.tar.gz" | wc -l)
        local latest_backup=$(find $backup_dir -name "*.tar.gz" -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        local latest_age=$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 3600 ))
        
        echo "Backup Directory: $backup_dir" >> $report_file
        echo "Total Backups: $backup_count" >> $report_file
        echo "Latest Backup: $(basename "$latest_backup")" >> $report_file
        echo "Latest Backup Age: ${latest_age} hours" >> $report_file
        
        # Health assessment
        if [ $latest_age -lt 25 ]; then
            echo "Status: ✅ HEALTHY (backups current)" >> $report_file
        elif [ $latest_age -lt 48 ]; then
            echo "Status: ⚠️ WARNING (backups aging)" >> $report_file
        else
            echo "Status: ❌ CRITICAL (backups stale)" >> $report_file
        fi
        
    else
        echo "Status: ❌ CRITICAL (backup directory missing)" >> $report_file
    fi
    
    # Display report
    cat $report_file
}
```

## 🔗 Key Backup Principles

1. **Automate Everything**: Manual backups will be forgotten
2. **Test Restores Regularly**: Untested backups are unreliable
3. **Encrypt Sensitive Data**: Protect data at rest and in transit
4. **Multiple Storage Locations**: Local + remote redundancy
5. **Monitor Backup Health**: Alert on backup failures
6. **Document Recovery Procedures**: Clear step-by-step guides
7. **Practice Disaster Recovery**: Regular recovery drills

## 🚨 Common Backup Anti-Patterns

❌ **Untested backups**
```bash
# Creating backups without testing restore
backup_volume app-data  # Hope it works!
```

✅ **Validated backup process**
```bash
backup_volume app-data
test_backup_recovery backups/app-data-latest.tar.gz
```

❌ **Single backup location**
```bash
# Only local backups - single point of failure
docker run --rm -v app-data:/data -v ./backups:/backup alpine tar czf /backup/app.tar.gz -C /data .
```

✅ **Multi-location backup strategy**
```bash
# Local + remote backup
backup_volume app-data
aws s3 cp backups/app-data-latest.tar.gz s3://company-backups/
```

---

**Next**: Permission Handling and Security (`p05-m01-l03`)