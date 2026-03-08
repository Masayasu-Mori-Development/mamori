-- 組織タイプ ENUM
CREATE TYPE organization_type AS ENUM ('corporation', 'municipality');

-- 組織テーブル作成
CREATE TABLE core.organizations (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES core.tenants(id),
    name                  VARCHAR(255) NOT NULL,
    name_kana             VARCHAR(255),
    organization_type     organization_type NOT NULL,
    corporate_number      VARCHAR(13),
    municipality_code     VARCHAR(6),
    postal_code           VARCHAR(10),
    prefecture            VARCHAR(10) NOT NULL,
    city                  VARCHAR(100) NOT NULL,
    address_line1         VARCHAR(255) NOT NULL,
    address_line2         VARCHAR(255),
    phone_number          VARCHAR(20),
    fax_number            VARCHAR(20),
    email                 VARCHAR(255),
    representative_name   VARCHAR(100),
    representative_title  VARCHAR(100),
    is_headquarters       BOOLEAN NOT NULL DEFAULT false,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by            UUID,
    updated_by            UUID,
    CONSTRAINT chk_organizations_corporate_number CHECK (
        (organization_type = 'corporation' AND corporate_number IS NOT NULL) OR
        (organization_type = 'municipality' AND municipality_code IS NOT NULL)
    ),
    CONSTRAINT chk_organizations_corporate_number_length CHECK (corporate_number IS NULL OR length(corporate_number) = 13),
    CONSTRAINT chk_organizations_municipality_code_length CHECK (municipality_code IS NULL OR length(municipality_code) = 6)
);

-- インデックス
CREATE INDEX idx_organizations_tenant_id ON core.organizations(tenant_id);
CREATE INDEX idx_organizations_type ON core.organizations(organization_type);
CREATE INDEX idx_organizations_municipality_code ON core.organizations(municipality_code);
CREATE INDEX idx_organizations_is_active ON core.organizations(is_active);

-- コメント
COMMENT ON TABLE core.organizations IS '組織テーブル（法人または自治体）';
COMMENT ON COLUMN core.organizations.organization_type IS '組織タイプ（corporation:法人/municipality:自治体）';
COMMENT ON COLUMN core.organizations.corporate_number IS '法人番号（13桁）';
COMMENT ON COLUMN core.organizations.municipality_code IS '全国地方公共団体コード（6桁）';
COMMENT ON COLUMN core.organizations.is_headquarters IS '本部機能フラグ';
