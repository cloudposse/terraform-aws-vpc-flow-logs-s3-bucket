provider "aws" {
  region = var.region
}

module "vpc" {
  // https://github.com/cloudposse/terraform-aws-vpc
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=0.17.0"
  enabled    = module.this.enabled
  namespace  = module.this.namespace
  stage      = module.this.stage
  name       = module.this.name
  cidr_block = "172.16.0.0/16"
}

module "flow_logs" {
  source = "../../"

  context = module.this.context
  region = var.region
  vpc_id = module.vpc.vpc_id

  // For testing
  force_destroy = true
}