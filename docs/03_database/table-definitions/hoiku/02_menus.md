# 献立テーブル (hoiku.menus)

## 概要

施設の日次献立を管理するテーブル。
朝食・昼食・おやつなどの食事区分ごとに献立を作成。

## テーブル定義

```sql
CREATE TYPE meal_type AS ENUM (
    'breakfast',    -- 朝食
    'lunch',        -- 昼食
    'snack',        -- おやつ
    'dinner'        -- 夕食
);

CREATE TYPE menu_status AS ENUM (
    'draft',        -- 下書き
    'pending',      -- 承認待ち
    'approved',     -- 承認済み
    'published'     -- 公開済み
);

CREATE TABLE hoiku.menus (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES core.tenants(id),
    facility_id        UUID NOT NULL REFERENCES core.facilities(id),
    menu_template_id   UUID REFERENCES hoiku.menu_templates(id),
    date               DATE NOT NULL,
    meal_type          meal_type NOT NULL,
    title              VARCHAR(255),
    description        TEXT,
    status             menu_status NOT NULL DEFAULT 'draft',
    total_servings     INTEGER NOT NULL DEFAULT 0,
    estimated_cost     DECIMAL(10, 2),
    approved_by        UUID REFERENCES core.users(id),
    approved_at        TIMESTAMP,
    published_by       UUID REFERENCES core.users(id),
    published_at       TIMESTAMP,
    notes              TEXT,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         UUID,
    updated_by         UUID,
    UNIQUE(facility_id, date, meal_type)
);

CREATE INDEX idx_menus_tenant_id ON hoiku.menus(tenant_id);
CREATE INDEX idx_menus_facility_id ON hoiku.menus(facility_id);
CREATE INDEX idx_menus_date ON hoiku.menus(date);
CREATE INDEX idx_menus_meal_type ON hoiku.menus(meal_type);
CREATE INDEX idx_menus_status ON hoiku.menus(status);
CREATE INDEX idx_menus_template_id ON hoiku.menus(menu_template_id);
CREATE INDEX idx_menus_facility_date_range ON hoiku.menus(facility_id, date);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 献立ID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID |
| facility_id | UUID | NOT NULL | - | 施設ID |
| menu_template_id | UUID | NULL | - | テンプレート献立ID（継承元） |
| date | DATE | NOT NULL | - | 提供日 |
| meal_type | meal_type | NOT NULL | - | 食事区分 |
| title | VARCHAR(255) | NULL | - | 献立名 |
| description | TEXT | NULL | - | 説明 |
| status | menu_status | NOT NULL | draft | ステータス |
| total_servings | INTEGER | NOT NULL | 0 | 総提供数 |
| estimated_cost | DECIMAL(10, 2) | NULL | - | 推定コスト |
| approved_by | UUID | NULL | - | 承認者 |
| approved_at | TIMESTAMP | NULL | - | 承認日時 |
| published_by | UUID | NULL | - | 公開者 |
| published_at | TIMESTAMP | NULL | - | 公開日時 |
| notes | TEXT | NULL | - | 備考 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者 |
| updated_by | UUID | NULL | - | 更新者 |

## サンプルデータ

```sql
INSERT INTO hoiku.menus (
    id, tenant_id, facility_id, date, meal_type,
    title, description, status, total_servings,
    created_by
) VALUES (
    'aa11bb22-cc33-dd44-ee55-ff6677889900',
    '550e8400-e29b-41d4-a716-446655440000',
    '123e4567-e89b-12d3-a456-426614174000',
    '2025-03-10',
    'lunch',
    '春の彩り給食',
    'たけのこご飯、鶏の照り焼き、菜の花のおひたし、お味噌汁',
    'approved',
    60,
    '7c9e6679-7425-40de-944b-e07fc1f90ae7'
);
```

## クエリ例

### 月次献立カレンダー取得

```sql
SELECT
    date,
    meal_type,
    title,
    status
FROM hoiku.menus
WHERE facility_id = :facility_id
  AND date BETWEEN :start_date AND :end_date
ORDER BY date, meal_type;
```

### 承認待ち献立を取得

```sql
SELECT
    m.*,
    f.name AS facility_name,
    u.family_name || u.given_name AS creator_name
FROM hoiku.menus m
INNER JOIN core.facilities f ON m.facility_id = f.id
INNER JOIN core.users u ON m.created_by = u.id
WHERE m.tenant_id = :tenant_id
  AND m.status = 'pending'
ORDER BY m.date;
```

## ビジネスルール

### ステータス遷移
```
draft → pending → approved → published
         ↓          ↓
      (差戻し)   (差戻し)
```

### 承認ワークフロー
1. 栄養士が下書き作成（`status = 'draft'`）
2. 承認依頼（`status = 'pending'`）
3. 施設長が承認（`status = 'approved'`）
4. 保護者向けに公開（`status = 'published'`）

## 備考

- 同一施設・同一日・同一食事区分は1件のみ（UNIQUE制約）
- テンプレート献立から複製可能
- 物理削除は行わず、ステータス管理で対応
