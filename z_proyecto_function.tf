# # https://github.com/hashicorp/terraform-provider-azurerm/issues/24730
# # definir el uai-id

data "azurerm_client_config" "current" {}


# ###################################################################################################################################
# ####                                              Creation assigned identity
# ###################################################################################################################################

resource "azurerm_user_assigned_identity" "uais_function_app_proy" {
  provider = azurerm.ailz

  for_each            = local.uai_function_names_proyecto
  name                = local.uai_function_names_proyecto[each.key]
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  location            = local.location
  tags                = var.tags
}

# ###################################################################################################################################
# ####                             role assigned identity to storage and access policy to storage
# ###################################################################################################################################

#storage proyecto
resource "azurerm_role_assignment" "storage_account_roles_proyecto" {
  provider = azurerm.ailz

  for_each = local.storage_account_roles_proyecto_map

  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.object_id
}

#storage central
resource "azurerm_role_assignment" "storage_account_roles_central" {
  provider = azurerm.ailz

  for_each = local.storage_account_roles_proyecto_map

  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.object_id
}


resource "azurerm_key_vault_access_policy" "regional_access_policies_proyecto" {
  provider = azurerm.ailz

  for_each     = local.uai_function_names_proyecto                                            #local.policy_access_key_proyecto_map
  key_vault_id = module.keyvault_proyecto.key-vault-id                                        #each.value.key_vault_id
  tenant_id    = azurerm_user_assigned_identity.uais_function_app_proy[each.key].tenant_id    #each.value.tenant_id
  object_id    = azurerm_user_assigned_identity.uais_function_app_proy[each.key].principal_id #each.value.principal_id
  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]
}
#### Infra central
resource "azurerm_key_vault_access_policy" "regional_access_policies_infra_central" {
  provider = azurerm.ailz

  for_each     = local.uai_function_names_proyecto
  key_vault_id = module.keyvaults["main"].key-vault-id
  tenant_id    = azurerm_user_assigned_identity.uais_function_app_proy[each.key].tenant_id
  object_id    = azurerm_user_assigned_identity.uais_function_app_proy[each.key].principal_id

  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]

}

resource "azurerm_role_assignment" "role-assign-function-keyvault-proyecto" {
  provider = azurerm.ailz
  for_each = local.uai_function_names_proyecto

  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_user_assigned_identity.uais_function_app_proy[each.key].principal_id

  depends_on = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "role-assign-function-cogaccount" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app_proy

  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function_proyecto]
}


resource "azurerm_role_assignment" "role-assign-function-cogaccount-user" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app_proy

  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function_proyecto]
}
#resource "azurerm_role_assignment" "role-assign-function-cogaccount-userPublisher" {
#  provider             = azurerm.ailz
# 
#  scope                = module.az_search["main"].search_service_id
#  role_definition_name = "Search Service Contributor"
#  principal_id         = "<PID>" #data.azurerm_client_config.current.object_id
#  
#  depends_on           = [ module.az_function_proyecto ]
#}

# ###################################################################################################################################
# ####                                    role assigned identity function service to openai
# ###################################################################################################################################

resource "azurerm_role_assignment" "role-assign-openai-function" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app_proy

  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "role-assign-cog-function" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app_proy

  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function_proyecto]
}

#### Solo orchestrator // revisar, se cambio a data reader a data contributor
resource "azurerm_role_assignment" "role-assign-srch-index-datareader-function" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app_proy

  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function_proyecto]
}

### Solo orchestrator
#Cosmos DB Built-in Data Contributor
#resource "azurerm_role_assignment" "role-assign-cosmosdb-function" {
#  provider              = azurerm.ailz
#  for_each              = azurerm_user_assigned_identity.uais_function_app_proy
# 
#  scope                = module.cosmosdb["main"].id
#  role_definition_id = "00000000-0000-0000-0000-000000000002"
#  #Cosmos DB Built-in Data Contributor"
#  principal_id         = each.value.principal_id
#  
#  depends_on = [ module.az_function_proyecto ]
#}


