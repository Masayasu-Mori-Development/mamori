# Hoiku Backend API エンドポイント定義

## 概要

hoiku-backend が提供する REST API エンドポイントの詳細仕様。

**ベースURL**: `http://localhost:8081` (開発環境)
**プロダクション**: `https://api.mamori.jp`

## 認証

全てのエンドポイント（`/auth/*` を除く）は JWT 認証が必要です。

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
X-Tenant-ID: 550e8400-e29b-41d4-a716-446655440000
```

## エンドポイント一覧

### 1. 認証 (Authentication)

#### POST /api/hoiku/auth/login

**概要**: ユーザーログイン

**リクエスト**:
```json
{
  "email": "tanaka.hanako@sakurakai.jp",
  "password": "password123"
}
```

**レスポンス**: 200 OK
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "dGhpc2lzYXJlZnJlc2h0b2tlbg...",
  "expiresIn": 3600,
  "user": {
    "id": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "email": "tanaka.hanako@sakurakai.jp",
    "familyName": "田中",
    "givenName": "花子",
    "tenantId": "550e8400-e29b-41d4-a716-446655440000",
    "roles": ["NUTRITIONIST"]
  }
}
```

**エラー**: 401 Unauthorized
```json
{
  "error": "INVALID_CREDENTIALS",
  "message": "メールアドレスまたはパスワードが正しくありません"
}
```

---

#### POST /api/hoiku/auth/refresh

**概要**: アクセストークンのリフレッシュ

**リクエスト**:
```json
{
  "refreshToken": "dGhpc2lzYXJlZnJlc2h0b2tlbg..."
}
```

**レスポンス**: 200 OK
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

---

### 2. 献立管理 (Menus)

#### GET /api/hoiku/menus

**概要**: 献立一覧取得（ページネーション対応）

**クエリパラメータ**:
- `facilityId` (required): 施設ID
- `startDate` (optional): 開始日 (YYYY-MM-DD)
- `endDate` (optional): 終了日 (YYYY-MM-DD)
- `mealType` (optional): 食事区分 (breakfast, lunch, snack, dinner)
- `status` (optional): ステータス (draft, pending, approved, published)
- `page` (optional): ページ番号（デフォルト: 0）
- `size` (optional): ページサイズ（デフォルト: 20, 最大: 100）
- `sort` (optional): ソート条件（例: date,desc）

**リクエスト例**:
```http
GET /api/hoiku/menus?facilityId=123e4567-e89b-12d3-a456-426614174000&startDate=2025-03-01&endDate=2025-03-31&page=0&size=20&sort=date,desc
```

**レスポンス**: 200 OK
```json
{
  "content": [
    {
      "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
      "facilityId": "123e4567-e89b-12d3-a456-426614174000",
      "date": "2025-03-10",
      "mealType": "lunch",
      "title": "春の彩り給食",
      "description": "たけのこご飯、鶏の照り焼き、菜の花のおひたし、お味噌汁",
      "status": "approved",
      "totalServings": 60,
      "estimatedCost": 18000.00,
      "createdAt": "2025-03-01T10:00:00Z",
      "updatedAt": "2025-03-05T15:30:00Z"
    }
  ],
  "page": {
    "number": 0,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8
  },
  "links": {
    "first": "/api/hoiku/menus?facilityId=...&page=0&size=20",
    "prev": null,
    "self": "/api/hoiku/menus?facilityId=...&page=0&size=20",
    "next": "/api/hoiku/menus?facilityId=...&page=1&size=20",
    "last": "/api/hoiku/menus?facilityId=...&page=7&size=20"
  }
}
```

---

#### GET /api/hoiku/menus/{id}

**概要**: 献立詳細取得

**パスパラメータ**:
- `id`: 献立ID

**レスポンス**: 200 OK
```json
{
  "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
  "facilityId": "123e4567-e89b-12d3-a456-426614174000",
  "facilityName": "さくら保育園 新横浜園",
  "date": "2025-03-10",
  "mealType": "lunch",
  "title": "春の彩り給食",
  "description": "たけのこご飯、鶏の照り焼き、菜の花のおひたし、お味噌汁",
  "status": "approved",
  "totalServings": 60,
  "estimatedCost": 18000.00,
  "items": [
    {
      "id": "item-001",
      "dishName": "たけのこご飯",
      "dishOrder": 1,
      "cookingMethod": "炊飯",
      "ingredients": [
        {
          "ingredientId": "ing-001",
          "ingredientName": "精白米",
          "amount": 50.0,
          "unit": "g",
          "wasteRate": 0.0
        },
        {
          "ingredientId": "ing-002",
          "ingredientName": "たけのこ(水煮)",
          "amount": 15.0,
          "unit": "g",
          "wasteRate": 5.0
        }
      ]
    },
    {
      "id": "item-002",
      "dishName": "鶏の照り焼き",
      "dishOrder": 2,
      "cookingMethod": "フライパン焼き",
      "ingredients": [
        {
          "ingredientId": "ing-003",
          "ingredientName": "鶏もも肉",
          "amount": 40.0,
          "unit": "g",
          "wasteRate": 10.0
        }
      ]
    }
  ],
  "nutrition": {
    "ageGroups": [
      {
        "ageGroupId": "age-001",
        "ageGroupName": "3-5歳",
        "servings": 40,
        "energyKcal": 452.5,
        "proteinG": 18.2,
        "fatG": 12.5,
        "carbohydrateG": 68.3,
        "calciumMg": 285.0,
        "ironMg": 3.8,
        "saltEquivalentG": 1.9,
        "standard": {
          "energyKcal": 450.0,
          "proteinG": 18.0,
          "calciumMg": 280.0,
          "ironMg": 4.0,
          "saltG": 2.0
        },
        "achievement": {
          "energyPercent": 100.6,
          "proteinPercent": 101.1,
          "calciumPercent": 101.8,
          "ironPercent": 95.0,
          "saltPercent": 95.0
        }
      }
    ]
  },
  "approvedBy": "user-123",
  "approvedAt": "2025-03-05T15:30:00Z",
  "createdBy": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "createdAt": "2025-03-01T10:00:00Z",
  "updatedAt": "2025-03-05T15:30:00Z"
}
```

