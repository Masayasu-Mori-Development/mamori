-- 監査ログアクションタイプ ENUM
CREATE TYPE audit_action_type AS ENUM (
    'create',       -- 作成
    'read',         -- 読み取り
    'update',       -- 更新
    'delete',       -- 削除
    'login',        -- ログイン
    'logout',       -- ログアウト
    'login_failed', -- ログイン失敗
    'export',       -- エクスポート
    'import'        -- インポート
);

-- 運営管理監査ログテーブル
CREATE TABLE admin.admin_audit_logs (
    id             BIGSERIAL PRIMARY KEY,
    admin_user_id  UUID REFERENCES admin.admin_users(id),
    action_type    audit_action_type NOT NULL,
    resource_type  VARCHAR(100),
    resource_id    UUID,
    tenant_id      UUID,
    description    TEXT NOT NULL,
    ip_address     INET,
    user_agent     TEXT,
    request_method VARCHAR(10),
    request_path   VARCHAR(500),
    request_body   JSONB,
    response_status INTEGER,
    error_message  TEXT,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_audit_logs_admin_user ON admin.admin_audit_logs(admin_user_id);
CREATE INDEX idx_admin_audit_logs_action_type ON admin.admin_audit_logs(action_type);
CREATE INDEX idx_admin_audit_logs_resource ON admin.admin_audit_logs(resource_type, resource_id);
CREATE INDEX idx_admin_audit_logs_tenant ON admin.admin_audit_logs(tenant_id);
CREATE INDEX idx_admin_audit_logs_created_at ON admin.admin_audit_logs(created_at DESC);
CREATE INDEX idx_admin_audit_logs_ip_address ON admin.admin_audit_logs(ip_address);

COMMENT ON TABLE admin.admin_audit_logs IS '運営管理監査ログ（全操作を記録、削除禁止）';
COMMENT ON COLUMN admin.admin_audit_logs.id IS 'ログID（BIGSERIAL）';
COMMENT ON COLUMN admin.admin_audit_logs.action_type IS '操作種類';
COMMENT ON COLUMN admin.admin_audit_logs.ip_address IS 'IPアドレス';
COMMENT ON COLUMN admin.admin_audit_logs.request_body IS 'リクエストボディ（機密情報除く）';
