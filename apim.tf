resource "azurerm_user_assigned_identity" "apims_uais" {
  provider = azurerm.ailz

  for_each            = var.apim_config
  name                = local.uai_apim_names[each.key]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  tags                = local.tags
}


# Assing the role to the APIM to access the cognitive services

resource "azurerm_role_assignment" "role-assign-apim-congnitive" {
  provider     = azurerm.ailz
  for_each     = module.openai
 
  scope                = each.value.cognitive_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = module.apim["main"].SystemAssigned_identity
  
  depends_on = [ module.openai ]
}

# Assing the role to the APIM to access the keyvaults
resource "azurerm_key_vault_access_policy" "keyvaults_access_policies" {
  provider     = azurerm.ailz
  for_each     = var.apim_config
  key_vault_id = module.keyvaults["main"].key-vault-id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.apims_uais[each.key].principal_id
  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_public_ip" "apims_public_ips" {
  provider            = azurerm.ailz
  for_each            = var.apim_config
  name                = local.apim_public_ip_names[each.key]
  resource_group_name = local.persistent_resource_group_name
  location            = local.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = "${local.apim_public_ip_names[each.key]}-${local.random_seed_hex}"
  tags                = local.tags
}
resource "azurerm_subnet" "apim_subnet" {
  provider             = azurerm.ailz
  name                 = "snet-apim-${var.basename}-${var.deployment_environment}"
  resource_group_name  = local.persistent_resource_group_name
  virtual_network_name = var.main_virtual_network_name
  address_prefixes     = [local.main_virtual_network_subnets_cidr["apim"]]

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet_route_table_association" "apim_route_table_association" {
  provider       = azurerm.ailz
  subnet_id      = azurerm_subnet.apim_subnet.id
  route_table_id = local.networking_properties.route_table_association
}

resource "azurerm_network_security_group" "apim_nsg" {
  provider            = azurerm.ailz
  name                = "nsg-apim-${var.basename}-${var.deployment_environment}"
  location            = local.location
  resource_group_name = local.persistent_resource_group_name
  tags                = local.tags
}
resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  provider                  = azurerm.ailz
  subnet_id                 = azurerm_subnet.apim_subnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowClientCommunication" {
  provider                    = azurerm.ailz
  name                        = "AllowClientCommunication"
  priority                    = 100
  direction                   = "Inbound" #revisar
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowManagementConnection" {
  provider                    = azurerm.ailz
  name                        = "AllowManagementConnection"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "ApiManagement"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowLoadBalancerConnection" {
  provider                    = azurerm.ailz
  name                        = "AllowLoadBalancerConnection"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6390"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowStorageDepConnection" {
  provider                    = azurerm.ailz
  name                        = "AllowStorageDepConnection"
  priority                    = 103
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Storage"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowSQLEndpointsAccess" {
  provider                    = azurerm.ailz
  name                        = "AllowSQLEndpointsAccess"
  priority                    = 104
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "SQL"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowKeyvaultAccess" {
  provider                    = azurerm.ailz
  name                        = "AllowKeyvaultAccess"
  priority                    = 105
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureKeyVault"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule_AllowDiagnosticLogPublishing" {
  provider                    = azurerm.ailz
  name                        = "AllowDiagnosticLogPublishing"
  priority                    = 106
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["1886", "443"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureMonitor"
  resource_group_name         = local.persistent_resource_group_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}


module "apim" {
  for_each = var.apim_config

  providers = {
    azurerm = azurerm.ailz
  }
  
  source                        = "./modules/az_apim"
  resource_group_name           = local.persistent_resource_group_name
  resource_group_id             = data.azurerm_resource_group.properties_rg.id
  basename                      = var.basename
  suffix                        = substr(local.random_seed_hex, 0, 2)
  enable_storage_account_diag   = true
  storage_account_id_diag       = module.diag_storage_account.storage-account-id
  uai_id                        = azurerm_user_assigned_identity.apims_uais[each.key].id
  uai_client_id                 = azurerm_user_assigned_identity.apims_uais[each.key].client_id
  snet_id                       = azurerm_subnet.apim_subnet.id
  enable_pep                    = false
  inbound_subnet_id             = azurerm_subnet.pep_subnet.id
  publisher_name                = "Suramericana"
  publisher_email               = local.responsible_analyst_upn
  extra_tags                    = local.tags
  sku_name                      = each.value.sku
  capacity                      = each.value.capacity
  is_developer_portal_enabled   = each.value.enable_developer_portal

  enable_backend                = each.value.enable_backend
  backend_definitions           = local.backend_definition_apim
  deployment_environment        = var.deployment_environment
}



#############################################################################################################################
####                                           Import APIS definitions                                                   ####
#############################################################################################################################
#1.14.0 azapi

#resource "azapi_update_resource" "apim_api_def" {
#  for_each = local.api_def_apim_map
#  type      = "Microsoft.ApiManagement/service@2023-09-01-preview"
#  parent_id = each.value.apim_id
#  name = "import"
#
#}

#resource "azapi_update_resource" "import_openai_api" {
#  for_each  = local.api_files
#  type      = "Microsoft.ApiManagement/service/apis@2023-09-01-preview"
#  parent_id = azapi_resource.apim.id
#  name      = "import-openai-api-${basename(each.value, ".yaml")}"
#
#  body = jsonencode({
#    properties = {
#      format     = "yaml"
#      value      = file("${path.module}/apis/${each.value}")
#      path       = basename(each.value, ".yaml")
#      serviceUrl = azurerm_api_management_backend.openai_backend.url
#      protocols  = ["https"]
#      backendService = {
#        url = azurerm_api_management_backend.openai_backend.url
#      }
#    }
#
#
#resource "azurerm_api_management_api" "example" {
#  name                = "example-api"
#  resource_group_name = azurerm_resource_group.example.name
#  api_management_name = azurerm_api_management.example.name
#  revision            = "1"
#  display_name        = "Example API"
#  path                = "example"
#  protocols           = ["https"]
#
#  import {
#    content_format = "swagger-link-json"
#    content_value  = "http://conferenceapi.azurewebsites.net/?format=json"
#  }
#}

#############################################################################################################################
####                                           Named values for APIM                                                     ####
#############################################################################################################################

#resource "azurerm_api_management_named_value" "name_values_apim" {
#  for_each = var.apim_config
#
#  provider = azurerm.ailz
#
#  name                = "apim-${var.basename}-${var.deployment_environment}"
#  resource_group_name = local.persistent_resource_group_name
#  api_management_name = module.apim[each.key].apim_name
#  display_name        = "apim-${var.basename}-${var.deployment_environment}"
#  #value               = module.apim[each.key].primary_key
#  tags                = local.tags
#
#  #https://kv-ailzmaindll00.vault.azure.net/secrets/contentSafetyKey
#  value_from_key_vault {
#    secret_id = 
#   identity_client_id = azurerm_user_assigned_identity.apims_uais[each.key].client_id
#  
#}
