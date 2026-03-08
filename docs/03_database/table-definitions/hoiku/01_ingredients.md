# 食材マスタテーブル (hoiku.ingredients)

## 概要

食材の栄養情報・アレルギー情報・廃棄率などを管理するテーブル。
3階層のマスタ構造（システム → 組織 → 施設）を実現。

## テーブル定義

```sql
CREATE TYPE ingredient_level AS ENUM (
    'system',       -- システムマスタ（運営管理）
    'organization', -- 組織マスタ
    'facility'      -- 施設マスタ
);

CREATE TABLE hoiku.ingredients (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID REFERENCES core.tenants(id),
    organization_id      UUID REFERENCES core.organizations(id),
    facility_id          UUID REFERENCES core.facilities(id),
    parent_ingredient_id UUID REFERENCES hoiku.ingredients(id),
    level                ingredient_level NOT NULL,
    code                 VARCHAR(50) NOT NULL,
    name                 VARCHAR(255) NOT NULL,
    name_kana            VARCHAR(255),
    category             VARCHAR(100),
    unit                 VARCHAR(20) NOT NULL DEFAULT 'g',
    standard_amount      DECIMAL(10, 2),
    waste_rate           DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    -- 栄養成分（100g あたり）
    energy_kcal          DECIMAL(10, 2),
    protein_g            DECIMAL(10, 2),
    fat_g                DECIMAL(10, 2),
    carbohydrate_g       DECIMAL(10, 2),
    sodium_mg            DECIMAL(10, 2),
    calcium_mg           DECIMAL(10, 2),
    iron_mg              DECIMAL(10, 2),
    vitamin_a_ug         DECIMAL(10, 2),
    vitamin_b1_mg        DECIMAL(10, 2),
    vitamin_b2_mg        DECIMAL(10, 2),
    vitamin_c_mg         DECIMAL(10, 2),
    dietary_fiber_g      DECIMAL(10, 2),
    salt_equivalent_g    DECIMAL(10, 2),
    -- アレルギー情報
    allergens            TEXT[],
    -- フラグ
    is_active            BOOLEAN NOT NULL DEFAULT true,
    is_seasonal          BOOLEAN NOT NULL DEFAULT false,
    season_start_month   INTEGER,
    season_end_month     INTEGER,
    notes                TEXT,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           UUID,
    updated_by           UUID,
    CONSTRAINT chk_ingredients_level_tenant CHECK (
        (level = 'system' AND tenant_id IS NULL) OR
        (level != 'system' AND tenant_id IS NOT NULL)
    ),
    CONSTRAINT chk_ingredients_level_organization CHECK (
        (level = 'organization' AND organization_id IS NOT NULL) OR
        (level != 'organization' AND organization_id IS NULL)
    ),
    CONSTRAINT chk_ingredients_level_facility CHECK (
        (level = 'facility' AND facility_id IS NOT NULL) OR
        (level != 'facility' AND facility_id IS NULL)
    ),
    CONSTRAINT chk_ingredients_waste_rate CHECK (waste_rate >= 0 AND waste_rate <= 100),
    CONSTRAINT chk_ingredients_season_months CHECK (
        (is_seasonal = false) OR
        (season_start_month BETWEEN 1 AND 12 AND season_end_month BETWEEN 1 AND 12)
    )
);

CREATE INDEX idx_ingredients_tenant_id ON hoiku.ingredients(tenant_id);
CREATE INDEX idx_ingredients_organization_id ON hoiku.ingredients(organization_id);
CREATE INDEX idx_ingredients_facility_id ON hoiku.ingredients(facility_id);
CREATE INDEX idx_ingredients_parent_id ON hoiku.ingredients(parent_ingredient_id);
CREATE INDEX idx_ingredients_level ON hoiku.ingredients(level);
CREATE INDEX idx_ingredients_code ON hoiku.ingredients(code);
CREATE INDEX idx_ingredients_name ON hoiku.ingredients(name);
CREATE INDEX idx_ingredients_category ON hoiku.ingredients(category);
CREATE INDEX idx_ingredients_is_active ON hoiku.ingredients(is_active);
CREATE INDEX idx_ingredients_allergens ON hoiku.ingredients USING GIN(allergens);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 食材ID（主キー） |
| tenant_id | UUID | NULL | - | テナントID（system以外で必須） |
| organization_id | UUID | NULL | - | 組織ID（organization levelで必須） |
| facility_id | UUID | NULL | - | 施設ID（facility levelで必須） |
| parent_ingredient_id | UUID | NULL | - | 親食材ID（継承元） |
| level | ingredient_level | NOT NULL | - | マスタレベル |
| code | VARCHAR(50) | NOT NULL | - | 食材コード |
| name | VARCHAR(255) | NOT NULL | - | 食材名 |
| name_kana | VARCHAR(255) | NULL | - | 食材名（カナ） |
| category | VARCHAR(100) | NULL | - | 分類（穀類/野菜/肉類等） |
| unit | VARCHAR(20) | NOT NULL | 'g' | 単位 |
| standard_amount | DECIMAL(10, 2) | NULL | - | 標準使用量 |
| waste_rate | DECIMAL(5, 2) | NOT NULL | 0.00 | 廃棄率（%） |
| energy_kcal | DECIMAL(10, 2) | NULL | - | エネルギー（100gあたり） |
| protein_g | DECIMAL(10, 2) | NULL | - | たんぱく質（100gあたり） |
| fat_g | DECIMAL(10, 2) | NULL | - | 脂質（100gあたり） |
| carbohydrate_g | DECIMAL(10, 2) | NULL | - | 炭水化物（100gあたり） |
| sodium_mg | DECIMAL(10, 2) | NULL | - | ナトリウム（100gあたり） |
| calcium_mg | DECIMAL(10, 2) | NULL | - | カルシウム（100gあたり） |
| iron_mg | DECIMAL(10, 2) | NULL | - | 鉄（100gあたり） |
| vitamin_a_ug | DECIMAL(10, 2) | NULL | - | ビタミンA（100gあたり） |
| vitamin_b1_mg | DECIMAL(10, 2) | NULL | - | ビタミンB1（100gあたり） |
| vitamin_b2_mg | DECIMAL(10, 2) | NULL | - | ビタミンB2（100gあたり） |
| vitamin_c_mg | DECIMAL(10, 2) | NULL | - | ビタミンC（100gあたり） |
| dietary_fiber_g | DECIMAL(10, 2) | NULL | - | 食物繊維（100gあたり） |
| salt_equivalent_g | DECIMAL(10, 2) | NULL | - | 食塩相当量（100gあたり） |
| allergens | TEXT[] | NULL | - | アレルゲン一覧 |
| is_active | BOOLEAN | NOT NULL | true | 有効フラグ |
| is_seasonal | BOOLEAN | NOT NULL | false | 季節食材フラグ |
| season_start_month | INTEGER | NULL | - | 旬の開始月（1-12） |
| season_end_month | INTEGER | NULL | - | 旬の終了月（1-12） |
| notes | TEXT | NULL | - | 備考 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者 |
| updated_by | UUID | NULL | - | 更新者 |

## サンプルデータ

### システムマスタ（運営管理者が登録）

```sql
INSERT INTO hoiku.ingredients (
    level, code, name, name_kana, category, unit, waste_rate,
    energy_kcal, protein_g, fat_g, carbohydrate_g, calcium_mg, iron_mg,
    allergens
) VALUES (
    'system', 'SYS-001', '精白米', 'セイハクマイ', '穀類', 'g', 0,
    358, 6.1, 0.9, 77.6, 5, 0.8,
    ARRAY[]::TEXT[]
),
(
    'system', 'SYS-002', '鶏卵', 'ケイラン', '卵類', 'g', 13,
    151, 12.3, 10.3, 0.3, 51, 1.8,
    ARRAY['卵']::TEXT[]
),
(
    'system', 'SYS-003', '牛乳', 'ギュウニュウ', '乳類', 'ml', 0,
    67, 3.3, 3.8, 4.8, 110, 0.02,
    ARRAY['乳']::TEXT[]
),
(
    'system', 'SYS-004', 'にんじん', 'ニンジン', '野菜類', 'g', 10,
    37, 0.6, 0.1, 9.3, 28, 0.2,
    ARRAY[]::TEXT[], true, 12, 3
),
(
    'system', 'SYS-005', '小麦粉（薄力粉）', 'コムギコ', '穀類', 'g', 0,
    368, 8.0, 1.7, 75.9, 17, 0.6,
    ARRAY['小麦']::TEXT[]
);
```

### 組織マスタ（システムマスタから継承＋カスタマイズ）

```sql
INSERT INTO hoiku.ingredients (
    tenant_id, organization_id, parent_ingredient_id,
    level, code, name, category, unit, waste_rate,
    energy_kcal, protein_g, fat_g, carbohydrate_g, notes
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    (SELECT id FROM hoiku.ingredients WHERE code = 'SYS-001' AND level = 'system'),
    'organization', 'ORG-SAK-001', '有機栽培米', '穀類', 'g', 0,
    360, 6.2, 1.0, 77.5,
    'さくら会専用の有機米'
);
```

### 施設マスタ（組織マスタから継承＋施設固有食材）

```sql
INSERT INTO hoiku.ingredients (
    tenant_id, organization_id, facility_id, parent_ingredient_id,
    level, code, name, category, unit, waste_rate,
    energy_kcal, protein_g, notes
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '123e4567-e89b-12d3-a456-426614174000',
    (SELECT id FROM hoiku.ingredients WHERE code = 'ORG-SAK-001'),
    'facility', 'FAC-SYH-001', '有機栽培米（新横浜園）', '穀類', 'g', 0,
    360, 6.2,
    '新横浜園で使用する有機米'
);
```

## 継承ロジック

### 栄養値の継承クエリ

```sql
WITH RECURSIVE ingredient_hierarchy AS (
    -- 対象の食材
    SELECT *
    FROM hoiku.ingredients
    WHERE id = :ingredient_id

    UNION ALL

    -- 親食材を再帰的に取得
    SELECT i.*
    FROM hoiku.ingredients i
    INNER JOIN ingredient_hierarchy ih ON i.id = ih.parent_ingredient_id
)
SELECT
    COALESCE(current.energy_kcal, parent.energy_kcal, grandparent.energy_kcal) AS energy_kcal,
    COALESCE(current.protein_g, parent.protein_g, grandparent.protein_g) AS protein_g,
    -- ... その他の栄養素
