variable "lifecycle_rule_enabled" {
  type        = bool
  description = <<-EOF
    DEPRECATED: Use `lifecycle_configuration_rules` instead.
    When `true`, configures lifecycle events on this bucket using individual (now deprecated) variables.
    When `false`, lifecycle events are not configured using individual (now deprecated) variables, but `lifecycle_configuration_rules` still apply.
    When `null`, lifecycle events are configured using individual (now deprecated) variables only if `lifecycle_configuration_rules` is empty.
    EOF
  default     = null
}

variable "lifecycle_prefix" {
  type        = string
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nPrefix filter. Used to manage object lifecycle events"
  default     = null
}

variable "lifecycle_tags" {
  type        = map(string)
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nTags filter. Used to manage object lifecycle events"
  default     = null
}

variable "expiration_days" {
  type        = number
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nNumber of days after which to expunge the objects"
  default     = null
}

variable "standard_transition_days" {
  type        = number
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nNumber of days to persist in the standard storage tier before moving to the infrequent access tier"
  default     = null
}

variable "glacier_transition_days" {
  type        = number
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nNumber of days after which to move the data to the Glacier Flexible Retrieval storage tier"
  default     = null
}

variable "noncurrent_version_transition_days" {
  type        = number
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nSpecifies (in days) when noncurrent object versions transition to Glacier Flexible Retrieval"
  default     = null
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "(Deprecated, use `lifecycle_configuration_rules` instead)\nSpecifies when non-current object versions expire (in days)"
  default     = null
}



locals {
  deprecated_lifecycle_rule = {
    enabled                                = var.lifecycle_rule_enabled == true || (var.lifecycle_rule_enabled == null && length(var.lifecycle_configuration_rules) == 0)
    id                                     = "_legacy_"
    abort_incomplete_multipart_upload_days = 5
    filter_and = {
      object_size_greater_than = null # integer >= 0
      object_size_less_than    = null # integer >= 1
      prefix                   = var.lifecycle_prefix
      tags                     = var.lifecycle_tags
    }

    transition = [
      {
        date          = null # string, RFC3339 time format, GMT
        days          = coalesce(var.standard_transition_days, 30)
        storage_class = "STANDARD_IA"
      },
      {
        date          = null # string, RFC3339 time format, GMT
        days          = coalesce(var.glacier_transition_days, 60)
        storage_class = "GLACIER"
      }
    ]
    noncurrent_version_transition = var.noncurrent_version_transition_days == null ? [] : [
      {
        days          = var.noncurrent_version_transition_days
        storage_class = "GLACIER"
      }
    ]

    expiration = {
      date                         = null # string, RFC3339 time format, GMT
      days                         = coalesce(var.expiration_days, 90)
      expired_object_delete_marker = null # bool
    }
    noncurrent_version_expiration = {
      newer_noncurrent_versions = null # integer > 0
      noncurrent_days           = coalesce(var.noncurrent_version_expiration_days, 90)
    }
  }
}
