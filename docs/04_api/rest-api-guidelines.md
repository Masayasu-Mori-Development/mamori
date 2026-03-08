# REST API 設計ガイドライン

## 概要

まもり保育ごはんの全バックエンド（core-backend, hoiku-backend, admin-backend）は、
統一された REST API 設計規則に従います。

## 基本方針

- **プロトコル**: HTTPS
- **データ形式**: JSON
- **文字エンコーディング**: UTF-8
- **日付形式**: ISO 8601 (YYYY-MM-DD, YYYY-MM-DDTHH:mm:ssZ)
- **API仕様**: OpenAPI 3.0 (Swagger)
- **認証**: JWT (Bearer Token)

## BFF（Backend for Frontend）構成

### エンドポイントプレフィックス

| バックエンド | プレフィックス | 対象フロントエンド | ポート |
|------------|-------------|-----------------|------|
| core-backend | `/api/core/*` | （認証・共通機能） | 8080 |
| hoiku-backend | `/api/hoiku/*` | hoiku-frontend | 8081 |
| admin-backend | `/api/admin/*` | admin-frontend | 8082 |

**重要**: フロントエンドは対応するバックエンドのみにアクセスします。
- hoiku-frontend → `/api/hoiku/*` のみ
- admin-frontend → `/api/admin/*` のみ

## エンドポイント設計規則

### 命名規則

#### リソース名
- **複数形の名詞**を使用: `/menus`, `/users`, `/facilities`
- **小文字＋ハイフン区切り**: `/menu-templates`, `/nutrition-standards`
- **日本語は使用しない**: ❌ `/献立`, ⭕ `/menus`

#### 階層構造
- **親子関係**を表現: `/facilities/{facilityId}/menus`
- **ネストは2階層まで**: ❌ `/organizations/{orgId}/facilities/{facilityId}/menus/{menuId}/items`

#### クエリパラメータ
- **フィルタリング**: `?status=approved&date=2025-03-01`
- **ソート**: `?sort=date,desc&sort=createdAt,asc`
- **ページネーション**: `?page=0&size=20`

### エンドポイント例

#### 基本的なCRUD

```
GET    /api/hoiku/menus                 # 献立一覧取得
GET    /api/hoiku/menus/{id}            # 献立詳細取得
POST   /api/hoiku/menus                 # 献立作成
PUT    /api/hoiku/menus/{id}            # 献立更新（全体）
PATCH  /api/hoiku/menus/{id}            # 献立更新（部分）
DELETE /api/hoiku/menus/{id}            # 献立削除
```

#### サブリソース

```
GET    /api/hoiku/menus/{menuId}/items                  # 献立明細一覧
POST   /api/hoiku/menus/{menuId}/items                  # 献立明細追加
DELETE /api/hoiku/menus/{menuId}/items/{itemId}         # 献立明細削除
```

#### アクション（非CRUD）

```
POST   /api/hoiku/menus/{id}/approve                    # 献立承認
POST   /api/hoiku/menus/{id}/publish                    # 献立公開
POST   /api/hoiku/menus/{id}/calculate-nutrition        # 栄養計算実行
POST   /api/hoiku/menus/{id}/duplicate                  # 献立複製
```

#### 一括操作

```
POST   /api/hoiku/menus/bulk-create                     # 一括作成
DELETE /api/hoiku/menus/bulk-delete                     # 一括削除
```

#### 検索・フィルタリング

```
GET    /api/hoiku/menus?facilityId={id}&date={date}     # 条件検索
GET    /api/hoiku/menus?status=approved&sort=date,desc  # フィルタ＋ソート
GET    /api/hoiku/ingredients?category=野菜類&allergens=卵 # 複合条件
```

## HTTPメソッドとステータスコード

### HTTPメソッドの使い分け

