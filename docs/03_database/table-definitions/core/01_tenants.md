# テナントテーブル (core.tenants)

## 概要

マルチテナント設計の基盤となるテーブル。全てのビジネスデータはこのテーブルに紐づく。

## テーブル定義

```sql
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
    updated_by          UUID
);

CREATE INDEX idx_tenants_subdomain ON core.tenants(subdomain);
CREATE INDEX idx_tenants_subscription_status ON core.tenants(subscription_status);
CREATE INDEX idx_tenants_is_active ON core.tenants(is_active);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | テナントID（主キー） |
| name | VARCHAR(255) | NOT NULL | - | テナント名（組織名） |
| subdomain | VARCHAR(100) | NOT NULL | - | サブドメイン（例: hoikuen123.mamori.jp） |
| plan_type | VARCHAR(50) | NOT NULL | 'trial' | プランタイプ（trial/basic/standard/enterprise） |
| subscription_status | VARCHAR(50) | NOT NULL | 'active' | 契約状態（active/suspended/cancelled） |
| max_users | INTEGER | NOT NULL | 10 | 最大ユーザー数 |
| max_facilities | INTEGER | NOT NULL | 3 | 最大施設数 |
| trial_end_date | TIMESTAMP | NULL | - | トライアル終了日 |
| contract_start_date | DATE | NULL | - | 契約開始日 |
| contract_end_date | DATE | NULL | - | 契約終了日 |
| is_active | BOOLEAN | NOT NULL | true | アクティブフラグ |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者（admin_users.id） |
| updated_by | UUID | NULL | - | 更新者（admin_users.id） |

## 制約

### 主キー
- `PRIMARY KEY (id)`

### ユニーク制約
- `UNIQUE (subdomain)` - サブドメインは一意

### CHECK制約

```sql
ALTER TABLE core.tenants ADD CONSTRAINT chk_tenants_plan_type
    CHECK (plan_type IN ('trial', 'basic', 'standard', 'enterprise'));

ALTER TABLE core.tenants ADD CONSTRAINT chk_tenants_subscription_status
    CHECK (subscription_status IN ('active', 'suspended', 'cancelled'));

ALTER TABLE core.tenants ADD CONSTRAINT chk_tenants_max_users
    CHECK (max_users > 0);

ALTER TABLE core.tenants ADD CONSTRAINT chk_tenants_max_facilities
    CHECK (max_facilities > 0);
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_tenants_subdomain | subdomain | サブドメイン検索の高速化 |
| idx_tenants_subscription_status | subscription_status | 契約状態フィルタリング |
| idx_tenants_is_active | is_active | アクティブテナント検索 |

## サンプルデータ

```sql
INSERT INTO core.tenants (
    id, name, subdomain, plan_type, subscription_status,
    max_users, max_facilities, contract_start_date
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    '社会福祉法人さくら会',
    'sakurakai',
    'standard',
    'active',
    50,
    10,
    '2025-01-01'
);
```

## 備考

- テナントの物理削除は行わず、`is_active = false` で論理削除
- 運営管理画面（admin-frontend）からのみ作成・編集可能
- 顧客画面（hoiku-frontend）からは参照のみ
- サブドメインは英数字とハイフンのみ許可（バリデーションはアプリケーション層で実施）
