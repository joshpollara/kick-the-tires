# Healthy dirspace for the all-or-nothing apply repro (mono#1541).
module "good-b" {
  source = "../../modules"

  null_resource_count = 1
}
