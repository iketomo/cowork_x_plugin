---
description: Supabase長期メモリの検索・参照
argument-hint: [検索キーワード（任意）]
allowed-tools: ["Skill", "Read"]
---

# /memory-read

Supabaseの長期メモリ（memoriesテーブル）から過去の議論・知見を検索・参照します。

## 実行手順
1. `memory-read` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を検索キーワードとして渡す

## 使用例
- `/memory-read` - 最近の記録一覧を表示
- `/memory-read Dify` - 「Dify」に関する過去の記録を検索
- `/memory-read 技術` - カテゴリ「技術」の記録を検索
