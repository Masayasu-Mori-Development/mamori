-- ロールスコープ ENUM
CREATE TYPE role_scope AS ENUM ('system', 'organization', 'facility');

-- ロールテーブル
CREATE TABLE core.roles (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID REFERENCES core.tenants(id),
    organization_id  UUID REFERENCES core.organizations(id),
    facility_id      UUID REFERENCES core.facilities(id),
    name             VARCHAR(100) NOT NULL,
    display_name     VARCHAR(100) NOT NULL,
    description      TEXT,
    scope            role_scope NOT NULL,
    is_system_role   BOOLEAN NOT NULL DEFAULT false,
    is_active        BOOLEAN NOT NULL DEFAULT true,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by       UUID,
    updated_by       UUID,
    CONSTRAINT chk_roles_scope_tenant CHECK (
        (scope = 'system' AND tenant_id IS NULL) OR
        (scope != 'system' AND tenant_id IS NOT NULL)
    ),
    CONSTRAINT chk_roles_scope_organization CHECK (
        (scope = 'organization' AND organization_id IS NOT NULL) OR
        (scope != 'organization' AND organization_id IS NULL)
    ),
    CONSTRAINT chk_roles_scope_facility CHECK (
        (scope = 'facility' AND facility_id IS NOT NULL) OR
        (scope != 'facility' AND facility_id IS NULL)
    )
);

CREATE INDEX idx_roles_tenant_id ON core.roles(tenant_id);
CREATE INDEX idx_roles_organization_id ON core.roles(organization_id);
CREATE INDEX idx_roles_facility_id ON core.roles(facility_id);
CREATE INDEX idx_roles_scope ON core.roles(scope);
CREATE INDEX idx_roles_is_active ON core.roles(is_active);
CREATE UNIQUE INDEX idx_roles_name_unique ON core.roles(tenant_id, name) WHERE tenant_id IS NOT NULL;
CREATE UNIQUE INDEX idx_roles_system_name_unique ON core.roles(name) WHERE scope = 'system';

COMMENT ON TABLE core.roles IS 'ロールテーブル（RBAC）';

-- ユーザーロール中間テーブル
CREATE TABLE core.user_roles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES core.tenants(id),
    user_id     UUID NOT NULL REFERENCES core.users(id),
    role_id     UUID NOT NULL REFERENCES core.roles(id),
    facility_id UUID REFERENCES core.facilities(id),
    granted_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by  UUID,
    UNIQUE(user_id, role_id, facility_id)
);

CREATE INDEX idx_user_roles_user_id ON core.user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON core.user_roles(role_id);
CREATE INDEX idx_user_roles_facility_id ON core.user_roles(facility_id);

-- パーミッションリソース ENUM
CREATE TYPE permission_resource AS ENUM (
    'menu', 'nutrition', 'ingredient', 'report',
    'user', 'facility', 'organization', 'setting'
);

-- パーミッションアクション ENUM
CREATE TYPE permission_action AS ENUM (
    'create', 'read', 'update', 'delete',
    'export', 'import', 'approve'
);

-- パーミッションテーブル
CREATE TABLE core.permissions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) UNIQUE NOT NULL,
    resource    permission_resource NOT NULL,
    action      permission_action NOT NULL,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(resource, action)
);

CREATE INDEX idx_permissions_resource ON core.permissions(resource);
CREATE INDEX idx_permissions_action ON core.permissions(action);
CREATE INDEX idx_permissions_is_active ON core.permissions(is_active);

-- ロールパーミッション中間テーブル
CREATE TABLE core.role_permissions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id       UUID NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES core.permissions(id) ON DELETE CASCADE,
    granted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by    UUID,
    UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role_id ON core.role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON core.role_permissions(permission_id);

-- システムロール初期データ
INSERT INTO core.roles (name, display_name, description, scope, is_system_role) VALUES
('TENANT_ADMIN', 'テナント管理者', 'テナント全体の管理権限', 'system', true),
('ORG_ADMIN', '組織管理者', '組織全体の管理権限', 'system', true),
('FACILITY_ADMIN', '施設管理者', '施設の管理権限', 'system', true),
('NUTRITIONIST', '栄養士', '献立作成・栄養計算権限', 'system', true),
('COOK', '調理師', '献立閲覧権限', 'system', true),
('VIEWER', '閲覧者', '閲覧のみ', 'system', true);

-- パーミッション初期データ
INSERT INTO core.permissions (name, resource, action, description) VALUES
-- 献立
('menu.create', 'menu', 'create', '献立を作成'),
('menu.read', 'menu', 'read', '献立を閲覧'),
('menu.update', 'menu', 'update', '献立を更新'),
('menu.delete', 'menu', 'delete', '献立を削除'),
('menu.approve', 'menu', 'approve', '献立を承認'),
('menu.export', 'menu', 'export', '献立をエクスポート'),
-- 栄養計算
('nutrition.read', 'nutrition', 'read', '栄養計算結果を閲覧'),
('nutrition.export', 'nutrition', 'export', '栄養計算をエクスポート'),
-- 食材マスタ
('ingredient.create', 'ingredient', 'create', '食材を作成'),
('ingredient.read', 'ingredient', 'read', '食材を閲覧'),
('ingredient.update', 'ingredient', 'update', '食材を更新'),
('ingredient.delete', 'ingredient', 'delete', '食材を削除'),
-- 帳票
('report.read', 'report', 'read', '帳票を閲覧'),
('report.export', 'report', 'export', '帳票を出力'),
-- ユーザー管理
('user.create', 'user', 'create', 'ユーザーを作成'),
('user.read', 'user', 'read', 'ユーザーを閲覧'),
('user.update', 'user', 'update', 'ユーザーを更新'),
('user.delete', 'user', 'delete', 'ユーザーを削除'),
-- 施設管理
('facility.read', 'facility', 'read', '施設を閲覧'),
('facility.update', 'facility', 'update', '施設を更新'),
-- 設定
('setting.read', 'setting', 'read', '設定を閲覧'),
('setting.update', 'setting', 'update', '設定を更新');
