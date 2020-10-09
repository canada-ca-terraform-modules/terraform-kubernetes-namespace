# Terraform Kubernetes Namespace

## Introduction

This module deploys and configures Namespaces inside a Kubernetes Cluster.

## Security Controls

The following security controls can be met through configuration of this template:

* TBD

## Dependencies

* None

## Optional (depending on options configured):

* None

## Usage

```terraform
resource "kubernetes_namespace" "xxxxx" {
  metadata {
    name = "xxxxx"

    labels = {}
  }
}

module "namespace_xxxxx" {
  source = "https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-kubernetes-namespace?ref=v2.0.0"

  name = "${kubernetes_namespace.xxxxx.metadata.0.name}"
  namespace_admins = {
    users = []
    groups = [
      # Enter Active Directory Group
    ]
  }

  # CICD
  ci_name = "argo"

  # Image Pull Secret
  enable_kubernetes_secret = "${var.enable_kubernetes_secret}"
  kubernetes_secret = "${var.kubernetes_secret}"
  docker_repo = "${var.docker_repo}"
  docker_username = "${var.docker_username}"
  docker_password = "${var.docker_password}"
  docker_email = "${var.docker_email}"
  docker_auth = "${var.docker_auth}"

  dependencies = []
}
```

## Variables Values

| Name                     | Type    | Required | Value                                                   |
| ------------------------ | ------- | -------- | ------------------------------------------------------- |
| name                     | string  | yes      | The namespace this module will run against              |
| namespace_admins         | string  | yes      | The user / group to authorize against                   |
| ci_Name                  | string  | yes      | The service account to use for CI                       |
| enable_kubernetes_secret | boolean | yes      | Whether to enable a custom image pull secret            |
| kubernetes_secret        | string  | yes      | The name of the secret that will be created             |
| docker_repo              | string  | yes      | The name of the docker repo that will be created        |
| docker_username          | string  | yes      | The username for authenticating against the docker repo |
| docker_password          | string  | yes      | The password for authenticating against the docker repo |
| docker_email             | string  | yes      | The email for authenticating against the docker repo    |
| docker_auth              | string  | yes      | The auth for authenticating against the docker repo     |
| dependencies             | string  | yes      | Dependency name refering to namespace module            |

## History

| Date     | Release    | Change                                                     |
| -------- | ---------- | ---------------------------------------------------------- |
| 20200123 | 1.0.0      | 1st release                                                |
| 20200820 | 1.0.1      | Namespace admin RBAC udpates                               |
| 20201009 | 2.0.0      | Updated module for Helm 3                                  |

