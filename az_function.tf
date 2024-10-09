# https://github.com/hashicorp/terraform-provider-azurerm/issues/24730
# definir el uai-id

###################################################################################################################################
####                                              Creation assigned identity
###################################################################################################################################

resource "azurerm_user_assigned_identity" "uais_function_app" {
  provider = azurerm.ailz

  for_each            = local.uai_function_names
  name                = local.uai_function_names[each.key]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}

###################################################################################################################################
####                           role assigned identity to storage and access policy to storage
###################################################################################################################################


resource "azurerm_role_assignment" "storage_account_roles" {
  provider = azurerm.ailz

  for_each = local.storage_account_roles_map

  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.object_id
}


##############################################################################################
####                                Access policy to keyvault
##############################################################################################

resource "azurerm_key_vault_access_policy" "regional_access_policies" {
  provider = azurerm.ailz

  for_each     = local.policy_access_key_map
  key_vault_id = each.value.key_vault_id
  tenant_id    = each.value.tenant_id
  object_id    = each.value.object_id

  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]

}

#system-assigned-identity-id
resource "azurerm_key_vault_access_policy" "system-assigned-identity-access-policy" {
  provider = azurerm.ailz

  key_vault_id = module.keyvaults["main"].key-vault-id
  tenant_id    = data.azurerm_client_config.current-user.tenant_id
  object_id    = module.az_function["main"].system-assigned-identity-id

  secret_permissions = [
    "Delete",
    "Get",
    "List",
    "Set",
  ]

}

###################################################################################################################################
####                              role assigned identity to keyvault user assigned
###################################################################################################################################

resource "azurerm_role_assignment" "role-assign-function-keyvault" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app

  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function]
}

resource "azurerm_role_assignment" "role-assign-user-assigned-shub-keyvault" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app

  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function]
}


resource "azurerm_role_assignment" "role-assign-system-assigned-shub-keyvault" {
  provider = azurerm.ailz

  scope                = module.keyvaults["main"].key-vault-id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.az_function["main"].system-assigned-identity-id

  depends_on = [module.az_function]
}


resource "azurerm_role_assignment" "role-assign-function-congnitive" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app

  scope                = module.content_safety["main"].cognitive_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function]
}

resource "azurerm_role_assignment" "role-assign-function-reader" {
  provider = azurerm.ailz
  for_each = azurerm_user_assigned_identity.uais_function_app

  scope                = module.content_safety["main"].cognitive_account_id
  role_definition_name = "Reader"
  principal_id         = each.value.principal_id

  depends_on = [module.az_function]
}

###################################################################################################################################
####                              role assigned identity to keyvault system assigned
###################################################################################################################################

resource "azurerm_role_assignment" "role-assign-function-congnitive-system-assigned" {
  provider = azurerm.ailz

  scope                = module.content_safety["main"].cognitive_account_id
  role_definition_name = "Cognitive Services User"
  principal_id         = module.az_function["main"].system-assigned-identity-id

}

resource "azurerm_role_assignment" "role-assign-function-reader-system-assigned" {
  provider = azurerm.ailz
  scope                = module.content_safety["main"].cognitive_account_id
  role_definition_name = "Reader"
  principal_id         = module.az_function["main"].system-assigned-identity-id

}

resource "azurerm_role_assignment" "storage-account-roles-system-assigned-shub" {
  provider             = azurerm.ailz
  for_each             = toset(local.functions_storage_account_roles)
  scope                = module.storage_account.storage-account-id
  role_definition_name = each.value
  principal_id         = module.az_function["main"].system-assigned-identity-id
}

###################################################################################################################################
####                            TO DO : role assigned identity to keyvault manual and access policy to keyvault
###################################################################################################################################
# funcion vscode
#resource "azurerm_role_assignment" "role-assign-function-keyvault-manual" {
#  provider = azurerm.ailz
#
#  scope                = module.keyvaults["main"].key-vault-id
#  role_definition_name = "Key Vault Certificate User"
#  principal_id         = "a840da17-11cd-4bb9-bcf8-d59ef1e94ea4"
#
#}
#revisar

# pipeline 2 funciones un app service configuraciones del orquestador y crear temas de indices ...

###################################################################################################################################
####                                    Networking definition for function module
###################################################################################################################################

###################                                Basic configuration for one subnet                           ###################

