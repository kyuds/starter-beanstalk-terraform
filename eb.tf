# elastic beanstalk service role
resource "aws_iam_role" "eb_service_role" {
    name = "${local.tag}-eb-service-role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Principal = {
                Service = "elasticbeanstalk.amazonaws.com"
            }
            Effect = "Allow"
            Sid    = ""
        },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_service_role_attachment" {
    for_each = toset([
        "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth",
        "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
    ])
    role       = aws_iam_role.eb_service_role.name
    policy_arn = each.value
}

# instance profile
resource "aws_iam_role" "eb_instance_role" {
    name = "${local.tag}-eb-instance-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Effect = "Allow"
                Sid    = ""
            },
        ]
    })

    max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "eb_instance_role_attachment" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
        "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
        "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ])
    role       = aws_iam_role.eb_instance_role.name
    policy_arn = each.value
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
    name = "${local.tag}-eb-instance-profile"
    role = aws_iam_role.eb_instance_role.name
}

# security group for eb instances (to connect to aurora)
resource "aws_security_group" "eb_security_group" {
    name = "${local.tag}-eb-sg"
    vpc_id = aws_vpc.vpc.id

    depends_on = [ aws_vpc.vpc ]
}
