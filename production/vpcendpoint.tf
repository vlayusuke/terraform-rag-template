# ===============================================================================
# VPC Endpoint (AWS Systems Manager)
# ===============================================================================
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.ssm"
  service_region      = local.region
  vpc_endpoint_type   = "Interface"
  ip_address_type     = "ipv4"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpce_ssm.id,
  ]

  subnet_ids = [
    for subnet in aws_subnet.main_private :
    subnet.id
  ]

  dns_options {
    dns_record_ip_type = "ipv4"
  }

  tags = {
    Name = "${local.project}-${local.env}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint_policy" "ssm" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm.id
  policy          = data.aws_iam_policy_document.ssm.json
}

data "aws_iam_policy_document" "ssm" {
  statement {
    sid    = "AllowSSMAccess"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# VPC Endpoint (AWS Systems Manager - Messages)
# ===============================================================================
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  service_region      = local.region
  vpc_endpoint_type   = "Interface"
  ip_address_type     = "ipv4"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpce_ssm.id,
  ]

  subnet_ids = [
    for subnet in aws_subnet.main_private :
    subnet.id
  ]

  dns_options {
    dns_record_ip_type = "ipv4"
  }

  tags = {
    Name = "${local.project}-${local.env}-vpce-ssm-messages"
  }
}

resource "aws_vpc_endpoint_policy" "ssm_messages" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm_messages.id
  policy          = data.aws_iam_policy_document.ssm_messages.json
}

data "aws_iam_policy_document" "ssm_messages" {
  statement {
    sid    = "AllowSSMMessagesAccess"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = [
      "*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# VPC Endpoint (Amazon S3 Bucket)
# ===============================================================================
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  ip_address_type   = "ipv4"

  route_table_ids = [
    for route_table in aws_route_table.main_private :
    route_table.id
  ]

  dns_options {
    dns_record_ip_type = "ipv4"
  }

  tags = {
    Name = "${local.project}-${local.env}-vpce-s3"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_gateway" {
  count           = length(local.availability_zones)
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
  route_table_id  = aws_route_table.main_private[count.index].id
}

resource "aws_vpc_endpoint_policy" "s3_gateway" {
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
  policy          = data.aws_iam_policy_document.s3_gateway.json
}

data "aws_iam_policy_document" "s3_gateway" {
  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "*",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}
