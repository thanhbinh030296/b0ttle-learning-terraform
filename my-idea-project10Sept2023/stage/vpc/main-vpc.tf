provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "b0ttle_vpc" {
  cidr_block = "30.0.0.0/16"
  tags = {
    "Name" = "b0ttle-vpc"
  }

}
# public subnet here
resource "aws_subnet" "subnet-1" {
  vpc_id     = "${aws_vpc.b0ttle_vpc.id}"
  cidr_block = "30.0.1.0/24"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.b0ttle_vpc.id

  tags = {
    Name = "b0ttle-public-internate-Gateway"
  }
}