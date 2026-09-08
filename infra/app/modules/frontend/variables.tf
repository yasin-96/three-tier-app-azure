variable "resource_group_name" {
  description = "Name der Resource Group, in der die Netzwerk-Ressourcen erstellt werden"
  type        = string
  default     = "three-tier-rg"
}

variable "location" {
  description = "Azure-Region"
  type        = string
  default     = "germanywestcentral"
}