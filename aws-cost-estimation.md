# AWS Cost Estimation for terraform-rag-template

このドキュメントは、`terraform-rag-template` リポジトリの構成から抽出した月額コスト見積もりテンプレートです。

- 対象: `develop` / `staging` / `production` の各環境 (構成・リソース数は同一)
- 稼働時間: 1ヶ月 = 730時間
- 通貨: USD
- 注意: 実際の単価は AWS Price List API / AWS 公式料金ページから取得してください

## 1. 1環境あたりの主要リソース一覧

| No | サービス | リソース | 数量 | 単位 | 単価 (USD) | 月額 (USD) | 備考 |
| :---: | :---- | :---- | ----: | :---: | ----: | ----: | :---- |
| 1 | EC2 | `aws_instance.ec2_bastion` | 1 | 台 | 0.0050 / 時間 | | `t4g.nano`、730時間稼働 |
| 2 | EIP | `aws_eip.ec2_bastion` | 1 | 個 | 0.00 / 時間 | | Bastion に割り当て済みなら通常無料 |
| 3 | NAT Gateway | `aws_nat_gateway.main` | 3 | 台 | 0.0650 / 時間 | | `ap-northeast-1`、730時間 |
| 4 | EIP | `aws_eip.main` | 3 | 個 | 0.0050 / 時間 | | NAT Gateway 用 |
| 5 | VPC Endpoint | `aws_vpc_endpoint.s3_gateway` | 1 | 件 | 0.00 | | S3 Gateway エンドポイントは無料 |
| 6 | Aurora Serverless v2 | `aws_rds_cluster.aurora_postgres` | 1 | クラスター | 0.00 | | |
| 7 | Aurora Serverless v2 | `aws_rds_cluster_instance.aurora_postgres_instance` | 2 | インスタンス | 0.1100 / ACU-時間 | | `db.serverless`、`min_capacity=0.5`〜`max_capacity=2.0` |
| 8 | CloudFront | `aws_cloudfront_distribution.main` | 1 | 配信 | 0.00 | | 設定自体は固定費なし。リクエスト/転送は別途見積もり |
| 9 | CloudFront | `aws_cloudfront_function.main` | 1 | 関数 | 0.10 / 100万件 | | リクエスト数に応じた課金 |
| 10 | CloudFront | `aws_cloudfront_key_value_store.main` | 1 | KVストア | 0.00 | | 使用量に応じた別途課金が必要な場合あり |
| 11 | API Gateway | `aws_api_gateway_rest_api.response_api` | 1 | API | 0.0220 / 時間 | | REST API のエンドポイント時間課金 |
| 12 | API Gateway | `aws_api_gateway_stage.response_api_stage` | 1 | ステージ | 0.00 | | ステージ設定自体は固定費なし |
| 13 | Kinesis Firehose | `aws_kinesis_firehose_delivery_stream.*` | 7 | ストリーム | 0.0290 / 時間 | | データ転送・変換は別途費用 |
| 14 | Lambda | `aws_lambda_function.*` | 4 | 関数 | 0.00001667 / GB-秒 | | 1Mリクエストあたり0.20 USD も追加 |
| 15 | CloudWatch Logs | `aws_cloudwatch_log_group.*` | 6 | Log Group | 0.03 / GB-月 | | 保存容量・取り出し等は別途見積もり |
| 16 | S3 | `aws_s3_bucket.*` | 12 | バケット | 0.0240 / GB-月 | | ストレージ容量・リクエスト・転送別 |
| 17 | KMS | `aws_kms_key.*` | 3 | キー | 1.00 / キー-月 | | |
| 18 | ACM | `aws_acm_certificate.*` | 2 | 証明書 | 0.00 | 0.00 | ACM証明書は通常無料 |
| 19 | Route 53 | `aws_route53_zone.main` | 1 | ゾーン | 0.50 / ゾーン-月 | | |
| 20 | Route 53 | `aws_route53_record.*` | 4 | レコード | 0.00 | | レコードセット自体は固定費なし |
| 21 | WAF | `aws_wafv2_web_acl.main` | 1 | Web ACL | 5.00 / ACL-月 | | ルール数に応じた追加料金が発生する場合あり |
| 22 | RDS Subnet Group | `aws_db_subnet_group.aurora_postgres` | 1 | | 0.00 | | 管理リソース |

