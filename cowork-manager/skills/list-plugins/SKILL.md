---
name: list-plugins
description: >
  This skill should be used when the user wants to list, browse, or understand installed Cowork plugins.
  Use when: "プラグイン一覧", "どんなプラグインが入ってる", "インストール済みプラグインを確認",
  "プラグインの機能を教えて", "何のプラグインが使える", "list plugins", "show plugins",
  "プラグインを見せて", "plugin-lister", "list-plugins".
version: 0.1.0
---

# プラグイン一覧・管理

インストール済みプラグインの確認・管理は、`plugin-lister` エージェントに委譲する。

## エージェントへの委譲

`plugin-lister` エージェントを起動して、以下を実施する:

- **全プラグイン一覧**: インストール済みプラグインを検索し、名前・バージョン・概要を整理して表示
- **スキル/コマンド要約**: 各プラグインのSKILL.md・コマンドファイルを読み取り、機能一覧を表示
- **特定プラグインの詳細**: プラグイン名が指定された場合、そのプラグインの詳細情報を提示

ユーザーが特定プラグインを指定した場合はその名前をエージェントに引き渡す。
