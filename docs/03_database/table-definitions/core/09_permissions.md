# パーミッションテーブル (core.permissions)

## 概要

システムの操作権限を細かく定義するテーブル。
ロールと組み合わせてRBAC（Role-Based Access Control）を実現。

## テーブル定義

```sql
CREATE TYPE permission_resource AS ENUM (
    'menu',              -- 献立
    'nutrition',         -- 栄養計算
    'ingredient',        -- 食材マスタ
    'report',            -- 帳票
    'user',              -- ユーザー管理
    'facility',          -- 施設管理
    'organization',      -- 組織管理
    'setting'            -- 設定
);

CREATE TYPE permission_action AS ENUM (
    'create',   -- 作成
    'read',     -- 読み取り
    'update',   -- 更新
    'delete',   -- 削除
    'export',   -- エクスポート
    'import',   -- インポート
    'approve'   -- 承認
);

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

-- ロールとパーミッションの中間テーブル
CREATE TABLE core.role_permissions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id       UUID NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES core.permissions(id) ON DELETE CASCADE,
    granted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by    UUID,
    UNIQUE(role_id, permission_id)
);

CREATE INDEX idx_permissions_resource ON core.permissions(resource);
CREATE INDEX idx_permissions_action ON core.permissions(action);
CREATE INDEX idx_permissions_is_active ON core.permissions(is_active);
CREATE INDEX idx_role_permissions_role_id ON core.role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON core.role_permissions(permission_id);
```

## カラム定義

### core.permissions

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | パーミッションID（主キー） |
| name | VARCHAR(100) | NOT NULL | - | パーミッション名（一意） |
| resource | permission_resource | NOT NULL | - | リソース種類 |
| action | permission_action | NOT NULL | - | 操作種類 |
| description | TEXT | NULL | - | 説明 |
| is_active | BOOLEAN | NOT NULL | true | アクティブフラグ |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |

### core.role_permissions

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 割り当てID（主キー） |
| role_id | UUID | NOT NULL | - | ロールID（外部キー） |
| permission_id | UUID | NOT NULL | - | パーミッションID（外部キー） |
| granted_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 付与日時 |
| granted_by | UUID | NULL | - | 付与者 |

## デフォルトパーミッション

### 献立関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('menu.create', 'menu', 'create', '献立を作成'),
('menu.read', 'menu', 'read', '献立を閲覧'),
('menu.update', 'menu', 'update', '献立を更新'),
('menu.delete', 'menu', 'delete', '献立を削除'),
('menu.approve', 'menu', 'approve', '献立を承認'),
('menu.export', 'menu', 'export', '献立をエクスポート'),
('menu.import', 'menu', 'import', '献立をインポート');
```

### 栄養計算関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('nutrition.read', 'nutrition', 'read', '栄養計算結果を閲覧'),
('nutrition.update', 'nutrition', 'update', '栄養基準を更新'),
('nutrition.export', 'nutrition', 'export', '栄養計算をエクスポート');
```

### 食材マスタ関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('ingredient.create', 'ingredient', 'create', '食材を作成'),
('ingredient.read', 'ingredient', 'read', '食材を閲覧'),
('ingredient.update', 'ingredient', 'update', '食材を更新'),
('ingredient.delete', 'ingredient', 'delete', '食材を削除'),
('ingredient.import', 'ingredient', 'import', '食材をインポート');
```

### 帳票関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('report.read', 'report', 'read', '帳票を閲覧'),
('report.export', 'report', 'export', '帳票を出力');
```

### ユーザー管理関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('user.create', 'user', 'create', 'ユーザーを作成'),
('user.read', 'user', 'read', 'ユーザーを閲覧'),
('user.update', 'user', 'update', 'ユーザーを更新'),
('user.delete', 'user', 'delete', 'ユーザーを削除');
```

### 施設管理関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('facility.create', 'facility', 'create', '施設を作成'),
('facility.read', 'facility', 'read', '施設を閲覧'),
('facility.update', 'facility', 'update', '施設を更新'),
('facility.delete', 'facility', 'delete', '施設を削除');
```

