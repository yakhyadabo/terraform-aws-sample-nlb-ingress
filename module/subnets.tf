# VPC of the subnets
data "aws_vpc" "main" {
  tags = {
    Name = var.vpc_name
    Environment = var.environment
  }
}

# NLB Subnets
# Subnets of the EC2 instances
data "aws_subnets" "public" {
  filter {
    name   = local.vpc_id
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = local.tier.public
  }
}

# EC2 instances Subnets
data "aws_subnets" "private" {
  filter {
    name   = local.vpc_id
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = local.tier.private
  }
}
