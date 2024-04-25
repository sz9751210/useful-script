import subprocess
import datetime
import pytz
import json


def run_command(command):
    """執行外部命令並返回 JSON 輸出。"""
    result = subprocess.run(
        command, check=True, shell=True, text=True, capture_output=True
    )
    if result.returncode != 0:
        print("命令執行失敗:", result.stderr)
        return None
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print("解析 JSON 失敗")
        return None


def set_project(project_id):
    """設置 GCloud 專案。"""
    if not project_id:
        raise ValueError("專案ID為必填項。")
    run_command(f"gcloud config set project {project_id} --format=json")


def get_cluster_maintenance_window(cluster_name, region):
    """獲取指定叢集的維護窗口信息。"""
    return run_command(
        f"gcloud container clusters describe {cluster_name} --region {region} --format=json"
    )


def localize_datetime(utc_datetime_str):
    """將 UTC 時間字符串轉換為 offset-aware datetime 對象。"""
    utc = pytz.UTC
    return utc.localize(
        datetime.datetime.strptime(utc_datetime_str, "%Y-%m-%dT%H:%M:%SZ")
    )


def main(project_id, cluster_name, region):
    set_project(project_id)
    maintenance_info = get_cluster_maintenance_window(cluster_name, region)
    if not maintenance_info or "maintenancePolicy" not in maintenance_info:
        print("無法獲取維護窗口信息。")
        return

    window = maintenance_info["maintenancePolicy"]["window"]["recurringWindow"][
        "window"
    ]
    start_time = localize_datetime(window["startTime"])
    end_time = localize_datetime(window["endTime"])
    print(f"維護窗口開始時間: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"維護窗口結束時間: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
    now_utc = datetime.datetime.now(pytz.utc)
    if start_time <= now_utc <= end_time:
        print("當前時間在維護窗口內，開始部署另一座叢集。")
    else:
        print("當前時間不在維護窗口內，不進行操作。")


if __name__ == "__main__":
    cluster_name = ""
    region = ""
    project_id = ""

    main(project_id, cluster_name, region)
