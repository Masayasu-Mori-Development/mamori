# 運営用アプリケーション設計

## 概要

まもり保育ごはんの運営側が使用する管理画面とAPIの設計。

**セキュリティ上の最重要原則**:
- 運営ユーザーと顧客ユーザーを**完全に分離**
- データベース、認証、API、フロントエンドすべてで分離

## システム構成の全体像

### アプリケーション構成（更新版）

```
mamori/
├── core-backend/           # 認証・共通機能
│   └── Port: 8080
│       └── /api/core/*
├── hoiku-backend/          # 保育機能（顧客向け）
│   └── Port: 8081
│       └── /api/hoiku/*
├── admin-backend/          # 運営機能（管理画面向け）★NEW
│   └── Port: 8082
│       └── /api/admin/*
├── hoiku-frontend/         # 保育施設向け画面
│   └── Port: 3000
├── admin-frontend/         # 運営管理画面 ★NEW
│   └── Port: 3001
└── infra/                  # インフラ
```

### データフロー

```
【顧客側】
hoiku-frontend (Port: 3000)
  ↓
hoiku-backend (Port: 8081) /api/hoiku/*
  ↓
PostgreSQL: core schema + hoiku schema

【運営側】
admin-frontend (Port: 3001)
  ↓
admin-backend (Port: 8082) /api/admin/*
  ↓
PostgreSQL: admin schema + core schema (read-only) + hoiku schema (read-only)
```

## セキュリティ分離設計

### 1. ユーザーテーブルの完全分離

**❌ 悪い設計例（混在）**:
```sql
-- 絶対にやってはいけない
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255),
    user_type VARCHAR(20),  -- 'admin' or 'customer' ← 危険！
    ...
);
```

**問題点**:
- SQLインジェクションで user_type を書き換えられるリスク
- 権限昇格攻撃が可能
- テナント分離が破られる可能性

**✅ 正しい設計（完全分離）**:
```sql
-- 運営ユーザー（admin schemaに配置）
CREATE TABLE admin.admin_users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    family_name VARCHAR(100) NOT NULL,
    given_name VARCHAR(100) NOT NULL,
    admin_role VARCHAR(50) NOT NULL,        -- 'super_admin', 'support', 'analyst'
    is_mfa_enabled BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 顧客ユーザー（core schemaに配置）
CREATE TABLE core.users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    family_name VARCHAR(100) NOT NULL,
    given_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 2. 認証トークンの分離

**JWT ペイロードの設計**:

```json
// 顧客ユーザーのJWT
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "type": "customer",           // ← 重要: トークンタイプ
  "tenant_id": "tenant-uuid",
  "organization_id": "org-uuid",
  "iss": "mamori-core-backend",
  "exp": 1234567890
}

