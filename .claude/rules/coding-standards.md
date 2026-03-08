---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.kt"
---

# コーディング規約

## 共通規約

- **インデント**: 2スペース（TypeScript/JavaScript/Kotlin共通）
- **改行コード**: LF
- **文字コード**: UTF-8
- **コメント**: 日本語で記述（APIドキュメントなど外部公開部分は英語）
- **命名規則**:
  - キャメルケース（変数、関数）
  - パスカルケース（クラス、コンポーネント）
  - スネークケース（定数、環境変数）

## フロントエンド（React + TypeScript）

### 基本方針

- **フレームワーク**: React 18以上
- **言語**: TypeScript（厳密なNull チェック有効）
- **状態管理**: Context API または Redux Toolkit
- **スタイリング**: CSS Modules または styled-components
- **テスト**: Jest + React Testing Library
- **Linter**: ESLint + Prettier

### コンポーネント設計

- Atomic Designパターンを推奨
- 関数コンポーネント + Hooks を使用
- propsの型定義は必須

```tsx
// ✅ Good
interface MenuCardProps {
  menuName: string;
  mealType: MealType;
  onEdit: (id: string) => void;
}

export const MenuCard: React.FC<MenuCardProps> = ({ menuName, mealType, onEdit }) => {
  return (
    <div className={styles.card}>
      <h3>{menuName}</h3>
      <span>{mealType}</span>
    </div>
  );
};

// ❌ Bad: 型定義なし
export const MenuCard = ({ menuName, mealType, onEdit }) => {
  // ...
};
```

### ファイル命名

- コンポーネント: `ComponentName.tsx`
- スタイル: `ComponentName.module.css`
- テスト: `ComponentName.test.tsx`
- カスタムフック: `useCustomHook.ts`

### Hooksの使用

```tsx
// ✅ Good: カスタムフックで再利用可能に
const useMenuData = (facilityId: string) => {
  const [menus, setMenus] = useState<Menu[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchMenus(facilityId).then(setMenus);
  }, [facilityId]);

  return { menus, loading };
};

// コンポーネントで使用
const MenuList = ({ facilityId }: Props) => {
  const { menus, loading } = useMenuData(facilityId);
  // ...
};
```

## バックエンド（Spring Boot + Kotlin）

### 基本方針

- **フレームワーク**: Spring Boot 3.x
- **言語**: Kotlin 1.9以上
- **ビルドツール**: Gradle（Kotlin DSL）
- **データベース**: PostgreSQL（AWS RDS）
- **ORM**: Spring Data JPA
- **認証**: Spring Security + JWT
- **API**: RESTful API（OpenAPI/Swagger仕様書生成）
- **テスト**: JUnit 5 + MockK

### レイヤードアーキテクチャ

```
Controller層 → Service層 → Repository層 → Domain層
```

#### Controller層

```kotlin
// ✅ Good
@RestController
@RequestMapping("/api/hoiku/menus")
class MenuController(
    private val menuService: MenuService
) {
    @GetMapping
    fun getMenus(
        @CurrentUser user: User,
        @RequestParam menuDate: LocalDate?
    ): ResponseEntity<List<MenuResponse>> {
        val menus = menuService.findByFacility(user.facilityId, menuDate)
        return ResponseEntity.ok(menus.map { it.toResponse() })
    }

    @PostMapping
    fun createMenu(
        @CurrentUser user: User,
        @Valid @RequestBody request: MenuRequest
    ): ResponseEntity<MenuResponse> {
        val menu = menuService.create(user, request)
        return ResponseEntity.status(HttpStatus.CREATED).body(menu.toResponse())
    }
}
```

#### Service層

