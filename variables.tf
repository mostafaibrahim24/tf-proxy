variable "aws_region" {
  description = "The AWS region to deploy resources into."
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "The name of the pre-existing EC2 Key Pair."
  type        = string
  default     = "tf-proj"
}

variable "private_key_path" {
  description = "Local path to the private key file for SSH connections (e.g., ~/.ssh/mykey.pem)."
  type        = string
  default     = "~/.ssh/tf-proj.pem"
}

variable "ingress_cidrs" {
  description = "List of CIDR blocks allowed to access SSH on proxy machines."
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}