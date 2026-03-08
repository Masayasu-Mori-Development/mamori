-- 施設タイプ ENUM
CREATE TYPE facility_type AS ENUM (
    'nursery',              -- 認可保育所
    'certified_nursery',    -- 認定こども園
    'small_nursery',        -- 小規模保育
    'enterprise_nursery',   -- 企業主導型保育
    'family_daycare'        -- 家庭的保育
);

-- 施設テーブル作成
CREATE TABLE core.facilities (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES core.tenants(id),
    organization_id         UUID NOT NULL REFERENCES core.organizations(id),
    municipality_code       VARCHAR(6) NOT NULL REFERENCES core.municipality_codes(code),
    name                    VARCHAR(255) NOT NULL,
    name_kana               VARCHAR(255),
    facility_type           facility_type NOT NULL,
    facility_number         VARCHAR(50),
    capacity                INTEGER NOT NULL,
    postal_code             VARCHAR(10),
    prefecture              VARCHAR(10) NOT NULL,
    city                    VARCHAR(100) NOT NULL,
    address_line1           VARCHAR(255) NOT NULL,
    address_line2           VARCHAR(255),
    phone_number            VARCHAR(20),
    fax_number              VARCHAR(20),
    email                   VARCHAR(255),
    director_name           VARCHAR(100),
    nutritionist_name       VARCHAR(100),
    opening_date            DATE,
    is_active               BOOLEAN NOT NULL DEFAULT true,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              UUID,
    updated_by              UUID,
    CONSTRAINT chk_facilities_capacity CHECK (capacity > 0),
    CONSTRAINT chk_facilities_municipality_code_length CHECK (length(municipality_code) = 6)
);

-- インデックス
CREATE INDEX idx_facilities_tenant_id ON core.facilities(tenant_id);
CREATE INDEX idx_facilities_organization_id ON core.facilities(organization_id);
CREATE INDEX idx_facilities_municipality_code ON core.facilities(municipality_code);
CREATE INDEX idx_facilities_type ON core.facilities(facility_type);
CREATE INDEX idx_facilities_is_active ON core.facilities(is_active);

-- コメント
COMMENT ON TABLE core.facilities IS '施設テーブル';
COMMENT ON COLUMN core.facilities.facility_type IS '施設タイプ';
COMMENT ON COLUMN core.facilities.municipality_code IS '所在地の自治体コード（栄養基準の適用に使用）';
COMMENT ON COLUMN core.facilities.capacity IS '定員数';
