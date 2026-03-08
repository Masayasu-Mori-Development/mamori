-- 運営管理者ロール ENUM
CREATE TYPE admin_role_type AS ENUM (
    'super_admin',      -- スーパー管理者
    'admin',            -- 管理者
    'support',          -- サポート担当
    'analyst',          -- アナリスト（閲覧のみ）
    'developer'         -- 開発者
);

-- 運営管理ユーザーテーブル
CREATE TABLE admin.admin_users (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email              VARCHAR(255) UNIQUE NOT NULL,
    password_hash      VARCHAR(255) NOT NULL,
    family_name        VARCHAR(100) NOT NULL,
    given_name         VARCHAR(100) NOT NULL,
    admin_role         admin_role_type NOT NULL,
    is_mfa_enabled     BOOLEAN NOT NULL DEFAULT true,
    mfa_secret         VARCHAR(255),
    is_active          BOOLEAN NOT NULL DEFAULT true,
    last_login_at      TIMESTAMP,
    password_changed_at TIMESTAMP,
    ip_whitelist       TEXT[],
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         UUID,
    updated_by         UUID
);

CREATE INDEX idx_admin_users_email ON admin.admin_users(email);
CREATE INDEX idx_admin_users_role ON admin.admin_users(admin_role);
CREATE INDEX idx_admin_users_active ON admin.admin_users(is_active);

COMMENT ON TABLE admin.admin_users IS '運営管理ユーザーテーブル（顧客ユーザーとは完全分離）';
COMMENT ON COLUMN admin.admin_users.admin_role IS '管理者ロール（super_admin/admin/support/analyst/developer）';
COMMENT ON COLUMN admin.admin_users.is_mfa_enabled IS 'MFA有効フラグ（全管理者必須）';
COMMENT ON COLUMN admin.admin_users.mfa_secret IS 'MFAシークレット（TOTP）';
COMMENT ON COLUMN admin.admin_users.ip_whitelist IS 'IPホワイトリスト';
