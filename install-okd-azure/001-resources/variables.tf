# Azure deployment target specification
variable "azure_target_region" {
  type = string
  default = "westeurope"
}
variable "azure_tenant_id" {
  type = string
}
variable "azure_subscription_id" {
  type = string
}

# Project name
variable "x_project_name" {
    type = string
    default = "my-project"
}

# This is set in env outside terraform
variable "x_remote_admin_sshprivkey_fn" {
    type = string
}

# This is set in env outside terraform
variable "x_okd_cluster_name" {
  type = string
}

# Services, bootstrap and cluster nodes size spec
variable "x_vm_instance_name_linux" {
    type = string
}
variable "x_cluster_node_count" {
  type = number
}

variable "x_default_tags" {
    type = any
}
