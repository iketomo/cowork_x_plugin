#!/bin/bash
# =============================================================================
# setup-claude-plugins.sh
#
# Cowork プラグインを現在の環境用に設定するセットアップスクリプト
# 対応環境: Windows (Git Bash) / WSL / macOS
#
# 使い方:
#   bash /path/to/cowork_plugin/setup-claude-plugins.sh
#
# 何をするか:
#   1. 実行環境を自動検出 (Windows / WSL / Mac)
#   2. Dropbox の cowork_plugin ディレクトリを installPath として
#      ~/.claude/plugins/installed_plugins.json を生成
#   3. WSL の場合: ~/.claude がシンボリックリンクなら独立化
#      (CLAUDE.md / rules / skills / commands / agents / settings は
#       Windows ~/.claude へのリンクを維持)
#
# プラグインを追加・更新したら、このスクリプトを再実行してください。
# =============================================================================

set -e

# ─────────────────────────────────────────────────────────────────────────────
# このスクリプト自身の場所 = cowork_plugin ディレクトリ
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────────────────────
# 1. 環境検出
# ─────────────────────────────────────────────────────────────────────────────
detect_env() {
  if [[ "$(uname -s)" == "Linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "mac"
  else
    echo "windows"
  fi
}

ENV=$(detect_env)
echo "🔍 検出された環境: $ENV"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 2. パス設定
# ─────────────────────────────────────────────────────────────────────────────
case "$ENV" in
  wsl)
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then WIN_USER=$(basename "$HOME"); fi
    WIN_HOME="/mnt/c/Users/$WIN_USER"
    WIN_CLAUDE="$WIN_HOME/.claude"
    CLAUDE_DIR="$HOME/.claude"
    DROPBOX_PLUGINS="$WIN_HOME/Dropbox/Cursor/cowork/cowork_plugin"
    ;;
  mac)
    CLAUDE_DIR="$HOME/.claude"
    if [ -d "$HOME/Library/CloudStorage/Dropbox/Cursor/cowork/cowork_plugin" ]; then
      DROPBOX_PLUGINS="$HOME/Library/CloudStorage/Dropbox/Cursor/cowork/cowork_plugin"
    elif [ -d "$HOME/Dropbox/Cursor/cowork/cowork_plugin" ]; then
      DROPBOX_PLUGINS="$HOME/Dropbox/Cursor/cowork/cowork_plugin"
    else
      echo "❌ Dropbox パスが見つかりません。DROPBOX_PLUGINS を手動で設定してください。"
      exit 1
    fi
    ;;
  windows)
    CLAUDE_DIR="$HOME/.claude"
    DROPBOX_PLUGINS="$SCRIPT_DIR"
    # SCRIPT_DIR が cowork_plugin ディレクトリそのもの
    ;;
esac

if [ ! -d "$DROPBOX_PLUGINS" ]; then
  echo "❌ プラグインディレクトリが見つかりません:"
  echo "   $DROPBOX_PLUGINS"
  exit 1
fi

echo "📦 プラグインディレクトリ: $DROPBOX_PLUGINS"
echo "🏠 Claude 設定ディレクトリ: $CLAUDE_DIR"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 3. WSL: ~/.claude シンボリックリンクを解除して独立化
# ─────────────────────────────────────────────────────────────────────────────
if [ "$ENV" = "wsl" ] && [ -L "$CLAUDE_DIR" ]; then
  echo "━━━ WSL ~/.claude 独立化 ━━━"
  echo "現在: ~/.claude -> $(readlink $CLAUDE_DIR)"
  echo ""

  if [ ! -d "$HOME/.claude.pre-setup-bak" ]; then
    cp -rL "$CLAUDE_DIR" "$HOME/.claude.pre-setup-bak"
    echo "✓ バックアップ: ~/.claude.pre-setup-bak"
  else
    echo "  (バックアップ済み: ~/.claude.pre-setup-bak)"
  fi

  rm "$CLAUDE_DIR"
  mkdir -p "$CLAUDE_DIR"
  mkdir -p "$CLAUDE_DIR/plugins"

  echo ""
  echo "共有ファイルのシンボリックリンクを作成:"
  for item in CLAUDE.md rules skills commands agents settings.json settings.local.json hooks teams; do
    src="$WIN_CLAUDE/$item"
    dst="$CLAUDE_DIR/$item"
    if [ -e "$src" ] || [ -L "$src" ]; then
      ln -sf "$src" "$dst"
      echo "  ✓ ~/.claude/$item -> Windows/.claude/$item"
    fi
  done
  echo ""
  echo "✅ WSL ~/.claude 独立化完了"
  echo ""
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. installed_plugins.json を生成
# ─────────────────────────────────────────────────────────────────────────────
echo "━━━ installed_plugins.json を生成 ━━━"

INSTALLED_PLUGINS_JSON="$CLAUDE_DIR/plugins/installed_plugins.json"
mkdir -p "$(dirname "$INSTALLED_PLUGINS_JSON")"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
CURRENT_ENV="$ENV"
PLUGINS_DIR="$DROPBOX_PLUGINS"

# Node.js で JSON 生成
node << NODEEOF
const fs = require('fs');
const path = require('path');
const pluginsDir = '$PLUGINS_DIR';
const env = '$CURRENT_ENV';
const now = '$NOW';
const plugins = {};

const entries = fs.readdirSync(pluginsDir).sort();
for (const name of entries) {
  const pluginDir = pluginsDir + '/' + name;
  const pluginJson = pluginDir + '/.claude-plugin/plugin.json';
  try {
    if (!fs.statSync(pluginDir).isDirectory()) continue;
    if (!fs.existsSync(pluginJson)) continue;
  } catch(e) { continue; }

  const meta = JSON.parse(fs.readFileSync(pluginJson, 'utf8'));
  const version = meta.version || '1.0.0';

  let installPath;
  if (env === 'windows') {
    // Git Bash の /c/Users/... を C:\Users\... に変換
    installPath = pluginDir.replace(/^\/c\//, 'C:/').split('/').join(path.sep);
  } else {
    installPath = pluginDir;
  }

  const key = name + '@cowork-plugins-marketplace';
  plugins[key] = [{
    scope: 'user',
    installPath: installPath,
    version: version,
    installedAt: now,
    lastUpdated: now
  }];
  console.log('  ✓ ' + name + ' (v' + version + ')');
  console.log('    -> ' + installPath);
}

const result = { version: 2, plugins: plugins };
const out = '$INSTALLED_PLUGINS_JSON';
fs.writeFileSync(out, JSON.stringify(result, null, 2), 'utf8');
console.log('');
console.log('保存完了: ' + out);
NODEEOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 セットアップ完了！"
echo ""
echo "次のステップ:"
echo "  1. Claude Code を再起動（または新しいセッションを開始）"
echo "  2. スキルが認識されているか確認: /list-plugins"
echo ""
echo "プラグインを追加・更新したら再実行:"
echo "  bash \"$SCRIPT_DIR/setup-claude-plugins.sh\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
