#!/bin/bash
# backup.sh - Enhanced GitLab backup script

# ログ設定
LOG_FILE="/Users/shinlab/Desktop/gitlab-backup/backup.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "======================================"
echo "GitLab Backup Started: $(date)"
echo "======================================"

# 変数設定
timestamp=$(date +%Y%m%d_%H%M%S)
backupFolder="/Users/shinlab/Desktop/gitlab-backup/$timestamp"
baseDir="/Users/shinlab/Desktop/gitlab-backup"

# バックアップディレクトリ作成
echo "Creating backup directory: $backupFolder"
mkdir -p "$backupFolder"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create backup directory"
    exit 1
fi

# GitLab 全体バックアップ作成 (リポジトリ含む)
echo "Creating GitLab backup..."
docker exec gitlab gitlab-backup create STRATEGY=copy

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create GitLab backup"
    exit 1
fi

echo "GitLab backup created successfully"

# バックアップファイルを外部フォルダにコピー
echo "Copying backup files to external folder..."
docker cp gitlab:/var/opt/gitlab/backups "$backupFolder"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy backup files"
    exit 1
fi

# 設定ファイルをコピー
echo "Copying configuration files..."
docker cp gitlab:/etc/gitlab "$backupFolder/etc-gitlab"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy configuration files"
    exit 1
fi

# バックアップの検証
echo "Verifying backup..."
if [ -d "$backupFolder/backups" ] && [ -d "$backupFolder/etc-gitlab" ]; then
    backupSize=$(du -sh "$backupFolder" | cut -f1)
    echo "Backup verification successful. Size: $backupSize"
else
    echo "ERROR: Backup verification failed"
    exit 1
fi

# 古いバックアップを削除（7日以上前のもの）
echo "Cleaning up old backups..."
find "$baseDir" -maxdepth 1 -type d -name "20*" -mtime +7 -exec rm -rf {} \;

if [ $? -eq 0 ]; then
    echo "Old backups cleaned up successfully"
else
    echo "WARNING: Failed to clean up old backups"
fi

echo "======================================"
echo "GitLab Backup Completed: $(date)"
echo "Backup location: $backupFolder"
echo "======================================"

exit 0 