---
description: いけともch向けYouTube企画案を週次で生成する
allowed-tools: ["Task", "Skill", "Read", "Write", "WebSearch"]
---

# YouTube企画案生成

weekly-youtube-ideasスキルを使って、今週のトレンドから企画案10本を生成してください。

## 実行手順

1. `config.local.md` からSupabaseプロジェクトIDを取得
2. サブエージェント（youtube-trend-analyzer）でトレンドデータ取得・分析を実行
3. サブエージェントの分析結果をもとに、メインエージェントで企画案10本を生成
4. レポートを `config.local.md` の出力先フォルダに保存
5. 完了後、レポートファイルのパスをユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
