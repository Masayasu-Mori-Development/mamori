---
paths:
  - "**/repository/**"
  - "**/entity/**"
  - "**/resources/db/migration/**"
---

# データベース設計原則

## Schema分離

PostgreSQLのSchema機能を使用して、coreとhoikuを分離：

```
mamori (Database)
├── core (Schema)    - 共通機能
└── hoiku (Schema)   - 保育特化機能
```

## マルチテナント原則

全業務テーブルに以下のカラムを必須とする：

- `tenant_id UUID NOT NULL`: テナントID
- `created_at TIMESTAMP NOT NULL`: 作成日時
- `updated_at TIMESTAMP NOT NULL`: 更新日時
- `created_by UUID`: 作成者（users.id）
- `updated_by UUID`: 更新者（users.id）

```sql
CREATE TABLE hoiku.menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    facility_id UUID NOT NULL,
    -- ビジネスカラム
    menu_date DATE NOT NULL,
    menu_name VARCHAR(255) NOT NULL,
    -- 監査カラム
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);
```

## 正規化

- 第三正規形を基本とする
- パフォーマンスのための意図的な非正規化は設計書に理由を記載

## インデックス

検索頻度の高いカラムに設定：

```sql
-- ✅ Good: tenant_idとfacility_idは検索頻度が高い
CREATE INDEX idx_menus_tenant_id ON hoiku.menus(tenant_id);
CREATE INDEX idx_menus_facility_id ON hoiku.menus(facility_id);
CREATE INDEX idx_menus_menu_date ON hoiku.menus(menu_date);

-- ✅ Good: 複合インデックス
CREATE INDEX idx_menus_tenant_facility ON hoiku.menus(tenant_id, facility_id);
```

## 命名規則

### テーブル名

- スネークケース（複数形）
- 例: `users`, `menus`, `menu_ingredients`

### カラム名

- スネークケース
- 例: `menu_name`, `created_at`, `tenant_id`

### 外部キー

- `{参照先テーブル}_id`
- 例: `tenant_id`, `facility_id`, `menu_id`

## データ型

| 用途 | データ型 | 例 |
|------|---------|-----|
| 主キー | UUID | `id UUID PRIMARY KEY` |
| 外部キー | UUID | `tenant_id UUID` |
| 文字列（短） | VARCHAR(n) | `name VARCHAR(255)` |
| 文字列（長） | TEXT | `description TEXT` |
| 数値（整数） | INTEGER | `capacity INTEGER` |
| 数値（小数） | DECIMAL(10, 2) | `energy_kcal DECIMAL(10, 2)` |
| 日付 | DATE | `menu_date DATE` |
| 日時 | TIMESTAMP | `created_at TIMESTAMP` |
| 真偽値 | BOOLEAN | `is_active BOOLEAN` |
| JSON | JSONB | `template_json JSONB` |

## Flywayマイグレーション

### ファイル命名規則

```
V{バージョン}__{説明}.sql
```

例:
- `V1__create_core_schema.sql`
- `V2__create_core_tenants.sql`
- `V3__create_core_users.sql`

### マイグレーションスクリプトの配置

```
core-backend/src/main/resources/db/migration/
├── V1__create_core_schema.sql
├── V2__create_core_tenants.sql
├── V3__create_core_organizations.sql
└── ...

hoiku-backend/src/main/resources/db/migration/
├── V1__create_hoiku_schema.sql
├── V2__create_hoiku_menus.sql
├── V3__create_hoiku_ingredients.sql
└── ...
```

### マイグレーションスクリプト例

```sql
-- V1__create_core_schema.sql
CREATE SCHEMA IF NOT EXISTS core;

-- V2__create_core_tenants.sql
CREATE TABLE core.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'free',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_tenants_code ON core.tenants(code);
CREATE INDEX idx_tenants_status ON core.tenants(status);

COMMENT ON TABLE core.tenants IS 'テナント（法人・組織）';
COMMENT ON COLUMN core.tenants.name IS 'テナント名';
```

## 外部キー制約

### Schema内の参照

```sql
-- ✅ Good: 同一Schema内は外部キー制約を設定
CREATE TABLE hoiku.menu_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id UUID NOT NULL REFERENCES hoiku.menus(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES hoiku.ingredients(id) ON DELETE RESTRICT
);
```

### 跨Schemaの参照

```sql
-- ⚠️ 注意: 跨Schemaの外部キー制約は設定しない（将来のDB分離を考慮）
CREATE TABLE hoiku.menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,  -- core.tenantsを参照するが外部キー制約なし
    facility_id UUID NOT NULL -- core.facilitiesを参照するが外部キー制約なし
);

-- アプリケーション層で整合性を保証
```

## JSON型の活用

帳票テンプレートなど柔軟なデータ構造にはJSONB型を使用：

```sql
CREATE TABLE hoiku.report_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name VARCHAR(255) NOT NULL,
    template_json JSONB NOT NULL
);

-- JSONBインデックス
CREATE INDEX idx_report_templates_json ON hoiku.report_templates USING gin(template_json);

-- JSONBクエリ例
SELECT * FROM hoiku.report_templates
WHERE template_json->>'municipality' = '横浜市';
```

## パフォーマンス最適化

### N+1問題の回避

```kotlin
// ❌ Bad: N+1問題発生
val menus = menuRepository.findAll()
menus.forEach { menu ->
    val ingredients = menuIngredientRepository.findByMenuId(menu.id)  // N回実行
}

// ✅ Good: JOIN FETCHで一括取得
@Query("SELECT m FROM MenuEntity m LEFT JOIN FETCH m.ingredients WHERE m.facilityId = :facilityId")
fun findByFacilityIdWithIngredients(@Param("facilityId") facilityId: UUID): List<MenuEntity>
```

### バッチサイズ設定

```yaml
spring:
  jpa:
    properties:
      hibernate:
        default_batch_fetch_size: 100
```

## トランザクション

- 複数テーブルの更新は必ずトランザクション内で実行
- `@Transactional` アノテーションを適切に使用

```kotlin
@Service
@Transactional
class MenuServiceImpl(
    private val menuRepository: MenuRepository,
    private val menuIngredientRepository: MenuIngredientRepository
) : MenuService {

    override fun deleteMenu(menuId: UUID) {
        // トランザクション内で複数テーブルを更新
        menuIngredientRepository.deleteByMenuId(menuId)
        menuRepository.deleteById(menuId)
    }
}
```
