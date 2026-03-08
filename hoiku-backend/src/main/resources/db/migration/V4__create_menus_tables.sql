-- 食事区分 ENUM
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'snack', 'dinner');

-- 献立ステータス ENUM
CREATE TYPE menu_status AS ENUM ('draft', 'pending', 'approved', 'published');

-- 献立テーブル
CREATE TABLE hoiku.menus (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES core.tenants(id),
    facility_id        UUID NOT NULL REFERENCES core.facilities(id),
    menu_template_id   UUID,  -- menu_templatesは後で作成
    date               DATE NOT NULL,
    meal_type          meal_type NOT NULL,
    title              VARCHAR(255),
    description        TEXT,
    status             menu_status NOT NULL DEFAULT 'draft',
    total_servings     INTEGER NOT NULL DEFAULT 0,
    estimated_cost     DECIMAL(10, 2),
    approved_by        UUID REFERENCES core.users(id),
    approved_at        TIMESTAMP,
    published_by       UUID REFERENCES core.users(id),
    published_at       TIMESTAMP,
    notes              TEXT,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         UUID,
    updated_by         UUID,
    UNIQUE(facility_id, date, meal_type)
);

CREATE INDEX idx_menus_tenant_id ON hoiku.menus(tenant_id);
CREATE INDEX idx_menus_facility_id ON hoiku.menus(facility_id);
CREATE INDEX idx_menus_date ON hoiku.menus(date);
CREATE INDEX idx_menus_meal_type ON hoiku.menus(meal_type);
CREATE INDEX idx_menus_status ON hoiku.menus(status);
CREATE INDEX idx_menus_facility_date_range ON hoiku.menus(facility_id, date);

COMMENT ON TABLE hoiku.menus IS '献立テーブル';

-- 献立明細テーブル
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

CREATE INDEX idx_menu_items_tenant_id ON hoiku.menu_items(tenant_id);
CREATE INDEX idx_menu_items_menu_id ON hoiku.menu_items(menu_id);

COMMENT ON TABLE hoiku.menu_items IS '献立明細（料理）テーブル';

-- 献立明細食材テーブル
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

CREATE INDEX idx_menu_item_ingredients_menu_item_id ON hoiku.menu_item_ingredients(menu_item_id);
CREATE INDEX idx_menu_item_ingredients_ingredient_id ON hoiku.menu_item_ingredients(ingredient_id);

COMMENT ON TABLE hoiku.menu_item_ingredients IS '献立明細食材テーブル';

-- 栄養計算結果テーブル
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

CREATE INDEX idx_nutrition_calculations_menu_id ON hoiku.nutrition_calculations(menu_id);
CREATE INDEX idx_nutrition_calculations_age_group_id ON hoiku.nutrition_calculations(age_group_id);

COMMENT ON TABLE hoiku.nutrition_calculations IS '栄養計算結果キャッシュテーブル';
