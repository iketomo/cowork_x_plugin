# Cowork Plugin 作成・管理ガイド

このドキュメントは、Claude Code / Cowork Plugin のマーケットプレイスにプラグインを追加・管理するための包括的なガイドです。

---

## 1. 基本概念

### Plugin と Marketplace の違い

| 概念 | 役割 | ファイル | 例え |
|------|------|---------|------|
| **Plugin** | 個別の機能パッケージ（skills, agents, commands等） | `.claude-plugin/plugin.json` | アプリ |
| **Marketplace** | プラグインのカタログ（配布用の入れ物） | `.claude-plugin/marketplace.json` | App Store |

- GitHubで公開するにはマーケットプレイスが必須
- プラグイン単体では `/plugin marketplace add` できない
- 1つのマーケットプレイスに複数プラグインを含められる

---

## 2. フォルダ構成ルール

### 正しい構成

```
cowork_plugin/                              # マーケットプレイス（リポジトリルート）
├── .claude-plugin/
│   └── marketplace.json                    # マーケットプレイスマニフェスト
├── {plugin-name}/                          # プラグイン本体（サブディレクトリ）
│   ├── .claude-plugin/
│   │   └── plugin.json                     # プラグインマニフェスト
│   ├── skills/                             # スキル定義
│   │   └── {skill-name}/
│   │       └── SKILL.md
│   ├── agents/                             # サブエージェント定義
│   │   └── {agent-name}.md
│   ├── commands/                           # スラッシュコマンド定義
│   │   └── {command-name}.md
│   ├── scripts/                            # ユーティリティスクリプト（必要時のみ）
│   ├── reference/                          # 参考資料（必要時のみ）
│   ├── log/                                # 出力レポート保存先（必要時のみ）
│   ├── config.example.md                   # 設定テンプレート（公開OK）
│   └── config.local.md                     # 実際の設定値（gitignore対象）
├── .claude/
│   ├── settings.local.json
│   └── plugin-creation-guide.md            # このファイル
├── CLAUDE.md
├── SETUP.md
├── PROGRESS.md
└── .gitignore
```

### 絶対守るべきルール

1. **marketplace.json と plugin.json は別ディレクトリに置く** — 同じ `.claude-plugin/` に同居させない
2. **プラグインは必ずサブディレクトリに配置** — ルート直下に skills/ 等を置かない
3. **marketplace.json の `source` は `"./サブディレクトリ名"`** — `"."` や外部URLではなく相対パス
4. **プラグイン名は kebab-case** — 例: `x-manager`, `circle-manager`

---

## 3. JSON マニフェスト仕様

### marketplace.json

ファイル配置: `cowork_plugin/.claude-plugin/marketplace.json`

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "cowork-plugins-marketplace",
  "owner": {
    "name": "iketomo"
  },
  "plugins": [
    {
      "name": "{plugin-name}",
      "source": "./{plugin-directory}",
      "description": "{プラグインの説明}",
      "version": "1.0.0",
      "author": {
        "name": "iketomo"
      },
      "category": "{カテゴリ}"
    }
  ]
}
```

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `$schema` | 推奨 | `"https://anthropic.com/claude-code/marketplace.schema.json"` |
| `name` | 必須 | マーケットプレイス識別子（kebab-case） |
| `owner.name` | 必須 | 管理者名 |
| `plugins[].name` | 必須 | プラグイン識別子（plugin.json の name と一致） |
| `plugins[].source` | 必須 | 相対パス `"./{dir}"` |
| `plugins[].description` | 推奨 | プラグインの説明 |
| `plugins[].version` | 推奨 | セマンティックバージョン |
| `plugins[].category` | 任意 | productivity, development, security 等 |

#### source の書き方

```json
// 同じリポジトリ内（Coworkでは常にこれを使う）
"source": "./{plugin-name}"
```

#### 予約済みマーケットプレイス名（使用不可）
`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`

### plugin.json

ファイル配置: `{plugin-name}/.claude-plugin/plugin.json`

```json
{
  "name": "{plugin-name}",
  "description": "{プラグインの説明}",
  "version": "1.0.0",
  "author": {
    "name": "iketomo",
    "email": ""
  }
}
```

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | 必須 | marketplace.json の plugins[].name と一致させる |
| `description` | 推奨 | プラグインの説明 |
| `version` | 推奨 | marketplace.json の plugins[].version と一致させる |
| `author.name` | 任意 | 作者名 |

---

## 4. コンポーネント作成テンプレート

### 4.1 SKILL.md（スキル定義）

ファイル配置: `{plugin}/skills/{skill-name}/SKILL.md`

```markdown
---
name: {skill-name}
description: >
  {スキルの説明。何をするスキルか、どんなリクエストで発動するかを記載。}
  「発動ワード1」「発動ワード2」「発動ワード3」
