####################################################################################################
####                              general variables settings                                    ####
####################################################################################################
variable "basename" {
  type = string
}

variable "deployment_environment" {
  type = string
}

variable "remote_state_subscription_id" {
  type = string
}

variable "ailz_subscription_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "tenant_id" {
  type = string
}

####################################################################################################
####                              network variables settings                                    ####
####################################################################################################

variable "private_dns_zones_subscription_id" {
  type = string
}

variable "main_virtual_network_name" {
  type = string
}

variable "dns_zone_properties" {
  description = "value"
  type = object({
    resource_group_name       = string
    provider                  = string
    private_dns_name_blob     = string
    private_dns_name_keyvault = string
    private_dns_name_openai   = string
    private_dns_name_search   = string
  })
}

variable "route_table_configuration" {
  type = object({
    resource_group_name = string
    provider            = string
    route_table_name    = string
  })
}

####################################################################################################
####                              storage account variables settings                            ####
####################################################################################################

variable "blob_properties" {
  type = object({
    private_dns_name = string
  })
}


variable "storage_account_config" {
  type = object({
    main_name                           = string
    diag_storage                        = bool
    is_enable_network_rules             = bool
    replication_type                    = string
    enable_static_website               = bool
    min_tls_version                     = string
    is_cross_tenant_replication_enabled = bool
    is_public_network_access_enabled    = bool
  })
}

variable "diag_storage_config" {
  type = object({
    main_name                           = string
    diag_storage                        = bool
    is_enable_network_rules             = bool
    replication_type                    = string
    enable_static_website               = bool
    min_tls_version                     = string
    is_cross_tenant_replication_enabled = bool
    is_public_network_access_enabled    = bool
  })
}

####################################################################################################
####                              keyvault variables settings                                   ####
####################################################################################################

variable "keyvault_properties" {
  type = object({
    private_dns_name = string
  })
}

variable "keyvaults" {
  type = object({
    main = string
  })
  description = "keyvaults"
  default = {
    main = "main"
  }
}

####################################################################################################
####                              cosmosdb variables settings                                   ####
####################################################################################################

variable "cosmosdbs_names" {
  type = object({
    main = string
  })
}

#variable "databases_cosmosdb" {
#  type = map(list(object({
#    suffix_cosmondb_name = string
#    is_new_database      = bool
#    database_name        = string
#  })))
#}

####################################################################################################
####                              redisdb variables settings                                    ####
####################################################################################################

variable "redisdb_config" {
  type = map(object({
    main_name = string
    family    = string
    sku       = string
    capacity  = string
  }))
}

####################################################################################################
####                         cognitive services variables settings                              ####
####################################################################################################

variable "openai_config" {
  type = map(object({
    main_name                        = string
    kind                             = string
    sku                              = string
    is_public_network_access_enabled = string
    models_definition = map(object({
      model_name        = string
      deployment_type   = string
      model_version     = string
      model_description = string
      model_capacity    = string
    }))
  }))
}

variable "content_safety_config" {
  type = map(object({
    main_name                        = string
    kind                             = string
    sku                              = string
    is_public_network_access_enabled = string
  }))
}

####################################################################################################
####                              search variables settings                                     ####
####################################################################################################
variable "az_search_config" {
  type = map(object({
    main_name                        = string
    sku                              = string
    is_public_network_access_enabled = string
    semantic_search_sku              = string
    enforcement                      = string
    replica_count                    = number
    partition_count                  = number
    hosting_mode                     = string
    aad_auth_failure_mode            = string
    disable_local_auth               = bool
  }))
}

####################################################################################################
####                              apim variables settings                                     ####
####################################################################################################

variable "apim_config" {
  type = map(object({
    sku                     = string
    capacity                = string
    enable_backend          = bool
    enable_developer_portal = string
  }))
}

####################################################################################################
####                              az function variables settings                                ####
####################################################################################################

variable "az_function_config" {
  description = "Configuracion para az function"

  type = map(object({
    app_service_plan = object({
      kind         = string
      sku_name     = string
      worker_count = number
    })

    main_name            = string
    is_deployed_code     = bool
    deployment_code_name = string
  }))
}



