resource "terraform_data" "vpc" {
  input = {
    vpc_id             = "vpc-0a1b2c3d4e5f6789"
    cidr_block         = "10.0.0.0/16"
    public_subnet_ids  = ["subnet-pub-a", "subnet-pub-b"]
    private_subnet_ids = ["subnet-prv-a", "subnet-prv-b", "subnet-prv-c"]
  }
}

output "vpc_id" {
  value = terraform_data.vpc.output.vpc_id
}

output "vpc_cidr_block" {
  value = terraform_data.vpc.output.cidr_block
}

output "public_subnet_ids" {
  value = terraform_data.vpc.output.public_subnet_ids
}

output "private_subnet_ids" {
  value = terraform_data.vpc.output.private_subnet_ids
}

# stategraph/mono#1540 fixture: plans clean, fails at apply. This runs through
# the STATEGRAPH engine (tag_query dir:sg), which is what makes it the real
# reproduction -- the bundler's synthetic module.state_<hash> wrappers only
# exist on this path.
resource "null_resource" "apply_fail" {
  provisioner "local-exec" {
    command = "echo 'KICK_THE_TIRES_1540_SENTINEL: this is the failure a user must see' >&2; exit 1"
  }
}
