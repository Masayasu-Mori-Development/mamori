# API設計

API仕様書とエンドポイント定義を管理するディレクトリです。

## ファイル構成

- **api-overview.md**: API設計の全体方針とエンドポイント一覧
- **core-api-spec.md**: Core Backend（/api/core/*）のAPI仕様書
- **hoiku-api-spec.md**: Hoiku Backend（/api/hoiku/*）のAPI仕様書
- **error-codes.md**: エラーコード一覧と対処方法
- **changelog.md**: API変更履歴

## OpenAPI（Swagger）仕様書

各バックエンドでOpenAPI仕様書が自動生成されます。

### Core Backend

- URL: `http://localhost:8080/swagger-ui.html`
- JSON: `http://localhost:8080/v3/api-docs`

### Hoiku Backend

- URL: `http://localhost:8081/swagger-ui.html`
- JSON: `http://localhost:8081/v3/api-docs`

## 命名規則

エンドポイントは以下の規則に従います：

```
/api/{service}/{resource}/{id}/{action}
```

**例**:
- `GET /api/core/users` - ユーザー一覧
- `POST /api/core/auth/login` - ログイン
- `GET /api/hoiku/menus/{id}` - 献立詳細
- `POST /api/hoiku/menus/{id}/ingredients` - 食材追加

## 更新ルール

1. **実装前に仕様書を作成**: API仕様を先に定義してからコード実装
2. **変更時は必ず更新**: エンドポイント追加・変更時は必ずドキュメント更新
3. **破壊的変更の記録**: 既存APIに影響する変更は changelog.md に記録
4. **サンプルリクエスト/レスポンス**: 必ず具体例を記載

## 参考

詳細なAPI設計原則は `.claude/rules/api-design.md` を参照してください。
