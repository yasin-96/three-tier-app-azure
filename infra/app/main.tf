provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatethreetier"
    container_name       = "tfstate"
    key                  = "app/terraform.tfstate" # ← "app/" statt "bootstrap/"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_resource_group" "app" {
  name     = "three-tier-rg"
  location = "germanywestcentral"
}

module "networking" {
  source              = "./modules/networking"
  location            = var.location
  resource_group_name = var.resource_group_name
}

module "app-layer" {
  source              = "./modules/app-layer"
  location            = var.location
  resource_group_name = var.resource_group_name
  app_subnet_id       = module.networking.app_subnet_id
  public_subnet_id    = module.networking.public_subnet_id
  vnet_id = module.networking.vnet_id
  cert_password = var.cert_password
}

module "frontend" {
  source = "./modules/frontend"
  location = var.location
  resource_group_name = var.resource_group_name
}