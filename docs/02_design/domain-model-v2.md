# ドメインモデル v2.0

全国展開前提の詳細設計

## 更新履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2026-03-08 | 2.0.0 | 全国展開前提で再設計 |
| 2026-03-08 | 1.0.0 | 初版作成 |

## ビジネス要件の再整理

### 対象顧客

1. **保育施設（法人運営）**
   - 社会福祉法人、株式会社、NPO法人など
   - 複数施設を運営する法人を想定
   - 本部で献立を一括管理し、各施設に配布

2. **保育施設（自治体直営）**
   - 市区町村が直営する公立保育園
   - 自治体が組織として複数施設を運営
   - 例: 横浜市が「横浜市立○○保育園」を複数運営

3. **自治体（監査側）**
   - 保育施設の監査・指導を行う行政機関
   - 献立の栄養基準チェック
   - 将来的に自治体向け機能を提供

### 全国展開前提の設計

- **初期**: 横浜市対応（MVP）
- **次期**: 神奈川県内の他自治体
- **中期**: 関東圏
- **長期**: 全国47都道府県

最初から全国対応できるデータ構造を設計する。

## ドメインモデル概要

### Core Domain（共通機能）

| エンティティ | 説明 | 主な属性 |
|------------|------|---------|
| **Tenant** | テナント（契約単位） | SaaS契約の単位 |
| **Organization** | 組織（法人・自治体） | 法人または自治体 |
| **Facility** | 施設（保育園） | 個別の保育施設 |
| **User** | ユーザー | システム利用者 |
| **Role** | 役割 | システム権限 |
| **UserOrganizationHistory** | ユーザー所属履歴 | 入退社・異動履歴 |
| **Prefecture** | 都道府県マスタ | 全国47都道府県 |
| **Municipality** | 自治体マスタ | 市区町村 |

### Hoiku Domain（保育特化）

| エンティティ | 説明 | 主な属性 |
|------------|------|---------|
| **Menu** | 献立 | 施設の献立 |
| **MenuTemplate** | 献立テンプレート | 本部が作成して配布 |
| **Ingredient** | 食材マスタ | 3階層（システム/組織/施設） |
| **MenuIngredient** | 献立-食材 | 献立と食材の紐付け |
| **NutritionStandard** | 栄養基準 | 自治体×年齢×食事区分 |
| **NutritionStandardDetail** | 栄養基準詳細 | 各栄養素の基準値 |
| **ReportTemplate** | 帳票テンプレート | 自治体別の帳票フォーマット |
| **GeneratedReport** | 生成済み帳票 | PDF生成履歴 |

## Organization（組織）の詳細設計

### Organization Type（組織種別）

```sql
CREATE TYPE organization_type AS ENUM (
    'corporation',      -- 法人（社会福祉法人、株式会社など）
    'municipality'      -- 自治体（市区町村）
);
```

### 組織の役割

| Type | 施設運営 | 監査機能 | 本部機能 |
|------|---------|---------|---------|
| **corporation** | ✅ | ❌ | ✅ |
| **municipality** | ✅（直営の場合） | ✅ | ✅ |

### 例

1. **社会福祉法人さくら会**
   - Type: `corporation`
   - 施設: さくら保育園、ひまわり保育園
   - 本部で献立テンプレートを作成し、各施設に配布

2. **横浜市（直営保育園運営）**
   - Type: `municipality`
   - 施設: 横浜市立○○保育園（複数）
   - 監査: 横浜市内の全保育施設
   - 本部で献立テンプレートを作成し、市立保育園に配布

3. **横浜市（監査のみ）**
   - Type: `municipality`
   - 施設: なし（直営施設がない場合）
   - 監査: 横浜市内の全保育施設

## 施設（Facility）の詳細設計

### 施設の所在地と栄養基準

```sql
CREATE TABLE core.facilities (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    organization_id UUID NOT NULL,
    facility_name VARCHAR(255) NOT NULL,
    -- 所在地（栄養基準の自動判定に使用）
    prefecture_code CHAR(2) NOT NULL,           -- '14' = 神奈川県
    municipality_code CHAR(5) NOT NULL,         -- '14100' = 横浜市
    address TEXT NOT NULL,
    -- その他
    capacity INTEGER,                            -- 定員
    phone_number VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);
```

### 全国地方公共団体コード（総務省）

- **都道府県コード**: 2桁（例: 14 = 神奈川県）
- **市区町村コード**: 5桁（例: 14100 = 横浜市）

このコードを使用して、施設の所在地から栄養基準を自動判定する。

## 食材マスタの3階層設計

### 階層構造

```
1. システムマスタ（運営のみ編集可能）
   ↓ 継承・カスタマイズ
2. Organizationマスタ（Organization が追加可能）
   ↓ 継承・カスタマイズ
3. Facilityマスタ（Facility が追加可能）
```

### データ構造

