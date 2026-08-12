# Healthy dirspace for proving the mono#1541 fix.
module "good-a" {
  source = "../../modules"

  null_resource_count = 1
}
