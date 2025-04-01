# security group for bastion host
resource "aws_security_group" "bastion_security_group" {
    name = "${local.tag}-bastion-sg"
    vpc_id = aws_vpc.vpc.id

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_vpc_security_group_ingress_rule" "bastion_security_group_ingress" {
    security_group_id = aws_security_group.bastion_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = -1

    depends_on = [ aws_security_group.bastion_security_group ]
}

resource "aws_vpc_security_group_egress_rule" "bastion_security_group_egress" {
    security_group_id = aws_security_group.bastion_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = -1

    depends_on = [ aws_security_group.bastion_security_group ]
}

# ec2 instance
data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
    filter {
        name   = "name"
        values = ["al2023-ami-2023*"]
    }
    filter {
        name   = "root-device-type"
        values = ["ebs"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "tls_private_key" "bastion_host_private_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "bastion_host_key_pair" {
    key_name = "${local.tag}-bastion-host-key-pair"
    public_key = tls_private_key.bastion_host_private_key.public_key_openssh

    depends_on = [ tls_private_key.bastion_host_private_key ]
}

resource "local_file" "bastion_host_key_download" {
    filename = var.bastion_host_pem_file
    content = tls_private_key.bastion_host_private_key.private_key_pem
    file_permission = "0400" # otherwise SSH is denied

    depends_on = [ tls_private_key.bastion_host_private_key ]
}

resource "aws_instance" "bastion_host" {
    ami = data.aws_ami.amazon_linux_2023.id
    instance_type = "t2.nano"

    vpc_security_group_ids = [ aws_security_group.bastion_host_sg.id ]
    subnet_id = aws_subnet.public_subnets[0].id
    associate_public_ip_address = true

    key_name = aws_key_pair.bastion_host_key_pair.key_name
    user_data = <<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y mariadb105

        cat <<- 'EOT' > /home/ec2-user/connect.sh
        #!/bin/bash
        mysql -h ${aws_rds_cluster.aurora_cluster.endpoint} -P 3306 -D ${var.aurora_db_name} -u ${var.aurora_master_username} -p
        EOT

        chmod +x /home/ec2-user/connect.sh
    EOF
    monitoring = false
    
    tags = {
        Name = "${local.tag}-bastion-host-ec2"
    }

    depends_on = [ 
        data.aws_ami.amazon_linux_2023, 
        aws_security_group.bastion_security_group, 
        aws_subnet.public_subnets,
        aws_key_pair.bastion_host_key_pair
    ]
}
