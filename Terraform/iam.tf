resource "aws_iam_policy" "alb_policy" {
  name   = "alb-policy"
  policy = file("${path.module}/../AWS/aws-load-balancer-controller-policy.json")
}

resource "aws_iam_role" "kubeadm_role" {
  name = "kubeadm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.kubeadm_role.name
  policy_arn = aws_iam_policy.alb_policy.arn
}

resource "aws_iam_instance_profile" "kubeadm_profile" {
  name = "kubeadm-profile"
  role = aws_iam_role.kubeadm_role.name
}