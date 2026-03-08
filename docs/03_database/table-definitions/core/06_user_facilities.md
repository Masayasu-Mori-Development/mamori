# ユーザー施設担当テーブル (core.user_facilities)

## 概要

ユーザーがどの施設を担当しているかを管理するテーブル。
施設異動の履歴も記録する。

## テーブル定義

```sql
CREATE TABLE core.user_facilities (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES core.tenants(id),
    user_id     UUID NOT NULL REFERENCES core.users(id),
    facility_id UUID NOT NULL REFERENCES core.facilities(id),
    start_date  DATE NOT NULL,
    end_date    DATE,
    is_primary  BOOLEAN NOT NULL DEFAULT false,
    role        VARCHAR(100),
    notes       TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by  UUID,
    updated_by  UUID,
    CONSTRAINT chk_user_facilities_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_user_facilities_tenant_id ON core.user_facilities(tenant_id);
CREATE INDEX idx_user_facilities_user_id ON core.user_facilities(user_id);
CREATE INDEX idx_user_facilities_facility_id ON core.user_facilities(facility_id);
CREATE INDEX idx_user_facilities_current ON core.user_facilities(user_id, facility_id) WHERE end_date IS NULL;
CREATE UNIQUE INDEX idx_user_facilities_primary ON core.user_facilities(user_id) WHERE is_primary = true AND end_date IS NULL;
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 担当ID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID（外部キー） |
| user_id | UUID | NOT NULL | - | ユーザーID（外部キー） |
| facility_id | UUID | NOT NULL | - | 施設ID（外部キー） |
| start_date | DATE | NOT NULL | - | 担当開始日 |
| end_date | DATE | NULL | - | 担当終了日（NULL=現在担当中） |
| is_primary | BOOLEAN | NOT NULL | false | 主担当フラグ |
| role | VARCHAR(100) | NULL | - | 施設内での役割 |
| notes | TEXT | NULL | - | 備考 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者（users.id） |
| updated_by | UUID | NULL | - | 更新者（users.id） |

## 制約

### 主キー
- `PRIMARY KEY (id)`

### 外部キー
- `FOREIGN KEY (tenant_id) REFERENCES core.tenants(id)`
- `FOREIGN KEY (user_id) REFERENCES core.users(id)`
- `FOREIGN KEY (facility_id) REFERENCES core.facilities(id)`

### ユニーク制約
- ユーザーごとに主担当施設は1つのみ（`is_primary = true AND end_date IS NULL`）

### CHECK制約

```sql
ALTER TABLE core.user_facilities ADD CONSTRAINT chk_user_facilities_role
    CHECK (role IN ('施設長', '栄養士', '調理師', '保育士', '事務', 'その他'));
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_user_facilities_tenant_id | tenant_id | テナント別検索 |
| idx_user_facilities_user_id | user_id | ユーザーの担当施設一覧 |
| idx_user_facilities_facility_id | facility_id | 施設の担当者一覧 |
| idx_user_facilities_current | user_id, facility_id (WHERE end_date IS NULL) | 現在の担当検索 |
| idx_user_facilities_primary | user_id (WHERE is_primary = true AND end_date IS NULL) | 主担当施設検索（ユニーク） |

## 関連テーブル

- `core.tenants` - テナント
- `core.users` - ユーザー
- `core.facilities` - 施設

## サンプルデータ

### 主担当施設

```sql
INSERT INTO core.user_facilities (
    id, tenant_id, user_id, facility_id,
    start_date, end_date, is_primary, role
) VALUES (
    'f1e2d3c4-b5a6-7890-cdef-123456789abc',
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '123e4567-e89b-12d3-a456-426614174000',
    '2024-04-01',
    NULL,  -- 現在担当中
    true,  -- 主担当
    '栄養士'
);
```

### 兼務施設

```sql
INSERT INTO core.user_facilities (
    id, tenant_id, user_id, facility_id,
    start_date, end_date, is_primary, role
) VALUES (
    'f2e3d4c5-b6a7-8901-defg-234567890bcd',
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '123e4567-e89b-12d3-a456-426614174001',
    '2024-06-01',
    NULL,  -- 現在担当中
    false, -- 兼務
    '栄養士'
);
```

### 過去の担当

```sql
INSERT INTO core.user_facilities (
    id, tenant_id, user_id, facility_id,
    start_date, end_date, is_primary, role, notes
) VALUES (
    'f3e4d5c6-b7a8-9012-efgh-345678901cde',
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '123e4567-e89b-12d3-a456-426614174002',
    '2023-04-01',
    '2024-03-31',
    true,
    '栄養士',
    '施設異動のため担当終了'
);
```

## クエリ例

### ユーザーの現在担当施設を取得

```sql
SELECT f.*, uf.is_primary, uf.role
FROM core.facilities f
INNER JOIN core.user_facilities uf ON f.id = uf.facility_id
WHERE uf.user_id = :user_id
  AND uf.tenant_id = :tenant_id
  AND uf.end_date IS NULL
ORDER BY uf.is_primary DESC, f.name;
```

### 施設の現在担当者を取得

```sql
SELECT u.*, uf.is_primary, uf.role
FROM core.users u
INNER JOIN core.user_facilities uf ON u.id = uf.user_id
WHERE uf.facility_id = :facility_id
  AND uf.tenant_id = :tenant_id
  AND uf.end_date IS NULL
ORDER BY uf.is_primary DESC, uf.role, u.family_name;
```

### ユーザーの主担当施設を取得

```sql
SELECT f.*
FROM core.facilities f
INNER JOIN core.user_facilities uf ON f.id = uf.facility_id
WHERE uf.user_id = :user_id
  AND uf.tenant_id = :tenant_id
  AND uf.is_primary = true
  AND uf.end_date IS NULL;
```

## ビジネスルール

### 主担当施設
- ユーザーは必ず1つの主担当施設を持つ
- `is_primary = true` は現在担当中（`end_date IS NULL`）の施設のうち1つのみ
- ユーザーのログイン時、主担当施設がデフォルトで選択される

### 兼務
- ユーザーは複数の施設を担当可能
- `is_primary = false` で兼務施設を登録
- 権限は施設ごとに個別設定可能

### 施設異動
- 異動時は既存レコードに `end_date` を設定
- 新しい施設への担当レコードを作成
- `is_primary` は新しい施設に移動

### アクセス制御
- ユーザーは担当施設のデータのみアクセス可能
- 組織管理者は配下全施設にアクセス可能
- 本部管理者は全施設にアクセス可能

## 備考

- 履歴データは物理削除しない
- 監査証跡として保持
- 施設担当の履歴を完全に追跡可能
- `role` は参考情報（権限管理は別途 `core.roles` で実施）
