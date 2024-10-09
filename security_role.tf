##########################################################################################
#####                             Service principal roles
##########################################################################################


resource "azurerm_role_assignment" "role-cognitive-services-current-user-assigned" {
  provider             = azurerm.ailz
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = data.azurerm_client_config.current-user.object_id
}

resource "azurerm_role_assignment" "role-cognitive-services-current-user-assigned-user" {
  provider             = azurerm.ailz
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = data.azurerm_client_config.current-user.object_id
}

#Search index data contributor
resource "azurerm_role_assignment" "role-search-index-data-contributor-current-user-assigned" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = data.azurerm_client_config.current-user.object_id
}

#Search service contributor
resource "azurerm_role_assignment" "role-search-service-data-contributor-current-user-assigned" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = data.azurerm_client_config.current-user.object_id
}

#Storage blob data reader - storage blob

resource "azurerm_role_assignment" "current-user-identity-role-central-storage" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = data.azurerm_client_config.current-user.object_id

}

resource "azurerm_role_assignment" "current-user-identity-role-proy-storage" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value
  principal_id         = data.azurerm_client_config.current-user.object_id
}

resource "azurerm_role_assignment" "role-assign-openai-current-user" {
  provider              = azurerm.ailz

  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = data.azurerm_client_config.current-user.object_id
}



#<PID>

##########################################################################################
#####                             Roles assigned to me 
##########################################################################################


resource "azurerm_role_assignment" "role-cognitive-services-assgined-to-me" {
  provider             = azurerm.ailz
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = "<PID>"
}

resource "azurerm_role_assignment" "role-cognitive-services-assgined-to-me-user" {
  provider             = azurerm.ailz
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = "<PID>"
}

#Search index data contributor
resource "azurerm_role_assignment" "role-search-index-data-contributor-assgined-to-me" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = "<PID>"
}

#Search service contributor
resource "azurerm_role_assignment" "role-search-service-data-contributor-assgined-to-me" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = "<PID>"
}

#Storage blob data reader - storage blob

resource "azurerm_role_assignment" "role-assign-openai-assigned-to-me" {
  provider              = azurerm.ailz

  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = "<PID>"
}