# orc and data ingestion
#Key Vault Secrets User
resource "azurerm_role_assignment" "role-assign-keyvault-function" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app_proy

  scope                = module.keyvault_proyecto.key-vault-id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "role-assign-function-keyvault-central" {
  provider             = azurerm.ailz
  for_each             = azurerm_user_assigned_identity.uais_function_app_proy
  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id
  depends_on           = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "role-assign-appinsigth-function" {
  provider             = azurerm.ailz
  for_each             = azurerm_user_assigned_identity.uais_function_app_proy
  scope                = module.az_function_proyecto["dataingestion"].application-insights-id
  role_definition_name = "Application Insights Component Contributor"
  principal_id         = each.value.principal_id
  depends_on           = [module.az_function_proyecto]
}

#resource "azapi_resource" "cosmos-role-assign-function-data-contributor" {
#  type = "Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15"
#  name = "00000000-0000-0000-0000-000000000001"
#  body = jsonencode({
#    properties = {
#      assignableScopes = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.persistent_resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${module.cosmosdb["main"].account_name}"]
#      roleName = "Cosmos DB Built-in Data Contributor"
#      type = "BuiltInRole"
#    }
#  })
#}


#resource "azapi_resource" "cosmosdb_sql_role_assignment" {
#  type = "Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15"
#
#  name = uuid()  
#  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.persistent_resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${module.cosmosdb["main"].account_name}"
#  body = jsonencode({
#    properties = {
#      roleDefinitionId = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.persistent_resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${module.cosmosdb["main"].account_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"  # Built-in Cosmos DB Data Contributor role definition ID
#      principalId      = module.az_function_proyecto["orchestrator"].system-assigned-identity-id
#      scope            = module.cosmosdb["main"].id  
#    }
#  })
#}


resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb-role-assign-function-data-contributor" {
  provider            = azurerm.ailz

  for_each            = azurerm_user_assigned_identity.uais_function_app_proy
  resource_group_name =  local.persistent_resource_group_name
  account_name        =  module.cosmosdb["main"].account_name
  role_definition_id  = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.persistent_resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${module.cosmosdb["main"].account_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = each.value.principal_id
  scope               = module.cosmosdb["main"].id
}


#resource "azurerm_role_assignment" "role-assigment-user-cosmosdb-function" {
#  provider             = azurerm.ailz
#  for_each             = azurerm_user_assigned_identity.uais_function_app_proy
#  scope                = module.cosmosdb["main"].id
#  role_definition_name = "DocumentDB Account Contributor" #"Cosmos DB Built-in Data Contributor"
#  principal_id         = each.value.principal_id
#  depends_on           = [module.az_function_proyecto]
#}

# ###################################################################################################################################
# ####                        Role assigment to function app System Assigned Identity
# ###################################################################################################################################

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb-role-assign-function-data-contributor-system-assigned" {
  provider            =  azurerm.ailz
  resource_group_name =  local.persistent_resource_group_name
  account_name        =  module.cosmosdb["main"].account_name
  role_definition_id  = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.persistent_resource_group_name}/providers/Microsoft.DocumentDB/databaseAccounts/${module.cosmosdb["main"].account_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = module.az_function_proyecto["orchestrator"].system-assigned-identity-id
  scope               = module.cosmosdb["main"].id
}




#resource "azurerm_role_assignment" "role-assigment-system-cosmosdb-function" {
#  provider             = azurerm.ailz
#  scope                = module.cosmosdb["main"].id
#  role_definition_name = "DocumentDB Account Contributor" #"Cosmos DB Built-in Data Contributor"
#  principal_id         = module.az_function_proyecto["orchestrator"].system-assigned-identity-id
#  depends_on           = [module.az_function_proyecto]
#}

resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
  depends_on           = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto-index" {
  provider             = azurerm.ailz
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
  depends_on           = [module.az_function_proyecto]
}


resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto-cogaccount-services" {
  provider             = azurerm.ailz
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
  depends_on           = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto-cogaccount-services-user" {
  provider             = azurerm.ailz
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
  depends_on           = [module.az_function_proyecto]
}

###################################################################################################################################
####    Cognitive Services OpenAI Contributor - role assigned over the system assigned identity
####    to the function app orchestrator and data ingestion - opeanai are deployed in the infra central
###################################################################################################################################

resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto-cogaccount-openai-services" {
  provider             = azurerm.ailz
  for_each             = module.az_function_proyecto 
  scope                = module.openai["main"].cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = each.value.system-assigned-identity-id
  depends_on           = [module.az_function_proyecto]
}


resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto-keyvault" {
  provider             = azurerm.ailz
  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
  depends_on           = [module.az_function_proyecto]
}

###################################################################################################################################
####    Key vault secrets user - role assigned over the system assigned identity - infra central
####    to the function app orchestrator and data ingestion
###################################################################################################################################

resource "azurerm_role_assignment" "role-assign-system-assigned-function-keyvault-central" {
  provider             = azurerm.ailz
  for_each             = module.az_function_proyecto
  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.system-assigned-identity-id

  depends_on = [module.az_function_proyecto]
}


###################################################################################################################################
####         Access policies - system assigned identity - infra central
####         to the function app orchestrator and data ingestion
###################################################################################################################################

resource "azurerm_key_vault_access_policy" "access_policy_proyecto_keyvault" {
  provider     = azurerm.ailz
  for_each     = module.az_function_proyecto
  key_vault_id = module.keyvaults["main"].key-vault-id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.system-assigned-identity-id

  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]

  depends_on = [module.az_function_proyecto]

}

###################################################################################################################################
####    Key vault secrets user - role assigned over the system assigned identity - infra proy
####    to the function app orchestrator and data ingestion
###################################################################################################################################

resource "azurerm_key_vault_access_policy" "access_policy_central_infrastructure_keyvault" {
  provider     = azurerm.ailz
  for_each     = module.az_function_proyecto
  key_vault_id = module.keyvault_proyecto.key-vault-id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.system-assigned-identity-id

  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]
  depends_on = [module.az_function_proyecto]
}

#storage proyecto
resource "azurerm_role_assignment" "system-assigned-identity-role-proyecto-storage" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = each.value
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id

  depends_on = [module.az_function_proyecto]
}
#storage central
resource "azurerm_role_assignment" "system-assigned-identity-role-central-storage" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id

  depends_on = [module.az_function_proyecto]
}



#   #revisar

#   # pipeline 2 funciones un app service configuraciones del orquestador y crear temas de indices ...

# ###################################################################################################################################
# ####                                    Service plan for function module
# ###################################################################################################################################

resource "azurerm_service_plan" "service-plan-proyecto" {
  provider = azurerm.ailz

  for_each            = local.az_function_config_proyecto
  name                = "sp-${var.basename}-${each.value.main_name}-${var.deployment_environment}-${local.random_seed_hex}"
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  location            = local.location
  os_type             = each.value.app_service_plan.kind
  sku_name            = each.value.app_service_plan.sku_name
  worker_count        = each.value.app_service_plan.worker_count
}

# #var.additional-app-settings

module "az_function_proyecto" {
  providers = {
    azurerm = azurerm.ailz
  }

