# テーブル定義書: hoiku.menus

## 概要

保育施設の献立情報を管理するテーブル。

## テーブル情報

| 項目 | 内容 |
|------|------|
| スキーマ名 | hoiku |
| テーブル名 | menus |
| 物理名 | hoiku.menus |
| 説明 | 献立情報 |

## カラム定義

| カラム名 | 物理名 | 型 | NULL | デフォルト | 説明 |
|---------|--------|-----|------|-----------|------|
| ID | id | UUID | NOT NULL | gen_random_uuid() | 主キー |
| テナントID | tenant_id | UUID | NOT NULL | - | テナントID（core.tenants参照） |
| 施設ID | facility_id | UUID | NOT NULL | - | 施設ID（core.facilities参照） |
| 献立日 | menu_date | DATE | NOT NULL | - | 献立提供日 |
| 食事区分 | meal_type | VARCHAR(50) | NOT NULL | - | 食事区分（breakfast, lunch, snack, dinner） |
| 献立名 | menu_name | VARCHAR(255) | NOT NULL | - | 献立名 |
| 説明 | description | TEXT | NULL | - | 献立の説明 |
| 対象年齢グループ | target_age_group | VARCHAR(50) | NULL | - | 対象年齢（0-1歳、1-2歳、3-5歳など） |
| ステータス | status | VARCHAR(20) | NOT NULL | 'draft' | ステータス（draft, published, archived） |
| 作成日時 | created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| 更新日時 | updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| 作成者 | created_by | UUID | NULL | - | 作成者のユーザーID |
| 更新者 | updated_by | UUID | NULL | - | 更新者のユーザーID |

## 制約

### 主キー

```sql
CONSTRAINT pk_menus PRIMARY KEY (id)
```

### インデックス

| インデックス名 | カラム | 種別 | 説明 |
|--------------|--------|------|------|
| idx_menus_tenant_id | tenant_id | INDEX | テナント検索 |
| idx_menus_facility_id | facility_id | INDEX | 施設検索 |
| idx_menus_menu_date | menu_date | INDEX | 日付検索 |
| idx_menus_meal_type | meal_type | INDEX | 食事区分検索 |

## DDL

```sql
CREATE TABLE hoiku.menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    facility_id UUID NOT NULL,
    menu_date DATE NOT NULL,
    meal_type VARCHAR(50) NOT NULL,
    menu_name VARCHAR(255) NOT NULL,
    description TEXT,
    target_age_group VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_menus_tenant_id ON hoiku.menus(tenant_id);
CREATE INDEX idx_menus_facility_id ON hoiku.menus(facility_id);
CREATE INDEX idx_menus_menu_date ON hoiku.menus(menu_date);
CREATE INDEX idx_menus_meal_type ON hoiku.menus(meal_type);

COMMENT ON TABLE hoiku.menus IS '献立情報';
COMMENT ON COLUMN hoiku.menus.id IS '主キー';
COMMENT ON COLUMN hoiku.menus.tenant_id IS 'テナントID';
COMMENT ON COLUMN hoiku.menus.facility_id IS '施設ID';
COMMENT ON COLUMN hoiku.menus.menu_date IS '献立提供日';
COMMENT ON COLUMN hoiku.menus.meal_type IS '食事区分（breakfast, lunch, snack, dinner）';
COMMENT ON COLUMN hoiku.menus.menu_name IS '献立名';
COMMENT ON COLUMN hoiku.menus.status IS 'ステータス（draft, published, archived）';
```

## サンプルデータ

```sql
INSERT INTO hoiku.menus (id, tenant_id, facility_id, menu_date, meal_type, menu_name, target_age_group, status) VALUES
('650e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440000', '2026-03-10', 'lunch', 'カレーライス', '3-5歳', 'published'),
('650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440000', '2026-03-10', 'snack', 'フルーツヨーグルト', '3-5歳', 'published'),
('650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440000', '2026-03-11', 'lunch', 'ハンバーグ定食', '3-5歳', 'draft');
```

## 関連テーブル

| テーブル | 関連 | 説明 |
|---------|------|------|
| hoiku.menu_ingredients | 1:N | 献立は複数の食材を持つ |
| core.tenants | N:1 | テナントに属する |
| core.facilities | N:1 | 施設に属する |

## ビジネスルール

1. **下書き→公開の遷移**: 下書き状態から公開に変更可能
2. **公開→アーカイブの遷移**: 公開済みの献立は削除ではなくアーカイブ
3. **食材必須**: 公開時は最低1つの食材が登録されている必要がある
4. **過去日付の制限**: 過去日付の献立は編集不可（参照のみ）

## 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|-----------|---------|--------|
| 2026-03-08 | 1.0.0 | 初版作成（テンプレート） | - |
