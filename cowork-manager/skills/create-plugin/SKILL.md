---
name: create-plugin
description: >
  This skill should be used when the user wants to create a new Cowork plugin from scratch.
  Use when: "プラグインを作って", "新しいプラグインを作成したい", "create a plugin",
  "build a plugin", "make a new plugin", "scaffold a plugin", "プラグインをゼロから作りたい",
  "plugin-creator", "create-plugin".
version: 0.1.0
---

# プラグイン新規作成

新しいCoworkプラグインを作成する場合は、`plugin-creator` エージェントに委譲する。

## エージェントへの委譲

`plugin-creator` エージェントを起動して、以下の5フェーズを通じてプラグインを設計・実装する:

1. **ディスカバリー** — ユーザーが何を作りたいかを理解する
2. **コンポーネント計画** — 必要なコンポーネントタイプを決定する
3. **設計・詳細化** — 各コンポーネントを仕様化する
4. **実装** — 全プラグインファイルを作成する
5. **レビューとパッケージング** — `.plugin` ファイルを届ける

ユーザーの依頼内容（プラグイン名、機能概要、外部ツール連携の有無など）をそのままエージェントに引き渡す。
