# Claude Code 環境マッピング
最終更新: 2026-03-19

---

## 実態ファイル / シンボリックリンク 全体図

### Windows デスクトップ（Claude Code Desktop）

| パス | 種別 | 内容 |
|------|------|------|
| `C:\Users\tomoh\.claude\` | **実体ディレクトリ** | すべての設定ファイルの本体 |
| `C:\Users\tomoh\.claude\CLAUDE.md` | **実体ファイル** | グローバル指示 |
| `C:\Users\tomoh\.claude\rules\` | **実体ディレクトリ** | コーディングルール等 |
| `C:\Users\tomoh\.claude\skills\` | **実体ディレクトリ** | ユーザー定義スキル |
| `C:\Users\tomoh\.claude\commands\` | **実体ディレクトリ** | ユーザー定義コマンド |
| `C:\Users\tomoh\.claude\agents\` | **実体ディレクトリ** | ユーザー定義エージェント |
| `C:\Users\tomoh\.claude\settings.json` | **実体ファイル** | Claude Code 設定 |
| `C:\Users\tomoh\.claude\plugins\installed_plugins.json` | **実体ファイル** | installPath = Dropbox の各プラグイン（後述） |
| `C:\Users\tomoh\Dropbox\Cursor\cowork\cowork_plugin\` | **実体ディレクトリ** | プラグイン本体（Dropbox同期・全環境の真実の源泉） |

---

### WSL（Ubuntu）

| パス | 種別 | リンク先 / 内容 |
|------|------|----------------|
| `/home/tomoh/.claude/` | **実体ディレクトリ** | ※以前はシンボリックリンク → 2026-03-19 に独立化済み |
| `~/.claude/CLAUDE.md` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/CLAUDE.md` |
| `~/.claude/rules/` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/rules/` |
| `~/.claude/skills/` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/skills/` |
| `~/.claude/commands/` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/commands/` |
| `~/.claude/agents/` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/agents/` |
| `~/.claude/settings.json` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/settings.json` |
| `~/.claude/hooks/` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/hooks/` |
| `~/.claude/teams/` | シンボリックリンク → | `/mnt/c/Users/tomoh/.claude/teams/` |
| `~/.claude/plugins/installed_plugins.json` | **実体ファイル（WSL独自）** | installPath = `/mnt/c/Users/tomoh/Dropbox/.../各プラグイン` |
| `/mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_plugin/` | **実体ディレクトリ** | プラグイン本体（Windows側Dropboxと同一場所） |

> **ポイント:** CLAUDE.md / rules / skills / commands / agents / settings は Windows と共有。
> `plugins/installed_plugins.json` だけ WSL 独自（パス形式が `/mnt/c/...`）。

---

### プラグインの真実の源泉（Dropbox）

```
C:\Users\tomoh\Dropbox\Cursor\cowork\cowork_plugin\
  circle-manager/
    .claude-plugin/plugin.json   ← バージョン情報
    skills/ commands/ agents/    ← プラグイン本体
  cowork-manager/
  luma-manager/
  work-utils/
  x-manager/
  youtube-ideas-manager/
  setup-claude-plugins.ps1       ← Windows (PowerShell) 用セットアップ
  setup-claude-plugins.sh        ← WSL / macOS 用セットアップ
  CLAUDECODEマッピング.md        ← このファイル
```

Dropbox が同期されているため、全マシンで同じプラグインファイルを参照できる。
`installed_plugins.json` だけ各環境で独自に持ち、環境に合ったパスを記載する。

---

## スクリプト一覧

### `setup-claude-plugins.ps1` ← **Windows PowerShell 用（推奨）**

**場所:** `cowork_plugin/setup-claude-plugins.ps1`

