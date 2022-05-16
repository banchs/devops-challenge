module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "3.14.0"
  create_vpc      = true
  name            = "vpc-devops-challenge-${var.env}"
  cidr            = var.vpc_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "Name"                   = "public-subnet-devops-challenge-${var.env}",
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "Name"                            = "private-subnet-devops-challenge-${var.env}",
    "kubernetes.io/role/internal-elb" = "1"
  }
}



resource "aws_security_group_rule" "alb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = module.eks.eks.node_security_group_id
}


module "eks" {
  source          = "github.com/banchs/tf-mod-eks?ref=1.0.1"
  env             = var.env
  cluster_name    = "demo-${var.env}"
  cluster_version = var.cluster_version
  additional_sg   = aws_security_group.nodes.id
  vpc_config = {
    vpc_id          = module.vpc.vpc_id
    vpc_subnets_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  }

  eks_managed_node_groups = {
    main = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.small", "t3.medium"]
      capacity_type  = "SPOT"
      subnet_ids     = module.vpc.private_subnets
    }
  }

  load_balancer_controller = {
    enabled = true
    version = "1.4.1"
  }

}

locals {
  ecr_registry_name = [
  "demo-timeoff-${var.env}"]
}

resource "aws_ecr_repository" "microservices" {
  for_each             = toset(local.ecr_registry_name)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_security_group" "web" {
  name        = "web-${var.name}-${var.env}"
  description = "Allow Web inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Web from Internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "web-${var.name}-${var.env}",
    Environment = var.env
  }
}

resource "kubernetes_ingress_v1" "nodesource_ingress" {
  depends_on = [
    module.eks
  ]
  metadata {
    name      = "ingress-demo-devops-${var.env}"
    namespace = "default"
    annotations = {
      #"alb.ingress.kubernetes.io/healthcheck-path"     = "/login"
      "alb.ingress.kubernetes.io/load-balancer-name"   = "ingress-demo-devops-${var.env}"
      "alb.ingress.kubernetes.io/name"                 = "ingress-demo-devops-${var.env}"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "instance"
      "alb.ingress.kubernetes.io/certificate-arn"      = module.acm.arn
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\":\"redirect\",\"RedirectConfig\": {\"Protocol\":\"HTTPS\",\"Port\":443,\"StatusCode\":\"HTTP_301\"}}"
      "alb.ingress.kubernetes.io/ssl-redirect"         = "443"
      "alb.ingress.kubernetes.io/security-groups"      = aws_security_group.web.id
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {

        path {
          backend {
            service {
              name = "timeoff-managment"
              port {
                number = 80
              }

            }
          }
          path      = "/"
          path_type = "Prefix"
        }

      }
    }
  }
}
data "aws_lb" "ingress" {
  depends_on = [
    kubernetes_ingress_v1.nodesource_ingress
  ]
  tags = {
    "ingress.k8s.aws/stack" = "default/ingress-demo-devops-${var.env}"
    "elbv2.k8s.aws/cluster" = "demo-${var.env}"
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.env}-${var.name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_lb.ingress.dns_name}"
    zone_id                = data.aws_lb.ingress.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "nodes" {
  name        = "nodes-${var.name}-${var.env}"
  description = "Allow Nodes inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Nodes from VPC"
    from_port       = 0
    to_port         = 0
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "nodes-${var.name}-${var.env}",
    Environment = var.env
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-${var.name}-${var.env}"
  description = "Allow RDS inbound access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "RDS from Nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "rds-${var.name}-${var.env}",
    Environment = var.env
  }
}

module "rds" {
  source               = "github.com/banchs/tf-mod-db//rds?ref=1.0.1"
  name                 = var.name
  env                  = var.env
  tags                 = var.tags
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  private_subnets_cidr = module.vpc.vpc_cidr_block
  kms_key_id           = module.kms.kms_arn
  security_groups_id   = aws_security_group.rds.id
  region               = var.region
}

module "kms" {
  source = "github.com/banchs/tf-mod-kms?ref=1.0.0"
  name   = var.name
  env    = var.env
  tags   = var.tags
}

module "acm" {
  source  = "github.com/banchs/tf-mod-acm?ref=1.0.0"
  name    = var.name
  env     = var.env
  tags    = var.tags
  zone_id = data.aws_route53_zone.selected.zone_id
}
