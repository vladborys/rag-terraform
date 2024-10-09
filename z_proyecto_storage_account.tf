
resource "azurerm_user_assigned_identity" "proyecto_uais_storage_account" {
  provider            = azurerm.ailz
  name                = local.uai_storage_names_proyecto["proyecto_storage"]
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  location            = local.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "role-storage-search-proyecto" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_user_assigned_identity.proyecto_uais_storage_account.principal_id
}


# ###############################################################################################
# ####                Storage account role assigned to system assigned identity
# ###############################################################################################

#resource "azurerm_role_assignment" "role-storage-system-identity-proyecto" {
#  provider             = azurerm.ailz
#  scope                = module.storage_account_proyecto.storage-account-id
#  role_definition_name = "Search Service Contributor"
#  principal_id         = module.storage_account_proyecto.system-assigned-identity-id
#}


module "storage_account_proyecto" {
  providers = {
    azurerm = azurerm.ailz
  }
  source                           = "./modules/az_storage_account"
  resource-group-name              = azurerm_resource_group.rg_proyecto.name
  location                         = local.location
  basename                         = "proy${var.basename}${var.deployment_environment}"
  diag-storage                     = local.storage_account_config_proy.diag_storage
  diag-storage-retention-days      = var.deployment_environment == "pdn" ? 365 : 7
  suffix                           = substr(local.random_seed_hex, 0, 3)
  enable-network-rules             = local.storage_account_config_proy.is_enable_network_rules
  subnet-id                        = azurerm_subnet.pep_subnet.id
  replication-type                 = local.storage_account_config_proy.replication_type
  min-tls-version                  = local.storage_account_config_proy.min_tls_version
  cross-tenant-replication-enabled = local.storage_account_config_proy.is_cross_tenant_replication_enabled
  enable-static-website            = local.storage_account_config_proy.enable_static_website
  is-enable-private-endpoint       = true
  is-public-network-access-enabled = local.storage_account_config_proy.is_public_network_access_enabled
  identity-uai-ids                 = [azurerm_user_assigned_identity.proyecto_uais_storage_account.id]
  extra-tags                       = var.tags
}

# ###############################################################################################
# ####                                Storage Container
# ###############################################################################################

resource "azurerm_storage_container" "container_products" {
  provider             = azurerm.ailz
  name                 = "products"
  storage_account_name = module.storage_account_proyecto.storage-account-name
  depends_on           = [module.storage_account_proyecto]
}