  for_each = local.az_function_config_proyecto
  #source              = "git::https://SuraColombia@dev.azure.com/SuraColombia/Gerencia_Tecnologia/_git/ti-lego-iac-azurerm-functions-lb?ref=v1.3"
  source              = "./modules/az_function"
  resource-group-name = azurerm_resource_group.rg_proyecto.name
  #  consumption-plan-resource-group-name
  basename                  = "${var.basename}${var.deployment_environment}"
  name                      = each.value.main_name #var.basename
  service-plan-id           = azurerm_service_plan.service-plan-proyecto[each.key].id
  consumption-plan-basename = "func-${each.value.main_name}-hub-proy"
  consumption               = false
  subnet-id                 = azurerm_subnet.functions_subnet.id # preguntar
  storage-account-name      = module.storage_account_proyecto.storage-account-name
  secret-storage-type       = "keyvault"
  keyvault-uri              = module.keyvaults["main"].key-vault-uri #revisar si aplica el keyvault central
  uai-id                    = azurerm_user_assigned_identity.uais_function_app_proy[each.key].id

  #ajustar secreto ???
  additional-app-settings = each.value.orchestrator ? local.var_orchestrator : local.var_data_ingestion

  extra-tags    = var.tags
  uai-client-id = azurerm_user_assigned_identity.uais_function_app_proy[each.key].client_id
  suffix        = local.random_seed_hex
  #   host-id
  #   always-on
  #   vnet-route-all
  enable-insights = true # preguntar
  #   connection-strings
  #   sticky-app-settings
  #   sticky-connection-strings
  #   health-check-path
  https-only = true
  #   client-certificate-mode
  #   enable-client-certificate
  use-32-bit-worker = true
  #   auto-swap-slot-name
  enable-remote-debugging  = false
  remote-debugging-version = "VS2022"
  #   enable-runtime-scale-monitoring
  cors-allowed-origins = ["https://portal.azure.com"]
  #   cors-support-credentials
  #   disable-homepage
  runtime             = "python"
  runtime-environment = "Development"
  #   java-version
  #   node-version
  python-version = "3.10"
  #   dotnet-version
  #   dotnet-isolated
  timezone = "America/Bogota"
  #   run-from-package
  storage-account-id-diag = module.diag_storage_account.storage-account-id # lo dejamos igual ?
  #   public-certificates
  #   load-certificates
  # como permitir inbound and outbound in function
  inbound-subnet-id = azurerm_subnet.pep_subnet.id

  enable-subnet-connection = true

  #is_deployed_code          = each.value.is_deployed_code
  #deployment_code_name      = each.value.deployment_code_name

  depends_on = [azurerm_key_vault_access_policy.regional_access_policies_proyecto, azurerm_role_assignment.storage_account_roles_proyecto]
}


# ###################################################################################################################################
# ####                                    Add role to the function app     "Storage File Data SMB Share Contributor"
# ###################################################################################################################################

resource "azurerm_role_assignment" "role-assign-function-storage-share-contributor" {
  provider             = azurerm.ailz
  for_each             = azurerm_user_assigned_identity.uais_function_app_proy
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = each.value.principal_id
  depends_on           = [module.az_function_proyecto]
}

resource "azurerm_role_assignment" "role-assign-function-storage-share-contributor-central" {
  provider             = azurerm.ailz
  for_each             = azurerm_user_assigned_identity.uais_function_app_proy
  scope                = module.storage_account.storage-account-id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = each.value.principal_id
  depends_on           = [module.az_function_proyecto]
}

#module.az_function_proyecto["dataingestion"].system-assigned-identity-id

#resource "azurerm_role_assignment" "role-assign-function-storage-share-contributor-system-assigned" {
#  provider             = azurerm.ailz
#  scope                = module.storage_account_proyecto.storage-account-id
#  role_definition_name = "Storage File Data SMB Share Contributor"
#  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
#  depends_on = [ module.az_function_proyecto ]
#}
#
#resource "azurerm_role_assignment" "role-assign-function-storage-share-contributor-central-system-assigned" {
#  provider             = azurerm.ailz
#  scope                = module.storage_account.storage-account-id
#  role_definition_name = "Storage File Data SMB Share Contributor"
#  principal_id         = module.az_function_proyecto["dataingestion"].system-assigned-identity-id
#  depends_on = [ module.az_function_proyecto ]
#}
