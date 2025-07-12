#!/bin/bash

# GitLab システム状態確認スクリプト

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 GitLab On-Premises システム状態${NC}"
echo "=================================================="
echo ""

# Docker サービス状態
echo -e "${BLUE}📦 Docker サービス状態${NC}"
echo "--------------------------------------------------"
docker-compose ps
echo ""

# サービス個別チェック
echo -e "${BLUE}🏥 サービス健康状態${NC}"
echo "--------------------------------------------------"

services=("gitlab" "prometheus" "grafana" "gitlab-webhook")

for service in "${services[@]}"; do
    status=$(docker-compose ps -q $service 2>/dev/null)
    if [ -n "$status" ]; then
        health=$(docker inspect --format='{{.State.Health.Status}}' $service 2>/dev/null)
        if [ "$health" = "healthy" ] || [ "$health" = "" ]; then
            echo -e "${GREEN}✅ $service: 正常${NC}"
        else
            echo -e "${RED}❌ $service: 異常 ($health)${NC}"
        fi
    else
        echo -e "${RED}❌ $service: 停止中${NC}"
    fi
done
echo ""

# アクセス確認
echo -e "${BLUE}🌐 アクセス確認${NC}"
echo "--------------------------------------------------"

# GitLab
if curl -f -s http://localhost:8001/users/sign_in > /dev/null 2>&1; then
    echo -e "${GREEN}✅ GitLab (http://localhost:8001): アクセス可能${NC}"
else
    echo -e "${RED}❌ GitLab (http://localhost:8001): アクセス不可${NC}"
fi

# Grafana
if curl -f -s http://localhost:8000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Grafana (http://localhost:8000): アクセス可能${NC}"
else
    echo -e "${RED}❌ Grafana (http://localhost:8000): アクセス不可${NC}"
fi

# Prometheus
if curl -f -s http://localhost:8002 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Prometheus (http://localhost:8002): アクセス可能${NC}"
else
    echo -e "${RED}❌ Prometheus (http://localhost:8002): アクセス不可${NC}"
fi

# WebHook
if curl -f -s http://localhost:9000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ WebHook (http://localhost:9000): アクセス可能${NC}"
else
    echo -e "${RED}❌ WebHook (http://localhost:9000): アクセス不可${NC}"
fi
echo ""

# ディスク使用量
echo -e "${BLUE}💾 ディスク使用量${NC}"
echo "--------------------------------------------------"
BACKUP_DIR="/Users/$(whoami)/Desktop/gitlab-backup"
if [ -d "$BACKUP_DIR" ]; then
    disk_usage=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        echo -e "${RED}⚠️  バックアップディスク使用量: $disk_usage% (警告レベル)${NC}"
    else
        echo -e "${GREEN}✅ バックアップディスク使用量: $disk_usage%${NC}"
    fi
    
    backup_count=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | wc -l | tr -d ' ')
    echo -e "📁 バックアップ数: $backup_count 個"
    
    if [ "$backup_count" -gt 0 ]; then
        latest_backup=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort | tail -1 | xargs basename)
        echo -e "📅 最新バックアップ: $latest_backup"
    fi
else
    echo -e "${YELLOW}⚠️  バックアップディレクトリが見つかりません${NC}"
fi
echo ""

# 監視設定確認
echo -e "${BLUE}⏰ 監視設定${NC}"
echo "--------------------------------------------------"
if crontab -l 2>/dev/null | grep -q "monitor.sh"; then
    echo -e "${GREEN}✅ 自動監視: 有効 (5分間隔)${NC}"
else
    echo -e "${YELLOW}⚠️  自動監視: 未設定${NC}"
fi
echo ""

# 最近のログ
echo -e "${BLUE}📋 最近の監視ログ (最新5行)${NC}"
echo "--------------------------------------------------"
if [ -f "$BACKUP_DIR/monitor.log" ]; then
    tail -5 "$BACKUP_DIR/monitor.log"
else
    echo "監視ログが見つかりません"
fi
echo ""

echo "=================================================="
echo -e "${CYAN}💡 詳細情報は以下のコマンドで確認できます:${NC}"
echo "  ログ確認: tail -f $BACKUP_DIR/monitor.log"
echo "  手動監視: ./monitor.sh"
echo "  手動バックアップ: ./backup/backup.sh"
echo "==================================================" 