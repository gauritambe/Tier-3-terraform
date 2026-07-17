#Custom VPC setup
resource "aws_vpc" "app-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "app-vpc"
  }
}

# AZ-1 subnets
#Public subnet
resource "aws_subnet" "app-public-subnet-1" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    depends_on = [ aws_vpc.app-vpc ]

    tags = {
      Name = "public-subnet-1"
    }
}

#Private Subnet
resource "aws_subnet" "app-private-subnet-1a" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    depends_on = [ aws_vpc.app-vpc ]

    tags = {
     Name = "private-subnet-1a" 
    }
}

#Private Subnet
resource "aws_subnet" "app-private-subnet-1b" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-1c"
    depends_on = [ aws_vpc.app-vpc ]

    tags = {
     Name = "private-subnet-1b" 
    }
}

# AZ-2 subnets
#Public subnet
resource "aws_subnet" "app-public-subnet-2" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "ap-south-1a"
    depends_on = [ aws_vpc.app-vpc ]

    tags = {
     Name = "public-subnet-2" 
    }
}

#Private Subnet
resource "aws_subnet" "app-private-subnet-2a" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.5.0/24"
    availability_zone = "ap-south-1b"
    depends_on = [ aws_vpc.app-vpc ]

    tags = {
     Name = "private-subnet-2a" 
    }
}

#Private Subnet
resource "aws_subnet" "app-private-subnet-2b" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = "10.0.6.0/24"
    availability_zone = "ap-south-1c"
    depends_on = [ aws_vpc.app-vpc ]

    tags = {
     Name = "private-subnet-2b" 
    }
}

#Internet Gateway
resource "aws_internet_gateway" "app-igw" {
  vpc_id = aws_vpc.app-vpc.id

  tags = {
    Name = "app-igw"
  }
}

#EIP 
resource "aws_eip" "app-eip" {
  domain = "vpc"

  tags = {
    Name = "app-eip"
  }
}

#NAT Gateway
resource "aws_nat_gateway" "app-nat" {
  allocation_id = aws_eip.app-eip.id
  subnet_id = aws_subnet.app-public-subnet-1.id

  tags = {
    Name = "app-nat"
  }

  depends_on = [ aws_internet_gateway.app-igw ]
}

#Route table configurations
resource "aws_route_table" "app-public-rt" {
  vpc_id = aws_vpc.app-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-igw.id
  } 

  tags = {
    Name = "app-public-rt"
  }
}

resource "aws_route_table" "app-private-rt" {
  vpc_id = aws_vpc.app-vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.app-nat.id
  } 

  tags = {
    Name = "app-private-rt"
  }
}

# Route table association public
resource "aws_route_table_association" "public-association-1" {
  subnet_id = aws_subnet.app-public-subnet-1.id
  route_table_id = aws_route_table.app-public-rt.id
}

resource "aws_route_table_association" "public-association-2" {
  subnet_id = aws_subnet.app-public-subnet-2.id
  route_table_id = aws_route_table.app-public-rt.id
}

# Route table association private
resource "aws_route_table_association" "private-association-1a" {
  subnet_id = aws_subnet.app-private-subnet-1a.id
  route_table_id = aws_route_table.app-private-rt.id
}

resource "aws_route_table_association" "private-association-2a" {
  subnet_id = aws_subnet.app-private-subnet-1b.id
  route_table_id = aws_route_table.app-private-rt.id
}

# AZ-2 Route association
resource "aws_route_table_association" "private-association-1b" {
  subnet_id = aws_subnet.app-private-subnet-2a.id
  route_table_id = aws_route_table.app-private-rt.id
}

resource "aws_route_table_association" "private-association-2b" {
  subnet_id = aws_subnet.app-private-subnet-2b.id
  route_table_id = aws_route_table.app-private-rt.id
}

#Security Group for webserver
resource "aws_security_group" "webserver-sg" {

  name = "webserver-sg"
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.168.0.112/32"]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-1.cidr_block]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-2.cidr_block]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-1.cidr_block]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-2.cidr_block]
  }

  egress {
    description = "Allow all"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver-sg"
  }
}

#Security Group for backend
resource "aws_security_group" "backend-sg" {

  name = "backend-sg"
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-1.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-2.cidr_block]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-1.cidr_block]
  }

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-2.cidr_block]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-1.cidr_block]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-public-subnet-2.cidr_block]
  }

  egress {
    description = "Allow all"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-sg"
  }
}

