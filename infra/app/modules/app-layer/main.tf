resource "azurerm_container_app_environment" "main" {
  name                           = "three-tier-env"
  resource_group_name            = var.resource_group_name
  location                       = var.location
  infrastructure_subnet_id       = var.app_subnet_id
  internal_load_balancer_enabled = true
  #zone_redundancy_enabled        = true  
}

resource "azurerm_public_ip" "appgw" {
  name                = "appgw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "three-tier-api" 
}

resource "azurerm_network_security_group" "appgw" {
  name                = "appgw-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  # 1. Eingehender Web-Traffic vom Internet (dein myapi.com)
  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80" # bzw. 443 bei HTTPS
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # 2. PFLICHT: Gateway-Manager-Ports für Application Gateway v2
  security_rule {
    name                       = "allow-gwmanager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"    # v2-Verwaltungs-Ports
    source_address_prefix      = "GatewayManager" # Azure Service Tag
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = var.public_subnet_id
  network_security_group_id = azurerm_network_security_group.appgw.id
}



resource "azurerm_application_gateway" "main" {
  name                = "three-tier-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.public_subnet_id
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  # WOHIN (Backend Pool = dein "Target Group"-Äquivalent)
  backend_address_pool {
    name = "container-apps-pool"

    fqdns = [
      "backend-app.${azurerm_container_app_environment.main.default_domain}"
    ]
  }

  # WIE zum Backend verbunden wird
  backend_http_settings {
    name                                = "http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    probe_name                          = "container-app-probe" # ← verweist auf die Probe

    host_name = "backend-app.${azurerm_container_app_environment.main.default_domain}"
  }

  # WORAUF das Gateway lauscht
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # Verbindet alles: Listener → Settings → Pool
  request_routing_rule {
    name                       = "routing-rule"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "container-apps-pool"
    backend_http_settings_name = "http-settings"
  }

  probe {
    name                                      = "container-app-probe"
    protocol                                  = "Https"
    path                                      = "/actuator/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3

    host = "backend-app.${azurerm_container_app_environment.main.default_domain}"

    match {
      status_code = ["200"]
    }
  }
}

resource "azurerm_container_app" "main" {
  name                         = "backend-app"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

   identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.containerapp.id
  }

  template {
    min_replicas = 2
    max_replicas = 3

    container {
      name   = "backend"
      image = "nginx_latest" #placeholder image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"
    

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_private_dns_zone" "containerapps" {
  name                = azurerm_container_app_environment.main.default_domain
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "containerapps" {
  name                  = "link-appgw-vnet"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.containerapps.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "backend" {
  name                = "backend-app"
  zone_name           = azurerm_private_dns_zone.containerapps.name
  resource_group_name = var.resource_group_name
  ttl                 = 30
  records             = [azurerm_container_app_environment.main.static_ip_address]
}

resource "azurerm_container_registry" "main" {
  name                = "acrthreetier"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"              
  admin_enabled       = false      
}

resource "azurerm_user_assigned_identity" "containerapp" {
  name                = "containerapp-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}