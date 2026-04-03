# プラグイン同期 手順書

## コマンド（WSL から実行）

```bash
bash /mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_plugin/.syncsetup/sync-plugins-to-wsl.sh
```

実行後、WSL の Claude Code を再起動。

---

## いつ実行するか

Claude Desktop でプラグインをインストール/更新した後（WSLでも使いたい場合）。

---

## 仕組み

```
Windows の installed_plugins.json
  installPath: "C:\Users\tomoh\.claude\plugins\cache\...\x-manager\1.0.8"

    ↓ スクリプトがパスを変換

WSL の installed_plugins.json
  installPath: "/mnt/c/Users/tomoh/.claude/plugins/cache/.../x-manager/1.0.8"
```

プラグイン本体のファイルはコピーしない。WSL は `/mnt/c/` 経由で Windows の cache を直接読む。
Windows 側はスクリプト不要（Claude Desktop が自動管理）。
