resource "aws_vpc" "url_shortener_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.url_shortener_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.url_shortener_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.url_shortener_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.url_shortener_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-northeast-2c"
}

resource "aws_subnet" "private_db_1" {
  vpc_id            = aws_vpc.url_shortener_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.url_shortener_vpc.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "ap-northeast-2c"
}

resource "aws_internet_gateway" "url_shortener_igw" {
  vpc_id = aws_vpc.url_shortener_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.url_shortener_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.url_shortener_igw.id
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_route_table.id
}
