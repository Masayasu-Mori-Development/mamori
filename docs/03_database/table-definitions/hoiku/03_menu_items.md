# 献立明細テーブル (hoiku.menu_items)

## 概要

献立に含まれる料理（メニュー項目）と使用食材を管理するテーブル。

## テーブル定義

```sql
CREATE TABLE hoiku.menu_items (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES core.tenants(id),
    menu_id        UUID NOT NULL REFERENCES hoiku.menus(id) ON DELETE CASCADE,
    dish_name      VARCHAR(255) NOT NULL,
    dish_order     INTEGER NOT NULL DEFAULT 0,
    cooking_method VARCHAR(100),
    notes          TEXT,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hoiku.menu_item_ingredients (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES core.tenants(id),
    menu_item_id   UUID NOT NULL REFERENCES hoiku.menu_items(id) ON DELETE CASCADE,
    ingredient_id  UUID NOT NULL REFERENCES hoiku.ingredients(id),
    amount         DECIMAL(10, 2) NOT NULL,
    unit           VARCHAR(20) NOT NULL DEFAULT 'g',
    notes          TEXT,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(menu_item_id, ingredient_id)
);

CREATE INDEX idx_menu_items_tenant_id ON hoiku.menu_items(tenant_id);
CREATE INDEX idx_menu_items_menu_id ON hoiku.menu_items(menu_id);
CREATE INDEX idx_menu_item_ingredients_menu_item_id ON hoiku.menu_item_ingredients(menu_item_id);
CREATE INDEX idx_menu_item_ingredients_ingredient_id ON hoiku.menu_item_ingredients(ingredient_id);
```

## サンプルデータ

### 献立明細

```sql
INSERT INTO hoiku.menu_items (
    tenant_id, menu_id, dish_name, dish_order, cooking_method
) VALUES
(
    '550e8400-e29b-41d4-a716-446655440000',
    'aa11bb22-cc33-dd44-ee55-ff6677889900',
    'たけのこご飯',
    1,
    '炊飯'
),
(
    '550e8400-e29b-41d4-a716-446655440000',
    'aa11bb22-cc33-dd44-ee55-ff6677889900',
    '鶏の照り焼き',
    2,
    'フライパン焼き'
);
```

### 食材明細

```sql
INSERT INTO hoiku.menu_item_ingredients (
    tenant_id, menu_item_id, ingredient_id, amount, unit
) VALUES
(
    '550e8400-e29b-41d4-a716-446655440000',
    (SELECT id FROM hoiku.menu_items WHERE dish_name = 'たけのこご飯'),
    (SELECT id FROM hoiku.ingredients WHERE code = 'SYS-001'),
    50,
    'g'
),
(
    '550e8400-e29b-41d4-a716-446655440000',
    (SELECT id FROM hoiku.menu_items WHERE dish_name = 'たけのこご飯'),
    (SELECT id FROM hoiku.ingredients WHERE name = 'たけのこ(水煮)'),
    15,
    'g'
);
```

## 備考

- `ON DELETE CASCADE` で献立削除時に自動削除
- 料理の順番は `dish_order` で管理