// 運営ユーザーのJWT
{
  "sub": "admin-uuid",
  "email": "admin@mamori.com",
  "type": "admin",              // ← 重要: トークンタイプ
  "admin_role": "super_admin",
  "iss": "mamori-admin-backend",
  "exp": 1234567890
}
```

**重要**:
- `type` フィールドで明示的に区別
- `iss`（発行者）も異なる
- admin トークンに `tenant_id` は含めない

### 3. API の分離

```
/api/core/*     → core-backend   （認証・共通機能）
/api/hoiku/*    → hoiku-backend  （顧客向け保育機能）
/api/admin/*    → admin-backend  （運営向け管理機能）★NEW
```

**API Gateway での制御**（将来的にALBまたはAPI Gateway導入時）:

```yaml
# 顧客向けAPI
/api/hoiku/*:
  backend: hoiku-backend:8081
  auth: customer JWT only
  cors: hoiku-frontend domain only

# 運営向けAPI
/api/admin/*:
  backend: admin-backend:8082
  auth: admin JWT only
  cors: admin-frontend domain only
  ip_whitelist: [運営オフィスIP, VPN IP]  # IP制限
```

### 4. データベース権限の分離

```sql
-- hoiku-backend 用のDBユーザー
CREATE USER hoiku_backend WITH PASSWORD 'xxx';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO hoiku_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA hoiku TO hoiku_backend;
REVOKE ALL ON SCHEMA admin FROM hoiku_backend;  -- adminスキーマは完全にアクセス不可

-- admin-backend 用のDBユーザー
CREATE USER admin_backend WITH PASSWORD 'xxx';
GRANT ALL ON SCHEMA admin TO admin_backend;
GRANT SELECT ON ALL TABLES IN SCHEMA core TO admin_backend;    -- 読み取りのみ
GRANT SELECT ON ALL TABLES IN SCHEMA hoiku TO admin_backend;   -- 読み取りのみ
-- admin-backend は顧客データを変更できない（読み取りのみ）
```

### 5. フロントエンドの分離

| 項目 | hoiku-frontend | admin-frontend |
|------|---------------|----------------|
| **ドメイン** | app.mamori.com | admin.mamori.com |
| **ポート（開発）** | 3000 | 3001 |
| **API接続先** | /api/hoiku/* | /api/admin/* |
| **認証方法** | 顧客JWT | 運営JWT |
| **アクセス制限** | なし | IP制限 + MFA |

## 運営管理画面の機能

### 運営ユーザーの役割

```sql
CREATE TYPE admin_role AS ENUM (
    'super_admin',      -- 全機能アクセス可能
    'support',          -- サポート業務（顧客データ閲覧、テナント管理）
    'analyst',          -- データ分析のみ（読み取り専用）
    'content_manager'   -- マスタデータ管理（食材、栄養基準、帳票テンプレート）
);
```

### 主要機能

#### 1. テナント管理

- テナント一覧
- テナント作成・編集・無効化
- 契約プラン管理
- 利用状況監視

**API例**:
```
GET    /api/admin/tenants
POST   /api/admin/tenants
GET    /api/admin/tenants/{id}
PUT    /api/admin/tenants/{id}
DELETE /api/admin/tenants/{id}
GET    /api/admin/tenants/{id}/usage  # 利用状況
```

#### 2. マスタデータ管理

- システム食材マスタ（文科省データ）
- 都道府県・自治体マスタ
- 栄養基準マスタ
- 帳票テンプレート管理

**API例**:
```
GET    /api/admin/system-ingredients
POST   /api/admin/system-ingredients
PUT    /api/admin/system-ingredients/{id}

GET    /api/admin/municipalities
POST   /api/admin/municipalities

GET    /api/admin/nutrition-standards
POST   /api/admin/nutrition-standards
PUT    /api/admin/nutrition-standards/{id}
```

#### 3. 顧客データ閲覧（サポート目的）

- 全テナントの献立閲覧（読み取り専用）
- 全テナントのユーザー情報閲覧
- 問題解決のためのデータ調査

**重要**: 変更は不可、閲覧のみ

**API例**:
```
GET    /api/admin/tenants/{tenantId}/menus         # 読み取り専用
GET    /api/admin/tenants/{tenantId}/users         # 読み取り専用
GET    /api/admin/tenants/{tenantId}/facilities    # 読み取り専用
```

#### 4. システム監視

- APIリクエスト数
- エラー率
- レスポンスタイム
- データベース使用状況

**API例**:
```
GET    /api/admin/monitoring/api-metrics
GET    /api/admin/monitoring/error-logs
GET    /api/admin/monitoring/performance
```

#### 5. 分析・レポート

- テナント別利用統計
- 献立作成数の推移
- ユーザー数の推移
- 収益分析

**API例**:
```
GET    /api/admin/analytics/tenant-usage
GET    /api/admin/analytics/menu-statistics
GET    /api/admin/analytics/revenue
```

## セキュリティ対策の詳細

### 1. 多要素認証（MFA）

運営ユーザーは**MFA必須**:

```sql
CREATE TABLE admin.admin_users (
    ...
    is_mfa_enabled BOOLEAN NOT NULL DEFAULT true,
    mfa_secret VARCHAR(255),                    -- TOTP secret
    mfa_backup_codes JSONB,                     -- バックアップコード
    ...
);
```

**ログインフロー**:
```
1. Email + Password 入力
2. TOTP（Google Authenticator等）による2段階認証
3. JWT発行
```

### 2. IP制限

運営管理画面は特定のIPからのみアクセス可能:

```yaml
# AWS Security Group / ALB設定
admin-frontend:
  allowed_ips:
    - 203.0.113.0/24    # 本社オフィス
    - 198.51.100.0/24   # VPN
```

### 3. 監査ログ

運営ユーザーの全操作をログ記録:

```sql
CREATE TABLE admin.admin_audit_logs (
    id UUID PRIMARY KEY,
    admin_user_id UUID NOT NULL REFERENCES admin.admin_users(id),
    action VARCHAR(100) NOT NULL,               -- 'view_tenant', 'create_ingredient'
    resource_type VARCHAR(50),                  -- 'tenant', 'ingredient'
    resource_id UUID,
    tenant_id UUID,                             -- 対象テナント（該当する場合）
    request_ip INET NOT NULL,
    request_method VARCHAR(10),
    request_path TEXT,
    request_body JSONB,
    response_status INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**記録する操作**:
- テナントデータの閲覧
- マスタデータの作成・変更・削除
- 設定変更
- エクスポート操作

### 4. CORS設定

```typescript
// admin-backend の CORS設定
const corsOptions = {
  origin: [
    'https://admin.mamori.com',        // 本番
    'http://localhost:3001'            // 開発
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Authorization', 'Content-Type']
};
```

### 5. セッション管理

```typescript
// 運営ユーザーのセッションタイムアウト: 短め
const ADMIN_SESSION_TIMEOUT = 30 * 60 * 1000;  // 30分

// 顧客ユーザーのセッションタイムアウト: 長め
const CUSTOMER_SESSION_TIMEOUT = 24 * 60 * 60 * 1000;  // 24時間
```

## データベース設計（admin schema）

### admin schema のテーブル

```sql
CREATE SCHEMA IF NOT EXISTS admin;

-- 運営ユーザー
CREATE TABLE admin.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    family_name VARCHAR(100) NOT NULL,
    given_name VARCHAR(100) NOT NULL,
    family_name_kana VARCHAR(100),
    given_name_kana VARCHAR(100),
    phone_number VARCHAR(20),
    admin_role VARCHAR(50) NOT NULL,            -- 'super_admin', 'support', etc.
    is_mfa_enabled BOOLEAN NOT NULL DEFAULT true,
    mfa_secret VARCHAR(255),
    mfa_backup_codes JSONB,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 運営ユーザーの操作ログ
CREATE TABLE admin.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES admin.admin_users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    tenant_id UUID,
    request_ip INET NOT NULL,
    request_method VARCHAR(10),
    request_path TEXT,
    request_body JSONB,
    response_status INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- システム設定
CREATE TABLE admin.system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES admin.admin_users(id)
);

-- お知らせ（全テナント向け）
CREATE TABLE admin.system_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    announcement_type VARCHAR(50) NOT NULL,     -- 'maintenance', 'feature', 'important'
    target_audience VARCHAR(50) NOT NULL,       -- 'all', 'specific_tenants'
    target_tenant_ids JSONB,                    -- 特定テナント向けの場合
    publish_at TIMESTAMP NOT NULL,
    expire_at TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES admin.admin_users(id)
);
```

## admin-backend の実装方針

### ディレクトリ構成

```
admin-backend/
├── src/
│   ├── main/kotlin/com/mamori/admin/
│   │   ├── controller/
│   │   │   ├── AuthController.kt           # 運営ユーザー認証
│   │   │   ├── TenantController.kt         # テナント管理
│   │   │   ├── SystemIngredientController.kt
│   │   │   ├── MunicipalityController.kt
│   │   │   └── AnalyticsController.kt
│   │   ├── service/
│   │   │   ├── AdminAuthService.kt
│   │   │   ├── TenantManagementService.kt
│   │   │   └── AuditLogService.kt
│   │   ├── repository/
│   │   │   ├── AdminUserRepository.kt
│   │   │   └── AuditLogRepository.kt
│   │   ├── security/
│   │   │   ├── AdminJwtAuthenticationFilter.kt
│   │   │   └── MfaService.kt
│   │   └── config/
│   │       ├── AdminSecurityConfig.kt
│   │       └── AdminDatabaseConfig.kt
│   └── resources/
│       ├── application.yml
│       └── db/migration/                   # Flyway（admin schema）
├── build.gradle.kts
└── settings.gradle.kts
```

### Spring Security設定（admin-backend）

```kotlin
@Configuration
@EnableWebSecurity
class AdminSecurityConfig {

    @Bean
    fun adminSecurityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .csrf { it.disable() }
            .cors { it.configurationSource(adminCorsConfigurationSource()) }
            .sessionManagement {
                it.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            }
            .authorizeHttpRequests { auth ->
                auth
                    .requestMatchers("/api/admin/auth/login").permitAll()
                    .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                    .anyRequest().denyAll()  // デフォルト拒否
            }
            .addFilterBefore(
                adminJwtAuthenticationFilter(),
                UsernamePasswordAuthenticationFilter::class.java
            )

        return http.build()
    }

    private fun adminCorsConfigurationSource(): CorsConfigurationSource {
        val configuration = CorsConfiguration()
        configuration.allowedOrigins = listOf(
            "https://admin.mamori.com",
            "http://localhost:3001"
        )
        configuration.allowedMethods = listOf("GET", "POST", "PUT", "DELETE")
        configuration.allowedHeaders = listOf("Authorization", "Content-Type")
        configuration.allowCredentials = true

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/api/admin/**", configuration)
        return source
    }
}
```

## admin-frontend の実装方針

### ディレクトリ構成

```
admin-frontend/
├── src/
│   ├── components/
│   │   ├── tenants/
│   │   │   ├── TenantList.tsx
│   │   │   └── TenantDetail.tsx
│   │   ├── ingredients/
│   │   │   └── SystemIngredientManager.tsx
│   │   ├── analytics/
│   │   │   └── Dashboard.tsx
│   │   └── common/
│   │       ├── AdminLayout.tsx
│   │       └── AdminHeader.tsx
│   ├── pages/
│   │   ├── login/
│   │   │   └── AdminLogin.tsx
│   │   ├── tenants/
│   │   ├── ingredients/
│   │   └── analytics/
│   ├── hooks/
│   │   ├── useAdminAuth.ts
│   │   └── useAdminApi.ts
│   ├── services/
│   │   └── adminApi.ts
│   └── types/
│       └── admin.ts
├── package.json
└── vite.config.ts
```

## デプロイ構成

### 開発環境

```yaml
services:
  - hoiku-frontend:  localhost:3000
  - admin-frontend:  localhost:3001
  - core-backend:    localhost:8080
  - hoiku-backend:   localhost:8081
  - admin-backend:   localhost:8082
  - postgresql:      localhost:5432
```

### 本番環境（AWS）

```
┌─────────────────────────────────────┐
│ CloudFront (CDN)                    │
├─────────────────────────────────────┤
│ app.mamori.com  → S3 (hoiku-frontend)│
│ admin.mamori.com → S3 (admin-frontend)│
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ ALB (Application Load Balancer)     │
├─────────────────────────────────────┤
│ /api/core/*  → core-backend (ECS)   │
│ /api/hoiku/* → hoiku-backend (ECS)  │
│ /api/admin/* → admin-backend (ECS)  │
│   ↑ IP制限（運営のみ）                │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ RDS PostgreSQL                      │
├─────────────────────────────────────┤
│ - admin schema  (運営データ)         │
│ - core schema   (共通データ)         │
│ - hoiku schema  (保育データ)         │
└─────────────────────────────────────┘
```

## まとめ

### セキュリティ分離のチェックリスト

- [x] ユーザーテーブルを完全に分離（admin.admin_users / core.users）
- [x] 認証トークンにユーザータイプを明示
- [x] API エンドポイントを分離（/api/admin/* / /api/hoiku/*）
- [x] データベース権限を分離（admin_backend / hoiku_backend）
- [x] フロントエンドを分離（admin.mamori.com / app.mamori.com）
- [x] 運営画面にIP制限
- [x] 運営ユーザーにMFA必須
- [x] 監査ログで全操作を記録
- [x] CORS設定で厳格に制御
- [x] セッションタイムアウトを適切に設定

### 次のステップ

1. admin-backend の実装
2. admin-frontend の実装
3. admin schema のマイグレーションファイル作成
4. セキュリティテストの実施
