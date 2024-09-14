resource "azurerm_network_interface" "okd-bootstrap--nic0" {
  name                = "okd-bootstrap--nic0"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.100.1.101"
  }
}

resource "azurerm_linux_virtual_machine" "okd-bootstrap" {
  name                = "bootstrap"

  resource_group_name = var.resource_group_name
  location            = var.location

  size                = var.instance_type

  source_image_id     = var.cluster_node_image_id

  # required for serial console
  boot_diagnostics {
    # null means it will use a managed storage account to store related data
    storage_account_uri = null
  }

  os_disk {
    disk_size_gb         =  100
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface_ids = ["${azurerm_network_interface.okd-bootstrap--nic0.id}"]

  admin_username        = "${var.vm_adminuser}"
  admin_ssh_key {
    username            = "${var.vm_adminuser}"
    public_key          = file("${var.remote_admin_sshprivkey_fn}.pub")
  }

  custom_data = filebase64("modules/m101-vm--okd-cluster-bootstrap/provision_bootstrap.ign")

  tags = var.tags
}


### Forward entries

### https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-dns-user-infra_installing-bare-metal


# Bootstrap node, forward DNS entry
resource "azurerm_private_dns_cname_record" "dns_okd_bootstrap" {
  name                = "bootstrap.${var.x_okd_cluster_name}" 
  zone_name           = var.okd_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  record              = "bootstrap.${ azurerm_network_interface.okd-bootstrap--nic0.internal_domain_name_suffix }"
}

# Bootstrap node, reverse DNS entry, pointing to the CNAME
resource "azurerm_private_dns_ptr_record" "revdns_okd_bootstrap" {
  name                = "101" 
  zone_name           = var.okd_dns_revzone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  records              = [ "bootstrap.${var.x_okd_cluster_name}.${var.okd_dns_zone.name}" ]
}