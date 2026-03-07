---
description: 保存済みアンケートサマリの一覧表示・検索・取得
argument-hint: [アンケート名やキーワード（任意）]
allowed-tools: ["Skill", "Read"]
---

# /enquete-read

Supabaseに保存済みのアンケート・インタビューサマリを読み込み・検索・表示します。

## 実行手順
1. `enquete-read` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を検索キーワードまたはアンケート名として渡す

## 使用例
- `/enquete-read` - 登録済みアンケート一覧を表示
- `/enquete-read 満足度` - 「満足度」を含むサマリを横断検索
- `/enquete-read 3月ミートアップ` - 特定アンケートの全サマリを取得
