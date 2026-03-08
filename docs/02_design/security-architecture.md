# セキュリティアーキテクチャ

## セキュリティ設計の基本方針

SaaSとして、以下のセキュリティ原則を遵守します：

1. **ゼロトラスト原則**: すべてのリクエストを検証
2. **最小権限の原則**: 必要最小限の権限のみ付与
3. **多層防御**: 複数のセキュリティレイヤーで保護
4. **データ分離**: テナント間のデータを完全に分離
5. **監査可能性**: すべての操作をログに記録

## 脅威モデル

### 主要な脅威

| 脅威 | 説明 | 対策 |
|------|------|------|
| **権限昇格攻撃** | 一般ユーザーが運営権限を取得 | ユーザーテーブル分離 |
| **クロステナント攻撃** | 他のテナントのデータにアクセス | tenant_id フィルタリング強制 |
| **SQLインジェクション** | SQL文を改ざんしてデータ窃取 | プリペアドステートメント必須 |
| **XSS攻撃** | スクリプト注入でセッション窃取 | 入力値サニタイズ |
| **CSRF攻撃** | 不正なリクエストを送信 | トークン検証 |
| **認証情報漏洩** | パスワード・トークンの漏洩 | ハッシュ化・暗号化 |
| **DoS攻撃** | サービス停止させる | レート制限・CloudFrontCDN |

## ユーザー分離アーキテクチャ

### ユーザータイプの完全分離

```
┌──────────────────────────────────────────────┐
│ 運営ユーザー（Admin Users）                    │
├──────────────────────────────────────────────┤
│ - admin.admin_users テーブル                  │
│ - admin-backend で認証                        │
│ - admin-frontend のみアクセス可能              │
│ - 全テナントのデータ閲覧可能（読み取り専用）     │
│ - IP制限 + MFA必須                           │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ 顧客ユーザー（Customer Users）                 │
├──────────────────────────────────────────────┤
│ - core.users テーブル                        │
│ - core-backend で認証                        │
│ - hoiku-frontend のみアクセス可能             │
│ - 自テナントのデータのみアクセス可能           │
│ - IP制限なし                                 │
└──────────────────────────────────────────────┘
```

### 認証フロー比較

#### 顧客ユーザーの認証

```
1. hoiku-frontend: POST /api/core/auth/login
   {
     "email": "user@facility.com",
     "password": "xxx"
   }

2. core-backend:
   - core.users テーブルで認証
   - JWT発行（type: "customer", tenant_id: "xxx"）

3. hoiku-frontend: JWT をlocalStorageに保存

4. 以降のリクエスト:
   Authorization: Bearer <customer-jwt>
   → hoiku-backend が検証
   → tenant_id で自動フィルタリング
```

#### 運営ユーザーの認証

```
1. admin-frontend: POST /api/admin/auth/login
   {
     "email": "admin@mamori.com",
     "password": "xxx"
   }

2. admin-backend:
   - admin.admin_users テーブルで認証
   - MFA検証（TOTP）

3. admin-backend:
   - MFA成功後、JWT発行（type: "admin", admin_role: "super_admin"）

4. admin-frontend: JWT をlocalStorageに保存

5. 以降のリクエスト:
   Authorization: Bearer <admin-jwt>
   → admin-backend が検証
   → admin_role で権限チェック
```

## JWT（JSON Web Token）設計

### JWT構造

```typescript
// 顧客ユーザーのJWT
interface CustomerJwtPayload {
  sub: string;                  // user.id (UUID)
  email: string;
  type: 'customer';             // 必須: ユーザータイプ
  tenant_id: string;            // テナントID
  organization_id: string;      // 組織ID
  role: string;                 // 'admin', 'manager', 'staff'
  iss: 'mamori-core-backend';
  exp: number;                  // 有効期限
  iat: number;                  // 発行日時
}

// 運営ユーザーのJWT
interface AdminJwtPayload {
  sub: string;                  // admin_user.id (UUID)
  email: string;
  type: 'admin';                // 必須: ユーザータイプ
  admin_role: string;           // 'super_admin', 'support', 'analyst'
  iss: 'mamori-admin-backend';
  exp: number;
  iat: number;
}
```

### JWT検証ロジック

