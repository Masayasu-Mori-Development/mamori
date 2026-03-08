-- ユーザーテーブル作成
CREATE TABLE core.users (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES core.tenants(id),
    email              VARCHAR(255) UNIQUE NOT NULL,
    password_hash      VARCHAR(255) NOT NULL,
    family_name        VARCHAR(100) NOT NULL,
    given_name         VARCHAR(100) NOT NULL,
    family_name_kana   VARCHAR(100),
    given_name_kana    VARCHAR(100),
    phone_number       VARCHAR(20),
    employee_number    VARCHAR(50),
    is_active          BOOLEAN NOT NULL DEFAULT true,
    last_login_at      TIMESTAMP,
    password_changed_at TIMESTAMP,
    email_verified     BOOLEAN NOT NULL DEFAULT false,
    email_verified_at  TIMESTAMP,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         UUID,
    updated_by         UUID,
    CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- インデックス
CREATE INDEX idx_users_tenant_id ON core.users(tenant_id);
CREATE INDEX idx_users_email ON core.users(email);
CREATE INDEX idx_users_is_active ON core.users(is_active);
CREATE INDEX idx_users_employee_number ON core.users(tenant_id, employee_number);

-- コメント
COMMENT ON TABLE core.users IS '顧客ユーザーテーブル（保育施設スタッフ）';
COMMENT ON COLUMN core.users.id IS 'ユーザーID';
COMMENT ON COLUMN core.users.email IS 'メールアドレス（ログインID）';
COMMENT ON COLUMN core.users.password_hash IS 'パスワードハッシュ（bcrypt）';
