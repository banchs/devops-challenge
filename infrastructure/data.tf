data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.eks.cluster_id
}