**エラー**: 404 Not Found
```json
{
  "error": "NOT_FOUND",
  "message": "献立が見つかりません"
}
```

---

#### POST /api/hoiku/menus

**概要**: 献立作成

**リクエスト**:
```json
{
  "facilityId": "123e4567-e89b-12d3-a456-426614174000",
  "date": "2025-03-10",
  "mealType": "lunch",
  "title": "春の彩り給食",
  "description": "たけのこご飯、鶏の照り焼き、菜の花のおひたし、お味噌汁",
  "items": [
    {
      "dishName": "たけのこご飯",
      "dishOrder": 1,
      "cookingMethod": "炊飯",
      "ingredients": [
        {
          "ingredientId": "ing-001",
          "amount": 50.0,
          "unit": "g"
        },
        {
          "ingredientId": "ing-002",
          "amount": 15.0,
          "unit": "g"
        }
      ]
    }
  ]
}
```

**レスポンス**: 201 Created
```http
Location: /api/hoiku/menus/aa11bb22-cc33-dd44-ee55-ff6677889900
```
```json
{
  "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
  "facilityId": "123e4567-e89b-12d3-a456-426614174000",
  "date": "2025-03-10",
  "mealType": "lunch",
  "title": "春の彩り給食",
  "status": "draft",
  "createdAt": "2025-03-01T10:00:00Z"
}
```

**エラー**: 400 Bad Request
```json
{
  "error": "VALIDATION_ERROR",
  "message": "入力内容に誤りがあります",
  "details": [
    {
      "field": "date",
      "message": "日付は必須です"
    }
  ]
}
```

**エラー**: 409 Conflict
```json
{
  "error": "DUPLICATE_MENU",
  "message": "同じ日付・食事区分の献立が既に存在します"
}
```

---

#### PUT /api/hoiku/menus/{id}

**概要**: 献立更新（全体）

**パスパラメータ**:
- `id`: 献立ID

**リクエスト**:
```json
{
  "date": "2025-03-10",
  "mealType": "lunch",
  "title": "春の彩り給食（更新版）",
  "description": "たけのこご飯、鶏の照り焼き、菜の花のおひたし、お味噌汁",
  "items": [...]
}
```

**レスポンス**: 200 OK
```json
{
  "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
  "title": "春の彩り給食（更新版）",
  "updatedAt": "2025-03-05T16:00:00Z"
}
```

---

#### PATCH /api/hoiku/menus/{id}

**概要**: 献立更新（部分）

**リクエスト**:
```json
{
  "title": "春の彩り給食（更新版）"
}
```

**レスポンス**: 200 OK

---

#### DELETE /api/hoiku/menus/{id}

**概要**: 献立削除

**レスポンス**: 204 No Content

**エラー**: 422 Unprocessable Entity
```json
{
  "error": "CANNOT_DELETE_APPROVED_MENU",
  "message": "承認済みの献立は削除できません"
}
```

---

#### POST /api/hoiku/menus/{id}/approve

**概要**: 献立承認

**リクエスト**:
```json
{
  "comment": "承認します"
}
```

**レスポンス**: 200 OK
```json
{
  "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
  "status": "approved",
  "approvedBy": "user-123",
  "approvedAt": "2025-03-05T15:30:00Z"
}
```

**エラー**: 422 Unprocessable Entity
```json
{
  "error": "INVALID_STATUS_TRANSITION",
  "message": "承認待ちステータスの献立のみ承認できます"
}
```

---

#### POST /api/hoiku/menus/{id}/publish

**概要**: 献立公開（保護者向け）

**レスポンス**: 200 OK
```json
{
  "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
  "status": "published",
  "publishedBy": "user-123",
  "publishedAt": "2025-03-06T10:00:00Z"
}
```

---

#### POST /api/hoiku/menus/{id}/calculate-nutrition

**概要**: 栄養計算実行

