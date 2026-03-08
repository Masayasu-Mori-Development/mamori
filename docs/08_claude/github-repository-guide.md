# GitHubリポジトリ構成ガイド

## リポジトリ構成

### モノレポ（推奨）

**リポジトリ名**: `mamori`（または `mamori-hoiku-gohan`）

```
mamori/
├── core-backend/          # Core Backend（Spring Boot Kotlin）
├── hoiku-backend/         # Hoiku Backend（Spring Boot Kotlin）
├── hoiku-frontend/        # Hoiku Frontend（React TypeScript）
├── infra/                 # インフラコード（Terraform）
├── docs/                  # 設計書・仕様書
├── .claude/               # Claude Code設定
├── .github/               # GitHub Actions CI/CD
├── CLAUDE.md              # プロジェクト指示書
└── README.md              # プロジェクト概要
```

### モノレポのメリット

1. **変更の整合性**: API変更時にフロント・バックエンドを同時変更
2. **バージョン管理の簡素化**: 1つのタグで全体をリリース
3. **ドキュメントの一元管理**: 実装と設計書が同じリポジトリ
4. **CI/CD設定の一元化**: GitHub Actionsが1箇所
5. **事業売却時の引き継ぎ容易**: 1つのリポジトリで完結

## GitHub初期設定

### 1. リポジトリ作成

```bash
# ローカルでGit初期化
cd /Users/masayasumori/Desktop/mamori
git init
git add .
git commit -m "chore: 初期コミット - プロジェクトセットアップ"

# GitHubでリポジトリ作成後
git remote add origin https://github.com/YOUR_USERNAME/mamori.git
git branch -M main
git push -u origin main
```

### 2. リポジトリ設定

| 設定項目 | 推奨値 |
|---------|--------|
| **Visibility** | Private（事業売却まで非公開） |
| **Description** | 保育施設向け監査対応帳票SaaS |
| **Topics** | `saas`, `childcare`, `nutrition`, `react`, `spring-boot`, `kotlin` |
| **README** | ✅ 既存のREADME.mdを使用 |
| **.gitignore** | ✅ 既存を使用 |
| **License** | なし（プロプライエタリ） |

### 3. ブランチ保護ルール

#### `main`ブランチ

Settings → Branches → Add rule

```yaml
Branch name pattern: main

保護設定:
☑ Require a pull request before merging
  ☑ Require approvals: 1
  ☑ Dismiss stale pull request approvals when new commits are pushed
☑ Require status checks to pass before merging
  ☑ Require branches to be up to date before merging
  Status checks:
    - CI (lint, test, build)
☑ Require conversation resolution before merging
☑ Do not allow bypassing the above settings
```

#### `develop`ブランチ

```yaml
Branch name pattern: develop

保護設定:
☑ Require a pull request before merging
  ☑ Require approvals: 1
☑ Require status checks to pass before merging
```

### 4. ブランチ戦略（Git Flow）

```
main          ────●─────────────●─────→ (本番環境)
               ↗                 ↗
develop    ───●─────●─────●─────●──────→ (開発環境)
             ↗     ↗     ↗
feature/xxx ●─────┘     │
feature/yyy       ●─────┘
```

#### ブランチ命名規則

| ブランチ | 用途 | 命名規則 | 例 |
|---------|------|---------|-----|
| `main` | 本番環境 | 固定 | `main` |
| `develop` | 開発環境 | 固定 | `develop` |
| `feature/*` | 機能開発 | `feature/{issue番号}-{機能名}` | `feature/123-menu-creation` |
| `fix/*` | バグ修正 | `fix/{issue番号}-{バグ内容}` | `fix/456-login-error` |
| `hotfix/*` | 緊急修正 | `hotfix/{issue番号}-{内容}` | `hotfix/789-security-patch` |
| `docs/*` | ドキュメントのみ | `docs/{内容}` | `docs/update-api-spec` |

## CI/CD設定（GitHub Actions）

### ディレクトリ構成

```
.github/
└── workflows/
    ├── core-backend-ci.yml      # Core Backend CI
    ├── hoiku-backend-ci.yml     # Hoiku Backend CI
    ├── hoiku-frontend-ci.yml    # Hoiku Frontend CI
    └── deploy.yml               # デプロイワークフロー
```

