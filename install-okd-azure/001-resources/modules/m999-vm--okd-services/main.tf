resource "azurerm_network_interface" "okd-services--nic0" {
  name                  = "okd-services--nic0"
  location              = var.location
  resource_group_name   = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.100.1.100"
    
    public_ip_address_id            = var.vm_pip.id
  }

}

resource "azurerm_linux_virtual_machine" "okd-services" {
  name                 = "okd-services"
  resource_group_name  = var.resource_group_name
  location             = var.location

  # size                 = var.instance_type
  size                 = "Standard_B2s"

  plan {
    name               = "rockylinux-9"
    product            = "rockylinux-9"
    publisher          = "erockyenterprisesoftwarefoundationinc1653071250513"
  }

  source_image_reference {
    publisher          = "erockyenterprisesoftwarefoundationinc1653071250513"
    offer              = "rockylinux-9"
    sku                = "rockylinux-9"
    version            = "latest" 
  }

  os_disk {
    # disk_size_gb         =  100
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface_ids = [
    azurerm_network_interface.okd-services--nic0.id,
  ]

  admin_username        = "${var.vm_adminuser}"
  admin_ssh_key {
    username            = "${var.vm_adminuser}"
    public_key          = file("${var.remote_admin_sshprivkey_fn}.pub")
  }

  # required for serial console
  boot_diagnostics {
    # null means it will use a managed storage account to store related data
    storage_account_uri = null
  }

  tags = var.tags
}

### Forward entries

### https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-dns-user-infra_installing-bare-metal

# Kubernetes API entry
resource "azurerm_private_dns_cname_record" "dns_okd_api" {
  name                = "api.${var.x_okd_cluster_name}" 
  zone_name           = var.okd_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  record              = "okd-services.${ azurerm_network_interface.okd-services--nic0.internal_domain_name_suffix }"
}

resource "azurerm_private_dns_cname_record" "dns_okd_apiint" {
  name                = "api-int.${var.x_okd_cluster_name}" 
  zone_name           = var.okd_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  record              = "okd-services.${ azurerm_network_interface.okd-services--nic0.internal_domain_name_suffix }"
}

# Kubernetes routes wildcard
resource "azurerm_private_dns_cname_record" "dns_okd_apps" {
  name                = "*.apps.${var.x_okd_cluster_name}" 
  zone_name           = var.okd_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  record              = "okd-services.${ azurerm_network_interface.okd-services--nic0.internal_domain_name_suffix }"
}

# Reverse DNS entries

resource "azurerm_private_dns_ptr_record" "revdns_okd_services" {
  name                = "100" 
  zone_name           = var.okd_dns_revzone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  records              = [
    "api.${var.x_okd_cluster_name}.${var.okd_dns_zone.name}",
    "api-int.${var.x_okd_cluster_name}.${var.okd_dns_zone.name}",
  ]
}