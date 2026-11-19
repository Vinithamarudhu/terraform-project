
provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "girija-vpc" }
}

resource "aws_subnet" "public1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = { Name = "girija-public-1" }
}

resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"
  map_public_ip_on_launch = true
  tags = { Name = "girija-public-2" }
}

resource "aws_subnet" "private1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = { Name = "girija-private-1" }
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-southeast-2b"
  map_public_ip_on_launch = true
  tags = { Name = "girija-private-2" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "girija-public-rt" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "girija-private-rt" }
}

resource "aws_route_table_association" "public1_assoc" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public2_assoc" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private1_assoc" {
  subnet_id = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private2_assoc" {
  subnet_id = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "girija-igw" }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = { Name = "girija-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public1.id
  tags = { Name = "girija-nat" }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private_internet" {
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_instance" "girija-public-ec2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public1.id
  associate_public_ip_address = true
  key_name = "girija-key"

  tags = {
    Name = "girija-public-ec2"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical - Ubuntu
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_s3_bucket" "girija-bucket" {
  bucket = "girija-bucket-2026-demo"

  tags = {
    Name = "girija-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "girija-versioning" {
  bucket = aws_s3_bucket.girija-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "girija-encryption" {
  bucket = aws_s3_bucket.girija-bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "girija-public-block" {
  bucket = aws_s3_bucket.girija-bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "girija-ec2-s3-role" {
  name = "girija-ec2-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}
