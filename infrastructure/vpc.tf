data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name             = var.name
  cidr             = "172.31.0.0/16"
  azs              = data.aws_availability_zones.available.names
  private_subnets  = ["172.31.1.0/24", "172.31.2.0/24", "172.31.3.0/24"]
  public_subnets   = ["172.31.4.0/24", "172.31.5.0/24", "172.31.6.0/24"]
  database_subnets = ["172.31.7.0/24", "172.31.8.0/24", "172.31.9.0/24"]

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}