### 組織管理関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('organization.create', 'organization', 'create', '組織を作成'),
('organization.read', 'organization', 'read', '組織を閲覧'),
('organization.update', 'organization', 'update', '組織を更新'),
('organization.delete', 'organization', 'delete', '組織を削除');
```

### 設定関連

```sql
INSERT INTO core.permissions (name, resource, action, description) VALUES
('setting.read', 'setting', 'read', '設定を閲覧'),
('setting.update', 'setting', 'update', '設定を更新');
```

## ロールとパーミッションの関連付け

### テナント管理者（全権限）

```sql
INSERT INTO core.role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM core.roles WHERE name = 'TENANT_ADMIN' AND scope = 'system'),
    id
FROM core.permissions;
```

### 栄養士（献立・栄養計算のみ）

```sql
INSERT INTO core.role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM core.roles WHERE name = 'NUTRITIONIST' AND scope = 'system'),
    id
FROM core.permissions
WHERE name IN (
    'menu.create', 'menu.read', 'menu.update', 'menu.export',
    'nutrition.read', 'nutrition.export',
    'ingredient.read',
    'report.read', 'report.export'
);
```

### 調理師（閲覧のみ）

```sql
INSERT INTO core.role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM core.roles WHERE name = 'COOK' AND scope = 'system'),
    id
FROM core.permissions
WHERE name IN (
    'menu.read',
    'ingredient.read',
    'report.read', 'report.export'
);
```

## クエリ例

### ユーザーのパーミッションを取得

```sql
SELECT DISTINCT p.name, p.resource, p.action
FROM core.permissions p
INNER JOIN core.role_permissions rp ON p.id = rp.permission_id
INNER JOIN core.user_roles ur ON rp.role_id = ur.role_id
WHERE ur.user_id = :user_id
  AND p.is_active = true;
```

### パーミッションチェック

```sql
CREATE OR REPLACE FUNCTION has_permission(
    p_user_id UUID,
    p_permission_name VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM core.user_roles ur
        INNER JOIN core.role_permissions rp ON ur.role_id = rp.role_id
        INNER JOIN core.permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = p_user_id
          AND p.name = p_permission_name
          AND p.is_active = true
    );
END;
$$ LANGUAGE plpgsql;
```

### 特定リソースへの操作可否をチェック

```sql
CREATE OR REPLACE FUNCTION can_perform_action(
    p_user_id UUID,
    p_resource VARCHAR,
    p_action VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM core.user_roles ur
        INNER JOIN core.role_permissions rp ON ur.role_id = rp.role_id
        INNER JOIN core.permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = p_user_id
          AND p.resource::TEXT = p_resource
          AND p.action::TEXT = p_action
          AND p.is_active = true
    );
END;
$$ LANGUAGE plpgsql;
```

## ビジネスルール

### パーミッション命名規則
- フォーマット: `{resource}.{action}`
- 例: `menu.create`, `user.update`, `report.export`

### 権限チェックフロー
1. ユーザーのロールを取得（`core.user_roles`）
2. ロールに紐づくパーミッションを取得（`core.role_permissions`）
3. 要求されたパーミッションが含まれているかチェック

### Spring Security統合

```kotlin
@PreAuthorize("@permissionEvaluator.hasPermission(authentication, 'menu', 'create')")
fun createMenu(request: MenuCreateRequest): MenuResponse {
    // 献立作成ロジック
}

@Component
class CustomPermissionEvaluator : PermissionEvaluator {
    override fun hasPermission(
        authentication: Authentication,
        resource: Any,
        action: Any
    ): Boolean {
        val userId = authentication.principal as UUID
        return permissionService.canPerformAction(userId, resource.toString(), action.toString())
    }
}
```

## パーミッションマトリックス

| ロール / 権限 | menu.* | nutrition.* | ingredient.* | report.* | user.* | facility.* | setting.* |
|--------------|--------|-------------|--------------|----------|--------|------------|-----------|
| TENANT_ADMIN | 全て | 全て | 全て | 全て | 全て | 全て | 全て |
| ORG_ADMIN | 全て | 全て | 全て | 全て | read, update | read, update | read, update |
| FACILITY_ADMIN | 全て | read, export | read | 全て | read（施設内） | read | read, update（施設内） |
| NUTRITIONIST | CRUD, export | read, export | read | read, export | - | - | - |
| COOK | read | - | read | read, export | - | - | - |
| VIEWER | read | read | read | read, export | - | - | - |

## 備考

- パーミッションは運営管理者のみが追加可能
- 新機能追加時は対応するパーミッションも追加
- 物理削除は行わず、`is_active = false` で論理削除
- パーミッション変更時はキャッシュを無効化
