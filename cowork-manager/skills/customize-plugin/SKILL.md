---
name: customize-plugin
description: >
  This skill should be used when the user wants to customize, configure, or adapt an existing Cowork plugin.
  Use when: "プラグインをカスタマイズ", "プラグインの設定を変えたい", "customize plugin",
  "configure plugin", "プラグインを組織に合わせて調整", "コネクタを設定したい",
  "プラグインのコマンドを変更", "set up plugin", "plugin-customizer", "customize-plugin".
version: 0.1.0
---

# プラグインカスタマイズ

既存のCoworkプラグインをカスタマイズする場合は、`plugin-customizer` エージェントに委譲する。

## エージェントへの委譲

`plugin-customizer` エージェントを起動して、以下の流れでカスタマイズを実施する:

1. **プラグインの特定** — カスタマイズ対象プラグインのファイルを探す
2. **モード判定** — 汎用セットアップ / 範囲を絞ったカスタマイズ / 全般的なカスタマイズ
3. **情報収集** — 知識MCPや対話を通じて変更内容を確定する
4. **変更の適用** — プラグインファイルを編集する
5. **パッケージング** — カスタマイズ済み `.plugin` ファイルを届ける

ユーザーが指定したプラグイン名と変更内容をエージェントに引き渡す。
