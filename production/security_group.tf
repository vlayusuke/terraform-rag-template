# ===============================================================================
# Security Group for VPC Endpoint (AWS Systems Manager)
# ===============================================================================
resource "aws_security_group" "vpce_ssm" {
  name        = "${local.project}-${local.env}-sgr-vpce-ssm"
  description = "Security Group for AWS Systems Manager VPC Endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS traffic from VPC Security Group"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      aws_vpc.main.cidr_block,
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      local.default_gateway_cidr,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-sgr-vpce-ssm"
  }
}


# ===============================================================================
# Security Group for Amazon EC2 (Bastion)
# ===============================================================================
resource "aws_security_group" "bastion" {
  name        = "${local.project}-${local.env}-sgr-ec2-bastion"
  description = "Security Group for ${local.project}-${local.env} Bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH traffic from Maintenance IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      for ip in var.maintenance_ips :
      ip
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      local.default_gateway_cidr,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-sgr-ec2-bastion"
  }
}


# ===============================================================================
# Security Group for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_security_group" "rds" {
  name        = "${local.project}-${local.env}-sgr-rds"
  description = "Security Group for ${local.project}-${local.env} Amazon Aurora Serverless v2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow PostgreSQL traffic from Bastion"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.bastion.id,
    ]
  }

  ingress {
    description = "Allow PostgreSQL traffic from EC2 Instance Connector Endpoint"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.eic.id,
    ]
  }

  ingress {
    description = "Allow PostgreSQL traffic from Amazon Bedrock"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      local.default_gateway_cidr,
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      local.default_gateway_cidr,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-sgr-rds"
  }
}


# ================================================================================
# Security Group for EC2 Instance Connector Endpoint
# ================================================================================
resource "aws_security_group" "eic" {
  name        = "${local.project}-${local.env}-sgr-eic"
  description = "Security Group for ${local.project}-${local.env} EC2 Instance Connector Endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH traffic from Maintenance IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      for ip in var.maintenance_ips :
      ip
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      local.default_gateway_cidr,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-sgr-eic"
  }
}
