output "project_vnet" {
  value = {
    id = "${azurerm_virtual_network.okd-vnet.id}"
  }
}

output "project_subnet_cluster" {
  value = {
    id = "${azurerm_subnet.subnet_clusterpriv.id}"
  }
}

output "o_vm-okd-services-pip0" {
  value = {
    id         = "${azurerm_public_ip.vm-okd-services-pip0.id}"
    name       = "${azurerm_public_ip.vm-okd-services-pip0.name}"
    ip_address = "${data.azurerm_public_ip.vm-okd-services-pip0.ip_address}"
  }
}

output "o_project_dns_zone" {
  value = azurerm_private_dns_zone.okd_dns_zone
}

output "o_project_dns_revzone" {
  value = azurerm_private_dns_zone.okd_dns_revzone
}
