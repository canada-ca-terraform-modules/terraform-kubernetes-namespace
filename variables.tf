variable "name" {
  type        = string
  nullable    = false
  description = "The name of the namespace."

  validation {
    condition     = var.name != ""
    error_message = "The name of the namespace cannot be null or empty."
  }
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

  description = "Defines the users and groups that will be admins in the namespace."
}

variable "allowed_storage" {
  type        = string
  nullable    = false
  default     = "0"
  description = "The sum of allowed storage requests across all PVCs in this namespace."
  validation {
    condition     = length(regexall("^-.*", var.allowed_storage)) > 0
    error_message = "The sum of allowed storage requests cannot be less than 0."
  }
}

variable "allowed_loadbalancers" {
  type        = number
  default     = 0
  description = "The number of Services of type LoadBalancer which can be specified in the namespace."
  validation {
    condition     = var.allowed_loadbalancers >= 0
    error_message = "The number of NodePorts cannot be less than 0."
  }
}

variable "allowed_nodeports" {
  type        = number
  default     = 0
  description = "The number of NodePorts which can be specified in Services across the namespace."
  validation {
    condition     = var.allowed_nodeports >= 0
    error_message = "The number of NodePorts cannot be less than 0."
  }
}

variable "docker_repo" {
  type        = string
  default     = "null"
  description = "The name of the docker repo that will be created"
}

variable "docker_username" {
  type        = string
  default     = "null"
  description = "The username for authenticating against the docker repo"
}

variable "docker_password" {
  type        = string
  default     = "null"
  description = "The password for authenticating against the docker repo"
}

variable "docker_email" {
  type        = string
  default     = "null"
  description = "The email for authenticating against the docker repo"
}

variable "docker_auth" {
  type        = string
  default     = "null"
  description = "The auth for authenticating against the docker repo"
}

variable "enable_kubernetes_secret" {
  type        = string
  default     = "0"
  description = "Whether to enable a custom image pull secret"
}

variable "kubernetes_secret" {
  type        = string
  default     = "null"
  description = "The name of the secret that will be created"
}

variable "ci_name" {
  type        = string
  nullable    = false
  description = "The service account to use for CI"
}

variable "fluentd_config" {
  type        = string
  default     = <<EOF
<match **>
  @type default
</match>
EOF
  description = "The fluentd configuration to use for the namespace"
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
