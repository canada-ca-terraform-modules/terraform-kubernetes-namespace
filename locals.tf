locals {
  # The curent version of the release.
  version = "2.10.2"
  # The name of this module.
  app_name = "terraform-kubernetes-namespace"

  # Common labels to set on all resources.
  common_labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/name"       = local.app_name
    "app.kubernetes.io/version"    = local.version
  }
}
