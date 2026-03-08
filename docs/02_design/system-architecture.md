# システムアーキテクチャ設計書

## ドキュメント情報

| 項目 | 内容 |
|------|------|
| ドキュメント名 | システムアーキテクチャ設計書 |
| バージョン | 1.0.0 |
| 最終更新日 | 2026-03-08 |
| ステータス | テンプレート |

## 1. システム全体像

### 1.1. アーキテクチャ図

```mermaid
graph TB
    subgraph "ユーザー"
        U1[栄養士]
        U2[施設管理者]
    end

    subgraph "フロントエンド"
        HF[hoiku-frontend<br/>React + TypeScript<br/>Port: 3000]
    end

    subgraph "バックエンド"
        CB[core-backend<br/>Spring Boot + Kotlin<br/>Port: 8080<br/>/api/core/*]
        HB[hoiku-backend<br/>Spring Boot + Kotlin<br/>Port: 8081<br/>/api/hoiku/*]
    end

    subgraph "データストア"
        DB[(PostgreSQL<br/>core schema<br/>hoiku schema)]
        S3[S3<br/>PDF帳票]
    end

    U1 --> HF
    U2 --> HF
    HF -->|認証| CB
    HF -->|献立・帳票| HB
    CB --> DB
    HB --> DB
    HB --> S3
```

### 1.2. 主要コンポーネント

| コンポーネント | 役割 | 技術スタック |
|--------------|------|-------------|
| hoiku-frontend | 保育施設向けUI | React 18, TypeScript, Vite |
| core-backend | 認証・共通機能 | Spring Boot 3.2, Kotlin 1.9 |
| hoiku-backend | 保育特化機能 | Spring Boot 3.2, Kotlin 1.9 |
| PostgreSQL | データベース | PostgreSQL 14+ |
| S3 | ファイルストレージ | AWS S3 |

## 2. 技術選定

### 2.1. フロントエンド

#### React + TypeScript

**選定理由**:
- コンポーネントベースで再利用性が高い
- TypeScriptによる型安全性
- 豊富なエコシステムとライブラリ
- 学習コストが低く、採用が容易

**代替案との比較**:
- Vue.js: Reactより採用実績が多い
- Next.js: SSRが不要なためオーバースペック

#### Vite

**選定理由**:
- 高速なビルドとHMR（Hot Module Replacement）
- モダンな開発体験
- 軽量で設定がシンプル

### 2.2. バックエンド

#### Spring Boot + Kotlin

**選定理由**:
- エンタープライズ向けの豊富な機能
- Kotlinのnull安全性とシンプルな構文
- JVMエコシステムの恩恵
- Spring Securityによる堅牢な認証・認可

**代替案との比較**:
- Go: パフォーマンスは優れるが、エコシステムが限定的
- Node.js (Express): JavaScriptの型安全性に課題

#### Gradle (Kotlin DSL)

**選定理由**:
- Kotlin DSLによる型安全なビルド設定
- Spring Bootとの親和性
- 柔軟な依存関係管理

### 2.3. データベース

#### PostgreSQL

**選定理由**:
- Schema分離機能が強力
- JSONB型でテンプレート管理が柔軟
- 高い信頼性と実績
- AWS RDSでマネージド運用可能

**Schema分離の利点**:
- `core.*` と `hoiku.*` で責任を明確化
- 将来的なDB分離が容易
- 権限管理がSchema単位で可能

### 2.4. インフラ

#### AWS

**選定理由**:
- 豊富なマネージドサービス
- スケーラビリティとグローバル展開
- セキュリティ機能の充実
- 実績と信頼性

**主要サービス**:
- ECS Fargate: コンテナ実行環境（サーバーレス）
- RDS: PostgreSQL マネージドサービス
- S3: オブジェクトストレージ（PDF帳票）
- CloudFront: CDN（フロントエンド配信）
- ALB: ロードバランサー

## 3. レイヤードアーキテクチャ

