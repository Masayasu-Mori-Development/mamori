# テーブル定義書: core.tenants

## 概要

テナント（法人・組織）を管理するテーブル。マルチテナントの基盤となる。

## テーブル情報

| 項目 | 内容 |
|------|------|
| スキーマ名 | core |
| テーブル名 | tenants |
| 物理名 | core.tenants |
| 説明 | テナント情報 |

## カラム定義

| カラム名 | 物理名 | 型 | NULL | デフォルト | 説明 |
|---------|--------|-----|------|-----------|------|
| ID | id | UUID | NOT NULL | gen_random_uuid() | 主キー |
| テナント名 | name | VARCHAR(255) | NOT NULL | - | テナント名 |
| テナントコード | code | VARCHAR(50) | NOT NULL | - | テナントコード（一意） |
| プラン | plan | VARCHAR(50) | NOT NULL | 'free' | プラン（free, basic, premium） |
| ステータス | status | VARCHAR(20) | NOT NULL | 'active' | ステータス（active, suspended, deleted） |
| 作成日時 | created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| 更新日時 | updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| 作成者 | created_by | UUID | NULL | - | 作成者のユーザーID |
| 更新者 | updated_by | UUID | NULL | - | 更新者のユーザーID |

## 制約

### 主キー

```sql
CONSTRAINT pk_tenants PRIMARY KEY (id)
```

### ユニーク制約

```sql
CONSTRAINT uk_tenants_code UNIQUE (code)
```

### インデックス

| インデックス名 | カラム | 種別 | 説明 |
|--------------|--------|------|------|
| idx_tenants_code | code | UNIQUE | テナントコード検索 |
| idx_tenants_status | status | INDEX | ステータス検索 |

## DDL

```sql
CREATE TABLE core.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'free',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_tenants_code ON core.tenants(code);
CREATE INDEX idx_tenants_status ON core.tenants(status);

COMMENT ON TABLE core.tenants IS 'テナント（法人・組織）';
COMMENT ON COLUMN core.tenants.id IS '主キー';
COMMENT ON COLUMN core.tenants.name IS 'テナント名';
COMMENT ON COLUMN core.tenants.code IS 'テナントコード（一意）';
COMMENT ON COLUMN core.tenants.plan IS 'プラン（free, basic, premium）';
COMMENT ON COLUMN core.tenants.status IS 'ステータス（active, suspended, deleted）';
```

## サンプルデータ

```sql
INSERT INTO core.tenants (id, name, code, plan, status) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'サンプル法人A', 'TENANT_A', 'free', 'active'),
('550e8400-e29b-41d4-a716-446655440001', 'サンプル法人B', 'TENANT_B', 'basic', 'active'),
('550e8400-e29b-41d4-a716-446655440002', 'サンプル法人C', 'TENANT_C', 'premium', 'active');
```

## 関連テーブル

| テーブル | 関連 | 説明 |
|---------|------|------|
| core.organizations | 1:N | テナントは複数の法人を持つ |
| core.facilities | 1:N | テナントは複数の施設を持つ |
| core.users | 1:N | テナントは複数のユーザーを持つ |

## 変更履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|-----------|---------|--------|
| 2026-03-08 | 1.0.0 | 初版作成（テンプレート） | - |
