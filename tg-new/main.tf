terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
  }
}

resource "null_resource" "fixture" {
  triggers = {
    fixture = "terragrunt-1.1.1"
  }
}
