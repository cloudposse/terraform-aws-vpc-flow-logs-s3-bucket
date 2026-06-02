locals {
  enabled = module.this.enabled

  bucket_name = length(var.bucket_name) > 0 ? var.bucket_name : module.bucket_name.id

  arn_format  = "arn:${data.aws_partition.current.partition}"
  create_kms  = local.enabled && (var.kms_key_arn == null || var.kms_key_arn == "")
  kms_key_arn = local.create_kms ? module.kms_key.alias_arn : var.kms_key_arn

  lifecycle_configuration_rules = (local.deprecated_lifecycle_rule.enabled ?
    tolist(concat(var.lifecycle_configuration_rules, [local.deprecated_lifecycle_rule])) : var.lifecycle_configuration_rules
  )

  # Effective object ownership: null input selects the recommended BucketOwnerEnforced.
  effective_ownership = var.s3_object_ownership == null ? "BucketOwnerEnforced" : var.s3_object_ownership

  # With BucketOwnerEnforced, S3 has ACLs entirely disabled. The log-delivery service
  # does not send the x-amz-acl header in that mode, so a StringEquals condition on
  # s3:x-amz-acl will never match and will silently deny all writes.  Only include the
  # ACL condition for ownership modes that still have ACLs enabled.
  acl_condition_required = local.effective_ownership != "BucketOwnerEnforced"

  # Source-scoping conditions for confused-deputy protection and cross-account delivery.
  # Priority: org ID (broadest, single condition) > account list > none (same-account only).
  use_org_condition     = length(var.flow_logs_source_org_id) > 0
  use_account_condition = !local.use_org_condition && length(var.flow_logs_source_account_ids) > 0
}

module "bucket_name" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled = local.enabled && length(var.bucket_name) == 0

  id_length_limit = 63 # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html

  context = module.this.context
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  count = module.this.enabled ? 1 : 0

  source_policy_documents = [var.kms_policy_source_json]

  statement {
    sid    = "Enable Root User Permissions"
    effect = "Allow"

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:Tag*",
      "kms:Untag*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    #bridgecrew:skip=CKV_AWS_109:This policy applies only to the key it is attached to
    #bridgecrew:skip=CKV_AWS_111:This policy applies only to the key it is attached to
    resources = [
      "*"
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${local.arn_format}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }

  statement {
    sid    = "Allow VPC Flow Logs to use the key"
    effect = "Allow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [
      "*"
    ]

    principals {
      type = "Service"

      identifiers = [
        "delivery.logs.amazonaws.com"
      ]
    }

    # Mirror the same source scoping used on the bucket policy for confused-deputy protection.
    dynamic "condition" {
      for_each = local.use_org_condition ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [var.flow_logs_source_org_id]
      }
    }
    dynamic "condition" {
      for_each = local.use_account_condition ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.flow_logs_source_account_ids
      }
    }
  }
}

