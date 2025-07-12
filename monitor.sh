#!/bin/bash
# monitor.sh - GitLab system monitoring script with backup trigger support

LOG_FILE="/Users/shinlab/Desktop/gitlab-backup/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_REQUEST_FILE="/Users/shinlab/Desktop/gitlab-onprem/backup/backup_request.json"

echo "[$DATE] Starting system health check..." >> "$LOG_FILE"

# バックアップリクエストをチェック
if [ -f "$BACKUP_REQUEST_FILE" ]; then
    echo "[$DATE] Backup request detected. Processing..." >> "$LOG_FILE"
    
    # バックアップリクエストの内容を読み取り
    PROJECT_NAME=$(jq -r '.project' "$BACKUP_REQUEST_FILE" 2>/dev/null || echo "unknown")
    BRANCH=$(jq -r '.branch' "$BACKUP_REQUEST_FILE" 2>/dev/null || echo "unknown")
    
    echo "[$DATE] Executing backup for project: $PROJECT_NAME, branch: $BRANCH" >> "$LOG_FILE"
    
    # バックアップを実行
    cd /Users/shinlab/Desktop/gitlab-onprem
    ./backup/backup.sh >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$DATE] Backup completed successfully for $PROJECT_NAME" >> "$LOG_FILE"
    else
        echo "[$DATE] Backup failed for $PROJECT_NAME" >> "$LOG_FILE"
    fi
    
    # バックアップリクエストファイルを削除
    rm -f "$BACKUP_REQUEST_FILE"
    echo "[$DATE] Backup request processed and removed." >> "$LOG_FILE"
fi

# サービスの状態をチェック
services=("gitlab" "prometheus" "grafana" "gitlab-webhook")
all_healthy=true

for service in "${services[@]}"; do
    status=$(docker-compose ps -q $service 2>/dev/null)
    if [ -n "$status" ]; then
        health=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null)
        if [ "$health" = "healthy" ] || [ "$health" = "" ]; then
            echo "[$DATE] $service: OK" >> "$LOG_FILE"
        else
            echo "[$DATE] $service: UNHEALTHY" >> "$LOG_FILE"
            all_healthy=false
        fi
    else
        echo "[$DATE] $service: NOT RUNNING" >> "$LOG_FILE"
        all_healthy=false
    fi
done

# 全サービスが正常でない場合は再起動
if [ "$all_healthy" = false ]; then
    echo "[$DATE] Unhealthy services detected. Restarting..." >> "$LOG_FILE"
    cd /Users/shinlab/Desktop/gitlab-onprem
    docker-compose restart
    echo "[$DATE] System restart completed." >> "$LOG_FILE"
else
    echo "[$DATE] All services are healthy." >> "$LOG_FILE"
fi

# ディスク使用量チェック
disk_usage=$(df -h /Users/shinlab/Desktop/gitlab-backup | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 80 ]; then
    echo "[$DATE] WARNING: Disk usage is $disk_usage%" >> "$LOG_FILE"
fi

echo "[$DATE] Health check completed." >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE" 