variable "vpc_id" {
  type        = string
}

variable "public_subnets" {
  type        = list(string)
}

variable "public_subnets_cidrs" {
    type        = list(string)
}
variable "private_subnets_cidrs" {
    type        = list(string)
}

variable "private_subnets" {
  type        = list(string)
}

variable "proxy_instance_ids" {
  type        = list(string)
}

variable "backend_instance_ids" {
  type        = list(string)
}

variable "internal_alb_sg_id" {
  type        = string
}

variable "public_alb_sg_id" {
  type        = string
}