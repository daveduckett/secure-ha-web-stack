# EC2 IAM Role and associated policies
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "ec2_iam_identity"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name      =   "ec2_instance_profile"
  role   =   aws_iam_role.ec2_role.name
}

data "aws_iam_policy" "ssm_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "attach_ssm_policy_to_ec2" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy" "ec2_secrets_policy" {
  name = "ec2_secrets_policy"
  role = aws_iam_role.ec2_role.id
    
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.secrets_vault.arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_access_policy" {
  name = "ec2_s3_access_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
      }
    ]
  })
}

