locals {
  arn_format  = "arn:${data.aws_partition.current.partition}"
  create_kms  = (var.kms_key_arn == null || var.kms_key_arn == "")
  kms_key_arn = local.create_kms ? module.kms_key.alias_arn : var.kms_key_arn
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  count = module.this.enabled ? 1 : 0

  source_json = var.kms_policy_source_json

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
  }
}

# https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3.html
data "aws_iam_policy_document" "bucket" {
  count = module.this.enabled ? 1 : 0

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
      "${local.arn_format}:s3:::${module.this.id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

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
      "${local.arn_format}:s3:::${module.this.id}"
    ]
  }

  dynamic "statement" {
    for_each = var.allow_ssl_requests_only ? [1] : []

    content {
      sid     = "ForceSSLOnlyAccess"
      effect  = "Deny"
      actions = ["s3:*"]
      resources = [
        "${local.arn_format}:s3:::${module.this.id}/*",
        "${local.arn_format}:s3:::${module.this.id}"
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
}

module "kms_key" {
  enabled = local.create_kms
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"

  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = join("", data.aws_iam_policy_document.kms.*.json)

  context = module.this.context
}

module "s3_log_storage_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "0.26.0"

  kms_master_key_arn                 = local.kms_key_arn
  sse_algorithm                      = "aws:kms"
  versioning_enabled                 = var.versioning_enabled
  expiration_days                    = var.expiration_days
  glacier_transition_days            = var.glacier_transition_days
  lifecycle_prefix                   = var.lifecycle_prefix
  lifecycle_rule_enabled             = var.lifecycle_rule_enabled
  lifecycle_tags                     = var.lifecycle_tags
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
  standard_transition_days           = var.standard_transition_days
  force_destroy                      = var.force_destroy
  policy                             = join("", data.aws_iam_policy_document.bucket.*.json)
  bucket_notifications_enabled       = var.bucket_notifications_enabled
  bucket_notifications_type          = var.bucket_notifications_type
  bucket_notifications_prefix        = var.bucket_notifications_prefix
  access_log_bucket_name             = var.access_log_bucket_name
  access_log_bucket_prefix           = var.access_log_bucket_prefix
  s3_object_ownership                = var.s3_object_ownership
  acl                                = var.acl

  context = module.this.context
}

resource "aws_flow_log" "default" {
  count                = module.this.enabled && var.flow_log_enabled ? 1 : 0
  log_destination      = module.s3_log_storage_bucket.bucket_arn
  log_destination_type = "s3"
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id
}
