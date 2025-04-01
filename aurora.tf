# security group (used for bastion host)
resource "aws_security_group" "aurora_security_group" {
    name = "${local.tag}-aurora-sg"
    vpc_id = aws_vpc.vpc.id

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_vpc_security_group_ingress_rule" "aurora_ingress_bastion" {
    security_group_id = aws_security_group.aurora_security_group.id
    referenced_security_group_id = aws_security_group.bastion_security_group.id
    ip_protocol = "tcp"
    from_port = 3306
    to_port = 3306

    depends_on = [ aws_security_group.aurora_security_group, aws_security_group.bastion_security_group ]
}

resource "aws_vpc_security_group_ingress_rule" "aurora_sg_ingress_eb" {
    security_group_id = aws_security_group.aurora_security_group.id
    referenced_security_group_id = aws_security_group.eb_security_group.id
    ip_protocol = "tcp"
    from_port = 3306
    to_port = 3306

    depends_on = [ aws_security_group.aurora_security_group, aws_security_group.eb_sg ]
}

resource "aws_vpc_security_group_egress_rule" "aurora_egress" {
    security_group_id = aws_security_group.aurora_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = -1

    depends_on = [ aws_security_group.aurora_security_group ]
}

# db subnet group
resource "aws_db_subnet_group" "aurora_subnet_group" {
    name = "${local.tag}-db-subnet-group"
    subnet_ids = aws_subnet.aurora_subnets[*].id

    depends_on = [ aws_subnet.aurora_subnets ]
}

# aurora
resource "aws_rds_cluster" "aurora_cluster" {
    cluster_identifier = "${local.tag}-aurora-cluster"
    engine = "aurora-mysql"
    engine_version = "8.0.mysql_aurora.3.05.2"
    database_name = var.aurora_db_name
    master_username = var.aurora_master_username
    master_password = var.aurora_master_password
    network_type = "IPV4"
    db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
    storage_encrypted = true

    vpc_security_group_ids = [ aws_security_group.aurora_security_group.id ]

    deletion_protection = false # TODO: MUST BE TRUE FOR PRODUCTION
    skip_final_snapshot = true  # TODO: MUST BE TRUE FOR PRODUCTION

    depends_on = [ aws_db_subnet_group.aurora_subnet_group, aws_security_group.aurora_security_group ]
}

resource "aws_rds_cluster_instance" "aurora_instance" {
    count = var.aurora_instance_count
    identifier = "${local.tag}-aurora-instance${count.index + 1}"
    cluster_identifier = aws_rds_cluster.aurora_cluster.id
    instance_class = "db.t4g.medium"
    engine = aws_rds_cluster.aurora_cluster.engine
    engine_version = aws_rds_cluster.aurora_cluster.engine_version
    publicly_accessible = false # we are in a private subnet

    depends_on = [ aws_rds_cluster.aurora_cluster ]
}

# outputs
output "aurora_cluster_writer_endpoint" {
    value = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_cluster_reader_endpoint" {
    value = aws_rds_cluster.aurora_cluster.reader_endpoint
}
