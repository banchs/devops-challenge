output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
