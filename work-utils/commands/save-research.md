---
description: 会話中のリサーチ・調査結果をSupabaseに構造化して保存
argument-hint: [保存対象の補足（任意）]
allowed-tools: ["Skill", "Read", "Task"]
---

# /save-research

会話の中で得られたリサーチ・調査結果をSupabaseのresearch_itemsテーブルに構造化して保存します。

## 実行手順
1. `save-research` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を保存対象の補足情報として考慮する

## 使用例
- `/save-research` - 直前の会話で調査・議論した内容を保存
- `/save-research LLM比較の調査` - 保存対象を指定して保存