| メソッド | 用途 | 冪等性 | リクエストボディ | レスポンスボディ |
|---------|------|--------|----------------|----------------|
| GET | リソース取得 | ⭕ | ❌ | ⭕ |
| POST | リソース作成 | ❌ | ⭕ | ⭕ |
| PUT | リソース全体更新 | ⭕ | ⭕ | ⭕ |
| PATCH | リソース部分更新 | ❌ | ⭕ | ⭕ |
| DELETE | リソース削除 | ⭕ | ❌ | ❌ または最小限 |

### HTTPステータスコード

#### 成功レスポンス (2xx)

| コード | 意味 | 使用場面 |
|-------|------|---------|
| 200 OK | 成功 | GET, PUT, PATCH成功時 |
| 201 Created | 作成成功 | POST成功時 |
| 204 No Content | 成功（レスポンスなし） | DELETE成功時 |

#### クライアントエラー (4xx)

| コード | 意味 | 使用場面 |
|-------|------|---------|
| 400 Bad Request | 不正なリクエスト | バリデーションエラー |
| 401 Unauthorized | 認証エラー | JWT未送信、期限切れ |
| 403 Forbidden | 権限エラー | アクセス権限なし |
| 404 Not Found | リソース不存在 | 指定IDのリソースなし |
| 409 Conflict | 競合エラー | 重複登録、楽観ロック失敗 |
| 422 Unprocessable Entity | 処理不可 | ビジネスルール違反 |
| 429 Too Many Requests | レート制限 | API呼び出し制限超過 |

#### サーバーエラー (5xx)

| コード | 意味 | 使用場面 |
|-------|------|---------|
| 500 Internal Server Error | サーバーエラー | 予期しないエラー |
| 503 Service Unavailable | サービス利用不可 | メンテナンス中 |

## リクエスト形式

### リクエストヘッダー

```http
POST /api/hoiku/menus HTTP/1.1
Host: api.mamori.jp
Content-Type: application/json; charset=utf-8
Accept: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
X-Tenant-ID: 550e8400-e29b-41d4-a716-446655440000
```

**必須ヘッダー**:
- `Content-Type: application/json; charset=utf-8` (POST/PUT/PATCHの場合)
- `Authorization: Bearer {token}` (認証が必要なエンドポイント)
- `X-Tenant-ID: {tenantId}` (マルチテナント対応)

### リクエストボディ

```json
{
  "facilityId": "123e4567-e89b-12d3-a456-426614174000",
  "date": "2025-03-10",
  "mealType": "lunch",
  "title": "春の彩り給食",
  "description": "旬の食材を使った給食です",
  "items": [
    {
      "dishName": "たけのこご飯",
      "dishOrder": 1,
      "ingredients": [
        {
          "ingredientId": "aa11bb22-cc33-dd44-ee55-ff6677889900",
          "amount": 50.0,
          "unit": "g"
        }
      ]
    }
  ]
}
```

## レスポンス形式

### 成功レスポンス

#### 単一リソース取得

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

{
  "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
  "facilityId": "123e4567-e89b-12d3-a456-426614174000",
  "date": "2025-03-10",
  "mealType": "lunch",
  "title": "春の彩り給食",
  "status": "approved",
  "totalServings": 60,
  "createdAt": "2025-03-01T10:00:00Z",
  "updatedAt": "2025-03-05T15:30:00Z"
}
```

#### リソース作成

```http
HTTP/1.1 201 Created
Location: /api/hoiku/menus/aa11bb22-cc33-dd44-ee55-ff6677889900
Content-Type: application/json; charset=utf-8

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

#### リソース削除

```http
HTTP/1.1 204 No Content
```

### エラーレスポンス

#### 統一エラー形式

```json
{
  "error": "VALIDATION_ERROR",
  "message": "入力内容に誤りがあります",
  "details": [
    {
      "field": "date",
      "message": "日付は必須です"
    },
    {
      "field": "mealType",
      "message": "食事区分は lunch, snack, dinner のいずれかである必要があります"
    }
  ],
  "timestamp": "2025-03-01T10:00:00Z",
  "path": "/api/hoiku/menus"
}
```

