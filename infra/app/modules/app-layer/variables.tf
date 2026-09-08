variable "location" {
  description = "Azure-Region (z.B. germanywestcentral)"
  type        = string
}

variable "resource_group_name" {
  description = "Name der Resource Group, in der die Netzwerk-Ressourcen erstellt werden"
  type        = string
}

variable "app_subnet_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "vnet_id" {
  type = string
}