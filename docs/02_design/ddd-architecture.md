# DDD アーキテクチャ設計

## 概要

まもり保育ごはんのバックエンド（core-backend, hoiku-backend, admin-backend）は、
**ドメイン駆動設計（DDD）** のアーキテクチャパターンを採用します。

## レイヤー構成

### 1. Presentation層（プレゼンテーション層）

**責務**: 外部からのリクエストを受け取り、Application層に委譲し、レスポンスを返す。

**構成要素**:
- **Controller**: REST APIエンドポイントの定義
- **DTO (Data Transfer Object)**: リクエスト/レスポンスのデータ構造
- **Validator**: 入力バリデーション

**実装場所**:
```
src/main/kotlin/com/mamori/{module}/controller/
src/main/kotlin/com/mamori/{module}/dto/
```

**実装例**:
```kotlin
@RestController
@RequestMapping("/api/hoiku/menus")
class MenuController(
    private val createMenuUseCase: CreateMenuUseCase,
    private val getMenuUseCase: GetMenuUseCase
) {

    @PostMapping
    fun createMenu(
        @Valid @RequestBody request: CreateMenuRequest
    ): ResponseEntity<MenuResponse> {
        val menu = createMenuUseCase.execute(request.toCommand())
        return ResponseEntity.ok(MenuResponse.from(menu))
    }

    @GetMapping("/{id}")
    fun getMenu(@PathVariable id: UUID): ResponseEntity<MenuResponse> {
        val menu = getMenuUseCase.execute(id)
        return ResponseEntity.ok(MenuResponse.from(menu))
    }
}
```

### 2. Application層（アプリケーション層）

**責務**: ユースケースの実装。ドメインロジックを組み合わせてビジネスフローを実現。

**構成要素**:
- **UseCase / ApplicationService**: ビジネスユースケースの実装
- **Command**: ユースケースへの入力パラメータ
- **Query**: 読み取り専用クエリ（CQRS）

**実装場所**:
```
src/main/kotlin/com/mamori/{module}/application/usecase/
src/main/kotlin/com/mamori/{module}/application/command/
src/main/kotlin/com/mamori/{module}/application/query/
```

**実装例**:
```kotlin
@Service
@Transactional
class CreateMenuUseCase(
    private val menuRepository: MenuRepository,
    private val facilityRepository: FacilityRepository,
    private val tenantContextService: TenantContextService
) {

    fun execute(command: CreateMenuCommand): Menu {
        // 1. テナントコンテキストの取得
        val tenantId = tenantContextService.getCurrentTenantId()

        // 2. 施設の存在確認
        val facility = facilityRepository.findById(command.facilityId)
            ?: throw FacilityNotFoundException(command.facilityId)

        // 3. ドメインモデルの生成
        val menu = Menu.create(
            facilityId = facility.id,
            date = command.date,
            mealType = command.mealType,
            title = command.title
        )

        // 4. 永続化
        return menuRepository.save(menu)
    }
}

data class CreateMenuCommand(
    val facilityId: UUID,
    val date: LocalDate,
    val mealType: MealType,
    val title: String
)
```

### 3. Domain層（ドメイン層）

**責務**: ビジネスルールとドメインロジックの実装。システムの核心部分。

**構成要素**:

#### 3.1 Entity（エンティティ）
- ライフサイクルを持つドメインオブジェクト
- 一意の識別子（ID）を持つ
- ビジネスロジックをカプセル化

```kotlin
@Entity
@Table(schema = "hoiku", name = "menus")
class Menu(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false)
    val tenantId: UUID,

    @Column(nullable = false)
    val facilityId: UUID,

    @Column(nullable = false)
    val date: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var mealType: MealType,

    @Column
    var title: String?,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: MenuStatus = MenuStatus.DRAFT,

    @OneToMany(mappedBy = "menu", cascade = [CascadeType.ALL], orphanRemoval = true)
    private val _items: MutableList<MenuItem> = mutableListOf()
) {
    val items: List<MenuItem> get() = _items.toList()

    companion object {
        fun create(
            facilityId: UUID,
            date: LocalDate,
            mealType: MealType,
            title: String?
        ): Menu {
            return Menu(
                tenantId = TenantContext.getCurrentTenantId(),
                facilityId = facilityId,
                date = date,
                mealType = mealType,
                title = title
            )
        }
    }

    // ドメインロジック
    fun addItem(dishName: String, dishOrder: Int): MenuItem {
        val item = MenuItem(
            menuId = this.id,
            tenantId = this.tenantId,
            dishName = dishName,
            dishOrder = dishOrder
        )
        _items.add(item)
        return item
    }

    fun approve(approvedBy: UUID) {
        require(this.status == MenuStatus.PENDING) {
            "承認待ちステータスの献立のみ承認できます"
        }
        this.status = MenuStatus.APPROVED
    }

    fun publish(publishedBy: UUID) {
        require(this.status == MenuStatus.APPROVED) {
            "承認済みステータスの献立のみ公開できます"
        }
        this.status = MenuStatus.PUBLISHED
    }
}
```

