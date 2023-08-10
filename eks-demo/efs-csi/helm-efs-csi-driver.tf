
module "eks-efs-csi-driver" {
  source  = "lablabs/eks-efs-csi-driver/aws"
  version = "0.1.2"

  cluster_identity_oidc_issuer = aws_eks_cluster.demo.identity[0].oidc[0].issuer
  cluster_identity_oidc_issuer_arn = aws_iam_openid_connect_provider.eks.arn

  depends_on = [aws_eks_cluster.demo]
}


# EFS file system
locals {
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
}

resource "aws_security_group" "allow_nfs" {
  name        = "allow nfs for efs"
  description = "Allow NFS inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.demo.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EKS Cluster security group
resource "aws_security_group" "eks_cluster" {
  name   = "ControlPlaneSecurityGroup"
  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ControlPlaneSecurityGroup"
  }
}

# EKS security group rule
resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow unmanaged nodes to communicate with control plane (all ports)"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_eks_cluster.demo.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.allow_nfs.id
  type                     = "ingress"
}

#efs file system
resource "aws_efs_file_system" "stw_node_efs" {
  creation_token = "efs-for-stw-node"
}

#efs mount targets
resource "aws_efs_mount_target" "stw_node_efs_mt_0" {
  file_system_id  = aws_efs_file_system.stw_node_efs.id
  subnet_id       = data.terraform_remote_state.network.outputs.private[0]
  security_groups = [aws_security_group.allow_nfs.id]
}

resource "aws_efs_mount_target" "stw_node_efs_mt_1" {
  file_system_id  = aws_efs_file_system.stw_node_efs.id
  subnet_id       = data.terraform_remote_state.network.outputs.private[1]
  security_groups = [aws_security_group.allow_nfs.id]
}