### 3.1. バックエンド構成（Spring Boot）

```
┌─────────────────────────────────┐
│      Controller 層              │  REST API、リクエスト/レスポンス処理
├─────────────────────────────────┤
│      Service 層                 │  ビジネスロジック、トランザクション管理
├─────────────────────────────────┤
│      Repository 層              │  データアクセス、Spring Data JPA
├─────────────────────────────────┤
│      Domain 層                  │  エンティティ、DTO、バリューオブジェクト
└─────────────────────────────────┘
```

#### 各層の責任

| 層 | 責任 | 例 |
|----|------|-----|
| Controller | HTTPリクエストの受付、レスポンス返却 | MenuController |
| Service | ビジネスロジックの実装 | MenuService, NutritionCalculationService |
| Repository | データベースアクセス | MenuRepository |
| Domain | データ構造の定義 | MenuEntity, MenuRequest, MenuResponse |

### 3.2. フロントエンド構成（React）

```
┌─────────────────────────────────┐
│      Pages                      │  ページコンポーネント（ルーティング）
├─────────────────────────────────┤
│      Components                 │  UIコンポーネント（再利用可能）
├─────────────────────────────────┤
│      Hooks                      │  カスタムフック（ロジック分離）
├─────────────────────────────────┤
│      Services                   │  API通信、外部連携
├─────────────────────────────────┤
│      Types                      │  TypeScript型定義
└─────────────────────────────────┘
```

## 4. データフロー

### 4.1. 認証フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant Frontend as hoiku-frontend
    participant CoreAPI as core-backend
    participant DB as PostgreSQL

    User->>Frontend: ログインフォーム入力
    Frontend->>CoreAPI: POST /api/core/auth/login
    CoreAPI->>DB: ユーザー認証（core.users）
    DB-->>CoreAPI: ユーザー情報
    CoreAPI->>CoreAPI: JWT生成
    CoreAPI-->>Frontend: JWT トークン
    Frontend->>Frontend: トークン保存（localStorage）
    Frontend-->>User: ダッシュボード表示
```

### 4.2. 献立作成フロー

```mermaid
sequenceDiagram
    participant User as 栄養士
    participant Frontend as hoiku-frontend
    participant HoikuAPI as hoiku-backend
    participant DB as PostgreSQL

    User->>Frontend: 献立作成フォーム入力
    Frontend->>HoikuAPI: POST /api/hoiku/menus<br/>Authorization: Bearer {JWT}
    HoikuAPI->>HoikuAPI: JWT検証
    HoikuAPI->>DB: 献立保存（hoiku.menus）
    DB-->>HoikuAPI: 保存成功
    HoikuAPI-->>Frontend: 献立ID返却

    User->>Frontend: 食材追加
    Frontend->>HoikuAPI: POST /api/hoiku/menus/{id}/ingredients
    HoikuAPI->>DB: 食材追加（hoiku.menu_ingredients）
    HoikuAPI->>HoikuAPI: 栄養計算実行
    HoikuAPI-->>Frontend: 栄養計算結果
    Frontend-->>User: 栄養計算結果表示
```

### 4.3. PDF生成フロー

```mermaid
sequenceDiagram
    participant User as 栄養士
    participant Frontend as hoiku-frontend
    participant HoikuAPI as hoiku-backend
    participant DB as PostgreSQL
    participant S3 as AWS S3

    User->>Frontend: PDF生成リクエスト
    Frontend->>HoikuAPI: POST /api/hoiku/reports/pdf
    HoikuAPI->>DB: 献立データ取得（hoiku.menus, menu_ingredients）
    HoikuAPI->>DB: テンプレート取得（hoiku.report_templates）
    HoikuAPI->>HoikuAPI: PDF生成（Apache PDFBox）
    HoikuAPI->>S3: PDFアップロード
    S3-->>HoikuAPI: S3 URL
    HoikuAPI->>DB: 帳票履歴保存（hoiku.generated_reports）
    HoikuAPI-->>Frontend: ダウンロードURL
    Frontend-->>User: PDFダウンロード
