resource "azurerm_network_interface" "okd-nodes--nic0" {
  count = "${var.cluster_node_count}"

  name                = "okd-node-${format("%02d", count.index+1)}--nic0"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.100.1.${(count.index+11)}"
  }
}


resource "azurerm_linux_virtual_machine" "okd-nodes" {
  count = "${var.cluster_node_count}"

  # name                = "okd-node-${format("%02d", count.index+1)}"
  name                = "master${format("%01d", count.index+1)}"
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
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  network_interface_ids = ["${element(azurerm_network_interface.okd-nodes--nic0.*.id, count.index)}"]

  admin_username        = "${var.vm_adminuser}"
  admin_ssh_key {
    username            = "${var.vm_adminuser}"
    public_key          = file("${var.remote_admin_sshprivkey_fn}.pub")
  }

  custom_data = filebase64("modules/m100-vm--okd-cluster-nodes/provision_master.ign")

  tags = var.tags
}

### https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-dns-user-infra_installing-bare-metal

### DNS entries must match with the install-config.yaml where control and worker pools are defined

### Forward DNS entries for control nodes
resource "azurerm_private_dns_cname_record" "dns_okd_master" {
  count = 3

  name                = "master${count.index+1}.${var.x_okd_cluster_name}" 
  zone_name           = var.okd_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  # record              = "okd-node-0${count.index+1}.${ element(azurerm_network_interface.okd-nodes--nic0.*.internal_domain_name_suffix, count.index) }"
  record              = "master${count.index+1}.${ element(azurerm_network_interface.okd-nodes--nic0.*.internal_domain_name_suffix, count.index) }"
}

### Reverse DNS entries for control nodes
resource "azurerm_private_dns_ptr_record" "revdns_okd_nodes" {
  count = 3

  name                = "1${(count.index+1)}" 
  zone_name           = var.okd_dns_revzone.name
  resource_group_name = var.resource_group_name
  ttl                 = 60
  records              = [ "master${(count.index+1)}.${var.x_okd_cluster_name}.${var.okd_dns_zone.name}" ]
}