```kotlin
// hoiku-backend のJWT検証
fun validateCustomerJwt(token: String): CustomerJwtPayload {
    val payload = Jwts.parserBuilder()
        .setSigningKey(secretKey)
        .build()
        .parseClaimsJws(token)
        .body

    // type が 'customer' であることを検証
    if (payload["type"] != "customer") {
        throw UnauthorizedException("Invalid token type")
    }

    // tenant_id が存在することを検証
    val tenantId = payload["tenant_id"] as? String
        ?: throw UnauthorizedException("Missing tenant_id")

    return CustomerJwtPayload(...)
}

// admin-backend のJWT検証
fun validateAdminJwt(token: String): AdminJwtPayload {
    val payload = Jwts.parserBuilder()
        .setSigningKey(adminSecretKey)  // 異なる秘密鍵
        .build()
        .parseClaimsJws(token)
        .body

    // type が 'admin' であることを検証
    if (payload["type"] != "admin") {
        throw UnauthorizedException("Invalid token type")
    }

    return AdminJwtPayload(...)
}
```

### JWT秘密鍵の管理

```yaml
# 環境変数で管理（AWS Secrets Managerから取得）
JWT_SECRET_KEY_CUSTOMER: <256-bit secret>
JWT_SECRET_KEY_ADMIN: <256-bit secret (異なる鍵)>
```

**重要**: 運営用と顧客用で**異なる秘密鍵**を使用する。

## テナントデータ分離

### マルチテナントフィルタリング

すべてのクエリに `tenant_id` フィルタを強制適用。

#### Spring Data JPAでの実装

```kotlin
// 悪い例（脆弱）
interface MenuRepository : JpaRepository<MenuEntity, UUID> {
    fun findAll(): List<MenuEntity>  // ❌ すべてのテナントのデータを取得
}

// 良い例（安全）
interface MenuRepository : JpaRepository<MenuEntity, UUID> {
    fun findByTenantId(tenantId: UUID): List<MenuEntity>  // ✅ tenant_id でフィルタ
}
```

#### @Where アノテーションでの強制（Hibernate）

```kotlin
@Entity
@Table(name = "menus", schema = "hoiku")
@Where(clause = "tenant_id = :tenantId")  // ← 常に適用
data class MenuEntity(
    @Id
    val id: UUID,
    val tenantId: UUID,
    val facilityId: UUID,
    ...
)
```

#### Spring Security Context での自動注入

```kotlin
@Service
class MenuService(
    private val menuRepository: MenuRepository
) {
    fun getMenus(): List<Menu> {
        // SecurityContextから自動的にtenant_idを取得
        val tenantId = SecurityContextHolder.getContext()
            .authentication
            .principal as CustomerUserDetails
            .tenantId

        return menuRepository.findByTenantId(tenantId)
    }
}
```

### Row Level Security（RLS）- PostgreSQL

将来的に、データベースレベルでのテナント分離を追加。

```sql
-- Row Level Security を有効化
ALTER TABLE hoiku.menus ENABLE ROW LEVEL SECURITY;

-- ポリシー作成: 自テナントのデータのみアクセス可能
CREATE POLICY tenant_isolation_policy ON hoiku.menus
    FOR ALL
    TO hoiku_backend
    USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- アプリケーションで接続時にセット
SET app.current_tenant_id = 'xxx-xxx-xxx-xxx';
```

## 認可（Authorization）設計

### 顧客ユーザーの役割

```sql
CREATE TABLE core.roles (
    id UUID PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 初期ロール
INSERT INTO core.roles (role_name, description, permissions) VALUES
('organization_admin', '組織管理者', '{
  "menus": ["create", "read", "update", "delete"],
  "users": ["create", "read", "update", "delete"],
  "facilities": ["create", "read", "update", "delete"],
  "reports": ["create", "read", "download"]
}'),
('facility_manager', '施設管理者', '{
  "menus": ["create", "read", "update", "delete"],
  "reports": ["create", "read", "download"]
}'),
('nutritionist', '栄養士', '{
  "menus": ["create", "read", "update"],
  "reports": ["create", "read", "download"]
}'),
('staff', '一般職員', '{
  "menus": ["read"],
  "reports": ["read"]
}');
```

### 権限チェック

