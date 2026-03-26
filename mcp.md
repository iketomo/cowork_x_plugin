# Claude Code MCP & CLI ツール セットアップガイド

> 別PCでClaude Codeの環境を再現するための手順書（2026-03-22 時点）

---

## 1. グローバルMCPサーバー（`~/.claude.json` の `mcpServers`）

Claude Codeの全プロジェクトで利用可能なMCPサーバー。`~/.claude.json` の `mcpServers` キーに設定する。

> **現在の運用状況（2026-03-22）**: 現在の `~/.claude.json` に `mcpServers` は定義されていない。下記の各サービス（Supabase, Slack, Notion, Gmail, Google Calendar, Firecrawl, Cloudflare 等）は **Claude.ai コネクタ（セクション2）** 経由で利用中。`mcpServers` に設定が必要なのは context7, notebooklm, memory, workspace-mcp, google-sheets のみ（これらは Claude.ai コネクタに存在しない）。

### 設定方法

```bash
claude mcp add <name> -- <command> <args...>
# または ~/.claude.json を直接編集
```

### 一覧と設定

#### 1-1. context7（ライブラリドキュメント検索）

```json
"context7": {
  "type": "stdio",
  "command": "npx",
  "args": ["@upstash/context7-mcp@latest"],
  "env": {}
}
```

**インストール**: npm/npx が使えればOK（自動ダウンロード）

#### 1-2. notebooklm（Google NotebookLM連携）

```json
"notebooklm": {
  "type": "stdio",
  "command": "notebooklm-mcp",
  "args": ["--transport", "stdio"],
  "env": {}
}
```

**インストール**:
```bash
# uv (推奨)
uv tool install notebooklm-mcp-cli

# 認証
nlm login
```

#### 1-3. notion（Notion連携）

```json
"notion": {
  "type": "http",
  "url": "https://mcp.notion.com/mcp"
}
```

**インストール**: 不要（Notion公式のHTTP MCP）。初回接続時にブラウザでOAuth認証。

#### 1-4. slack（Slack連携）

```json
"slack": {
  "type": "http",
  "url": "https://mcp.slack.com/mcp",
  "oauth": {
    "clientId": "7139628693671.10568346411057",
    "callbackPort": 8080
  }
}
```

**インストール**: 不要（Slack公式のHTTP MCP）。初回接続時にブラウザでOAuth認証。

#### 1-5. firecrawl（Webスクレイピング・検索）

```json
"firecrawl": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "firecrawl-mcp"],
  "env": {}
}
```

**インストール**: npm/npx が使えればOK。
**注意**: FIRECRAWL_API_KEY が必要な場合は `env` に追加。現在は未設定（無料枠 or Claude.ai側のコネクタで代用）。

#### 1-6. memory（ナレッジグラフ長期メモリ）

```json
"memory": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-memory", "--data-dir", "/home/tomoh/.claude-memory"],
  "env": {}
}
```

**インストール**: npm/npx が使えればOK。
**注意**: `--data-dir` のパスは環境に合わせて変更すること。

#### 1-7. supabase_remote（Supabase MCP）

```json
"supabase_remote": {
  "type": "http",
  "url": "https://mcp.supabase.com/mcp?project_ref=<PROJECT_REF>&read_only=false"
}
```

**インストール**: 不要（Supabase公式のHTTP MCP）。初回接続時にブラウザで認証。
**注意**: `project_ref` は自分のSupabaseプロジェクトIDに置換。

#### 1-8. google-sheets（Googleスプレッドシート）

```json
"google-sheets": {
  "command": "npx",
  "args": [
    "mcp-remote",
    "https://google-sheets-mcp.<YOUR_DOMAIN>.workers.dev/mcp",
    "--header",
    "Authorization:Bearer <YOUR_TOKEN>"
  ]
}
```

**インストール**: npm/npx が使えればOK。
**注意**: Cloudflare Workers上のカスタムデプロイ。URLとトークンは環境固有。

