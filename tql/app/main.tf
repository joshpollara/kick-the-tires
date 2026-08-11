# Layered run fixture for tag query testing (#1661).
module "app" {
  source = "../../modules"

  null_resource_count = 1
}