version: 1.0.0
---

# {スキル名}

## 概要
{スキルが何をするか}

## コンテキスト節約アーキテクチャ
- メインエージェント: 最小限の処理（SQL実行、入力検証等）
- サブエージェント: 重い処理を委譲（分析、DB保存、レポート生成等）

## 実行手順

### ステップ1: データ取得
{SQLクエリやAPI呼び出し}

### ステップ2: サブエージェント起動
Taskツールで {agent-name} サブエージェントを起動する。
以下のデータを渡す：
- {渡すデータ1}
- {渡すデータ2}

### ステップ3: 結果報告
{サブエージェントの結果をユーザーに報告}

## 重要ルール
- {守るべきルール}
```

#### フロントマター仕様

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | 必須 | スキル識別子（kebab-case） |
| `description` | 必須 | 説明文。`>` で複数行。発動トリガーワードも含める |
| `version` | 任意 | バージョン |

#### 既存プラグインのスキルパターン

| パターン | 特徴 | 例 |
|---------|------|-----|
| **サブエージェント委譲型** | メインはSQL実行のみ、分析はサブエージェントへ | x-daily-report, x-trend-report, circle-daily-report |
| **直接実行型** | メインエージェントが直接処理 | luma-daily-report |
| **多段階委譲型** | 複数サブエージェントを順番に呼び出す | x-trend-report（3段階） |
| **入出力仲介型** | ユーザー入力をサブエージェントに渡す | x-writing, x-post |

### 4.2 Agent（サブエージェント定義）

ファイル配置: `{plugin}/agents/{agent-name}.md`

```markdown
---
name: {agent-name}
description: |
  {エージェントの説明。呼び出し元・役割を記載。}

  <example>
  Context: {どの場面で呼び出されるか}
  user: "{ユーザーの発言例}"
  assistant: "{Claudeの応答例}"
  <commentary>
  {補足説明}
  </commentary>
  </example>
model: sonnet
color: blue
tools: ["WebSearch", "Write", "Read"]
---

# {エージェント名}

## 役割
{このエージェントが担う具体的な役割}

## 手順
1. {具体的な処理ステップ}
2. ...

## 返却フォーマット
{出力形式の指定}
```

#### フロントマター仕様

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | 必須 | エージェント識別子 |
| `description` | 必須 | 説明（`\|` で複数行、`<example>` タグで例示可） |
| `model` | 必須 | `sonnet`（推奨）, `opus`, `haiku` |
| `color` | 推奨 | `blue`, `cyan`, `green`, `yellow`, `red`, `purple` |
| `tools` | 推奨 | 使用可能ツール配列 |

#### 使用可能ツール一覧
`"WebSearch"`, `"Write"`, `"Read"`, `"Bash"`, `"Grep"`, `"Glob"`, `"Task"`, `"Skill"`, `"Edit"`, `"AskUserQuestion"`, `"WebFetch"`

#### ツール選択の指針

| 処理内容 | 推奨ツール |
|---------|-----------|
| レポート分析・DB保存 | `["Write", "Read"]` or `["WebSearch", "Write", "Bash"]` |
| 文章作成 | `["WebSearch", "Read"]` |
| データ収集 | `["WebSearch", "WebFetch", "Read"]` |
| ファイル操作が必要 | `["Write", "Read", "Bash"]` |

### 4.3 Command（スラッシュコマンド定義）

ファイル配置: `{plugin}/commands/{command-name}.md`

```markdown
---
description: {コマンドの説明}
argument-hint: [{引数の説明}]
allowed-tools: ["Skill", "Read", "Write", "Task"]
---

