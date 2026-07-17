locals {
  # Vary the plan per workspace so each region's output differs
  counts = {
    us-east-1 = 3
    us-west-2 = 1
    eu-west-1 = 0
    ap-south-1 = 2
    sa-east-1 = 0
  }
}

module "payments" {
  source = "../modules"

  null_resource_count = lookup(local.counts, terraform.workspace, 1)
}
