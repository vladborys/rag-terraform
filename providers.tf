provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id            = var.remote_state_subscription_id
  storage_use_azuread        = true
}

provider "azurerm" {
  alias               = "ailz"
  subscription_id     = var.ailz_subscription_id
  storage_use_azuread = true

  features {}
}

provider "azurerm" {
  alias = "privatednszones_int"

  features {}
  skip_provider_registration = true
  subscription_id            = var.private_dns_zones_subscription_id
}

provider "null" {}