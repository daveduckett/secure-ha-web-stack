# Define the VPC
resource "aws_vpc" "main_vpc" {
  cidr_block            =   var.vpc_cidr
  enable_dns_hostnames  =   true
  enable_dns_support    =   true
  
    tags = {
        Name = "main_vpc"
    }
}

# Declare the IGW
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name = "main_vpc_igw"
    }
}

# Declare the AZ data source
data "aws_availability_zones" "available" {
  state = "available"
}

# e.g., Create subnets
resource "aws_subnet" "public_entrypoint" {
    vpc_id              =   aws_vpc.main_vpc.id
    count               =   3
    availability_zone   =   data.aws_availability_zones.available.names[count.index]
    cidr_block          =   cidrsubnet(var.vpc_cidr, 8, count.index) 

        tags = {
            Name = "public_entrypoint-${count.index}"
        }
}

resource "aws_subnet" "private_ec2" {
    vpc_id              =   aws_vpc.main_vpc.id
    count               =   3
    availability_zone   =   data.aws_availability_zones.available.names[count.index]
    cidr_block          =   cidrsubnet(var.vpc_cidr, 8, count.index + 10) 


         tags = {
            Name = "private_ec2-${count.index}"
        }
}

resource "aws_subnet" "isolated_rds" {
    vpc_id              =   aws_vpc.main_vpc.id
    count               =   3
    availability_zone   =   data.aws_availability_zones.available.names[count.index]
    cidr_block          =   cidrsubnet(var.vpc_cidr, 8, count.index + 20) 


        tags = {
            Name = "isolated_rds-${count.index}"
        }
}

# EIP for Nat Gateway
resource "aws_eip" "ngw_ip" {
    domain   =  "vpc"
}

# Define the NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.ngw_ip.id
subnet_id     = aws_subnet.public_entrypoint[0].id

    tags = {
        Name = "nat_gateway"
    }

    depends_on = [aws_internet_gateway.igw]
}

# Defining the routing tables and associations 
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Name = "public_routing_table"
  }
}

resource "aws_route_table_association" "public_Internet_out" {
    count          =    3
    subnet_id      =    aws_subnet.public_entrypoint[count.index].id
    route_table_id =    aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }


    tags = {
        Name = "private_routing_table"
    }
}

resource "aws_route_table_association" "private_out" {
    count          =    3
    subnet_id      =    aws_subnet.private_ec2[count.index].id
    route_table_id =    aws_route_table.private_route_table.id
}

resource "aws_route_table" "isolated_route_table" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name = "isolated_routing_table"
    }
}

resource "aws_route_table_association" "isolated_box" {
    count          =    3
    subnet_id      =    aws_subnet.isolated_rds[count.index].id
    route_table_id =    aws_route_table.isolated_route_table.id
}

# VPC Endpoints to comm with internal AWS Resources
resource "aws_vpc_endpoint" "s3_endpoint" {
    vpc_id              =   aws_vpc.main_vpc.id
    service_name        =   "com.amazonaws.${var.aws_region}.s3"
    vpc_endpoint_type   =   "Gateway"
    route_table_ids     =   [ aws_route_table.public_route_table.id, 
                            aws_route_table.private_route_table.id ]

  tags = {
    Environment = "Dev"
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
    vpc_id              =   aws_vpc.main_vpc.id
    service_name        =   "com.amazonaws.${var.aws_region}.ssm"
    vpc_endpoint_type   =   "Interface"
    security_group_ids  =   [ aws_security_group.vpc_endpoint_sg.id ]
    subnet_ids          =   aws_subnet.private_ec2[*].id
    




  tags = {
    Environment = "Dev"
  }
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
    vpc_id              =   aws_vpc.main_vpc.id
    service_name        =   "com.amazonaws.${var.aws_region}.ssmmessages"
    vpc_endpoint_type   =   "Interface"
    security_group_ids  =   [ aws_security_group.vpc_endpoint_sg.id ]
    subnet_ids          =   aws_subnet.private_ec2[*].id
    


  tags = {
    Environment = "Dev"
  }
}

resource "aws_vpc_endpoint" "ec2messages_endpoint" {
    vpc_id              =   aws_vpc.main_vpc.id
    service_name        =   "com.amazonaws.${var.aws_region}.ec2messages"
    vpc_endpoint_type   =   "Interface"
    security_group_ids  =   [ aws_security_group.vpc_endpoint_sg.id ]
    subnet_ids          =   aws_subnet.private_ec2[*].id
    


  tags = {
    Environment = "Dev"
  }
}