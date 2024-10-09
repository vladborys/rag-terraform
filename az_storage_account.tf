
resource "azurerm_user_assigned_identity" "uais_storage_account" {

  provider = azurerm.ailz

  #for_each            = local.blob_properties.storage_keys
  name                = local.uai_storage_names["main_storage"]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}



module "storage_account" {
  providers = {
    azurerm = azurerm.ailz
  }
  source                            = "./modules/az_storage_account"
  resource-group-name               = local.persistent_resource_group_name
  location                          = local.location
  basename                          = "${var.basename}${var.deployment_environment}"
  diag-storage                      = var.storage_account_config.diag_storage
  diag-storage-retention-days       = var.deployment_environment == "pdn" ? 365 : 7
  suffix                            = substr(local.random_seed_hex, 0, 2)
  enable-network-rules              = var.storage_account_config.is_enable_network_rules
  subnet-id                         = azurerm_subnet.pep_subnet.id
  replication-type                  = var.storage_account_config.replication_type
  min-tls-version                   = var.storage_account_config.min_tls_version
  cross-tenant-replication-enabled  = var.storage_account_config.is_cross_tenant_replication_enabled
  enable-static-website             = var.storage_account_config.enable_static_website
  is-enable-private-endpoint        = true
  is-public-network-access-enabled  = var.storage_account_config.is_public_network_access_enabled
  identity-uai-ids                  = [azurerm_user_assigned_identity.uais_storage_account.id]
  extra-tags                        = var.tags
}



