module "nginx" {
  source               = "./module"
  region               = var.region
  vpc_name             = local.vpc_name
  environment          = var.project.environment
  key_name             = var.key_name
  service_name         = var.service_name
}

locals {
  vpc_name = "${var.project.environment}-vpc"
}