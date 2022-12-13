# Terraform Kubernetes Namespace

## Introduction

This module configures Namespaces inside a Kubernetes Cluster. In particular this namespace module does the following:
- Creates a new role within the namespace called **namespace-admin** and binds the role to var.namespace_admins.users & var.namespace_admins.groups. The **namespace-admin** role grants read & write permission to most of the resources in the namespace. Only read permission is granted to the resource quotas and endpoints resources. Typically, an Azure Active Directory group will be assigned the namespace-admin role.
- Sets a resource quota within the namespace that limits the quantity of services.loadbalancers & services.nodeports in the namespace. This defaults to 0.
- A new secret is created. The secret stores information that can be used to pull an image from a container image repository. This information includes, the FQDN of the repository, a set of credentials used to access the repository, an service account's email address and an authorization code used as part of the image pull secret. For instance, this secret could specify the information needed to pull image from an artifactory repository.
- A service account is created so that CD pipelines can deploy to the kubernetes namespace. For instance, the service account can be used to deploy to an Octopus project from a Gitlab repository. The service account is assigned a couple roles. It is assigned two cluster roles, one called **cluster-user** and the other called **var.ci_name** (the value of the Terraform variable). Typically, the var.ci_name variable will be set to "octopus" (after the Octopus deployment tool). The service account is also binded to a role scoped at the namespace called namespace-admin (the role created earlier in the module).
- Lastly, the module creates a new ConfigMap called **fluentd-config** within the namespace. The ConfigMap has a key called fluent.conf and its value is specified by the fluentd_config Terraform variable.

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

  name = kubernetes_namespace.xxxxx.metadata.0.name
  namespace_admins = {
    users = []
    groups = [
      # Enter Active Directory Group
    ]
  }

  # CICD
  ci_name = "argo"

  # Image Pull Secret
  enable_kubernetes_secret = var.enable_kubernetes_secret
  kubernetes_secret = var.kubernetes_secret
  docker_repo = var.docker_repo
  docker_username = var.docker_username
  docker_password = var.docker_password
  docker_email = var.docker_email
  docker_auth = var.docker_auth
}
```

## Variables Values

| Name                     | Type         | Required | Value                                                                                                                                                                                                                                                                                                                                                                          |
| ------------------------ | ------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| name                     | string       | yes      | The namespace this module will run against                                                                                                                                                                                                                                                                                                                                     |
| namespace_admins         | string       | yes      | The user / group to authorize against                                                                                                                                                                                                                                                                                                                                          |
| ci_Name                  | string       | yes      | The service account to use for CI                                                                                                                                                                                                                                                                                                                                              |
| enable_kubernetes_secret | boolean      | yes      | Whether to enable a custom image pull secret                                                                                                                                                                                                                                                                                                                                   |
| kubernetes_secret        | string       | yes      | The name of the secret that will be created                                                                                                                                                                                                                                                                                                                                    |
| docker_repo              | string       | yes      | The name of the docker repo that will be created                                                                                                                                                                                                                                                                                                                               |
| docker_username          | string       | yes      | The username for authenticating against the docker repo                                                                                                                                                                                                                                                                                                                        |
| docker_password          | string       | yes      | The password for authenticating against the docker repo                                                                                                                                                                                                                                                                                                                        |
| docker_email             | string       | yes      | The email for authenticating against the docker repo                                                                                                                                                                                                                                                                                                                           |
| docker_auth              | string       | yes      | The auth for authenticating against the docker repo                                                                                                                                                                                                                                                                                                                            |
| allowed_hosts            | list(string) | no       | A list of the hosts that are allowed by the restrict-hostnames policy to be used by ingress & VirtualService Kuberenetes resources in the namespace. Path allowance is based on the path as a prefix, there if the value test.ca/baz is passed to the allowed_hosts variable, the /baz/foo and /bazfoobar would be permitted by the policy. A path of / should allow anything. |
| allowed_storage          | string       | no       | The sum of allowed storage requests across all PVCs in this namespace. (**default**: "0")                                                                                                                                                                                                                                                                                      |
| allowed_loadbalancers    | number       | no       | The number of Services of type LoadBalancer which can be specified in the namespace.                                                                                                                                                                                                                                                                                           |
| allowed_nodeports        | number       | no       | The number of NodePorts which can be specified in Services across the namespace.                                                                                                                                                                                                                                                                                               |
| fluentd_config           | string       | no       | The configuration that is applied to the fluentd service                                                                                                                                                                                                                                                                                                                       |

## History

| Date     | Release | Change                                                       |
| -------- | ------- | ------------------------------------------------------------ |
| 20200123 | 1.0.0   | 1st release                                                  |
| 20200820 | 1.0.1   | Namespace admin RBAC udpates                                 |
| 20201009 | 2.0.0   | Updated module for Helm 3                                    |
| 20201022 | 2.1.0   | Removed additional dashboard configuration                   |
| 20201030 | 2.1.1   | Granted access to the ServiceEntry resource                  |
| 20201110 | 2.2.0   | Support customization of fluentd config                      |
| 20210225 | 2.2.1   | Update kubernetes provider                                   |
| 20211201 | 2.3.0   | Namespace admin RBAC rules for Argo                          |
| 20211207 | 2.4.0   | Namespace admin RBAC rules for CronJobber                    |
| 20211207 | 2.4.1   | Namespace admin RBAC updates for Istio 1.6                   |
| 202112-- | 2.4.2   | Fix RBAC                                                     |
| 202203-- | 2.4.3   | Remove DaemonSets from NamespaceAdmin role                   |
| 202206-- | 2.5.0   | Added read access to aadpodidentity.k8s.io Custom Resources. |
| 202206-- | 2.5.1   | Update rule location for better plan delta                   |
| 20220722 | 2.6.0   | Add allow_hosts annotation for restrict-hostname policy      |
| 20221206 | 2.7.0   | Add resource quota for storage requests with a default of 0  |
| 20221212 | 2.7.1   | Removed uneeded validation and updated error messages        |
