# VSCode開発環境セットアップ

## VSCodeを推奨する理由

このプロジェクトでは**VSCodeを推奨**します。

### 理由

1. **完全無料** - IntelliJ Ultimate（$169/年）と異なり、コスト0
2. **モノレポに最適** - 1つのエディタでFE/BE/Infraを管理
3. **Claude Codeとの親和性** - Claude Codeはエディタ非依存だが、VSCodeユーザーが多い
4. **軽量・高速** - メモリ使用量が少なく、起動が早い
5. **豊富な拡張機能** - Kotlin、Spring Boot、React、Terraformすべてサポート

## 必須拡張機能

### 共通

| 拡張機能 | ID | 説明 |
|---------|-----|------|
| **GitLens** | `eamodio.gitlens` | Git履歴・ブランチ管理 |
| **Git Graph** | `mhutchie.git-graph` | Gitグラフ可視化 |
| **EditorConfig** | `EditorConfig.EditorConfig` | コーディング規約統一 |
| **Prettier** | `esbenp.prettier-vscode` | コードフォーマッター |
| **Error Lens** | `usernamehw.errorlens` | エラー表示強化 |

### フロントエンド（React + TypeScript）

| 拡張機能 | ID | 説明 |
|---------|-----|------|
| **ESLint** | `dbaeumer.vscode-eslint` | JavaScriptリンター |
| **Prettier** | `esbenp.prettier-vscode` | フォーマッター |
| **ES7+ React/Redux/React-Native snippets** | `dsznajder.es7-react-js-snippets` | Reactスニペット |
| **Auto Import** | `steoates.autoimport` | 自動import |
| **Path Intellisense** | `christian-kohler.path-intellisense` | パス補完 |
| **CSS Modules** | `clinyong.vscode-css-modules` | CSS Modules補完 |

### バックエンド（Kotlin + Spring Boot）

| 拡張機能 | ID | 説明 |
|---------|-----|------|
| **Kotlin Language** | `mathiasfrohlich.Kotlin` | Kotlin言語サポート |
| **Extension Pack for Java** | `vscjava.vscode-java-pack` | Java開発環境 |
| **Spring Boot Extension Pack** | `vmware.vscode-boot-dev-pack` | Spring Boot開発環境 |
| **Gradle for Java** | `vscjava.vscode-gradle` | Gradleサポート |
| **YAML** | `redhat.vscode-yaml` | YAML編集 |

### インフラ（Terraform）

| 拡張機能 | ID | 説明 |
|---------|-----|------|
| **HashiCorp Terraform** | `hashicorp.terraform` | Terraform公式拡張 |
| **Terraform Doc Snippets** | `run-at-scale.terraform-doc-snippets` | Terraformスニペット |

### ドキュメント

| 拡張機能 | ID | 説明 |
|---------|-----|------|
| **Markdown All in One** | `yzhang.markdown-all-in-one` | Markdown編集強化 |
| **Markdown Preview Enhanced** | `shd101wyy.markdown-preview-enhanced` | Markdownプレビュー |
| **Mermaid Markdown Syntax Highlighting** | `bpruitt-goddard.mermaid-markdown-syntax-highlighting` | Mermaid図サポート |

## インストール方法

### 1. 拡張機能の一括インストール

以下のコマンドで一括インストール可能です：

```bash
# 共通
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph
code --install-extension EditorConfig.EditorConfig
code --install-extension esbenp.prettier-vscode
code --install-extension usernamehw.errorlens

# フロントエンド
code --install-extension dbaeumer.vscode-eslint
code --install-extension dsznajder.es7-react-js-snippets
code --install-extension steoates.autoimport
code --install-extension christian-kohler.path-intellisense
code --install-extension clinyong.vscode-css-modules

# バックエンド
code --install-extension mathiasfrohlich.Kotlin
code --install-extension vscjava.vscode-java-pack
code --install-extension vmware.vscode-boot-dev-pack
code --install-extension vscjava.vscode-gradle
code --install-extension redhat.vscode-yaml

# インフラ
code --install-extension hashicorp.terraform
code --install-extension run-at-scale.terraform-doc-snippets

# ドキュメント
code --install-extension yzhang.markdown-all-in-one
code --install-extension shd101wyy.markdown-preview-enhanced
code --install-extension bpruitt-goddard.mermaid-markdown-syntax-highlighting
```

### 2. VSCode設定ファイル

プロジェクトルートに`.vscode/settings.json`を作成します（後述）。

## VSCode設定

### プロジェクト設定（.vscode/settings.json）

```json
{
  // 共通設定
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit"
  },
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,

  // TypeScript/JavaScript
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2
  },

  // Kotlin
  "[kotlin]": {
    "editor.tabSize": 2
  },

  // YAML
  "[yaml]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },

  // Markdown
  "[markdown]": {
    "editor.defaultFormatter": "yzhang.markdown-all-in-one",
    "editor.tabSize": 2
  },

  // Terraform
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },

  // Java/Kotlin設定
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.compile.nullAnalysis.mode": "automatic",

  // Git
  "git.autofetch": true,
  "git.confirmSync": false,

  // ファイル除外
  "files.exclude": {
    "**/.gradle": true,
    "**/build": true,
    "**/node_modules": true,
    "**/.DS_Store": true
  },

  // 検索除外
  "search.exclude": {
    "**/node_modules": true,
    "**/build": true,
    "**/.gradle": true,
    "**/dist": true
  }
}
```

