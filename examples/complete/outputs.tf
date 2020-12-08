output "kms_key_arn" {
  value       = module.flow_logs.kms_key_arn
  description = "KMS Key ARN"
}

output "kms_key_id" {
  value       = module.flow_logs.kms_key_id
  description = "KMS Key ID"
}

output "kms_alias_arn" {
  value       = module.flow_logs.kms_alias_arn
  description = "KMS Alias ARN"
}

output "kms_alias_name" {
  value       = module.flow_logs.kms_alias_name
  description = "KMS Alias name"
}

output "bucket_domain_name" {
  value       = module.flow_logs.bucket_domain_name
  description = "FQDN of bucket"
}

output "bucket_id" {
  value       = module.flow_logs.bucket_id
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = module.flow_logs.bucket_arn
  description = "Bucket ARN"
}

output "bucket_prefix" {
  value       = module.flow_logs.bucket_prefix
  description = "Bucket prefix configured for lifecycle rules"
}

output "flow_log_id" {
  value       = module.flow_logs.flow_log_id
  description = "Flow Log ID"
}

output "flow_log_arn" {
  value       = module.flow_logs.flow_log_arn
  description = "Flow Log ARN"
}
