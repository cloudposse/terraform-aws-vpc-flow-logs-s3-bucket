## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0, < 0.14.0 |
| aws | ~> 2.0 |
| local | ~> 1.3 |
| template | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | `string` | `"-"` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | `""` | no |
| expiration\_days | Number of days after which to expunge the objects | `number` | `90` | no |
| force\_destroy | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable | `bool` | `false` | no |
| glacier\_transition\_days | Number of days after which to move the data to the glacier storage tier | `number` | `60` | no |
| lifecycle\_prefix | Prefix filter. Used to manage object lifecycle events | `string` | `""` | no |
| lifecycle\_rule\_enabled | Enable lifecycle events on this bucket | `bool` | `true` | no |
| lifecycle\_tags | Tags filter. Used to manage object lifecycle events | `map(string)` | `{}` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `""` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `""` | no |
| noncurrent\_version\_expiration\_days | Specifies when noncurrent object versions expire | `number` | `90` | no |
| noncurrent\_version\_transition\_days | Specifies when noncurrent object versions transitions | `number` | `30` | no |
| region | If specified, the AWS region this bucket should reside in. Otherwise, the region used by the callee | `string` | `""` | no |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `""` | no |
| standard\_transition\_days | Number of days to persist in the standard storage tier before moving to the infrequent access tier | `number` | `30` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| traffic\_type | The type of traffic to capture. Valid values: `ACCEPT`, `REJECT`, `ALL` | `string` | `"ALL"` | no |
| vpc\_id | VPC ID to create flow logs for | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_arn | Bucket ARN |
| bucket\_domain\_name | FQDN of bucket |
| bucket\_id | Bucket Name (aka ID) |
| bucket\_prefix | Bucket prefix configured for lifecycle rules |
| id | The Flow Log ID |
| kms\_alias\_arn | KMS Alias ARN |
| kms\_alias\_name | KMS Alias name |
| kms\_key\_arn | KMS Key ARN |
| kms\_key\_id | KMS Key ID |