```kotlin
// Controller での権限チェック
@PreAuthorize("hasPermission('menus', 'create')")
@PostMapping("/api/hoiku/menus")
fun createMenu(@RequestBody request: MenuRequest): MenuResponse {
    ...
}

// カスタム Permission Evaluator
@Component
class CustomPermissionEvaluator : PermissionEvaluator {
    override fun hasPermission(
        authentication: Authentication,
        targetDomainObject: Any?,
        permission: Any
    ): Boolean {
        val user = authentication.principal as CustomerUserDetails
        val resource = targetDomainObject as String
        val action = permission as String

        // ユーザーのロールから権限を取得
        val permissions = user.role.permissions as Map<String, List<String>>
        val allowedActions = permissions[resource] ?: emptyList()

        return allowedActions.contains(action)
    }
}
```

## 入力値検証（Validation）

### SQLインジェクション対策

```kotlin
// ❌ 悪い例: 文字列結合（SQLインジェクションの危険）
@Query("SELECT m FROM MenuEntity m WHERE m.menuName = '" + menuName + "'")
fun findByMenuNameUnsafe(menuName: String): List<MenuEntity>

// ✅ 良い例: プリペアドステートメント
@Query("SELECT m FROM MenuEntity m WHERE m.menuName = :menuName")
fun findByMenuName(@Param("menuName") menuName: String): List<MenuEntity>
```

### XSS対策

```kotlin
// フロントエンド（React）
import DOMPurify from 'dompurify';

// ユーザー入力をサニタイズ
const sanitizedInput = DOMPurify.sanitize(userInput);

// バックエンド（Kotlin）
import org.owasp.encoder.Encode

// HTML エスケープ
val sanitized = Encode.forHtml(userInput)
```

### バリデーション

```kotlin
// DTOでのバリデーション
data class MenuRequest(
    @field:NotBlank(message = "献立名は必須です")
    @field:Size(max = 255, message = "献立名は255文字以内です")
    val menuName: String,

    @field:NotNull(message = "献立日は必須です")
    @field:Future(message = "献立日は未来日付である必要があります")
    val menuDate: LocalDate,

    @field:Pattern(
        regexp = "^(breakfast|lunch|snack|dinner)$",
        message = "食事区分が不正です"
    )
    val mealType: String
)
```

## 暗号化

### パスワードハッシュ化

```kotlin
// BCryptでハッシュ化（Springデフォルト）
@Service
class PasswordService {
    private val encoder = BCryptPasswordEncoder(12)  // strength: 12

    fun hashPassword(plainPassword: String): String {
        return encoder.encode(plainPassword)
    }

    fun verifyPassword(plainPassword: String, hashedPassword: String): Boolean {
        return encoder.matches(plainPassword, hashedPassword)
    }
}
```

### データベース暗号化

```yaml
# RDS 設定
Encrypted: true
KmsKeyId: arn:aws:kms:ap-northeast-1:xxx:key/xxx

# バックアップも暗号化
BackupEncryption: true
```

### 通信の暗号化

```yaml
# HTTPS のみ許可（HTTP → HTTPS リダイレクト）
CloudFront:
  ViewerProtocolPolicy: redirect-to-https
  MinimumProtocolVersion: TLSv1.2

ALB:
  Protocol: HTTPS
  SslPolicy: ELBSecurityPolicy-TLS-1-2-2017-01
```

## レート制限

### APIレート制限

```kotlin
// Spring Boot + Bucket4j
@Service
class RateLimitService {
    private val cache = ConcurrentHashMap<String, Bucket>()

    fun resolveBucket(userId: String): Bucket {
        return cache.computeIfAbsent(userId) {
            Bucket.builder()
                .addLimit(
                    Bandwidth.classic(
                        100,                              // 100リクエスト
                        Refill.intervally(100, Duration.ofMinutes(1))
                    )
                )
                .build()
        }
    }
}

// Controller でのレート制限チェック
@PostMapping("/api/hoiku/menus")
fun createMenu(@CurrentUser user: User, @RequestBody request: MenuRequest): MenuResponse {
    val bucket = rateLimitService.resolveBucket(user.id.toString())
    if (!bucket.tryConsume(1)) {
        throw RateLimitExceededException("リクエスト回数の上限を超えました")
    }
    ...
}
```

### ログイン試行回数制限

```kotlin
// 5回失敗でアカウントロック（30分）
@Service
class LoginAttemptService {
    private val attemptsCache = CacheBuilder.newBuilder()
        .expireAfterWrite(30, TimeUnit.MINUTES)
        .build<String, Int>()

    fun loginFailed(email: String) {
        val attempts = attemptsCache.getIfPresent(email) ?: 0
        attemptsCache.put(email, attempts + 1)
    }

    fun isBlocked(email: String): Boolean {
        val attempts = attemptsCache.getIfPresent(email) ?: 0
        return attempts >= 5
    }
}
```

