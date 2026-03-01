---
description: Lumaイベントの日次レポートを生成してSlackに送信する
allowed-tools: ["Task", "Skill", "Read", "Write"]
---

# Luma日次レポート生成

luma-daily-reportスキルを使って、Lumaイベントの日次レポートを生成しSlackに送信してください。

## 実行手順

1. `config.local.md` からSupabaseプロジェクトID・Slack channel_idを取得
2. Supabase MCP の `execute_sql` で、luma-daily-reportスキルに定義されたSQLを実行してデータを取得
3. 取得したデータを分析し、サマリ・イベント別ステータス・傾向分析・打ち手提案を含むレポートを生成
4. slack_create_canvas でCanvasを作成
5. slack_send_message でDMにサマリを送信
6. 完了後、ユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