#### 1-9. workspace-mcp（Google Workspace全体連携）

```json
"workspace-mcp": {
  "type": "http",
  "url": "http://localhost:8000/mcp"
}
```

**インストール**:
```bash
# リポジトリをクローン
git clone https://github.com/taylorwilsdon/google_workspace_mcp.git ~/google_workspace_mcp

# Docker Composeで起動
cd ~/google_workspace_mcp
docker-compose up -d

# Google OAuth2 認証が必要（初回セットアップはREADME参照）
```

**注意**: ローカルでDockerサーバーとして常駐させる必要あり。

---

## 2. Claude.ai MCPコネクタ（クラウド側）

Claude.aiアカウントに紐づくクラウドMCPコネクタ。Claude Codeの `settings` > `Integrations` または claude.ai Web UIから設定。

| コネクタ名 | 用途 |
|-----------|------|
| **Supabase** | DB操作・SQL実行（read_only=false） |
| **Slack** | チャンネル検索・メッセージ送信 |
| **Gmail** | メール検索・下書き作成 |
| **Google Calendar** | 予定の確認・作成 |
| **Notion** | ページ検索・作成・更新 |
| **Cloudflare Developer Platform** | Workers/D1/KV/R2管理 |
| **Firecrawl** | Webスクレイピング（クラウド版） |

**設定方法**: Claude.ai にログインし、Settings > Integrations から各サービスを接続。アカウント単位の設定なので、同じAnthropicアカウントでログインすれば別PCでも自動的に利用可能。

---

## 3. CLI ツール

### 3-1. gws（Google Workspace CLI）

```bash
# Windows (npm global)
npm install -g gws-cli
# ※パッケージ名は要確認、Windows側にインストール済み
```

**用途**: Google Sheets/Drive/Calendar/Gmail をCLIから操作。スキル `gws-read` / `fetch-gsheet` で使用。

### 3-2. nlm / notebooklm-mcp（NotebookLM CLI）

```bash
# uv でインストール（推奨）
uv tool install notebooklm-mcp-cli

# 認証
nlm login
```

**用途**: NotebookLMのノートブック操作、ソース追加、オーディオ生成など。

---

## 4. 前提ツール

以下がインストール済みであること：

| ツール | インストール |
|--------|------------|
| **Node.js + npm** | `nvm install --lts` or 公式インストーラ |
| **npx** | npm に付属 |
| **pnpm** | `npm install -g pnpm` |
| **uv** (Python) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **Docker** | Docker Desktop or WSL2上のDocker |
| **jq** | `apt install jq` or `choco install jq` |
| **git** | 標準インストール |
| **gh** (GitHub CLI) | `apt install gh` or `choco install gh` |

---

## 5. セットアップ手順（別PCでの再現）

### Step 1: Claude Codeインストール

```bash
npm install -g @anthropic-ai/claude-code
```

### Step 2: グローバルMCPサーバーを登録

```bash
# context7
claude mcp add context7 -- npx @upstash/context7-mcp@latest

# notebooklm（先にuv tool install notebooklm-mcp-cliを実行）
claude mcp add notebooklm -- notebooklm-mcp --transport stdio

# notion
claude mcp add notion --transport http --url https://mcp.notion.com/mcp

# slack
# ※OAuth設定付きのため、~/.claude.json を直接編集するのが確実
# 上記1-4のJSONを mcpServers に追加

# firecrawl
claude mcp add firecrawl -- npx -y firecrawl-mcp

# memory
claude mcp add memory -- npx -y @modelcontextprotocol/server-memory --data-dir ~/.claude-memory

# supabase_remote
claude mcp add supabase_remote --transport http --url "https://mcp.supabase.com/mcp?project_ref=<YOUR_PROJECT_REF>&read_only=false"

# google-sheets, workspace-mcp は環境固有のためJSON直接編集
```

