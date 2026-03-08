-- ユーザー組織所属履歴テーブル
CREATE TABLE core.user_organization_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),
    user_id         UUID NOT NULL REFERENCES core.users(id),
    organization_id UUID NOT NULL REFERENCES core.organizations(id),
    start_date      DATE NOT NULL,
    end_date        DATE,
    employment_type VARCHAR(50) NOT NULL,
    position        VARCHAR(100),
    department      VARCHAR(100),
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      UUID,
    updated_by      UUID,
    CONSTRAINT chk_user_org_history_date_range CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_user_org_history_employment_type CHECK (employment_type IN ('正社員', '契約社員', 'パート', 'アルバイト', '派遣', '業務委託'))
);

CREATE INDEX idx_user_org_history_tenant_id ON core.user_organization_history(tenant_id);
CREATE INDEX idx_user_org_history_user_id ON core.user_organization_history(user_id);
CREATE INDEX idx_user_org_history_organization_id ON core.user_organization_history(organization_id);
CREATE INDEX idx_user_org_history_current ON core.user_organization_history(user_id, end_date) WHERE end_date IS NULL;
CREATE INDEX idx_user_org_history_dates ON core.user_organization_history(start_date, end_date);

COMMENT ON TABLE core.user_organization_history IS 'ユーザー組織所属履歴（入退社・異動対応）';

-- ユーザー施設担当テーブル
CREATE TABLE core.user_facilities (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES core.tenants(id),
    user_id     UUID NOT NULL REFERENCES core.users(id),
    facility_id UUID NOT NULL REFERENCES core.facilities(id),
    start_date  DATE NOT NULL,
    end_date    DATE,
    is_primary  BOOLEAN NOT NULL DEFAULT false,
    role        VARCHAR(100),
    notes       TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by  UUID,
    updated_by  UUID,
    CONSTRAINT chk_user_facilities_date_range CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_user_facilities_role CHECK (role IN ('施設長', '栄養士', '調理師', '保育士', '事務', 'その他'))
);

CREATE INDEX idx_user_facilities_tenant_id ON core.user_facilities(tenant_id);
CREATE INDEX idx_user_facilities_user_id ON core.user_facilities(user_id);
CREATE INDEX idx_user_facilities_facility_id ON core.user_facilities(facility_id);
CREATE INDEX idx_user_facilities_current ON core.user_facilities(user_id, facility_id) WHERE end_date IS NULL;
CREATE UNIQUE INDEX idx_user_facilities_primary ON core.user_facilities(user_id) WHERE is_primary = true AND end_date IS NULL;

COMMENT ON TABLE core.user_facilities IS 'ユーザー施設担当';
COMMENT ON COLUMN core.user_facilities.is_primary IS '主担当フラグ（ユーザーごとに1施設のみ）';
