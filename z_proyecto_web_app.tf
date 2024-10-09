locals {
  az_web_app_config_proyecto = {
    "proyecto1" : {
      "app_service_plan" = {
        "os_type"      = "Linux"
        "sku_name"     = "P0v3"
        "worker_count" = 1
      }
      "main_name"      = "sh1"
      "enable_backend" = true
    },
  }

  uai_web_app_names_proyecto = {
    for k, v in local.az_web_app_config_proyecto : k => "uai-webapps-${var.basename}-${k}-${var.deployment_environment}"
  }

  #kv_access_policies_web_app_proyecto_map = merge([
  #  for idk, idv in local.uai_web_app_names_proyecto : {
  #      key_vault_id = module.keyvault_proyecto.key-vault-id
  #      object_id    = azurerm_user_assigned_identity.uais_web_app_proyecto[idk].principal_id
  #      tenant_id    = azurerm_user_assigned_identity.uais_web_app_proyecto[idk].tenant_id
  #  }
  #]...)

}

resource "azurerm_user_assigned_identity" "uais_web_app_proyecto" {
  provider = azurerm.ailz
  for_each = local.uai_web_app_names_proyecto

  name                = local.uai_web_app_names_proyecto[each.key]
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  location            = local.location
  tags                = var.tags
}

# ###############################################################################################
# ####                
# ###############################################################################################

# ###############################################################################################
# ####                Storage Account role assigned to webapp user assigned identity
# ###############################################################################################
resource "azurerm_role_assignment" "role-storage-webapp-proyecto" {
  provider             = azurerm.ailz
  for_each             = azurerm_user_assigned_identity.uais_web_app_proyecto
  
  scope                = module.storage_account_proyecto.storage-account-id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value.principal_id
}


resource "azurerm_role_assignment" "role-assign-search-webapp-cogaccount" {
  provider     = azurerm.ailz
  for_each     = azurerm_user_assigned_identity.uais_web_app_proyecto
 
  scope                = module.az_search["main"].search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = each.value.principal_id
  
  depends_on = [ module.web_app_proyecto]
}

resource "azurerm_role_assignment" "role-assign-appinsigth-webapp" {
  provider              = azurerm.ailz
  for_each              = azurerm_user_assigned_identity.uais_web_app_proyecto
 
  scope                = module.az_function_proyecto["dataingestion"].application-insights-id
  role_definition_name = "Application Insights Component Contributor"
  principal_id         = each.value.principal_id
  
  depends_on = [ module.web_app_proyecto ]
}

#Key Vault Secrets User
resource "azurerm_role_assignment" "role-assign-keyvault-webapp" {
  provider              = azurerm.ailz
  for_each              = azurerm_user_assigned_identity.uais_web_app_proyecto
 
  scope                = module.keyvault_proyecto.key-vault-id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id
  
  depends_on = [ module.web_app_proyecto ]
}

resource "azurerm_role_assignment" "role-assign-cog-webapp" {
  provider              = azurerm.ailz
  for_each              = azurerm_user_assigned_identity.uais_web_app_proyecto
 
  scope                = module.cognitive_services.cognitive_account_id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = each.value.principal_id
  
  depends_on = [ module.web_app_proyecto ]
}

resource "azurerm_key_vault_access_policy" "kv_access_policies_web_app_proyecto" {
  provider = azurerm.ailz
  for_each = local.uai_web_app_names_proyecto #local.kv_access_policies_web_app_proyecto_map

  key_vault_id = module.keyvault_proyecto.key-vault-id                                       #each.value.key_vault_id
  tenant_id    = azurerm_user_assigned_identity.uais_web_app_proyecto[each.key].tenant_id    #each.value.tenant_id
  object_id    = azurerm_user_assigned_identity.uais_web_app_proyecto[each.key].principal_id #each.value.object_id
  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]
}

resource "azurerm_service_plan" "web_app_service_plan_proyecto" {
  provider = azurerm.ailz
  for_each = local.az_web_app_config_proyecto

  name                = "sp-webapps-${var.basename}-${each.value.main_name}-${var.deployment_environment}-${local.random_seed_hex}"
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  location            = local.location
  os_type             = each.value.app_service_plan.os_type
  sku_name            = each.value.app_service_plan.sku_name
  worker_count        = each.value.app_service_plan.worker_count
}

module "web_app_proyecto" {
  providers = {
    azurerm = azurerm.ailz
  }

  for_each = local.az_web_app_config_proyecto

  #source = "git::https://<Name>@dev.azure.com/<Name>/Tecnologia/_git/ti-lego-iac-azurerm-webapp-lb?ref=v3.1"
  source = "./modules/az_app_service"
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  basename            = "${var.basename}-${each.value.main_name}-${var.deployment_environment}"
  suffix              = local.random_seed_hex
  service_plan_id     = azurerm_service_plan.web_app_service_plan_proyecto[each.key].id
  #storage_account_diag_id        = local.diag_storage_account_id
  #storage_account_diag_sas_token = "@Microsoft.KeyVault(SecretUri=${local.webapps_diagnostic_sas_token_kv_secret_versionless_id})"
  uai_id        = azurerm_user_assigned_identity.uais_web_app_proyecto[each.key].id
  uai_client_id = azurerm_user_assigned_identity.uais_web_app_proyecto[each.key].client_id
  #inbound_snet_id                = azurerm_subnet.pep_subnet.id
  outbound_snet_id = azurerm_subnet.proy_app_subnet.id
  #registry_host    = "https://index.docker.io" # Cambiar por "https://${local.acr_login_server}" si usas el ACR para guardar las imagenes docker de tu app
  #image_name       = "oscarrrenalias/golang-http-server"
  startup_cmd      = null

  enable_service_plan = true
  #public_certificates            = local.public_certificates
  extra_tags = var.tags
  app_settings = {
    WEBSITES_PORT                 = "8080"
    SPEECH_SYNTHESIS_VOICE_NAME   = "en-US-RyanMultilingualNeural"
    SPEECH_SYNTHESIS_LANGUAGE     = "en-US"
    SPEECH_RECOGNITION_LANGUAGE   = "en-US"
    SPEECH_REGION                 = "eastus2"
    ORCHESTRATOR_URI              = "https://func-ailzdll-orch-0001.azurewebsites.net"
    ORCHESTRATOR_ENDPOINT         = "https://func-ailzdll-orch-0001.azurewebsites.net/api/orc"
    AZURE_KEY_VAULT_ENDPOINT      = module.keyvault_proyecto.key-vault-uri
    AZURE_KEY_VAULT_NAME          = module.keyvault_proyecto.key-vault-name
    STORAGE_ACCOUNT               = module.storage_account_proyecto.storage-account-name
    LOGLEVEL                      ="INFO"
  }
}

resource "azurerm_private_endpoint" "pep_web_app_proyecto" {
  provider            = azurerm.ailz
  for_each            = local.az_web_app_config_proyecto

  name                = "pe-webapp-${var.basename}-${each.value.main_name}-${var.deployment_environment}-${local.random_seed_hex}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg_proyecto.name
  subnet_id           = azurerm_subnet.pep_subnet.id
  tags                = var.tags

  private_dns_zone_group {
    name                 = "pdzg-app-${var.basename}-${each.value.main_name}-${var.deployment_environment}-${local.random_seed_hex}"
    private_dns_zone_ids = ["/subscriptions/<ID>/resourceGroups/<RG>/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"]
  }

  private_service_connection {
    name                           = "psc-webapp-${var.basename}-${each.value.main_name}-${var.deployment_environment}-${local.random_seed_hex}"
    private_connection_resource_id = module.web_app_proyecto[each.key].id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}
