#!/bin/bash

# GitLab On-Premises 自動バックアップ・復旧システム
# クイックセットアップスクリプト

set -e  # エラー時に停止

echo "🚀 GitLab On-Premises 自動バックアップ・復旧システム セットアップ開始"
echo "=================================================================="

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 進捗表示関数
print_step() {
    echo -e "${BLUE}[ステップ $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 前提条件チェック
print_step "1" "前提条件をチェックしています..."

# Docker チェック
if ! command -v docker &> /dev/null; then
    print_error "Docker がインストールされていません。Docker Desktop for Mac をインストールしてください。"
    echo "https://www.docker.com/products/docker-desktop"
    exit 1
fi
print_success "Docker が見つかりました"

# Docker Compose チェック
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose がインストールされていません。"
    exit 1
fi
print_success "Docker Compose が見つかりました"

# Docker が実行中かチェック
if ! docker info &> /dev/null; then
    print_error "Docker が実行されていません。Docker Desktop を起動してください。"
    exit 1
fi
print_success "Docker が実行中です"

# バックアップディレクトリ作成
print_step "2" "バックアップディレクトリを作成しています..."
BACKUP_DIR="/Users/$(whoami)/Desktop/gitlab-backup"
mkdir -p "$BACKUP_DIR"
print_success "バックアップディレクトリを作成しました: $BACKUP_DIR"

# スクリプト権限設定
print_step "3" "スクリプトに実行権限を付与しています..."
chmod +x backup/backup.sh
chmod +x monitor.sh
print_success "実行権限を設定しました"

# 既存のコンテナ確認
print_step "4" "既存のサービスを確認しています..."
if docker-compose ps | grep -q "Up"; then
    print_warning "既存のサービスが実行中です。停止してから再起動します。"
    docker-compose down
fi

# サービス起動
print_step "5" "GitLabサービスを起動しています..."
echo "これには数分かかる場合があります..."
docker-compose up -d

print_success "サービスを起動しました"

# サービス状態確認
print_step "6" "サービス状態を確認しています..."
sleep 10
docker-compose ps

# GitLab初期化待機
print_step "7" "GitLabの初期化を待機しています..."
echo "GitLabの完全な起動には3-5分かかる場合があります..."

for i in {1..30}; do
    if curl -f -s http://localhost:8001/users/sign_in > /dev/null 2>&1; then
        print_success "GitLabが正常に起動しました！"
        break
    fi
    echo -n "."
    sleep 10
done

# 自動監視設定
print_step "8" "自動監視を設定しています..."
CURRENT_DIR=$(pwd)
CRON_JOB="*/5 * * * * cd $CURRENT_DIR && ./monitor.sh"

# 既存のcrontabを確認
if crontab -l 2>/dev/null | grep -q "monitor.sh"; then
    print_warning "自動監視は既に設定されています"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    print_success "自動監視を設定しました（5分間隔）"
fi

# 初期パスワード取得
print_step "9" "GitLab初期パスワードを取得しています..."
sleep 5
if docker exec gitlab cat /etc/gitlab/initial_root_password 2>/dev/null | grep "Password:"; then
    GITLAB_PASSWORD=$(docker exec gitlab cat /etc/gitlab/initial_root_password 2>/dev/null | grep "Password:" | awk '{print $2}')
    print_success "GitLab初期パスワードを取得しました"
else
    print_warning "初期パスワードの取得に失敗しました。手動で確認してください。"
    GITLAB_PASSWORD="<手動で確認>"
fi

# セットアップ完了
echo ""
echo "=================================================================="
echo -e "${GREEN}🎉 セットアップが完了しました！${NC}"
echo "=================================================================="
echo ""
echo "📊 アクセス情報:"
echo "  GitLab:     http://localhost:8001"
echo "  Grafana:    http://localhost:8000"
echo "  Prometheus: http://localhost:8002"
echo "  WebHook:    http://localhost:9000"
echo ""
echo "🔐 ログイン情報:"
echo "  GitLab:"
echo "    ユーザー名: root"
echo "    パスワード: $GITLAB_PASSWORD"
echo ""
echo "  Grafana:"
echo "    ユーザー名: admin"
echo "    パスワード: admin"
echo ""
echo "📋 次のステップ:"
echo "  1. GitLabにログインしてパスワードを変更"
echo "  2. プロジェクトを作成"
echo "  3. WebHookを設定 (Settings > Webhooks)"
echo "     URL: http://gitlab-webhook:9000/hook"
echo "     Events: Push events"
echo "  4. システム監視は自動的に実行されます"
echo ""
echo "📖 詳細な使用方法は README.md を参照してください"
echo ""
print_success "GitLab自動バックアップ・復旧システムの準備が完了しました！" 