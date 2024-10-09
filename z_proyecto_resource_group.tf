resource "azurerm_resource_group" "rg_proyecto" {
  provider = azurerm.ailz
  name     = "rg-ailz-proyecto-dll-eastus-001"
  location = "East US"
  tags = var.tags
}