# Dell Boomi Atom on AWS ECS Fargate Deployment

This repository contains the Infrastructure as Code (IaC) configurations required to set up a highly available Dell Boomi Atom running on AWS ECS Fargate using Terraform. Additionally, it features a Python-based AWS Lambda function responsible for AWS Secrets Manager rotation.

This repo is configured for the intention of use for Coforma. If you intend to use it please fork it and make your own customizations.

## Overview

- **Fargate Task**: Runs a single task that is allocated 1 vCPU and 2GB of memory. The task is responsible for running the Dell Boomi Atom.
  
- **Lambda Function for Secrets Rotation**: It rotates the secrets every 12 hours using the environment variables `boomi_account_id`, `boomi_username`, and `boomi_auth_token`. This ensures that the task can always pull a new version if an issue arises.
  
- **VPC Configuration**: The Boomi Atom operates inside a private VPC but can connect to the internet using dedicated egress rules routed through a NAT Gateway and an Internet Gateway (IGW) pair.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | < 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.19.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.19.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs"></a> [ecs](#module\_ecs) | terraform-aws-modules/ecs/aws | ~> 5.2.2 |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | terraform-aws-modules/lambda/aws | ~> 6.0.1 |
| <a name="module_secrets_manager"></a> [secrets\_manager](#module\_secrets\_manager) | terraform-aws-modules/secrets-manager/aws | ~> 1.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_log_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_ssm_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.task_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.boomi_account_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.boomi_auth_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.boomi_username](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boomi_account_id"></a> [boomi\_account\_id](#input\_boomi\_account\_id) | The account ID for the boomi platform | `string` | n/a | yes |
| <a name="input_boomi_auth_token"></a> [boomi\_auth\_token](#input\_boomi\_auth\_token) | The auth token for the boomi platform | `string` | n/a | yes |
| <a name="input_boomi_username"></a> [boomi\_username](#input\_boomi\_username) | The username for the boomi platform | `string` | n/a | yes |
| <a name="input_application"></a> [application](#input\_application) | The name of the application | `string` | `"co-boomi-atom"` | no |
| <a name="input_atom_name"></a> [atom\_name](#input\_atom\_name) | The name of the atom | `string` | `"coforma-atom-1"` | no |
| <a name="input_atom_security_group_egress"></a> [atom\_security\_group\_egress](#input\_atom\_security\_group\_egress) | Atom security group egress rules | <pre>list(object({<br>    from_port   = number<br>    to_port     = number<br>    description = string<br>    protocol    = string<br>    cidr_blocks = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": "Unanet traffic",<br>    "from_port": 31001,<br>    "protocol": "tcp",<br>    "to_port": 31001<br>  }<br>]</pre> | no |
| <a name="input_atom_version"></a> [atom\_version](#input\_atom\_version) | The version of the atom | `string` | `"4.3.5"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy to | `string` | `"us-east-1"` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port of the container | `number` | `9090` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment to deploy to | `string` | `"prod"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The owner of the application | `string` | `"devsecops"` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | The CIDR block for the subnet | `list(string)` | <pre>[<br>  "10.1.0.0/27",<br>  "10.1.0.32/27"<br>]</pre> | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | The CIDR block for the subnet | `list(string)` | <pre>[<br>  "10.1.0.64/27",<br>  "10.1.0.96/27"<br>]</pre> | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | The number of days to retain logs | `number` | `7` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | `"10.1.0.0/24"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Prerequisites

1. **Terraform/OpenTofu**: Ensure that Terraform is installed and appropriately configured with your AWS credentials.

2. **AWS Account**: Necessary permissions to create and manage the mentioned AWS resources.

3. **Python**: Required for the AWS Lambda function. Ensure you have the AWS SDK for Python (Boto3) installed and requests.

4. **[terraform-docs](https://github.com/terraform-docs/terraform-docs)**: Tool used to generate terraform docs.

## Deployment Steps

1. **Clone the Repository**:

    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```

2. Ensure Python requirements are installed next to the lambda function

    ```bash
    pip3 install --target ./lambda/package boto3 requests
    ```

3. **Initialize Terraform**:

    ```bash
    terraform init
    ```

4. **Apply Terraform Configurations**:
Before applying, always make sure to review the changes Terraform will perform.

    ```bash
    terraform plan
    terraform apply
    ```

5. **Lambda Function Configuration**:
   Ensure that the Lambda function has the three environment variables set:
   - `boomi_account_id`
   - `boomi_username`
   - `boomi_auth_token`

6. **Monitoring**:
   Monitor the task and lambda logs via AWS CloudWatch for any potential issues.

## Security Considerations

- Ensure that your AWS credentials are stored securely and are not exposed in any Terraform configurations.
- Make sure the Boomi credentials used in the Lambda environment variables are securely stored in AWS Secrets Manager or another secrets management tool.
- Ensure that the VPC egress and ingress rules are set appropriately to minimize any potential security risks.

## Contributing

If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcomed.

Before submitting a PR please make sure to run the following:

```bash
terraform fmt
terraform-docs markdown table --output-file README.md --output-mode inject --sort-by required .
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
