# Provider
provider "aws" {
  region = "us-east-1"
}
# IGW
resource "aws_internet_gateway" "ng-igw" {
  vpc_id = "${aws_vpc.ng-vpc.id}"
  tags = {
    Name = "ng-igw"
  }
}
# VPC
resource "aws_vpc" "ng-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ng-vpc"
  }
}
# Subnet
resource "aws_subnet" "ng-pblc-subnet" {
  vpc_id     = "${aws_vpc.ng-vpc.id}"
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "ng-pblc-subnet"
  }
}

resource "aws_subnet" "ng-prvt-subnet" {
  vpc_id     = "${aws_vpc.ng-vpc.id}"
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "ng-pblc-subnet"
  }
}
# Route Table
resource "aws_route_table" "ng-pblc-rt" {
  vpc_id = "${aws_vpc.ng-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ng-igw.id}"
  }
  tags = {
    Name = "ng-pblc-rt"
  }
}

resource "aws_route_table" "ng-prvt-rt" {
  vpc_id = "${aws_vpc.ng-vpc.id}"
  tags = {
    Name = "ng-prvt-rt"
  }
}

# Route Table Association 
resource "aws_route_table_association" "ng-pblc-association" {
  subnet_id      = "${aws_subnet.ng-pblc-subnet.id}"
  route_table_id = "${aws_route_table.ng-pblc-rt.id}"
}
resource "aws_route_table_association" "ng-prvt-association" {
  subnet_id      = "${aws_subnet.ng-prvt-subnet.id}"
  route_table_id = "${aws_route_table.ng-prvt-rt.id}"
}

# Elastic IP
resource "aws_eip" "natgwIP" {
  vpc = true
  lifecycle {
    prevent_destroy = false
  }
  tags = {
    Name = "NAT-gateway-elasticIP"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.natgwIP.id}"
  subnet_id     = "${aws_subnet.ng-pblc-subnet.id}"
  tags = {
    Name = "natgw"
  }
}

# NAT gateway association 
resource "aws_route" "nat_gateway" {
  route_table_id         = "${aws_route_table.ng-prvt-rt.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.natgw.id}"
}
# Security group
resource "aws_security_group" "nat_gateway_pblc_SG" {
  name   = "nat_gateway_pblc_SG"
  vpc_id = "${aws_vpc.ng-vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["71.171.85.147/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nat_gateway_pblc_SG"
  }
}

resource "aws_security_group" "nat_gateway_prvt_SG" {
  name   = "nat_gateway_prvt_SG"
  vpc_id = "${aws_vpc.ng-vpc.id}"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat_gateway_prvt_SG"
  }
}



# EC2 instance 
resource "aws_instance" "natgw-pblc-instance" {
  ami                         = "ami-04a0ee204b44cc91a"
  instance_type               = "t2.2xlarge"
  key_name                    = "linux-test"
  subnet_id                   = "${aws_subnet.ng-pblc-subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.nat_gateway_pblc_SG.id}"]
  associate_public_ip_address = "true"
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = true
  }
  tags = {
    Name = "natgw-pblc-windows-instance"
  }
}
resource "aws_instance" "natgw-prvt-instance" {
  ami                    = "ami-04a0ee204b44cc91a"
  instance_type          = "t2.2xlarge"
  key_name               = "linux-test"
  subnet_id              = "${aws_subnet.ng-prvt-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.nat_gateway_prvt_SG.id}"]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = true
  }
  tags = {
    Name = "natgw-prvt-windows-instance"
  }
}

resource "aws_instance" "natgw-prvt-ansible-instance" {
  ami                         = "ami-09d95fab7fff3776c"
  instance_type               = "t2.xlarge"
  key_name                    = "linux-test"
  subnet_id                   = "${aws_subnet.ng-pblc-subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.nat_gateway_pblc_SG.id}"]
  associate_public_ip_address = "true"
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "100"
    delete_on_termination = true
  }
  tags = {
    Name = "natgw-prvt-ansible-instance"
  }
}
