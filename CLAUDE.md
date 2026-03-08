# まもり保育ごはん（Mamori）- Claude Code プロジェクト指示書

## プロジェクト概要

**まもり保育ごはん（Mamori）** は、保育施設向けの監査対応帳票を効率化するWeb SaaSです。

### ビジョン

- 給食業務のDX化
- 監査対応の標準化
- 将来的に給食市場全体（介護・病院・学校・社員食堂）へ展開（まもり◯◯ごはんシリーズ）

### MVPスコープ

- 献立入力
- 栄養計算
- 横浜市帳票PDF出力
- 最低限の施設管理

### 技術スタック

- **フロントエンド**: React + TypeScript（Vite）
- **バックエンド**: Spring Boot 3.x + Kotlin
- **データベース**: PostgreSQL（Schema分離: core / hoiku）
- **クラウドインフラ**: AWS（ECS, RDS, S3, CloudFront）
- **IaC**: Terraform
- **モノレポ構成**: core-backend / hoiku-backend / hoiku-frontend

## アーキテクチャ思想

### Core と Hoiku の分離

- **core-backend**: 認証・ユーザー管理・テナント管理・権限管理・帳票エンジン基盤（共通機能）
- **hoiku-backend**: 保育施設特化機能（献立、栄養計算、保育帳票）
- **hoiku-frontend**: 保育施設向け画面

### マルチテナント設計

- 全業務テーブルに `tenant_id` 必須
- 複数の保育施設（法人）が同一DBを共有
- 将来的に大口顧客のみDB分離も可能な設計

### BFF（Backend For Frontend）思想

- hoiku-frontendは `/api/hoiku/*` のみアクセス
- admin-frontendは `/api/core/*` のみアクセス（将来）
- coreロジックはhoiku-backendから内部ライブラリとして利用可能

### 認証設計

- 認証はcore-backendで一元管理
- JWT発行はcore-backendが担当
- hoiku-backendはJWT検証のみ実施

## ディレクトリ構造

```
mamori/
├── .claude/              # Claude Code設定
│   ├── settings.json     # プロジェクト固有の設定
│   └── rules/            # パス固有のルール
├── CLAUDE.md             # このファイル（プロジェクト指示書）
├── README.md             # プロジェクトドキュメント
├── .gitignore            # Git除外設定
├── initial_doc.txt       # 初期設計ドキュメント（ChatGPTとの会話まとめ）
├── core-backend/         # Spring Boot Kotlin（認証・共通機能）
│   ├── src/
│   │   ├── main/kotlin/com/mamori/core/
│   │   │   ├── controller/    # REST API
│   │   │   ├── service/       # ビジネスロジック
│   │   │   ├── repository/    # データアクセス
│   │   │   ├── domain/        # エンティティ・DTO
│   │   │   ├── config/        # 設定クラス
│   │   │   ├── security/      # 認証・認可
│   │   │   └── exception/     # 例外ハンドリング
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/  # Flyway（coreスキーマ）
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── hoiku-backend/        # Spring Boot Kotlin（保育特化機能）
│   ├── src/
│   │   ├── main/kotlin/com/mamori/hoiku/
│   │   │   ├── controller/    # 保育向けREST API
│   │   │   ├── service/       # 献立・栄養計算ロジック
│   │   │   ├── repository/    # 保育データアクセス
│   │   │   ├── domain/        # 保育エンティティ・DTO
│   │   │   └── config/        # 保育設定
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/  # Flyway（hoikuスキーマ）
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── hoiku-frontend/       # React + TypeScript
│   ├── src/
│   │   ├── components/   # UIコンポーネント
│   │   ├── pages/        # ページコンポーネント
│   │   ├── hooks/        # カスタムフック
│   │   ├── services/     # APIクライアント
│   │   └── types/        # TypeScript型定義
│   ├── public/
│   ├── package.json
│   └── vite.config.ts
└── infra/                # AWSインフラ設定
    └── terraform/
        ├── modules/      # 再利用可能モジュール
        └── environments/ # 環境別設定（dev/staging/prod）
```

## ドメインモデル

### Core（共通）

- **Organization**: 法人・組織
- **Facility**: 施設（保育園、介護施設など）
- **User**: ユーザー
- **Role**: 役割・権限
- **Tenant**: テナント情報

### Hoiku（保育特化）

- **Menu**: 献立
- **Ingredient**: 食材
- **NutritionStandard**: 栄養基準
- **ReportTemplate**: 帳票テンプレート（自治体別）

## PostgreSQL Schema設計

詳細なデータベース設計原則・マイグレーション規則は @.claude/rules/database-design.md を参照してください。

### Schema分離

```sql
-- 共通機能
core.organizations
core.facilities
core.users
core.roles
core.tenants

-- 保育特化機能
hoiku.menus
hoiku.ingredients
hoiku.nutrition_standards
hoiku.report_templates
```

### マルチテナント原則

全業務テーブルに以下カラムを必須とする:

- `tenant_id`: テナントID（UUID）
- `created_at`: 作成日時
- `updated_at`: 更新日時
- `created_by`: 作成者
- `updated_by`: 更新者

## コーディング規約

詳細なコーディング規約は以下のファイルを参照してください：

@.claude/rules/coding-standards.md

### インフラ（AWS）

- **IaC**: Terraform
- **環境分離**: dev / staging / production
- **主要サービス**:
  - Compute: ECS Fargate または EC2
  - Database: RDS（PostgreSQL）
  - Storage: S3
  - CDN: CloudFront
  - DNS: Route 53
  - 認証: Cognito（オプション）