FROM ingredient_hierarchy
ORDER BY level DESC;  -- system < organization < facility の順
```

## アレルゲン一覧

特定原材料（表示義務7品目）:
- 卵
- 乳
- 小麦
- えび
- かに
- 落花生（ピーナッツ）
- そば

特定原材料に準ずるもの（推奨21品目）:
- アーモンド、あわび、いか、いくら、オレンジ、カシューナッツ、キウイフルーツ
- 牛肉、くるみ、ごま、さけ、さば、大豆、鶏肉、バナナ、豚肉、まつたけ
- もも、やまいも、りんご、ゼラチン

## クエリ例

### 施設で利用可能な全食材を取得

```sql
-- システムマスタ + 組織マスタ + 施設マスタを統合
SELECT * FROM hoiku.ingredients
WHERE is_active = true
  AND (
      level = 'system'
      OR (level = 'organization' AND organization_id = :organization_id)
      OR (level = 'facility' AND facility_id = :facility_id)
  )
ORDER BY category, name;
```

### アレルゲンで絞り込み

```sql
SELECT * FROM hoiku.ingredients
WHERE is_active = true
  AND NOT ('卵' = ANY(allergens))
  AND NOT ('乳' = ANY(allergens));
```

## ビジネスルール

### 3階層マスタの優先順位
1. **施設マスタ**: 施設固有の食材（最優先）
2. **組織マスタ**: 組織共通の食材
3. **システムマスタ**: 全テナント共通の食材

### 継承ルール
- `parent_ingredient_id` で親食材を参照
- 未設定の栄養値は親から継承
- 施設は組織またはシステムから、組織はシステムから継承可能

### 廃棄率の適用
```
正味量 = 購入量 × (1 - 廃棄率 / 100)
```

## 備考

- 栄養成分は文部科学省「日本食品標準成分表」に準拠
- 物理削除は行わず、`is_active = false` で論理削除
- 季節食材は旬の時期に推奨表示
