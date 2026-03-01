---
description: X投稿パフォーマンスの日次レポートを生成する
allowed-tools: ["Task", "Skill", "Read", "Write", "WebSearch"]
---

# X日次レポート生成

x-daily-reportスキルを使って、X投稿パフォーマンスの日次レポートを生成してください。

## 実行手順

1. Supabase MCP の `execute_sql`（project_id: `iltymrnkqchixvtpvewm`）で、x-daily-reportスキルに定義されたSQLを実行してデータを取得
2. 取得したデータをサブエージェント（x-daily-analyzer）に渡してレポートを生成
3. 完了後、レポートファイルのパスをユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