```sql
CREATE TYPE ingredient_level AS ENUM (
    'system',           -- システムマスタ
    'organization',     -- 組織マスタ
    'facility'          -- 施設マスタ
);

CREATE TABLE hoiku.ingredients (
    id UUID PRIMARY KEY,
    -- 階層管理
    level ingredient_level NOT NULL,
    tenant_id UUID,                             -- system の場合は NULL
    organization_id UUID,                       -- system, organization の場合
    facility_id UUID,                           -- facility の場合のみ
    -- 基本情報
    ingredient_code VARCHAR(50) NOT NULL,       -- 食品番号（文科省準拠）
    ingredient_name VARCHAR(255) NOT NULL,
    ingredient_name_kana VARCHAR(255),
    category VARCHAR(100),                      -- 野菜、肉類、魚類など
    -- 単位
    standard_unit VARCHAR(20) NOT NULL DEFAULT 'g',  -- g, ml, 個
    -- 栄養成分（100g あたり）
    energy_kcal DECIMAL(10, 2),
    protein_g DECIMAL(10, 2),
    fat_g DECIMAL(10, 2),
    carbohydrate_g DECIMAL(10, 2),
    sodium_mg DECIMAL(10, 2),                   -- ナトリウム
    salt_equivalent_g DECIMAL(10, 2),           -- 食塩相当量
    calcium_mg DECIMAL(10, 2),
    iron_mg DECIMAL(10, 2),
    vitamin_a_ug DECIMAL(10, 2),
    vitamin_b1_mg DECIMAL(10, 2),
    vitamin_b2_mg DECIMAL(10, 2),
    vitamin_c_mg DECIMAL(10, 2),
    dietary_fiber_g DECIMAL(10, 2),
    -- 廃棄率
    waste_rate DECIMAL(5, 2),                   -- 廃棄率（%）
    -- アレルギー情報
    allergens JSONB,                            -- ['卵', '乳', '小麦', ...]
    -- 状態管理
    is_active BOOLEAN NOT NULL DEFAULT true,
    -- 継承元（カスタマイズの場合）
    parent_ingredient_id UUID REFERENCES hoiku.ingredients(id),
    -- 監査カラム
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);
```

### 食材の継承とカスタマイズ

#### パターン1: システムマスタをそのまま使用

```
システム: にんじん（ID: A）
  ↓
Organization: そのまま使用
  ↓
Facility: そのまま使用
```

#### パターン2: Organization でカスタマイズ

```
システム: にんじん（ID: A, エネルギー: 39kcal）
  ↓ parent_ingredient_id = A
Organization: 有機にんじん（ID: B, エネルギー: 42kcal）
  ↓
Facility: Organization のマスタを使用
```

#### パターン3: Facility で独自食材追加

```
Facility: 自家製味噌（ID: C, parent = NULL）
```

## ユーザー管理の詳細設計

### 入退社・異動履歴に対応

```sql
-- ユーザーマスタ（個人情報）
CREATE TABLE core.users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    family_name VARCHAR(100) NOT NULL,
    given_name VARCHAR(100) NOT NULL,
    family_name_kana VARCHAR(100),
    given_name_kana VARCHAR(100),
    phone_number VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ユーザーと組織の所属履歴
CREATE TABLE core.user_organization_history (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES core.users(id),
    tenant_id UUID NOT NULL,
    organization_id UUID NOT NULL REFERENCES core.organizations(id),
    -- 所属期間
    start_date DATE NOT NULL,
    end_date DATE,                              -- NULL = 現在も所属中
    -- 役割
    role_id UUID NOT NULL REFERENCES core.roles(id),
    -- 監査カラム
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ユーザーと施設の紐付け
CREATE TABLE core.user_facilities (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES core.users(id),
    facility_id UUID NOT NULL REFERENCES core.facilities(id),
    -- 紐付け期間
    start_date DATE NOT NULL,
    end_date DATE,                              -- NULL = 現在も担当中
    -- 監査カラム
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, facility_id, start_date)
);
```

### ユーザーのライフサイクル例

#### シナリオ1: 施設移動

```
栄養士Aさん
  2024-04-01 ~ 2025-03-31: さくら保育園
  2025-04-01 ~ 現在:       ひまわり保育園
```

```sql
-- user_facilities に2レコード
INSERT INTO core.user_facilities VALUES
('uuid1', 'user_A', 'facility_sakura', '2024-04-01', '2025-03-31'),
('uuid2', 'user_A', 'facility_himawari', '2025-04-01', NULL);
```

#### シナリオ2: 退社→再入社

```
栄養士Bさん
  2023-04-01 ~ 2024-03-31: さくら会（退社）
  2025-04-01 ~ 現在:       さくら会（再入社）
```

```sql
-- user_organization_history に2レコード
INSERT INTO core.user_organization_history VALUES
('uuid1', 'user_B', 'tenant_X', 'org_sakura', '2023-04-01', '2024-03-31', 'role_nutritionist'),
('uuid2', 'user_B', 'tenant_X', 'org_sakura', '2025-04-01', NULL, 'role_nutritionist');
```

## 献立テンプレートと配布機能

### 献立テンプレート

本部が作成し、各施設に配布する献立のテンプレート。

