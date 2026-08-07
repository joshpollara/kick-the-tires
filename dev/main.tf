module "dev" {
  source = "../modules"

  null_resource_count = 5
}

# #1540 fixture: compaction only engages once the rendered comment exceeds the
# size limit, and a plan of a few null_resources is nowhere near it. This emits
# a large blob at APPLY time (local-exec output does not appear at plan), which
# is what pushes the apply comment over the limit and makes compaction run.
resource "null_resource" "bulk_output" {
  provisioner "local-exec" {
    command = "for i in $(seq 1 3000); do echo \"dev bulk filler line $i ------------------------------------------\"; done"
  }
}
