#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html

ROLE_NAME=$(echo $ROLE_NAME | sed 's/"//g')
SCHEMA_NAME=$(echo $SCHEMA_NAME | sed 's/"//g')
# Grant the bedrock_user permission to manage the $SCHEMA_NAME schema
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "GRANT ALL PRIVILEGES ON SCHEMA $SCHEMA_NAME TO \"$ROLE_NAME\";"