```sql
CREATE TABLE hoiku.menu_templates (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    organization_id UUID NOT NULL,              -- 本部で作成
    template_name VARCHAR(255) NOT NULL,
    description TEXT,
    -- 献立情報
    menu_date DATE,                             -- NULL = 汎用テンプレート
    meal_type VARCHAR(50) NOT NULL,             -- 'breakfast', 'lunch', 'snack'
    target_age_group VARCHAR(50),               -- '3-5歳'
    -- 状態
    status VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft, published
    -- 監査カラム
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- テンプレートの食材
CREATE TABLE hoiku.menu_template_ingredients (
    id UUID PRIMARY KEY,
    template_id UUID NOT NULL REFERENCES hoiku.menu_templates(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES hoiku.ingredients(id),
    quantity DECIMAL(10, 2) NOT NULL,           -- 使用量
    unit VARCHAR(20) NOT NULL DEFAULT 'g',
    display_order INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 献立（施設での実運用）

テンプレートから作成、または施設が独自に作成する献立。

```sql
CREATE TABLE hoiku.menus (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    facility_id UUID NOT NULL,                  -- 施設で管理
    -- テンプレート紐付け（テンプレートから作成した場合）
    template_id UUID REFERENCES hoiku.menu_templates(id),
    -- 献立情報
    menu_date DATE NOT NULL,
    meal_type VARCHAR(50) NOT NULL,
    menu_name VARCHAR(255) NOT NULL,
    description TEXT,
    target_age_group VARCHAR(50),
    -- 栄養基準（自動判定 + 手動変更可能）
    nutrition_standard_id UUID REFERENCES hoiku.nutrition_standards(id),
    is_standard_manually_set BOOLEAN NOT NULL DEFAULT false,  -- 手動設定フラグ
    -- 状態
    status VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft, published, archived
    -- 監査カラム
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);
```

### 配布フロー

```
1. 本部: MenuTemplate を作成
   ↓
2. 本部: 「全施設に配布」を実行
   ↓
3. システム: 各施設ごとに Menu を生成
   - template_id に紐付け
   - 施設で自由に編集可能
```

## 栄養基準の詳細設計

### 年齢区分

厚生労働省「日本人の食事摂取基準」に基づく：

| 年齢区分 | コード | 説明 |
|---------|--------|------|
| 0-1歳 | `0-1` | 0歳児、1歳児 |
| 1-2歳 | `1-2` | 1歳児、2歳児 |
| 3-5歳 | `3-5` | 3歳以上就学前 |

### 栄養基準マスタ

```sql
CREATE TABLE hoiku.nutrition_standards (
    id UUID PRIMARY KEY,
    municipality_code CHAR(5) NOT NULL,         -- '14100' = 横浜市
    age_group VARCHAR(10) NOT NULL,             -- '0-1', '1-2', '3-5'
    meal_type VARCHAR(50) NOT NULL,             -- 'breakfast', 'lunch', 'snack'
    -- 有効期間（基準の変更に対応）
    effective_from DATE NOT NULL,
    effective_to DATE,                          -- NULL = 現在も有効
    -- その他
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    UNIQUE(municipality_code, age_group, meal_type, effective_from)
);

CREATE TABLE hoiku.nutrition_standard_details (
    id UUID PRIMARY KEY,
    standard_id UUID NOT NULL REFERENCES hoiku.nutrition_standards(id) ON DELETE CASCADE,
    nutrient_type VARCHAR(50) NOT NULL,         -- 'energy', 'protein', 'fat', ...
    min_value DECIMAL(10, 2),                   -- 最小値（NULL = 制限なし）
    max_value DECIMAL(10, 2),                   -- 最大値（NULL = 制限なし）
    unit VARCHAR(20) NOT NULL,                  -- 'kcal', 'g', 'mg', 'μg'
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(standard_id, nutrient_type)
);
```

### 栄養基準の自動判定ロジック

```sql
-- 献立作成時、以下のロジックで自動判定
SELECT ns.id
FROM hoiku.nutrition_standards ns
JOIN core.facilities f ON f.municipality_code = ns.municipality_code
WHERE f.id = :facility_id
  AND ns.age_group = :target_age_group
  AND ns.meal_type = :meal_type
  AND ns.effective_from <= :menu_date
  AND (ns.effective_to IS NULL OR ns.effective_to >= :menu_date)
ORDER BY ns.effective_from DESC
LIMIT 1;
```

### 手動変更機能

```sql
-- 献立作成後、ユーザーが手動で栄養基準を変更可能
UPDATE hoiku.menus
SET nutrition_standard_id = :new_standard_id,
    is_standard_manually_set = true
WHERE id = :menu_id;
```

## 次のステップ

このドメインモデルを基に、以下を作成します：

1. **全体のER図** - Mermaid形式で可視化
2. **全テーブルのDDL** - Flyway マイグレーションファイル
3. **テーブル定義書** - 各テーブルの詳細仕様

## 参考資料

- [全国地方公共団体コード（総務省）](https://www.soumu.go.jp/denshijiti/code.html)
- [日本食品標準成分表（文部科学省）](https://www.mext.go.jp/a_menu/syokuhinseibun/mext_01110.html)
- [日本人の食事摂取基準（厚生労働省）](https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/kenkou_iryou/kenkou/eiyou/syokuji_kijyun.html)
