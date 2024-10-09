module "keyvaults" {
  providers = {
    azurerm = azurerm.ailz
  }
  for_each = var.keyvaults
  source = "./modules/az_keyvault"
  location                  = local.location
  resource-group-name       = local.persistent_resource_group_name
  basename                  = "${var.basename}${each.value}${var.deployment_environment}"
  suffix                    = substr(local.random_seed_hex, 0, 2)
  enable-rbac-authorization = false
  is_enable_contributor_uai = true
  uai-principal-contributor-id = azurerm_user_assigned_identity.apims_uais[each.key].principal_id
  extra-tags                = var.tags
  depends_on = [ azurerm_user_assigned_identity.apims_uais ]
}

resource "azurerm_private_endpoint" "keyvaults-pep" {
  provider = azurerm.ailz

  for_each = var.keyvaults

  name                = "pep-${module.keyvaults[each.key].key-vault-name}"
  location            = local.location
  resource_group_name = local.persistent_resource_group_name
  subnet_id           = azurerm_subnet.pep_subnet.id
  private_service_connection {
    name                           = module.keyvaults[each.key].key-vault-name
    private_connection_resource_id = module.keyvaults[each.key].key-vault-id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${module.keyvaults[each.key].key-vault-name}"
    private_dns_zone_ids = [local.keyvault_properties.private_dns_id]
  }
}

resource "azurerm_key_vault_secret" "azure-secret-permissions" {
  provider = azurerm.ailz

  for_each = local.flatten_key_vault_secrets

  name         = each.value.secret_name
  key_vault_id = each.value.key_vault_id
  value        = each.value.key_vault_secret_value
  content_type = each.value.description
  tags         = var.tags
}

