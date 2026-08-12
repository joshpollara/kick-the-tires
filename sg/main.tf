resource "terraform_data" "vpc" {
  input = {
    vpc_id             = "vpc-0a1b2c3d4e5f6789"
    cidr_block         = "10.0.0.0/16"
    environment        = "stacks-demo"
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
