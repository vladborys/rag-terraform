
resource "azurerm_user_assigned_identity" "uais_cosmos" {
  provider = azurerm.ailz

  for_each = var.cosmosdbs_names

  name                = local.uai_cosmos_names[each.key]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}

module "cosmosdb" {
  providers = {
    azurerm = azurerm.ailz
  }
  for_each = var.cosmosdbs_names
  source              = "./modules/az_cosmos"
  resource_group_name = local.persistent_resource_group_name
  basename            = "${var.basename}-${each.value}-${var.deployment_environment}"
  suffix              = substr(local.random_seed_hex, 0, 4)
  kind_database      = "GlobalDocumentDB"
  consistency_policy = "Eventual"
  uai_id             = azurerm_user_assigned_identity.uais_cosmos[each.key].id
  snet_id            = azurerm_subnet.pep_subnet.id
  extra_tags         = var.tags
}

#Revisar modulo de cosmos
resource "azurerm_cosmosdb_sql_database" "db-cosmos" {
  provider = azurerm.ailz
  for_each = module.cosmosdb

  name                = "db-${each.value.account_name}-1"
  resource_group_name = local.persistent_resource_group_name
  account_name        = each.value.account_name 
  throughput          = null
  depends_on          = [module.cosmosdb]

}

#####################################################################################################
###                          Create container cosmosdb
#####################################################################################################
resource "azurerm_cosmosdb_sql_container" "cosmosdb_container_conversation" {
  provider = azurerm.ailz
  for_each = module.cosmosdb

  name                = "conversations"
  resource_group_name = local.persistent_resource_group_name
  account_name        = each.value.account_name 
  database_name       = azurerm_cosmosdb_sql_database.db-cosmos[each.key].name
  partition_key_paths  = ["/id"]
  throughput          = null
  depends_on          = [module.cosmosdb]
}

resource "azurerm_cosmosdb_sql_container" "cosmosdb_container_models" {
  provider = azurerm.ailz
  for_each = module.cosmosdb

  name                = "models"
  resource_group_name = local.persistent_resource_group_name
  account_name        = each.value.account_name 
  database_name       = azurerm_cosmosdb_sql_database.db-cosmos[each.key].name
  partition_key_paths  = ["/id"]
  throughput          = null
  depends_on          = [module.cosmosdb]
}
#resource "azurerm_cosmosdb_mongo_database" "az_cosmosdb_mongo" {
#  for_each            = local.filtered_database_cosmosdb
#  name                = "ailzdb-${each.value.database_name}-1"
#  resource_group_name = var.resource_group_name
#  account_name        = "cosmos-ailz-${each.value.cosmon_name}-${var.deployment_environment}-${each.value.suffix_cosmondb_name}"
#  depends_on          = [module.cosmos]
#}
