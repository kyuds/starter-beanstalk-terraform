# vpc
variable "vpc_cidr" {
    type = string
    description = "cidr range for vpc"
    default = "0.0.0.0/16"
}

variable "public_subnet_cidr_range" {
    type = list(string)
    description = "cidr ranges for our public subnets"
    default = [ "10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20" ]
}

variable "public_subnet_azs" {
    type = list(string)
    description = "corresponding public subnet AZ locations"
    default = [ "us-east-1a", "us-east-1b", "us-east-1c" ]
}

variable "beanstalk_subnet_cidr_range" {
    type = list(string)
    description = "cidr ranges for beanstalk subnets"
    default = [ "10.0.80.0/20", "10.0.96.0/20", "10.0.112.0/20" ]
}

variable "beanstalk_subnet_azs" {
    type = list(string)
    description = "corresponding subnet AZ locations for beanstalk"
    default = [ "us-east-1a", "us-east-1b", "us-east-1c" ]
}

variable "aurora_subnet_cidr_range" {
    type = list(string)
    description = "cidr ranges for aurora db subnets"
    default = [ "10.0.160.0/20", "10.0.176.0/20", "10.0.192.0/20" ]
}

variable "aurora_subnet_azs" {
    type = list(string)
    description = "corresponding subnet AZ locations for aurora db"
    default = [ "us-east-1a", "us-east-1b", "us-east-1c" ]
}

# aurora
variable "aurora_db_name" {
    type = string
    description = "aurora db name"
    default = "db"
}

variable "aurora_master_username" {
    type = string
    description = "aurora master username"
    default = "admin"
}

variable "aurora_master_password" {
    type = string
    description = "aurora master password"
    default = "supersecretpassword123"
}

variable "aurora_instance_count" {
    type = number
    description = "number of aurora cluster instances"
    default = 2
}

# bastion
variable "bastion_host_pem_file" {
    type = string
    description = "pem file name for bastion host ssh access"
    default = "key.pem"
}

# application load balancer
variable "alb_acm_certificate" {
    type = string
    description = "ACM certificate arn for application load balancer HTTPS"
}
