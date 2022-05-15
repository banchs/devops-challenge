provider "aws" {
  region = var.region
  assume_role {
    session_name = "terraform-demo-${var.env}"
    role_arn     = var.AWS_ROLE_TO_ASSUME
    external_id  = var.AWS_ROLE_EXTERNAL_ID
  }
  skip_credentials_validation = true
  skip_metadata_api_check     = true
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.12.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
  required_version = "~> 1.1.9"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
