

resource "azurerm_user_assigned_identity" "uais_cognitive_services" {
  provider = azurerm.ailz
  #for_each            = local.uai_content_safety_names
  name                = "uai-cognitive-services-${var.basename}-${var.deployment_environment}"
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}

# ##################################################################################################
# ####                Role Assignment to Storage Account
# ##################################################################################################

resource "azurerm_role_assignment" "role-storage-cognitive-services" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.uais_cognitive_services.principal_id
}
#central
resource "azurerm_role_assignment" "role-storage-central-cognitive-services" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.uais_cognitive_services.principal_id
}

#resource "azurerm_role_assignment" "role-cognitive-services-contributor" {
#  provider             = azurerm.ailz
#  scope                = module.cognitive_services.cognitive_account_id
#  role_definition_name = "Cognitive Services Contributor"
#  principal_id         = azurerm_user_assigned_identity.uais_cognitive_services.principal_id
#}

resource "azurerm_role_assignment" "role-cognitive-services-openai-contributor" {
  provider             = azurerm.ailz
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = azurerm_user_assigned_identity.uais_cognitive_services.principal_id
}

#resource "azurerm_role_assignment" "role-cognitive-services-user-assigned" {
#  provider             = azurerm.ailz
#  scope                = module.cognitive_services.cognitive_account_id
#  role_definition_name = "Cognitive Services User"
#  principal_id         = "a34a9364-8d17-4273-9405-e3180fd464f8"
#}



# ##################################################################################################
# ####                Role Assignment system assigment identity to Cognitive Services
# ##################################################################################################
resource "azurerm_role_assignment" "role-storage-cognitive-services-system-assigned-identity" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value
  principal_id         = module.cognitive_services.system_assigned_identity_principal_id
}
#central
resource "azurerm_role_assignment" "role-storage-central-cognitive-services-system-assigned-identity" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = module.cognitive_services.system_assigned_identity_principal_id
}

#resource "azurerm_role_assignment" "role-cognitive-services-contributor-system-assigned-identity" {
#  provider             = azurerm.ailz
#  scope                = module.cognitive_services.cognitive_account_id
#  role_definition_name = "Cognitive Services Contributor"
#  principal_id         = module.cognitive_services.system_assigned_identity_principal_id
#}

resource "azurerm_role_assignment" "role-cognitive-services-openai-contributor-system-assigned-identity" {
  provider             = azurerm.ailz
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = module.cognitive_services.system_assigned_identity_principal_id
}
# ##################################################################################################
# ####                Cognitive Services Account Module
# ##################################################################################################

module "cognitive_services" {
    providers = {
      azurerm  = azurerm.ailz
    }
  
    source                        = "./modules/az_cognitive_account"
    basename                      = "ailz-service-account"
    suffix                        = substr(local.random_seed_hex, 0, 4)
    location                      = local.location
    resource_group_name           = "rg-ailz-proyecto-dll-eastus-001"
    sku_name                      = "S0"
    kind                          = "CognitiveServices"
    public_network_access_enabled = false
    identity_uai_ids              = [azurerm_user_assigned_identity.uais_cognitive_services.id]
    inbound_subnet_id             = azurerm_subnet.pep_subnet.id
    enable_storage_account_diag   = true
    storage_account_id_diag       = module.diag_storage_account.storage-account-id
  }