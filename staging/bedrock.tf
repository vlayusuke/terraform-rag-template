# ===============================================================================
# Amazon Bedrock Guardrail
# ===============================================================================
resource "aws_bedrock_guardrail" "bedrock_guardrail" {
  name                      = "${local.project}-${local.env}-brk-guardrail"
  description               = "Amazon Bedrock Guardrail for ${local.project}-${local.env}"
  blocked_input_messaging   = "Your input has been blocked due to policy violations."
  blocked_outputs_messaging = "The response has been blocked due to policy violations."

  content_policy_config {
    filters_config {
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
      type            = "HATE"
    }
    tier_config {
      tier_name = "STANDARD"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      action         = "BLOCK"
      input_action   = "BLOCK"
      output_action  = "ANONYMIZE"
      input_enabled  = true
      output_enabled = true
      type           = "NAME"
    }

    regexes_config {
      action         = "BLOCK"
      input_action   = "BLOCK"
      output_action  = "BLOCK"
      input_enabled  = true
      output_enabled = false
      description    = "example regex"
      name           = "regex_example"
      pattern        = "^\\d{3}-\\d{2}-\\d{4}$"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "investment_topic"
      examples   = ["Where should I invest my money ?"]
      type       = "DENY"
      definition = "Investment advice refers to inquiries, guidance, or recommendations regarding the management or allocation of funds or assets with the goal of generating returns ."
    }
    tier_config {
      tier_name = "STANDARD"
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
    words_config {
      text = "HATE"
    }
  }

  cross_region_config {
    guardrail_profile_identifier = "arn:aws:bedrock:${local.region}:${data.aws_caller_identity.current.account_id}:guardrail-profile/apac.guardrail.v1:0"
  }

  tags = {
    Name = "${local.project}-${local.env}-brk-guardrail"
  }
}

resource "aws_bedrock_guardrail_version" "bedrock_guardrail_version" {
  description   = "Amazon Bedrock Guardrail version for ${local.project}-${local.env}"
  guardrail_arn = aws_bedrock_guardrail.bedrock_guardrail.guardrail_arn
  skip_destroy  = true
}


# ===============================================================================
# Amazon Bedrock Knowledge base
# ===============================================================================
resource "aws_bedrockagent_knowledge_base" "knowledge_base" {
  name     = "${local.project}-${local.env}-brk-knowledge-base"
  role_arn = aws_iam_role.bedrock_knowledge_base.arn

  knowledge_base_configuration {
    type = "VECTOR"

    # Titan Text Embeddings v2
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.bedrock_knowledge_base_model.model_arn
    }
  }

  storage_configuration {
    type = "RDS"

    rds_configuration {
      credentials_secret_arn = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      database_name          = aws_rds_cluster.aurora_postgres.database_name
      resource_arn           = aws_rds_cluster.aurora_postgres.arn
      table_name             = "${local.schema_name}.${local.table_name}"

      field_mapping {
        primary_key_field = "id"
        vector_field      = "embedding"
        text_field        = "chunks"
        metadata_field    = "metadata"
      }
    }
  }

  depends_on = [
    aws_rds_cluster_instance.aurora_postgres_instance,
  ]

  tags = {
    Name = "${local.project}-${local.env}-brk-knowledge-base"
  }
}

data "aws_bedrock_foundation_model" "bedrock_knowledge_base_model" {
  model_id = local.bedrock_knowledge_base_model
}

# Create a data source for the knowledge base from documents in an S3 bucket.
resource "aws_bedrockagent_data_source" "bedrock_data_source" {
  name              = "${local.project}-${local.env}-brk-knowledge-base-data-source"
  knowledge_base_id = aws_bedrockagent_knowledge_base.knowledge_base.id

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.rag_documents.arn
    }
  }
}
