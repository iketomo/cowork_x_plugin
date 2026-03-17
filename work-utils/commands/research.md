---
description: テーマを指定して多段階リサーチ（設計→並列調査→統合→批判チェック→レポート化）を実行
argument-hint: [調査テーマ]
allowed-tools: ["Skill", "Read", "Agent", "Write", "Bash"]
---

# /research

テーマを受け取り、多段階リサーチを実行してレポートを作成します。

## 実行手順
1. `multi-stage-research` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を調査テーマとして渡す

## 使用例
- `/research AI Agentの最新動向` - 指定テーマで多段階リサーチを実行
- `/research` - 対話的にテーマを確認してからリサーチ開始
