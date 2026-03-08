---
paths:
  - "**/controller/**"
  - "**/api/**"
---

# API設計原則

## エンドポイント構成

```
/api/core/*   → core-backend（認証・テナント管理など）
/api/hoiku/*  → hoiku-backend（献立・栄養計算など）
```

## RESTful設計

- **リソース指向**: URLはリソースを表現
- **HTTPメソッド**: GET（取得）、POST（作成）、PUT（更新）、DELETE（削除）
- **ステータスコード**: 適切なHTTPステータスコードを返却

### エンドポイント命名規則

```
/api/{service}/{resource}/{id}/{action}
```

**例**:
- `GET /api/core/users` - ユーザー一覧
- `POST /api/core/auth/login` - ログイン
- `GET /api/hoiku/menus/{id}` - 献立詳細
- `POST /api/hoiku/menus/{id}/ingredients` - 食材追加
- `GET /api/hoiku/menus/{id}/nutrition` - 栄養計算結果

## バージョニング

- 初期は バージョンなし
- 将来的に `/api/v2/` などで対応
- 破壊的変更は事前通知（3ヶ月前）

## リクエスト/レスポンス形式

### リクエスト

```json
POST /api/hoiku/menus
Content-Type: application/json
Authorization: Bearer {JWT_TOKEN}

{
  "menuDate": "2026-03-10",
  "mealType": "LUNCH",
  "menuName": "カレーライス",
  "description": "野菜たっぷりのカレー",
  "targetAgeGroup": "3-5歳"
}
```

### 成功レスポンス

```json
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "menuDate": "2026-03-10",
  "mealType": "LUNCH",
  "menuName": "カレーライス",
  "description": "野菜たっぷりのカレー",
  "targetAgeGroup": "3-5歳",
  "status": "DRAFT",
  "createdAt": "2026-03-08T10:30:00Z",
  "updatedAt": "2026-03-08T10:30:00Z"
}
```

### エラーレスポンス

統一されたエラーレスポンス形式：

```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "VALIDATION_ERROR",
  "message": "入力値が不正です",
  "details": [
    "献立名は必須です",
    "献立日は未来日付である必要があります"
  ]
}
```

## HTTPステータスコード

| コード | 用途 | 例 |
|--------|------|-----|
| 200 OK | 成功（取得・更新） | GET /api/hoiku/menus |
| 201 Created | 作成成功 | POST /api/hoiku/menus |
| 204 No Content | 削除成功 | DELETE /api/hoiku/menus/{id} |
| 400 Bad Request | バリデーションエラー | 必須項目未入力 |
| 401 Unauthorized | 認証エラー | JWTトークンなし・無効 |
| 403 Forbidden | 認可エラー | 権限不足 |
| 404 Not Found | リソースなし | 献立が見つからない |
| 409 Conflict | 競合 | 重複データ |
| 500 Internal Server Error | サーバーエラー | 予期しないエラー |

## ページネーション

大量データは必ずページング処理を実装：

### リクエスト

```
GET /api/hoiku/menus?page=1&size=20&sort=menuDate,desc
```

クエリパラメータ：
- `page`: ページ番号（0始まり）
- `size`: 1ページあたりの件数（デフォルト: 20、最大: 100）
- `sort`: ソート順（例: `menuDate,desc`）

### レスポンス

```json
{
  "content": [
    { "id": "...", "menuName": "カレーライス", ... },
    { "id": "...", "menuName": "ハンバーグ定食", ... }
  ],
  "page": {
    "number": 1,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8
  }
}
```

## 認証・認可

### 認証ヘッダー

```
Authorization: Bearer <JWT_TOKEN>
```

### トークンなし

```json
HTTP/1.1 401 Unauthorized

{
  "error": "UNAUTHORIZED",
  "message": "認証が必要です"
}
```

### 権限不足

```json
HTTP/1.1 403 Forbidden

{
  "error": "FORBIDDEN",
  "message": "この操作を実行する権限がありません"
}
```

## Core Backend API例

### 認証

```
POST /api/core/auth/login
POST /api/core/auth/refresh
POST /api/core/auth/logout
```

### ユーザー管理

```
GET    /api/core/users
POST   /api/core/users
GET    /api/core/users/{id}
PUT    /api/core/users/{id}
DELETE /api/core/users/{id}
```

### 施設管理

```
GET    /api/core/facilities
POST   /api/core/facilities
GET    /api/core/facilities/{id}
PUT    /api/core/facilities/{id}
DELETE /api/core/facilities/{id}
```

## Hoiku Backend API例

### 献立管理

```
GET    /api/hoiku/menus
POST   /api/hoiku/menus
GET    /api/hoiku/menus/{id}
PUT    /api/hoiku/menus/{id}
DELETE /api/hoiku/menus/{id}
POST   /api/hoiku/menus/{id}/publish        # 公開
POST   /api/hoiku/menus/{id}/archive        # アーカイブ
```

### 食材追加

```
GET    /api/hoiku/menus/{id}/ingredients
POST   /api/hoiku/menus/{id}/ingredients
DELETE /api/hoiku/menus/{id}/ingredients/{ingredientId}
```

### 栄養計算

```
GET /api/hoiku/menus/{id}/nutrition          # 栄養計算結果
```

### 帳票生成

```
POST /api/hoiku/reports/pdf                  # PDF生成
GET  /api/hoiku/reports                      # 帳票履歴一覧
GET  /api/hoiku/reports/{id}/download        # PDFダウンロード
```

## セキュリティ

- 全てのエンドポイントは認証必須（ログインを除く）
- テナントIDによるデータ分離を徹底
- SQLインジェクション対策（プリペアドステートメント）
- XSS対策（入力値エスケープ）
- CSRF対策（トークン検証）