# https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3-permissions.html
data "aws_iam_policy_document" "bucket" {
  count = module.this.enabled ? 1 : 0

  # Grant the VPC Flow Logs delivery service permission to write log objects.
  #
  # The s3:x-amz-acl condition is only included when ACLs are enabled on the bucket
  # (i.e. s3_object_ownership is ObjectWriter or BucketOwnerPreferred).  When
  # BucketOwnerEnforced is in effect, S3 rejects all ACL-related headers; the
  # delivery service sends no ACL header in that mode, so a StringEquals condition
  # on s3:x-amz-acl would never match and would silently deny every write.
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${local.arn_format}:s3:::${local.bucket_name}/*"
    ]

    # Only add the ACL condition when ownership mode allows ACLs.
    dynamic "condition" {
      for_each = local.acl_condition_required ? [1] : []
      content {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    }

    # Scope to a specific AWS Organization (takes priority over per-account scoping).
    dynamic "condition" {
      for_each = local.use_org_condition ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [var.flow_logs_source_org_id]
      }
    }

    # Scope to explicit account IDs when no org ID is provided.
    dynamic "condition" {
      for_each = local.use_account_condition ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.flow_logs_source_account_ids
      }
    }

    # Restrict to ARNs originating from the listed accounts (confused-deputy protection).
    dynamic "condition" {
      for_each = local.use_account_condition ? [1] : []
      content {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values = [
          for id in var.flow_logs_source_account_ids :
          "${local.arn_format}:logs:*:${id}:*"
        ]
      }
    }
  }

  # Grant the delivery service permission to read the bucket ACL. The log-delivery service calls
  # GetBucketAcl as part of its pre-write checks regardless of Object Ownership mode; this is a
  # bucket-policy read and is unrelated to ACL enforcement.
  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      "${local.arn_format}:s3:::${local.bucket_name}"
    ]

    # Mirror the same source conditions applied to the Write statement.
    dynamic "condition" {
      for_each = local.use_org_condition ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [var.flow_logs_source_org_id]
      }
    }

    dynamic "condition" {
      for_each = local.use_account_condition ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = var.flow_logs_source_account_ids
      }
    }

    dynamic "condition" {
      for_each = local.use_account_condition ? [1] : []
      content {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values = [
          for id in var.flow_logs_source_account_ids :
          "${local.arn_format}:logs:*:${id}:*"
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = var.allow_ssl_requests_only ? [1] : []

    content {
      sid     = "ForceSSLOnlyAccess"
      effect  = "Deny"
      actions = ["s3:*"]
      resources = [
        "${local.arn_format}:s3:::${local.bucket_name}/*",
        "${local.arn_format}:s3:::${local.bucket_name}"
      ]

      principals {
        identifiers = ["*"]
        type        = "*"
      }

      condition {
        test     = "Bool"
        values   = ["false"]
        variable = "aws:SecureTransport"
      }
    }
  }

  lifecycle {
    # some form of name must be supplied.
    precondition {
      condition     = try(length(local.bucket_name) > 0, false)
      error_message = <<-EOT
        Bucket name must be provided either directly via `bucket_name`
        or indirectly via `null-label` inputs such as `name` or `namespace`.
        EOT
    }
  }
}

module "kms_key" {
  enabled = local.create_kms
  source  = "cloudposse/kms-key/aws"
  version = "0.12.2"

  alias = format("alias/%v", local.bucket_name)

  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = join("", data.aws_iam_policy_document.kms[*].json)

  context = module.this.context

  # Depend on the data resource for error checking,
  # because we cannot have a precondition on a module.
  depends_on = [data.aws_iam_policy_document.bucket]
}

module "s3_log_storage_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "2.0.0"

  bucket_name = local.bucket_name

  kms_master_key_arn = local.kms_key_arn
  sse_algorithm      = "aws:kms"
  bucket_key_enabled = var.bucket_key_enabled

  lifecycle_configuration_rules = local.lifecycle_configuration_rules
  object_lock_configuration     = var.object_lock_configuration

  force_destroy = var.force_destroy

  acl                     = var.acl
  s3_object_ownership     = local.effective_ownership
  source_policy_documents = data.aws_iam_policy_document.bucket[*].json

  bucket_notifications_enabled = var.bucket_notifications_enabled
  bucket_notifications_type    = var.bucket_notifications_type
  bucket_notifications_prefix  = var.bucket_notifications_prefix

  access_log_bucket_name   = var.access_log_bucket_name
  access_log_bucket_prefix = var.access_log_bucket_prefix

  versioning_enabled = var.versioning_enabled

  context = module.this.context
}

resource "aws_flow_log" "default" {
  count                = local.enabled && var.flow_log_enabled ? 1 : 0
  log_destination      = module.s3_log_storage_bucket.bucket_arn
  log_destination_type = "s3"
  log_format           = var.log_format
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id

  tags = module.this.tags
}