#### 3.2 Value Object（値オブジェクト）
- 識別子を持たない不変オブジェクト
- 等価性は属性値で判断

```kotlin
@Embeddable
data class Address(
    @Column(name = "postal_code")
    val postalCode: String,

    @Column(name = "prefecture", nullable = false)
    val prefecture: String,

    @Column(name = "city", nullable = false)
    val city: String,

    @Column(name = "address_line1", nullable = false)
    val addressLine1: String,

    @Column(name = "address_line2")
    val addressLine2: String?
) {
    init {
        require(prefecture.isNotBlank()) { "都道府県は必須です" }
        require(city.isNotBlank()) { "市区町村は必須です" }
        require(addressLine1.isNotBlank()) { "住所1は必須です" }
    }

    fun fullAddress(): String {
        return "$prefecture$city$addressLine1${addressLine2 ?: ""}"
    }
}

// Email Value Object
@Embeddable
data class Email(
    @Column(nullable = false)
    val value: String
) {
    init {
        require(value.matches(EMAIL_REGEX)) {
            "無効なメールアドレス形式です"
        }
    }

    companion object {
        private val EMAIL_REGEX = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$".toRegex()
    }
}
```

#### 3.3 Aggregate（集約）
- 関連するエンティティとValue Objectのまとまり
- 集約ルート（Aggregate Root）が外部からのアクセスを制御

```kotlin
// Menu が集約ルート、MenuItem が集約内のエンティティ
class Menu {  // Aggregate Root
    @OneToMany(mappedBy = "menu", cascade = [CascadeType.ALL], orphanRemoval = true)
    private val _items: MutableList<MenuItem> = mutableListOf()

    // 集約ルート経由でのみ MenuItem を操作可能
    fun addItem(dishName: String, dishOrder: Int): MenuItem {
        val item = MenuItem(...)
        _items.add(item)
        return item
    }

    fun removeItem(itemId: UUID) {
        _items.removeIf { it.id == itemId }
    }
}

// MenuItem は Menu 集約の一部
@Entity
class MenuItem(
    @Id
    val id: UUID = UUID.randomUUID(),
    val menuId: UUID,  // 親集約への参照
    val dishName: String,
    val dishOrder: Int
) {
    // MenuItem は Menu 経由でのみ操作される
}
```

#### 3.4 Domain Service（ドメインサービス）
- 複数のエンティティにまたがるビジネスロジック
- エンティティに属さないドメインロジック

```kotlin
@Service
class NutritionCalculationService(
    private val ingredientRepository: IngredientRepository
) {
    /**
     * 献立の栄養計算を実行
     * 複数のエンティティ（Menu, MenuItem, Ingredient）にまたがるロジック
     */
    fun calculate(menu: Menu, ageGroup: AgeGroup, servings: Int): NutritionResult {
        var totalEnergy = BigDecimal.ZERO
        var totalProtein = BigDecimal.ZERO
        var totalFat = BigDecimal.ZERO
        var totalCarbohydrate = BigDecimal.ZERO

        menu.items.forEach { item ->
            item.ingredients.forEach { menuIngredient ->
                val ingredient = ingredientRepository.findById(menuIngredient.ingredientId)
                    ?: throw IngredientNotFoundException(menuIngredient.ingredientId)

                // 廃棄率を考慮した正味量
                val netAmount = menuIngredient.amount * (1 - ingredient.wasteRate / 100)

                // 100gあたりの栄養成分から実際の量を計算
                totalEnergy += ingredient.energyKcal * netAmount / 100
                totalProtein += ingredient.proteinG * netAmount / 100
                totalFat += ingredient.fatG * netAmount / 100
                totalCarbohydrate += ingredient.carbohydrateG * netAmount / 100
            }
        }

        // 1人分の栄養量
        return NutritionResult(
            energyKcal = totalEnergy / servings.toBigDecimal(),
            proteinG = totalProtein / servings.toBigDecimal(),
            fatG = totalFat / servings.toBigDecimal(),
            carbohydrateG = totalCarbohydrate / servings.toBigDecimal()
        )
    }
}

data class NutritionResult(
    val energyKcal: BigDecimal,
    val proteinG: BigDecimal,
    val fatG: BigDecimal,
    val carbohydrateG: BigDecimal
)
```

