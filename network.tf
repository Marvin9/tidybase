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
