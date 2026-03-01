---
description: Circleコミュニティ「アイザック」の日次レポートを生成する
allowed-tools: ["Task", "Skill", "Read", "Write"]
---

# Circle日次レポート生成

circle-daily-reportスキルを使って、アイザックの日次レポートを生成してください。

## 実行手順

1. `config.local.md` からSupabaseプロジェクトIDを取得
2. Supabase MCP の `execute_sql` で、circle-daily-reportスキルに定義されたSQLを実行してデータを取得
3. 取得したデータを分析し、未対応コメント・新規投稿・メンバー動向・盛り上げアクション提案を含むレポートを生成
4. レポートを `config.local.md` の出力先フォルダに保存
5. 完了後、レポートファイルのパスをユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
