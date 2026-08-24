#creating a IAM role for EKS cluster

resource "aws_iam_role" "eks_cluster_master_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attaching the AmazonEKSClusterPolicy to the IAM role for eks master
resource "aws_iam_role_policy_attachment" "eks_cluster_master_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_master_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_master_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_master_role.name
}

resource "aws_iam_role" "eks_worker_node_role" {
  name = "eks-worker-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eks_autoscaler_policy" {
  name = "eks-autoscaler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "ec2:DescribeLaunchTemplateVersions",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_autoscaler_policy_attachment" {
  policy_arn = aws_iam_policy.eks_autoscaler_policy.arn
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_worker_node_role.name
}

resource "aws_iam_instance_profile" "eks_worker_node_instance_profile" {
  name = "eks-worker-node-instance-profile"
  role = aws_iam_role.eks_worker_node_role.name
  depends_on = [aws_iam_role.eks_worker_node_role]
 }

data "aws_vpc" "eks_vpc" {
  filter {
    name   = "tag:Name"
    values = ["myvpc"]
  }
}

data "aws_subnet" "eks_subnet1" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet1"]
  }
  vpc_id = data.aws_vpc.eks_vpc.id
}

data "aws_subnet" "eks_subnet2" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet2"]
  }
  vpc_id = data.aws_vpc.eks_vpc.id
}

data "aws_security_group" "eks_security_group" {
  filter {
    name   = "tag:Name"
    values = ["my-security-group"]
  }
  vpc_id = data.aws_vpc.eks_vpc.id
}

resource "aws_eks_cluster" "my_eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_master_role.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.eks_subnet1.id, data.aws_subnet.eks_subnet2.id]
    security_group_ids = [data.aws_security_group.eks_security_group.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_master_policy,
    aws_iam_role_policy_attachment.eks_cluster_service_policy,
    aws_iam_role_policy_attachment.eks_cluster_vpc_resource_controller
  ]
  tags = {
    Name = "my-eks-cluster"
  }
}

#create key pair for SSH access to the worker nodes
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = file(".ssh/id_rsa.pub") # Replace with the path to your public key
}


resource "aws_eks_node_group" "my_eks_node_group" {
  cluster_name    = aws_eks_cluster.my_eks_cluster.name
  node_group_name = "my-eks-node-group"
  node_role_arn   = aws_iam_role.eks_worker_node_role.arn
  subnet_ids      = [data.aws_subnet.eks_subnet1.id, data.aws_subnet.eks_subnet2.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = ["t3.micro"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_role_policy_attachment.eks_cni_policy_attachment,
    aws_iam_role_policy_attachment.eks_registry_policy_attachment,
    aws_iam_role_policy_attachment.eks_ssm_policy_attachment,
    aws_iam_role_policy_attachment.eks_service_policy_attachment,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller_policy_attachment
  ]

  #create a remote access block to allow SSH access to the worker nodes
    remote_access {
        ec2_ssh_key = aws_key_pair.my_key_pair.key_name
        source_security_group_ids = [data.aws_security_group.eks_security_group.id]
    }

  tags = {
    Name = "my-eks-node-group"
  }
}

