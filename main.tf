#-----------------------------------------------
# Resource Time Static
#-----------------------------------------------
resource "time_static" "this" {}

#-----------------------------------------------------
# Resource Container Registry
#-----------------------------------------------------

resource "azurerm_container_registry" "this" {

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled
  export_policy_enabled         = var.export_policy_enabled
  public_network_access_enabled = var.public_network_access_enabled
  quarantine_policy_enabled     = var.quarantine_policy_enabled
  sku                           = var.sku
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  tags = merge(var.tags, {
    creation_date        = "${time_static.this.year}-${time_static.this.month}-${time_static.this.day}"
    managed_by_terraform = "true"
  })

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags = merge(var.tags, {
        creation_date        = "${time_static.this.year}-${time_static.this.month}-${time_static.this.day}"
        managed_by_terraform = "true"
      })
    }
  }

  dynamic "identity" {
    for_each = var.identity != null ? {"identity" = var.identity} : {}
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  network_rule_bypass_option = var.network_rule_bypass_option

  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? {network_rule_set = var.network_rule_set} : {}
    content {
      default_action = network_rule_set.value.default_action

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule
        content {
          action   = "Allow"
          ip_range = ip_rule.value.ip_range
        }
      }

      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_network
        content {
          action    = "Allow"
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? {retention_policy = var.retention_policy} : {}
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }

  dynamic "trust_policy" {
    for_each = var.enable_content_trust ? {trust_policy = var.enable_content_trust} : {}
    content {
      enabled = trust_policy.value
    }
  }

  lifecycle {
    precondition {
      condition     = !var.anonymous_pull_enabled ? true : var.sku == "Standard" || var.sku == "Premium"
      error_message = "`anonymous_pull_enabled` cannot be used along with `sku` set to `Basic`."
    }
    precondition {
      condition     = !var.data_endpoint_enabled ? true : var.sku == "Premium"
      error_message = "`data_endpoint_enabled` can only be used along with `sku` set to `Premium`."
    }
    precondition {
      condition     = var.export_policy_enabled ? true : var.public_network_access_enabled == false
      error_message = "`export_policy_enabled` can only be used along with `public_network_access_enabled` set to `false`."
    }
    precondition {
      condition     = var.network_rule_set == null ? true : var.sku == "Premium"
      error_message = "`network_rule_set` can only be used along with `sku` set to `Premium`."
    }
  }

}

#---------------------------------------------------------
# Creating Private Endpoint
#---------------------------------------------------------

# Get Networking Data for a Private Endpoint
data "azurerm_subnet" "this" {
  count = var.private_endpoint_subnet != null ? 1 : 0

  name                 = var.private_endpoint_subnet.name
  virtual_network_name = var.private_endpoint_subnet.virtual_network_name
  resource_group_name  = var.private_endpoint_subnet.resource_group_name

}

# Private Endpoint Creation or selection
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet != null ? 1 : 0

  name                          = "${var.name}-pe"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  subnet_id                     = data.azurerm_subnet.this[0].id
  custom_network_interface_name = "${var.name}-nic"
  tags = merge(var.tags, {
    creation_date        = "${time_static.this.year}-${time_static.this.month}-${time_static.this.day}"
    managed_by_terraform = "true"
  })

  private_service_connection {
    name                           = "${var.name}-pe" 
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
  
}
