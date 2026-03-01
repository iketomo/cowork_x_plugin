---
description: Lumaイベントの日次レポートを生成してSlackに送信する
allowed-tools: ["Task", "Skill", "Read", "Write"]
---

# Luma日次レポート生成

luma-daily-reportスキルを使って、Lumaイベントの日次レポートを生成しSlackに送信してください。

## 実行手順

1. `config.local.md` からSupabaseプロジェクトID・Slack channel_idを取得
2. Supabase MCP の `execute_sql` で、luma-daily-reportスキルに定義されたSQL（Step 1の1-1〜1-4）を実行してデータを取得
3. 取得したデータをサブエージェント（luma-daily-analyzer）に渡してレポート生成＋Slack用サマリ作成
4. サブエージェントから返されたSlack用サマリで、slack_create_canvas + slack_send_message を実行
5. 完了後、レポートファイルのパスをユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
