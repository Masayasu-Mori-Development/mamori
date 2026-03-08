-- 年齢グループテーブル
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

COMMENT ON TABLE hoiku.age_groups IS '年齢グループマスタ（全テナント共通）';

-- 初期データ
INSERT INTO hoiku.age_groups (name, display_name, min_age_months, max_age_months, sort_order, description) VALUES
('0-1歳', '0-1歳児', 0, 23, 1, '離乳食期〜完了期'),
('1-2歳', '1-2歳児', 12, 35, 2, '幼児食移行期'),
('3-5歳', '3-5歳児', 36, 71, 3, '幼児食期');

-- 栄養基準テーブル
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

COMMENT ON TABLE hoiku.nutrition_standards IS '栄養基準（自治体別・年齢グループ別）';

-- サンプルデータ（横浜市の栄養基準）
INSERT INTO hoiku.nutrition_standards (
    municipality_code, age_group_id, standard_name,
    effective_from, lunch_energy_kcal, lunch_protein_g,
    lunch_calcium_mg, lunch_iron_mg, lunch_salt_g,
    snack_energy_kcal, snack_protein_g,
    source_document
) VALUES
(
    '141003',
    (SELECT id FROM hoiku.age_groups WHERE name = '0-1歳'),
    '横浜市保育所給食基準（令和7年度）',
    '2025-04-01',
    250, 10.0, 180, 2.5, 1.2,
    100, 3.0,
    '横浜市こども青少年局通知'
),
(
    '141003',
    (SELECT id FROM hoiku.age_groups WHERE name = '1-2歳'),
    '横浜市保育所給食基準（令和7年度）',
    '2025-04-01',
    300, 12.0, 220, 3.0, 1.5,
    120, 4.0,
    '横浜市こども青少年局通知'
),
(
    '141003',
    (SELECT id FROM hoiku.age_groups WHERE name = '3-5歳'),
    '横浜市保育所給食基準（令和7年度）',
    '2025-04-01',
    450, 18.0, 280, 4.0, 2.0,
    150, 5.0,
    '横浜市こども青少年局通知'
);
