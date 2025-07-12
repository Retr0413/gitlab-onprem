from flask import Flask, request
import logging
import json
import os
from datetime import datetime

app = Flask(__name__)

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/webhook.log'),
        logging.StreamHandler()
    ]
)

# バックアップリクエストファイルのパス
BACKUP_REQUEST_FILE = "/backup/backup_request.json"

@app.route('/hook', methods=['POST'])
def hook():
    try:
        data = request.json
        app.logger.info(f"WebHook received: {json.dumps(data, indent=2)}")
        
        # プッシュイベントのみトリガー
        if data.get('object_kind') == 'push':
            project_name = data.get('project', {}).get('name', 'unknown')
            branch = data.get('ref', '').split('/')[-1]  # refs/heads/main -> main
            
            app.logger.info(f"Push event detected for project: {project_name}, branch: {branch}")
            
            # バックアップリクエストファイルを作成
            backup_request = {
                "timestamp": datetime.now().isoformat(),
                "project": project_name,
                "branch": branch,
                "event": "push",
                "processed": False
            }
            
            try:
                with open(BACKUP_REQUEST_FILE, 'w') as f:
                    json.dump(backup_request, f, indent=2)
                app.logger.info(f"Backup request created for {project_name}")
            except Exception as e:
                app.logger.error(f"Failed to create backup request: {str(e)}")
                
        else:
            app.logger.info(f"Non-push event ignored: {data.get('object_kind')}")
            
        return '', 200
        
    except Exception as e:
        app.logger.error(f"WebHook processing error: {str(e)}")
        return '', 500

@app.route('/health', methods=['GET'])
def health():
    return {'status': 'healthy', 'timestamp': datetime.now().isoformat()}, 200

if __name__ == '__main__':
    # バックアップディレクトリを作成
    os.makedirs('/backup', exist_ok=True)
    app.logger.info("WebHook receiver starting...")
    app.run(host='0.0.0.0', port=9000)