module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.19.2"
  enabled     = var.enabled
  namespace   = var.namespace
  name        = var.name
  stage       = var.stage
  environment = var.environment
  delimiter   = var.delimiter
  attributes  = var.attributes
  tags        = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  count = var.enabled ? 1 : 0

  statement {
    sid    = "Enable IAM User Permissions"
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
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = [
      "*"
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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

module "kms_key" {
  source      = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=tags/0.7.0"
  enabled     = var.enabled
  namespace   = var.namespace
  name        = var.name
  stage       = var.stage
  environment = var.environment
  delimiter   = var.delimiter
  attributes  = var.attributes
  tags        = var.tags

  description             = "KMS key for VPC flow logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = join("", data.aws_iam_policy_document.kms.*.json)
}

module "s3_bucket" {
  source      = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.14.0"
  enabled     = var.enabled
  namespace   = var.namespace
  name        = var.name
  stage       = var.stage
  environment = var.environment
  delimiter   = var.delimiter
  attributes  = var.attributes
  tags        = var.tags

  kms_master_key_arn = module.kms_key.alias_arn
  sse_algorithm      = "aws:kms"

  versioning_enabled = false

  expiration_days                    = var.expiration_days
  glacier_transition_days            = var.glacier_transition_days
  lifecycle_prefix                   = var.lifecycle_prefix
  lifecycle_rule_enabled             = var.lifecycle_rule_enabled
  lifecycle_tags                     = var.lifecycle_tags
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
  standard_transition_days           = var.standard_transition_days

  force_destroy = var.force_destroy
}

resource "aws_flow_log" "default" {
  count                = var.enabled ? 1 : 0
  log_destination      = module.s3_bucket.bucket_arn
  log_destination_type = "s3"
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id
}
