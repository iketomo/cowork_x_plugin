---
description: 反省・学び・成功体験をグロースログとしてSupabaseに保存
argument-hint: [保存したい内容（任意）]
allowed-tools: ["Skill", "Read", "Task"]
---

# /growthlog-save

反省・学び・成功体験をSupabaseのgrowth_log_learningsテーブルに構造化して保存します。

## 実行手順
1. `growthlog-save` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を保存対象のテキストとして渡す

## 使用例
- `/growthlog-save` - 直前の会話で語った反省・学びを保存
- `/growthlog-save 今日は朝の時間を有効活用できた` - 指定した内容を保存
