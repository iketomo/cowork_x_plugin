---
description: AI・生成AI領域のXトレンド分析レポートを生成する
allowed-tools: ["Task", "Skill", "Read", "Write", "WebSearch"]
---

# Xトレンド分析レポート生成

x-trend-reportスキルを使って、AI・生成AI領域のXトレンド分析レポートを生成してください。

## 実行手順

1. サブエージェント（x-trend-data-collector）でSupabaseからトレンドデータを収集
2. サブエージェント（x-trend-news-researcher）でTOP5投稿のニュース背景を並列調査
3. サブエージェント（x-trend-analyzer）で総合分析・DB保存・レポート出力
4. 完了後、レポートファイルのパスをユーザーに報告

$ARGUMENTS が指定されている場合は、その内容を追加条件として考慮してください。
