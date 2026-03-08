# 運営管理監査ログテーブル (admin.admin_audit_logs)

## 概要

運営管理者の全ての操作を記録する監査ログテーブル。
セキュリティインシデント調査・コンプライアンス対応に使用。

## テーブル定義

```sql
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
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | BIGSERIAL | NOT NULL | auto_increment | ログID（主キー） |
| admin_user_id | UUID | NULL | - | 管理者ID |
| action_type | audit_action_type | NOT NULL | - | 操作種類 |
| resource_type | VARCHAR(100) | NULL | - | 対象リソース種類 |
| resource_id | UUID | NULL | - | 対象リソースID |
| tenant_id | UUID | NULL | - | テナントID（対象がテナントデータの場合） |
| description | TEXT | NOT NULL | - | 操作説明 |
| ip_address | INET | NULL | - | IPアドレス |
| user_agent | TEXT | NULL | - | ユーザーエージェント |
| request_method | VARCHAR(10) | NULL | - | HTTPメソッド |
| request_path | VARCHAR(500) | NULL | - | リクエストパス |
| request_body | JSONB | NULL | - | リクエストボディ（機密情報除く） |
| response_status | INTEGER | NULL | - | HTTPステータスコード |
| error_message | TEXT | NULL | - | エラーメッセージ |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 記録日時 |

## サンプルデータ

### ログイン成功

```sql
INSERT INTO admin.admin_audit_logs (
    admin_user_id, action_type, description,
    ip_address, user_agent, response_status
) VALUES (
    '11111111-2222-3333-4444-555555555555',
    'login',
    'ログイン成功',
    '192.168.1.100',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
    200
);
```

### テナント作成

```sql
INSERT INTO admin.admin_audit_logs (
    admin_user_id, action_type, resource_type, resource_id, tenant_id,
    description, ip_address, request_method, request_path, request_body
) VALUES (
    '11111111-2222-3333-4444-555555555555',
    'create',
    'tenant',
    '550e8400-e29b-41d4-a716-446655440000',
    '550e8400-e29b-41d4-a716-446655440000',
    'テナント「社会福祉法人さくら会」を作成',
    '192.168.1.100',
    'POST',
    '/api/admin/tenants',
    '{"name": "社会福祉法人さくら会", "subdomain": "sakurakai"}'::JSONB
);
```

### ログイン失敗

```sql
INSERT INTO admin.admin_audit_logs (
    admin_user_id, action_type, description,
    ip_address, response_status, error_message
) VALUES (
    NULL,  -- ユーザー未確定
    'login_failed',
    'ログイン失敗: 無効なパスワード',
    '192.168.1.200',
    401,
    'Invalid credentials'
);
```

## クエリ例

### 特定管理者の操作履歴

```sql
SELECT
    action_type,
    resource_type,
    description,
    ip_address,
    created_at
FROM admin.admin_audit_logs
WHERE admin_user_id = :admin_user_id
ORDER BY created_at DESC
LIMIT 100;
```

### 不正アクセスの検出

```sql
SELECT
    ip_address,
    COUNT(*) as failed_attempts,
    MAX(created_at) as last_attempt
FROM admin.admin_audit_logs
WHERE action_type = 'login_failed'
  AND created_at >= NOW() - INTERVAL '1 hour'
GROUP BY ip_address
HAVING COUNT(*) >= 5;
```

### データエクスポート履歴

```sql
SELECT
    au.email,
    aal.description,
    aal.tenant_id,
    aal.created_at
FROM admin.admin_audit_logs aal
INNER JOIN admin.admin_users au ON aal.admin_user_id = au.id
WHERE aal.action_type = 'export'
ORDER BY aal.created_at DESC;
```

## 保持期間

- **通常ログ**: 3年間保持
- **ログイン関連**: 5年間保持
- **セキュリティインシデント**: 永久保持

## パーティショニング

パフォーマンス向上のため、月次パーティショニングを推奨:

```sql
-- 月次パーティション作成例
CREATE TABLE admin.admin_audit_logs_2025_03 PARTITION OF admin.admin_audit_logs
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
```

## 備考

- **削除禁止**: 監査ログは物理削除不可
- **変更禁止**: INSERT のみ、UPDATE/DELETE は禁止
- **暗号化**: 機密情報（パスワード等）は記録しない
- **アラート**: 異常なアクセスパターンを検知してアラート
