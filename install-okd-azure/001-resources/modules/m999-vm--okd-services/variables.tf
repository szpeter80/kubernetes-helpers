variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}


variable "instance_type" {
  type = string
}

variable "tags" {
  type = any
}

variable "vm_pip" {
  type = any
}

variable "vm_adminuser" {
  type = string
}

variable "remote_admin_sshprivkey_fn" {
  type = string
}

variable "x_okd_cluster_name" {
  type = string
}

variable "okd_dns_zone" {
  type = any
}

variable "okd_dns_revzone" {
  type = any
}
