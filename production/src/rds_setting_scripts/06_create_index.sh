#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html
# Create an index with the cosine operator which the bedrock can use to query the data
SCHEMA_NAME=$(echo $SCHEMA_NAME | sed 's/"//g')
TABLE_NAME=$(echo $TABLE_NAME | sed 's/"//g')
INDEX_NAME=$(echo $INDEX_NAME | sed 's/"//g')

# chunks列の全文検索用GINインデックス
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "CREATE INDEX IF NOT EXISTS ${INDEX_NAME}_chunks_gin ON $SCHEMA_NAME.$TABLE_NAME USING gin (to_tsvector('simple',chunks));"

# embedding列のHNSWインデックス
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "CREATE INDEX IF NOT EXISTS ${INDEX_NAME}_embedding_hnsw ON $SCHEMA_NAME.$TABLE_NAME USING hnsw (embedding vector_cosine_ops);"
