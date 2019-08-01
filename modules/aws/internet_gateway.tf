resource "aws_internet_gateway" "dev" {
  vpc_id = "${aws_vpc.dev.id}"

  tags = {
      Name = "group1_dev"
  }
}
