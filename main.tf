provider "aws" {
  region = "us-east-1"
}

locals {
environment = terraform.workspace == "skruhlik.dev" ? "skruhlik.dev" : "skruhlik.prod"
environment_db = terraform.workspace == "skruhlik.dev" ? "skruhlikdev" : "skruhlikprod"
}

resource "aws_vpc" "skruhlik-vpc" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "skruhlik-vpc"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pr1
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-private-subnet-1"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pr2
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-private-subnet-2"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pb1
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-public-subnet-1"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.skruhlik-vpc.id
  cidr_block = var.cidr_block_pb2
  availability_zone = "us-east-1a"

  tags = {
    Name        = "skruhlik-public-subnet-2"
    Environment = local.environment
    ManagedBy   = var.managedby
  }
}

resource "aws_internet_gateway" "skruhlik-gw" {
  vpc_id = aws_vpc.skruhlik-vpc.id

  tags = {
    Name = "skruhlik-InternetGateway"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.skruhlik-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.skruhlik-gw.id
  }

  tags = {
    Name = "skruhlik-PublicRouteTable"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_security_group" "skruhlik-allow-ssh" {
  name        = "skruhlik-allow-ssh"
  description = "allow ssh access"
  vpc_id      = aws_vpc.skruhlik-vpc.id  

  ingress {
    description = "ssh from public subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "skruhlik-allow-ssh"
    Environment = local.environment
	ManagedBy = var.managedby
  }
}


resource "aws_ecr_repository" "skruhlik-ecr-repository" {
  name                  = "skruhlik-ecr-repository"
  image_scanning_configuration {
    scan_on_push        = false
  }
  encryption_configuration {
    encryption_type     = "AES256"
  }
  
  tags = {
    Name      = "skruhlik-ecr-repository"
    ManagedBy = var.managedby
  }
}

/*
resource "aws_dynamodb_table" "skruhlik-lock-table" {
  name           = "skruhlik-lock-table"
  billing_mode   = "PAY_PER_REQUEST"  
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = local.environment
    ManagedBy = var.managedby   
  }
}
*/

/*
resource "aws_s3_bucket" "skruhlik-bucket" {
  bucket = "skruhlik-bucket"
  acl    = "private"

  tags = {
    Environment = local.environment
	ManagedBy = var.managedby
  }
}
*/

terraform {
  backend "s3" {
    bucket = "skruhlik-bucket"
    key    = "terraform.local.environment.tfstate"
    region = "us-east-1"
	dynamodb_table = "skruhlik-lock-table"
  }
}

resource "random_string" "rand_pass" {
  length           = 12
  special          = true
  override_special = "$@"
}

module "ssm_store" {
  source  = "cloudposse/ssm-parameter-store/aws"

  parameter_write = [
    {
      name        = "skruhlik.pass"
      value       = random_string.rand_pass.result
      type        = "SecureString"
      overwrite   = "true"
      description = var.description
    }
  ]

  tags = {
    ManagedBy = var.managedby
  }
}

resource "aws_network_interface" "private_1" {
  subnet_id   = aws_subnet.private_subnet_1.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-private-interface"
  }
}

resource "aws_network_interface" "private_2" {
  subnet_id   = aws_subnet.private_subnet_2.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-private-interface"
  }
}

resource "aws_network_interface" "public_1" {
  subnet_id   = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-public-interface"
  }
}

resource "aws_network_interface" "public_2" {
  subnet_id   = aws_subnet.public_subnet_2.id
  security_groups = [aws_security_group.skruhlik-allow-ssh.id]

  tags = {
    Name = "skruhlik-public-interface"
  }
}

/*
resource "aws_network_interface_attachment" "private_subnet_1" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.private_1.id
  device_index         = 4
}
*/

/*
resource "aws_network_interface_attachment" "public_subnet_1" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.public_1.id
  device_index         = 1
}
*/

resource "aws_network_interface_attachment" "private_subnet_2" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.private_2.id
  device_index         = 2
}

/*
resource "aws_network_interface_attachment" "public_subnet_2" {
  instance_id          = aws_instance.skruhlik-terraform-ec2.id
  network_interface_id = aws_network_interface.public_2.id
  device_index         = 3
}
*/

resource "aws_instance" "skruhlik-terraform-ec2" {
  availability_zone      = "us-east-1a"
  ami                    = "ami-044a3516c1b05985f"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_1.id 
  vpc_security_group_ids = [aws_security_group.skruhlik-allow-ssh.id]
  key_name               = "devops"
  associate_public_ip_address = true

  tags = {
    Name = "skruhlik-terraform-ec2"
  }
}

resource "aws_db_instance" "skruhlik_pg_instance" {
  count = var.necessity_db == "yes" ? 1 : 0
  
  allocated_storage    = 10
  db_name              = "${local.environment_db}"
  engine               = "postgres"
  engine_version       = "16.2"
  instance_class       = var.instance_class
  username             = "postgres"
  password             = random_string.rand_pass.result
  publicly_accessible  = true
  skip_final_snapshot  = true
}

output "vpc_id" {
  value = aws_vpc.skruhlik-vpc.id
}

output "vpc_public_subnet_ids" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "vpc_private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "vpc_vgw_id" {
  value = aws_internet_gateway.skruhlik-gw.id
}
