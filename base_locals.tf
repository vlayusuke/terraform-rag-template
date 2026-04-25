# ================================================================================
# Base Local Values
# ================================================================================
locals {
  # repository info
  repository = "vlayusuke/terraform-rag-template"

  # project info
  project = "tf-rag"
  author  = "Yusuke TOMIOKA"
  email   = "vlayusuke@gmail.com"

  # state files
  production_state_file  = "production.terraform.tfstate"
  staging_state_file     = "staging.terraform.tfstate"
  development_state_file = "development.terraform.tfstate"
  audit_state_file       = "audit.terraform.tfstate"
  root_state_file        = "terraform.tfstate"

  # region
  region = "ap-northeast-1"

  # availability zones
  availability_zones = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d",
  ]

  # domain
  domain = "rag.vlayusuke.net"

  # database info
  database_name             = "tf-rag"
  database_master_user_name = "admin"
}
