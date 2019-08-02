variable "helm_service_account" {}

variable "name" {
  type = string
}

variable "namespace_admins" {
  type = object({
    users = list(string)
    groups = list(string)
  })

  default = {
    users = []
    groups = []
  }
}

variable "allowed_loadbalancers" {
  type = number
  default = 0
}

variable "allowed_nodeports" {
  type = number
  default = 0
}

variable "dependencies" {
  type = "list"
}

variable "docker_repo" {
  type = string
}

variable "docker_username" {
  type = string
}

variable "docker_password" {
  type = string
}

variable "docker_email" {
  type = string
}

variable "docker_auth" {
  type = string
}

variable "kubernetes_secret" {
  type = string
}
