
resource "azurerm_subnet" "proy_app_subnet" {
  provider = azurerm.ailz
  name                  = "snet-proy-appserv-${var.basename}-${var.deployment_environment}"
  resource_group_name   = local.persistent_resource_group_name
  virtual_network_name  = var.main_virtual_network_name    # se deja la misma vnet ?
  address_prefixes      = [local.main_virtual_network_subnets_cidr["app_service"]]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }

}

resource "azurerm_network_security_group" "proy_app_nsg" {
  provider = azurerm.ailz
  name                = "nsg-proy-appserv-${var.basename}-${var.deployment_environment}"
  location            = local.location
  resource_group_name = local.persistent_resource_group_name#azurerm_resource_group.rg_proyecto.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "proy_app_nsg_association" {
  provider = azurerm.ailz
  subnet_id                 = azurerm_subnet.proy_app_subnet.id
  network_security_group_id = azurerm_network_security_group.proy_app_nsg.id
}

resource "azurerm_subnet_route_table_association" "proy_app_route_table_association" {
  provider       = azurerm.ailz
  
  subnet_id      = azurerm_subnet.proy_app_subnet.id
  route_table_id = local.networking_properties.route_table_association
}