## 2. Audit環境（1アカウントあたり）

| No | サービス | リソース | 数量 | 単位 | 単価 (USD) | 月額 (USD) | 備考 |
| :---: | :---- | :---- | ----: | :---: | ----: | ----: | :---- |
| 1 | CloudTrail | `aws_cloudtrail.audit` / `aws_cloudtrail.audit_osaka` / `aws_cloudtrail.audit_global` | 3 | トレイル | 0.00 | | 管理イベントは一定量まで無料。ログストレージ・イベント量別課金 |
| 2 | S3 | `aws_s3_bucket.*` | 8 | バケット | 0.0240 / GB-月 | | ログ保存容量・リクエスト・転送別 |
| 3 | CloudWatch Logs | `aws_cloudwatch_log_group.*` | 9 | Log Group | 0.03 / GB-月 | | 保存容量・取り出し等は別途見積もり |
| 4 | GuardDuty | `aws_guardduty_detector.main` | 1 | 検出器 | 4.00 / GB analyzed | | 解析データ量に応じた課金 |
| 5 | Inspector2 | `aws_inspector2_enabler.*` | 2 | エネーブル | 0.00 | | 使用量ベースで別途課金が発生する可能性あり |
| 6 | AWS Config | `aws_config_configuration_recorder.*` | 2 | レコーダー | 0.00 | | 構成アイテム数・ルール数別課金 |
| 7 | AWS Config | `aws_config_config_rule.*` | 5 | ルール | 2.00 / ルール-月 | | |
| 8 | Lambda | `aws_lambda_function.*` | 5 | 関数 | 0.00001667 / GB-秒 | | 1Mリクエストあたり0.20 USD も追加 |
| 9 | SNS | `aws_sns_topic.*` | 3 | トピック | 0.00 | | トピック自体は無料。メッセージ配信は別途課金 |
| 10 | KMS | `aws_kms_key.*` | 2 | キー | 1.00 / キー-月 | | |
| 11 | CloudFormation | `aws_cloudformation_stack.*` | 2 | スタック | 0.00 | | 管理リソース |

## 3. 計算の考え方

- 730時間ベースで価格を算出するリソース
  - EC2、NAT Gateway、その他時間課金リソース
- Aurora Serverless v2
  - `serverlessv2_scaling_configuration` により ACU で課金
  - 実際のコストは平均 ACU 量に依存するため、利用想定値を用いて計算する必要があります
- ストレージ・ログ・転送は利用量想定が必要
  - S3 容量、PUT/GET リクエスト、データ転送
  - CloudWatch Logs 保存容量 / データ量
  - CloudFront データ転送・リクエスト数
  - API Gateway リクエスト数
  - Firehose 転送量
- サービス単価は AWS 公式料金を参照し、USD で入力してください

## 4. 使い方

1. `単価 (USD)` に AWS 公式料金を入力する
2. `月額 (USD)` に数量 × 単価を計算する
3. 必要に応じて、利用量想定を補完する
   - 例: S3 ストレージ GB、CloudFront 帯域 GB、API Gateway リクエスト数
4. `develop` / `staging` / `production` は同じ構成なので、1環境分の集計をコピーして環境数分を合算する

## 5. 補足

- `aws_acm_certificate` は通常無料のため単価を `0.00` に設定しています
- `aws_route53_zone` はホストゾーン月額が発生します
- `aws_rds_cluster_instance` は Serverless のため、インスタンス時間ではなく ACU 時間での見積もりが必要です
- `audit` 環境はセキュリティ・監査系の別アカウント向け構成として別途見積もりしてください

## 5. 精度向上の手段

- `infracost` を用いて Terraform から自動で見積を生成することを推奨します。

```bash
brew install infracost
cd develop
infracost breakdown --path .
```

---

最終更新: 2026-06-05
