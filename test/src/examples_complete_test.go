package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"math/rand"
	"strconv"
	"testing"
	"time"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	rand.Seed(time.Now().UnixNano())

	randId := strconv.Itoa(rand.Intn(100000))
	attributes := []string{randId}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
			"region": "us-east-2",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApplyAndIdempotent(t, terraformOptions)

	terraform.OutputAll(t, terraformOptions)

	varNamespace := terraformOptions.Vars["namespace"]
	varStage := terraformOptions.Vars["stage"]
	varName := terraformOptions.Vars["name"]
	// Assume '-' delimiter

	bucketArn := terraform.Output(t, terraformOptions, "bucket_arn")
	expectedBucketArn := fmt.Sprintf("arn:aws:s3:::%s-%s-%s", varNamespace, varStage, varName)

	assert.Equal(t, bucketArn, expectedBucketArn)
	assert.Empty(t, terraform.Output(t, terraformOptions, "bucket_prefix"))
}