#### Kotlin実装例

```kotlin
data class ErrorResponse(
    val error: String,
    val message: String,
    val details: List<FieldError>? = null,
    val timestamp: String = Instant.now().toString(),
    val path: String? = null
)

data class FieldError(
    val field: String,
    val message: String
)
```

#### エラーコード一覧

| エラーコード | HTTPステータス | 説明 |
|------------|--------------|------|
| VALIDATION_ERROR | 400 | バリデーションエラー |
| UNAUTHORIZED | 401 | 認証エラー |
| FORBIDDEN | 403 | 権限エラー |
| NOT_FOUND | 404 | リソース不存在 |
| CONFLICT | 409 | 重複エラー |
| BUSINESS_RULE_VIOLATION | 422 | ビジネスルール違反 |
| INTERNAL_SERVER_ERROR | 500 | サーバーエラー |

## ページネーション

### ページネーション方式

**オフセットベース**のページネーションを採用します。

### リクエスト

```http
GET /api/hoiku/menus?page=0&size=20&sort=date,desc&sort=createdAt,asc
```

**パラメータ**:
- `page`: ページ番号（0始まり）デフォルト: 0
- `size`: 1ページあたりの件数（デフォルト: 20, 最大: 100）
- `sort`: ソート条件（`{field},{direction}` 形式、複数指定可能）

### レスポンス

```json
{
  "content": [
    {
      "id": "aa11bb22-cc33-dd44-ee55-ff6677889900",
      "date": "2025-03-10",
      "title": "春の彩り給食",
      "status": "approved"
    }
  ],
  "page": {
    "number": 0,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8
  },
  "links": {
    "first": "/api/hoiku/menus?page=0&size=20",
    "prev": null,
    "self": "/api/hoiku/menus?page=0&size=20",
    "next": "/api/hoiku/menus?page=1&size=20",
    "last": "/api/hoiku/menus?page=7&size=20"
  }
}
```

### Kotlin実装例

```kotlin
data class PageResponse<T>(
    val content: List<T>,
    val page: PageInfo,
    val links: PageLinks
)

data class PageInfo(
    val number: Int,        // 現在のページ番号（0始まり）
    val size: Int,          // 1ページあたりの件数
    val totalElements: Long, // 全件数
    val totalPages: Int     // 総ページ数
)

data class PageLinks(
    val first: String,
    val prev: String?,
    val self: String,
    val next: String?,
    val last: String
)

// Spring Data JPA の Page を PageResponse に変換
fun <T, R> Page<T>.toPageResponse(
    mapper: (T) -> R,
    baseUrl: String
): PageResponse<R> {
    return PageResponse(
        content = this.content.map(mapper),
        page = PageInfo(
            number = this.number,
            size = this.size,
            totalElements = this.totalElements,
            totalPages = this.totalPages
        ),
        links = PageLinks(
            first = "$baseUrl?page=0&size=${this.size}",
            prev = if (this.hasPrevious()) "$baseUrl?page=${this.number - 1}&size=${this.size}" else null,
            self = "$baseUrl?page=${this.number}&size=${this.size}",
            next = if (this.hasNext()) "$baseUrl?page=${this.number + 1}&size=${this.size}" else null,
            last = "$baseUrl?page=${this.totalPages - 1}&size=${this.size}"
        )
    )
}
```

### Controller実装例

```kotlin
@GetMapping
fun getMenus(
    @RequestParam facilityId: UUID,
    @RequestParam(required = false) status: String?,
    @PageableDefault(size = 20, sort = ["date"], direction = Sort.Direction.DESC) pageable: Pageable
): ResponseEntity<PageResponse<MenuResponse>> {
    val menus = getMenusUseCase.execute(facilityId, status, pageable)
    val response = menus.toPageResponse(
        mapper = { MenuResponse.from(it) },
        baseUrl = "/api/hoiku/menus"
    )
    return ResponseEntity.ok(response)
}
```

