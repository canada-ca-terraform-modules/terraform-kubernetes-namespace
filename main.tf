resource "kubernetes_resource_quota" "service_quota" {
  metadata {
    name      = "service-quota"
    namespace = var.name
    labels    = local.common_labels
  }

  spec {
    hard = {
      "services.loadbalancers" = var.allowed_loadbalancers
      "services.nodeports"     = var.allowed_nodeports
    }
  }
}

# conflicting name introduced as intermediary step towards having storage quota across existing resources [CN-1457]
# ref: https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-kubernetes-namespace/-/merge_requests/16#note_210914
resource "kubernetes_resource_quota" "storage_quota" {
  metadata {
    name      = "limit-storage"
    namespace = var.name
    labels    = local.common_labels
    annotations = {
      "kubernetes.io/description" = <<-EOF
      To limit additional costs to the cloud project, this policy is in place to
      prevent the use of more storage than is already in use. If you require additional storage,
      please obtain CIO (IT requests) or BRM (business requests) approval and submit a Cloud Jira to have the quota increased.
      EOF
    }
  }

  spec {
    hard = {
      "requests.storage" = var.allowed_storage
    }
  }
}

resource "kubernetes_role" "namespace-admin" {
  metadata {
    name      = "namespace-admin"
    namespace = var.name
    labels    = local.common_labels
  }

  # Read-only access to resource quotas
  rule {
    api_groups = [""]
    resources  = ["resourcequotas", "endpoints"]
    verbs      = ["list", "get", "watch"]
  }

  # Read/write access to most resources in namespace
  rule {
    api_groups = [
      "",
      "apps",
      "autoscaling",
      "batch",
      "extensions",
      "policy",
      "rbac.authorization.k8s.io",
      "metrics.k8s.io",
      "elasticsearch.k8s.elastic.co",
      "kibana.k8s.elastic.co",
      "monitoring.coreos.com",
      "networking.k8s.io",
      "cert-manager.io"
    ]
    resources = [
      "nodes",
      "deployments",
      "deployments/scale",
      "cronjobs",
      "events",
      "jobs",
      "replicasets",
      "replicasets/scale",
      "replicationcontrollers",
      "secrets",
      "serviceaccounts",
      "services",
      "services/proxy",
      "statefulsets",
      "statefulsets/scale",
      "persistentvolumeclaims",
      "pods",
      "pods/attach",
      "pods/ephemeralcontainers",
      "pods/exec",
      "pods/log",
      "pods/portforward",
      "poddisruptionbudgets",
      "horizontalpodautoscalers",
      "configmaps",
      "ingresses",
      "elasticsearches",
      "kibanas",
      "roles",
      "rolebindings",
      "prometheuses",
      "prometheusrules",
      "alertmanagers",
      "servicemonitors",
      "certificates",
      "issuers"
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete",
      "edit",
      "exec"
    ]
  }

  # Read/write access for Istio networking
  rule {
    api_groups = [
      "networking.istio.io",
    ]
    resources = [
      "destinationrules",
      "serviceentries",
      "sidecars",
      "virtualservices",
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete",
      "edit",
      "exec"
    ]
  }

  # Read/write access for Istio security
  rule {
    api_groups = [
      "security.istio.io",
    ]
    resources = [
      "authorizationpolicies",
      "peerauthentications",
      "requestauthentications",
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete",
      "edit",
      "exec"
    ]
  }

  # Read/write access for Argo
  rule {
    api_groups = [
      "argoproj.io"
    ]
    resources = [
      "workflows",
      "workflows/finalizers",
      "workfloweventbindings",
      "workfloweventbindings/finalizers",
      "workflowtemplates",
      "workflowtemplates/finalizers",
      "cronworkflows",
      "cronworkflows/finalizers",
      "clusterworkflowtemplates",
      "clusterworkflowtemplates/finalizers",
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete",
      "edit",
      "exec"
    ]
  }

  # Read/write access for CronJobber
  rule {
    api_groups = [
      "cronjobber.hidde.co"
    ]
    resources = [
      "tzcronjobs",
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete",
      "edit",
    ]
  }

  # read-only access to all resources in the aadpodidentity.k8s.io api group
  rule {
    api_groups = ["aadpodidentity.k8s.io"]
    resources  = ["*"]
    verbs      = ["list", "get", "watch"]
  }

  # Read/write access for Solr
  rule {
    api_groups = [
      "solr.apache.org"
    ]
    resources = [
      "solrclouds",
    ]
    verbs = [
      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete",
      "edit"
    ]
  }
}

resource "kubernetes_role_binding" "namespace-admins" {
  metadata {
    name      = "namespace-admins"
    namespace = var.name
    labels    = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "namespace-admin"
  }

  # Users
  dynamic "subject" {
    for_each = var.namespace_admins.users
    content {
      kind      = "User"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }

  # Groups
  dynamic "subject" {
    for_each = var.namespace_admins.groups
    content {
      kind      = "Group"
      name      = subject.value
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

# Secret

resource "kubernetes_secret" "secret_registry" {
  count = var.enable_kubernetes_secret ? 1 : 0

  metadata {
    name      = var.kubernetes_secret
    namespace = var.name
    labels    = local.common_labels
  }

  data = {
    ".dockerconfigjson" = templatefile("${path.module}/templates/dockerconfigjson.tpl", {
      repo     = var.docker_repo,
      username = var.docker_username,
      password = var.docker_password,
      email    = var.docker_email,
      auth     = var.docker_auth,
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

# CI/CD

resource "kubernetes_service_account" "ci" {
  metadata {
    name      = var.ci_name
    namespace = var.name
    labels    = local.common_labels
  }

  automount_service_account_token = false
}

resource "kubernetes_cluster_role_binding" "ci-user" {
  metadata {
    name   = "cluster-user-ci-${var.name}"
    labels = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-user"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ci.metadata.0.name
    namespace = kubernetes_service_account.ci.metadata.0.namespace
  }
}

resource "kubernetes_role_binding" "namespace-admin-ci" {
  metadata {
    name      = "namespace-admin-${var.ci_name}"
    namespace = var.name
    labels    = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "namespace-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ci.metadata.0.name
    namespace = kubernetes_service_account.ci.metadata.0.namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.ci_name
    namespace = "ci"
  }
}

resource "kubernetes_cluster_role_binding" "ci" {
  metadata {
    name   = "${var.ci_name}-${var.name}"
    labels = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.ci_name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.ci_name
    namespace = var.name
  }
}

# Logging

resource "kubernetes_config_map" "fluentd-config" {
  metadata {
    name      = "fluentd-config"
    namespace = var.name
    labels    = local.common_labels
  }

  data = {
    "fluent.conf" = var.fluentd_config
  }
}

locals {
  hostsAndPathsMap = [for v in var.allowed_hosts : {
    host = (length(regexall("/", v)) > 0) ? regex("^[^/]*", v) : v
    path = (length(regexall("/", v)) > 0) ? regex("/.*", v) : ""
  }]
}

resource "kubernetes_annotations" "allowed_hosts" {
  count = length(var.allowed_hosts) == 0 ? 0 : 1

  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = var.name
  }
  annotations = {
    "ingress.statcan.gc.ca/allowed-hosts" = jsonencode(local.hostsAndPathsMap)
  }
  force = true
}
