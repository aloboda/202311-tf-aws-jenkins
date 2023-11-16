terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region  = "us-east-1"
    profile = "default"
    key     = "2311cgterraformstatefile"
    bucket  = "andriicg202311terraform"
  }
}