## OpenAPI (Swagger) 設定

### 依存関係

```kotlin
// build.gradle.kts
dependencies {
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0")
}
```

### Swagger設定

```kotlin
@Configuration
class SwaggerConfig {

    @Bean
    fun openAPI(): OpenAPI {
        return OpenAPI()
            .info(
                Info()
                    .title("まもり保育ごはん Hoiku API")
                    .description("保育施設向け献立・栄養計算API")
                    .version("v1.0.0")
                    .contact(
                        Contact()
                            .name("まもりごはん運営")
                            .email("support@mamori.jp")
                    )
            )
            .addSecurityItem(SecurityRequirement().addList("Bearer Authentication"))
            .components(
                Components()
                    .addSecuritySchemes(
                        "Bearer Authentication",
                        SecurityScheme()
                            .type(SecurityScheme.Type.HTTP)
                            .scheme("bearer")
                            .bearerFormat("JWT")
                    )
            )
    }
}
```

### API ドキュメントアノテーション

```kotlin
@RestController
@RequestMapping("/api/hoiku/menus")
@Tag(name = "Menu", description = "献立管理API")
class MenuController(
    private val createMenuUseCase: CreateMenuUseCase
) {

    @Operation(
        summary = "献立作成",
        description = "新しい献立を作成します"
    )
    @ApiResponses(
        value = [
            ApiResponse(responseCode = "201", description = "作成成功"),
            ApiResponse(responseCode = "400", description = "バリデーションエラー"),
            ApiResponse(responseCode = "401", description = "認証エラー"),
            ApiResponse(responseCode = "403", description = "権限エラー")
        ]
    )
    @PostMapping
    fun createMenu(
        @Parameter(description = "献立作成リクエスト", required = true)
        @Valid @RequestBody request: CreateMenuRequest
    ): ResponseEntity<MenuResponse> {
        val menu = createMenuUseCase.execute(request.toCommand())
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(MenuResponse.from(menu))
    }
}
```

### Swagger UI アクセス

- **Swagger UI**: `http://localhost:8081/swagger-ui.html`
- **OpenAPI JSON**: `http://localhost:8081/v3/api-docs`

## バージョニング

### URIバージョニング（推奨）

```
/api/v1/hoiku/menus
/api/v2/hoiku/menus
```

### ヘッダーバージョニング

```http
Accept: application/vnd.mamori.v1+json
```

**現在**: v1のみのため、バージョンプレフィックスは省略
**将来**: 破壊的変更が必要な場合、v2を追加

## CORS設定

### 許可するオリジン

```kotlin
@Configuration
class CorsConfig : WebMvcConfigurer {

    override fun addCorsMappings(registry: CorsRegistry) {
        registry.addMapping("/api/**")
            .allowedOrigins(
                "http://localhost:3000",  // hoiku-frontend (dev)
                "http://localhost:3001",  // admin-frontend (dev)
                "https://app.mamori.jp",  // hoiku-frontend (prod)
                "https://admin.mamori.jp" // admin-frontend (prod)
            )
            .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600)
    }
}
```

## まとめ

### REST API 設計のベストプラクティス

1. **リソース指向**: 名詞ベースのエンドポイント
2. **HTTPメソッドの正しい使用**: GET/POST/PUT/PATCH/DELETE
3. **適切なステータスコード**: 200/201/204/400/404等
4. **統一されたエラーレスポンス**: エラーコード＋メッセージ＋詳細
5. **ページネーション**: 大量データの効率的な取得
6. **OpenAPI仕様**: 自動生成されたAPIドキュメント

### 実装チェックリスト

- [ ] エンドポイント命名規則に従っているか
- [ ] 適切なHTTPメソッドを使用しているか
- [ ] ステータスコードは正しいか
- [ ] エラーレスポンスは統一形式か
- [ ] ページネーション対応しているか
- [ ] Swaggerアノテーションを付与しているか
- [ ] CORS設定は適切か
- [ ] JWT認証を実装しているか
