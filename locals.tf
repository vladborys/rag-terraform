
# name values apim https://kv-ailzmaindll00.vault.azure.net/secrets/apimSubscriptionKey


locals {
  random_seed_hex = "0001"

  ############################################## APIM configurations ##############################################
  apim_files_apis_def = fileset("${path.module}/apis_definitions", "*.yaml")
  folder_name         = "apis_definitions"

  backend_definition_apim = {
    "openai" : {
      name        = "gpt-4o"
      url         = "https://oai-ailz-0001.openai.azure.com/openai/v1"
      protocol    = "http"
      api_def_url = "gpt-4o.openapi.yaml"
      proyecto    = "copiloto"
    }
    #,
    #"func_sec_hub":{
    #  name="security_hub"
    #  url = "https://func-shdll--0001.azurewebsites.net"
    #  protocol = "https"
    #  api_def_url = "securityHub.openapi.yaml"
    #  proyecto = "copiloto"
    # }
  }

  #api_def_apim_map =  {
  #  for apimk,apimv in var.apim_config: "${apimk}" => merge([
  #    for bk,bv in local.backend_definition_apim :{
  #      for filev in local.apim_files_apis_def : "${bk}#${basename(filev)}" => {
  #      
  #        backend_url = module.apim[apimk].backend_url[bk] 
  #        backend_protocol = module.apim[apimk].backend_protocol[bk] #string
  #        apim_id = module.apim[apimk].apim_id
  #        file_api_url = "${path.module}/${local.folder_name}/${filev}"
  #      }
  #    }
  #  ])
  #}

  ############################################## Keyvault configurations ##############################################
  keyvault_properties = {
    private_dns_id = join("/", compact(["/subscriptions/${var.private_dns_zones_subscription_id}", var.dns_zone_properties.resource_group_name, var.dns_zone_properties.provider, var.keyvault_properties.private_dns_name]))
  }

  key_vault_secrets = {
     #"apimSubscriptionKey" = merge([
     #   for k, v in var.apim_config : {
     #     for apimv in module.apim : "apimSubscriptionKey-${k}" => {
     #       component = "apim"
     #       ref_key = k
     #       primary_key = apimv.subscription_primary_key
     #       }
     #   } #k => "apimSubscriptionKey-${k}"
     # ]...)
      
      "contentSafetyKey" = merge([
        for k, v in var.content_safety_config : {
          for csv in module.content_safety : "contentSafetyKey-${k}" => {
            component = "contentSafety"
            ref_key = k
            primary_key = csv.cognitive_account_primary_access_key
            }
        } #k => "contentSafetyKey-${k}"
      ]...)
    
   }


  flatten_key_vault_secrets = merge([
    for k, v in local.key_vault_secrets : {
      for sk, sv in v : "${k}#${sk}" => {
        secret_name = sk
        key_vault_id = module.keyvaults["main"].key-vault-id #varaible quemda arreglar para que sea dinamico
        key_vault_secret_value = sv.primary_key
        description = "Secret for ${sv.component} component"
      }
    }
  ]...)

  

  ############################################## Function configurations ##############################################

  uai_function_names = {
    for k, v in var.az_function_config : k => "uai-function-${var.basename}-${k}-${var.deployment_environment}"
  }

  uai_cosmos_names = {
    for k, v in var.cosmosdbs_names : k => "uai-cosmos-${var.basename}-${k}-${var.deployment_environment}"
  }

  uai_search_names = {
    #"main" = "uai-srch-main-${var.basename}-${var.deployment_environment}"
    for k, v in var.az_search_config : k => "uai-srch-${var.basename}-${k}-${var.deployment_environment}"
  }

  uai_openai_names = {
    for k, v in var.openai_config : k => "uai-openai-${var.basename}-${k}-${var.deployment_environment}"
  }

  uai_content_safety_names = {
    for k, v in var.content_safety_config : k => "uai-contentsafety-${var.basename}-${k}-${var.deployment_environment}"
  }

  uai_apim_names = {
    for k, v in var.apim_config : k => "uai-apim-${var.basename}-${k}-${var.deployment_environment}"
  }

  apim_public_ip_names = {
    for k, v in var.apim_config : k => "pip-apim-${var.basename}-${k}-${var.deployment_environment}"
  }

  uai_storage_names = {
    "main_diag_storage" : "uai-diag-storage-${var.basename}-${var.diag_storage_config.main_name}-${var.deployment_environment}"
    "main_storage" : "uai-main-storage-${var.basename}-${var.storage_account_config.main_name}-${var.deployment_environment}"

    #for k, v in var.storage_account_config : k => "uai-storage-${var.basename}-${k}-${var.deployment_environment}"
  }


  persistent_resource_group_name = "rg-ailz-persistence-dll-eastus-001"
  location                       = "East US"

  main_virtual_network_subnets_cidr = {
    "apim"             = "10.56.128.0/28",  # 14 ips
    "privateendpoints" = "10.56.128.32/27", # 30 ips
    "functions"        = "10.56.128.64/27"  # 30 ips
    "app_service"      = "10.56.128.96/27"  #
  }

  networking_properties = {
    route_table_association = join("/", compact(["/subscriptions/${var.ailz_subscription_id}", var.route_table_configuration.resource_group_name, var.route_table_configuration.provider, var.route_table_configuration.route_table_name]))
  }



  blob_properties = {
    storage_keys = keys(var.az_search_config)

    basename = {

    }

    private_dns_id = join("/", compact(["/subscriptions/${var.private_dns_zones_subscription_id}", var.dns_zone_properties.resource_group_name, var.dns_zone_properties.provider, var.blob_properties.private_dns_name]))
  }

  openai_properties = {
    private_dns_id = join("/", compact(["/subscriptions/${var.private_dns_zones_subscription_id}", var.dns_zone_properties.resource_group_name, var.dns_zone_properties.provider, var.dns_zone_properties.private_dns_name_openai]))
  }

  search_properties = {
    #srch_keys      = keys(var.az_search_config)
    srch_keys      = { for key in keys(var.az_search_config) : key => key }
    private_dns_id = join("/", compact(["/subscriptions/${var.private_dns_zones_subscription_id}", var.dns_zone_properties.resource_group_name, var.dns_zone_properties.provider, var.dns_zone_properties.private_dns_name_search]))
  }
  responsible_analyst_upn = "aa@bb.com.co"

  tags = var.tags


  functions_storage_account_roles = [
    "Storage Blob Data Owner",
    "Storage Blob Data Reader",
    "Storage Account Contributor",
    "Storage Queue Data Contributor",
    "Storage Blob Data Contributor",
    "Storage Table Data Contributor",
    "Storage Account Key Operator Service Role",
    "Reader and Data Access",
  ]

  storage_account_roles_map = merge([
    for idk, idv in local.uai_function_names : {
      for fsarv in local.functions_storage_account_roles : "${idk}#${fsarv}" => {
        object_id            = azurerm_user_assigned_identity.uais_function_app[idk].principal_id
        role_definition_name = fsarv

      }
    }
  ]...)


  policy_access_key_map = merge([
    for idk, idv in local.uai_function_names : {
      for kvk, kvv in var.keyvaults : "${idk}#${idv}" => {
        key_vault_id = module.keyvaults[kvk].key-vault-id
        object_id    = azurerm_user_assigned_identity.uais_function_app[idk].principal_id
        tenant_id    = azurerm_user_assigned_identity.uais_function_app[idk].tenant_id
      }
    }
  ]...)


  #cognitive_account_id

  #policy_role_assigned_cognitive_account = merge([
  #    for k, v in azurerm_user_assigned_identity.apims_uais : {
  #      for oaik, oaiv in module.openai :"${k}#${oaik}" => {
  #        principal_id_uai = azurerm_user_assigned_identity.uais_function_app[k].principal_id
  #        cognitive_account_id = module.openai[oaik].cognitive_account_id
  #        }
  #      }
  #]...)  


  #####  cosmosdb

  filtered_database_cosmosdb = {
    "main" =  {

    }
  }


}
