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

variable "allowed_hosts" {
  type        = list(string)
  default     = []
  description = <<-EOF
    A list of the hosts that are allowed by the restrict-hostnames policy to be used by ingress & VirtualService Kuberenetes resources in the namespace.
    Path allowance is based on the path as a prefix, there if the value test.ca/baz is passed to the allowed_hosts variable, the /baz/foo and /bazfoobar 
    would be permitted by the policy. A path of / should allow anything.
  EOF
}
