terraform { required_version = ">= 1.4" }
resource "terraform_data" "alpha" { input = "2" }               # update
resource "terraform_data" "beta"  { triggers_replace = ["2"] }  # replace
resource "terraform_data" "delta" { input = "1" }               # create
# gamma removed                                                 # delete
