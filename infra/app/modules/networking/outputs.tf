output "app_subnet_id" {
  description = "ID des App-Subnets (für die Container Apps Environment)"
  value       = azurerm_subnet.app.id
}

output "public_subnet_id" {
  description = "ID des Public-Subnets (für das Application Gateway)"
  value       = azurerm_subnet.public.id
}

output "data_subnet_id" {
  description = "ID des Data-Subnets (für PostgreSQL)"
  value       = azurerm_subnet.data.id
}

output "vnet_id" {
  description = "ID des VNets"
  value       = azurerm_virtual_network.main.id
}