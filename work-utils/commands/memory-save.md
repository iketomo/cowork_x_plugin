---
description: Supabase長期メモリへの保存
argument-hint: [保存内容（任意）]
allowed-tools: ["Skill", "Read", "AskUserQuestion"]
---

# /memory-save

Supabaseの長期メモリ（memoriesテーブル）に議論・知見・設計決定を保存します。

## 実行手順
1. `memory-save` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を保存対象として渡す

## 使用例
- `/memory-save` - 直前の議論をSupabase長期メモリに保存
- `/memory-save Difyの設計方針` - 指定内容を保存