### Core Backend CI例

```yaml
# .github/workflows/core-backend-ci.yml
name: Core Backend CI

on:
  pull_request:
    paths:
      - 'core-backend/**'
      - '.github/workflows/core-backend-ci.yml'
  push:
    branches:
      - main
      - develop
    paths:
      - 'core-backend/**'

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_DB: mamori_test
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Cache Gradle packages
        uses: actions/cache@v3
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}

      - name: Grant execute permission for gradlew
        run: chmod +x core-backend/gradlew

      - name: Run tests
        run: |
          cd core-backend
          ./gradlew test

      - name: Build
        run: |
          cd core-backend
          ./gradlew build
```

### モノレポ最適化

**変更されたディレクトリのみビルド**するように`paths`を設定：

```yaml
on:
  pull_request:
    paths:
      - 'core-backend/**'  # Core Backendのみ変更時
```

## Secrets管理

Settings → Secrets and variables → Actions

| Secret名 | 説明 |
|---------|------|
| `AWS_ACCESS_KEY_ID` | AWSアクセスキー（デプロイ用） |
| `AWS_SECRET_ACCESS_KEY` | AWSシークレットキー（デプロイ用） |
| `DATABASE_URL` | データベース接続URL（テスト用） |
| `JWT_SECRET` | JWT署名キー |

## Issue/PR管理

### Issue テンプレート

`.github/ISSUE_TEMPLATE/`に以下を作成：

- `bug_report.md` - バグ報告
- `feature_request.md` - 機能要望
- `documentation.md` - ドキュメント更新

### Pull Request テンプレート

`.github/pull_request_template.md`

```markdown
## 概要
<!-- 変更内容の概要を記載 -->

## 変更内容
- [ ] 機能追加
- [ ] バグ修正
- [ ] リファクタリング
- [ ] ドキュメント更新

## チェックリスト
- [ ] テストが通ることを確認
- [ ] ドキュメントを更新（必要な場合）
- [ ] レビュー可能な単位に分割

## 関連Issue
Closes #XXX
```

## 代替案：マルチリポジトリ（将来的な選択肢）

将来、以下の状況になった場合はマルチリポに分割を検討：

### 分割するタイミング

1. **チーム規模の拡大**: 10人以上の開発チーム
2. **独立したリリースサイクル**: サービスごとに異なるリリース頻度
3. **外部パートナー連携**: 一部サービスのみアクセス権を与えたい
4. **マイクロサービス化**: 完全に独立したサービスに分割

### マルチリポ構成例

```
mamori-core-backend      # Core Backend
mamori-hoiku-backend     # Hoiku Backend
mamori-hoiku-frontend    # Hoiku Frontend
mamori-infra             # インフラコード
mamori-docs              # ドキュメント（または各リポジトリに含める）
```

### マルチリポのデメリット

- API変更時に複数リポジトリを同期する必要
- バージョン管理が複雑（どのバージョン同士が互換性があるか）
- CI/CDの設定が各リポジトリで必要
- 事業売却時の引き継ぎが複雑

## 推奨：モノレポから始める

**まずはモノレポで開始**し、必要に応じて将来マルチリポに分割することを推奨します。

### モノレポ → マルチリポ移行の容易性

Git の `subtree` や `filter-branch` を使えば、後から分割も可能です。

```bash
# 例：hoiku-frontendを別リポジトリに分割
git subtree split --prefix=hoiku-frontend -b hoiku-frontend-only
```

## まとめ

| 項目 | モノレポ | マルチリポ |
|------|---------|-----------|
| **管理の簡便性** | ⭐⭐⭐ | ⭐ |
| **変更の整合性** | ⭐⭐⭐ | ⭐ |
| **サービス独立性** | ⭐ | ⭐⭐⭐ |
| **CI/CD複雑度** | ⭐⭐⭐ | ⭐ |
| **事業売却時** | ⭐⭐⭐ | ⭐ |
| **小〜中規模向け** | ⭐⭐⭐ | ⭐ |
| **大規模向け** | ⭐ | ⭐⭐⭐ |

**現段階の推奨**: モノレポ（1つのリポジトリ）
