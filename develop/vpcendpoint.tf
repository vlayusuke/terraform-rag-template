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
