# VARIABLES
variable "env" {
  description = "AWS Environment"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Resource name"
  type        = string
  default     = "devops-challenge"
}

variable "domain_name" {
  default = "gbanchs.com"
}

variable "vpc_cidr" {
  default = "172.0.0.0/24"
}

variable "tags" {
  default = {
    Environment = "production"
    Provisioner = "Terraform"
    Application = "devops-challenge"
  }
}

variable "additional_sg" {
  type    = string
  default = ""
}

variable "AWS_ROLE_TO_ASSUME" {
  sensitive = true
  type      = string
}

variable "AWS_ROLE_EXTERNAL_ID" {
  sensitive = true
  type      = string
}

variable "private_subnets" {
  type    = list(any)
  default = ["172.0.1.0/24", "172.0.2.0/24", "172.0.3.0/24"]
}

variable "public_subnets" {
  type    = list(any)
  default = ["172.0.4.0/24", "172.0.5.0/24", "172.0.6.0/24"]
}
