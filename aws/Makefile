.PHONY: create_oidc create_aws_load_balancer create_efs_and_install_eks delete_efs delete_aws_load_balancer delete_oidc

create_oidc:
	@source export_envs.sh && bash create_oidc.sh

create_aws_load_balancer:
	@source export_envs.sh && ./create_aws_load_balancer.sh

create_efs:
	@source export_envs.sh && ./create_efs.sh

delete_efs:
	@source export_envs.sh && bash delete_efs.sh

delete_aws_load_balancer:
	@source export_envs.sh && bash delete_aws_load_balancer.sh

delete_oidc:
	@source export_envs.sh && bash delete_oidc.sh