### Step 3: Claude.ai コネクタを接続

1. https://claude.ai にログイン
2. Settings > Integrations へ移動
3. 以下を順に接続：Supabase, Slack, Gmail, Google Calendar, Notion, Cloudflare, Firecrawl

### Step 4: CLIツールをインストール

```bash
uv tool install notebooklm-mcp-cli
nlm login
npm install -g gws-cli  # パッケージ名要確認
```

### Step 5: workspace-mcp（Google Workspace）のセットアップ

```bash
git clone https://github.com/taylorwilsdon/google_workspace_mcp.git ~/google_workspace_mcp
cd ~/google_workspace_mcp
# README.mdに従ってOAuth認証とDocker起動
docker-compose up -d
```

### Step 6: Cowork Pluginのインストール

```bash
# settings.json の extraKnownMarketplaces と enabledPlugins を設定
# または Claude Code 内から /list-plugins で確認・有効化
```

---

## 5-7. Cowork Plugin のセットアップ（詳細）

### マーケットプレイスの登録

`~/.claude/settings.json` の `extraKnownMarketplaces` に以下を追加：

```json
"extraKnownMarketplaces": {
  "claude-plugins-official": {
    "source": {
      "source": "github",
      "repo": "anthropics/claude-plugins-official"
    }
  },
  "cowork-plugins-marketplace": {
    "source": {
      "source": "git",
      "url": "https://github.com/iketomo/cowork_x_plugin.git"
    }
  }
}
```

### プラグインの有効化

`~/.claude/settings.json` の `enabledPlugins` に以下を追加：

```json
"enabledPlugins": {
  "circle-manager@cowork-plugins-marketplace": true,
  "cowork-manager@cowork-plugins-marketplace": true,
  "luma-manager@cowork-plugins-marketplace": true,
  "work-utils@cowork-plugins-marketplace": true,
  "x-manager@cowork-plugins-marketplace": true,
  "youtube-ideas-manager@cowork-plugins-marketplace": true
}
```

---

## 5-8. settings.json の全体構成