# /{command-name}

{コマンドの概要説明}

## 実行手順
1. {ステップ1}
2. {ステップ2}

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
```

#### フロントマター仕様

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `description` | 必須 | コマンドの説明 |
| `allowed-tools` | 推奨 | 使用許可ツール配列 |
| `argument-hint` | 任意 | 引数のヒント（`[説明]` 形式） |

#### コマンド → スキルの関係
- コマンドは通常、対応するスキルを呼び出すエントリポイント
- コマンドの `allowed-tools` に `"Skill"` を含めることでスキル呼び出しが可能
- `$ARGUMENTS` でユーザーからの引数を受け取る

---

## 5. 機密情報の管理

### config.example.md（公開用テンプレート）

```markdown
# {Plugin Name} 設定テンプレート
> このファイルを `config.local.md` にコピーして値を記入してください。

## Supabase
- Project Name: `your-project-name`
- Project ID: `your-project-id`
- Anon Key: `your-anon-key`
- Service Role Key: `your-service-role-key`
- Edge Function Base URL: `https://your-project-id.supabase.co/functions/v1`

## 外部サービス
- API Key: `your-api-key`
- Webhook URL: `your-webhook-url`

## アカウント情報
- Username: `your-username`
- Display Name: `your-display-name`
```

### config.local.md（実際の値）

gitignore 対象。実際のキーや URL を記入する。

### .gitignore に必ず含めるもの

```
**/config.local.md
.env
.env.local
```

### スキル/エージェントからの参照方法

スキルやエージェントの MD 内に以下のように記載：
```
※ API設定は config.local.md を参照すること。
```

---

## 6. コンテキスト節約アーキテクチャ

Cowork プラグインでは **メインエージェントのコンテキストウインドウを節約するため、サブエージェントへの委譲を積極的に行う** ことが最重要設計方針。

### パターン

```
ユーザー → コマンド → スキル（メインエージェント）→ サブエージェント
                        ↑ 最小限の処理               ↑ 重い処理を委譲
                        （SQL実行、入力検証）          （分析、生成、DB保存、レポート出力）
```

### 設計指針

1. **メインエージェントでやること**: SQL実行によるデータ取得、ユーザー入力の検証、サブエージェント起動
2. **サブエージェントに委譲すること**: データ分析、レポート生成、DB保存、Web検索、ファイル書き出し
3. **サブエージェントへのデータ渡し**: Task ツールの prompt にデータを含めて渡す

---

## 7. バージョン管理ルール

### 個別バージョン管理ルール

バージョンは **アップデートしたプラグインのみ** 個別にバンプする（全プラグイン同期は不要）。

更新時に一致させる2箇所：
1. `.claude-plugin/marketplace.json` の該当 `plugins[].version`
2. 該当プラグイン直下の `.claude-plugin/plugin.json` の `version`

### 更新手順

1. プラグインの内容を更新
2. 該当プラグインのバージョン番号を `1.0.X` → `1.0.X+1` のように段階的にアップ
3. marketplace.json の該当プラグインの version を更新
4. 該当プラグインの plugin.json の version を更新
5. `UPDATE.md` に日付・プラグイン名・バージョン・変更内容を記録

---

## 8. プラグイン作成手順

### Phase 1: 要件定義

以下を明確にする：

| 項目 | 確認内容 |
|------|---------|
| プラグイン名 | kebab-case で命名（例: `slack-reporter`） |
| スキル一覧 | 何を自動化するか（各スキルの名前・概要） |
| サブエージェント | 重い処理の委譲先（コンテキスト節約のため） |
| コマンド | ユーザーが呼び出すスラッシュコマンド |
| 外部サービス | Supabase, API, Slack 等の連携先 |
| データベース | テーブル設計（`{plugin}_*` プレフィックス） |

### Phase 2: フォルダ構成の作成

```bash
# 1. プラグインディレクトリ作成
mkdir -p {plugin-name}/.claude-plugin
mkdir -p {plugin-name}/skills
mkdir -p {plugin-name}/agents
mkdir -p {plugin-name}/commands