resource "azurerm_subnet" "functions_subnet" {
  provider = azurerm.ailz

  name                 = "snet-plan-functions-${var.basename}-${var.deployment_environment}"
  resource_group_name  = local.persistent_resource_group_name
  virtual_network_name = var.main_virtual_network_name
  address_prefixes     = [local.main_virtual_network_subnets_cidr.functions]
  service_endpoints = [
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.KeyVault",
  ]

  delegation {
    name = "sf"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azurerm_subnet_route_table_association" "functions_route_table_association" {
  provider       = azurerm.ailz
  subnet_id      = azurerm_subnet.functions_subnet.id
  route_table_id = local.networking_properties.route_table_association
}


resource "azurerm_network_security_group" "function_nsg" {
  provider = azurerm.ailz

  name                = "nsg-function-${var.basename}-${var.deployment_environment}"
  location            = local.location
  resource_group_name = local.persistent_resource_group_name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "name" {
  provider = azurerm.ailz

  network_security_group_id = azurerm_network_security_group.function_nsg.id
  subnet_id                 = azurerm_subnet.functions_subnet.id

}

###################################################################################################################################
####                                    Service plan for function module
###################################################################################################################################

resource "azurerm_service_plan" "service-plan" {
  provider = azurerm.ailz

  for_each = var.az_function_config

  name                = "sp-${var.basename}-${each.value.main_name}-${var.deployment_environment}-${local.random_seed_hex}"
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  os_type             = each.value.app_service_plan.kind
  sku_name            = each.value.app_service_plan.sku_name
  worker_count        = each.value.app_service_plan.worker_count

}


###################################################################################################################################
####                                    Function module
###################################################################################################################################

module "az_function" {
  providers = {
    azurerm = azurerm.ailz
  }

  for_each = var.az_function_config

  source                    = "./modules/az_function"
  resource-group-name       = local.persistent_resource_group_name
  basename                  = "${var.basename}${var.deployment_environment}"
  name                      = each.value.main_name
  service-plan-id           = azurerm_service_plan.service-plan[each.key].id
  consumption-plan-basename = "func-security-hub"
  consumption               = false
  subnet-id                 = azurerm_subnet.functions_subnet.id
  storage-account-name      = module.storage_account.storage-account-name
  secret-storage-type       = "keyvault"
  keyvault-uri              = module.keyvaults[each.key].key-vault-uri
  uai-id                    = azurerm_user_assigned_identity.uais_function_app[each.key].id

  additional-app-settings = {
    CONTENT_SAFETY_ENDPOINT        = "${module.content_safety["main"].cognitive_account_endpoint}"
    AzureWebJobsStorage            = "${module.storage_account.primary-connection-string}"
    AZURE_KEY_VAULT_NAME           = "${module.keyvaults["main"].key-vault-name}"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "1"
    ENABLE_ORYX_BUILD              = true
  }

  extra-tags               = var.tags
  uai-client-id            = azurerm_user_assigned_identity.uais_function_app[each.key].client_id
  suffix                   = local.random_seed_hex
  enable-insights          = true
  https-only               = true
  use-32-bit-worker        = true
  enable-remote-debugging  = false
  remote-debugging-version = "VS2022"
  cors-allowed-origins     = ["https://portal.azure.com", "https://apim-ailz-00.developer.azure-api.net"]
  runtime                  = "python"
  runtime-environment      = "Development"
  python-version           = "3.10"
  timezone                 = "America/Bogota"
  storage-account-id-diag  = module.diag_storage_account.storage-account-id
  inbound-subnet-id        = azurerm_subnet.pep_subnet.id
  enable-subnet-connection = true
  depends_on               = [azurerm_key_vault_access_policy.regional_access_policies, azurerm_role_assignment.storage_account_roles]
}



###################################################################################################################################
####                                    upload file to function
###################################################################################################################################
#resource "azurerm_storage_container" "deploy_container_code" {
#  provider = azurerm.ailz
#  name                  = "code-deploy-${var.basename}-${var.deployment_environment}"
#  storage_account_name  = module.storage-account.storage-account-name
#  container_access_type = "private"
#}


# resource "azurerm_storage_blob" "function_zip" {
#   provider = azurerm.ailz

#   name                   = "function.zip"
#   storage_account_name   = module.storage_account.storage-account-name
#   storage_container_name = azurerm_storage_container.deploy_container_code.name
#   type                   = "block"
#   source                 = data.archive_file.function_zip.output_path
# }

###################################################################################################################################
####                                    upload file to function
###################################################################################################################################

#resource "null_resource" "deploy_function" {
#  provider = azurerm.ailz
#
#  provisioner "local-exec" {
#    command = "az functionapp deployment source config-zip --resource-group ${local.persistent_resource_group_name} --name ${module.az_function.function-name} --src ${data.archive_file.function_zip.output_path}"
#  }
#}
