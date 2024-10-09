########################################################################################################
####                                  Principal AILZ Subnet Configuration                           ####
########################################################################################################

resource "azurerm_subnet" "pep_subnet" {
  provider = azurerm.ailz
  name                  = substr(join("-", compact(["snet-pep", var.basename, var.deployment_environment])), 0, 80)
  resource_group_name   = local.persistent_resource_group_name
  virtual_network_name  = var.main_virtual_network_name 
  address_prefixes      = [local.main_virtual_network_subnets_cidr["privateendpoints"]]

}

resource "azurerm_network_security_group" "pep_nsg" {
  provider = azurerm.ailz
  name                = substr(join("-", compact(["nsg-pep", var.basename, var.deployment_environment])), 0, 80)
  location            = local.location
  resource_group_name = local.persistent_resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "pep_nsg_association" {
  provider = azurerm.ailz
  subnet_id                 = azurerm_subnet.pep_subnet.id
  network_security_group_id = azurerm_network_security_group.pep_nsg.id
}

resource "azurerm_subnet_route_table_association" "route_table_association" {
  provider = azurerm.ailz
  
  subnet_id      = azurerm_subnet.pep_subnet.id
  route_table_id = local.networking_properties.route_table_association
}

