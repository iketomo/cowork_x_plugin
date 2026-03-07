---
description: Supabase長期メモリへの保存・検索・活用
argument-hint: [保存内容や検索キーワード（任意）]
allowed-tools: ["Skill", "Read", "AskUserQuestion"]
---

# /memory

Supabaseの長期メモリ（memoriesテーブル）に議論・知見を保存、または過去の記録を検索・活用します。

## 実行手順
1. `memory-manager` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を保存対象または検索キーワードとして渡す

## 使用例
- `/memory 保存` - 直前の議論をSupabase長期メモリに保存
- `/memory Dify` - 「Dify」に関する過去の記録を検索
- `/memory` - 最近の記録一覧を表示
