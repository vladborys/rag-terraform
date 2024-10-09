resource "azurerm_user_assigned_identity" "uais_search" {
  provider            = azurerm.ailz
  for_each            = local.search_properties.srch_keys
  name                = local.uai_search_names[each.value]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}

# ###############################################################################################
# ####                role assigned identity to storage and access policy to storage
# ###############################################################################################
resource "azurerm_role_assignment" "role-storage-search-ailz" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.uais_search["main"].principal_id
}

resource "azurerm_role_assignment" "role-storage-search-principal-storage" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.uais_search["main"].principal_id
}

# ###############################################################################################
# ####                role assigned identity search service to openai
# ###############################################################################################

resource "azurerm_role_assignment" "role-assign-search-cogaccount" {
  provider     = azurerm.ailz
  for_each     = azurerm_user_assigned_identity.uais_search
 
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = each.value.principal_id
  
  depends_on = [ module.az_search ]
}

# ###############################################################################################
# ####                role assigned identity search service to cognitive services
# ###############################################################################################

resource "azurerm_role_assignment" "role-assign-search-cogaccount-cognitive-services" {
  provider     = azurerm.ailz
  for_each     = azurerm_user_assigned_identity.uais_search
 
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = each.value.principal_id
  
  depends_on = [ module.az_search ]
}


# ###############################################################################################
# ####                role assigned identity search service data index contributor
# ###############################################################################################
resource "azurerm_role_assignment" "role-assign-search-data-index-contributor" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azurerm_user_assigned_identity.uais_search["main"].principal_id
}

resource "azurerm_role_assignment" "role-assign-search-contributor" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_user_assigned_identity.uais_search["main"].principal_id
}

###############################################################################################
###                        System assigned identity assigned roles
###############################################################################################

resource "azurerm_role_assignment" "role-assign-search-system-identity" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = module.az_search["main"].system_assigned_identity
}

#Search Index Data Contributor
resource "azurerm_role_assignment" "role-assign-search-data-index-contributor-system-identity" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = module.az_search["main"].system_assigned_identity
}
#Cognitive Services OpenAI User
resource "azurerm_role_assignment" "role-assign-search-cogaccount-system-identity" {
  provider             = azurerm.ailz
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = module.az_search["main"].system_assigned_identity
}

#role storage account
resource "azurerm_role_assignment" "role-storage-system-identity" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value
  principal_id         = module.az_search["main"].system_assigned_identity
}


resource "azurerm_role_assignment" "role-storage-system-identity-principal-storage" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = module.az_search["main"].system_assigned_identity
}

# ###############################################################################################
# ####                role assigned identity search service to my user
# ###############################################################################################
#a34a9364-8d17-4273-9405-e3180fd464f8
#resource "azurerm_role_assignment" "role-assign-search-data-index-contributor-my-user" {
#  provider             = azurerm.ailz
#  scope                = module.az_search["main"].search_service_id
#  role_definition_name = "Search Index Data Contributor"
#  principal_id         = "a34a9364-8d17-4273-9405-e3180fd464f8"
#}

###############################################################################################
###                                     Search Service module
###############################################################################################

module "az_search" {
  providers = {
    azurerm = azurerm.ailz
  }
  for_each                        = var.az_search_config
  
  source                           = "./modules/az_search"
  subnet_id                        = azurerm_subnet.pep_subnet.id
  is_public_network_access_enabled = each.value.is_public_network_access_enabled
  semantic_search_sku              = each.value.semantic_search_sku
  suffix                           = local.random_seed_hex
  sku                              = each.value.sku
  resource_group_name              = local.persistent_resource_group_name
  basename                         = each.value.main_name
  private_dns_zone_id              = local.search_properties.private_dns_id
  identity_uai_ids                 = [azurerm_user_assigned_identity.uais_search[each.key].id] #arreglar
  replica_count                    = each.value.replica_count
  partition_count                  = each.value.partition_count
  enforcement                      = each.value.enforcement
  resource_group_id                = data.azurerm_resource_group.properties_rg.id
  hosting_mode                     = each.value.hosting_mode
  disable_local_auth               = each.value.disable_local_auth
  aad_auth_failure_mode            = each.value.aad_auth_failure_mode
  extra_tags                       = var.tags
}

###############################################################################################
###                     Shared Private Link Service to Function data ingestion
###############################################################################################
resource "azurerm_search_shared_private_link_service" "search-private-link-function-data-ingestion" {
  provider            = azurerm.ailz
  name                = "search-private-share-link-function-sites-data-ingestion"
  search_service_id   = module.az_search["main"].search_service_id
  subresource_name    = "sites"
  target_resource_id  = module.az_function_proyecto["dataingestion"].function-id
  request_message     = "Connection between the search service and the data ingestion function"

}

# ###############################################################################################
# ####                Private Link between Search Service and Storage Account
# ###############################################################################################

resource "azurerm_search_shared_private_link_service" "search_private_link_blob" {
  provider            = azurerm.ailz
  name                = "search-private-share-link-blob"
  search_service_id   = module.az_search["main"].search_service_id
  subresource_name    = "blob"
  target_resource_id  = module.storage_account_proyecto.storage-account-id
  request_message     = "Connection between the search service and the storage account"
}