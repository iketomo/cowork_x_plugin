---
description: グロースログ（反省・学び）の一覧表示・検索・取得
argument-hint: [検索キーワード（任意）]
allowed-tools: ["Skill", "Read"]
---

# /growthlog-read

Supabaseに保存済みのグロースログ（反省・学び・成功体験）を読み込み・検索・表示します。

## 実行手順
1. `growthlog-read` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容を検索キーワードとして渡す

## 使用例
- `/growthlog-read` - 最近のグロースログ一覧を表示
- `/growthlog-read マインド` - 「マインド」カテゴリの学びを検索
- `/growthlog-read 家族` - 「家族」に関する学びを検索
- `/growthlog-read 復習` - 復習が必要な学びを抽出