## 監査ログ

### ログ記録対象

| 対象 | 記録内容 |
|------|---------|
| **認証** | ログイン成功/失敗、ログアウト |
| **データ作成** | 献立作成、食材追加、ユーザー作成 |
| **データ変更** | 献立編集、設定変更 |
| **データ削除** | 献立削除、ユーザー削除 |
| **権限変更** | ロール変更、権限付与 |
| **データ閲覧**（運営のみ） | 他テナントデータの閲覧 |
| **エクスポート** | PDF生成、CSVダウンロード |

### ログ構造

```sql
CREATE TABLE core.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES core.users(id),
    tenant_id UUID,
    action VARCHAR(100) NOT NULL,           -- 'login', 'create_menu', 'delete_user'
    resource_type VARCHAR(50),              -- 'menu', 'user', 'facility'
    resource_id UUID,
    old_value JSONB,                        -- 変更前の値
    new_value JSONB,                        -- 変更後の値
    request_ip INET NOT NULL,
    user_agent TEXT,
    request_method VARCHAR(10),
    request_path TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_audit_logs_user_id ON core.audit_logs(user_id);
CREATE INDEX idx_audit_logs_tenant_id ON core.audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_created_at ON core.audit_logs(created_at DESC);
```

### ログ記録の実装

```kotlin
@Aspect
@Component
class AuditLogAspect(
    private val auditLogRepository: AuditLogRepository,
    private val request: HttpServletRequest
) {
    @AfterReturning("@annotation(Audited)")
    fun logAuditEvent(joinPoint: ProceedingJoinPoint) {
        val user = SecurityContextHolder.getContext()
            .authentication.principal as UserDetails

        val auditLog = AuditLog(
            userId = user.id,
            tenantId = user.tenantId,
            action = joinPoint.signature.name,
            requestIp = request.remoteAddr,
            userAgent = request.getHeader("User-Agent"),
            requestMethod = request.method,
            requestPath = request.requestURI,
            createdAt = LocalDateTime.now()
        )

        auditLogRepository.save(auditLog)
    }
}

// 使用例
@Audited
@PostMapping("/api/hoiku/menus")
fun createMenu(@RequestBody request: MenuRequest): MenuResponse {
    ...
}
```

## セキュリティテスト

### 定期的に実施するテスト

1. **ペネトレーションテスト**: 外部専門家による侵入テスト
2. **脆弱性スキャン**: OWASP ZAP、Burp Suiteでの自動スキャン
3. **依存関係チェック**: Snyk、Dependabotで脆弱性検知
4. **コードレビュー**: セキュリティ観点でのコードレビュー

### セキュリティチェックリスト

- [ ] 運営ユーザーと顧客ユーザーのテーブル分離
- [ ] JWT に type フィールドを含める
- [ ] tenant_id フィルタリング強制
- [ ] プリペアドステートメント使用
- [ ] 入力値バリデーション
- [ ] XSS対策（エスケープ処理）
- [ ] CSRF対策（トークン検証）
- [ ] パスワードハッシュ化（BCrypt）
- [ ] HTTPS通信のみ
- [ ] レート制限実装
- [ ] 監査ログ記録
- [ ] MFA実装（運営ユーザー）
- [ ] IP制限（運営管理画面）
- [ ] セキュリティヘッダー設定

## セキュリティヘッダー

```kotlin
// Spring Security での設定
http.headers { headers ->
    headers
        .contentSecurityPolicy {
            it.policyDirectives("default-src 'self'; script-src 'self'")
        }
        .httpStrictTransportSecurity {
            it.maxAgeInSeconds(31536000)
            it.includeSubDomains(true)
        }
        .frameOptions { it.deny() }
        .xssProtection { it.enable() }
}
```

## インシデント対応

### インシデント対応フロー

1. **検知**: 監視アラート、ユーザー報告
2. **初動対応**: 被害範囲の特定、該当機能の停止
3. **調査**: ログ分析、原因特定
4. **復旧**: 脆弱性修正、サービス再開
5. **事後対応**: ポストモーテム作成、再発防止策

### 緊急連絡先

- セキュリティ責任者: security@mamori.com
- インシデント報告: incident@mamori.com

## 参考資料

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [AWS セキュリティのベストプラクティス](https://aws.amazon.com/jp/architecture/security-identity-compliance/)
