#!/bin/bash
# =============================================================================
# sync-plugins-to-wsl.sh
#
# Windows の Claude Desktop でインストール済みのプラグインを WSL でも使えるようにする
#
# 前提:
#   - Windows 側で Claude Desktop からプラグインをインストール/更新済み
#   - WSL の ~/.claude/ は独立化済み（CLAUDE.md 等は Windows へ symlink。
#     settings.json は Windows/WSL で別ファイル — 本スクリプトは触らない）
#
# やること:
#   1. Windows 側の installed_plugins.json を読み取る
#   2. installPath を /mnt/c/... 形式に変換する
#   3. WSL 側の installed_plugins.json に書き出す
#
# 使い方 (WSL から):
#   bash /mnt/c/Users/<ユーザー名>/Dropbox/Cursor/cowork/cowork_plugin/.syncsetup/sync-plugins-to-wsl.sh
#
# =============================================================================

set -e

# ─────────────────────────────────────────────────────────────────────────────
# 環境チェック
# ─────────────────────────────────────────────────────────────────────────────
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo "ERROR: This script is for WSL only."
  echo "  Windows -> Claude Desktop handles plugin installation automatically."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Windows ユーザー名を取得
# ─────────────────────────────────────────────────────────────────────────────
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
if [ -z "$WIN_USER" ]; then
  echo "ERROR: Could not detect Windows username."
  exit 1
fi

WIN_CLAUDE="/mnt/c/Users/$WIN_USER/.claude"
WSL_CLAUDE="$HOME/.claude"
export WIN_SOURCE="$WIN_CLAUDE/plugins/installed_plugins.json"
export WSL_TARGET="$WSL_CLAUDE/plugins/installed_plugins.json"

echo "=== sync-plugins-to-wsl ==="
echo ""
echo "  Windows user:   $WIN_USER"
echo "  Windows source: $WIN_SOURCE"
echo "  WSL target:     $WSL_TARGET"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Windows 側の installed_plugins.json が存在するか
# ─────────────────────────────────────────────────────────────────────────────
if [ ! -f "$WIN_SOURCE" ]; then
  echo "ERROR: Windows installed_plugins.json not found:"
  echo "  $WIN_SOURCE"
  echo ""
  echo "  Install plugins via Claude Desktop first."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# WSL 側の ~/.claude/plugins/ ディレクトリを確保
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p "$WSL_CLAUDE/plugins"

# ─────────────────────────────────────────────────────────────────────────────
# パス変換して書き出し
#
# Windows パス例:
#   C:\Users\tomoh\.claude\plugins\cache\cowork-plugins-marketplace\x-manager\1.0.6
#   C:/Users/tomoh/.claude/plugins/cache/cowork-plugins-marketplace/x-manager/1.0.6
#
# 変換後 (WSL):
#   /mnt/c/Users/tomoh/.claude/plugins/cache/cowork-plugins-marketplace/x-manager/1.0.6
# ─────────────────────────────────────────────────────────────────────────────
node << 'NODEEOF'
const fs = require('fs');

const winSource = process.env.WIN_SOURCE;
const wslTarget = process.env.WSL_TARGET;

const raw = fs.readFileSync(winSource, 'utf8').replace(/^\uFEFF/, '');
const data = JSON.parse(raw);

function winPathToWsl(winPath) {
  if (!winPath) return winPath;
  // Normalize backslashes to forward slashes
  let p = winPath.replace(/\\/g, '/');
  // C:/Users/... -> /mnt/c/Users/...
  p = p.replace(/^([A-Za-z]):\//, (_, drive) => '/mnt/' + drive.toLowerCase() + '/');
  return p;
}

const converted = {
  version: data.version,
  plugins: {}
};

let count = 0;
for (const [key, entries] of Object.entries(data.plugins)) {
  converted.plugins[key] = entries.map(entry => {
    const wslPath = winPathToWsl(entry.installPath);
    // Verify the path is accessible
    const accessible = fs.existsSync(wslPath);
    const status = accessible ? 'OK' : 'WARN: not accessible';
    console.log('  ' + key.split('@')[0] + ' v' + entry.version);
    console.log('    Win:  ' + entry.installPath);
    console.log('    WSL:  ' + wslPath + ' [' + status + ']');
    count++;
    return {
      ...entry,
      installPath: wslPath
    };
  });
}

fs.writeFileSync(wslTarget, JSON.stringify(converted, null, 2), 'utf8');

console.log('');
console.log('Synced ' + count + ' plugins.');
console.log('Saved: ' + wslTarget);
NODEEOF

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code in WSL"
echo "  2. Verify: /list-plugins"
echo ""
