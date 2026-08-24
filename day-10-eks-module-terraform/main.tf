terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = local.region
}

# ============================================================
# Local Variables
# ============================================================

locals {
  name   = "nareshit-cluster"
  region = "us-east-1"

  vpc_cidr = "10.123.0.0/16"

  azs = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnets = [
    "10.123.1.0/24",
    "10.123.2.0/24"
  ]

  private_subnets = [
    "10.123.3.0/24",
    "10.123.4.0/24"
  ]

  intra_subnets = [
    "10.123.5.0/24",
    "10.123.6.0/24"
  ]

  tags = {
    Example = local.name
  }
}

# ============================================================
# VPC
# ============================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs = local.azs

  public_subnets = local.public_subnets

  private_subnets = local.private_subnets

  intra_subnets = local.intra_subnets

  # NAT Gateway for private subnet internet access
  enable_nat_gateway = true

  # ----------------------------------------------------------
  # Public subnet tags
  # Used for internet-facing AWS Load Balancers
  # ----------------------------------------------------------

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # ----------------------------------------------------------
  # Private subnet tags
  # Used for internal AWS Load Balancers
  # ----------------------------------------------------------

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

# ============================================================
# EKS Cluster
# ============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  # ----------------------------------------------------------
  # Cluster Configuration
  # ----------------------------------------------------------

  name = local.name

  kubernetes_version = "1.33"

  # Allow kubectl/API access from the internet.
  # You can restrict this later using:
  # endpoint_public_access_cidrs
  # ----------------------------------------------------------

  endpoint_public_access = true

  # Automatically give the Terraform cluster creator
  # administrator access to the cluster.
  # ----------------------------------------------------------

  enable_cluster_creator_admin_permissions = true

  # ----------------------------------------------------------
  # Networking
  # ----------------------------------------------------------

  vpc_id = module.vpc.vpc_id

  # EKS worker nodes will be launched in private subnets.
  subnet_ids = module.vpc.private_subnets

  # EKS control-plane ENIs will use intra subnets.
  control_plane_subnet_ids = module.vpc.intra_subnets

  # ==========================================================
  # EKS Managed Add-ons
  # ==========================================================

  addons = {

    # --------------------------------------------------------
    # VPC CNI
    #
    # IMPORTANT:
    # before_compute = true ensures the CNI addon is created
    # before the managed node group.
    # --------------------------------------------------------

    vpc-cni = {
      most_recent    = true
      before_compute = true
    }

    # --------------------------------------------------------
    # EKS Pod Identity Agent
    #
    # Install before worker nodes are created.
    # --------------------------------------------------------

    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }

    # --------------------------------------------------------
    # kube-proxy
    # --------------------------------------------------------

    kube-proxy = {
      most_recent = true
    }

    # --------------------------------------------------------
    # CoreDNS
    # --------------------------------------------------------

    coredns = {
      most_recent = true
    }
  }

  # ==========================================================
  # EKS Managed Node Groups
  # ==========================================================

  eks_managed_node_groups = {

    ascode-cluster-wg = {

      # ------------------------------------------------------
      # Scaling
      # ------------------------------------------------------

      min_size = 2

      max_size = 3

      desired_size = 2

      # ------------------------------------------------------
      # Instance configuration
      # ------------------------------------------------------

      instance_types = [
        "t3.medium"
      ]

      capacity_type = "ON_DEMAND"

      # Explicitly use Amazon Linux 2023.
      #
      # EKS 1.33 supports AL2023.
      # ------------------------------------------------------

      ami_type = "AL2023_x86_64_STANDARD"

      # ------------------------------------------------------
      # Rolling update configuration
      # ------------------------------------------------------

      max_unavailable = 1

      # ------------------------------------------------------
      # Node tags
      # ------------------------------------------------------

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  # ==========================================================
  # Common EKS Tags
  # ==========================================================

  tags = local.tags
}