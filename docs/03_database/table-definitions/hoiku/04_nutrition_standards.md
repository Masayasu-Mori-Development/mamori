# 栄養基準テーブル (hoiku.nutrition_standards)

## 概要

自治体別・年齢グループ別の栄養摂取基準を管理するテーブル。
施設の所在地に応じて自動適用される。

## テーブル定義

```sql
CREATE TABLE hoiku.nutrition_standards (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_code     VARCHAR(6) NOT NULL REFERENCES core.municipality_codes(code),
    age_group_id          UUID NOT NULL REFERENCES hoiku.age_groups(id),
    standard_name         VARCHAR(255) NOT NULL,
    effective_from        DATE NOT NULL,
    effective_to          DATE,
    -- 昼食（給食）基準（1食あたり）
    lunch_energy_kcal     DECIMAL(10, 2) NOT NULL,
    lunch_protein_g       DECIMAL(10, 2) NOT NULL,
    lunch_fat_g           DECIMAL(10, 2),
    lunch_carbohydrate_g  DECIMAL(10, 2),
    lunch_calcium_mg      DECIMAL(10, 2),
    lunch_iron_mg         DECIMAL(10, 2),
    lunch_vitamin_a_ug    DECIMAL(10, 2),
    lunch_vitamin_b1_mg   DECIMAL(10, 2),
    lunch_vitamin_b2_mg   DECIMAL(10, 2),
    lunch_vitamin_c_mg    DECIMAL(10, 2),
    lunch_dietary_fiber_g DECIMAL(10, 2),
    lunch_salt_g          DECIMAL(10, 2),
    -- おやつ基準（1食あたり）
    snack_energy_kcal     DECIMAL(10, 2),
    snack_protein_g       DECIMAL(10, 2),
    -- メタデータ
    source_document       VARCHAR(255),
    notes                 TEXT,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by            UUID,
    updated_by            UUID,
    CONSTRAINT chk_nutrition_standards_dates CHECK (
        effective_to IS NULL OR effective_to >= effective_from
    )
);

CREATE INDEX idx_nutrition_standards_municipality ON hoiku.nutrition_standards(municipality_code);
CREATE INDEX idx_nutrition_standards_age_group ON hoiku.nutrition_standards(age_group_id);
CREATE INDEX idx_nutrition_standards_effective ON hoiku.nutrition_standards(effective_from, effective_to);
CREATE INDEX idx_nutrition_standards_active ON hoiku.nutrition_standards(is_active);
CREATE UNIQUE INDEX idx_nutrition_standards_unique ON hoiku.nutrition_standards(
    municipality_code, age_group_id, effective_from
) WHERE is_active = true;
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 基準ID（主キー） |
| municipality_code | VARCHAR(6) | NOT NULL | - | 自治体コード |
| age_group_id | UUID | NOT NULL | - | 年齢グループID |
| standard_name | VARCHAR(255) | NOT NULL | - | 基準名 |
| effective_from | DATE | NOT NULL | - | 有効開始日 |
| effective_to | DATE | NULL | - | 有効終了日 |
| lunch_energy_kcal | DECIMAL(10, 2) | NOT NULL | - | 昼食エネルギー |
| lunch_protein_g | DECIMAL(10, 2) | NOT NULL | - | 昼食たんぱく質 |
| ... | ... | ... | ... | その他の栄養素 |
| source_document | VARCHAR(255) | NULL | - | 根拠文書 |
| notes | TEXT | NULL | - | 備考 |
| is_active | BOOLEAN | NOT NULL | true | 有効フラグ |

## サンプルデータ

### 横浜市の栄養基準（0-1歳児）

```sql
INSERT INTO hoiku.nutrition_standards (
    municipality_code, age_group_id, standard_name,
    effective_from, lunch_energy_kcal, lunch_protein_g,
    lunch_calcium_mg, lunch_iron_mg, lunch_salt_g,
    snack_energy_kcal, snack_protein_g,
    source_document
) VALUES (
    '141003',  -- 横浜市鶴見区
    (SELECT id FROM hoiku.age_groups WHERE name = '0-1歳'),
    '横浜市保育所給食基準（令和7年度）',
    '2025-04-01',
    250,  -- エネルギー
    10.0, -- たんぱく質
    180,  -- カルシウム
    2.5,  -- 鉄
    1.2,  -- 食塩
    100,  -- おやつエネルギー
    3.0,  -- おやつたんぱく質
    '横浜市こども青少年局通知 令和7年3月'
);
```

## クエリ例

### 施設に適用される栄養基準を取得

```sql
SELECT ns.*
FROM hoiku.nutrition_standards ns
INNER JOIN core.facilities f ON ns.municipality_code = f.municipality_code
WHERE f.id = :facility_id
  AND ns.is_active = true
  AND CURRENT_DATE BETWEEN ns.effective_from AND COALESCE(ns.effective_to, '9999-12-31')
ORDER BY ns.age_group_id;
```

## ビジネスルール

### 自動適用ロジック
1. 施設作成時、`facility.municipality_code` から栄養基準を検索
2. 該当自治体の基準が見つからない場合、都道府県の標準基準を適用
3. 都道府県の基準もない場合、国の基準を適用

### バージョン管理
- 年度切り替え時に新しい基準を登録
- 旧基準は `effective_to` を設定して履歴化
- 過去献立の栄養計算は作成時点の基準を使用

## 備考

- 自治体ごとに微妙に異なる基準に対応
- 運営管理画面から一括インポート可能