PowerShell から実行する Windows 専用セットアップスクリプト。

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\tomoh\Dropbox\Cursor\cowork\cowork_plugin\setup-claude-plugins.ps1"
```

| ステップ | 内容 |
|---------|------|
| 1. パス設定 | `$env:USERPROFILE\.claude` を Claude 設定ディレクトリとして自動設定 |
| 2. プラグインスキャン | `cowork_plugin/` 配下の `.claude-plugin/plugin.json` を読んで全プラグインを検出 |
| 3. JSON 生成 | Windows バックスラッシュパスで `installed_plugins.json` を書き出す |

> **なぜ `.ps1` が必要か:**
> PowerShell の `bash` は Git Bash 経由で Node.js を呼ぶが、そのとき `/c/Users/...` パスを
> `C:\c\Users\...` と誤解釈する。PowerShell ネイティブスクリプトならパス問題が起きない。

---

### `setup-claude-plugins.sh` ← **WSL / macOS 用**

**場所:** `cowork_plugin/setup-claude-plugins.sh`

WSL または macOS の bash から実行するセットアップスクリプト。

```bash
# WSL から実行
bash /mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh

# macOS から実行
bash ~/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh
```

| ステップ | 内容 |
|---------|------|
| 1. 環境検出 | WSL / macOS を自動判別 |
| 2. Dropbox パス特定 | Windows ユーザー名を自動取得し `/mnt/c/Users/{name}/...` を構築 |
| 3. WSL のみ: `~/.claude` 独立化 | シンボリックリンクを解除し実ディレクトリに変換。共有ファイルは Windows `.claude` への個別リンクとして維持 |
| 4. JSON 生成 | `/mnt/c/...` パスで `installed_plugins.json` を書き出す |

---

### `x-manager/scripts/test_x_generate_image.sh` ← 動作確認用（通常は不要）

Supabase Edge Function `x-generate-image` の動作確認スクリプト。
Edge Function をデプロイ・更新した後の確認時のみ使用。

> GEMINI_API_KEY が Supabase Secrets に設定されていないと Test 2 は失敗する。

---

## 今やること（このマシン）

- [x] Windows: `installed_plugins.json` を Dropbox パスに更新済み
- [x] WSL: `~/.claude` の独立化 + `installed_plugins.json` を `/mnt/c/...` パスで生成済み
- [x] PowerShell スクリプト動作確認済み（文字化け修正済み）
- [ ] **Claude Code（デスクトップ / WSL）を再起動** → スキルが認識されるか確認

---

## 別PC（ノートPC）初回セットアップ

Dropbox が同期されていれば、以下を実行するだけ。ユーザー名が違っても自動検出する。

**Windows（PowerShell）:**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\{ユーザー名}\Dropbox\Cursor\cowork\cowork_plugin\setup-claude-plugins.ps1"
```

**WSL:**
```bash
bash /mnt/c/Users/{ユーザー名}/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh
```

---

## 定期メンテ（プラグイン追加・更新のたびに）

### 正しい更新フロー

```
1. ClaudeCowork（デスクトップアプリ）でプラグインを更新
   └ cowork_plugin/ のファイルが更新される（Dropboxに反映）
   └ ⚠️ installed_plugins.json がキャッシュパスに書き戻される

2. Windows PowerShell でスクリプト実行
   └ installed_plugins.json を Dropboxパスに上書き修正

3. WSL でスクリプト実行
   └ WSL側の installed_plugins.json を /mnt/c/ パスに上書き修正

4. 各環境の Claude Code を再起動
```

> **なぜ 2・3 が必要か:**
> ClaudeCowork の更新処理が `installed_plugins.json` を
> `~/.claude/plugins/cache/...` のキャッシュパスに書き戻してしまう。
> スクリプト実行で Dropbox パスに修正し直す。

```powershell
# Windows（PowerShell）
powershell -ExecutionPolicy Bypass -File "C:\Users\tomoh\Dropbox\Cursor\cowork\cowork_plugin\setup-claude-plugins.ps1"
```

```bash
# WSL
bash /mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh
```
