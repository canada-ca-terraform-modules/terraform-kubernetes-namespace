# Part of a hack for module-to-module dependencies.
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
# and
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-473091030
# Make sure to add this null_resource.dependency_getter to the `depends_on`
# attribute to all resource(s) that will be constructed first within this
# module:
resource "null_resource" "dependency_getter" {
  triggers = {
    my_dependencies = "${join(",", var.dependencies)}"
  }
}

# Dashboard

resource "kubernetes_service_account" "dashboard" {
  metadata {
    name = "dashboard"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_cluster_role_binding" "dashboard-cluster-user" {
  metadata {
    name = "dashboard-${var.name}-cluster-user"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-user"
  }

  # Dashboard
  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.dashboard.metadata.0.name}"
    namespace = "${kubernetes_service_account.dashboard.metadata.0.namespace}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role_binding" "namespace-admins-dashboard-user" {
  metadata {
    name = "${var.name}-dashboard-user"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "dashboard-user"
  }

  # Users
  dynamic "subject" {
    for_each = "${var.namespace_admins.users}"
    content {
      kind = "User"
      name = "${subject.value}"
      api_group = "rbac.authorization.k8s.io"
    }
  }

  # Groups
  dynamic "subject" {
    for_each = "${var.namespace_admins.groups}"
    content {
      kind = "Group"
      name = "${subject.value}"
      api_group = "rbac.authorization.k8s.io"
    }
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_resource_quota" "service_quota" {
  metadata {
    name = "service-quota"
    namespace = "${var.name}"
  }

  spec {
    hard = {
      "services.loadbalancers" = "${var.allowed_loadbalancers}"
      "services.nodeports" = "${var.allowed_nodeports}"
    }
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role" "namespace-admin" {
  metadata {
    name = "namespace-admin"
    namespace = "${var.name}"
  }

  # Read-only access to resource quotas
  rule {
    api_groups = [""]
    resources = ["resourcequotas"]
    verbs = ["list", "get", "watch"]
  }

  # Read/write access to most resources in namespace
  rule {
    api_groups = [
      "",
      "apps",
      "batch",
      "extensions",
      "rbac.authorization.k8s.io",
      "metrics.k8s.io",
      "networking.istio.io",
      "authentication.istio.io",
      "elasticsearch.k8s.elastic.co",
      "kibana.k8s.elastic.co"
    ]
    resources = [
      "nodes",
      "deployments",
      "deployments/scale",
      "daemonsets",
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
      "pods/exec",
      "pods/log",
      "pods/portforward",
      "configmaps",
      "ingresses",
      "policies",
      "destinationrules",
      "gateways",
      "virtualservices",
      "elasticsearches",
      "kibanas",
      "roles",
      "rolebindings"
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

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role_binding" "namespace-admins" {
  metadata {
    name = "namespace-admins"
    namespace = "${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "namespace-admin"
  }

  # Users
  dynamic "subject" {
    for_each = "${var.namespace_admins.users}"
    content {
      kind = "User"
      name = "${subject.value}"
      api_group = "rbac.authorization.k8s.io"
    }
  }

  # Groups
  dynamic "subject" {
    for_each = "${var.namespace_admins.groups}"
    content {
      kind = "Group"
      name = "${subject.value}"
      api_group = "rbac.authorization.k8s.io"
    }
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role_binding" "namespace-service-account-admins" {
  metadata {
    name = "namespace-service-account-admins"
    namespace = "${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "namespace-admin"
  }

  # Dashboard
  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.dashboard.metadata.0.name}"
    namespace = "${kubernetes_service_account.dashboard.metadata.0.namespace}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# Secret

resource "kubernetes_secret" "secret_registry" {
  count = "${var.enable_kubernetes_secret ? 1 : 0}"

  metadata {
    name = "${var.kubernetes_secret}"
    namespace = "${var.name}"
  }

  data = {
    ".dockerconfigjson" = "${templatefile("${path.module}/templates/dockerconfigjson.tpl",  {
        repo = "${var.docker_repo}",
        username = "${var.docker_username}",
        password = "${var.docker_password}",
        email = "${var.docker_email}",
        auth = "${var.docker_auth}",
     })}"
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Tiller

resource "kubernetes_service_account" "tiller" {
  metadata {
    name = "tiller"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller-${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "tiller"
  }

  # Tiller
  subject {
    kind = "ServiceAccount"
    name = "tiller"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "null_resource" "helm_init" {
  provisioner "local-exec" {
    command = "helm init --service-account ${var.helm_service_account} --tiller-namespace ${var.name} --wait"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role" "tiller" {
  metadata {
    name = "tiller"
    namespace = "${var.name}"
  }

  rule {
    api_groups = ["", "extensions", "apps", "batch", "policy", "autoscaling", "rbac.authorization.k8s.io", "networking.k8s.io", "networking.istio.io", "authentication.istio.io"]
    resources = ["*"]
    verbs = ["*"]
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role_binding" "tiller" {
  metadata {
    name = "tiller"
    namespace = "${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "tiller"
  }

  # Tiller
  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.tiller.metadata.0.name}"
    namespace = "${kubernetes_service_account.tiller.metadata.0.namespace}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# CI/CD

resource "kubernetes_service_account" "ci" {
  metadata {
    name = "${var.ci_name}"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_cluster_role_binding" "ci-user" {
  metadata {
    name = "cluster-user-ci-${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-user"
  }

  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.ci.metadata.0.name}"
    namespace = "${kubernetes_service_account.ci.metadata.0.namespace}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_role_binding" "namespace-admin-ci" {
  metadata {
    name = "namespace-admin-${var.ci_name}"
    namespace = "${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "namespace-admin"
  }

  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.ci.metadata.0.name}"
    namespace = "${kubernetes_service_account.ci.metadata.0.namespace}"
  }

  subject {
    kind = "ServiceAccount"
    name = "${var.ci_name}"
    namespace = "ci"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_cluster_role_binding" "ci" {
  metadata {
    name = "${var.ci_name}-${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "${var.ci_name}"
  }

  subject {
    kind = "ServiceAccount"
    name = "${var.ci_name}"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# Logging

resource "kubernetes_config_map" "fluentd-config" {
  metadata {
    name = "fluentd-config"
    namespace = "${var.name}"
  }

  data = {
    "fluent.conf" = "${file("${path.module}/config/fluent.conf")}"
  }
}

# Part of a hack for module-to-module dependencies.
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
resource "null_resource" "dependency_setter" {
  # Part of a hack for module-to-module dependencies.
  # https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
  # List resource(s) that will be constructed last within the module.
  depends_on = [
    "kubernetes_role.tiller"
  ]
}