`~/.claude/settings.json` の完全な設定テンプレート（現在の本番設定）：

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "model": "opus[1m]",
  "permissions": {
    "allow": [
      "Read", "Edit", "Write",
      "WebFetch(*)", "WebSearch",
      "Bash(find:*)", "Bash(ls:*)", "Bash(cd:*)", "Bash(pwd:*)",
      "Bash(mkdir:*)", "Bash(cp:*)", "Bash(mv:*)", "Bash(touch:*)",
      "Bash(cat:*)", "Bash(head:*)", "Bash(tail:*)", "Bash(wc:*)",
      "Bash(sort:*)", "Bash(uniq:*)", "Bash(diff:*)",
      "Bash(grep:*)", "Bash(rg:*)", "Bash(sed:*)", "Bash(awk:*)",
      "Bash(cut:*)", "Bash(tr:*)", "Bash(tee:*)", "Bash(xargs:*)",
      "Bash(echo:*)", "Bash(printf:*)",
      "Bash(which:*)", "Bash(whoami:*)", "Bash(env:*)", "Bash(export:*)",
      "Bash(dirname:*)", "Bash(basename:*)", "Bash(realpath:*)", "Bash(readlink:*)",
      "Bash(stat:*)", "Bash(file:*)", "Bash(chmod:*)",
      "Bash(tar:*)", "Bash(zip:*)", "Bash(unzip:*)",
      "Bash(curl:*)", "Bash(wget:*)", "Bash(jq:*)",
      "Bash(git *)", "Bash(gh *)",
      "Bash(node:*)", "Bash(node *)",
      "Bash(npm *)", "Bash(npx *)", "Bash(pnpm *)", "Bash(yarn *)", "Bash(bun *)",
      "Bash(python:*)", "Bash(python *)", "Bash(pip *)", "Bash(pip3 *)",
      "Bash(uv *)", "Bash(poetry *)", "Bash(pytest *)",
      "Bash(cargo *)", "Bash(rustc *)", "Bash(go *)",
      "Bash(docker *)", "Bash(docker-compose *)",
      "Bash(make *)", "Bash(cmake *)",
      "Bash(nlm:*)", "Bash(nlm *)",
      "Bash(tmux *)", "Bash(tree:*)", "Bash(du:*)", "Bash(df:*)",
      "Bash(date:*)", "Bash(sleep:*)", "Bash(true:*)", "Bash(false:*)",
      "Bash(test:*)", "Bash([:*)",
      "Bash(rm -rf ~/.claude/teams:*)", "Bash(rm -rf ~/.claude/tasks:*)",
      "mcp__slack__slack_search_channels",
      "mcp__slack__slack_read_channel",
      "mcp__slack__slack_read_thread",
      "mcp__slack__slack_search_public",
      "mcp__slack__slack_search_public_and_private",
      "mcp__slack__slack_send_message",
      "mcp__notion__*",
      "mcp__notebooklm__*",
      "mcp__memory__*",
      "mcp__context7__*",
      "mcp__firecrawl__*",
      "mcp__workspace-mcp__*",
      "mcp__supabase_remote__*",
      "mcp__google-sheets__*"
    ],
    "deny": [
      "Bash(rm -rf /*)",
      "Bash(rm -rf /:*)",
      "Bash(git push --force *)",
      "Bash(git reset --hard *)",
      "Bash(git clean -f *)",
      "Bash(> /dev/*)"
    ],
    "defaultMode": "bypassPermissions"
  },
  "skipDangerousModePermissionPrompt": true,
  "statusLine": {
    "type": "command",
    "command": "bash /home/tomoh/.claude/statusline-command.sh"
  },
  "enabledPlugins": { ... },
  "extraKnownMarketplaces": { ... }
}
```

**主要設定の説明**：

| キー | 値 | 説明 |
|------|-----|------|
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `"1"` | エージェントチーム機能（Teams/Send Message）を有効化 |
| `model` | `"opus[1m]"` | デフォルトモデル（Opus 1M コンテキスト） |
| `permissions.defaultMode` | `"bypassPermissions"` | ツール実行の確認プロンプトをデフォルトでスキップ |
| `skipDangerousModePermissionPrompt` | `true` | bypassPermissions モード起動時の警告をスキップ |
| `statusLine` | command 型 | ステータスバーにカスタムコマンド出力を表示 |

---

## 6. 設定ファイル一覧

| ファイル | 場所 | 内容 |
|---------|------|------|
| `~/.claude.json` | グローバル | MCPサーバー定義、プロジェクト設定 |
| `~/.claude/settings.json` | グローバル | 権限、モデル、プラグイン、フック |
| `~/.claude/CLAUDE.md` | グローバル | グローバル行動方針 |
| `~/.claude/rules/*.md` | グローバル | ルールファイル群 |
| `~/.claude/agents/*.md` | グローバル | カスタムエージェント定義 |
| `~/.claude-memory/` | グローバル | memory MCPのデータ保存先 |
| `<project>/.mcp.json` | プロジェクト | プロジェクト固有MCP（現在は未使用） |
| `<project>/CLAUDE.md` | プロジェクト | プロジェクト固有の指示 |

---

## 7. 注意事項

- **機密情報**: `supabase_remote` のURL、`google-sheets` のトークンなどは環境固有。このファイルをGitにpushする場合はトークンをマスクすること
- **OAuth認証**: Notion, Slack, Supabase（Claude.ai版）は初回接続時にブラウザ認証が必要
- **workspace-mcp**: Dockerが必要。WSL2環境ではDocker Desktop for Windowsとの連携を確認
- **Windows環境**: `curl -sk` フラグ必須、`python3` → `python`、一時ファイルは `C:/tmp/` を使用（rules/windows-environment.md 参照）
