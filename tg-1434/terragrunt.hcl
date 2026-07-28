# Version constraint here is the point of this test: tenv resolves version
# files before TG_DEFAULT_VERSION, so this forces tenv to list versions.
terragrunt_version_constraint = ">= 0.67.0"

# No upper bound on purpose: tenv resolves this constraint to the latest
# terraform release, ignoring the workflow tf_version (which only sets
# TFENV_TERRAFORM_DEFAULT_VERSION, a lower-precedence fallback).
terraform_version_constraint = ">= 1.0"

terraform {
  source = "../modules"
}

inputs = {
  null_resource_count = 1
}
