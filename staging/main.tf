module "dev" {
  source = "../modules"

  null_resource_count = 0
}

# #1540 fixture: an apply that succeeds at plan and fails at apply, so the
# comment has one failing dirspace alongside dev's large succeeding one.
# The sentinel string is what we look for in the PR comment -- if compaction
# drops this step's output, the fix is not working.
resource "null_resource" "apply_fail" {
  provisioner "local-exec" {
    command = "echo 'KICK_THE_TIRES_1540_SENTINEL: this is the failure a user must see' >&2; exit 1"
  }
}
