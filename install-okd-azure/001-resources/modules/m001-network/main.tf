resource "azurerm_virtual_network" "okd-vnet" {
  name                = "okdvnet"
  address_space       = ["10.100.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet_clusterpriv" {
  name                 = "subnet_clusterpriv"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.okd-vnet.name
  address_prefixes     = ["10.100.1.0/24"]
}

resource "azurerm_public_ip" "vm-okd-services-pip0" {
  name                = "vmokdservicespip0"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Dynamic"
}

// public ip known only after deployment, so we read back our resource, in a 2nd terraform run
data "azurerm_public_ip" "vm-okd-services-pip0" {
  name                = azurerm_public_ip.vm-okd-services-pip0.name
  resource_group_name = azurerm_public_ip.vm-okd-services-pip0.resource_group_name

  timeouts {
    read = "10m"
  }
}

# Forward DNS zone
resource "azurerm_private_dns_zone" "okd_dns_zone" {
  name                = "okd-demo.zzz"
  resource_group_name = var.resource_group_name
}

# Associate the DNS zone to the Vnet assigned to the VM's network
resource "azurerm_private_dns_zone_virtual_network_link" "okd_dns_zone_link" {
  name                  = "okd_dns_zone_link"
  resource_group_name = var.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.okd_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.okd-vnet.id
}


# The reverse zone
resource "azurerm_private_dns_zone" "okd_dns_revzone" {
  name                = "1.100.10.in-addr.arpa"
  resource_group_name = var.resource_group_name
}

# Link reverse zone to the vm's Vnet
resource "azurerm_private_dns_zone_virtual_network_link" "okd_dns_revzone_link" {
  name                  = "okd_dns_revzone_link"
  resource_group_name = var.resource_group_name

  private_dns_zone_name = azurerm_private_dns_zone.okd_dns_revzone.name
  virtual_network_id    = azurerm_virtual_network.okd-vnet.id
}


