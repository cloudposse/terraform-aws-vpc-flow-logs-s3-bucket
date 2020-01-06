## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | string | `` | no |
| expiration_days | Number of days after which to expunge the objects | number | `90` | no |
| force_destroy | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable | bool | `false` | no |
| glacier_transition_days | Number of days after which to move the data to the glacier storage tier | number | `60` | no |
| lifecycle_prefix | Prefix filter. Used to manage object lifecycle events | string | `` | no |
| lifecycle_rule_enabled | Enable lifecycle events on this bucket | bool | `true` | no |
| lifecycle_tags | Tags filter. Used to manage object lifecycle events | map(string) | `<map>` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | string | `` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | string | `` | no |
| noncurrent_version_expiration_days | Specifies when noncurrent object versions expire | number | `90` | no |
| noncurrent_version_transition_days | Specifies when noncurrent object versions transitions | number | `30` | no |
| region | If specified, the AWS region this bucket should reside in. Otherwise, the region used by the callee | string | `` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | string | `` | no |
| standard_transition_days | Number of days to persist in the standard storage tier before moving to the infrequent access tier | number | `30` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | map(string) | `<map>` | no |
| traffic_type | The type of traffic to capture. Valid values: `ACCEPT`, `REJECT`, `ALL` | string | `ALL` | no |
| vpc_id | VPC ID the DB instance will be created in | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket_arn | Bucket ARN |
| bucket_domain_name | FQDN of bucket |
| bucket_id | Bucket Name (aka ID) |
| bucket_prefix | Bucket prefix configured for lifecycle rules |
| id | The Flow Log ID |
| kms_alias_arn | KMS Alias ARN |
| kms_alias_name | KMS Alias name |
| kms_key_arn | KMS Key ARN |
| kms_key_id | KMS Key ID |

