#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/srv/homelab/backups"
LOG_FILE="/var/log/docker-volume-backup.log"
RETENTION_DAYS=30
VOLUMES=("nextcloud_data" "portainer_data" "grafana_data" "prometheus_data")
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Backup function
backup_volume() {
    local volume_name=$1
    local backup_file="$BACKUP_DIR/${volume_name}_${DATE}.tar.gz"
    
    log "Starting backup of volume: $volume_name"
    
    # Check if volume exists
    if ! docker volume inspect "$volume_name" &>/dev/null; then
        log "ERROR: Volume $volume_name does not exist"
        return 1
    fi
    
    # Create backup
    docker run --rm \
        -v "$volume_name:/source:ro" \
        -v "$BACKUP_DIR:/backup" \
        alpine sh -c "
            cd /source && 
            tar czf /backup/${volume_name}_${DATE}.tar.gz . && 
            echo 'Backup size:' && 
            du -h /backup/${volume_name}_${DATE}.tar.gz
        "
    
    if [ $? -eq 0 ]; then
        log "SUCCESS: Backup completed for $volume_name"
        log "Backup file: $backup_file"
    else
        log "ERROR: Backup failed for $volume_name"
        return 1
    fi
}

# Restore function
restore_volume() {
    local volume_name=$1
    local backup_file=$2
    
    log "Starting restore of volume: $volume_name from $backup_file"
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        log "ERROR: Backup file $backup_file does not exist"
        return 1
    fi
    
    # Create volume if it doesn't exist
    docker volume create "$volume_name" &>/dev/null
    
    # Stop containers using this volume
    log "Stopping containers using volume $volume_name"
    docker ps --filter volume="$volume_name" -q | xargs -r docker stop
    
    # Restore backup
    docker run --rm \
        -v "$volume_name:/target" \
        -v "$(dirname $backup_file):/backup" \
        alpine sh -c "
            rm -rf /target/* /target/..?* /target/.[!.]* 2>/dev/null || true &&
            cd /target && 
            tar xzf /backup/$(basename $backup_file)
        "
    
    if [ $? -eq 0 ]; then
        log "SUCCESS: Restore completed for $volume_name"
    else
        log "ERROR: Restore failed for $volume_name"
        return 1
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days"
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    log "Cleanup completed"
}

# List backups
list_backups() {
    echo "Available backups in $BACKUP_DIR:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"
}

# Verify backup
verify_backup() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR: Backup file $backup_file does not exist"
        return 1
    fi
    
    log "Verifying backup: $backup_file"
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        log "SUCCESS: Backup verification passed"
        return 0
    else
        log "ERROR: Backup verification failed"
        return 1
    fi
}

# Main execution
case "$1" in
    backup)
        log "Starting backup process for all volumes"
        for volume in "${VOLUMES[@]}"; do
            backup_volume "$volume"
        done
        cleanup_old_backups
        log "Backup process completed"
        ;;
    backup-single)
        if [ -z "$2" ]; then
            echo "Usage: $0 backup-single <volume_name>"
            exit 1
        fi
        backup_volume "$2"
        ;;
    restore)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 restore <volume_name> <backup_file>"
            exit 1
        fi
        restore_volume "$2" "$3"
        ;;
    list)
        list_backups
        ;;
    verify)
        if [ -z "$2" ]; then
            echo "Usage: $0 verify <backup_file>"
            exit 1
        fi
        verify_backup "$2"
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    *)
        echo "Usage: $0 {backup|backup-single|restore|list|verify|cleanup}"
        echo ""
        echo "Commands:"
        echo "  backup              - Backup all configured volumes"
        echo "  backup-single <vol> - Backup single volume"
        echo "  restore <vol> <file>- Restore volume from backup"
        echo "  list                - List available backups"
        echo "  verify <file>       - Verify backup integrity"
        echo "  cleanup             - Remove old backups"
        echo ""
        echo "Examples:"
        echo "  $0 backup"
        echo "  $0 backup-single nextcloud_data"
        echo "  $0 restore nextcloud_data /path/to/backup.tar.gz"
        echo "  $0 list"
        exit 1
        ;;
esac 