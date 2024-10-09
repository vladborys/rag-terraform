####################################################################################################
###                 Custom roles and policies for the project-subscription ailz                  ###
####################################################################################################

#resource "azurerm_role_definition" "custom-role-comosdb-data-contributor" {
#  provider = azurerm.ailz
#  name = "CustomCosmosDBRole Cosmos DB Built-in Data Contributor"
#  scope = data.azurerm_subscription.current-subscription.id
#  permissions {
#    actions     = [
#      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
#      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
#      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
#    ]
#    not_actions = []
#  }
#  assignable_scopes = [data.azurerm_subscription.current-subscription.id]
#}


# Documentation role assigment actions
# https://learn.microsoft.com/en-us/azure/cosmos-db/how-to-setup-rbac