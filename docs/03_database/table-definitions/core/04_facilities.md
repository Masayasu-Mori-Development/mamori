# 施設テーブル (core.facilities)

## 概要

保育施設の基本情報を管理するテーブル。
各施設は1つの組織に所属し、独自の献立・栄養計算を行う。

## テーブル定義

```sql
CREATE TYPE facility_type AS ENUM (
    'nursery',              -- 認可保育所
    'certified_nursery',    -- 認定こども園
    'small_nursery',        -- 小規模保育
    'enterprise_nursery',   -- 企業主導型保育
    'family_daycare'        -- 家庭的保育
);

CREATE TABLE core.facilities (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES core.tenants(id),
    organization_id         UUID NOT NULL REFERENCES core.organizations(id),
    municipality_code       VARCHAR(6) NOT NULL REFERENCES core.municipality_codes(code),
    name                    VARCHAR(255) NOT NULL,
    name_kana               VARCHAR(255),
    facility_type           facility_type NOT NULL,
    facility_number         VARCHAR(50),
    capacity                INTEGER NOT NULL,
    postal_code             VARCHAR(10),
    prefecture              VARCHAR(10) NOT NULL,
    city                    VARCHAR(100) NOT NULL,
    address_line1           VARCHAR(255) NOT NULL,
    address_line2           VARCHAR(255),
    phone_number            VARCHAR(20),
    fax_number              VARCHAR(20),
    email                   VARCHAR(255),
    director_name           VARCHAR(100),
    nutritionist_name       VARCHAR(100),
    opening_date            DATE,
    is_active               BOOLEAN NOT NULL DEFAULT true,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              UUID,
    updated_by              UUID
);

CREATE INDEX idx_facilities_tenant_id ON core.facilities(tenant_id);
CREATE INDEX idx_facilities_organization_id ON core.facilities(organization_id);
CREATE INDEX idx_facilities_municipality_code ON core.facilities(municipality_code);
CREATE INDEX idx_facilities_type ON core.facilities(facility_type);
CREATE INDEX idx_facilities_is_active ON core.facilities(is_active);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 施設ID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID（外部キー） |
| organization_id | UUID | NOT NULL | - | 組織ID（外部キー） |
| municipality_code | VARCHAR(6) | NOT NULL | - | 所在地の自治体コード（外部キー） |
| name | VARCHAR(255) | NOT NULL | - | 施設名 |
| name_kana | VARCHAR(255) | NULL | - | 施設名（カナ） |
| facility_type | facility_type | NOT NULL | - | 施設タイプ |
| facility_number | VARCHAR(50) | NULL | - | 施設番号（自治体発行） |
| capacity | INTEGER | NOT NULL | - | 定員数 |
| postal_code | VARCHAR(10) | NULL | - | 郵便番号 |
| prefecture | VARCHAR(10) | NOT NULL | - | 都道府県 |
| city | VARCHAR(100) | NOT NULL | - | 市区町村 |
| address_line1 | VARCHAR(255) | NOT NULL | - | 住所1（番地） |
| address_line2 | VARCHAR(255) | NULL | - | 住所2（建物名） |
| phone_number | VARCHAR(20) | NULL | - | 電話番号 |
| fax_number | VARCHAR(20) | NULL | - | FAX番号 |
| email | VARCHAR(255) | NULL | - | メールアドレス |
| director_name | VARCHAR(100) | NULL | - | 施設長名 |
| nutritionist_name | VARCHAR(100) | NULL | - | 栄養士名 |
| opening_date | DATE | NULL | - | 開設日 |
| is_active | BOOLEAN | NOT NULL | true | アクティブフラグ |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者（users.id） |
| updated_by | UUID | NULL | - | 更新者（users.id） |

## 制約

### 主キー
- `PRIMARY KEY (id)`

### 外部キー
- `FOREIGN KEY (tenant_id) REFERENCES core.tenants(id)`
- `FOREIGN KEY (organization_id) REFERENCES core.organizations(id)`
- `FOREIGN KEY (municipality_code) REFERENCES core.municipality_codes(code)`

### CHECK制約

```sql
ALTER TABLE core.facilities ADD CONSTRAINT chk_facilities_capacity
    CHECK (capacity > 0);

ALTER TABLE core.facilities ADD CONSTRAINT chk_facilities_municipality_code_length
    CHECK (length(municipality_code) = 6);
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_facilities_tenant_id | tenant_id | テナント別施設一覧取得 |
| idx_facilities_organization_id | organization_id | 組織別施設一覧取得 |
| idx_facilities_municipality_code | municipality_code | 自治体別施設検索 |
| idx_facilities_type | facility_type | 施設タイプ別検索 |
| idx_facilities_is_active | is_active | アクティブ施設検索 |

## 関連テーブル

- `core.tenants` - 所属テナント
- `core.organizations` - 所属組織
- `core.municipality_codes` - 所在地自治体
- `core.user_facilities` - 施設担当ユーザー
- `hoiku.menus` - 献立
- `hoiku.ingredients` - 施設食材マスタ
- `hoiku.nutrition_standards` - 栄養基準

## サンプルデータ

```sql
INSERT INTO core.facilities (
    id, tenant_id, organization_id, municipality_code,
    name, name_kana, facility_type, facility_number,
    capacity, prefecture, city, address_line1,
    director_name, nutritionist_name, opening_date
) VALUES (
    '123e4567-e89b-12d3-a456-426614174000',
    '550e8400-e29b-41d4-a716-446655440000',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '141003',
    'さくら保育園 新横浜園',
    'サクラホイクエン シンヨコハマエン',
    'nursery',
    'YOK-2024-001',
    60,
    '神奈川県',
    '横浜市港北区',
    '新横浜3-1-1',
    '鈴木一郎',
    '田中花子',
    '2024-04-01'
);
```

## ビジネスルール

### 栄養基準の自動適用
- `municipality_code` に基づいて、該当自治体の栄養基準を自動適用
- 施設作成時に `hoiku.nutrition_standards` から最新の基準を検索して適用
- 手動で別の基準に変更することも可能

### 施設タイプ別の制約
- `nursery` (認可保育所): 定員20名以上
- `small_nursery` (小規模保育): 定員6〜19名
- `family_daycare` (家庭的保育): 定員5名以下

### 献立管理
- 各施設は独立した献立を持つ
- 本部からテンプレート献立を受け取り、独自にカスタマイズ可能
- 施設ごとに異なる年齢構成・人数に対応

## 備考

- 施設の物理削除は行わず、`is_active = false` で論理削除
- 閉園した施設も履歴として保持（監査対応）
- `municipality_code` は所在地の自治体（運営組織とは異なる場合あり）
- 栄養基準は所在地の自治体基準を適用
