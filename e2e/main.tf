terraform { required_version = ">= 1.4" }

resource "terraform_data" "alpha" { input = "1" }
resource "terraform_data" "beta"  { triggers_replace = ["1"] }
resource "terraform_data" "gamma" { input = "1" }
