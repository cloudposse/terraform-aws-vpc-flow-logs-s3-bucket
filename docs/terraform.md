## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| acl | The canned ACL to apply. We recommend `private` for compatibility with AWS services | string | `private` | no |
| attributes | Additional attributes (e.g. `1`) | list | `<list>` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage` and `attributes` | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | string | `true` | no |
| expiration_days | Number of days after which to expunge the objects | string | `90` | no |
| force_destroy | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | string | `false` | no |
| glacier_transition_days | Number of days after which to move the data to the glacier storage tier | string | `60` | no |
| lifecycle_prefix | Prefix filter. Used to manage object lifecycle events. | string | `` | no |
| lifecycle_rule_enabled | Enable lifecycle events on this bucket | string | `true` | no |
| lifecycle_tags | Tags filter. Used to manage object lifecycle events. | map | `<map>` | no |
| name | The Name of the application or solution  (e.g. `bastion` or `portal`) | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | - | yes |
| noncurrent_version_expiration_days | Specifies when noncurrent object versions expire. | string | `90` | no |
| noncurrent_version_transition_days | Specifies when noncurrent object versions transitions | string | `30` | no |
| policy | A valid bucket policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. | string | `` | no |
| region | If specified, the AWS region this bucket should reside in. Otherwise, the region used by the callee. | string | `` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| standard_transition_days | Number of days to persist in the standard storage tier before moving to the infrequent access tier | string | `30` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map | `<map>` | no |
| traffic_type | The type of traffic to capture. Valid values: `ACCEPT`, `REJECT`, `ALL` | string | `ALL` | no |
| versioning_enabled | A state of versioning. Versioning is a means of keeping multiple variants of an object in the same bucket. | string | `false` | no |
| vpc_id | VPC ID the DB instance will be created in | string | - | yes |

