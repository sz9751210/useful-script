import subprocess
import ipaddress
import json


def set_project(project_id):
    subprocess.run(
        ["gcloud", "config", "set", "project", project_id],
        check=True,
        stderr=subprocess.DEVNULL,
    )


def run_gcloud_command(args, output_format="json"):
    result = subprocess.run(
        args + ["--format", output_format], capture_output=True, text=True, check=True
    )
    if output_format == "json":
        return json.loads(result.stdout)
    return result.stdout


def list_vpcs_and_subnets_for_projects(project_ids):
    for project_id in project_ids:
        set_project(project_id)
        print(f"列出專案 {project_id} 下的所有 VPC 網路和子網路：\n" + "-" * 70)
        subnets_result = run_gcloud_command(
            ["gcloud", "compute", "networks", "subnets", "list"],
            output_format="table(network.basename():label=VPC網路, name:label=名稱, region.basename():label=區域, ipCidrRange:label=IPv4範圍)",
        )
        print(subnets_result)


def find_relative_subnets(project_ids, cidr_to_check):
    try:
        target_network = ipaddress.ip_network(cidr_to_check)
    except ValueError:
        print("無效的 CIDR 範圍。請輸入正確的 CIDR 格式。")
        return

    for project_id in project_ids:
        set_project(project_id)
        subnets = run_gcloud_command(
            ["gcloud", "compute", "networks", "subnets", "list"]
        )

        closest_smaller, closest_larger = get_closest_subnets(subnets, target_network)

        print_relative_subnets(
            project_id, cidr_to_check, closest_smaller, closest_larger
        )


def get_closest_subnets(subnets, target_network):
    closest_smaller = closest_larger = None
    min_diff_smaller = min_diff_larger = float("inf")

    for subnet in subnets:
        subnet_network = ipaddress.ip_network(subnet["ipCidrRange"])
        diff = int(subnet_network.network_address) - int(target_network.network_address)

        if subnet_network < target_network and abs(diff) < min_diff_smaller:
            min_diff_smaller, closest_smaller = abs(diff), subnet
        elif subnet_network > target_network and abs(diff) < min_diff_larger:
            min_diff_larger, closest_larger = abs(diff), subnet

    return closest_smaller, closest_larger


def print_relative_subnets(project_id, cidr_to_check, closest_smaller, closest_larger):
    if closest_smaller:
        print(
            f"專案 {project_id} 中最接近但小於 {cidr_to_check} 的網段是：{closest_smaller['name']} ({closest_smaller['ipCidrRange']})"
        )
    else:
        print(f"專案 {project_id} 中沒有小於 {cidr_to_check} 的網段。")

    if closest_larger:
        print(
            f"專案 {project_id} 中最接近但大於 {cidr_to_check} 的網段是：{closest_larger['name']} ({closest_larger['ipCidrRange']})"
        )
    else:
        print(f"專案 {project_id} 中沒有大於 {cidr_to_check} 的網段。")


def main():
    project_ids = ["project-1" "project-2"]
    while True:
        print("\n功能選單:")
        print("1. 列出專案的所有子網")
        print("2. 檢查 IP 或 CIDR 是否在子網中被使用")
        print("q. 退出程序")
        choice = input("請輸入選項（1, 2, 或 'q' 退出）：")

        if choice == "1":
            print("開始檢查 IP 地址...")
            list_vpcs_and_subnets_for_projects(project_ids)
        elif choice == "2":
            ip_input = input("請輸入 IP 地址或 CIDR 範圍進行檢查：")
            find_relative_subnets(project_ids, ip_input)
        elif choice == "q":
            print("正在退出程序...")
            break
        else:
            print("無效的選項，請重新輸入。")


if __name__ == "__main__":
    main()
