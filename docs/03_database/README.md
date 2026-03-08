# データベース設計

## 概要

このディレクトリには、PostgreSQLのスキーマ設計とテーブル定義書を管理します。

## ドキュメント一覧

| ドキュメント名 | 説明 | ステータス |
|--------------|------|-----------|
| [schema-design.md](./schema-design.md) | スキーマ設計（Core/Hoiku分離） | 作成済み |
| [table-definitions/](./table-definitions/) | テーブル定義書 | テンプレート作成済み |
| [er-diagrams/](./er-diagrams/) | ER図 | 未作成 |

## Schema構成

### Core Schema

認証・ユーザー管理・テナント管理など共通機能のテーブル。

**テーブル一覧**:
- `core.tenants` - テナント
- `core.organizations` - 法人
- `core.facilities` - 施設
- `core.users` - ユーザー
- `core.roles` - 役割
- `core.user_roles` - ユーザー役割

### Hoiku Schema

献立・栄養計算・帳票生成など保育特化機能のテーブル。

**テーブル一覧**:
- `hoiku.menus` - 献立
- `hoiku.ingredients` - 食材
- `hoiku.menu_ingredients` - 献立食材
- `hoiku.nutrition_standards` - 栄養基準
- `hoiku.report_templates` - 帳票テンプレート
- `hoiku.generated_reports` - 生成済み帳票

## テーブル定義書の作成方法

1. `table-definitions/core/` または `table-definitions/hoiku/` 配下に `{table_name}.md` を作成
2. テンプレートに従って記述
3. プルリクエストでレビュー

## 参考資料

- [schema-design.md](./schema-design.md) - スキーマ設計の詳細
- [02_design/domain-model.md](../02_design/domain-model.md) - ドメインモデル
