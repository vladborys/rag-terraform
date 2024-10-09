resource "azurerm_user_assigned_identity" "uais_diag_storage" {

  provider = azurerm.ailz

  #for_each            = local.blob_properties.storage_keys
  name                = local.uai_storage_names["main_diag_storage"]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}


module "diag_storage_account" {
  providers = {
    azurerm = azurerm.ailz
  }

  #source                          = "git::https://SuraColombia@dev.azure.com/SuraColombia/Gerencia_Tecnologia/_git/ti-lego-iac-azurerm-storage-lb?ref=v1.2"
  source                           = "./modules/az_storage_account"
  resource-group-name              = local.persistent_resource_group_name
  location                         = local.location
  basename                         = "dg${var.basename}${var.deployment_environment}"
  diag-storage                     = var.diag_storage_config.diag_storage
  diag-storage-retention-days      = var.deployment_environment == "pdn" ? 365 : 7
  suffix                           = substr(local.random_seed_hex, 0, 2)
  identity-uai-ids                 = [azurerm_user_assigned_identity.uais_diag_storage.id]
  is-public-network-access-enabled = var.diag_storage_config.is_public_network_access_enabled
  is-enable-private-endpoint       = true
  subnet-id                        = azurerm_subnet.pep_subnet.id
  enable-network-rules             = var.diag_storage_config.is_enable_network_rules
  replication-type                 = var.diag_storage_config.replication_type
  min-tls-version                  = var.diag_storage_config.min_tls_version
  enable-static-website            = var.diag_storage_config.enable_static_website
  cross-tenant-replication-enabled = var.diag_storage_config.is_cross_tenant_replication_enabled
  extra-tags                       = var.tags
}

















#resource "azurerm_private_endpoint" "blob-storage-pep" {
#  provider = azurerm.ailz
#
#  name                = "pep-${module.diag_storage.storage-account-name}"
#  location            = local.location
#  resource_group_name = local.persistent_resource_group_name
#  subnet_id           = azurerm_subnet.pep_subnet.id
#  private_service_connection {
#    name                           = module.diag_storage.storage-account-name
#    private_connection_resource_id = module.diag_storage.storage-account-id
#    subresource_names              = ["blob"] #dfs queu ....
#    is_manual_connection           = false
#  }
#  private_dns_zone_group {
#    name                 = "pdzg-${module.diag_storage.storage-account-name}"
#    private_dns_zone_ids = [local.blob_properties.private_dns_id]
#  }
#}
