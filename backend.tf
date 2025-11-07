terraform {
  backend "s3" {
    bucket         = "tf-pj-mi24"
    key            = "vpc-project/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}