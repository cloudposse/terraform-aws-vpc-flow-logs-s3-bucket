module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

module "kms_key" {
  source     = "git::https://github.com/cloudposse/terraform-aws-kms-key.git?ref=tags/0.1.2"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"

  description             = "KMS key for VPC flow logs"
  deletion_window_in_days = 10
  enable_key_rotation     = "true"
  alias                   = "alias/vpc_flow_logs"
}

module "s3_bucket" {
  source     = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.4.0"
  enabled    = "${var.enabled}"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.stage}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"

  kms_master_key_id = "${module.kms_key.key_id}"
  sse_algorithm     = "aws:kms"

  versioning_enabled = "false"

  region = "${var.region}"

  expiration_days                    = "${var.expiration_days}"
  glacier_transition_days            = "${var.glacier_transition_days}"
  lifecycle_prefix                   = "${var.lifecycle_prefix}"
  lifecycle_rule_enabled             = "${var.lifecycle_rule_enabled}"
  lifecycle_tags                     = "${var.lifecycle_tags}"
  noncurrent_version_expiration_days = "${var.noncurrent_version_expiration_days}"
  noncurrent_version_transition_days = "${var.noncurrent_version_transition_days}"
  standard_transition_days           = "${var.standard_transition_days}"
  #policy                             = "${module.policy.result_document}"

  force_destroy = "${var.force_destroy}"
}

//module "policy" {
//  source           = "git::https://github.com/cloudposse/terraform-aws-iam-policy-document-aggregator.git?ref=tags/0.1.2"
//  source_documents = ["${var.policy}", "${data.aws_iam_policy_document.assume_role.json}"]
//}
//
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = "AWSLogDeliveryAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    resources = ["${module.s3_bucket.bucket_arn}"]

    principals {
      type = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid = "AWSLogDeliveryWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = ["${module.s3_bucket.bucket_arn}/*"]

    condition {
      test = "StringEquals"
      values = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }

    principals {
      type = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = "${module.s3_bucket.bucket_arn}"
  policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_flow_log" "default" {
  log_destination      = "${module.s3_bucket.bucket_arn}"
  log_destination_type = "s3"
  traffic_type         = "${var.traffic_type}"
  vpc_id               = "${var.vpc_id}"
}
