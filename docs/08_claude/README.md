# Claude Code設定

Claude Codeの設定とプロジェクト指示書を管理するディレクトリです。

## 実際の設定ファイルの場所

**重要**: Claude Codeの設定ファイルは `.claude/` ディレクトリに配置されています。このディレクトリはGit管理されており、事業売却時にもそのまま引き継がれます。

```
.claude/
├── settings.json           # プロジェクト設定（Git管理）
├── settings.local.json     # ローカル設定（.gitignoreで除外）
└── rules/                  # パス固有のルール（Git管理）
    ├── coding-standards.md
    ├── api-design.md
    └── database-design.md
```

## ファイル構成

### このディレクトリ（docs/08_claude/）

- **README.md**: このファイル（Claude Code設定の概要）
- **setup-guide.md**: 新規開発者向けのClaude Code初期設定手順
- **usage-guide.md**: Claude Codeの効果的な使い方
- **rules-guide.md**: `.claude/rules/`の運用方針

### .claude/ディレクトリ（プロジェクトルート）

| ファイル | 説明 | Git管理 |
|---------|------|---------|
| **settings.json** | プロジェクト共通設定 | ✅ Yes |
| **settings.local.json** | 個人のローカル設定 | ❌ No (.gitignore) |
| **rules/coding-standards.md** | コーディング規約 | ✅ Yes |
| **rules/api-design.md** | API設計原則 | ✅ Yes |
| **rules/database-design.md** | DB設計原則 | ✅ Yes |

## CLAUDE.md（プロジェクト指示書）

プロジェクトルートの `CLAUDE.md` がClaude Codeのメイン設定ファイルです。

### 役割

- プロジェクト概要の説明
- アーキテクチャ思想の共有
- 技術スタックの定義
- 開発ルールの明示
- `.claude/rules/`ファイルへの参照

### 分割構成

CLAUDE.mdが大きくなりすぎないように、詳細ルールは`.claude/rules/`に分割しています。

```markdown
# CLAUDE.md内での参照方法
@.claude/rules/coding-standards.md
@.claude/rules/api-design.md
@.claude/rules/database-design.md
```

## Claude Code設定の重要性

このプロジェクトは**事業売却を前提**としているため、Claude Code設定は以下の点で重要です：

1. **新規開発者のオンボーディング**: CLAUDE.mdを読むだけでプロジェクト全体を理解可能
2. **一貫したコード品質**: `.claude/rules/`により、誰が書いても同じコーディングスタイルを維持
3. **設計思想の継承**: Why（なぜその設計にしたか）を明記することで、将来の変更判断を支援
4. **効率的な開発**: Claude Codeが適切なコンテキストを持つことで、高品質なコード提案が可能

## 更新ルール

### CLAUDE.mdの更新

- **アーキテクチャ変更時**: 必ず更新
- **新技術導入時**: 技術スタックセクションを更新
- **重要な設計判断時**: その理由を記載

### .claude/rules/の更新

- **コーディング規約追加時**: coding-standards.md を更新
- **API設計変更時**: api-design.md を更新
- **DB設計変更時**: database-design.md を更新

### 新規ルールファイルの追加

パス固有のルールを追加する場合：

```yaml
---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
---

# テストコード規約
...
```

## セキュリティ設定

`.claude/settings.json`では、機密情報へのアクセスを制限しています：

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./frontend/.env)",
      "Read(./backend/src/main/resources/application-*.yml)",
      "Read(./infra/terraform/*.tfvars)",
      "Read(./**/*secret*)",
      "Read(./**/*credential*)"
    ]
  },
  "respectGitignore": true
}
```

## 参考リンク

- [Claude Code公式ドキュメント](https://docs.claude.com/en/docs/claude-code)
- プロジェクトルートの `CLAUDE.md`
- `.claude/rules/` ディレクトリ