```kotlin
// ✅ Good: インターフェースと実装を分離
interface MenuService {
    fun findByFacility(facilityId: UUID, menuDate: LocalDate?): List<Menu>
    fun create(user: User, request: MenuRequest): Menu
}

@Service
@Transactional
class MenuServiceImpl(
    private val menuRepository: MenuRepository,
    private val nutritionCalculationService: NutritionCalculationService
) : MenuService {

    override fun findByFacility(facilityId: UUID, menuDate: LocalDate?): List<Menu> {
        return if (menuDate != null) {
            menuRepository.findByFacilityIdAndMenuDate(facilityId, menuDate)
        } else {
            menuRepository.findByFacilityId(facilityId)
        }
    }

    override fun create(user: User, request: MenuRequest): Menu {
        val menu = Menu(
            id = UUID.randomUUID(),
            tenantId = user.tenantId,
            facilityId = user.facilityId,
            menuDate = request.menuDate,
            mealType = request.mealType,
            menuName = request.menuName,
            description = request.description,
            targetAgeGroup = request.targetAgeGroup,
            status = MenuStatus.DRAFT,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now(),
            createdBy = user.id,
            updatedBy = user.id
        )
        return menuRepository.save(menu)
    }
}
```

#### Repository層

```kotlin
// ✅ Good: Spring Data JPAのクエリメソッド
interface MenuRepository : JpaRepository<MenuEntity, UUID> {
    fun findByFacilityId(facilityId: UUID): List<MenuEntity>
    fun findByFacilityIdAndMenuDate(facilityId: UUID, menuDate: LocalDate): List<MenuEntity>
    fun findByTenantIdAndFacilityId(tenantId: UUID, facilityId: UUID): List<MenuEntity>
}
```

### 命名規則

- Controller: `*Controller.kt`
- Service: `*Service.kt`、実装クラス: `*ServiceImpl.kt`
- Repository: `*Repository.kt`
- Entity: `*Entity.kt`
- DTO: `*Request.kt`, `*Response.kt`

### Null安全性

```kotlin
// ✅ Good: Kotlinのnull安全性を活用
data class MenuRequest(
    val menuName: String,          // Non-null
    val description: String?,      // Nullable
    val menuDate: LocalDate
)

// ✅ Good: Safe call演算子
val description = menu.description?.trim()

// ✅ Good: Elvis演算子
val name = menu.menuName ?: "未設定"

// ❌ Bad: !! 演算子は極力避ける
val name = menu.menuName!!  // NullPointerExceptionのリスク
```

### データクラス

```kotlin
// ✅ Good: data classで簡潔に
data class Menu(
    val id: UUID,
    val menuName: String,
    val menuDate: LocalDate,
    val status: MenuStatus
)

// ✅ Good: copy()で不変性を保つ
val updatedMenu = menu.copy(status = MenuStatus.PUBLISHED)
```

## コメント規約

### 日本語コメント

```kotlin
// ✅ Good: ビジネスロジックの説明は日本語で
// 横浜市の栄養基準に基づいて献立を検証する
fun validateMenu(menu: Menu, standard: NutritionStandard): ValidationResult {
    // エネルギーが基準値を満たしているか確認
    if (menu.energyKcal < standard.energyKcalMin) {
        return ValidationResult.failure("エネルギーが不足しています")
    }
    // ...
}
```

### KDoc（Kotlinドキュメント）

```kotlin
/**
 * 献立の栄養価を計算する
 *
 * @param menu 献立
 * @param ingredients 食材リスト
 * @return 栄養計算結果
 * @throws IllegalArgumentException 食材が1つも含まれていない場合
 */
fun calculateNutrition(menu: Menu, ingredients: List<Ingredient>): NutritionResult {
    require(ingredients.isNotEmpty()) { "食材が1つも含まれていません" }
    // ...
}
```

## エラーハンドリング

### フロントエンド

```typescript
// ✅ Good: try-catchで適切にエラーハンドリング
const fetchMenus = async (facilityId: string) => {
  try {
    const response = await api.get(`/api/hoiku/menus?facilityId=${facilityId}`);
    return response.data;
  } catch (error) {
    if (error.response?.status === 401) {
      // 認証エラー
      router.push('/login');
    } else {
      // その他のエラー
      toast.error('献立の取得に失敗しました');
    }
    throw error;
  }
};
```

### バックエンド

```kotlin
// ✅ Good: カスタム例外を使用
class MenuNotFoundException(menuId: UUID) : RuntimeException("献立が見つかりません: $menuId")

// ✅ Good: @ControllerAdviceでグローバルエラーハンドリング
@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(MenuNotFoundException::class)
    fun handleMenuNotFound(e: MenuNotFoundException): ResponseEntity<ErrorResponse> {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse("NOT_FOUND", e.message ?: "リソースが見つかりません"))
    }
}
```
