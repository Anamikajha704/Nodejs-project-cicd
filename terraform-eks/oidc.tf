# Establishing the cryptographic trust between AWS and GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [] # AWS ignores thumbprints now; it handles them automatically
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    triggered_by = [
      aws_iam_openid_connect_provider.github
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:Anamikajha704/Nodejs-project-cicd:*"] 
    }
  }
}

# Create the deployment IAM Role
resource "aws_iam_role" "github_actions_role" {
  name               = "${var.cluster_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Attach permissions needed to push images to ECR and interact with EKS
resource "aws_iam_role_policy_attachment" "power_user" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

output "github_actions_role_arn" {
  description = "Paste this ARN value into your GitHub Actions workflow configuration"
  value       = aws_iam_role.github_actions_role.arn
}
