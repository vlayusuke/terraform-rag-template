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
      input_strength  = "HIGH"
      output_strength = "HIGH"
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
      name       = "hate_speech_topic"
      examples   = ["Create a harmful statement about a protected group."]
      type       = "DENY"
      definition = "Hate speech is content that attacks, insults, or dehumanizes people based on protected characteristics such as race, religion, political belief, or sexual orientation."
    }
    topics_config {
      name       = "protected_class_criticism_topic"
      examples   = ["Write a harmful critique targeting people because of their religion or gender identity."]
      type       = "DENY"
      definition = "Content that denigrates or discriminates against people for their beliefs, religion, politics, or LGBTQ+ identity is prohibited."
    }
    topics_config {
      name       = "defamation_topic"
      examples   = ["Generate an unverified negative statement about a specific individual."]
      type       = "DENY"
      definition = "Defamatory or harassing content targeting a specific person, including abusive or unverified claims, is prohibited."
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
# Amazon Bedrock Agent
# ===============================================================================
resource "aws_bedrockagent_agent" "bedrock_agent" {
  agent_name                  = "${local.project}-${local.env}-brk-api-agent"
  agent_resource_role_arn     = aws_iam_role.bedrock_agent.arn
  description                 = "Amazon Bedrock Agent for ${local.project}-${local.env}"
  foundation_model            = data.aws_bedrock_foundation_model.bedrock_agent_model.model_id
  region                      = local.region
  customer_encryption_key_arn = aws_kms_key.bedrock.arn
  idle_session_ttl_in_seconds = 600
  prepare_agent               = true
  instruction                 = <<EOT
    You are a helpful assistant for providing information about AWS services.
    When you receive a question, please provide an answer based on the information you have.
  EOT

  memory_configuration {
    storage_days = 7
    enabled_memory_types = [
      "SESSION_SUMMARY",
    ]

    session_summary_configuration {
      max_recent_sessions = 100
    }
  }

  guardrail_configuration = [
    {
      guardrail_identifier = aws_bedrock_guardrail.bedrock_guardrail.name
      guardrail_version    = aws_bedrock_guardrail_version.bedrock_guardrail_version.version
    }
  ]

  tags = {
    Name = "${local.project}-${local.env}-brk-api-agent"
  }
}

data "aws_bedrock_foundation_model" "bedrock_agent_model" {
  model_id = local.bedrock_foundation_model
}

resource "aws_bedrockagent_agent_action_group" "bedrock_agent_action_group" {
  action_group_name             = "${local.project}-${local.env}-brk-invoke-api-action-group"
  agent_id                      = aws_bedrockagent_agent.bedrock_agent.id
  parent_action_group_signature = "AMAZON.UserInput"
  agent_version                 = "DRAFT"
  skip_resource_in_use_check    = true

  action_group_executor {
    lambda = aws_lambda_function.request_api.arn
  }

  api_schema {
    payload = file("${path.module}/files/schema/request-api-schema.yml")
  }
}

resource "aws_bedrockagent_agent_alias" "bedrock_agent" {
  agent_alias_name = "${local.project}-${local.env}-brk-request-api-alias"
  description      = "Amazon Bedrock Agent Alias for ${local.project}-${local.env}"
  agent_id         = aws_bedrockagent_agent.bedrock_agent.id

  tags = {
    Name = "${local.project}-${local.env}-brk-request-api-alias"
  }
}

resource "aws_bedrockagent_prompt" "bedrock_prompt" {
  name        = "${local.project}-${local.env}-brk-api-prompt"
  description = "Amazon Bedrock Prompt for ${local.project}-${local.env}"

  variant {
    name          = "${local.project}-${local.env}-brk-api-prompt-variant"
    model_id      = data.aws_bedrock_foundation_model.bedrock_agent_model.model_id
    template_type = "TEXT"

    template_configuration {
      text {
        text = "Your prompt template goes here"
        cache_point {
          type = "default"
        }
      }
    }
  }

  tags = {
    Name = "${local.project}-${local.env}-brk-api-prompt"
  }
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
      bucket_arn = aws_s3_bucket.rag_document.arn
    }
  }
}


# ===============================================================================
# Associate with Amazon Bedrock Agent and Amazon Bedrock Knowledge base
# ===============================================================================
resource "aws_bedrockagent_agent_knowledge_base_association" "bedrock_agent_knowledge_base_association" {
  agent_id = aws_bedrockagent_agent.bedrock_agent.id

  # Instructions for the knowledge base data source. Required field.
  description = <<EOT
    Questions about the documents, please search the knowledge base for an answer.
  EOT

  knowledge_base_id    = aws_bedrockagent_knowledge_base.knowledge_base.id
  knowledge_base_state = "ENABLED"

  depends_on = [
    aws_bedrockagent_knowledge_base.knowledge_base,
  ]
}
