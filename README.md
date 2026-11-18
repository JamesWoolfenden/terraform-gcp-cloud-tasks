# terraform-gcp-cloud-tasks

[![Build Status](https://github.com/JamesWoolfenden/terraform-gcp-cloud-tasks/workflows/Verify/badge.svg?branch=main)](https://github.com/JamesWoolfenden/terraform-gcp-cloud-tasks/actions)
[![Latest Release](https://img.shields.io/github/release/JamesWoolfenden/terraform-gcp-cloud-tasks.svg)](https://github.com/JamesWoolfenden/terraform-gcp-cloud-tasks/releases/latest)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/JamesWoolfenden/terraform-gcp-cloud-tasks.svg?label=latest)](https://github.com/JamesWoolfenden/terraform-gcp-cloud-tasks/releases/latest)
![Terraform Version](https://img.shields.io/badge/tf-%3E%3D1.5.0-blue.svg)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

Terraform module for a Cloud Tasks queue. Every task dispatched from the queue carries an OIDC token for a dedicated invoker service account (queue-level `http_target`), so the backend can require authentication. The queue has bounded rate limits and retries, Cloud Logging enabled via `stackdriver_logging_config`, enqueuer grants (`roles/cloudtasks.enqueuer`) that reject public members, and the Cloud Tasks service agent is granted `roles/iam.serviceAccountTokenCreator` on the invoker SA only. Cloud Tasks CMEK is a location-wide setting (`CmekConfig`) that has no resource in the `google`/`google-beta` 7.31.0 providers, so it is not managed here; set it with `gcloud tasks cmek-config update --location=REGION --kms-key-name=KEY` if you need it.

## Usage

Add **module.cloud_tasks.tf** to your code:-

```terraform
module "cloud_tasks" {
  source                  = "jameswoolfenden/cloud-tasks/gcp"
  name                    = "example-queue"
  location                = "europe-west2"
  invoker_service_account = google_service_account.invoker.id
  uri_override_host       = "example-service-abc123-nw.a.run.app"
  oidc_audience           = "https://example-service-abc123-nw.a.run.app"
  enqueuers               = ["serviceAccount:${google_service_account.producer.email}"]
}
```

Grant the invoker SA `roles/run.invoker` (or the equivalent) on the backend. See [example/examplea](example/examplea) for a complete working example.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_cloud_tasks_queue.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_tasks_queue) | resource |
| [google_cloud_tasks_queue_iam_member.enqueuers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_tasks_queue_iam_member) | resource |
| [google_service_account_iam_member.enqueuers_act_as](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_iam_member.service_agent_token_creator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_project.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enqueuers"></a> [enqueuers](#input\_enqueuers) | IAM members granted roles/cloudtasks.enqueuer on the queue | `list(string)` | `[]` | no |
| <a name="input_grant_enqueuers_act_as"></a> [grant\_enqueuers\_act\_as](#input\_grant\_enqueuers\_act\_as) | Grant each enqueuer roles/iam.serviceAccountUser on the invoker SA, needed when tasks set their own OIDC token | `bool` | `false` | no |
| <a name="input_grant_service_agent_oidc_minting"></a> [grant\_service\_agent\_oidc\_minting](#input\_grant\_service\_agent\_oidc\_minting) | Grant the Cloud Tasks service agent roles/iam.serviceAccountTokenCreator on the invoker SA so it can mint OIDC tokens | `bool` | `true` | no |
| <a name="input_http_method"></a> [http\_method](#input\_http\_method) | HTTP method used when dispatching tasks | `string` | `"POST"` | no |
| <a name="input_invoker_service_account"></a> [invoker\_service\_account](#input\_invoker\_service\_account) | ID (projects/PROJECT/serviceAccounts/EMAIL) of the dedicated service account whose OIDC token is attached to every dispatched task | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Region the queue is created in | `string` | `"europe-west2"` | no |
| <a name="input_logging_sampling_ratio"></a> [logging\_sampling\_ratio](#input\_logging\_sampling\_ratio) | Fraction of task operations written to Cloud Logging (greater than 0, up to 1.0) | `number` | `1` | no |
| <a name="input_max_concurrent_dispatches"></a> [max\_concurrent\_dispatches](#input\_max\_concurrent\_dispatches) | Maximum number of concurrent tasks dispatched from the queue | `number` | `10` | no |
| <a name="input_max_dispatches_per_second"></a> [max\_dispatches\_per\_second](#input\_max\_dispatches\_per\_second) | Maximum rate at which tasks are dispatched from the queue | `number` | `10` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Cloud Tasks queue | `string` | n/a | yes |
| <a name="input_oidc_audience"></a> [oidc\_audience](#input\_oidc\_audience) | Audience for the OIDC token. Null uses the task's target URI | `string` | `null` | no |
| <a name="input_retry_config"></a> [retry\_config](#input\_retry\_config) | Retry behaviour for failed tasks. max\_attempts is bounded so a poison task cannot retry forever | <pre>object({<br/>    max_attempts       = optional(number, 5)<br/>    max_retry_duration = optional(string, "3600s")<br/>    min_backoff        = optional(string, "1s")<br/>    max_backoff        = optional(string, "300s")<br/>    max_doublings      = optional(number, 5)<br/>  })</pre> | `{}` | no |
| <a name="input_uri_override_host"></a> [uri\_override\_host](#input\_uri\_override\_host) | Host every task is forced to (with scheme HTTPS). Required unless var.grant\_enqueuers\_act\_as is true, because the queue attaches the invoker SA's OIDC token to every task; null leaves the task's own URI untouched | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | ID of the Cloud Tasks queue |
| <a name="output_name"></a> [name](#output\_name) | Name of the Cloud Tasks queue |
| <a name="output_service_agent"></a> [service\_agent](#output\_service\_agent) | IAM member string of the Cloud Tasks service agent for this project |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Role and Permissions

<!-- BEGINNING OF PRE-COMMIT-PIKE DOCS HOOK -->
The Terraform resource required is:

```golang
# apply role
resource "google_project_iam_custom_role" "terraform_pike" {
  project     = "pike-477416"
  role_id     = "terraform_pike"
  title       = "terraform_pike"
  description = "A user with least privileges"
  permissions = [
    "cloudtasks.queues.create",
    "cloudtasks.queues.delete",
    "cloudtasks.queues.get",
    "cloudtasks.queues.getIamPolicy",
    "cloudtasks.queues.setIamPolicy",
    "cloudtasks.queues.update",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "resourcemanager.projects.get"
  ]
}

# plan role
resource "google_project_iam_custom_role" "terraform_pike_plan" {
  project     = "pike-477416"
  role_id     = "terraform_pike_plan"
  title       = "terraform_pike_plan"
  description = "A user with least privileges"
  permissions = [
    "cloudtasks.queues.get",
    "cloudtasks.queues.getIamPolicy",
    "iam.serviceAccounts.getIamPolicy",
    "resourcemanager.projects.get"
  ]
}


```
<!-- END OF PRE-COMMIT-PIKE DOCS HOOK -->

## Help

**Got a question?**

File a GitHub [issue](https://github.com/jameswoolfenden/terraform-gcp-cloud-tasks/issues).

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/jameswoolfenden/terraform-gcp-cloud-tasks/issues) to report any bugs or file feature requests.

## Copyrights

Copyright © 2026 James Woolfenden

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements. See the NOTICE file
distributed with this work for additional information
regarding copyright ownership. The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

<https://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the License for the
specific language governing permissions and limitations
under the License.

### Contributors

[![James Woolfenden][jameswoolfenden_avatar]][jameswoolfenden_homepage]<br/>[James Woolfenden][jameswoolfenden_homepage]

[jameswoolfenden_homepage]: https://github.com/jameswoolfenden
[jameswoolfenden_avatar]: https://github.com/jameswoolfenden.png?size=150