#Security Group for db
resource "aws_security_group" "db-sg" {

  name = "db-sg"
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-private-subnet-1a.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-private-subnet-2a.cidr_block]
  }

  ingress {
    description = "MYSQL"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-private-subnet-1a.cidr_block]
  }

  ingress {
    description = "MYSQL"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [aws_subnet.app-private-subnet-2a.cidr_block]
  }

  egress {
    description = "Allow all"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

#Security Group for ALB
resource "aws_security_group" "alb-sg" {

  name = "alb-sg"
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# Key Pair
resource "aws_key_pair" "app-key" {
  key_name = "app-key"
  public_key = file(".ssh/id_ed25519.pub")

  tags = {
    Name = "app-key"
  }
}

# EC2 Instance 
# AZ-1 Instance configuration
#webserver instance
resource "aws_instance" "app-webserver-1" {
  ami = var.aws-ami
  instance_type = "t3.micro"
  subnet_id = aws_subnet.app-public-subnet-1.id
  key_name = aws_key_pair.app-key.key_name
  vpc_security_group_ids = [ aws_security_group.webserver-sg.id ]

  tags = {
    Name = "app-webserver-1"
  }
}

#Backend Instance
resource "aws_instance" "app-backend-1" {
  ami = var.aws-ami
  instance_type = "t3.small"
  subnet_id = aws_subnet.app-private-subnet-1a.id
  key_name = aws_key_pair.app-key.key_name
  vpc_security_group_ids = [ aws_security_group.backend-sg.id ]

  tags = {
    Name = "app-backend-1"
  }
}

#DB instance
resource "aws_instance" "app-db-1" {
  ami = var.aws-ami
  instance_type = "t3.small"
  subnet_id = aws_subnet.app-private-subnet-1b.id
  key_name = aws_key_pair.app-key.key_name
  vpc_security_group_ids = [ aws_security_group.db-sg.id ]

  tags = {
    Name = "app-db-1"
  }
}

# AZ-2 Instance configuration
#webserver instance
resource "aws_instance" "app-webserver-2" {
  ami = var.aws-ami
  instance_type = "t3.micro"
  subnet_id = aws_subnet.app-public-subnet-2.id
  key_name = aws_key_pair.app-key.key_name
  vpc_security_group_ids = [ aws_security_group.webserver-sg.id ]

  tags = {
    Name = "app-webserver-2"
  }
}

#Backend Instance
resource "aws_instance" "app-backend-2" {
  ami = var.aws-ami
  instance_type = "t3.small"
  subnet_id = aws_subnet.app-private-subnet-2a.id
  key_name = aws_key_pair.app-key.key_name
  vpc_security_group_ids = [ aws_security_group.backend-sg.id ]

  tags = {
    Name = "app-backend-2"
  }
}

#DB instance
resource "aws_instance" "app-db-2" {
  ami = var.aws-ami
  instance_type = "t3.small"
  subnet_id = aws_subnet.app-private-subnet-2b.id
  key_name = aws_key_pair.app-key.key_name
  vpc_security_group_ids = [ aws_security_group.db-sg.id ]

  tags = {
    Name = "app-db-2"
  }
}

#Application Load Balancer
resource "aws_lb" "app-alb" {
  name = "app-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = [
    aws_subnet.app-public-subnet-1.id,
    aws_subnet.app-public-subnet-2.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "app-alb"
  }
}

# Target Attachment
resource "aws_lb_target_group_attachment" "app-attachment-1" {
  target_group_arn = aws_lb_target_group.app-tg.arn
  target_id = aws_instance.app-webserver-1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "app-attachment-2" {
  target_group_arn = aws_lb_target_group.app-tg.arn
  target_id = aws_instance.app-webserver-2.id
  port = 80
}

#Target Group
resource "aws_lb_target_group" "app-tg" {
  name = "app-tg"
  target_type = "instance"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.app-vpc.id

  health_check {
    path = "/"
  }

  tags = {
    Name = "app-tg"
  }
}

# ALB Listner
resource "aws_lb_listener" "alb-listner" {
  load_balancer_arn = aws_lb.app-alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app-tg.arn
  }
}