# 組織テーブル (core.organizations)

## 概要

法人または自治体の情報を管理するテーブル。
組織は複数の施設を持つことができる。

## テーブル定義

```sql
CREATE TYPE organization_type AS ENUM (
    'corporation',      -- 法人
    'municipality'      -- 自治体
);

CREATE TABLE core.organizations (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES core.tenants(id),
    name                  VARCHAR(255) NOT NULL,
    name_kana             VARCHAR(255),
    organization_type     organization_type NOT NULL,
    corporate_number      VARCHAR(13),
    municipality_code     VARCHAR(6),
    postal_code           VARCHAR(10),
    prefecture            VARCHAR(10) NOT NULL,
    city                  VARCHAR(100) NOT NULL,
    address_line1         VARCHAR(255) NOT NULL,
    address_line2         VARCHAR(255),
    phone_number          VARCHAR(20),
    fax_number            VARCHAR(20),
    email                 VARCHAR(255),
    representative_name   VARCHAR(100),
    representative_title  VARCHAR(100),
    is_headquarters       BOOLEAN NOT NULL DEFAULT false,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by            UUID,
    updated_by            UUID
);

CREATE INDEX idx_organizations_tenant_id ON core.organizations(tenant_id);
CREATE INDEX idx_organizations_type ON core.organizations(organization_type);
CREATE INDEX idx_organizations_municipality_code ON core.organizations(municipality_code);
CREATE INDEX idx_organizations_is_active ON core.organizations(is_active);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 組織ID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID（外部キー） |
| name | VARCHAR(255) | NOT NULL | - | 組織名 |
| name_kana | VARCHAR(255) | NULL | - | 組織名（カナ） |
| organization_type | organization_type | NOT NULL | - | 組織タイプ（corporation/municipality） |
| corporate_number | VARCHAR(13) | NULL | - | 法人番号（13桁） |
| municipality_code | VARCHAR(6) | NULL | - | 全国地方公共団体コード（6桁） |
| postal_code | VARCHAR(10) | NULL | - | 郵便番号 |
| prefecture | VARCHAR(10) | NOT NULL | - | 都道府県 |
| city | VARCHAR(100) | NOT NULL | - | 市区町村 |
| address_line1 | VARCHAR(255) | NOT NULL | - | 住所1（番地） |
| address_line2 | VARCHAR(255) | NULL | - | 住所2（建物名） |
| phone_number | VARCHAR(20) | NULL | - | 電話番号 |
| fax_number | VARCHAR(20) | NULL | - | FAX番号 |
| email | VARCHAR(255) | NULL | - | メールアドレス |
| representative_name | VARCHAR(100) | NULL | - | 代表者名 |
| representative_title | VARCHAR(100) | NULL | - | 代表者役職 |
| is_headquarters | BOOLEAN | NOT NULL | false | 本部機能フラグ |
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

### CHECK制約

```sql
ALTER TABLE core.organizations ADD CONSTRAINT chk_organizations_corporate_number
    CHECK (
        (organization_type = 'corporation' AND corporate_number IS NOT NULL) OR
        (organization_type = 'municipality' AND municipality_code IS NOT NULL)
    );

ALTER TABLE core.organizations ADD CONSTRAINT chk_organizations_corporate_number_length
    CHECK (corporate_number IS NULL OR length(corporate_number) = 13);

ALTER TABLE core.organizations ADD CONSTRAINT chk_organizations_municipality_code_length
    CHECK (municipality_code IS NULL OR length(municipality_code) = 6);
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_organizations_tenant_id | tenant_id | テナント別組織一覧取得 |
| idx_organizations_type | organization_type | 組織タイプ別検索 |
| idx_organizations_municipality_code | municipality_code | 自治体コード検索 |
| idx_organizations_is_active | is_active | アクティブ組織検索 |

## 関連テーブル

- `core.tenants` - 所属テナント
- `core.facilities` - 配下の施設（1:N）
- `core.user_organization_history` - ユーザー所属履歴
- `hoiku.ingredients` - 組織食材マスタ
- `hoiku.menu_templates` - 本部献立テンプレート

## サンプルデータ

### 法人の例

```sql
INSERT INTO core.organizations (
    id, tenant_id, name, name_kana, organization_type,
    corporate_number, prefecture, city, address_line1,
    representative_name, representative_title, is_headquarters
) VALUES (
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '550e8400-e29b-41d4-a716-446655440000',
    '社会福祉法人さくら会',
    'シャカイフクシホウジンサクラカイ',
    'corporation',
    '1234567890123',
    '神奈川県',
    '横浜市港北区',
    '新横浜2-1-1',
    '佐藤太郎',
    '理事長',
    true
);
```

### 自治体の例

```sql
INSERT INTO core.organizations (
    id, tenant_id, name, name_kana, organization_type,
    municipality_code, prefecture, city, address_line1,
    is_headquarters
) VALUES (
    '6ba7b811-9dad-11d1-80b4-00c04fd430c8',
    '550e8400-e29b-41d4-a716-446655440001',
    '横浜市',
    'ヨコハマシ',
    'municipality',
    '141003',
    '神奈川県',
    '横浜市中区',
    '港町1-1',
    true
);
```

## ビジネスルール

### 法人の場合
- `corporate_number` は必須（13桁の法人番号）
- 国税庁の法人番号公表サイトで検証可能
- `is_headquarters = true` の組織は本部機能を持つ

### 自治体の場合
- `municipality_code` は必須（6桁の全国地方公共団体コード）
- 総務省の地方公共団体コード一覧で検証
- 自治体が直接施設を運営する場合、`is_headquarters = true`

### 本部機能
- `is_headquarters = true` の組織は以下の機能を持つ：
  - 献立テンプレートの作成・配布
  - 組織食材マスタの管理
  - 配下施設の一括設定変更
  - レポート集計

## 備考

- 1テナントに複数の組織が存在可能（M&A対応）
- 組織の物理削除は行わず、`is_active = false` で論理削除
- 法人番号・自治体コードの重複チェックはアプリケーション層で実施
