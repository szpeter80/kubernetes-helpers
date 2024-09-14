resource "azurerm_resource_group" "rg-main" {
    provider = azurerm.default
    tags = var.x_default_tags

    name     = "szpl--${var.x_project_name}"
    location = var.azure_target_region
}

module "m001-network" {
    source = "./modules/m001-network"
    tags                    = var.x_default_tags
    location                = azurerm_resource_group.rg-main.location
    resource_group_name     = azurerm_resource_group.rg-main.name

    x_okd_cluster_name      = var.x_okd_cluster_name
}

module "m002-storage" {
    source = "./modules/m002-storage"
    tags                    = var.x_default_tags
    location                = azurerm_resource_group.rg-main.location
    resource_group_name     = azurerm_resource_group.rg-main.name
}

module "m100-vm--okd-cluster-nodes" {
    source = "./modules/m100-vm--okd-cluster-nodes"

    # Bootstrap ignition files hosted on the service node
    depends_on = [ module.m999-vm--okd-services,  module.m101-vm--okd-cluster-bootstrap]

    tags                    = var.x_default_tags
    location                = azurerm_resource_group.rg-main.location
    resource_group_name     = azurerm_resource_group.rg-main.name

    subnet_id               = module.m001-network.project_subnet_cluster.id
    instance_type           = var.x_vm_instance_name_linux

    cluster_node_count      = var.x_cluster_node_count
    cluster_node_image_id   = module.m002-storage.fcos-img.id

    vm_adminuser            = "adminuser"
    remote_admin_sshprivkey_fn = var.x_remote_admin_sshprivkey_fn

    x_okd_cluster_name      = var.x_okd_cluster_name

    okd_dns_zone            = module.m001-network.o_project_dns_zone
    okd_dns_revzone         = module.m001-network.o_project_dns_revzone

}

module "m101-vm--okd-cluster-bootstrap" {
    source = "./modules/m101-vm--okd-cluster-bootstrap"

    # Bootstrap ignition files hosted on the service node
    depends_on = [ module.m999-vm--okd-services ]

    tags                    = var.x_default_tags
    location                = azurerm_resource_group.rg-main.location
    resource_group_name     = azurerm_resource_group.rg-main.name

    subnet_id               = module.m001-network.project_subnet_cluster.id
    instance_type           = var.x_vm_instance_name_linux
    vm_adminuser            = "adminuser"
    remote_admin_sshprivkey_fn = var.x_remote_admin_sshprivkey_fn

    cluster_node_image_id   = module.m002-storage.fcos-img.id

    x_okd_cluster_name      = var.x_okd_cluster_name

    okd_dns_zone            = module.m001-network.o_project_dns_zone
    okd_dns_revzone         = module.m001-network.o_project_dns_revzone
}

module "m999-vm--okd-services" {
    source = "./modules/m999-vm--okd-services"
    tags                       = var.x_default_tags
    location                   = azurerm_resource_group.rg-main.location
    resource_group_name        = azurerm_resource_group.rg-main.name

    vm_pip                     = module.m001-network.o_vm-okd-services-pip0
    vm_adminuser               = "adminuser"
    remote_admin_sshprivkey_fn = var.x_remote_admin_sshprivkey_fn

    subnet_id                  = module.m001-network.project_subnet_cluster.id
    instance_type              = var.x_vm_instance_name_linux
    
    x_okd_cluster_name      = var.x_okd_cluster_name

    okd_dns_zone            = module.m001-network.o_project_dns_zone
    okd_dns_revzone         = module.m001-network.o_project_dns_revzone
}
