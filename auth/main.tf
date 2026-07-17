module "auth" {
  source = "../modules"

  # Invalid: variable expects a number, this fails during plan
  null_resource_count = "not-a-number"
}
