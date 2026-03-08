# Hoiku スキーマ残りのテーブル定義（簡易版）

## menu_templates (献立テンプレート)

本部が作成した献立テンプレートを管理。各施設に配布して使用。

```sql
CREATE TABLE hoiku.menu_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),
    organization_id UUID NOT NULL REFERENCES core.organizations(id),
    template_name   VARCHAR(255) NOT NULL,
    description     TEXT,
    meal_type       meal_type NOT NULL,
    is_published    BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      UUID,
    updated_by      UUID
);
```

## nutrition_calculations (栄養計算結果)

献立の栄養計算結果をキャッシュするテーブル。

```sql
CREATE TABLE hoiku.nutrition_calculations (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES core.tenants(id),
    menu_id            UUID NOT NULL REFERENCES hoiku.menus(id) ON DELETE CASCADE,
    age_group_id       UUID NOT NULL REFERENCES hoiku.age_groups(id),
    servings           INTEGER NOT NULL,
    -- 計算結果（1人分）
    energy_kcal        DECIMAL(10, 2),
    protein_g          DECIMAL(10, 2),
    fat_g              DECIMAL(10, 2),
    carbohydrate_g     DECIMAL(10, 2),
    calcium_mg         DECIMAL(10, 2),
    iron_mg            DECIMAL(10, 2),
    vitamin_a_ug       DECIMAL(10, 2),
    vitamin_b1_mg      DECIMAL(10, 2),
    vitamin_b2_mg      DECIMAL(10, 2),
    vitamin_c_mg       DECIMAL(10, 2),
    dietary_fiber_g    DECIMAL(10, 2),
    salt_equivalent_g  DECIMAL(10, 2),
    calculated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(menu_id, age_group_id)
);
```

## reports (帳票)

監査用帳票の出力履歴を管理。

```sql
CREATE TABLE hoiku.reports (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES core.tenants(id),
    facility_id         UUID NOT NULL REFERENCES core.facilities(id),
    report_template_id  UUID NOT NULL REFERENCES hoiku.report_templates(id),
    report_name         VARCHAR(255) NOT NULL,
    target_year_month   VARCHAR(7) NOT NULL,  -- YYYY-MM形式
    file_path           VARCHAR(500),
    file_size_bytes     BIGINT,
    generated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    generated_by        UUID REFERENCES core.users(id)
);
```

## report_templates (帳票テンプレート)

自治体別の帳票テンプレートを管理。

```sql
CREATE TABLE hoiku.report_templates (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_code VARCHAR(6) REFERENCES core.municipality_codes(code),
    template_name     VARCHAR(255) NOT NULL,
    template_type     VARCHAR(100) NOT NULL,  -- menu_list, nutrition_summary等
    template_file_path VARCHAR(500),
    version           VARCHAR(50),
    is_active         BOOLEAN NOT NULL DEFAULT true,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 横浜市の帳票テンプレート例
INSERT INTO hoiku.report_templates (
    municipality_code, template_name, template_type, version
) VALUES
('141003', '横浜市給食献立表', 'menu_list', 'R7-001'),
('141003', '横浜市栄養管理報告書', 'nutrition_summary', 'R7-001');
```

## 備考

これらのテーブルの詳細定義は必要に応じて追加作成します。