## セキュリティ要件

- **機密情報管理**:
  - `.env`ファイルはGitにコミットしない
  - AWS認証情報はIAMロール/環境変数で管理
  - API キーは AWS Secrets Manager に保存
- **脆弱性対策**:
  - XSS対策: 入力値のエスケープ処理
  - CSRF対策: トークン検証
  - SQLインジェクション対策: プリペアドステートメント使用
  - 認証/認可: JWT + HTTPSのみ通信
- **依存関係**: 定期的な脆弱性スキャン（Dependabot/Snyk）

## API設計

詳細なAPI設計原則は以下のファイルを参照してください：

@.claude/rules/api-design.md

### エンドポイント構成

```
/api/core/*   → core-backend（認証・テナント管理など）
/api/hoiku/*  → hoiku-backend（献立・栄養計算など）
```

## ビルド・実行コマンド

### Core Backend

```bash
cd core-backend
./gradlew build       # ビルド
./gradlew test        # テスト実行
./gradlew bootRun     # アプリケーション起動（ポート: 8080）
./gradlew clean       # クリーン
```

### Hoiku Backend

```bash
cd hoiku-backend
./gradlew build       # ビルド
./gradlew test        # テスト実行
./gradlew bootRun     # アプリケーション起動（ポート: 8081）
./gradlew clean       # クリーン
```

### Hoiku Frontend

```bash
cd hoiku-frontend
npm install           # 依存関係インストール
npm run dev           # 開発サーバー起動（ポート: 3000）
npm run build         # 本番ビルド
npm run test          # テスト実行
npm run lint          # Lint チェック
```

### インフラ

```bash
cd infra/terraform
terraform init        # 初期化
terraform plan        # 実行計画確認
terraform apply       # インフラ適用
terraform destroy     # インフラ削除
```

## 開発ワークフロー

1. **ブランチ戦略**: Git Flow
   - `main`: 本番環境
   - `develop`: 開発環境
   - `feature/*`: 機能開発
   - `hotfix/*`: 緊急修正

2. **コミットメッセージ**: Conventional Commits
   - `feat:` 新機能
   - `fix:` バグ修正
   - `docs:` ドキュメント変更
   - `refactor:` リファクタリング
   - `test:` テスト追加/修正
   - `chore:` ビルド・設定変更

3. **CI/CD**: GitHub Actions
   - プルリクエスト作成時: Lint + テスト実行
   - マージ時: ビルド + デプロイ

## データベース設計

詳細なデータベース設計原則は以下のファイルを参照してください：

@.claude/rules/database-design.md

## テスト方針

- **単体テスト**: カバレッジ80%以上を目標
- **統合テスト**: 主要なユーザーフローをカバー
- **E2Eテスト**: クリティカルパスのみ実装（Cypress/Playwright）
- **テストデータ**: Fixtureを使用して管理

## パフォーマンス要件

- **フロントエンド**:
  - First Contentful Paint < 1.5秒
  - Time to Interactive < 3秒
  - Lighthouse スコア90以上
- **バックエンド**:
  - API レスポンスタイム < 200ms（95パーセンタイル）
  - データベースクエリ最適化（N+1問題の回避）

## モニタリング・ログ

- **ログレベル**: ERROR / WARN / INFO / DEBUG
- **ログ出力**: JSON形式（構造化ログ）
- **監視**: CloudWatch / CloudWatch Logs
- **アラート**: エラー率、レスポンスタイム、リソース使用率

## ドキュメント管理

### 設計書・仕様書の管理

**全てのドキュメントはGit管理対象**です。`docs/` ディレクトリ配下に体系的に管理されています。

#### ドキュメント構成

```
docs/
├── 01_requirements/        # 要件定義
├── 02_design/              # システム設計
├── 03_database/            # データベース設計
├── 04_api/                 # API設計
├── 05_infrastructure/      # インフラ設計
├── 06_testing/             # テスト仕様
└── 07_operations/          # 運用設計
```

#### ドキュメント管理原則

1. **Markdown形式で記述**: バージョン管理に適し、GitHub上で読みやすい
2. **実装と同期**: 機能追加・変更時は必ずドキュメントも更新
3. **Why（なぜ）を重視**: 設計判断の理由を必ず記載
4. **将来の開発者が理解できる**: 事業売却時の引き継ぎを想定

詳細は [docs/README.md](./docs/README.md) を参照してください。

### API仕様

- **OpenAPI（Swagger）**: 自動生成
  - Core Backend: `http://localhost:8080/swagger-ui.html`
  - Hoiku Backend: `http://localhost:8081/swagger-ui.html`
- **API設計書**: `docs/04_api/` 配下に手動で作成

### アーキテクチャ図

- **ツール**: Mermaid（テキストベース）、Draw.io（複雑な図）
- **保存場所**: 各設計書に埋め込み、または `docs/assets/` に画像として保存

### コードコメント

- 複雑なロジックには必ず日本語で説明を記載
- ビジネスルールは Why（なぜそうするか）を記載

## 注意事項

- コードレビューは必須（1名以上の承認が必要）
- **ドキュメントレビューも必須**: 実装とドキュメントの整合性を確認
- 機密情報（パスワード、API キー）は絶対にコミットしない
- 本番環境へのデプロイは必ず事前にステージング環境で検証
- 破壊的変更は必ず移行計画とロールバック手順を用意
