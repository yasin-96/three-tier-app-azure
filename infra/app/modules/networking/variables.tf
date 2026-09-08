variable "resource_group_name" {
  description = "Name der Resource Group, in der die Netzwerk-Ressourcen erstellt werden"
  type        = string
}

variable "location" {
  description = "Azure-Region"
  type        = string
}

variable "vnet_cidr" {
  description = "Adressraum des VNets"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR für das Public Subnet (Application Gateway, NAT Gateway)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_subnet_cidr" {
  description = "CIDR für das App Subnet (Container Apps)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR für das Data Subnet (PostgreSQL Flexible Server, delegiert)"
  type        = string
  default     = "10.0.3.0/24"
}