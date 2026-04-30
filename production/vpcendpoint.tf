# ===============================================================================
# VPC Endpoint (Amazon S3 Bucket)
# ===============================================================================
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${local.project}-${local.env}-vpce-s3"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_gateway" {
  count           = length(local.availability_zones)
  vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
  route_table_id  = aws_route_table.main_private[count.index].id
}
