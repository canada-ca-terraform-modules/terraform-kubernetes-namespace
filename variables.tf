variable "name" {
  type = string
}

variable "namespace_admins" {
  type = object({
    users  = list(string)
    groups = list(string)
  })

  default = {
    users  = []
    groups = []
  }
}

variable "allowed_loadbalancers" {
  type    = number
  default = 0
}

variable "allowed_nodeports" {
  type    = number
  default = 0
}

variable "dependencies" {
  type = list(any)
}

variable "docker_repo" {
  type    = string
  default = "null"
}

variable "docker_username" {
  type    = string
  default = "null"
}

variable "docker_password" {
  type    = string
  default = "null"
}

variable "docker_email" {
  type    = string
  default = "null"
}

variable "docker_auth" {
  type    = string
  default = "null"
}

variable "enable_kubernetes_secret" {
  type    = string
  default = "0"
}

variable "kubernetes_secret" {
  type    = string
  default = "null"
}

variable "ci_name" {
  type = string
}

variable "fluentd_config" {
  type    = string
  default = <<EOF
<match **>
  @type default
</match>
EOF
}