```

## 5. API設計

### 5.1. RESTful API原則

- リソース指向のURL設計
- HTTPメソッドの適切な使用（GET, POST, PUT, DELETE）
- ステータスコードの適切な返却
- JSON形式のリクエスト/レスポンス

### 5.2. エンドポイント命名規則

```
/api/{service}/{resource}/{id}/{action}
```

**例**:
- `GET /api/core/users` - ユーザー一覧
- `POST /api/core/auth/login` - ログイン
- `GET /api/hoiku/menus/{id}` - 献立詳細
- `POST /api/hoiku/menus/{id}/ingredients` - 食材追加

### 5.3. 認証・認可

- **認証**: JWT（JSON Web Token）
- **認可**: ロールベースアクセス制御（RBAC）
- **トークン**: Authorizationヘッダーで送信

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 6. セキュリティアーキテクチャ

### 6.1. 多層防御

```
┌─────────────────────────────────┐
│  CloudFront (CDN + WAF)         │  DDoS対策、WAFルール
├─────────────────────────────────┤
│  ALB (Application Load Balancer)│  SSL/TLS終端、ヘルスチェック
├─────────────────────────────────┤
│  ECS (Private Subnet)           │  アプリケーション実行
├─────────────────────────────────┤
│  RDS (Private Subnet)           │  データベース
└─────────────────────────────────┘
```

### 6.2. ネットワーク分離

- **Public Subnet**: ALB
- **Private Subnet**: ECS, RDS
- **Security Group**: 最小権限の原則

## 7. スケーラビリティ戦略

### 7.1. 水平スケーリング

- **ECS Auto Scaling**: CPU使用率ベース
- **RDS Read Replica**: 読み取り負荷分散（将来）

### 7.2. キャッシュ戦略

- **CloudFront**: 静的コンテンツ（フロントエンド）
- **Redis/ElastiCache**: セッション管理、APIキャッシュ（将来）

### 7.3. 非同期処理

- **SQS**: PDF生成の非同期化（将来）
- **Lambda**: バッチ処理（将来）

## 8. 監視・運用

### 8.1. ログ設計

- **アプリケーションログ**: CloudWatch Logs
- **アクセスログ**: ALB Access Log → S3
- **監査ログ**: CloudWatch Logs（長期保存）

### 8.2. メトリクス

- **CloudWatch Metrics**: CPU、メモリ、ディスク使用率
- **カスタムメトリクス**: API レスポンスタイム、エラー率

### 8.3. アラート

- **SNS**: 閾値超過時の通知
- **Slack**: アラート通知先

## 9. 将来拡張

### 9.1. まもり介護ごはん、まもり病院ごはん

```
mamori-kaigo-backend (Port: 8082)
mamori-kaigo-frontend
kaigo.mamori.jp

mamori-hospital-backend (Port: 8083)
mamori-hospital-frontend
hospital.mamori.jp
```

### 9.2. マイクロサービス化

現在のモノリス構成から、将来的にマイクロサービスへ移行可能：

- 認証サービス（core-backend）
- 献立サービス（hoiku-backend）
- 帳票生成サービス（独立）
- 通知サービス

## 10. 制約事項

### 10.1. 技術的制約

- Java 17以上必須（Spring Boot 3.x）
- Node.js 18以上推奨
- PostgreSQL 14以上

### 10.2. リソース制約

- RDS: db.t3.medium（開発環境）、db.r5.large（本番環境）
- ECS: 0.5 vCPU, 1GB RAM（最小）

## 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|-----------|---------|--------|
| 2026-03-08 | 1.0.0 | 初版作成（テンプレート） | - |

---

**注**: このドキュメントはテンプレートです。実際のシステムアーキテクチャに基づいて内容を更新してください。
