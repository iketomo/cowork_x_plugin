---
name: x-daily-report
description: >
  X（Twitter）投稿パフォーマンスの日次レポートを生成するスキル。
  Supabaseのx_*テーブルからデータを取得し、Winner/Watch分類・伸びパターン分析・投稿方針提案を行い、Markdownレポートを出力する。
  「X日次レポート」「Xのパフォーマンス」「ツイート分析」「投稿の伸び確認」「x-daily-report」などのリクエストで発動。
version: 1.0.0
---

# X投稿パフォーマンス日次レポート

## 概要
Supabaseのx_*テーブルからデータを取得し、投稿パフォーマンスを分析してレポートを生成する。

## 前提
- Supabaseプロジェクト: `config.local.md` の Supabase 設定を参照
- MCP: `execute_sql` を使用してデータ取得

## コンテキスト節約アーキテクチャ

**メインエージェントの役割は最小限にする。**

| 担当 | 処理内容 |
|------|----------|
| メインエージェント | SQL実行 → サブエージェント起動 → 完了報告 |
| サブエージェント（x-daily-analyzer） | 分類・分析・ニュース検索・DB保存・レポートファイル出力 すべて |

メインエージェントは **SQL結果をそのままサブエージェントに渡し、返り値のファイルパスだけ受け取る**。分析・レポート生成には一切関与しない。

## 実行手順

### ステップ1: メインエージェント — データ取得（SQL 1本）

以下のSQLを `execute_sql` で実行する。**上位20件のみ**返すことでコンテキスト消費を抑える。

```sql
WITH latest AS (
  SELECT DISTINCT ON (tweet_id) tweet_id, date, like_count, repost_count, reply_count, quote_count, impression_count
  FROM x_tweet_metrics_daily
  ORDER BY tweet_id, date DESC
),
three_days_ago AS (
  SELECT DISTINCT ON (tweet_id) tweet_id, like_count, repost_count, reply_count, quote_count, impression_count
  FROM x_tweet_metrics_daily
  WHERE date <= CURRENT_DATE - 3
  ORDER BY tweet_id, date DESC
),
yesterday AS (
  SELECT DISTINCT ON (tweet_id) tweet_id, like_count, repost_count, reply_count, quote_count, impression_count
  FROM x_tweet_metrics_daily
  WHERE date <= CURRENT_DATE - 1
  ORDER BY tweet_id, date DESC
),
scored AS (
  SELECT
    t.tweet_id,
    LEFT(t.text, 60) as text_short,
    t.url,
    t.created_at::date as created_date,
    l.like_count as cur_likes,
    l.repost_count as cur_reposts,
    l.quote_count as cur_quotes,
    COALESCE(l.like_count - w.like_count, l.like_count) as d3_likes,
    COALESCE(l.repost_count - w.repost_count, l.repost_count) as d3_reposts,
    COALESCE(l.quote_count - w.quote_count, l.quote_count) as d3_quotes,
    COALESCE(l.like_count - y.like_count, 0) as d24h_likes,
    COALESCE(l.repost_count - y.repost_count, 0) as d24h_reposts,
    COALESCE(l.like_count - w.like_count, l.like_count)
      + COALESCE(l.repost_count - w.repost_count, l.repost_count) * 3
      + COALESCE(l.quote_count - w.quote_count, l.quote_count) * 5
      as score_3d
  FROM x_tweets t
  JOIN latest l ON l.tweet_id = t.tweet_id
  LEFT JOIN three_days_ago w ON w.tweet_id = t.tweet_id
  LEFT JOIN yesterday y ON y.tweet_id = t.tweet_id
  WHERE t.is_tracking = true
),
counts AS (
  SELECT COUNT(*) as total_tracked FROM x_tweets WHERE is_tracking = true
)
SELECT s.*, c.total_tracked
FROM scored s, counts c
WHERE s.score_3d > 0 OR s.d24h_likes > 0
ORDER BY s.score_3d DESC
LIMIT 20;
```

### ステップ2: メインエージェント — サブエージェント起動

SQL結果を受け取ったら、**すぐにTaskツールでサブエージェント `x-daily-analyzer` を起動**する。メインエージェントでの分析は一切行わない。

Taskツールの呼び出し：
- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"X daily report generation"`

**promptに含める内容：**
1. SQL結果データ（JSON文字列としてそのまま貼り付け）
2. agents/x-daily-analyzer.md に定義されたサブエージェント指示に従って処理を実行するよう指示

### ステップ3: メインエージェント — 完了報告

サブエージェントから返ってきたファイルパスを使い、以下を行う：
1. **Readツールでレポートファイルを読み込む**（Claude Code上で折りたたみ式に表示され、ユーザーがクリックで閲覧可能）
2. 1〜2行の簡潔なサマリだけテキストで出力する。レポート全文をテキストとして出力するのは**禁止**（Readツール結果で閲覧可能なため）。

**以上で完了。** メインエージェントは分析やレポート内容の要約を行わない。
