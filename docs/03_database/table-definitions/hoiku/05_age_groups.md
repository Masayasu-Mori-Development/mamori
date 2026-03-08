# 年齢グループテーブル (hoiku.age_groups)

## 概要

保育施設における年齢グループ区分を管理するテーブル。
栄養基準・献立・提供数の管理単位。

## テーブル定義

```sql
CREATE TABLE hoiku.age_groups (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    min_age_months INTEGER NOT NULL,
    max_age_months INTEGER NOT NULL,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_age_groups_age_range CHECK (max_age_months >= min_age_months)
);

CREATE INDEX idx_age_groups_active ON hoiku.age_groups(is_active);
CREATE INDEX idx_age_groups_sort_order ON hoiku.age_groups(sort_order);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 年齢グループID |
| name | VARCHAR(100) | NOT NULL | - | グループ名（一意） |
| display_name | VARCHAR(100) | NOT NULL | - | 表示名 |
| min_age_months | INTEGER | NOT NULL | - | 最小月齢 |
| max_age_months | INTEGER | NOT NULL | - | 最大月齢 |
| sort_order | INTEGER | NOT NULL | 0 | 表示順 |
| description | TEXT | NULL | - | 説明 |
| is_active | BOOLEAN | NOT NULL | true | 有効フラグ |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |

## デフォルトデータ

```sql
INSERT INTO hoiku.age_groups (name, display_name, min_age_months, max_age_months, sort_order, description) VALUES
('0-1歳', '0-1歳児', 0, 23, 1, '離乳食期〜完了期'),
('1-2歳', '1-2歳児', 12, 35, 2, '幼児食移行期'),
('3-5歳', '3-5歳児', 36, 71, 3, '幼児食期');
```

## 備考

- システム共通マスタ（全テナント共通）
- 運営管理画面からのみ編集可能
