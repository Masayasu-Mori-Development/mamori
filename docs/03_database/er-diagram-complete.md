# 完全ER図

全国展開対応版のエンティティ関連図

## 全体構成

### Core Schema（共通機能）

```mermaid
erDiagram
    TENANTS ||--o{ ORGANIZATIONS : has
    TENANTS ||--o{ FACILITIES : has
    TENANTS ||--o{ USERS : has

    ORGANIZATIONS ||--o{ FACILITIES : manages
    ORGANIZATIONS ||--o{ USER_ORGANIZATION_HISTORY : has
    ORGANIZATIONS ||--o{ MENU_TEMPLATES : creates
    ORGANIZATIONS ||--o{ INGREDIENTS : owns

    FACILITIES ||--o{ MENUS : has
    FACILITIES ||--o{ USER_FACILITIES : employs
    FACILITIES ||--o{ INGREDIENTS : owns
    FACILITIES }o--|| MUNICIPALITIES : located_in

    USERS ||--o{ USER_ORGANIZATION_HISTORY : belongs_to
    USERS ||--o{ USER_FACILITIES : assigned_to
    USERS }o--o{ ROLES : has

    PREFECTURES ||--o{ MUNICIPALITIES : contains
    MUNICIPALITIES ||--o{ NUTRITION_STANDARDS : defines

    TENANTS {
        uuid id PK
        string name
        string code
        string plan
        string status
        timestamp created_at
        timestamp updated_at
    }

    ORGANIZATIONS {
        uuid id PK
        uuid tenant_id FK
        string organization_type "corporation or municipality"
        string organization_name
        string organization_code
        string prefecture_code FK
        string municipality_code FK
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    FACILITIES {
        uuid id PK
        uuid tenant_id FK
        uuid organization_id FK
        string facility_name
        string prefecture_code FK
        string municipality_code FK
        string address
        integer capacity
        string phone_number
        string email
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    USERS {
        uuid id PK
        string email UK
        string password_hash
        string family_name
        string given_name
        string family_name_kana
        string given_name_kana
        string phone_number
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    USER_ORGANIZATION_HISTORY {
        uuid id PK
        uuid user_id FK
        uuid tenant_id FK
        uuid organization_id FK
        date start_date
        date end_date "NULL = current"
        uuid role_id FK
        timestamp created_at
        timestamp updated_at
    }

    USER_FACILITIES {
        uuid id PK
        uuid user_id FK
        uuid facility_id FK
        date start_date
        date end_date "NULL = current"
        timestamp created_at
        timestamp updated_at
    }

    ROLES {
        uuid id PK
        string role_name
        string description
        jsonb permissions
        timestamp created_at
        timestamp updated_at
    }

    PREFECTURES {
        string code PK "2 digits"
        string name
        string name_kana
        string name_en
        timestamp created_at
        timestamp updated_at
    }

    MUNICIPALITIES {
        string code PK "5 digits"
        string prefecture_code FK
        string name
        string name_kana
        string name_en
        timestamp created_at
        timestamp updated_at
    }
```

### Hoiku Schema（保育特化）

```mermaid
erDiagram
    MENU_TEMPLATES ||--o{ MENU_TEMPLATE_INGREDIENTS : contains
    MENU_TEMPLATES ||--o{ MENUS : "distributed to"

    MENUS ||--o{ MENU_INGREDIENTS : contains
    MENUS }o--|| NUTRITION_STANDARDS : evaluated_by

    INGREDIENTS ||--o{ MENU_INGREDIENTS : used_in
    INGREDIENTS ||--o{ MENU_TEMPLATE_INGREDIENTS : used_in
    INGREDIENTS }o--o| INGREDIENTS : inherits_from

    NUTRITION_STANDARDS ||--o{ NUTRITION_STANDARD_DETAILS : defines
    NUTRITION_STANDARDS ||--o{ MENUS : applies_to

    MENUS ||--o{ GENERATED_REPORTS : generates
    REPORT_TEMPLATES ||--o{ GENERATED_REPORTS : uses

    MENU_TEMPLATES {
        uuid id PK
        uuid tenant_id FK
        uuid organization_id FK
        string template_name
        text description
        date menu_date "NULL = generic"
        string meal_type
        string target_age_group
        string status "draft, published"
        timestamp created_at
        timestamp updated_at
        uuid created_by FK
        uuid updated_by FK
    }

    MENU_TEMPLATE_INGREDIENTS {
        uuid id PK
        uuid template_id FK
        uuid ingredient_id FK
        decimal quantity
        string unit
        integer display_order
        timestamp created_at
        timestamp updated_at
    }

    MENUS {
        uuid id PK
        uuid tenant_id FK
        uuid facility_id FK
        uuid template_id FK "NULL = original"
        date menu_date
        string meal_type
        string menu_name
        text description
        string target_age_group
        uuid nutrition_standard_id FK
        boolean is_standard_manually_set
        string status "draft, published, archived"
        timestamp created_at
        timestamp updated_at
        uuid created_by FK
        uuid updated_by FK
    }

    MENU_INGREDIENTS {
        uuid id PK
        uuid menu_id FK
        uuid ingredient_id FK
        decimal quantity
        string unit
        integer display_order
        timestamp created_at
        timestamp updated_at
    }

    INGREDIENTS {
        uuid id PK
        string level "system, organization, facility"
        uuid tenant_id FK "NULL for system"
        uuid organization_id FK
        uuid facility_id FK
        string ingredient_code
        string ingredient_name
        string ingredient_name_kana
        string category
        string standard_unit
        decimal energy_kcal "per 100g"
        decimal protein_g
        decimal fat_g
        decimal carbohydrate_g
        decimal sodium_mg
        decimal salt_equivalent_g
        decimal calcium_mg
        decimal iron_mg
        decimal vitamin_a_ug
        decimal vitamin_b1_mg
        decimal vitamin_b2_mg
        decimal vitamin_c_mg
        decimal dietary_fiber_g
        decimal waste_rate "percentage"
        jsonb allergens
        boolean is_active
        uuid parent_ingredient_id FK
        timestamp created_at
        timestamp updated_at
        uuid created_by FK
        uuid updated_by FK
    }

    NUTRITION_STANDARDS {
        uuid id PK
        string municipality_code FK
        string age_group "0-1, 1-2, 3-5"
        string meal_type
        date effective_from
        date effective_to "NULL = current"
        text description
        timestamp created_at
        timestamp updated_at
        uuid created_by FK
        uuid updated_by FK
    }

    NUTRITION_STANDARD_DETAILS {
        uuid id PK
        uuid standard_id FK
        string nutrient_type
        decimal min_value "NULL = no limit"
        decimal max_value "NULL = no limit"
        string unit
        timestamp created_at
        timestamp updated_at
    }

    REPORT_TEMPLATES {
        uuid id PK
        string municipality_code FK
        string template_name
        string template_type "nutrition_report, menu_list"
        text template_content
        jsonb template_config
        date effective_from
        date effective_to
        timestamp created_at
        timestamp updated_at
    }

    GENERATED_REPORTS {
        uuid id PK
        uuid tenant_id FK
        uuid facility_id FK
        uuid menu_id FK
        uuid template_id FK
        string report_type
        date report_period_start
        date report_period_end
        string file_path
        string status "generating, completed, failed"
        timestamp created_at
        uuid created_by FK
    }
```

