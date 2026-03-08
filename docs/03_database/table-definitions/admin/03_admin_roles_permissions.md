# 運営管理ロール・パーミッション（簡易版）

## admin_roles (運営管理ロール)

運営管理者のロールは `admin.admin_users.admin_role` カラムで管理するため、
当初設計からこのテーブルは不要と判断。

admin_role_type ENUM で十分に対応可能:
- super_admin
- admin
- support
- analyst
- developer

## admin_permissions (運営管理パーミッション)

運営管理者の権限も `admin_role_type` で十分に管理可能なため、
別途パーミッションテーブルは作成しない。

### ロール別権限マトリックス

| 操作 | super_admin | admin | support | analyst | developer |
|-----|-------------|-------|---------|---------|-----------|
| テナント作成 | ◯ | ◯ | × | × | × |
| テナント編集 | ◯ | ◯ | △ | × | × |
| ユーザー管理 | ◯ | ◯ | × | × | × |
| マスタ管理 | ◯ | ◯ | × | × | △ |
| 監査ログ閲覧 | ◯ | ◯ | △ | ◯ | × |
| システム設定 | ◯ | △ | × | × | × |

## Spring Security 実装例

```kotlin
@PreAuthorize("hasRole('ADMIN_SUPER_ADMIN') or hasRole('ADMIN_ADMIN')")
fun createTenant(request: TenantCreateRequest): TenantResponse {
    // テナント作成ロジック
}

@Component
class AdminSecurityConfig {
    @Bean
    fun adminSecurityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .securityMatcher("/api/admin/**")
            .authorizeHttpRequests { auth ->
                auth
                    .requestMatchers("/api/admin/auth/**").permitAll()
                    .requestMatchers("/api/admin/tenants/**").hasAnyRole("ADMIN_SUPER_ADMIN", "ADMIN_ADMIN")
                    .requestMatchers("/api/admin/audit/**").hasAnyRole("ADMIN_SUPER_ADMIN", "ADMIN_ADMIN", "ADMIN_ANALYST")
                    .anyRequest().authenticated()
            }
        return http.build()
    }
}
```

## 備考

- シンプルな ENUM ベースの権限管理
- 必要に応じて将来的にテーブル化も検討可能
- 現状は5つのロールで十分に運用可能
