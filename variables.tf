variable "name" {
  description = "(Required) Specifies the name of the Container Registry. Only Alphanumeric characters allowed. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the Container Registry. Changing this forces a new resource to be created."
  type        = string
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "admin_enabled" {
  description = "(Optional) Specifies whether the admin user is enabled. Defaults to `false`."
  type        = bool
  default     = false
}

variable "anonymous_pull_enabled" {
  description = "(Optional) Whether allows anonymous (unauthenticated) pull access to this Container Registry? This is only supported on resources with the Standard or Premium SKU."
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "(Optional) Whether to enable dedicated data endpoints for this Container Registry? This is only supported on resources with the Premium SKU."
  type        = bool
  default     = false
}

variable "enable_content_trust" {
  description = "(Optional) Boolean value to enable or disable Content trust in Azure Container Registry."
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "(Optional) Boolean value that indicates whether export policy is enabled. Defaults to `true`. In order to set it to false, make sure the public_network_access_enabled is also set to false."
  type        = bool
  default     = true
}

variable "georeplications" {
  description = <<EOT
  (Optional) A georeplications block as documented below.
  list(object({
    location                  = (Required) A location where the container registry should be geo-replicated.
    regional_endpoint_enabled = (Optional) Whether regional endpoint is enabled for this Container Registry?
    zone_redundancy_enabled   = (Optional) Whether zone redundancy is enabled for this replication location? Defaults to `false`.
    tags                      = (Optional) A mapping of tags to assign to this replication location.
  }))
  EOT
  type = list(object({
    location                  = string
    regional_endpoint_enabled = optional(bool)
    zone_redundancy_enabled   = optional(bool)
    tags                      = optional(map(any))
  }))
  default = []
}

variable "identity" {
  description = <<EOT
  (Optional) An identity block as defined below.
  object({
    type         = (Required) Specifies the type of Managed Service Identity that should be configured on this Container Registry. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both).
    identity_ids = (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Container Registry.
  })
  EOT
  type = object({
    type         = string
    identity_ids = optional(list(string),null)
  })
  default = null
  validation {
    condition     = var.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    error_message = "Error: Accepted values for type are either `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned`"
  }
}

variable "network_rule_bypass_option" {
  description = "(Optional) Whether to allow trusted Azure services to access a network restricted Container Registry? Possible values are None and AzureServices. Defaults to `AzureServices`."
  type        = string
  default     = "AzureServices"
  validation {
    condition     = contains(["None", "AzureServices"], var.network_rule_bypass_option)
    error_message = "Error: Accepted values are either `None` or `AzureServices`."
  }
}

variable "network_rule_set" {
  description = <<EOT
  (Optional) A network_rule_set block as documented below.
  Azure automatically configures Network Rules - to remove these you'll need to specify an network_rule_set block with default_action set to `Deny`.
  object({
    default_action  = (Optional) The behaviour for requests matching no rules. Either `Allow` or `Deny`. Defaults to `Allow`.
    ip_rule         = (Optional) One or more ip_rule blocks as defined below.
    type = object({
      ip_range = (Required) The CIDR block from which requests will match the rule.
    })
    virtual_network = (Optional) One or more virtual_network blocks as defined below.
    type = object({
      subnet_id = (Required) The subnet id from which requests will match the rule.
    })
  })
  EOT
  type = object({
    default_action = optional(string,"Allow")
    ip_rule = optional(object({
      ip_range = string
    }))
    virtual_network = optional(object({
      subnet_id = string
    }))
  })
  default = null
  validation {
    condition     = var.network_rule_set == null ? true : contains(["Allow", "Deny"], var.network_rule_set.default_action)
    error_message = "Error: Accepted values for `default_action` are either `Allow` or `Deny`."
  }
}

variable "public_network_access_enabled" {
  description = "(Optional) Whether public network access is allowed for the container registry. Defaults to `false`."
  type        = bool
  default     = false
}

variable "quarantine_policy_enabled" {
  description = "(Optional) Boolean value that indicates whether quarantine policy is enabled."
  type        = bool
  default     = false
}

variable "retention_policy" {
  description = <<EOT
  (Optional) A retention_policy block as documented below.
  object({
    days    = (Optional) The number of days to retain an untagged manifest after which it gets purged. Default is 7.
    enabled = (Optional) Boolean value that indicates whether the policy is enabled.
  })
  EOT
  type = object({
    days    = optional(string)
    enabled = optional(bool)
  })
  default = null
}

variable "sku" {
  description = "(Optional) The SKU name of the container registry. Possible values are `Basic`, `Standard` and `Premium`."
  type        = string
  default     = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "Error: Accepted values are either `Basic`, `Standard` or `Premium`."
  }
}

variable "zone_redundancy_enabled" {
  description = "(Optional) Whether zone redundancy is enabled for this Container Registry? Changing this forces a new resource to be created. Defaults to 'false'."
  type        = bool
  default     = false
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(any)
  default     = {}
}

#---------------------------------------------------------
# Private Endpoint for Key Vault
#---------------------------------------------------------

variable "private_endpoint_subnet" {
  description = "(Optional) Network information required to create a private endpoint."
  type = object({
    virtual_network_name = string
    name                 = string
    resource_group_name  = string
  })
  default = null
}