## 主要なリレーションシップ

### 1. テナント階層

```
Tenant (契約単位)
  └─ Organization (法人・自治体)
      └─ Facility (施設)
          └─ Menu (献立)
```

### 2. ユーザー所属

```
User (個人)
  └─ UserOrganizationHistory (組織所属履歴)
      ├─ start_date: 2024-04-01
      └─ end_date: NULL (現在も所属中)
  └─ UserFacilities (施設担当)
      ├─ Facility A (2024-04-01 ~ 2025-03-31)
      └─ Facility B (2025-04-01 ~ NULL)
```

### 3. 食材マスタの継承

```
System Ingredient (システムマスタ)
  └─ Organization Ingredient (組織カスタマイズ)
      └─ Facility Ingredient (施設独自食材)
```

### 4. 献立配布フロー

```
MenuTemplate (本部作成)
  ├─ Menu (施設A)
  ├─ Menu (施設B)
  └─ Menu (施設C)
```

### 5. 栄養基準の適用

```
Municipality (自治体)
  └─ NutritionStandard (栄養基準)
      └─ NutritionStandardDetail (各栄養素)
          ├─ energy: 450-550 kcal
          ├─ protein: 15-20 g
          └─ ...

Facility (施設)
  └─ municipality_code で自動判定
      └─ Menu に適用
```

## カーディナリティ

| リレーション | カーディナリティ | 説明 |
|------------|----------------|------|
| Tenant - Organization | 1:N | 1テナントが複数組織を持つ（将来対応） |
| Organization - Facility | 1:N | 1組織が複数施設を管理 |
| Facility - Menu | 1:N | 1施設が複数献立を持つ |
| Menu - MenuIngredient | 1:N | 1献立が複数食材を含む |
| User - UserOrganizationHistory | 1:N | 履歴管理（入退社・異動） |
| User - UserFacilities | N:N | 1ユーザーが複数施設を担当可能 |
| MenuTemplate - Menu | 1:N | 1テンプレートから複数献立を生成 |
| NutritionStandard - Menu | 1:N | 1基準が複数献立に適用 |

## インデックス戦略

### 必須インデックス

| テーブル | カラム | 理由 |
|---------|--------|------|
| facilities | (tenant_id, organization_id) | 施設一覧取得 |
| facilities | municipality_code | 栄養基準の自動判定 |
| menus | (facility_id, menu_date) | 日付範囲での献立検索 |
| menus | nutrition_standard_id | 基準別の献立検索 |
| ingredients | (level, tenant_id, organization_id, facility_id) | 階層別の食材検索 |
| ingredients | ingredient_name | 食材名での検索 |
| user_organization_history | (user_id, end_date) | 現在所属中の組織検索 |
| user_facilities | (user_id, end_date) | 現在担当中の施設検索 |
| nutrition_standards | (municipality_code, age_group, meal_type, effective_from) | 栄養基準の検索 |

### 複合インデックス

```sql
-- 献立検索の最適化
CREATE INDEX idx_menus_facility_date ON hoiku.menus(facility_id, menu_date);
CREATE INDEX idx_menus_tenant_facility ON hoiku.menus(tenant_id, facility_id);

-- 食材マスタの階層検索
CREATE INDEX idx_ingredients_level_org_facility
ON hoiku.ingredients(level, organization_id, facility_id);

-- ユーザー所属の検索
CREATE INDEX idx_user_org_history_active
ON core.user_organization_history(user_id, organization_id)
WHERE end_date IS NULL;

CREATE INDEX idx_user_facilities_active
ON core.user_facilities(user_id, facility_id)
WHERE end_date IS NULL;
```

## 次のステップ

1. ✅ ドメインモデル v2 作成完了
2. ✅ ER図作成完了
3. 次: 各テーブルの詳細DDL作成
4. 次: Flyway マイグレーションファイル作成