#### 3.5 Repository Interface（リポジトリインターフェース）
- ドメイン層でインターフェースを定義
- 永続化の詳細はInfrastructure層で実装

```kotlin
interface MenuRepository {
    fun findById(id: UUID): Menu?
    fun findByFacilityIdAndDate(facilityId: UUID, date: LocalDate): List<Menu>
    fun save(menu: Menu): Menu
    fun delete(menu: Menu)
}
```

**実装場所**:
```
src/main/kotlin/com/mamori/{module}/domain/model/      # Entity, Value Object
src/main/kotlin/com/mamori/{module}/domain/service/    # Domain Service
src/main/kotlin/com/mamori/{module}/domain/repository/ # Repository Interface
```

### 4. Infrastructure層（インフラストラクチャ層）

**責務**: 技術的な実装詳細。データベース、外部API、メール送信など。

**構成要素**:
- **Repository実装**: JPA, JDBC等を使った永続化
- **外部API連携**: 外部サービスとの通信
- **Config**: Spring Boot設定

**実装場所**:
```
src/main/kotlin/com/mamori/{module}/infrastructure/repository/
src/main/kotlin/com/mamori/{module}/infrastructure/external/
src/main/kotlin/com/mamori/{module}/config/
```

**実装例**:
```kotlin
@Repository
class MenuRepositoryImpl(
    private val jpaRepository: MenuJpaRepository
) : MenuRepository {

    override fun findById(id: UUID): Menu? {
        return jpaRepository.findById(id).orElse(null)
    }

    override fun findByFacilityIdAndDate(facilityId: UUID, date: LocalDate): List<Menu> {
        return jpaRepository.findByFacilityIdAndDate(facilityId, date)
    }

    override fun save(menu: Menu): Menu {
        return jpaRepository.save(menu)
    }

    override fun delete(menu: Menu) {
        jpaRepository.delete(menu)
    }
}

interface MenuJpaRepository : JpaRepository<Menu, UUID> {
    fun findByFacilityIdAndDate(facilityId: UUID, date: LocalDate): List<Menu>
}
```

## ディレクトリ構造

### hoiku-backend の例

```
hoiku-backend/
└── src/main/kotlin/com/mamori/hoiku/
    ├── controller/                 # Presentation層
    │   ├── MenuController.kt
    │   ├── IngredientController.kt
    │   └── NutritionController.kt
    │
    ├── dto/                        # Presentation層
    │   ├── request/
    │   │   ├── CreateMenuRequest.kt
    │   │   └── UpdateMenuRequest.kt
    │   └── response/
    │       ├── MenuResponse.kt
    │       └── MenuListResponse.kt
    │
    ├── application/                # Application層
    │   ├── usecase/
    │   │   ├── CreateMenuUseCase.kt
    │   │   ├── GetMenuUseCase.kt
    │   │   └── ApproveMenuUseCase.kt
    │   ├── command/
    │   │   ├── CreateMenuCommand.kt
    │   │   └── ApproveMenuCommand.kt
    │   └── query/
    │       └── MenuQueryService.kt
    │
    ├── domain/                     # Domain層
    │   ├── model/
    │   │   ├── menu/
    │   │   │   ├── Menu.kt         # Aggregate Root
    │   │   │   ├── MenuItem.kt     # Entity
    │   │   │   ├── MenuStatus.kt   # Enum
    │   │   │   └── MealType.kt     # Enum
    │   │   └── ingredient/
    │   │       ├── Ingredient.kt
    │   │       └── IngredientLevel.kt
    │   ├── service/
    │   │   ├── NutritionCalculationService.kt
    │   │   └── MenuTemplateDistributionService.kt
    │   └── repository/
    │       ├── MenuRepository.kt           # Interface
    │       ├── IngredientRepository.kt     # Interface
    │       └── NutritionStandardRepository.kt
    │
    ├── infrastructure/             # Infrastructure層
    │   ├── repository/
    │   │   ├── MenuRepositoryImpl.kt
    │   │   ├── MenuJpaRepository.kt
    │   │   ├── IngredientRepositoryImpl.kt
    │   │   └── IngredientJpaRepository.kt
    │   └── external/
    │       └── PdfGenerationService.kt
    │
    ├── config/                     # 設定
    │   ├── SwaggerConfig.kt
    │   ├── SecurityConfig.kt
    │   └── JpaConfig.kt
    │
    └── HoikuApplication.kt
```

## 依存関係のルール

### 依存の方向

```
Presentation層 → Application層 → Domain層 ← Infrastructure層
```

