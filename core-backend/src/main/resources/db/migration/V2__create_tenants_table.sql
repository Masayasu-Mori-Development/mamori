-- テナントテーブル作成
CREATE TABLE core.tenants (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255) NOT NULL,
    subdomain           VARCHAR(100) UNIQUE NOT NULL,
    plan_type           VARCHAR(50) NOT NULL DEFAULT 'trial',
    subscription_status VARCHAR(50) NOT NULL DEFAULT 'active',
    max_users           INTEGER NOT NULL DEFAULT 10,
    max_facilities      INTEGER NOT NULL DEFAULT 3,
    trial_end_date      TIMESTAMP,
    contract_start_date DATE,
    contract_end_date   DATE,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          UUID,
    updated_by          UUID,
    CONSTRAINT chk_tenants_plan_type CHECK (plan_type IN ('trial', 'basic', 'standard', 'enterprise')),
    CONSTRAINT chk_tenants_subscription_status CHECK (subscription_status IN ('active', 'suspended', 'cancelled')),
    CONSTRAINT chk_tenants_max_users CHECK (max_users > 0),
    CONSTRAINT chk_tenants_max_facilities CHECK (max_facilities > 0)
);

-- インデックス
CREATE INDEX idx_tenants_subdomain ON core.tenants(subdomain);
CREATE INDEX idx_tenants_subscription_status ON core.tenants(subscription_status);
CREATE INDEX idx_tenants_is_active ON core.tenants(is_active);

-- コメント
COMMENT ON TABLE core.tenants IS 'テナントテーブル';
COMMENT ON COLUMN core.tenants.id IS 'テナントID';
COMMENT ON COLUMN core.tenants.subdomain IS 'サブドメイン（例: sakurakai.mamori.jp）';
COMMENT ON COLUMN core.tenants.plan_type IS 'プランタイプ（trial/basic/standard/enterprise）';
