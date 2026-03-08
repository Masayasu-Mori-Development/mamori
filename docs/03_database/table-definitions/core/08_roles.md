# ロールテーブル (core.roles)

## 概要

顧客ユーザー（保育施設スタッフ）の権限ロールを管理するテーブル。
RBAC（Role-Based Access Control）の実装基盤。

## テーブル定義

```sql
CREATE TYPE role_scope AS ENUM (
    'system',       -- システム全体（運営管理者が定義）
    'organization', -- 組織単位（本部管理者が定義）
    'facility'      -- 施設単位（施設管理者が定義）
);

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

-- ユーザーとロールの中間テーブル
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
```

## カラム定義

### core.roles

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | ロールID（主キー） |
| tenant_id | UUID | NULL | - | テナントID（system以外で必須） |
| organization_id | UUID | NULL | - | 組織ID（organization scopeで必須） |
| facility_id | UUID | NULL | - | 施設ID（facility scopeで必須） |
| name | VARCHAR(100) | NOT NULL | - | ロール名（英数字） |
| display_name | VARCHAR(100) | NOT NULL | - | 表示名（日本語） |
| description | TEXT | NULL | - | 説明 |
| scope | role_scope | NOT NULL | - | スコープ（system/organization/facility） |
| is_system_role | BOOLEAN | NOT NULL | false | システムロールフラグ |
| is_active | BOOLEAN | NOT NULL | true | アクティブフラグ |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者 |
| updated_by | UUID | NULL | - | 更新者 |

### core.user_roles

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 割り当てID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID |
| user_id | UUID | NOT NULL | - | ユーザーID |
| role_id | UUID | NOT NULL | - | ロールID |
| facility_id | UUID | NULL | - | 施設ID（施設限定ロールの場合） |
| granted_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 付与日時 |
| granted_by | UUID | NULL | - | 付与者 |

## デフォルトロール

### システムロール（全テナント共通）

```sql
INSERT INTO core.roles (name, display_name, description, scope, is_system_role) VALUES
('TENANT_ADMIN', 'テナント管理者', 'テナント全体の管理権限', 'system', true),
('ORG_ADMIN', '組織管理者', '組織全体の管理権限', 'system', true),
('FACILITY_ADMIN', '施設管理者', '施設の管理権限', 'system', true),
('NUTRITIONIST', '栄養士', '献立作成・栄養計算権限', 'system', true),
('COOK', '調理師', '献立閲覧権限', 'system', true),
('VIEWER', '閲覧者', '閲覧のみ', 'system', true);
```

## サンプルデータ

### カスタムロール（組織固有）

```sql
INSERT INTO core.roles (
    tenant_id, organization_id, name, display_name, description, scope
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    'MENU_REVIEWER',
    '献立レビュワー',
    '献立の承認権限を持つ',
    'organization'
);
```

### ユーザーへのロール割り当て

```sql
INSERT INTO core.user_roles (tenant_id, user_id, role_id, facility_id) VALUES
(
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    (SELECT id FROM core.roles WHERE name = 'NUTRITIONIST' AND scope = 'system'),
    '123e4567-e89b-12d3-a456-426614174000'
);
```

## クエリ例

### ユーザーの権限を取得

```sql
SELECT r.name, r.display_name, r.scope, ur.facility_id
FROM core.user_roles ur
INNER JOIN core.roles r ON ur.role_id = r.id
WHERE ur.user_id = :user_id
  AND ur.tenant_id = :tenant_id
  AND r.is_active = true;
```

### 施設の管理者を取得

```sql
SELECT u.*, r.display_name as role_name
FROM core.users u
INNER JOIN core.user_roles ur ON u.id = ur.user_id
INNER JOIN core.roles r ON ur.role_id = r.id
WHERE ur.facility_id = :facility_id
  AND r.name = 'FACILITY_ADMIN'
  AND u.is_active = true;
```

## 権限チェックロジック

### 階層的な権限

```sql
-- テナント管理者: 全施設にアクセス可能
-- 組織管理者: 配下の全施設にアクセス可能
-- 施設管理者: 担当施設のみアクセス可能

CREATE OR REPLACE FUNCTION check_facility_access(
    p_user_id UUID,
    p_facility_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM core.user_roles ur
        INNER JOIN core.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_user_id
          AND (
              -- テナント管理者
              r.name = 'TENANT_ADMIN'
              OR
              -- 組織管理者（施設の所属組織と一致）
              (r.name = 'ORG_ADMIN' AND EXISTS (
                  SELECT 1 FROM core.facilities f
                  WHERE f.id = p_facility_id
                    AND f.organization_id = r.organization_id
              ))
              OR
              -- 施設管理者または担当者
              ur.facility_id = p_facility_id
          )
    );
END;
$$ LANGUAGE plpgsql;
```

## ビジネスルール

### ロールスコープ
- **system**: 全テナント共通の標準ロール（運営が定義）
- **organization**: 組織固有のカスタムロール（本部管理者が定義）
- **facility**: 施設固有のカスタムロール（施設管理者が定義）

### ロール継承
- テナント管理者 > 組織管理者 > 施設管理者 > 一般ユーザー
- 上位ロールは下位ロールの権限を包含

### デフォルト権限

| ロール | 献立作成 | 献立編集 | 献立削除 | 帳票出力 | ユーザー管理 | 設定変更 |
|--------|---------|---------|---------|---------|------------|---------|
| TENANT_ADMIN | ◯ | ◯ | ◯ | ◯ | ◯ | ◯ |
| ORG_ADMIN | ◯ | ◯ | ◯ | ◯ | ◯（組織内） | ◯（組織内） |
| FACILITY_ADMIN | ◯ | ◯ | ◯ | ◯ | ◯（施設内） | ◯（施設内） |
| NUTRITIONIST | ◯ | ◯ | △ | ◯ | × | × |
| COOK | × | × | × | ◯ | × | × |
| VIEWER | × | × | × | ◯ | × | × |

## 備考

- システムロール（`is_system_role = true`）は変更・削除不可
- カスタムロールは各組織・施設が自由に定義可能
- 権限の詳細は `core.permissions` および `core.role_permissions` で管理
- ロールの物理削除は行わず、`is_active = false` で論理削除
