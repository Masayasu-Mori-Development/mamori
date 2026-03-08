# PostgreSQL Schema設計ドキュメント

## 概要

まもり保育ごはんでは、PostgreSQLのSchema機能を使用して、coreとhoikuの2つのスキーマに分離します。

### Schema分離の理由

- **責任の明確化**: 共通機能（core）と保育特化機能（hoiku）を分離
- **将来の拡張性**: 介護（kaigo）、病院（hospital）など他領域への展開を容易にする
- **アクセス制御**: Schema単位で権限管理が可能
- **DB分離の準備**: 将来的に大口顧客専用DBへの移行が容易

## Schema構成

```
mamori (Database)
├── core (Schema)    - 共通機能
└── hoiku (Schema)   - 保育特化機能
```

---

## Core Schema（共通機能）

### 1. core.tenants（テナント）

法人・組織を表すマルチテナントの基盤テーブル。

```sql
CREATE TABLE core.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'free', -- free, basic, premium
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, suspended, deleted
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_tenants_code ON core.tenants(code);
CREATE INDEX idx_tenants_status ON core.tenants(status);
```

### 2. core.organizations（法人）

テナント配下の法人情報。

```sql
CREATE TABLE core.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    postal_code VARCHAR(10),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_organizations_tenant_id ON core.organizations(tenant_id);
```

### 3. core.facilities（施設）

保育園、介護施設など、各種施設の情報。

```sql
CREATE TABLE core.facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES core.organizations(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    facility_type VARCHAR(50) NOT NULL, -- nursery, elderly_care, hospital, etc.
    postal_code VARCHAR(10),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    capacity INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_facilities_tenant_id ON core.facilities(tenant_id);
CREATE INDEX idx_facilities_organization_id ON core.facilities(organization_id);
CREATE INDEX idx_facilities_facility_type ON core.facilities(facility_type);
```

### 4. core.users（ユーザー）

システム利用者の情報。

```sql
CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id) ON DELETE CASCADE,
    facility_id UUID REFERENCES core.facilities(id) ON DELETE SET NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, inactive, deleted
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_users_tenant_id ON core.users(tenant_id);
CREATE INDEX idx_users_facility_id ON core.users(facility_id);
CREATE INDEX idx_users_email ON core.users(email);
CREATE INDEX idx_users_status ON core.users(status);
```

### 5. core.roles（役割）

システムの役割定義。

```sql
CREATE TABLE core.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 初期データ
INSERT INTO core.roles (name, description) VALUES
('SYSTEM_ADMIN', 'システム管理者'),
('TENANT_ADMIN', 'テナント管理者'),
('FACILITY_ADMIN', '施設管理者'),
('STAFF', '一般スタッフ');
```

### 6. core.user_roles（ユーザー役割）

ユーザーと役割の関連。

```sql
CREATE TABLE core.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, role_id)
);

CREATE INDEX idx_user_roles_user_id ON core.user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON core.user_roles(role_id);
```

---

## Hoiku Schema（保育特化機能）

### 1. hoiku.menus（献立）

保育施設の献立情報。

```sql
CREATE TABLE hoiku.menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL, -- core.tenants参照（外部キー制約は跨Schemaのため設定しない）
    facility_id UUID NOT NULL, -- core.facilities参照
    menu_date DATE NOT NULL,
    meal_type VARCHAR(50) NOT NULL, -- breakfast, lunch, snack, dinner
    menu_name VARCHAR(255) NOT NULL,
    description TEXT,
    target_age_group VARCHAR(50), -- 0-1歳, 1-2歳, 3-5歳など
    status VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft, published, archived
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_menus_tenant_id ON hoiku.menus(tenant_id);
CREATE INDEX idx_menus_facility_id ON hoiku.menus(facility_id);
CREATE INDEX idx_menus_menu_date ON hoiku.menus(menu_date);
CREATE INDEX idx_menus_meal_type ON hoiku.menus(meal_type);
```

### 2. hoiku.ingredients（食材）

食材マスタ。

```sql
CREATE TABLE hoiku.ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100), -- vegetables, meat, fish, grains, etc.
    unit VARCHAR(20) NOT NULL, -- g, ml, 個, etc.
    -- 栄養成分（100gあたり）
    energy_kcal DECIMAL(10, 2),
    protein_g DECIMAL(10, 2),
    fat_g DECIMAL(10, 2),
    carbohydrate_g DECIMAL(10, 2),
    sodium_mg DECIMAL(10, 2),
    calcium_mg DECIMAL(10, 2),
    iron_mg DECIMAL(10, 2),
    vitamin_a_ug DECIMAL(10, 2),
    vitamin_b1_mg DECIMAL(10, 2),
    vitamin_b2_mg DECIMAL(10, 2),
    vitamin_c_mg DECIMAL(10, 2),
    dietary_fiber_g DECIMAL(10, 2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_ingredients_tenant_id ON hoiku.ingredients(tenant_id);
CREATE INDEX idx_ingredients_category ON hoiku.ingredients(category);
CREATE INDEX idx_ingredients_name ON hoiku.ingredients(name);
```

### 3. hoiku.menu_ingredients（献立食材）

献立と食材の関連（使用量含む）。

