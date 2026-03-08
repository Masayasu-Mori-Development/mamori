# まもり保育ごはん（Mamori）

保育施設向けの監査対応帳票を効率化するWeb SaaSです。

## ビジョン

- 給食業務のDX化
- 監査対応の標準化
- 全国展開（47都道府県対応）
- 将来的に給食市場全体（介護・病院・学校）へ展開（まもり◯◯ごはんシリーズ）

## MVPスコープ

- 献立入力
- 栄養計算
- 横浜市帳票PDF出力（全国対応の基盤設計）
- 施設管理・本部機能
- 運営管理機能

## 目次

- [技術スタック](#技術スタック)
- [プロジェクト構成](#プロジェクト構成)
- [前提条件](#前提条件)
- [セットアップ](#セットアップ)
- [開発ガイド](#開発ガイド)
- [デプロイ](#デプロイ)
- [トラブルシューティング](#トラブルシューティング)

## 技術スタック

### フロントエンド
- **フレームワーク**: React 18+
- **言語**: TypeScript
- **状態管理**: Context API / Redux Toolkit
- **スタイリング**: CSS Modules / styled-components
- **テスト**: Jest + React Testing Library
- **ビルドツール**: Vite / Create React App

### バックエンド
- **フレームワーク**: Spring Boot 3.x
- **言語**: Kotlin 1.9+
- **ビルドツール**: Gradle (Kotlin DSL)
- **データベース**: PostgreSQL
- **ORM**: Spring Data JPA
- **認証**: Spring Security + JWT
- **API仕様**: OpenAPI (Swagger)

### インフラ
- **クラウド**: AWS
- **IaC**: Terraform
- **コンテナ**: Docker
- **CI/CD**: GitHub Actions

### アーキテクチャ

- **Core と Hoiku の分離**: 認証・共通機能（core-backend）と保育特化機能（hoiku-backend）を分離
- **マルチテナント設計**: 全テーブルに `tenant_id` 必須
- **PostgreSQL Schema分離**: `core.*` と `hoiku.*`
- **BFF思想**: hoiku-frontendは `/api/hoiku/*` のみアクセス

## プロジェクト構成

```
mamori/
├── .claude/              # Claude Code設定
│   ├── settings.json     # プロジェクト固有設定
│   └── rules/            # パス固有ルール
├── core-backend/         # Spring Boot Kotlin（認証・共通機能）
│   ├── src/
│   │   ├── main/kotlin/com/mamori/core/
│   │   │   ├── controller/    # REST API
│   │   │   ├── service/       # ビジネスロジック
│   │   │   ├── repository/    # データアクセス
│   │   │   ├── domain/        # エンティティ・DTO
│   │   │   ├── security/      # 認証・認可
│   │   │   └── config/        # 設定クラス
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/  # Flyway（coreスキーマ）
│   ├── build.gradle.kts
│   └── gradlew
├── hoiku-backend/        # Spring Boot Kotlin（保育特化機能）
│   ├── src/
│   │   ├── main/kotlin/com/mamori/hoiku/
│   │   │   ├── controller/    # 保育向けREST API
│   │   │   ├── service/       # 献立・栄養計算ロジック
│   │   │   ├── repository/    # 保育データアクセス
│   │   │   └── domain/        # 保育エンティティ・DTO
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/  # Flyway（hoikuスキーマ）
│   ├── build.gradle.kts
│   └── gradlew
├── admin-backend/        # Spring Boot Kotlin（運営管理機能）★NEW
│   ├── src/
│   │   ├── main/kotlin/com/mamori/admin/
│   │   │   ├── controller/    # 運営向けREST API
│   │   │   ├── service/       # テナント管理・マスタデータ管理
│   │   │   ├── repository/    # 運営データアクセス
│   │   │   ├── security/      # 運営認証（MFA対応）
│   │   │   └── domain/        # 運営エンティティ・DTO
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/  # Flyway（adminスキーマ）
│   ├── build.gradle.kts
│   └── gradlew
├── hoiku-frontend/       # React + TypeScript（顧客向け）
│   ├── src/
│   │   ├── components/   # UIコンポーネント
│   │   ├── pages/        # ページコンポーネント
│   │   ├── hooks/        # カスタムフック
│   │   ├── contexts/     # Contextプロバイダー
│   │   ├── services/     # APIクライアント
│   │   ├── utils/        # ユーティリティ関数
│   │   └── types/        # TypeScript型定義
│   ├── public/           # 静的ファイル
│   └── package.json
├── admin-frontend/       # React + TypeScript（運営管理画面）★NEW
│   ├── src/
│   │   ├── components/   # 管理画面UIコンポーネント
│   │   ├── pages/        # 管理画面ページ
│   │   ├── hooks/        # カスタムフック
│   │   ├── services/     # 運営APIクライアント
│   │   └── types/        # TypeScript型定義
│   ├── public/
│   └── package.json
├── infra/                # インフラ定義
│   └── terraform/
│       ├── modules/      # 再利用可能モジュール
│       └── environments/ # 環境別設定
│           ├── dev/
│           ├── staging/
│           └── prod/
├── docs/                 # 設計書・仕様書
│   ├── 01_requirements/  # 要件定義
│   ├── 02_design/        # システム設計
│   ├── 03_database/      # データベース設計
│   ├── 04_api/           # API設計
│   ├── 05_infrastructure/# インフラ設計
│   ├── 06_testing/       # テスト仕様
│   ├── 07_operations/    # 運用設計
│   └── 08_claude/        # Claude Code設定
├── CLAUDE.md             # Claude Code プロジェクト指示書
├── README.md             # このファイル
└── .gitignore
```

## 前提条件

開発を始める前に、以下のツールをインストールしてください。

### 必須
- **Node.js**: v18以上（推奨: v20 LTS）
- **npm**: v9以上
- **Java**: JDK 17以上（推奨: Amazon Corretto 17）
- **Gradle**: 8.x（Gradle Wrapperを使用するため不要）
- **PostgreSQL**: 14以上
- **Docker**: 20.x以上（任意だが推奨）
- **AWS CLI**: v2（デプロイ時）
- **Terraform**: v1.5以上（インフラ構築時）

### 推奨
- **Git**: 2.x以上
- **IDE**: IntelliJ IDEA / VS Code

## セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd mamori
```

### 2. PostgreSQLの準備

Dockerを使用する場合:
```bash
docker run --name mamori-postgres \
  -e POSTGRES_DB=mamori \
  -e POSTGRES_USER=mamori_user \
  -e POSTGRES_PASSWORD=mamori_pass \
  -p 5432:5432 \
  -d postgres:14

# core、hoiku、adminスキーマの作成
docker exec -it mamori-postgres psql -U mamori_user -d mamori -c "CREATE SCHEMA IF NOT EXISTS core;"
docker exec -it mamori-postgres psql -U mamori_user -d mamori -c "CREATE SCHEMA IF NOT EXISTS hoiku;"
docker exec -it mamori-postgres psql -U mamori_user -d mamori -c "CREATE SCHEMA IF NOT EXISTS admin;"
```

ローカルにインストールする場合:
```bash
# PostgreSQLに接続してデータベースとスキーマを作成
psql -U postgres
CREATE DATABASE mamori;
CREATE USER mamori_user WITH PASSWORD 'mamori_pass';
GRANT ALL PRIVILEGES ON DATABASE mamori TO mamori_user;

# mamoriデータベースに接続してスキーマを作成
\c mamori
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS hoiku;
CREATE SCHEMA IF NOT EXISTS admin;
GRANT ALL ON SCHEMA core TO mamori_user;
GRANT ALL ON SCHEMA hoiku TO mamori_user;
GRANT ALL ON SCHEMA admin TO mamori_user;
```

### 3. Core Backend のセットアップ

```bash
cd core-backend

# 環境変数の設定
cp src/main/resources/application-local.yml.example src/main/resources/application-local.yml
# application-local.ymlを編集してDB接続情報を設定

# ビルド
./gradlew build

# アプリケーション起動（ポート: 8080）
./gradlew bootRun --args='--spring.profiles.active=local'
```

### 4. Hoiku Backend のセットアップ

```bash
cd hoiku-backend

# 環境変数の設定
cp src/main/resources/application-local.yml.example src/main/resources/application-local.yml
# application-local.ymlを編集してDB接続情報を設定

# ビルド
./gradlew build

# アプリケーション起動（ポート: 8081）
./gradlew bootRun --args='--spring.profiles.active=local'
```

### 5. Hoiku Frontend のセットアップ

```bash
cd hoiku-frontend

# 依存関係のインストール
npm install

# 環境変数の設定
cp .env.example .env
# .envを編集してAPI URLなどを設定

# 開発サーバー起動（ポート: 3000）
npm run dev
```

### 6. 動作確認

- **Hoiku Frontend**: `http://localhost:3000`
- **Core Backend API**: `http://localhost:8080/api/core/health`
- **Core Backend Swagger**: `http://localhost:8080/swagger-ui.html`
- **Hoiku Backend API**: `http://localhost:8081/api/hoiku/health`
- **Hoiku Backend Swagger**: `http://localhost:8081/swagger-ui.html`

## 開発ガイド

### ブランチ戦略

Git Flowを採用しています。

- `main`: 本番環境（プロテクトブランチ）
- `develop`: 開発環境（プロテクトブランチ）
- `feature/*`: 機能開発
- `hotfix/*`: 緊急修正

#### 新機能の開発手順

```bash
# developブランチから新機能ブランチを作成
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# 開発・コミット
git add .
git commit -m "feat: 新機能の説明"

# プルリクエスト作成
git push origin feature/your-feature-name
```

### コミットメッセージ規約

Conventional Commitsを採用しています。

- `feat:` 新機能
- `fix:` バグ修正
- `docs:` ドキュメント変更
- `style:` コードスタイル修正（動作に影響なし）
- `refactor:` リファクタリング
- `test:` テスト追加・修正
- `chore:` ビルド設定、依存関係更新など

例:
```bash
git commit -m "feat: ユーザー登録機能を追加"
git commit -m "fix: ログイン時のエラーハンドリングを修正"
```

### テストの実行

#### フロントエンド

```bash
cd frontend
npm run test              # 単体テスト
npm run test:coverage     # カバレッジ付き
npm run test:e2e          # E2Eテスト（Cypress/Playwright）
```

#### バックエンド

```bash
cd backend
./gradlew test            # 単体テスト
./gradlew integrationTest # 統合テスト
./gradlew jacocoTestReport # カバレッジレポート生成
```

### コードフォーマット

#### フロントエンド

```bash
cd frontend
npm run lint              # Lintチェック
npm run lint:fix          # 自動修正
npm run format            # Prettier実行
```

#### バックエンド

```bash
cd backend
./gradlew ktlintCheck     # Kotlin Lintチェック
./gradlew ktlintFormat    # 自動修正
```

### APIの開発

1. **エンティティの定義**: `backend/src/main/kotlin/com/mamori/domain/entity/`
2. **DTOの作成**: `backend/src/main/kotlin/com/mamori/domain/dto/`
3. **リポジトリの実装**: `backend/src/main/kotlin/com/mamori/repository/`
4. **サービスの実装**: `backend/src/main/kotlin/com/mamori/service/`
5. **コントローラーの実装**: `backend/src/main/kotlin/com/mamori/controller/`
6. **テストの作成**: `backend/src/test/kotlin/`

OpenAPI仕様は自動生成されます: `http://localhost:8080/v3/api-docs`

## デプロイ

### インフラのプロビジョニング

```bash
cd infra/terraform/environments/dev

# 初期化
terraform init

# 実行計画の確認
terraform plan

# インフラの作成
terraform apply
```

### CI/CDパイプライン

GitHub Actionsで自動デプロイが設定されています。

- **Pull Request作成時**: Lint + テスト実行
- **developブランチへのマージ**: 開発環境へ自動デプロイ
- **mainブランチへのマージ**: 本番環境へ自動デプロイ

手動デプロイ:
```bash
# フロントエンド
cd frontend
npm run build
# S3へアップロード、CloudFront無効化

# バックエンド
cd backend
./gradlew bootJar
# ECS/EC2へデプロイ
```

## トラブルシューティング

### フロントエンドが起動しない

1. Node.jsのバージョン確認: `node --version`（v18以上）
2. 依存関係の再インストール: `rm -rf node_modules package-lock.json && npm install`
3. ポート3000が使用中: `.env`で`PORT=3001`に変更

### バックエンドが起動しない

1. Javaのバージョン確認: `java --version`（JDK 17以上）
2. PostgreSQLの接続確認: `psql -U mamori_user -d mamori`
3. ビルドのクリーン: `./gradlew clean build`
4. ポート8080が使用中: `application-local.yml`で`server.port`を変更

### データベース接続エラー

1. PostgreSQLが起動しているか確認: `docker ps`（Dockerの場合）
2. 接続情報の確認: `application-local.yml`
3. ファイアウォール設定の確認

### テストが失敗する

1. テストデータベースの初期化: `./gradlew clean`
2. 最新のコードに更新: `git pull origin develop`
3. 依存関係の更新: `npm install` / `./gradlew build --refresh-dependencies`

## Claude Codeとの連携

このプロジェクトは[Claude Code](https://claude.ai/claude-code)に最適化されています。

- **CLAUDE.md**: プロジェクトの指示書（コーディング規約、アーキテクチャ情報）
- **.claude/settings.json**: 機密情報の保護設定
- **.claude/rules/**: パス固有のルール（必要に応じて追加）

Claude Codeを使用することで、コードレビュー、バグ修正、新機能実装を効率的に行えます。

## ライセンス

このプロジェクトは非公開です。無断での複製・配布を禁止します。

## お問い合わせ

プロジェクトに関する質問は、開発チームまでお問い合わせください。
