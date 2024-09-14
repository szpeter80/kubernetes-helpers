resource "azurerm_storage_account" "clustersto" {
  name                     = "clustersto"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_storage_container" "container--artifacts" {
  name                  = "artifacts"
  storage_account_name  = azurerm_storage_account.clustersto.name
  #container_access_type = "private"
}

# https://thomasthornton.cloud/2022/07/11/uploading-contents-of-a-folder-to-azure-blob-storage-using-terraform/
### resource "azurerm_storage_blob" "fcos-vhd" {
###   timeouts {
###     create = "5m"
###     update = "5m"
###     delete = "5m"
###   }
### 
###   name                   = "fcos.vhd"
###   storage_account_name   = azurerm_storage_account.clustersto.name
###   storage_container_name = azurerm_storage_container.container--artifacts.name
###   type                   = "Block"
###   source                 = "../fcos.vhd"
###   #content_md5            = filemd5("../fcos.vhd") 
### }

resource "azurerm_image" "fcos-img" {
  name                = "fcos-img"
  location            = var.location
  resource_group_name = var.resource_group_name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    #blob_uri = azurerm_storage_blob.fcos-vhd.url
    blob_uri = "https://example.blob.core.windows.net/artifacts/fcos.vhd"
    #size_gb  = 30
  }
}