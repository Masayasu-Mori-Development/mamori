# BFF（Backend for Frontend）アーキテクチャとデータフロー設計

## 概要

まもり保育ごはんは **BFF（Backend for Frontend）パターン** を採用し、
フロントエンドごとに最適化されたバックエンドAPIを提供します。

## BFF パターンの目的

### 従来の問題点
- 1つのバックエンドで複数のフロントエンド（Web/Mobile/Admin等）に対応
- フロントエンドごとに必要なデータ構造が異なる
- 不要なデータの送受信が発生
- セキュリティポリシーの混在（顧客用/運営用）

### BFF による解決
- **フロントエンドごとに専用のバックエンド**を配置
- **最適化されたAPI設計**（Over-fetching/Under-fetchingの解消）
- **セキュリティの完全分離**（顧客用/運営用）
- **独立したデプロイ**（影響範囲の限定）

## システム構成図

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend Layer                          │
├─────────────────────────────────┬───────────────────────────────┤
│  hoiku-frontend (Port 3000)     │  admin-frontend (Port 3001)   │
│  - 保育施設スタッフ向け          │  - 運営管理者向け              │
│  - 献立作成・栄養計算            │  - テナント管理                │
│  - 帳票出力                      │  - マスタ管理                  │
└─────────────────┬───────────────┴──────────────┬────────────────┘
                  │                              │
                  │ /api/hoiku/*                 │ /api/admin/*
                  │                              │
┌─────────────────▼───────────────┬──────────────▼────────────────┐
│         BFF Layer                                                │
├─────────────────────────────────┼───────────────────────────────┤
│  hoiku-backend (Port 8081)      │  admin-backend (Port 8082)    │
│  - 保育特化API                   │  - 運営管理API                 │
│  - 献立管理                      │  - テナント管理                │
│  - 栄養計算                      │  - 監査ログ                    │
│  - 帳票生成                      │  - マスタデータ管理             │
└─────────────────┬───────────────┴──────────────┬────────────────┘
                  │                              │
                  │ core サービス呼び出し         │
                  │                              │
┌─────────────────▼──────────────────────────────▼────────────────┐
│                    Core Services Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  core-backend (Port 8080)                                       │
│  - 認証・認可サービス                                            │
│  - ユーザー管理                                                  │
│  - テナント管理                                                  │
│  - 共通マスタ管理                                                │
└─────────────────────────────────────────────────────────────────┘
                  │
┌─────────────────▼─────────────────────────────────────────────┐
│                    Database Layer                             │
├───────────────────────────────────────────────────────────────┤
│  PostgreSQL                                                   │
│  - core schema (認証・共通)                                    │
│  - hoiku schema (保育特化)                                     │
│  - admin schema (運営管理)                                     │
└───────────────────────────────────────────────────────────────┘
```

## バックエンドの役割分担

### core-backend (Port 8080)

**役割**: 認証・共通機能の提供（内部サービス）

**主要API**:
- `POST /api/core/auth/login` - ログイン（JWT発行）
- `POST /api/core/auth/refresh` - トークンリフレッシュ
- `GET /api/core/users/{id}` - ユーザー情報取得
- `GET /api/core/tenants/{id}` - テナント情報取得
- `GET /api/core/facilities/{id}` - 施設情報取得

**特徴**:
- **直接的な外部公開なし**（BFF経由でのみアクセス）
- 認証・認可の中心
- マスタデータの管理

### hoiku-backend (Port 8081)

**役割**: 保育施設スタッフ向けAPI（hoiku-frontend専用）

**主要API**:
- `/api/hoiku/menus` - 献立管理
- `/api/hoiku/ingredients` - 食材管理
- `/api/hoiku/nutrition` - 栄養計算
- `/api/hoiku/reports` - 帳票生成

**特徴**:
- **hoiku-frontend のみアクセス可能**
- 献立・栄養計算に特化
- core-backend の認証サービスを利用
- テナント分離を強制

### admin-backend (Port 8082)

**役割**: 運営管理者向けAPI（admin-frontend専用）

**主要API**:
- `/api/admin/tenants` - テナント管理
- `/api/admin/users` - 運営ユーザー管理
- `/api/admin/audit-logs` - 監査ログ
- `/api/admin/master-data` - マスタデータ管理

**特徴**:
- **admin-frontend のみアクセス可能**
- 運営管理に特化
- **顧客データと完全分離**（admin.admin_users）
- MFA必須、IP制限

## リクエストフロー

### 1. 認証フロー（ログイン）

```
┌──────────────┐
│hoiku-frontend│
└──────┬───────┘
       │ 1. POST /api/hoiku/auth/login
       │    { email, password }
       ▼
┌──────────────┐
│hoiku-backend │
└──────┬───────┘
       │ 2. 内部呼び出し
       │    authService.login(email, password)
       ▼
┌──────────────┐
│ core-backend │
│  AuthService │
└──────┬───────┘
       │ 3. ユーザー検証
       │    - core.users テーブル参照
       │    - パスワードハッシュ検証
       │    - テナントID取得
       │    - ロール・権限取得
       │
       │ 4. JWT生成
       │    {
       │      sub: userId,
       │      tenantId: tenantId,
       │      type: "customer",
       │      roles: ["NUTRITIONIST"],
       │      exp: ...
       │    }
       ▼
┌──────────────┐
│hoiku-backend │
└──────┬───────┘
       │ 5. レスポンス
       │    {
       │      accessToken: "eyJhbGc...",
       │      refreshToken: "dGhpc2lz...",
       │      user: { ... }
       │    }
       ▼
┌──────────────┐
│hoiku-frontend│
└──────────────┘
```

**実装例（hoiku-backend）**:

```kotlin
@RestController
@RequestMapping("/api/hoiku/auth")
class HoikuAuthController(
    private val coreAuthService: CoreAuthService  // core-backend のサービスを呼び出し
) {

    @PostMapping("/login")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<LoginResponse> {
        // core-backend の認証サービスに委譲
        val authResult = coreAuthService.login(request.email, request.password)

        // JWT の type が "customer" であることを確認
        require(authResult.tokenType == "customer") {
            "Invalid token type for hoiku frontend"
        }

        return ResponseEntity.ok(LoginResponse.from(authResult))
    }
}
```

### 2. 通常APIリクエストフロー（献立作成）

```
┌──────────────┐
│hoiku-frontend│
└──────┬───────┘
       │ 1. POST /api/hoiku/menus
       │    Authorization: Bearer {JWT}
       │    X-Tenant-ID: {tenantId}
       │    { facilityId, date, mealType, ... }
       ▼
┌──────────────────────────────────────┐
│hoiku-backend                         │
│  Spring Security Filter Chain        │
└──────┬───────────────────────────────┘
       │ 2. JWT検証
       │    - JWTの署名検証
       │    - type: "customer" 確認
       │    - 有効期限確認
       │    - tenantId 抽出
       │
       │ 3. テナントコンテキスト設定
       │    TenantContext.setCurrentTenantId(tenantId)
       │
       ▼
┌──────────────┐
│  Controller  │
└──────┬───────┘
       │ 4. リクエスト受付
       │    @PostMapping("/api/hoiku/menus")
       │    fun createMenu(@RequestBody request)
       │
       ▼
┌──────────────┐
│   UseCase    │
└──────┬───────┘
       │ 5. ビジネスロジック実行
       │    - 施設の存在確認
       │    - 権限チェック（施設担当者か）
       │    - ドメインモデル生成
       │    - 永続化
       │
       ▼
┌──────────────┐
│  Repository  │
└──────┬───────┘
       │ 6. データベース保存
       │    INSERT INTO hoiku.menus (...)
       │    WHERE tenant_id = {currentTenantId}
       │
       ▼
┌──────────────┐
│  PostgreSQL  │
└──────────────┘
```

**実装例（hoiku-backend）**:

```kotlin
// 1. Security Filter
@Component
class JwtAuthenticationFilter(
    private val jwtService: JwtService,
    private val tenantContextService: TenantContextService
) : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val token = extractToken(request)
        if (token != null) {
            val claims = jwtService.validateToken(token)

            // type が "customer" であることを確認
            require(claims["type"] == "customer") {
                "Invalid token type"
            }

            // テナントコンテキストに設定
            val tenantId = UUID.fromString(claims["tenantId"] as String)
            tenantContextService.setCurrentTenantId(tenantId)

            // Spring Security の認証情報を設定
            val authentication = JwtAuthenticationToken(claims)
            SecurityContextHolder.getContext().authentication = authentication
        }

        filterChain.doFilter(request, response)
    }
}

// 2. Controller
@RestController
@RequestMapping("/api/hoiku/menus")
class MenuController(
    private val createMenuUseCase: CreateMenuUseCase
) {

    @PostMapping
    @PreAuthorize("hasPermission(#request.facilityId, 'menu', 'create')")
    fun createMenu(
        @Valid @RequestBody request: CreateMenuRequest
    ): ResponseEntity<MenuResponse> {
        val menu = createMenuUseCase.execute(request.toCommand())
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(MenuResponse.from(menu))
    }
}

// 3. UseCase
@Service
@Transactional
class CreateMenuUseCase(
    private val menuRepository: MenuRepository,
    private val facilityRepository: FacilityRepository,
    private val tenantContextService: TenantContextService
) {

    fun execute(command: CreateMenuCommand): Menu {
        val tenantId = tenantContextService.getCurrentTenantId()

        // 施設の存在確認＋テナント一致確認
        val facility = facilityRepository.findById(command.facilityId)
            ?: throw FacilityNotFoundException(command.facilityId)

        require(facility.tenantId == tenantId) {
            "Facility does not belong to current tenant"
        }

        // ドメインモデル生成（テナントIDは自動設定）
        val menu = Menu.create(
            facilityId = facility.id,
            date = command.date,
            mealType = command.mealType,
            title = command.title
        )

        return menuRepository.save(menu)
    }
}

// 4. Repository
@Repository
class MenuRepositoryImpl(
    private val jpaRepository: MenuJpaRepository,
    private val tenantContextService: TenantContextService
) : MenuRepository {

    override fun save(menu: Menu): Menu {
        // 保存時に tenantId を自動設定
        val tenantId = tenantContextService.getCurrentTenantId()
        if (menu.tenantId != tenantId) {
            throw IllegalStateException("Menu tenant ID mismatch")
        }
        return jpaRepository.save(menu)
    }
}
```

## テナント分離の実装

### 1. TenantContext（スレッドローカル）

```kotlin
object TenantContext {
    private val currentTenantId = ThreadLocal<UUID>()

    fun setCurrentTenantId(tenantId: UUID) {
        currentTenantId.set(tenantId)
    }

    fun getCurrentTenantId(): UUID {
        return currentTenantId.get()
            ?: throw IllegalStateException("Tenant ID not set in context")
    }

    fun clear() {
        currentTenantId.remove()
    }
}

@Component
class TenantContextService {
    fun setCurrentTenantId(tenantId: UUID) {
        TenantContext.setCurrentTenantId(tenantId)
    }

    fun getCurrentTenantId(): UUID {
        return TenantContext.getCurrentTenantId()
    }

    fun clear() {
        TenantContext.clear()
    }
}
```

### 2. JPA での自動フィルタリング

```kotlin
// Entity に @Where アノテーション
@Entity
@Table(schema = "hoiku", name = "menus")
@Where(clause = "tenant_id = current_setting('app.current_tenant_id')::uuid")
class Menu(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false, updatable = false)
    val tenantId: UUID = TenantContext.getCurrentTenantId(),

    // ... その他のフィールド
)

// または、Hibernate Filter を使用
@FilterDef(name = "tenantFilter", parameters = [ParamDef(name = "tenantId", type = "uuid")])
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
@Entity
class Menu { ... }

// セッションごとにフィルタを有効化
@Component
class TenantFilterAspect(
    private val entityManager: EntityManager,
    private val tenantContextService: TenantContextService
) {

    @Before("@annotation(org.springframework.transaction.annotation.Transactional)")
    fun enableTenantFilter() {
        val session = entityManager.unwrap(Session::class.java)
        session.enableFilter("tenantFilter")
            .setParameter("tenantId", tenantContextService.getCurrentTenantId())
    }
}
```

### 3. 保存時の自動設定

```kotlin
@Entity
class Menu(
    @Column(nullable = false, updatable = false)
    val tenantId: UUID = TenantContext.getCurrentTenantId(),  // 自動設定
    // ...
)

// または、@PrePersist で設定
@Entity
class Menu(
    @Column(nullable = false, updatable = false)
    var tenantId: UUID? = null,
    // ...
) {
    @PrePersist
    fun prePersist() {
        if (tenantId == null) {
            tenantId = TenantContext.getCurrentTenantId()
        }
    }
}
```

## エラーハンドリングフロー

### グローバル例外ハンドラ

```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(DomainException::class)
    fun handleDomainException(
        ex: DomainException,
        request: WebRequest
    ): ResponseEntity<ErrorResponse> {
        val status = when (ex) {
            is NotFoundException -> HttpStatus.NOT_FOUND
            is ValidationException -> HttpStatus.BAD_REQUEST
            is BusinessRuleViolationException -> HttpStatus.UNPROCESSABLE_ENTITY
            else -> HttpStatus.INTERNAL_SERVER_ERROR
        }

        val errorResponse = ErrorResponse(
            error = ex.errorCode,
            message = ex.message ?: "エラーが発生しました",
            timestamp = Instant.now().toString(),
            path = request.getDescription(false).removePrefix("uri=")
        )

        return ResponseEntity.status(status).body(errorResponse)
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(
        ex: MethodArgumentNotValidException
    ): ResponseEntity<ErrorResponse> {
        val fieldErrors = ex.bindingResult.fieldErrors.map {
            FieldError(
                field = it.field,
                message = it.defaultMessage ?: "Invalid value"
            )
        }

        val errorResponse = ErrorResponse(
            error = "VALIDATION_ERROR",
            message = "入力内容に誤りがあります",
            details = fieldErrors,
            timestamp = Instant.now().toString()
        )

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse)
    }
}
```

## まとめ

### BFF パターンの利点

1. **セキュリティの完全分離**
   - 顧客用（core.users）と運営用（admin.admin_users）が完全分離
   - JWT の type フィールドで明確に区別

2. **最適化されたAPI**
   - フロントエンドごとに必要なデータ構造を提供
   - 不要なデータ送信を削減

3. **独立したデプロイ**
   - hoiku-backend と admin-backend は独立してデプロイ可能
   - 影響範囲の限定

4. **明確な責務分離**
   - core-backend: 認証・共通機能
   - hoiku-backend: 保育特化機能
   - admin-backend: 運営管理機能

### 実装のポイント

1. **テナント分離の徹底**
   - 全クエリに tenant_id フィルタを適用
   - ThreadLocal で現在のテナントを管理

2. **JWT の type フィールド**
   - "customer" と "admin" を明確に区別
   - BFF ごとに異なる署名鍵を使用

3. **エラーハンドリングの統一**
   - グローバル例外ハンドラで一元管理
   - 統一されたエラーレスポンス形式
