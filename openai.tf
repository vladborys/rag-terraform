resource "azurerm_user_assigned_identity" "uais_openai" {
  provider = azurerm.ailz

  for_each            = local.uai_openai_names
  name                = local.uai_openai_names[each.key]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}
#Cognitive Services OpenAI User
resource "azurerm_role_assignment" "openai-role-assign-contributor" {
  provider             = azurerm.ailz
  for_each             = azurerm_user_assigned_identity.uais_openai
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = each.value.principal_id
}

###############################################################################################
###                        role openai system assigned identity
###############################################################################################

resource "azurerm_role_assignment" "role-openai-system-assigment-contributor" {
  provider             = azurerm.ailz
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = module.openai["main"].system_assigned_identity_principal_id
  depends_on = [ module.openai ]
}


###############################################################################################
###                        OpenAI Cognitive Services Account
###############################################################################################

module "openai" {
  providers = {
    azurerm = azurerm.ailz
  }

  for_each = var.openai_config

  source                        = "./modules/az_cognitive_account"
  basename                      = each.value.main_name
  suffix                        = substr(local.random_seed_hex, 0, 4)
  location                      = local.location
  resource_group_name           = local.persistent_resource_group_name
  sku_name                      = each.value.sku
  kind                          = each.value.kind
  public_network_access_enabled = each.value.is_public_network_access_enabled
  identity_uai_ids              = [azurerm_user_assigned_identity.uais_openai[each.key].id]
  inbound_subnet_id             = azurerm_subnet.pep_subnet.id
  enable_storage_account_diag   = true
  storage_account_id_diag       = module.diag_storage_account.storage-account-id
  
  model_deployments             = each.value.models_definition
}
