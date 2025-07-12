# GitLab On-Premises 自動バックアップ・復旧システム

## 概要

このプロジェクトは、GitLab Enterprise Editionを基盤とした自動バックアップ・復旧システムです。リポジトリへのプッシュ時に自動でバックアップを実行し、システム障害時には自動復旧機能により迅速にサービスを復旧させます。

## 主な機能

### 🚀 自動バックアップ
- **WebHook連携**: GitLabリポジトリへのプッシュ時に自動バックアップ実行
- **完全バックアップ**: リポジトリデータ + 設定ファイルの完全バックアップ
- **バックアップ検証**: バックアップ完了後の自動検証機能
- **自動クリーンアップ**: 7日以上経過した古いバックアップの自動削除

### 🔄 自動復旧・監視
- **ヘルスチェック**: 全サービスの健康状態を定期監視
- **自動再起動**: 不健全なサービスの自動検出・再起動
- **システム監視**: 5分間隔でのシステム状態チェック
- **ディスク監視**: ストレージ使用量の監視・アラート

### 📊 監視・可視化
- **Grafana**: リアルタイム監視ダッシュボード
- **Prometheus**: メトリクス収集・分析
- **詳細ログ**: 全操作の詳細ログ記録

## システム要件

- **OS**: macOS (Darwin)
- **Docker**: Docker Desktop for Mac
- **Docker Compose**: v2.0以上
- **ディスク容量**: 最低10GB（バックアップ保存用）
- **メモリ**: 最低8GB推奨
- **ネットワーク**: インターネット接続（初回セットアップ時）

## ファイル構成

```
gitlab-onprem/
├── docker-compose.yml          # Docker Compose設定
├── README.md                   # このファイル
├── setup.sh                   # 自動セットアップスクリプト
├── status.sh                  # システム状態確認スクリプト
├── gitlab-onprem.service       # systemdサービス設定
├── monitor.sh                  # システム監視スクリプト
├── backup/
│   └── backup.sh              # バックアップスクリプト
├── webhook/
│   ├── receiver.py            # WebHook受信サーバー
│   └── requirements.txt       # Python依存関係
├── grafana/
│   └── provisioning/          # Grafana設定
│       ├── dashboards/
│       └── datasources/
└── prometheus/
    └── prometheus.yml         # Prometheus設定
```

## インストール手順

### 🚀 クイックセットアップ（推奨）

新規ユーザーは自動セットアップスクリプトの使用を推奨します：

```bash
git clone <repository-url>
cd gitlab-onprem
./setup.sh
```

セットアップスクリプトが以下を自動実行します：
- 前提条件のチェック
- バックアップディレクトリの作成
- 権限設定
- サービス起動
- 自動監視設定
- 初期パスワードの表示

### 📋 手動セットアップ

高度なカスタマイズが必要な場合は手動でセットアップできます：

#### 1. プロジェクトのクローン
```bash
git clone <repository-url>
cd gitlab-onprem
```

#### 2. バックアップディレクトリの作成
```bash
mkdir -p /Users/$(whoami)/Desktop/gitlab-backup
```

#### 3. スクリプトに実行権限を付与
```bash
chmod +x backup/backup.sh
chmod +x monitor.sh
chmod +x setup.sh
```

#### 4. システムの起動
```bash
docker-compose up -d
```

#### 5. 自動監視の設定
```bash
# crontabに監視スクリプトを登録
echo "*/5 * * * * cd $(pwd) && ./monitor.sh" | crontab -
```

## 起動・停止方法

### システム起動
```bash
# 全サービス起動
docker-compose up -d

# 特定サービスのみ起動
docker-compose up -d gitlab
```

### システム停止
```bash
# 全サービス停止
docker-compose down

# データを保持したまま停止
docker-compose stop
```

### システム再起動
```bash
# 全サービス再起動
docker-compose restart

# 特定サービスのみ再起動
docker-compose restart gitlab
```

## アクセス情報

| サービス | URL | 説明 |
|---------|-----|------|
| **GitLab** | http://localhost:8001 | メインのGitLabインターフェース |
| **Grafana** | http://localhost:8000 | 監視ダッシュボード |
| **Prometheus** | http://localhost:8002 | メトリクス収集システム |
| **WebHook** | http://localhost:9000 | 自動バックアップAPI |

### GitLab初回ログイン

1. ブラウザで http://localhost:8001 にアクセス
2. 初期パスワードを確認:
   ```bash
   docker exec gitlab cat /etc/gitlab/initial_root_password
   ```
3. ユーザー名: `root`、パスワード: 上記で確認したパスワードでログイン
4. **セキュリティのため、初回ログイン後に必ずパスワードを変更してください**

### Grafana初回ログイン

- ユーザー名: `admin`
- パスワード: `admin`

## WebHook設定方法

### 1. GitLabプロジェクトでWebHookを設定

1. GitLabにログインし、対象プロジェクトを選択
2. **Settings** > **Webhooks** に移動
3. 以下の設定を入力:
   - **URL**: `http://gitlab-webhook:9000/hook`
   - **Trigger Events**: ✅ Push events
   - **SSL verification**: ❌ 無効化
4. **Add webhook** をクリック

### 2. WebHook動作テスト

```bash
# 手動でWebHookをテスト
curl -X POST http://localhost:9000/hook \
  -H "Content-Type: application/json" \
  -d '{"object_kind": "push", "project": {"name": "test-project"}, "ref": "refs/heads/main"}'
```

## 監視・メンテナンス

