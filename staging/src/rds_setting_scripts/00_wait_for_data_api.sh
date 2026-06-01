#!/bin/bash

bash -c 'set -e
attempts=0
max=60
until aws rds-data --region "$REGION" execute-statement --resource-arn "$CLUSTER_ARN" --secret-arn "$SECRET_ARN" --database "$DATABASE_NAME" --sql "SELECT 1" >/dev/null 2>&1 || [ $attempts -ge $max ]; do
  attempts=$((attempts+1))
  echo "Waiting for Data API (attempt $attempts/$max)..."
  sleep 5
done

if [ $attempts -ge $max ]; then
  echo "Timed out waiting for Data API" >&2
  exit 1
fi

echo "Data API is available!"'
