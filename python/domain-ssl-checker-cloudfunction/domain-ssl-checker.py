# -*- coding: utf-8 -*-

import functions_framework
from datetime import datetime
import requests
import ssl
import socket
import os
import yaml

def load_domains_from_yaml(yaml_file_path):
    try:
        with open(yaml_file_path, 'r', encoding='utf-8') as file:
            data = yaml.safe_load(file)
            return data.get('domain_envs', {})
    except FileNotFoundError as e:
        logging.error(f"YAML檔案未找到: {e}")
        return {}

def send_notification(message, domain, webhook_url, auth_user, auth_password):
    response = requests.post(webhook_url, json=message, auth=(auth_user, auth_password))
    if response.status_code ==200:
        print(f"Notification sent for {domain}")
    else:
        print(f"Send failed for {domain}")
    
def get_ssl_cert_expiry_date(domain):
    """獲取 SSL 證書的過期日期。"""
    ssl_context = ssl.create_default_context()
    conn = ssl_context.wrap_socket(socket.socket(socket.AF_INET), server_hostname=domain)
    # 3 秒連接超時
    conn.settimeout(3.0)
    try:
        conn.connect((domain, 443))
        ssl_info = conn.getpeercert()
        # 根據 SSL 證書中的 'notAfter' 字段獲取證書過期時間
        expire_date = datetime.strptime(ssl_info['notAfter'], '%b %d %H:%M:%S %Y %Z')
        return expire_date
    except Exception as e:
        print(f"無法獲取 {domain} 的 SSL 證書過期日期，錯誤：{e}")
        return None
    finally:
        conn.close()

def check_ssl_expiration(domain, env, platform, webhook_url, auth_user, auth_password):
    """檢查 SSL 證書過期時間。"""
    expire_date = get_ssl_cert_expiry_date(domain)
    if expire_date:
        remaining_days = (expire_date - datetime.utcnow()).days
        if remaining_days <= 30:
            message = {
                "來源": "Cloud Function",
                "標題": "憑證到期",
                "域名": domain,
                "到期日": expire_date.strftime("%Y-%m-%d"),
                "平台": platform,
                "環境": env,
            }
            print(f"{domain} 的 SSL 證書將在 {remaining_days} 天內過期。")
            send_notification(message, domain, webhook_url, auth_user, auth_password)
        else:
            print(f"{domain} 的 SSL 證書過期日期是 {expire_date.strftime('%Y-%m-%d')}。")

@functions_framework.http
def check_ssl_cloud_function(request):
    """HTTP Cloud Function for checking SSL certificate expiration."""
    platform = os.environ.get("PLATFORM", "未設定")
    webhook_url = os.environ.get("WEBHOOK_URL", "未設定")
    auth_user = os.environ.get("AUTH_USER", "未設定")
    auth_password = os.environ.get("AUTH_PASSWORD", "未設定")
    yaml_file_path = 'domains.yaml'
    domain_envs = load_domains_from_yaml(yaml_file_path)
    for env, domains in domain_envs.items():
        for domain in domains:
            check_ssl_expiration(domain, env, platform, webhook_url, auth_user, auth_password)
    return 'SSL 檢查完成'
