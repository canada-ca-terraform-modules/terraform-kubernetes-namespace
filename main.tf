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

resource "kubernetes_service_account" "dashboard" {
  metadata {
    name = "dashboard"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# Namespace admin role bindings
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

resource "kubernetes_service_account" "octopus" {
  metadata {
    name = "octopus"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# Namespace admin role bindings
resource "kubernetes_cluster_role_binding" "octopus-user" {
  metadata {
    name = "cluster-user-octopus-${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-user"
  }

  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.octopus.metadata.0.name}"
    namespace = "${kubernetes_service_account.octopus.metadata.0.namespace}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# Namespace admin role bindings
resource "kubernetes_role_binding" "namespace-admin-octopus" {
  metadata {
    name = "namespace-admin-octopus"
    namespace = "${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "namespace-admin"
  }

  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.octopus.metadata.0.name}"
    namespace = "${kubernetes_service_account.octopus.metadata.0.namespace}"
  }

  subject {
    kind = "ServiceAccount"
    name = "octopus"
    namespace = "ci"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "kubernetes_cluster_role_binding" "octopus" {
  metadata {
    name = "octopus-${var.name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "octopus"
  }

  subject {
    kind = "ServiceAccount"
    name = "ocotpus"
    namespace = "${var.name}"
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

# Namespace admin role
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

# Namespace admin role bindings
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

# Namespace admin role bindings
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

resource "kubernetes_secret" "secret_registry" {
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

resource "kubernetes_service_account" "tiller" {
  metadata {
    name = "tiller"
    namespace = "${var.name}"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

# Tiller role bindings
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

# Tiller role
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

# Tiller role bindings
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

# Setup namespace logs
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
