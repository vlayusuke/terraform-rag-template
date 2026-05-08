# ===============================================================================
# Security Group for Amazon EC2 (Bastion)
# ===============================================================================
resource "aws_security_group" "bastion" {
  name        = "${local.project}-${local.env}-bastion-sg"
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
    Name = "${local.project}-${local.env}-bastion-sg"
  }
}


# ===============================================================================
# Security Group for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_security_group" "rds" {
  name        = "${local.project}-${local.env}-rds-sg"
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

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      local.default_gateway_cidr,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-rds-sg"
  }
}


# ================================================================================
# Security Group for EC2 Instance Connector Endpoint
# ================================================================================
resource "aws_security_group" "eic" {
  name        = "${local.project}-${local.env}-eic-sg"
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
    Name = "${local.project}-${local.env}-eic-sg"
  }
}
