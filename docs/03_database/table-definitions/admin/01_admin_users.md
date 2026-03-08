# 運営管理ユーザーテーブル (admin.admin_users)

## 概要

システム運営側のユーザー（まもりごはん運営メンバー）を管理するテーブル。
**顧客ユーザー（core.users）とは完全に分離**。

## テーブル定義

```sql
CREATE TYPE admin_role_type AS ENUM (
    'super_admin',      -- スーパー管理者
    'admin',            -- 管理者
    'support',          -- サポート担当
    'analyst',          -- アナリスト（閲覧のみ）
    'developer'         -- 開発者
);

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
```

## カラム定義

| カラム名 | データ型 | NULL | デフォルト | 説明 |
|---------|---------|------|-----------|------|
| id | UUID | NOT NULL | gen_random_uuid() | 管理者ID（主キー） |
| email | VARCHAR(255) | NOT NULL | - | メールアドレス |
| password_hash | VARCHAR(255) | NOT NULL | - | パスワードハッシュ |
| family_name | VARCHAR(100) | NOT NULL | - | 姓 |
| given_name | VARCHAR(100) | NOT NULL | - | 名 |
| admin_role | admin_role_type | NOT NULL | - | 管理者ロール |
| is_mfa_enabled | BOOLEAN | NOT NULL | true | MFA有効フラグ |
| mfa_secret | VARCHAR(255) | NULL | - | MFAシークレット（TOTP） |
| is_active | BOOLEAN | NOT NULL | true | アクティブフラグ |
| last_login_at | TIMESTAMP | NULL | - | 最終ログイン日時 |
| password_changed_at | TIMESTAMP | NULL | - | パスワード変更日時 |
| ip_whitelist | TEXT[] | NULL | - | IPホワイトリスト |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 更新日時 |
| created_by | UUID | NULL | - | 作成者 |
| updated_by | UUID | NULL | - | 更新者 |

## サンプルデータ

```sql
INSERT INTO admin.admin_users (
    email, password_hash, family_name, given_name,
    admin_role, is_mfa_enabled, is_active
) VALUES (
    'admin@mamori.jp',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    '運営',
    '太郎',
    'super_admin',
    true,
    true
);
```

## セキュリティ要件

### MFA（多要素認証）
- **必須**: 全ての管理者ユーザーはMFA有効化必須
- **方式**: TOTP（Google Authenticator、Authy等）
- **バックアップコード**: 初回設定時に発行

### JWT
- **Secret Key**: 顧客用とは異なる専用シークレット
- **Type Field**: `type: "admin"` を必須で含む
- **有効期限**: 30分（顧客用より短い）

### IP制限
- **ホワイトリスト**: `ip_whitelist` に登録されたIPのみアクセス可
- **動的IP対応**: VPN経由でのアクセスを推奨

## ビジネスルール

### ロール権限

| ロール | テナント管理 | ユーザー管理 | マスタ管理 | 監査ログ閲覧 | システム設定 |
|--------|------------|------------|-----------|------------|------------|
| super_admin | ◯ | ◯ | ◯ | ◯ | ◯ |
| admin | ◯ | ◯ | ◯ | ◯ | △ |
| support | △（閲覧） | △（閲覧） | × | △（一部） | × |
| analyst | △（閲覧） | × | × | ◯ | × |
| developer | × | × | △（開発用） | × | △（開発環境のみ） |

## 備考

- **重要**: `core.users` とは完全に別テーブル
- JWT生成時は必ず `type: "admin"` フィールドを含める
- 管理者の追加・削除は super_admin のみ実行可能
- 物理削除は行わず、`is_active = false` で論理削除
