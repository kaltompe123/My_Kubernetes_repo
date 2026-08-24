provider "aws" {
  region = "us-east-1"  # Specify your desired region
}

resource   "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
 enable_dns_hostnames = true
    tags = {
        Name = "myvpc"
    }

}    

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "myigw"
  }
}

resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet1"
    }
}

resource "aws_subnet" "public-subnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet2"
    }
}

resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}   

resource "aws_route_table_association" "myrt-association1" {
  route_table_id = aws_route_table.myrt.id
  subnet_id      = aws_subnet.public-subnet1.id
}

resource "aws_route_table_association" "myrt-association2" {
  route_table_id = aws_route_table.myrt.id
  subnet_id      = aws_subnet.public-subnet2.id
}


resource "aws_security_group" "my-security-group" {
  name        = "my-security-group"
  description = "Security group for my resources"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
}

    egress {
    from_port   = 0
    to_port     = 0 
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
        Name = "my-security-group"  
    }   
}