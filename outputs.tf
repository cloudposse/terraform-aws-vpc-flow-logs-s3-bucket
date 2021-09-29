output "kms_key_arn" {
  value       = module.kms_key.key_arn
  description = "KMS Key ARN"
}

output "kms_key_id" {
  value       = module.kms_key.key_id
  description = "KMS Key ID"
}

output "kms_alias_arn" {
  value       = module.kms_key.alias_arn
  description = "KMS Alias ARN"
}

output "kms_alias_name" {
  value       = module.kms_key.alias_name
  description = "KMS Alias name"
}

output "bucket_domain_name" {
  value       = module.s3_log_storage_bucket.bucket_domain_name
  description = "FQDN of bucket"
}

output "bucket_id" {
  value       = module.s3_log_storage_bucket.bucket_id
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = module.s3_log_storage_bucket.bucket_arn
  description = "Bucket ARN"
}

output "bucket_prefix" {
  value       = module.s3_log_storage_bucket.prefix
  description = "Bucket prefix configured for lifecycle rules"
}

output "flow_log_id" {
  value       = join("", aws_flow_log.default.*.id)
  description = "Flow Log ID"
}

output "flow_log_arn" {
  value       = join("", aws_flow_log.default.*.arn)
  description = "Flow Log ARN"
}

output "bucket_notifications_sqs_queue_arn" {
  value       = module.s3_log_storage_bucket.bucket_notifications_sqs_queue_arn
  description = "Notifications SQS queue ARN"
}
