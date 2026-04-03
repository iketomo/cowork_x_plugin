# Claude Code 環境マッピング
最終更新: 2026-03-27

---

## プラグインの更新フロー

```
Dropbox (開発・編集)
    | git push
    v
GitHub (iketomo/cowork_x_plugin.git)
    | Claude Desktop でインストール/更新
    v
Windows: ~/.claude/plugins/cache/{plugin}/{version}/
         installed_plugins.json は Claude Desktop が自動管理
    | sync-plugins-to-wsl.sh（WSLを使う場合のみ）
    v
WSL:     ~/.claude/plugins/installed_plugins.json（/mnt/c/... パスに変換）
         プラグイン本体は Windows の cache を /mnt/c/ 経由で直接参照
```

**ポイント:**
- Windows 側はスクリプト不要。Claude Desktop が全自動管理
- WSL 側だけ、パス形式の違いを吸収するスクリプトが必要

---

## ファイル配置図

### Windows（Claude Code Desktop）

| パス | 種別 | 内容 |
|------|------|------|
| `C:\Users\{user}\.claude\` | 実体 | 設定ファイルの本体 |
| `  CLAUDE.md` | 実体 | グローバル指示 |
| `  rules/` | 実体 | コーディングルール等 |
| `  skills/` | 実体 | ユーザー定義スキル |
| `  commands/` | 実体 | ユーザー定義コマンド |
| `  agents/` | 実体 | ユーザー定義エージェント |
| `  settings.json` | 実体 | Claude Code 設定 |
| `  plugins/installed_plugins.json` | 実体 | Claude Desktop が自動管理（cache パス） |
| `  plugins/cache/` | 実体 | GitHub からDLしたプラグイン本体 |

### WSL（Ubuntu）

| パス | 種別 | リンク先 / 内容 |
|------|------|----------------|
| `~/.claude/` | 実体 | 独立ディレクトリ |
| `  CLAUDE.md` | symlink → | `/mnt/c/Users/{user}/.claude/CLAUDE.md` |
| `  rules/` | symlink → | `/mnt/c/Users/{user}/.claude/rules/` |
| `  skills/` | symlink → | `/mnt/c/Users/{user}/.claude/skills/` |
| `  commands/` | symlink → | `/mnt/c/Users/{user}/.claude/commands/` |
| `  agents/` | symlink → | `/mnt/c/Users/{user}/.claude/agents/` |
| `  settings.json` | **WSL独自** | パス・環境差のため Windows と共有しない（各OSで別ファイル） |
| `  settings.local.json` | symlink → | `/mnt/c/Users/{user}/.claude/settings.local.json` |
| `  hooks/` | symlink → | `/mnt/c/Users/{user}/.claude/hooks/` |
| `  teams/` | symlink → | `/mnt/c/Users/{user}/.claude/teams/` |
| `  plugins/` | **WSL独自** | `installed_plugins.json` のパス形式が異なるため |
| `  plugins/installed_plugins.json` | 実体 | `sync-plugins-to-wsl.sh` で生成 |

> シンボリックリンクで共有できるもの → そのまま共有（CLAUDE.md, rules, skills 等）
> ファイルの中身にパスが書いてあるもの → WSL独自で持つ（installed_plugins.json）
> `settings.json` も WSL 独自（Windows の設定をそのまま symlink するとパスやツール連携が合わないことがある）

---

## sync-plugins-to-wsl.sh

Windows 側の `installed_plugins.json` を読んで、パスを `/mnt/c/...` 形式に変換し WSL 側に書き出す。

```bash
# WSL から実行
bash /mnt/c/Users/{user}/Dropbox/Cursor/cowork/cowork_plugin/.syncsetup/sync-plugins-to-wsl.sh
```

| ステップ | 内容 |
|---------|------|
| 1 | WSL であることを確認 |
| 2 | Windows ユーザー名を `cmd.exe` で自動検出 |
| 3 | Windows 側の `installed_plugins.json` を読む |
| 4 | `C:\...` → `/mnt/c/...` にパス変換 |
| 5 | WSL 側の `installed_plugins.json` に書き出す |

---

## 別PC（ノートPC）での作業

Dropbox が同期されていれば、どのPCでも同じ手順で動く。
ユーザー名が違ってもスクリプトが `cmd.exe` 経由で自動検出する。

1. Claude Desktop でプラグインをインストール（GitHub 経由）
2. WSL が必要なら `sync-plugins-to-wsl.sh` を実行
