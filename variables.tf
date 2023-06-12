variable "vpc_id" {
  type        = string
  description = "VPC ID to create flow logs for"
  default     = null
}

variable "bucket_name" {
  type        = string
  description = <<-EOT
    Bucket name. If not provided, the bucket will be created with a name generated from the context.
    EOT
  default     = ""
  nullable    = false
  validation {
    condition     = length(var.bucket_name) <= 63
    error_message = "Bucket name, if provided, must be <= 63 characters."
  }
}

variable "force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable"
  default     = false
  nullable    = false
}

variable "traffic_type" {
  type        = string
  description = "The type of traffic to capture. Valid values: `ACCEPT`, `REJECT`, `ALL`"
  default     = "ALL"
  nullable    = false
}

variable "allow_ssl_requests_only" {
  type        = bool
  description = "Set to `true` to require requests to use Secure Socket Layer (HTTPS/SSL). This will explicitly deny access to HTTP requests"
  default     = true
  nullable    = false
}

variable "flow_log_enabled" {
  type        = bool
  description = "Enable/disable the Flow Log creation. Useful in multi-account environments where the bucket is in one account, but VPC Flow Logs are in different accounts"
  default     = true
  nullable    = false
}

variable "bucket_notifications_enabled" {
  type        = bool
  description = "Send notifications for the object created events. Used for 3rd-party log collection from a bucket"
  default     = false
  nullable    = false
}

variable "bucket_notifications_type" {
  type        = string
  description = "Type of the notification configuration. Only SQS is supported."
  default     = "SQS"
  nullable    = false
}

variable "bucket_notifications_prefix" {
  type        = string
  description = "Prefix filter. Used to manage object notifications"
  default     = ""
  nullable    = false
}

variable "access_log_bucket_name" {
  type        = string
  description = "Name of the S3 bucket where S3 access log will be sent to"
  default     = ""
  nullable    = false
}

variable "access_log_bucket_prefix" {
  type        = string
  description = "Prefix to prepend to the current S3 bucket name, where S3 access logs will be sent to"
  default     = "logs/"
  nullable    = false
}

variable "kms_key_arn" {
  type        = string
  description = "ARN (or alias) of KMS that will be used for s3 bucket encryption."
  default     = ""
  nullable    = false
}

variable "kms_policy_source_json" {
  type        = string
  description = "Additional IAM policy document that can optionally be merged with default created KMS policy"
  default     = ""
  nullable    = false
}

variable "bucket_key_enabled" {
  type        = bool
  description = <<-EOT
  Set this to true to use Amazon S3 Bucket Keys for SSE-KMS, which may reduce the number of AWS KMS requests.
  For more information, see: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
  EOT
  default     = true
  nullable    = false
}

variable "versioning_enabled" {
  type        = bool
  description = "Enable object versioning, keeping multiple variants of an object in the same bucket"
  default     = false
  nullable    = false
}

variable "s3_object_ownership" {
  type        = string
  description = <<-EOF
    Specifies the S3 object ownership control.
    Valid values are `ObjectWriter`, `BucketOwnerPreferred`, and `BucketOwnerEnforced`."
    Default of `BucketOwnerPreferred` is for backwards compatibility.
    Recommended setting is `BucketOwnerEnforced`, which will be used if you pass in `null`.
    EOF
  default     = "BucketOwnerPreferred"
  # null selects the recommended setting of BucketOwnerEnforced
}

variable "acl" {
  type        = string
  description = "The canned ACL to apply. We recommend log-delivery-write for compatibility with AWS services"
  default     = "log-delivery-write"
}

/*
Schema for lifecycle_configuration_rules (defined in cloudposse/terraform-aws-s3-bucket module)
{
  enabled = true # bool
  id      = string
  abort_incomplete_multipart_upload_days = null # number
  filter_and = {
    object_size_greater_than = null # integer >= 0
    object_size_less_than    = null # integer >= 1
    prefix                   = null # string
    tags                     = {}   # map(string)
  }
  expiration = {
    date                         = null # string, RFC3339 time format, GMT
    days                         = null # integer > 0
    expired_object_delete_marker = null # bool
  }
  noncurrent_version_expiration = {
    newer_noncurrent_versions = null # integer > 0
    noncurrent_days           = null # integer >= 0
  }
  transition = [{
    date          = null # string, RFC3339 time format, GMT
    days          = null # integer >= 0
    storage_class = null # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
  }]
  noncurrent_version_transition = [{
    newer_noncurrent_versions = null # integer >= 0
    noncurrent_days           = null # integer >= 0
    storage_class             = null # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
  }]
}

*/
variable "lifecycle_configuration_rules" {
  type = list(object({
    enabled = bool
    id      = string

    abort_incomplete_multipart_upload_days = number

    # `filter_and` is the `and` configuration block inside the `filter` configuration.
    # This is the only place you should specify a prefix.
    filter_and = optional(object({
      object_size_greater_than = optional(number) # integer >= 0
      object_size_less_than    = optional(number) # integer >= 1
      prefix                   = optional(string)
      tags                     = optional(map(string))
    }))
    expiration = optional(object({
      date                         = optional(string) # string, RFC3339 time format, GMT
      days                         = optional(number) # integer > 0
      expired_object_delete_marker = optional(bool)
    }))
    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = optional(number) # integer > 0
      noncurrent_days           = optional(number) # integer >= 0
    }))
    transition = optional(list(object({
      date          = optional(string) # string, RFC3339 time format, GMT
      days          = optional(number) # integer >= 0
      storage_class = string           # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
    })), [])
    noncurrent_version_transition = optional(list(object({
      newer_noncurrent_versions = optional(number) # integer >= 0
      noncurrent_days           = optional(number) # integer >= 0
      storage_class             = string           # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
    })), [])
  }))
  description = "A list of lifecycle V2 rules"
  default     = []
  nullable    = false

}

variable "object_lock_configuration" {
  type = object({
    mode  = string # Valid values are GOVERNANCE and COMPLIANCE.
    days  = number
    years = number
  })
  description = <<-EOT
    A configuration for [S3 object locking](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html).
    EOT
  default     = null
}

variable "log_format" {
  description = "The fields to include in the flow log record, in the order in which they should appear."
  type        = string
  default     = null
}
