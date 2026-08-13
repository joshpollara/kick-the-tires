# Real change: creates one resource.
module "app" {
  source = "../../modules"

  null_resource_count = 1
}
