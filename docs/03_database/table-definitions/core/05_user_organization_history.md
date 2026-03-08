# ユーザー組織所属履歴テーブル (core.user_organization_history)

## 概要

ユーザーの組織への所属履歴を管理するテーブル。
入社・退社・異動・再入社などのイベントを全て記録する。

## テーブル定義

```sql
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
    CONSTRAINT chk_user_org_history_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_user_org_history_tenant_id ON core.user_organization_history(tenant_id);
CREATE INDEX idx_user_org_history_user_id ON core.user_organization_history(user_id);
CREATE INDEX idx_user_org_history_organization_id ON core.user_organization_history(organization_id);
CREATE INDEX idx_user_org_history_current ON core.user_organization_history(user_id, end_date) WHERE end_date IS NULL;
CREATE INDEX idx_user_org_history_dates ON core.user_organization_history(start_date, end_date);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 履歴ID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID（外部キー） |
| user_id | UUID | NOT NULL | - | ユーザーID（外部キー） |
| organization_id | UUID | NOT NULL | - | 組織ID（外部キー） |
| start_date | DATE | NOT NULL | - | 開始日 |
| end_date | DATE | NULL | - | 終了日（NULL=現在所属中） |
| employment_type | VARCHAR(50) | NOT NULL | - | 雇用形態（正社員/契約社員/パート等） |
| position | VARCHAR(100) | NULL | - | 役職 |
| department | VARCHAR(100) | NULL | - | 部署 |
| notes | TEXT | NULL | - | 備考 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者（users.id） |
| updated_by | UUID | NULL | - | 更新者（users.id） |

## 制約

### 主キー
- `PRIMARY KEY (id)`

### 外部キー
- `FOREIGN KEY (tenant_id) REFERENCES core.tenants(id)`
- `FOREIGN KEY (user_id) REFERENCES core.users(id)`
- `FOREIGN KEY (organization_id) REFERENCES core.organizations(id)`

### CHECK制約

```sql
ALTER TABLE core.user_organization_history ADD CONSTRAINT chk_user_org_history_employment_type
    CHECK (employment_type IN ('正社員', '契約社員', 'パート', 'アルバイト', '派遣', '業務委託'));
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_user_org_history_tenant_id | tenant_id | テナント別履歴検索 |
| idx_user_org_history_user_id | user_id | ユーザー別履歴取得 |
| idx_user_org_history_organization_id | organization_id | 組織別所属者検索 |
| idx_user_org_history_current | user_id, end_date (WHERE end_date IS NULL) | 現在所属中の組織検索 |
| idx_user_org_history_dates | start_date, end_date | 期間検索 |

## 関連テーブル

- `core.tenants` - テナント
- `core.users` - ユーザー
- `core.organizations` - 組織

## サンプルデータ

### 現在所属中

```sql
INSERT INTO core.user_organization_history (
    id, tenant_id, user_id, organization_id,
    start_date, end_date, employment_type, position, department
) VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '2024-04-01',
    NULL,  -- 現在所属中
    '正社員',
    '栄養士',
    '給食部'
);
```

### 退職済み

```sql
INSERT INTO core.user_organization_history (
    id, tenant_id, user_id, organization_id,
    start_date, end_date, employment_type, position, department, notes
) VALUES (
    'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '2022-04-01',
    '2024-03-31',
    '正社員',
    '栄養士',
    '給食部',
    '一身上の都合により退職'
);
```

### 再入社

```sql
-- 1回目の在籍
INSERT INTO core.user_organization_history (
    tenant_id, user_id, organization_id,
    start_date, end_date, employment_type
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '2020-04-01',
    '2022-03-31',
    '正社員'
);

-- 2回目の在籍（再入社）
INSERT INTO core.user_organization_history (
    tenant_id, user_id, organization_id,
    start_date, end_date, employment_type
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
    '2024-04-01',
    NULL,  -- 現在所属中
    '正社員'
);
```

## クエリ例

### 現在所属中のユーザーを取得

```sql
SELECT u.*, uoh.organization_id, uoh.employment_type, uoh.position
FROM core.users u
INNER JOIN core.user_organization_history uoh ON u.id = uoh.user_id
WHERE uoh.tenant_id = :tenant_id
  AND uoh.end_date IS NULL;
```

### 特定期間に在籍していたユーザーを取得

```sql
SELECT u.*, uoh.organization_id, uoh.start_date, uoh.end_date
FROM core.users u
INNER JOIN core.user_organization_history uoh ON u.id = uoh.user_id
WHERE uoh.tenant_id = :tenant_id
  AND uoh.start_date <= :target_date
  AND (uoh.end_date IS NULL OR uoh.end_date >= :target_date);
```

## ビジネスルール

### 期間の重複チェック
- 同一ユーザーが複数の組織に同時所属することは可能（兼務）
- 同一組織への重複所属は不可（アプリケーション層でチェック）

### 終了日の設定
- `end_date = NULL` は現在所属中を意味する
- 退職時は `end_date` を設定し、`core.users.is_active = false` に更新
- 異動時は既存レコードに `end_date` を設定し、新しいレコードを作成

### 再入社の扱い
- 同じ `user_id` で新しいレコードを作成
- `core.users.is_active = true` に戻す
- メールアドレスが変わっている場合は `core.users.email` を更新

## 備考

- 履歴データは物理削除しない（監査証跡）
- 給与計算・勤怠管理との連携に使用
- 組織変更の履歴を完全に追跡可能