### 推奨拡張機能リスト（.vscode/extensions.json）

```json
{
  "recommendations": [
    "eamodio.gitlens",
    "mhutchie.git-graph",
    "EditorConfig.EditorConfig",
    "esbenp.prettier-vscode",
    "usernamehw.errorlens",
    "dbaeumer.vscode-eslint",
    "dsznajder.es7-react-js-snippets",
    "steoates.autoimport",
    "christian-kohler.path-intellisense",
    "clinyong.vscode-css-modules",
    "mathiasfrohlich.Kotlin",
    "vscjava.vscode-java-pack",
    "vmware.vscode-boot-dev-pack",
    "vscjava.vscode-gradle",
    "redhat.vscode-yaml",
    "hashicorp.terraform",
    "run-at-scale.terraform-doc-snippets",
    "yzhang.markdown-all-in-one",
    "shd101wyy.markdown-preview-enhanced",
    "bpruitt-goddard.mermaid-markdown-syntax-highlighting"
  ]
}
```

## デバッグ設定

### Spring Boot デバッグ（.vscode/launch.json）

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Debug Core Backend",
      "request": "launch",
      "mainClass": "com.mamori.core.MamoriCoreApplicationKt",
      "projectName": "core-backend",
      "args": "",
      "envFile": "${workspaceFolder}/core-backend/.env"
    },
    {
      "type": "java",
      "name": "Debug Hoiku Backend",
      "request": "launch",
      "mainClass": "com.mamori.hoiku.MamoriHoikuApplicationKt",
      "projectName": "hoiku-backend",
      "args": "",
      "envFile": "${workspaceFolder}/hoiku-backend/.env"
    }
  ]
}
```

### React デバッグ

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "chrome",
      "request": "launch",
      "name": "Debug React App",
      "url": "http://localhost:3000",
      "webRoot": "${workspaceFolder}/hoiku-frontend/src"
    }
  ]
}
```

## タスク設定（.vscode/tasks.json）

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Core Backend: Build",
      "type": "shell",
      "command": "./gradlew build",
      "options": {
        "cwd": "${workspaceFolder}/core-backend"
      },
      "group": "build"
    },
    {
      "label": "Hoiku Backend: Build",
      "type": "shell",
      "command": "./gradlew build",
      "options": {
        "cwd": "${workspaceFolder}/hoiku-backend"
      },
      "group": "build"
    },
    {
      "label": "Frontend: Build",
      "type": "shell",
      "command": "npm run build",
      "options": {
        "cwd": "${workspaceFolder}/hoiku-frontend"
      },
      "group": "build"
    }
  ]
}
```

## ワークスペース設定

モノレポプロジェクトなので、マルチルートワークスペースを使用します。

### .vscode/mamori.code-workspace

```json
{
  "folders": [
    {
      "name": "Root",
      "path": ".."
    },
    {
      "name": "Core Backend",
      "path": "../core-backend"
    },
    {
      "name": "Hoiku Backend",
      "path": "../hoiku-backend"
    },
    {
      "name": "Hoiku Frontend",
      "path": "../hoiku-frontend"
    },
    {
      "name": "Infrastructure",
      "path": "../infra"
    },
    {
      "name": "Docs",
      "path": "../docs"
    }
  ],
  "settings": {
    "files.exclude": {
      "**/.git": true,
      "**/.gradle": true,
      "**/build": true,
      "**/node_modules": true
    }
  }
}
```

## VSCode vs IntelliJ 比較

| 項目 | VSCode | IntelliJ Community | IntelliJ Ultimate |
|------|--------|-------------------|------------------|
| **価格** | 無料 | 無料 | $169/年（初年度） |
| **Kotlinサポート** | 良い | 優秀 | 優秀 |
| **Spring Bootサポート** | 普通 | 限定的 | 優秀 |
| **リファクタリング** | 普通 | 優秀 | 優秀 |
| **デバッグ** | 良い | 優秀 | 優秀 |
| **React/TypeScript** | 優秀 | 普通 | 良い |
| **Terraform** | 優秀 | 普通 | 良い |
| **起動速度** | 速い | 普通 | 遅い |
| **メモリ使用量** | 少ない | 多い | 非常に多い |
| **モノレポ対応** | 優秀 | 普通 | 良い |

## 推奨ワークフロー

### 開発開始時

```bash
# VSCodeでワークスペースを開く
code mamori.code-workspace
```

### フロントエンド開発時

1. `hoiku-frontend` フォルダを開く
2. ターミナルで `npm run dev`
3. 開発サーバーが起動（http://localhost:3000）

### バックエンド開発時

1. `core-backend` または `hoiku-backend` フォルダを開く
2. F5キーでデバッグ起動
3. または、ターミナルで `./gradlew bootRun`

## IntelliJが必要になるケース

以下の場合はIntelliJ IDEA Community Edition（無料）を検討：

1. **Kotlinのリファクタリングを頻繁に行う**
2. **Spring Bootの依存関係管理が複雑になる**
3. **データベースツールが必要**（Ultimate版のみ）

## まとめ

- **まずはVSCodeで開発を開始** - 完全無料で十分な機能
- **不便を感じたらIntelliJ Community Editionを試す** - 無料
- **本格的なSpring Boot開発が必要ならIntelliJ Ultimate** - 有料だが開発効率が大幅向上

ARR 100M円を目指すプロジェクトなら、開発効率への投資は検討価値がありますが、まずは無料のVSCodeで始めることを推奨します。
