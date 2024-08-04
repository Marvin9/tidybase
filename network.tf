resource "aws_vpc" "tidybase_network" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tidybase"
  }
}

resource "aws_internet_gateway" "tidybase_internet_gateway" {
  tags = {
    Name = "tidybase"
  }
}

resource "aws_internet_gateway_attachment" "tidybase_internet_gateway_attachement" {
  vpc_id              = aws_vpc.tidybase_network.id
  depends_on          = [aws_internet_gateway.tidybase_internet_gateway]
  internet_gateway_id = aws_internet_gateway.tidybase_internet_gateway.id
}

resource "aws_route_table" "tidybase_route_table" {
  vpc_id = aws_vpc.tidybase_network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tidybase_internet_gateway.id
  }
}

resource "aws_route_table_association" "tidybase_compute_route_table" {
  route_table_id = aws_route_table.tidybase_route_table.id
  subnet_id      = aws_subnet.tidybase_compute_subnet.id
}

resource "aws_route_table_association" "tidybase_lb_1_route_table" {
  route_table_id = aws_route_table.tidybase_route_table.id
  subnet_id      = aws_subnet.tidybase_lb_1.id
}

resource "aws_route_table_association" "tidybase_lb_2_route_table" {
  route_table_id = aws_route_table.tidybase_route_table.id
  subnet_id      = aws_subnet.tidybase_lb_2.id
}

resource "aws_subnet" "tidybase_lb_1" {
  vpc_id            = aws_vpc.tidybase_network.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "tidybase-lb-1"
  }
}

resource "aws_subnet" "tidybase_lb_2" {
  vpc_id            = aws_vpc.tidybase_network.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.3.0/24"

  tags = {
    Name = "tidybase-lb-2"
  }
}

resource "aws_security_group" "tidybase_lb" {
  vpc_id = aws_vpc.tidybase_network.id

  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "allow all http"
      from_port        = 80
      protocol         = "tcp"
      self             = true
      to_port          = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
    }
  ]

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "allow all http"
      from_port        = 80
      protocol         = "tcp"
      self             = true
      to_port          = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
    }
  ]
}
