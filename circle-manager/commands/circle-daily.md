---
description: Circleコミュニティ「アイザック」の日次レポートを生成する
allowed-tools: ["Task", "Skill", "Read", "Write"]
---

# Circle日次レポート生成

circle-daily-reportスキルを使って、アイザックの日次レポートを生成してください。

## 実行手順

1. `config.local.md` からSupabaseプロジェクトIDを取得
2. Supabase MCP の `execute_sql` で、circle-daily-reportスキルに定義されたSQL（Step 1〜5）を実行してデータを取得
3. 取得したデータをサブエージェント（circle-daily-analyzer）に渡してレポートを生成
4. 完了後、レポートファイルのパスと未対応コメント件数をユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
