provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

#--------LOCAL
locals {
  vpc_cidr = "10.0.0.0/16"
}

#-----------------------------------------------
# ---- STARTING NETWORK
#--- VPC
resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr
}

#---- SUBNET
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.5.0/24"

  tags = {
    Name = "public_subnet_2"
  }
}

#------- I-GATEWAY
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "b0ttle-ig"
  }
}

# ---- ROUTE_TABLE
resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "route_table_1"
  }
}


#---- associate
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.route_table_1.id
}

# ---- ENDING NETWORK
#-----------------------------------------------


#-------------------------------------------------
#--------------- STARTING EC 2

# ---------------- Security group
resource "aws_security_group" "sg_bast1" {
  name        = "sg_bast1"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_bast1"
  }
}

resource "aws_security_group" "sg_bast2" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_bast2"
  }
}


#---------------- ec2 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.sg_bast1.id]

  associate_public_ip_address = true
  #security_groups = [aws_security_group.sg_bast1.id]

  key_name = "binhnt030296"

  tags = {
    Name = "bastion_host"
  }

}




# ---------------- launch template
resource "aws_launch_template" "foo" {
  name = "foo"

  block_device_mappings {
    #device_name = "/dev/sda1"
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      encrypted   = true
    }
  }

  image_id = data.aws_ami.ubuntu.id

  instance_initiated_shutdown_behavior = "terminate"


  instance_type = "t2.micro"


  key_name = "binhnt030296"


  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.sg_bast2.id]
    subnet_id = aws_subnet.public_subnet_2.id
  }

  #vpc_security_group_ids = [aws_security_group.sg_bast2.id]

  update_default_version = true

  tags = {
    Name = "test"
  }
}

# ------------------------ auto scaling group

resource "aws_autoscaling_group" "asg_b0ttle" {
  name                      = "foobar3-terraform-test"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  #placement_group           = aws_placement_group.test.id
  launch_template {
    id = aws_launch_template.foo.id
    version =  aws_launch_template.foo.latest_version
  }
  #vpc_zone_identifier       = [aws_subnet.example1.id, aws_subnet.example2.id]
  
  vpc_zone_identifier = [aws_subnet.public_subnet_2.id]
  
  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}

#--------------- EDNING EC 2 
#-------------------------------------------------








