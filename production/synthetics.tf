# ===============================================================================
# Amazon CloudWatch Synthetics Group
# ===============================================================================
resource "aws_synthetics_group" "main" {
  name = "${local.project}-${local.env}-cwt-syn-group"

  tags = {
    Name = "${local.project}-${local.env}-cwt-syn-group"
  }
}
