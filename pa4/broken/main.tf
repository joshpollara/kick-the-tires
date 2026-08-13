resource "null_resource" "broken" {
  count = var.undeclared_count
}