### システム状態確認
```bash
# 総合システム状態確認（推奨）
./status.sh

# サービス状態確認
docker-compose ps

# ヘルスチェック確認
curl http://localhost:9000/health

# システム全体の監視実行
./monitor.sh
```

### ログ確認
```bash
# 監視ログ
tail -f /Users/shinlab/Desktop/gitlab-backup/monitor.log

# バックアップログ
tail -f /Users/shinlab/Desktop/gitlab-backup/backup.log

# WebHookログ
docker logs gitlab-webhook --tail 50

# GitLabログ
docker logs gitlab --tail 50
```

### 手動バックアップ実行
```bash
# 手動バックアップ実行
./backup/backup.sh

# バックアップ一覧確認
ls -la /Users/shinlab/Desktop/gitlab-backup/
```

## バックアップ・復旧

### バックアップファイルの場所
- **保存先**: `/Users/shinlab/Desktop/gitlab-backup/`
- **形式**: `YYYYMMDD_HHMMSS` フォルダ内に以下が保存
  - `backups/`: GitLabデータバックアップ
  - `etc-gitlab/`: GitLab設定ファイル

### 復旧手順

1. **サービス停止**
   ```bash
   docker-compose down
   ```

2. **データボリューム削除**
   ```bash
   docker volume rm gitlab-onprem_gitlab-config gitlab-onprem_gitlab-logs gitlab-onprem_gitlab-data
   ```

3. **サービス再起動**
   ```bash
   docker-compose up -d gitlab
   ```

4. **バックアップ復元**
   ```bash
   # 設定ファイル復元
   docker cp /Users/shinlab/Desktop/gitlab-backup/YYYYMMDD_HHMMSS/etc-gitlab gitlab:/etc/gitlab
   
   # データバックアップ復元
   docker cp /Users/shinlab/Desktop/gitlab-backup/YYYYMMDD_HHMMSS/backups gitlab:/var/opt/gitlab/
   
   # GitLab設定再読み込み
   docker exec gitlab gitlab-ctl reconfigure
   
   # バックアップ復元実行
   docker exec gitlab gitlab-backup restore BACKUP=<backup_filename>
   ```

## トラブルシューティング

### 一般的な問題

#### GitLabにアクセスできない
```bash
# GitLabコンテナ状態確認
docker-compose logs gitlab

# GitLabサービス状態確認
docker exec gitlab gitlab-ctl status

# GitLab再設定
docker exec gitlab gitlab-ctl reconfigure
```

#### WebHookが動作しない
```bash
# WebHookログ確認
docker logs gitlab-webhook

# WebHookコンテナ再起動
docker-compose restart webhook

# WebHook手動テスト
curl -X POST http://localhost:9000/hook -H "Content-Type: application/json" -d '{"object_kind": "push", "project": {"name": "test"}, "ref": "refs/heads/main"}'
```

#### バックアップが失敗する
```bash
# バックアップスクリプト手動実行
./backup/backup.sh

# GitLabバックアップ権限確認
docker exec gitlab ls -la /var/opt/gitlab/backups

# ディスク容量確認
df -h /Users/shinlab/Desktop/gitlab-backup
```

### ログファイルの場所

| ログの種類 | ファイルパス |
|-----------|-------------|
| システム監視 | `/Users/shinlab/Desktop/gitlab-backup/monitor.log` |
| バックアップ | `/Users/shinlab/Desktop/gitlab-backup/backup.log` |
| WebHook | コンテナ内: `/app/webhook.log` |
| GitLab | コンテナ内: `/var/log/gitlab/` |

## セキュリティ考慮事項

### 推奨設定

1. **GitLab管理者パスワード**: 初回ログイン後に強固なパスワードに変更
2. **Grafana管理者パスワード**: デフォルトパスワードの変更
3. **ファイアウォール**: 必要なポートのみ開放
4. **SSL/TLS**: 本番環境ではHTTPS設定を推奨
5. **バックアップ暗号化**: 機密データがある場合はバックアップの暗号化を検討

### ポート使用状況

| ポート | サービス | 説明 |
|-------|---------|------|
| 8001 | GitLab HTTP | GitLabメインアクセス |
| 8443 | GitLab HTTPS | GitLab HTTPS（設定時） |
| 2222 | GitLab SSH | Git SSH アクセス |
| 8000 | Grafana | 監視ダッシュボード |
| 8002 | Prometheus | メトリクス収集 |
| 9000 | WebHook | 自動バックアップAPI |

## 開発・カスタマイズ

### WebHook機能の拡張

`webhook/receiver.py` を編集してカスタマイズ可能:
- 異なるイベントタイプの処理
- 通知機能の追加
- バックアップ条件の変更

### 監視項目の追加

`monitor.sh` を編集して監視項目を追加:
- 追加サービスの監視
- カスタムアラート条件
- 外部通知連携

### Grafanaダッシュボード

`grafana/provisioning/` でカスタムダッシュボードを追加可能

## サポート

問題が発生した場合は、以下の情報を収集してサポートに連絡してください:

1. システム情報: `docker-compose ps`
2. ログファイル: 上記「ログ確認」セクション参照
3. 設定ファイル: `docker-compose.yml`
4. エラー内容: 具体的なエラーメッセージ

---

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 更新履歴

- **v1.0.0**: 初期リリース
  - GitLab Enterprise Edition統合
  - 自動バックアップ・復旧機能
  - Grafana/Prometheus監視システム
  - WebHook自動化システム 