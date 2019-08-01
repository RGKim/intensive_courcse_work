resource "aws_subnet" "subnet_1a" {
  vpc_id            = "${aws_vpc.dev.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block        = "101.0.1.0/24"

  tags = { 
    Name = "user21_subnet-1a"
  }
}



resource "aws_subnet" "subnet_1c" {
  vpc_id            = "${aws_vpc.dev.id}"
  availability_zone = "ap-northeast-1c"
  cidr_block        = "101.0.2.0/24"

  tags = { 
    Name = "user21_subnet-1b"
  }
}


