# Version constraint here is the point of this test: tenv resolves version
# files before TG_DEFAULT_VERSION, so this forces tenv to list versions.
terragrunt_version_constraint = ">= 0.67.0"

terraform {
  source = "../modules"
}

inputs = {
  null_resource_count = 1
}
