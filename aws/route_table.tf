# dev_public
resource "aws_route_table" "dev_public" {
  vpc_id = "${aws_vpc.dev.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dev.id}"
  }

  tags = {
      Name = "group1_dev-public"
  }
}

resource "aws_route_table_association" "dev_subnet_1a" {
  subnet_id      = "${aws_subnet.subnet_1a.id}"
  route_table_id = "${aws_route_table.dev_public.id}"
}

