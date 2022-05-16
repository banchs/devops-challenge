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
  default = "10.0.0.0/16"
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
  default = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

variable "public_subnets" {
  type    = list(any)
  default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "cluster_version" {
  type    = number
  default = 1.22
}