**重要**:
- Domain層は他のどの層にも依存しない（依存性逆転の原則）
- Repository の実装は Infrastructure層だが、インターフェースは Domain層
- Application層は Domain層に依存するが、Infrastructure層には依存しない

### 依存性注入（DI）

```kotlin
// Application層のUseCaseは、Domain層のRepositoryインターフェースに依存
@Service
class CreateMenuUseCase(
    private val menuRepository: MenuRepository  // Interface（Domain層）
) {
    fun execute(command: CreateMenuCommand): Menu {
        val menu = Menu.create(...)
        return menuRepository.save(menu)  // 実装はInfrastructure層
    }
}

// Spring Bootが自動的にInfrastructure層の実装を注入
@Repository
class MenuRepositoryImpl : MenuRepository {
    // 実装
}
```

## トランザクション管理

### 基本方針
- **Application層（UseCase）でトランザクション境界を定義**
- `@Transactional` アノテーションを使用

```kotlin
@Service
@Transactional
class CreateMenuUseCase(
    private val menuRepository: MenuRepository,
    private val nutritionCalculationService: NutritionCalculationService
) {
    fun execute(command: CreateMenuCommand): Menu {
        // このメソッド全体が1つのトランザクション
        val menu = Menu.create(...)
        val savedMenu = menuRepository.save(menu)

        // 栄養計算も同一トランザクション内
        nutritionCalculationService.calculate(savedMenu, ...)

        return savedMenu
    }
}
```

### 読み取り専用トランザクション

```kotlin
@Service
@Transactional(readOnly = true)
class GetMenuUseCase(
    private val menuRepository: MenuRepository
) {
    fun execute(id: UUID): Menu {
        return menuRepository.findById(id)
            ?: throw MenuNotFoundException(id)
    }
}
```

## エラーハンドリング

### ドメイン例外

```kotlin
// Domain層で定義
sealed class DomainException(message: String) : RuntimeException(message)

class MenuNotFoundException(id: UUID) : DomainException("献立が見つかりません: $id")
class InvalidMenuStatusException(message: String) : DomainException(message)
class FacilityNotFoundException(id: UUID) : DomainException("施設が見つかりません: $id")
```

### グローバル例外ハンドラ

```kotlin
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(MenuNotFoundException::class)
    fun handleMenuNotFound(ex: MenuNotFoundException): ResponseEntity<ErrorResponse> {
        return ResponseEntity
            .status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse(
                error = "NOT_FOUND",
                message = ex.message ?: "リソースが見つかりません"
            ))
    }

    @ExceptionHandler(InvalidMenuStatusException::class)
    fun handleInvalidMenuStatus(ex: InvalidMenuStatusException): ResponseEntity<ErrorResponse> {
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(ErrorResponse(
                error = "INVALID_STATUS",
                message = ex.message ?: "不正なステータスです"
            ))
    }
}
```

## DTO vs Entity の使い分け

### 基本原則
- **外部との境界（Controller）では DTO を使用**
- **内部（Application, Domain）では Entity を使用**

### DTO → Entity 変換（Mapper）

```kotlin
// Request DTO
data class CreateMenuRequest(
    val facilityId: UUID,
    val date: String,  // ISO 8601形式
    val mealType: String,
    val title: String?
) {
    fun toCommand(): CreateMenuCommand {
        return CreateMenuCommand(
            facilityId = this.facilityId,
            date = LocalDate.parse(this.date),
            mealType = MealType.valueOf(this.mealType),
            title = this.title
        )
    }
}

// Response DTO
data class MenuResponse(
    val id: UUID,
    val facilityId: UUID,
    val date: String,
    val mealType: String,
    val title: String?,
    val status: String,
    val items: List<MenuItemResponse>
) {
    companion object {
        fun from(menu: Menu): MenuResponse {
            return MenuResponse(
                id = menu.id,
                facilityId = menu.facilityId,
                date = menu.date.toString(),
                mealType = menu.mealType.name,
                title = menu.title,
                status = menu.status.name,
                items = menu.items.map { MenuItemResponse.from(it) }
            )
        }
    }
}
```

## まとめ

### DDD の利点
1. **ビジネスロジックの集中化**: Domain層にロジックが集約される
2. **テストのしやすさ**: Domain層は純粋なKotlinコードでテスト可能
3. **変更に強い**: ビジネスルール変更時、Domain層のみ修正すれば良い
4. **保守性の向上**: 責務が明確で理解しやすい

### 実装時の注意点
1. Domain層に外部依存（Spring, JPA等）を持ち込まない
2. Entity には必要最小限のアノテーションのみ（`@Entity`, `@Id` 等）
3. ビジネスルールは必ずDomain層に実装
4. トランザクション境界はApplication層で管理
