resource "aws_vpc" "tidybase_network" {
  cidr_block = "10.0.0.0/16"

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

resource "aws_subnet" "tidybase_compute_subnet" {
  vpc_id     = aws_vpc.tidybase_network.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "tidybase-compute-public"
  }
}

resource "aws_route_table" "tidybase_route_table" {
  vpc_id = aws_vpc.tidybase_network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tidybase_internet_gateway.id
  }
}

resource "aws_route_table_association" "tidybase_route_table_association" {
  subnet_id      = aws_subnet.tidybase_compute_subnet.id
  route_table_id = aws_route_table.tidybase_route_table.id
}

resource "aws_security_group" "tidybase_compute_security_group" {
  vpc_id = aws_vpc.tidybase_network.id
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_compute_allow_all_http_ingress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_compute_allow_all_ssh_ingress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_compute_allow_all_https_ingress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tidybase_compute_allow_all_https_egress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
