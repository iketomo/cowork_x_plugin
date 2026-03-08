---
description: 保存済みリサーチ・調査結果の一覧表示・検索・取得
argument-hint: [検索キーワード（任意）]
allowed-tools: ["Skill", "Read"]
---

# /research-read

Supabaseに保存済みのリサーチ・調査結果を読み込み・検索・表示します。

## 実行手順
1. `research-read` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を検索キーワードとして渡す

## 使用例
- `/research-read` - 保存済みリサーチ一覧を表示
- `/research-read RAG` - 「RAG」を含むリサーチを検索
- `/research-read LLM比較` - 特定リサーチの詳細を取得
