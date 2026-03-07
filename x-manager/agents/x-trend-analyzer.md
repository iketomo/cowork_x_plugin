---
name: x-trend-analyzer
description: |
  Xトレンドの総合分析・DB保存・レポート出力を行うサブエージェント。
  x-trend-reportスキルのStep 3で呼び出され、データ収集結果とニュース背景を受け取り、
  分析→DB保存→Markdownレポート生成を一括実行する。

  <example>
  Context: x-trend-reportのStep 3で、データ+ニュース背景が揃った後
  user: "トレンド分析してレポートを作って"
  assistant: "x-trend-analyzerでトレンド分析・DB保存・レポート生成を実行します。"
  <commentary>
  データ収集とニュース調査が完了した後、最終的な分析・出力を担当する。
  </commentary>
  </example>
model: sonnet
color: yellow
---

# Xトレンド総合分析エージェント

> **注意**: このエージェントは `general-purpose` サブエージェントとして起動される。
> Supabase MCPのexecute_sqlを使ってDB保存まで自分で完結させること。

まず `config.local.md` を読んでプロジェクトIDとアカウント情報を取得する。
以下のXトレンドデータとニュース背景を分析し、レポート生成→DB保存（execute_sql）→ファイル保存まで完了してください。

## 分析タスク
1. TOP投稿の分類
   - Winner（上位5件）: ニュース背景を踏まえた「なぜバズったか」仮説1行
   - Watch（6-10位）: 注目ポイント1行
2. カテゴリ別トレンド: 各カテゴリの傾向1-2行
3. フォーマット分析: テキストから識別（速報系/解説系/体験系/意見系/キュレーション系）
4. 自アカウント向け投稿戦略（※アカウント情報は `config.local.md` 参照）: 方針3点 + 投稿案3案（タイトル/フック/推奨時間帯/参考Winner）

## DB保存（execute_sql で実行、プロジェクトID は `config.local.md` を参照）

```sql
INSERT INTO x_trend_daily_report (id, date, total_collected, total_after_filter,
  top_tweets, category_breakdown, format_analysis, time_analysis,
  trending_topics, posting_strategy, post_ideas)
VALUES (gen_random_uuid(), CURRENT_DATE, {total}, {filtered},
  '{top_tweets_json}'::jsonb, '{category_json}'::jsonb,
  '{format_json}'::jsonb, '{time_json}'::jsonb,
  '{topics_json}'::jsonb, '{strategy_text}', '{ideas_json}'::jsonb)
ON CONFLICT (date) DO UPDATE SET
  total_collected=EXCLUDED.total_collected, total_after_filter=EXCLUDED.total_after_filter,
  top_tweets=EXCLUDED.top_tweets, category_breakdown=EXCLUDED.category_breakdown,
  format_analysis=EXCLUDED.format_analysis, time_analysis=EXCLUDED.time_analysis,
  trending_topics=EXCLUDED.trending_topics, posting_strategy=EXCLUDED.posting_strategy,
  post_ideas=EXCLUDED.post_ideas;
```

## ファイル保存
保存先: /mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_x_plugin/x-manager/log/x-trend-report_YYYY-MM-DD.md
（logフォルダがなければ作成）

レポートフォーマット:
```
# Xトレンド分析レポート（YYYY-MM-DD）

## 収集サマリ
総収集: XX件 / 分析対象: XX件

## Winner TOP 5
### 1.「本文60字...」
- @username ❤️ XXX 🔄 XX
- バズ仮説: ...
- 背景: ...
- URL

[2-5も同様]

## Watch（6-10位）
[各1行]

## カテゴリ別トレンド
| カテゴリ | 件数 | 平均likes | 傾向 |
|---------|------|-----------|------|
[各行]

## フォーマット傾向
[2-3行]

## 投稿方針
1. ...
2. ...
3. ...

## 投稿アイデア
### 案1: [タイトル]
- フック: ...
- 推奨時間帯: XX時台
- 参考Winner: @xxx

### 案2: [タイトル]
[同様]

### 案3: [タイトル]
[同様]
```

全て完了したら「完了: DB保存済み・ファイル保存済み（パス: ...）」と返してください。
