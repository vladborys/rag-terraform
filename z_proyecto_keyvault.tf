module "keyvault_proyecto" {
  providers = {
    azurerm = azurerm.ailz
  }

  #   for_each = var.keyvaults

  #source                    = "git::https://<Name>@dev.azure.com/<Name>/Tecnologia/_git/ti-lego-iac-azurerm-keyvault-lb?ref=v1.3"
  source = "./modules/az_keyvault"
  location                  = local.location
  resource-group-name       = azurerm_resource_group.rg_proyecto.name
  basename                  = "proy${var.basename}${var.deployment_environment}"
  suffix                    = substr(local.random_seed_hex, 0, 2)
  enable-rbac-authorization = false
  extra-tags                = var.tags
}

resource "azurerm_private_endpoint" "keyvaults-pep-proy" {
  provider = azurerm.ailz

  #   for_each = var.keyvaults

  name                = "pep-proy-${module.keyvault_proyecto.key-vault-name}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  subnet_id           = azurerm_subnet.pep_subnet.id
  private_service_connection {
    name                           = module.keyvault_proyecto.key-vault-name
    private_connection_resource_id = module.keyvault_proyecto.key-vault-id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
  ################# arreglar dns a todos los keyvault
  private_dns_zone_group {
    name                 = "pdzg-proy-${module.keyvault_proyecto.key-vault-name}"
    private_dns_zone_ids = [local.keyvault_properties.private_dns_id]
  }
}
