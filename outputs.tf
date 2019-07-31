output "helm_service_account" {
    value = "${kubernetes_service_account.tiller.metadata.0.name}"
}

output "name" {
    value = "${var.name}"
}

# Part of a hack for module-to-module dependencies.
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
# and
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-473091030
output "depended_on" {
  value = "${null_resource.dependency_setter.id}-${timestamp()}"
}