```sql
CREATE TABLE hoiku.menu_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id UUID NOT NULL REFERENCES hoiku.menus(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES hoiku.ingredients(id) ON DELETE RESTRICT,
    quantity DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_menu_ingredients_menu_id ON hoiku.menu_ingredients(menu_id);
CREATE INDEX idx_menu_ingredients_ingredient_id ON hoiku.menu_ingredients(ingredient_id);
```

### 4. hoiku.nutrition_standards（栄養基準）

自治体・年齢別の栄養基準。

```sql
CREATE TABLE hoiku.nutrition_standards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    municipality VARCHAR(100) NOT NULL, -- 横浜市、川崎市など
    age_group VARCHAR(50) NOT NULL, -- 0-1歳, 1-2歳, 3-5歳など
    meal_type VARCHAR(50) NOT NULL, -- lunch, snackなど
    energy_kcal_min DECIMAL(10, 2),
    energy_kcal_max DECIMAL(10, 2),
    protein_g_min DECIMAL(10, 2),
    protein_g_max DECIMAL(10, 2),
    fat_g_min DECIMAL(10, 2),
    fat_g_max DECIMAL(10, 2),
    carbohydrate_g_min DECIMAL(10, 2),
    carbohydrate_g_max DECIMAL(10, 2),
    sodium_mg_max DECIMAL(10, 2),
    calcium_mg_min DECIMAL(10, 2),
    iron_mg_min DECIMAL(10, 2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_nutrition_standards_tenant_id ON hoiku.nutrition_standards(tenant_id);
CREATE INDEX idx_nutrition_standards_municipality ON hoiku.nutrition_standards(municipality);
```

### 5. hoiku.report_templates（帳票テンプレート）

自治体別の帳票テンプレート（JSONで保存）。

```sql
CREATE TABLE hoiku.report_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    municipality VARCHAR(100) NOT NULL, -- 横浜市、川崎市など
    template_name VARCHAR(255) NOT NULL,
    template_type VARCHAR(50) NOT NULL, -- nutrition_report, menu_list, etc.
    template_json JSONB NOT NULL, -- テンプレート定義（フィールド、レイアウトなど）
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_report_templates_tenant_id ON hoiku.report_templates(tenant_id);
CREATE INDEX idx_report_templates_municipality ON hoiku.report_templates(municipality);
```

### 6. hoiku.generated_reports（生成済み帳票）

生成されたPDF帳票の履歴。

```sql
CREATE TABLE hoiku.generated_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    facility_id UUID NOT NULL,
    template_id UUID REFERENCES hoiku.report_templates(id) ON DELETE SET NULL,
    report_type VARCHAR(50) NOT NULL,
    report_date DATE NOT NULL,
    file_path VARCHAR(500) NOT NULL, -- S3パス
    status VARCHAR(20) NOT NULL DEFAULT 'generated', -- generated, downloaded, archived
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_generated_reports_tenant_id ON hoiku.generated_reports(tenant_id);
CREATE INDEX idx_generated_reports_facility_id ON hoiku.generated_reports(facility_id);
CREATE INDEX idx_generated_reports_report_date ON hoiku.generated_reports(report_date);
```

---

## マルチテナント原則

全業務テーブルに以下のカラムを必須とする:

- `tenant_id UUID NOT NULL`: テナントID
- `created_at TIMESTAMP NOT NULL`: 作成日時
- `updated_at TIMESTAMP NOT NULL`: 更新日時
- `created_by UUID`: 作成者（users.id）
- `updated_by UUID`: 更新者（users.id）

## Row Level Security（RLS）検討事項

将来的にPostgreSQLのRow Level Security機能を使用して、テナント単位でのデータアクセス制御を実装する可能性がある。

```sql
-- 例: menusテーブルのRLS
ALTER TABLE hoiku.menus ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON hoiku.menus
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);
```

## Flyway Migration順序

1. Core Schemaの作成とテーブル作成
2. Hoiku Schemaの作成とテーブル作成
3. 初期データ投入（roles、nutrition_standardsなど）

```
core-backend/src/main/resources/db/migration/
├── V1__create_core_schema.sql
├── V2__create_core_tenants.sql
├── V3__create_core_organizations.sql
├── V4__create_core_facilities.sql
├── V5__create_core_users.sql
├── V6__create_core_roles.sql
├── V7__create_core_user_roles.sql
└── V8__insert_initial_roles.sql

hoiku-backend/src/main/resources/db/migration/
├── V1__create_hoiku_schema.sql
├── V2__create_hoiku_menus.sql
├── V3__create_hoiku_ingredients.sql
├── V4__create_hoiku_menu_ingredients.sql
├── V5__create_hoiku_nutrition_standards.sql
├── V6__create_hoiku_report_templates.sql
└── V7__create_hoiku_generated_reports.sql
```

## 注意事項

- 跨Schemaの外部キー制約は設定しない（PostgreSQLで可能だが、将来のDB分離を考慮）
- JSON型（JSONB）を活用して柔軟なデータ構造に対応（report_templates）
- UUIDを主キーとして使用（分散システムへの対応）
- インデックスは検索頻度とパフォーマンスを考慮して適切に設定
