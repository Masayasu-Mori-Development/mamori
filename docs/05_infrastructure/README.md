# インフラ設計

AWSインフラストラクチャの設計書を管理するディレクトリです。

## ファイル構成

- **infrastructure-overview.md**: インフラ全体構成とアーキテクチャ図
- **network-design.md**: VPC、サブネット、セキュリティグループ設計
- **compute-design.md**: ECS/EC2の構成とオートスケーリング設計
- **database-design.md**: RDS（PostgreSQL）の構成とバックアップ設計
- **storage-design.md**: S3バケット構成とライフサイクルポリシー
- **cdn-design.md**: CloudFrontの設定とキャッシュ戦略
- **monitoring-design.md**: CloudWatch監視設計とアラート設定
- **disaster-recovery.md**: 障害対応手順とバックアップ戦略

## 環境構成

| 環境 | 用途 | AWS アカウント | リージョン |
|------|------|---------------|-----------|
| **dev** | 開発環境 | 開発用アカウント | ap-northeast-1（東京） |
| **staging** | ステージング環境 | 本番用アカウント | ap-northeast-1（東京） |
| **production** | 本番環境 | 本番用アカウント | ap-northeast-1（東京） |

## Terraform構成

インフラのコード化（IaC）はTerraformで管理します。

```
infra/terraform/
├── modules/              # 再利用可能モジュール
│   ├── network/         # VPC、サブネット
│   ├── compute/         # ECS、ALB
│   ├── database/        # RDS
│   └── storage/         # S3
└── environments/        # 環境別設定
    ├── dev/
    ├── staging/
    └── production/
```

## 主要AWSサービス

| サービス | 用途 |
|---------|------|
| **ECS Fargate** | コンテナ実行環境 |
| **RDS PostgreSQL** | データベース |
| **S3** | ファイルストレージ、静的ファイル配信 |
| **CloudFront** | CDN |
| **Route 53** | DNS管理 |
| **ALB** | ロードバランサー |
| **CloudWatch** | 監視・ログ管理 |
| **Secrets Manager** | 機密情報管理 |

## セキュリティ設計

- **VPC分離**: 各環境は独立したVPCで管理
- **プライベートサブネット**: データベースは外部アクセス不可
- **IAMロール**: 最小権限の原則に基づいたロール設計
- **暗号化**: データベース、S3バケットは暗号化必須
- **HTTPSのみ**: 全通信をHTTPS/TLSで暗号化

## 更新ルール

1. **インフラ変更前に設計書を更新**: Terraform適用前に必ずドキュメント化
2. **変更理由を記載**: Why（なぜその構成にしたか）を必ず記載
3. **コスト試算**: 大きな変更時はコスト影響を記載
4. **ロールバック手順**: 変更時は必ずロールバック手順も記載
