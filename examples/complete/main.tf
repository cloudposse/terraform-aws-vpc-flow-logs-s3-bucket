provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.18.0"

  cidr_block = "172.16.0.0/16"

  context = module.this.context
}

module "flow_logs" {
  source = "../../"

  flow_log_enabled                   = var.flow_log_enabled
  lifecycle_prefix                   = var.lifecycle_prefix
  lifecycle_rule_enabled             = var.lifecycle_rule_enabled
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
  standard_transition_days           = var.standard_transition_days
  glacier_transition_days            = var.glacier_transition_days
  expiration_days                    = var.expiration_days
  traffic_type                       = var.traffic_type
  allow_ssl_requests_only            = var.allow_ssl_requests_only
  vpc_id                             = module.vpc.vpc_id
  kms_key_arn                        = var.kms_key_arn

  # For testing
  force_destroy = true

  context = module.this.context
}
