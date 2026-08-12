# Unplannable dirspace for proving the mono#1541 fix.
resource "null_resource" "broken" {
  count = var.undeclared_count
}
