locals {
  ####                     configuracion storage
  uai_storage_names_proyecto = {
    "proyecto_storage" : "uai-proyecto-storage-${var.basename}-${var.storage_account_config.main_name}-${var.deployment_environment}"
  }

  storage_account_config_proy = {

    "main_name"                           = "ailzproy"
    "diag_storage"                        = false
    "is_enable_network_rules"             = false
    "replication_type"                    = "LRS"
    "enable_static_website"               = false
    "min_tls_version"                     = "TLS1_0"
    "is_cross_tenant_replication_enabled" = true
    "is_public_network_access_enabled"    = false
  }

  ####                     configuracion function

  az_function_config_proyecto = {
    "orchestrator" : {
      "app_service_plan" = {
        "kind"         = "Linux"
        "sku_name"     = "P0v3"
        "worker_count" = 1
      }
      "orchestrator"         = true
      "main_name"            = "orch"
      "enable_backend"       = true
      "is_deployed_code"     = true
      "deployment_code_name" = "orchestrator"
    },
    "dataingestion" : {
      "app_service_plan" = {
        "kind"         = "Linux"
        "sku_name"     = "P0v3"
        "worker_count" = 1
      }
      "orchestrator"         = false
      "main_name"            = "data-ingestion"
      "is_deployed_code"     = true
      "deployment_code_name" = "data_ingestion"
      "enable_backend"       = true
    }

  }

  uai_function_names_proyecto = {
    for k, v in local.az_function_config_proyecto : k => "uai-function-${var.basename}-${k}-${var.deployment_environment}"
  }

  storage_account_roles_proyecto_map = merge([
    for idk, idv in local.uai_function_names_proyecto : {
      for fsarv in local.functions_storage_account_roles : "${idk}#${fsarv}" => {
        object_id            = azurerm_user_assigned_identity.uais_function_app_proy[idk].principal_id
        role_definition_name = fsarv

      }
    }
  ]...)

  # No hace nada
  policy_access_key_proyecto_map = merge([
    for idk, idv in local.uai_function_names_proyecto : {
      key_vault_id = module.keyvault_proyecto.key-vault-id
      object_id    = azurerm_user_assigned_identity.uais_function_app_proy[idk].principal_id
      tenant_id    = azurerm_user_assigned_identity.uais_function_app_proy[idk].tenant_id
    }
  ]...)

  ## Crear modelo de embeddings desde cliente o api /// gpt 4o
  var_orchestrator = {
    AzureWebJobsStorage                     = "${module.storage_account_proyecto.primary-connection-string}"
    #SCM_DO_BUILD_DURING_DEPLOYMENT          = "1"
    #ENABLE_ORYX_BUILD                       =true
    AZURE_DB_ID                             = module.cosmosdb["main"].account_name          # nombre cosmosdb
    AZURE_DB_NAME                           = "db-cosmos-ailz-main-dll-0001-1"              # nombre db dentro de cosmos
    AZURE_KEY_VAULT_ENDPOINT                = "https://kv-ailzmaindll00.vault.azure.net/"   # endpoint infra central keyvault
    AZURE_DB_CONVERSATIONS_CONTAINER_NAME   = "conversations"                               # nombre contenedor conversations
    AZURE_DB_MODELS_CONTAINER_NAME          = "models"                                      # nombre contenedor models                            
    AZURE_KEY_VAULT_NAME                    = "${module.keyvaults["main"].key-vault-name}"  # nombre keyvault
    AZURE_SEARCH_SERVICE                    = module.az_search["main"].search_service_name  # nombre del servicio de busqueda (search service)"
    AZURE_SEARCH_INDEX                      = "ragindex"                                    # nombre del indice de busqueda (search index)
    AZURE_SEARCH_APPROACH                   = "hybrid"                                      # enfoque de busqueda 
    AZURE_SEARCH_USE_SEMANTIC               = "true"                                        # uso de busqueda semantica                             
    AZURE_SEARCH_API_VERSION                = "2024-03-01-preview"                          # version de la api de busqueda  (search api version)
    AZURE_OPENAI_RESOURCE                   = module.openai["main"].cognitive_account_name  # nombre del recurso de openai
    AZURE_OPENAI_CHATGPT_MODEL              = "model-deployment-gpt-4o"                     # modelo de openai conversacional
    AZURE_OPENAI_CHATGPT_DEPLOYMENT         = "chat"                                        # despliegue de openai conversacional   
    AZURE_OPENAI_CHATGPT_LLM_MONITORING     = "true"                                        # monitoreo de lenguaje natural 
    AZURE_OPENAI_API_VERSION                = "2024-02-15-preview"                          # version de la api de openai
    AZURE_OPENAI_LOAD_BALANCING             = false                                         # balanceo de carga de openai    
    AZURE_OPENAI_EMBEDDING_MODEL            = "model-deployment-text-embedding-ada-002"     # modelo de embeddings de openai  
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT       = "model-deployment-text-embedding-ada-002"     # despliegue de embeddings de openai
    AZURE_OPENAI_STREAM                     = false                                         # stream openai
    ORCHESTRATOR_MESSAGES_LANGUAGE          = "en"                                          # lenguaje de los mensajes del orquestador  
    ENABLE_ORYX_BUILD                       = true                                          # habilitar oryx build                            
    BING_SEARCH_TOP_K                       = 3                                             # top k de busqueda de bing
    BING_RETRIEVAL                          = false                                         # retrival bing                           
    BING_SEARCH_MAX_TOKENS                  = 1000                                          # maximo de tokens de busqueda de bing  
    SQL_RETRIEVAL                           = false                                         # retrival sql                         
    SQL_TOP_K                               = 3                                             # top k de busqueda de sql  
    SQL_MAX_TOKENS                          = 1000                                          # maximo de tokens de busqueda de sql
    TERADATA_TOP_K                          = 3                                             # top k de busqueda de teradata      
    TERADATA_RETRIEVAL                      = false                                         # teradata retrival                                    # retrival teradata                          
    TERADATA_MAX_TOKENS                     = 1000                                          # maximo de tokens de busqueda de teradata  
    RETRIEVAL_PRIORITY                      = "search"                                      # prioridad de busqueda      
    SCM_DO_BUILD_DURING_DEPLOYMENT          = true                                          # construir durante el despliegue    
    LOGLEVEL                                = "INFO"                                        # nivel de log
  }

  var_data_ingestion = {
    AzureWebJobsStorage               = "${module.storage_account_proyecto.primary-connection-string}"
    AZURE_KEY_VAULT_ENDPOINT          = module.keyvaults["main"].key-vault-uri   #"https://kv-ailzmaindll00.vault.azure.net/" 
    DOCINT_API_VERSION                ="2023-07-31"
    AZURE_KEY_VAULT_NAME              ="${module.keyvaults["main"].key-vault-name}"
    FUNCTION_APP_NAME                 = "func-ailzdll-data-ingestion-0001"
    SEARCH_SERVICE                    = module.az_search["main"].search_service_name     #"srch-ailz-0001"
    SEARCH_INDEX_NAME                 ="ragindex"
    SEARCH_ANALYZER_NAME              ="standard" #? verificar
    SEARCH_API_VERSION                ="2023-10-01-Preview"
    AZURE_SEARCH_TRIMMING             = false
    SEARCH_INDEX_INTERVAL             ="PT1H" #? verificar
    STORAGE_ACCOUNT_NAME              ="${module.storage_account_proyecto.storage-account-name}"
    STORAGE_CONTAINER                 ="documents"
    AZURE_FORMREC_SERVICE             = "${module.cognitive_services.cognitive_account_name}"
    AZURE_OPENAI_API_VERSION          ="2024-02-15-preview" #? verificar
    AZURE_SEARCH_APPROACH             ="hybrid"
    AZURE_OPENAI_SERVICE_NAME         = module.openai["main"].cognitive_account_name #"oai-ailz-0001"
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT ="model-deployment-text-embedding-ada-002"
    NUM_TOKENS                        ="2048"
    MIN_CHUNK_SIZE                    ="100"
    TOKEN_OVERLAP                     ="200"
    NETWORK_ISOLATION                 = true
    ENABLE_ORYX_BUILD                 = true
    SCM_DO_BUILD_DURING_DEPLOYMENT    = "1"
    AzureWebJobsFeatureFlags          ="EnableWorkerIndexing"
    LOGLEVEL                          ="INFO"
    BUILD_FLAGS                       ="UseExpressBuild"
    AZURE_FUNCTIONS_ENVIRONMENT       ="Production"

  }


}
