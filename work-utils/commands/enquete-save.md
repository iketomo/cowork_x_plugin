---
description: アンケート・インタビューの生データを分析し、構造化サマリとしてSupabaseに保存
argument-hint: [データソースの説明（任意）]
allowed-tools: ["Skill", "Read", "Task", "AskUserQuestion"]
---

# /enquete-save

アンケート・インタビュー等のリサーチデータを分析し、「1示唆 = 1レコード」の構造化サマリとしてSupabaseに保存します。

## 実行手順
1. `enquete-save` スキルを Skill ツールで呼び出す
2. $ARGUMENTS が指定されている場合は、その内容をデータソースの補足情報として考慮する

## 使用例
- `/enquete-save` - 直前の会話で共有されたアンケートデータを保存
- `/enquete-save 3月のミートアップアンケート` - データソースを指定して保存
