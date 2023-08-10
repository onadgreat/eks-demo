# EFS CSI Driver Policy
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/iam-policy-example.json
data "aws_iam_policy_document" "efs_csi" {
  count = var.create_role && var.attach_efs_csi_policy ? 1 : 0

  statement {
    actions = [
      "ec2:DescribeAvailabilityZones",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
    ]

    resources = ["*"]
  }

  statement {
    actions   = ["elasticfilesystem:CreateAccessPoint"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    actions   = ["elasticfilesystem:TagResource"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    actions   = ["elasticfilesystem:DeleteAccessPoint"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}
# efs IAM policy
resource "aws_iam_policy" "efs_csi" {
  count = var.create_role && var.attach_efs_csi_policy ? 1 : 0

  name   = "efs-csi-policy"
  policy = data.aws_iam_policy_document.efs_csi[0].json
}

# IAM policy attachment
resource "aws_iam_role_policy_attachment" "efs_csi" {
  count = var.create_role && var.attach_efs_csi_policy ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.efs_csi[0].arn
}

# efs IAM role
resource "aws_iam_role" "this" {
  count              = var.create_role ? 1 : 0
  name               = "efs-csi"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_assume_role_policy[0].json
}

# efs assume role policy
data "aws_iam_policy_document" "efs_csi_assume_role_policy" {
  count = var.create_role ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}