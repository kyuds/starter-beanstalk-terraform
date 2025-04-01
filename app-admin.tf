# elastic beanstalk application for phishing block admin
resource "aws_elastic_beanstalk_application" "eb_admin" {
    name = "${local.tag}-eb-admin"
    appversion_lifecycle {
        service_role = aws_iam_role.eb_service_role.arn
        max_count = 5
        delete_source_from_s3 = true
    }
}

# environment
resource "aws_elastic_beanstalk_environment" "eb_admin_env" {
    name = "${local.tag}-eb-admin-env"
    application = aws_elastic_beanstalk_application.eb_admin.name
    cname_prefix = "${local.tag}-admin"
    tier = "WebServer"
    solution_stack_name = "64bit Amazon Linux 2023 v4.4.4 running Corretto 17"

    setting {
        namespace = "aws:autoscaling:asg"
        name = "EnableCapacityRebalancing"
        value = "true"
    }
    setting {
        namespace = "aws:autoscaling:asg"
        name = "MinSize"
        value = "1"
    }
    setting {
        namespace = "aws:autoscaling:asg"
        name = "MaxSize"
        value = "2"
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "IamInstanceProfile"
        value = aws_iam_instance_profile.eb_instance_profile.arn
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "SecurityGroups"
        value = join(",", [aws_security_group.eb_security_group.id])
    }
    setting {
        namespace = "aws:ec2:instances"
        name = "InstanceTypes"
        value = "t3.micro,t3.small"
    }
    setting {
        namespace = "aws:ec2:instances"
        name = "SupportedArchitectures"
        value = "x86_64"
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "VPCId"
        value = aws_vpc.vpc.id
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "Subnets"
        value = join(",", aws_subnet.beanstalk_subnets[*].id)
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "ELBSubnets"
        value = join(",", aws_subnet.public_subnets[*].id)
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "AssociatePublicIpAddress"
        value = "false"
    }
    setting {
        namespace = "aws:elasticbeanstalk:cloudwatch:logs"
        name = "StreamLogs"
        value = "true"
    }
    setting {
        namespace = "aws:elasticbeanstalk:cloudwatch:logs"
        name = "DeleteOnTerminate"
        value = "true"
    }
    setting {
        namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
        name = "HealthStreamingEnabled"
        value = "true"
    }
    setting {
        namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
        name = "DeleteOnTerminate"
        value = "true"
    }
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name = "ServiceRole"
        value = aws_iam_role.eb_service_role.arn
    }
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name = "LoadBalancerType"
        value = "application"
    }
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name = "LoadBalancerIsShared"
        value = "true"
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
        name = "UpdateLevel"
        value = "minor"
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
        name = "UpdateLevel"
        value = "minor"
    }
    setting {
        namespace = "aws:elbv2:loadbalancer"
        name = "SharedLoadBalancer"
        value = aws_lb.alb.arn
    }
    setting {
        namespace = "aws:elbv2:loadbalancer"
        name = "SecurityGroups"
        value = aws_security_group.alb_security_group.id
    }
    # autoscaling
    setting {
        namespace = "aws:autoscaling:trigger"
        name = "MeasureName"
        value = "CPUUtilization"
    }
    setting {
        namespace = "aws:autoscaling:trigger"
        name = "Unit"
        value = "Percent"
    }
    setting {
        namespace = "aws:autoscaling:trigger"
        name = "LowerThreshold"
        value = "20"
    }
    setting {
        namespace = "aws:autoscaling:trigger"
        name = "UpperThreshold"
        value = "27"
    }

    depends_on = [ aws_elastic_beanstalk_application.eb_admin, aws_lb_listener_rule.force_http_redirect ]
}
