

variable "vpc_id" {
  type        = string
}

variable "public_subnets" {
  type        = list(string)
}

variable "private_subnets" {
  type        = list(string)
}
variable "internal_alb_dns" {
  type        = string
}

variable "key_pair_name" {
  type        = string
}

variable "private_key_path" {
  type        = string
}

variable "ingress_cidrs" {
  type        = list(string)
}

variable "internal_alb_sg_id" {
  type        = string
}

variable "public_alb_sg_id" {
  type        = string
}