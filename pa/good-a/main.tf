# Healthy dirspace for the all-or-nothing apply repro (mono#1541).
module "good-a" {
  source = "../../modules"

  null_resource_count = 1
}