**リクエスト**:
```json
{
  "ageGroups": [
    {
      "ageGroupId": "age-001",
      "servings": 40
    },
    {
      "ageGroupId": "age-002",
      "servings": 20
    }
  ]
}
```

**レスポンス**: 200 OK
```json
{
  "results": [
    {
      "ageGroupId": "age-001",
      "ageGroupName": "3-5歳",
      "servings": 40,
      "energyKcal": 452.5,
      "proteinG": 18.2,
      "fatG": 12.5,
      "carbohydrateG": 68.3,
      "calciumMg": 285.0,
      "ironMg": 3.8,
      "saltEquivalentG": 1.9
    }
  ]
}
```

---

#### POST /api/hoiku/menus/{id}/duplicate

**概要**: 献立複製

**リクエスト**:
```json
{
  "targetDate": "2025-03-17",
  "copyItems": true
}
```

**レスポンス**: 201 Created
```json
{
  "id": "new-menu-id",
  "date": "2025-03-17",
  "status": "draft"
}
```

---

### 3. 食材管理 (Ingredients)

#### GET /api/hoiku/ingredients

**概要**: 食材一覧取得

**クエリパラメータ**:
- `level` (optional): system | organization | facility
- `organizationId` (optional): 組織ID
- `facilityId` (optional): 施設ID
- `category` (optional): 分類
- `allergens` (optional): アレルゲン（カンマ区切り）
- `isActive` (optional): 有効フラグ
- `page`, `size`, `sort`

**レスポンス**: 200 OK（ページネーション形式）
```json
{
  "content": [
    {
      "id": "ing-001",
      "level": "system",
      "code": "SYS-001",
      "name": "精白米",
      "nameKana": "セイハクマイ",
      "category": "穀類",
      "unit": "g",
      "wasteRate": 0.0,
      "energyKcal": 358.0,
      "proteinG": 6.1,
      "allergens": [],
      "isActive": true
    }
  ],
  "page": {...}
}
```

---

#### GET /api/hoiku/ingredients/{id}

**概要**: 食材詳細取得

**レスポンス**: 200 OK
```json
{
  "id": "ing-001",
  "level": "system",
  "parentIngredientId": null,
  "code": "SYS-001",
  "name": "精白米",
  "nameKana": "セイハクマイ",
  "category": "穀類",
  "unit": "g",
  "standardAmount": null,
  "wasteRate": 0.0,
  "energyKcal": 358.0,
  "proteinG": 6.1,
  "fatG": 0.9,
  "carbohydrateG": 77.6,
  "calciumMg": 5.0,
  "ironMg": 0.8,
  "vitaminAUg": 0.0,
  "vitaminB1Mg": 0.08,
  "vitaminB2Mg": 0.02,
  "vitaminCMg": 0.0,
  "dietaryFiberG": 0.5,
  "saltEquivalentG": 0.0,
  "allergens": [],
  "isSeasonal": false,
  "isActive": true,
  "createdAt": "2025-01-01T00:00:00Z"
}
```

---

#### POST /api/hoiku/ingredients

**概要**: 食材作成（組織・施設レベル）

**リクエスト**:
```json
{
  "level": "organization",
  "organizationId": "org-001",
  "parentIngredientId": "ing-001",
  "code": "ORG-SAK-001",
  "name": "有機栽培米",
  "category": "穀類",
  "unit": "g",
  "wasteRate": 0.0,
  "energyKcal": 360.0,
  "proteinG": 6.2
}
```

**レスポンス**: 201 Created

---

### 4. 帳票管理 (Reports)

#### POST /api/hoiku/reports/generate

**概要**: 帳票生成

**リクエスト**:
```json
{
  "facilityId": "facility-001",
  "templateId": "yokohama-menu-list",
  "targetYearMonth": "2025-03",
  "format": "pdf"
}
```

**レスポンス**: 200 OK
```json
{
  "reportId": "report-001",
  "fileName": "yokohama_menu_list_2025_03.pdf",
  "downloadUrl": "/api/hoiku/reports/report-001/download",
  "expiresAt": "2025-03-10T10:00:00Z"
}
```

---

#### GET /api/hoiku/reports/{id}/download

**概要**: 帳票ダウンロード

**レスポンス**: 200 OK (application/pdf)

---

## エラーレスポンス一覧

| エラーコード | HTTPステータス | 説明 |
|------------|--------------|------|
| VALIDATION_ERROR | 400 | バリデーションエラー |
| UNAUTHORIZED | 401 | 認証エラー |
| FORBIDDEN | 403 | 権限エラー |
| NOT_FOUND | 404 | リソース不存在 |
| DUPLICATE_MENU | 409 | 献立重複エラー |
| INVALID_STATUS_TRANSITION | 422 | ステータス遷移エラー |
| CANNOT_DELETE_APPROVED_MENU | 422 | 承認済み献立削除エラー |
| INTERNAL_SERVER_ERROR | 500 | サーバーエラー |

## レート制限

- **通常リクエスト**: 1000リクエスト/時間
- **帳票生成**: 100リクエスト/時間

レート制限超過時:
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 3600
```
```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "リクエスト上限に達しました。1時間後に再試行してください"
}
```
