module "dev" {
  source = "../modules"

  # Deliberately large for #1540: enough resources that dev's apply output is
  # long enough to push the comment past the size limit, which is what makes
  # compaction kick in at all.
  null_resource_count = 60
}
