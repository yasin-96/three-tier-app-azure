provider "azurerm" {
  features {}
}

provider "azuread" {
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatethreetier"
    container_name       = "tfstate"
    key                  = "bootstrap/terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate"
  location = "germanywestcentral"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstatethreetier"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azuread_application" "github" {
  display_name = "github-actions-three-tier"
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
}

resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application.github.id
  display_name   = "github-federated-cred"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:yasin-96@62212311/three-tier-app-azure@1354662097:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github_contributor" {
  scope                = azurerm_resource_group.tfstate.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github.object_id
}

resource "azurerm_role_assignment" "github_contributor_app" {
  scope                = "/subscriptions/678c11b0-ff2e-44fb-8cbd-f7d3a849c3b0/resourceGroups/three-tier-rg"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github.object_id
}

resource "azurerm_role_assignment" "github_state_blob" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github.object_id
}