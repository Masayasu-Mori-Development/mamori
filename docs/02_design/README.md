# システム設計

## 概要

このディレクトリには、まもり保育ごはんのシステム設計書を管理します。

## ドキュメント一覧

| ドキュメント名 | 説明 | ステータス |
|--------------|------|-----------|
| [system-architecture.md](./system-architecture.md) | システムアーキテクチャ（全体構成、技術選定） | テンプレート |
| [domain-model.md](./domain-model.md) | ドメインモデル（エンティティ、関連） | テンプレート |
| [security-design.md](./security-design.md) | セキュリティ設計（認証、認可、暗号化） | テンプレート |

## 設計の基本方針

### 1. Core と Hoiku の分離

- **core-backend**: 認証・ユーザー管理・テナント管理など共通機能
- **hoiku-backend**: 献立・栄養計算・帳票生成など保育特化機能
- **hoiku-frontend**: 保育施設向けUI

### 2. マルチテナント設計

- 全業務テーブルに `tenant_id` を必須化
- テナント単位でデータを完全分離
- 将来的な大口顧客専用DB分離も考慮

### 3. BFF（Backend For Frontend）思想

- hoiku-frontendは `/api/hoiku/*` のみアクセス
- 認証は `/api/core/*` で一元管理
- 疎結合で将来の拡張に対応

### 4. スケーラビリティ

- ステートレスなアプリケーション設計
- AWS Auto Scalingによる柔軟なスケーリング
- PostgreSQL Schema分離による論理的な境界

## 設計原則

### SOLID原則

- **Single Responsibility Principle**: 単一責任の原則
- **Open/Closed Principle**: 開放/閉鎖の原則
- **Liskov Substitution Principle**: リスコフの置換原則
- **Interface Segregation Principle**: インターフェース分離の原則
- **Dependency Inversion Principle**: 依存性逆転の原則

### DRY (Don't Repeat Yourself)

- 共通ロジックは core-backend に集約
- 重複コードを排除し、保守性を向上

### KISS (Keep It Simple, Stupid)

- 過度な抽象化を避ける
- シンプルで理解しやすい設計

## 設計レビュー

設計変更時は以下の観点でレビュー:

- [ ] アーキテクチャの一貫性
- [ ] スケーラビリティへの影響
- [ ] セキュリティリスク
- [ ] パフォーマンスへの影響
- [ ] 保守性・拡張性

## 参考資料

- [CLAUDE.md](../../CLAUDE.md) - プロジェクト指示書
- [01_requirements](../01_requirements/) - 要件定義書
- [03_database](../03_database/) - データベース設計書
