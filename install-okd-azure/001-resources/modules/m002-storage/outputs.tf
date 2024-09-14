output "openshift-storage-container-artifacts" {
  value = {
    id = "${azurerm_storage_container.container--artifacts.id}"
  }
}

output "fcos-img" {
  value = {
    id = "${azurerm_image.fcos-img.id}"
  }
}