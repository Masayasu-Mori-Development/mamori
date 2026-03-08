# 全国地方公共団体コードマスタ (core.municipality_codes)

## 概要

総務省が定める全国地方公共団体コード（6桁）のマスタテーブル。
施設の所在地を管理し、自治体別の栄養基準を自動適用するために使用。

## テーブル定義

```sql
CREATE TABLE core.municipality_codes (
    code            VARCHAR(6) PRIMARY KEY,
    prefecture_code VARCHAR(2) NOT NULL,
    prefecture_name VARCHAR(10) NOT NULL,
    city_name       VARCHAR(100) NOT NULL,
    full_name       VARCHAR(110) NOT NULL,
    prefecture_kana VARCHAR(20),
    city_kana       VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    effective_from  DATE,
    effective_to    DATE,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_municipality_codes_prefecture ON core.municipality_codes(prefecture_code);
CREATE INDEX idx_municipality_codes_active ON core.municipality_codes(is_active);
CREATE INDEX idx_municipality_codes_full_name ON core.municipality_codes(full_name);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| code | VARCHAR(6) | NOT NULL | - | 全国地方公共団体コード（主キー） |
| prefecture_code | VARCHAR(2) | NOT NULL | - | 都道府県コード（JIS X 0401） |
| prefecture_name | VARCHAR(10) | NOT NULL | - | 都道府県名 |
| city_name | VARCHAR(100) | NOT NULL | - | 市区町村名 |
| full_name | VARCHAR(110) | NOT NULL | - | 完全名（都道府県+市区町村） |
| prefecture_kana | VARCHAR(20) | NULL | - | 都道府県名（カナ） |
| city_kana | VARCHAR(100) | NULL | - | 市区町村名（カナ） |
| is_active | BOOLEAN | NOT NULL | true | 有効フラグ |
| effective_from | DATE | NULL | - | 有効開始日 |
| effective_to | DATE | NULL | - | 有効終了日 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |

## 制約

### 主キー
- `PRIMARY KEY (code)`

### CHECK制約

```sql
ALTER TABLE core.municipality_codes ADD CONSTRAINT chk_municipality_codes_code_length
    CHECK (length(code) = 6);

ALTER TABLE core.municipality_codes ADD CONSTRAINT chk_municipality_codes_prefecture_code_length
    CHECK (length(prefecture_code) = 2);

ALTER TABLE core.municipality_codes ADD CONSTRAINT chk_municipality_codes_dates
    CHECK (effective_to IS NULL OR effective_to >= effective_from);
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_municipality_codes_prefecture | prefecture_code | 都道府県別検索 |
| idx_municipality_codes_active | is_active | 有効な自治体検索 |
| idx_municipality_codes_full_name | full_name | 自治体名検索 |

## 関連テーブル

- `core.facilities` - 施設所在地
- `core.organizations` - 自治体組織
- `hoiku.nutrition_standards` - 自治体別栄養基準

## サンプルデータ

### 都道府県（北海道の例）

```sql
INSERT INTO core.municipality_codes (
    code, prefecture_code, prefecture_name, city_name, full_name,
    prefecture_kana, city_kana, effective_from
) VALUES
('010006', '01', '北海道', '札幌市', '北海道札幌市', 'ホッカイドウ', 'サッポロシ', '1972-04-01'),
('011002', '01', '北海道', '札幌市中央区', '北海道札幌市中央区', 'ホッカイドウ', 'サッポロシチュウオウク', '1972-04-01'),
('012025', '01', '北海道', '函館市', '北海道函館市', 'ホッカイドウ', 'ハコダテシ', '1922-08-01');
```

### 神奈川県の主要自治体

```sql
INSERT INTO core.municipality_codes (
    code, prefecture_code, prefecture_name, city_name, full_name,
    prefecture_kana, city_kana, effective_from
) VALUES
('140007', '14', '神奈川県', '横浜市', '神奈川県横浜市', 'カナガワケン', 'ヨコハマシ', '1889-04-01'),
('141003', '14', '神奈川県', '横浜市鶴見区', '神奈川県横浜市鶴見区', 'カナガワケン', 'ヨコハマシツルミク', '1927-10-01'),
('141011', '14', '神奈川県', '横浜市神奈川区', '神奈川県横浜市神奈川区', 'カナガワケン', 'ヨコハマシカナガワク', '1927-10-01'),
('141305', '14', '神奈川県', '横浜市港北区', '神奈川県横浜市港北区', 'カナガワケン', 'ヨコハマシコウホクク', '1939-04-01'),
('141500', '14', '神奈川県', '川崎市', '神奈川県川崎市', 'カナガワケン', 'カワサキシ', '1924-07-01'),
('142018', '14', '神奈川県', '相模原市', '神奈川県相模原市', 'カナガワケン', 'サガミハラシ', '1954-11-20');
```

### 廃止された自治体の例

```sql
INSERT INTO core.municipality_codes (
    code, prefecture_code, prefecture_name, city_name, full_name,
    prefecture_kana, city_kana, is_active, effective_from, effective_to
) VALUES
('142301', '14', '神奈川県', '津久井町', '神奈川県津久井町', 'カナガワケン', 'ツクイマチ',
    false, '1955-02-11', '2007-03-11');  -- 相模原市に編入
```

## データ投入

### 初期データ投入

```sql
-- 全国1,741自治体（2024年時点）のデータを投入
-- データソース: 総務省「全国地方公共団体コード」
-- https://www.soumu.go.jp/denshijiti/code.html

COPY core.municipality_codes (
    code, prefecture_code, prefecture_name, city_name, full_name,
    prefecture_kana, city_kana, effective_from
) FROM '/path/to/municipality_codes.csv' CSV HEADER;
```

## ビジネスルール

### コード体系
- 1〜2桁目: 都道府県コード（JIS X 0401）
- 3〜6桁目: 市区町村コード
- 例: `141003` = 神奈川県（14） + 横浜市鶴見区（1003）

### 自治体統廃合への対応
- 統廃合で廃止された自治体は `is_active = false` に設定
- `effective_to` に廃止日を記録
- 既存施設の `municipality_code` は変更しない（履歴保持）
- 新設自治体は新しいコードで登録

### 栄養基準の自動適用
1. 施設作成時に `municipality_code` を設定
2. `hoiku.nutrition_standards` から該当自治体の基準を検索
3. 基準が見つからない場合、都道府県の標準基準を適用
4. 都道府県の基準もない場合、国の標準基準を適用

## メンテナンス

### 年次更新
- 総務省が年1回（4月1日）更新
- 統廃合情報を反映
- 運営管理画面から CSV インポート機能で更新

### データ整合性チェック
```sql
-- 使用されているコードが有効かチェック
SELECT f.id, f.name, f.municipality_code
FROM core.facilities f
LEFT JOIN core.municipality_codes mc ON f.municipality_code = mc.code
WHERE mc.code IS NULL OR mc.is_active = false;
```

## 備考

- このテーブルは全テナント共通のマスタデータ
- `tenant_id` は持たない
- 運営管理画面（admin-frontend）からのみ更新可能
- 顧客画面（hoiku-frontend）からは参照のみ
- 物理削除は行わず、`is_active = false` で論理削除
