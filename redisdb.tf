
#resource "azurerm_user_assigned_identity" "userassing" {
#  location            = local.location
#  name                = "userassing${var.basename}"
#  resource_group_name = local.persistent_resource_group_name
#}
#
#module "redisdb_cache" {
#
#  providers = {
#    azurerm = azurerm.ailz
#  }
#
#  for_each                      = var.redisdb_config
#  source                        = "git::https://dev.azure.com/<Name>/Tecnologia/_git/ti-lego-iac-azurerm-redis-lb?ref=v2.0"
#  basename                      = "${var.basename}${each.value.main_name}${var.deployment_environment}"
#  suffix                        = substr(local.random_seed_hex, 0, 2)
#  location                      = local.location
#  resource-group-name           = local.persistent_resource_group_name
#  
#  public-network-access-enabled = false
#  subnet-id                     = azurerm_subnet.pep_subnet.id
#  sku-name                      = each.value.sku
#  family                        = each.value.family
#  capacity                      = each.value.capacity
#  uai-id                        = azurerm_user_assigned_identity.userassing.id
#  extra-tags                    = var.tags
#
#}
#

