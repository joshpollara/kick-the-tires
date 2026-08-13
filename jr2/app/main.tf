# Starts with no changes (count = 0).
module "app" {
  source = "../../modules"

  null_resource_count = 0
}