# 2. 必要に応じて追加ディレクトリ
mkdir -p {plugin-name}/scripts    # スクリプトがある場合
mkdir -p {plugin-name}/reference  # 参考資料がある場合
mkdir -p {plugin-name}/log        # レポート出力がある場合
```

### Phase 3: マニフェスト作成

1. `{plugin-name}/.claude-plugin/plugin.json` を作成
2. `.claude-plugin/marketplace.json` に新プラグインのエントリを追加

### Phase 4: コンポーネント作成

1. スキル: `skills/{skill-name}/SKILL.md` — セクション4.1のテンプレートに従う
2. エージェント: `agents/{agent-name}.md` — セクション4.2のテンプレートに従う
3. コマンド: `commands/{command-name}.md` — セクション4.3のテンプレートに従う

### Phase 5: 設定ファイル

1. `config.example.md` にテンプレートを作成
2. `config.local.md` に実際の値を記入
3. `.gitignore` で `config.local.md` が除外されていることを確認

### Phase 6: セキュリティチェック

公開前に以下が含まれていないことを確認：

- APIキー・トークン（`eyJ`, `sk-`, `Bearer` 等）
- プロジェクトID・URL
- Webhook URL
- 個人メールアドレス・アカウント名
- パスワード・シークレット

### Phase 7: バージョン同期

全プラグインのバージョンが同一であることを確認し、必要なら更新。

### Phase 8: CLAUDE.md 更新

`cowork_plugin/CLAUDE.md` のプラグイン一覧に新プラグインの情報を追加。

---

## 9. 既存プラグインの実装パターン（リファレンス）

### x-manager（最も機能が豊富）
- スキル数: 5, エージェント数: 5, コマンド数: 5
- 特徴: 多段階サブエージェント委譲、Edge Function連携、画像生成
- 参考: `reference/` フォルダに文章ガイドラインや例文を格納

### circle-manager / luma-manager / youtube-ideas-manager
- スキル数: 1, エージェント数: 1, コマンド数: 1
- 特徴: シンプルな1スキル構成、日次レポート生成パターン

### 共通パターン
- Supabase MCP の `execute_sql` でデータ取得
- サブエージェントに分析・レポート生成を委譲
- Markdown形式でレポートを `log/` に保存
- `config.local.md` で機密情報を管理

---

## 10. よくあるエラーと対処

| エラー | 原因 | 対処 |
|--------|------|------|
| マーケットプレイスの追加に失敗 | marketplace.json がない or 構造不正 | marketplace.json の存在と source パスを確認 |
| plugin.json と marketplace.json が同居 | 同じ .claude-plugin/ 内 | プラグインをサブディレクトリに移動 |
| source が `"."` | ルートをプラグインとして参照 | `"./plugin-dir"` に修正 |
| スキルが認識されない | SKILL.md フロントマター不正 | `name`, `description` の存在を確認 |
| コマンドが表示されない | commands/ がプラグインディレクトリ外 | プラグインサブディレクトリ内に配置 |
| バージョン不一致 | marketplace.json と plugin.json の version が異なる | 全ファイルのバージョンを同期 |

---

## 11. 公式リファレンス

| リソース | URL |
|---------|-----|
| プラグイン作成ドキュメント | https://code.claude.com/docs/en/plugins |
| マーケットプレイス作成ドキュメント | https://code.claude.com/docs/en/plugin-marketplaces |
| プラグインリファレンス（スキーマ） | https://code.claude.com/docs/en/plugins-reference |
| 公式マーケットプレイス | https://github.com/anthropics/claude-plugins-official |
