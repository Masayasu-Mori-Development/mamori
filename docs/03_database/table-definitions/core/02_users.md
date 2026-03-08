# ユーザーテーブル (core.users)

## 概要

顧客向けユーザー（保育施設スタッフ）の認証情報とプロフィールを管理するテーブル。
運営管理ユーザー（admin.admin_users）とは完全に分離されている。

## テーブル定義

```sql
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
    updated_by         UUID
);

CREATE INDEX idx_users_tenant_id ON core.users(tenant_id);
CREATE INDEX idx_users_email ON core.users(email);
CREATE INDEX idx_users_is_active ON core.users(is_active);
CREATE INDEX idx_users_employee_number ON core.users(tenant_id, employee_number);
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | ユーザーID（主キー） |
| tenant_id | UUID | NOT NULL | - | テナントID（外部キー） |
| email | VARCHAR(255) | NOT NULL | - | メールアドレス（ログインID） |
| password_hash | VARCHAR(255) | NOT NULL | - | パスワードハッシュ（bcrypt） |
| family_name | VARCHAR(100) | NOT NULL | - | 姓 |
| given_name | VARCHAR(100) | NOT NULL | - | 名 |
| family_name_kana | VARCHAR(100) | NULL | - | 姓（カナ） |
| given_name_kana | VARCHAR(100) | NULL | - | 名（カナ） |
| phone_number | VARCHAR(20) | NULL | - | 電話番号 |
| employee_number | VARCHAR(50) | NULL | - | 社員番号 |
| is_active | BOOLEAN | NOT NULL | true | アクティブフラグ |
| last_login_at | TIMESTAMP | NULL | - | 最終ログイン日時 |
| password_changed_at | TIMESTAMP | NULL | - | パスワード変更日時 |
| email_verified | BOOLEAN | NOT NULL | false | メール認証済みフラグ |
| email_verified_at | TIMESTAMP | NULL | - | メール認証日時 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者（users.id） |
| updated_by | UUID | NULL | - | 更新者（users.id） |

## 制約

### 主キー
- `PRIMARY KEY (id)`

### 外部キー
- `FOREIGN KEY (tenant_id) REFERENCES core.tenants(id)`

### ユニーク制約
- `UNIQUE (email)` - メールアドレスは全テナント間で一意

### CHECK制約

```sql
ALTER TABLE core.users ADD CONSTRAINT chk_users_email_format
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
```

## インデックス

| インデックス名 | カラム | 目的 |
|-------------|-------|------|
| idx_users_tenant_id | tenant_id | テナント別ユーザー一覧取得 |
| idx_users_email | email | ログイン処理の高速化 |
| idx_users_is_active | is_active | アクティブユーザー検索 |
| idx_users_employee_number | tenant_id, employee_number | 社員番号検索（テナント内） |

## 関連テーブル

- `core.tenants` - 所属テナント
- `core.user_organization_history` - 組織所属履歴
- `core.user_facilities` - 施設担当履歴
- `core.roles` - 権限ロール（中間テーブル経由）

## サンプルデータ

```sql
INSERT INTO core.users (
    id, tenant_id, email, password_hash,
    family_name, given_name, family_name_kana, given_name_kana,
    employee_number, is_active, email_verified
) VALUES (
    '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    '550e8400-e29b-41d4-a716-446655440000',
    'tanaka.hanako@sakurakai.jp',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- 'password123'のハッシュ
    '田中',
    '花子',
    'タナカ',
    'ハナコ',
    'EMP-001',
    true,
    true
);
```

## セキュリティ考慮事項

### パスワードポリシー
- 最小8文字
- 英数字混在必須
- bcryptでハッシュ化（work factor: 10以上）
- 90日ごとの変更推奨

### アカウントロック
- 5回連続ログイン失敗で30分ロック
- ロック情報は別テーブル（core.user_login_attempts）で管理

### メール認証
- 新規登録時に認証メール送信
- `email_verified = false` の間は機能制限

## 備考

- ユーザーの物理削除は行わず、`is_active = false` で論理削除
- 退職者は `is_active = false` に設定し、user_organization_history に終了日を記録
- 再入社の場合、同じ email で再度 `is_active = true` に戻す
- **重要**: 運営管理ユーザー（admin.admin_users）とは完全に分離
- JWT生成時は `type: "customer"` フィールドを含める
