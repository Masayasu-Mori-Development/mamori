# GitHub初期セットアップ手順

## 前提条件

- GitHubアカウントを持っていること
- Git がインストールされていること

## 手順

### 1. Gitリポジトリの初期化

```bash
cd /Users/masayasumori/Desktop/mamori

# Git初期化
git init

# 全ファイルをステージング
git add .

# 初回コミット
git commit -m "chore: プロジェクト初期セットアップ

- Core Backend（Spring Boot Kotlin）
- Hoiku Backend（Spring Boot Kotlin）
- Hoiku Frontend（React TypeScript）
- インフラコード（Terraform）
- ドキュメント体系（docs/）
- Claude Code設定（.claude/）
- GitHub Actions CI/CD設定"
```

### 2. GitHubでリポジトリ作成

1. **GitHubにアクセス**: https://github.com
2. **New repository** をクリック
3. **リポジトリ設定**:
   - **Repository name**: `mamori`（または `mamori-hoiku-gohan`）
   - **Description**: 保育施設向け監査対応帳票SaaS
   - **Visibility**: **Private**（重要：事業売却まで非公開）
   - **Initialize this repository with**:
     - ❌ Add a README file（既存を使用）
     - ❌ Add .gitignore（既存を使用）
     - ❌ Choose a license（プロプライエタリ）
4. **Create repository** をクリック

### 3. リモートリポジトリの設定とプッシュ

```bash
# リモートリポジトリを追加（YOUR_USERNAMEを自分のユーザー名に置き換え）
git remote add origin https://github.com/YOUR_USERNAME/mamori.git

# メインブランチ名を設定
git branch -M main

# GitHubにプッシュ
git push -u origin main
```

### 4. developブランチの作成

```bash
# developブランチを作成
git checkout -b develop

# developブランチをGitHubにプッシュ
git push -u origin develop

# mainブランチに戻る
git checkout main
```

### 5. ブランチ保護ルールの設定

#### mainブランチの保護

1. GitHubリポジトリページで **Settings** → **Branches** をクリック
2. **Add rule** をクリック
3. **Branch name pattern**: `main`
4. 以下にチェック:
   - ☑ **Require a pull request before merging**
     - ☑ Require approvals: **1**
     - ☑ Dismiss stale pull request approvals when new commits are pushed
   - ☑ **Require status checks to pass before merging**
     - ☑ Require branches to be up to date before merging
     - Status checks that are required（最初のPR後に選択可能）:
       - `Core Backend CI`
       - `Hoiku Backend CI`
       - `Hoiku Frontend CI`
   - ☑ **Require conversation resolution before merging**
   - ☑ **Do not allow bypassing the above settings**
5. **Create** をクリック

#### developブランチの保護

1. **Add rule** をクリック
2. **Branch name pattern**: `develop`
3. 以下にチェック:
   - ☑ **Require a pull request before merging**
     - ☑ Require approvals: **1**
   - ☑ **Require status checks to pass before merging**
5. **Create** をクリック

### 6. GitHub Actionsの確認

1. GitHubリポジトリページで **Actions** タブをクリック
2. 以下のワークフローが表示されることを確認:
   - `Core Backend CI`
   - `Hoiku Backend CI`
   - `Hoiku Frontend CI`

### 7. Topics（タグ）の設定

1. GitHubリポジトリページで **⚙️（Settings）** をクリック
2. **Topics** セクションで以下を追加:
   - `saas`
   - `childcare`
   - `nutrition`
   - `react`
   - `spring-boot`
   - `kotlin`
   - `typescript`
   - `postgresql`

## 日常の開発フロー

### 新機能の開発

```bash
# developブランチから最新を取得
git checkout develop
git pull origin develop

# 機能ブランチを作成（issue番号-機能名）
git checkout -b feature/123-menu-creation

# コード変更・コミット
git add .
git commit -m "feat: 献立作成機能を追加"

# GitHubにプッシュ
git push -u origin feature/123-menu-creation
```

### プルリクエストの作成

1. GitHubでプッシュ後に表示される **Compare & pull request** をクリック
2. **base**: `develop` ← **compare**: `feature/123-menu-creation`
3. PRテンプレートに従って記入
4. **Create pull request** をクリック
5. レビュアーを指定
6. CI/CDが全てグリーンになることを確認
7. レビュー承認後、**Merge pull request**

### リリース（developからmainへ）

```bash
# developブランチの最新を取得
git checkout develop
git pull origin develop

# リリースブランチを作成
git checkout -b release/v1.0.0

# バージョン番号の更新（package.json、build.gradleなど）
# ...

git add .
git commit -m "chore: v1.0.0リリース準備"

# GitHubにプッシュ
git push -u origin release/v1.0.0
```

1. GitHubで **base**: `main` ← **compare**: `release/v1.0.0` のPRを作成
2. レビュー・承認後、mainにマージ
3. mainブランチにタグを作成:

```bash
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## トラブルシューティング

### GitHub Actionsが失敗する場合

1. **Actions** タブで失敗したワークフローをクリック
2. エラーログを確認
3. ローカルで修正してプッシュ

### ブランチ保護でプッシュできない場合

- mainやdevelopブランチには直接プッシュできません
- 必ずfeatureブランチからPRを作成してください

## Secrets設定（デプロイ時に必要）

将来的にAWSへのデプロイを自動化する場合：

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** をクリック
3. 以下のSecretsを追加:

| Secret名 | 説明 |
|---------|------|
| `AWS_ACCESS_KEY_ID` | AWSアクセスキー |
| `AWS_SECRET_ACCESS_KEY` | AWSシークレットキー |
| `DATABASE_URL` | RDS接続URL |
| `JWT_SECRET` | JWT署名キー |

## 参考

- [GitHub Actionsドキュメント](https://docs.github.com/ja/actions)
- [ブランチ保護ルール](https://docs.github.com/ja/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
