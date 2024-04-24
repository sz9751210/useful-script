import subprocess
import ipaddress
import json


def list_vpcs_and_subnets_for_projects(project_ids):
    for project_id in project_ids:
        subprocess.run(
            ["gcloud", "config", "set", "project", project_id],
            check=True,
            stderr=subprocess.DEVNULL,
        )

        print(f"列出專案 {project_id} 下的所有 VPC 網路和子網路：")
        print("-" * 70)

        subnets_result = subprocess.run(
            [
                "gcloud",
                "compute",
                "networks",
                "subnets",
                "list",
                "--format=table(network.basename():label=VPC網路, name:label=名稱, region.basename():label=區域, ipCidrRange:label=IPv4範圍)",
            ],
            text=True,
            check=True,
            stdout=subprocess.PIPE,
        )
        print(subnets_result.stdout)


def check_subnet_coverage(project_ids, cidr_to_check):
    try:
        network_to_check = ipaddress.ip_network(cidr_to_check)
    except ValueError:
        print("無效的 CIDR 範圍。請輸入正確的 CIDR 格式，例如 '192.168.1.0/24'。")
        return

    found = False
    for project_id in project_ids:
        subprocess.run(
            ["gcloud", "config", "set", "project", project_id],
            check=True,
            stderr=subprocess.DEVNULL,
        )

        subnets_result = subprocess.run(
            ["gcloud", "compute", "networks", "subnets", "list", "--format=json"],
            capture_output=True,
            text=True,
            check=True,
        )
        subnets = json.loads(subnets_result.stdout)

        for subnet in subnets:
            subnet_name = subnet["name"]
            vpc_name = subnet["network"].split("/")[-1]
            subnet_range = subnet["ipCidrRange"]
            subnet_network = ipaddress.ip_network(subnet_range)

            if network_to_check.overlaps(subnet_network):
                print(
                    f"CIDR 範圍 {cidr_to_check} 與專案 {project_id} 中的 VPC {vpc_name}，子網 {subnet_name} （IP範圍 {subnet_range}）有交集。"
                )
                found = True

    if not found:
        print(f"CIDR 範圍 {cidr_to_check} 在所有列出的專案子網中未被使用。")


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
            check_subnet_coverage(project_ids, ip_input)
        elif choice == "q":
            print("正在退出程序...")
            break
        else:
            print("無效的選項，請重新輸入。")


if __name__ == "__main__":
    main()
