module "logging" {
  source = "../modules"

  # Invalid: var.retention_days is never declared, this fails during plan
  null_resource_count = var.retention_days
}
