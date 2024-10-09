# © Copyright Seguros SURA 2023
terraform {
  backend "azurerm" {}

  required_version = ">= 1.5.6"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.14.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.51.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    # https://github.com/hashicorp/terraform-provider-tls/issues/205
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "~> 0.2.5"
    }
    
  }
}

data "azurerm_resource_group" "properties_rg" {
  provider = azurerm.ailz
  name     = local.persistent_resource_group_name
}

#resource "azurerm_user_assigned_identity" "uais_cs" {
#  provider = azurerm.ailz
#
#  name                = "${var.basename}-uais-cs"
#  resource_group_name = local.persistent_resource_group_name
#  location            = local.location
#  tags                = local.tags
#}

#module "analytics" {
#  source = "./modules/analytics"
#  log_analytics_workspace_name = module.policies.log_analytics_workspace_name.name
#  application_insights_name = module.policies.application_insights_name.name
#  application_insights_workbook_name = module.policies.application_insights_workbook_name.name
#
#  azure_region = local.location
#  resource_group_name = local.persistent_resource_group_name
#  deployment_environment = var.deployment_environment
#}
