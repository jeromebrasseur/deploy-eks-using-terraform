module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "infoline-vpc"
  cidr = var.vpc_cidr

  azs = data.aws_availability_zones.azs.names

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "kubernetes.io/cluster/infoline-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/infoline-eks-cluster" = "shared"
    "kubernetes.io/role/elb"               = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/infoline-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"      = 1
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.0"

  cluster_name    = "infoline-eks-cluster"
  cluster_version = "1.32"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_type = ["t3.medium"]
    }
  }

  map_users = {
    {
      userarn  = "arn:aws:iam::455768854429:user/admin-devops"
      username = "admin-devops"
      groups   = "system:masters"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
