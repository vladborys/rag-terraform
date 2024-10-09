resource "azurerm_user_assigned_identity" "uais_content_safety" {
  provider = azurerm.ailz
  for_each            = local.uai_content_safety_names
  name                = local.uai_content_safety_names[each.key]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = var.tags
}

module "content_safety" {
    providers = {
      azurerm  = azurerm.ailz
    }

    for_each                      = var.content_safety_config
    source                        = "./modules/az_cognitive_account"
    basename                      = "${each.value.main_name}"
    suffix                        = substr(local.random_seed_hex, 0, 4)
    location                      = local.location
    resource_group_name           = local.persistent_resource_group_name
    sku_name                      = each.value.sku
    kind                          = each.value.kind
    public_network_access_enabled = each.value.is_public_network_access_enabled
    identity_uai_ids              = [azurerm_user_assigned_identity.uais_content_safety[each.key].id]
    inbound_subnet_id             = azurerm_subnet.pep_subnet.id
    enable_storage_account_diag   = true
    storage_account_id_diag       = module.diag_storage_account.storage-account-id
}