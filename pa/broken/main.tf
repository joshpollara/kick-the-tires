# Unplannable dirspace for the all-or-nothing apply repro (mono#1541).
# References an undeclared variable, so every plan fails at validation,
# mirroring a module materialized without its declarations.
resource "null_resource" "broken" {
  count = var.undeclared_count

  provisioner "local-exec" {
    command = "echo never planned"
  }
}
