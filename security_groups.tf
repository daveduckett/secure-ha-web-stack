# ALB Security Group Definition
resource "aws_security_group" "alb_sg" {
    name        =   "alb_sg"
    description =   "Security group for ALB"
    vpc_id      =   aws_vpc.main_vpc.id

    tags = {
        Name = "core_sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_Internet_web_traffic_to_alb" {
    security_group_id =     aws_security_group.alb_sg.id
    cidr_ipv4         =     "0.0.0.0/0"
    from_port         =     80
    ip_protocol       =     "tcp"
    to_port           =     80
}

# App Security Group Definition
resource "aws_security_group" "app_sg" {
    name        =   "app_sg"
    description =   "Security group for App"
    vpc_id      =   aws_vpc.main_vpc.id

    tags = {
        Name = "core_sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_web_traffic_from_alb" {
    security_group_id            =     aws_security_group.app_sg.id
    referenced_security_group_id =     aws_security_group.alb_sg.id
    from_port                    =     5000
    ip_protocol                  =     "tcp"
    to_port                      =     5000
}

# DB Security Group Definition
resource "aws_security_group" "db_sg" {
    name        =   "db_sg"
    description =   "Security group for Database"
    vpc_id      =   aws_vpc.main_vpc.id

    tags = {
        Name = "core_sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_3306_traffic_from_app_to_db" {
    security_group_id            =     aws_security_group.db_sg.id
    referenced_security_group_id =     aws_security_group.app_sg.id
    from_port                    =     3306
    ip_protocol                  =     "tcp"
    to_port                      =     3306
}

resource "aws_vpc_security_group_ingress_rule" "allow_5432_traffic_from_app_to_db" {
    security_group_id            =     aws_security_group.db_sg.id
    referenced_security_group_id =     aws_security_group.app_sg.id
    from_port                    =     5432
    ip_protocol                  =     "tcp"
    to_port                      =     5432
}

# VPC Endpoints Security Group Definition
resource "aws_security_group" "vpc_endpoint_sg" {
    name        =   "ssm_endpoint_sg"
    description =   "Security group for SSM Endpoint"
    vpc_id      =   aws_vpc.main_vpc.id

    tags = {
        Name = "vpc_endpoint_sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_vpc_service_traffic_to_endpoint" {
    security_group_id =     aws_security_group.vpc_endpoint_sg.id
    cidr_ipv4         =     var.vpc_cidr
    from_port         =     443
    ip_protocol       =     "tcp"
    to_port           =     443
}

 # Add to security_groups.tf
resource "aws_vpc_security_group_egress_rule" "app_egress" {
    security_group_id = aws_security_group.app_sg.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1" # All protocols
}
    
resource "aws_vpc_security_group_egress_rule" "alb_egress" {
    security_group_id = aws_security_group.alb_sg.id
    cidr_ipv4 = "0.0.0.0/0"    
    from_port         = 5000
    to_port           = 5000
    ip_protocol       = "tcp"
}