data "azurerm_client_config" "current-user" {}
data "azurerm_subscription" "current-subscription" {}

#data "azurerm_cosmosdb_sql_role_definition" "data-contributor-role-cosmos" {
#  resource_group_name = local.persistent_resource_group_name
#  account_name        = module.cosmosdb["main"].account_name
#  name = "Contributor"
#  #role_definition_id  = "00000000-0000-0000-0000-000000000001"
#}