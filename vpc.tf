# vpc declaration
resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "${local.tag}-vpc"
    }
}

# subnets
resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_azs)
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.public_subnet_cidr_range, count.index)
    availability_zone = element(var.public_subnet_azs, count.index)
    tags = {
        Name = "${local.tag}-subnet-public${count.index + 1}"
        Description = "public subnet"
    }
    depends_on = [ aws_vpc.vpc ]
}

resource "aws_subnet" "beanstalk_subnets" {
    count = length(var.beanstalk_subnet_azs)
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.beanstalk_subnet_cidr_range, count.index)
    availability_zone = element(var.beanstalk_subnet_azs, count.index)
    tags = {
        Name = "${local.tag}-subnet-beanstalk${count.index + 1}"
        Description = "private subnet for beanstalk"
    }
    depends_on = [ aws_vpc.vpc ]
}

resource "aws_subnet" "aurora_subnets" {
    count = length(var.aurora_subnet_azs)
    vpc_id = aws_vpc.vpc.id
    cidr_block = element(var.aurora_subnet_cidr_range, count.index)
    availability_zone = element(var.aurora_subnet_azs, count.index)
    tags = {
        Name = "${local.tag}-subnet-aurora${count.index + 1}"
        Description = "private subnet for aurora"
    }
    depends_on = [ aws_vpc.vpc ]
}

# internet gateway
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${local.tag}-igtw"
    }
    depends_on = [ aws_vpc.vpc ]
}

# NAT gateway
resource "aws_eip" "nat_elastic_ip" {
    count = length(aws_subnet.public_subnets)
    domain = "vpc"
    tags = {
        Name = "${local.tag}-nat-eip"
    }
    depends_on = [ aws_subnet.public_subnets ]
}

resource "aws_nat_gateway" "nat_gateway" {
    count = length(aws_subnet.public_subnets)
    subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
    allocation_id = element(aws_eip.nat_elastic_ip[*].id, count.index)
    tags = {
        Name = "${local.tag}-nat"
    }
    depends_on = [ aws_eip.nat_elastic_ip, aws_subnet.public_subnets ]
}

# route table declarations
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }
    tags = {
        Name = "${local.tag}-public-rt"
    }
    depends_on = [ aws_internet_gateway.internet_gateway, aws_vpc.vpc ]
}

resource "aws_route_table" "private_route_table" {
    count = length(aws_nat_gateway.nat_gateway)
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = element(aws_nat_gateway.nat_gateway[*].id, count.index)
    }
    tags = {
        Name = "${local.tag}-private-rt${count.index + 1}"
    }
    depends_on = [ aws_nat_gateway.nat_gateway, aws_vpc.vpc ]
}

# route table associations
resource "aws_route_table_association" "public_route_table_association" {
    count = length(aws_subnet.public_subnets)
    subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
    route_table_id = aws_route_table.public_route_table.id
    depends_on = [ aws_subnet.public_subnets, aws_route_table.public_route_table ]
}

resource "aws_route_table_association" "private_route_table_association_beanstalk" {
    count = length(aws_subnet.beanstalk_subnets)
    subnet_id = element(aws_subnet.beanstalk_subnets[*].id, count.index)
    route_table_id = element(aws_route_table.private_route_table[*].id, count.index)
    depends_on = [ aws_subnet.beanstalk_subnets, aws_route_table.private_route_table ]
}

resource "aws_route_table_association" "private_route_table_association_aurora" {
    count = length(aws_subnet.aurora_subnets)
    subnet_id = element(aws_subnet.aurora_subnets[*].id, count.index)
    route_table_id = element(aws_route_table.private_route_table[*].id, count.index)
    depends_on = [ aws_subnet.aurora_subnets, aws_route_table.private_route_table ]
}

# marking default route table as unused
resource "aws_default_route_table" "default_route_table" {
    default_route_table_id = aws_vpc.vpc.default_route_table_id
    tags = {
        Name = "[NOTUSED](default)"
    }
    depends_on = [ aws_vpc.vpc ]
}
