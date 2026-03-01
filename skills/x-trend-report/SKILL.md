---
name: x-trend-report
description: >
  AI・生成AI領域のXトレンド分析レポートを生成するスキル。
  Supabaseのx_trend_*テーブルからバズ投稿・エンゲージメント推移を取得し、
  カテゴリ別トレンド分析・フォーマット分析・投稿アイデア生成を行い、Markdownレポートを保存する。
  「Xトレンドレポート」「トレンド分析」「AI界隈のバズ」「競合分析レポート」「今日のXトレンド」
  「トレンドトラッカーのレポート」「x-trend-report」などのリクエストで発動。
version: 1.0.0
---

# Xトレンド分析 日次レポート

## 概要
AI・生成AI領域のバズ投稿を分析し、自身のX投稿戦略に活かすレポートを生成する（アカウント情報は `config.local.md` を参照）。

## コンテキスト節約ルール（最重要）

### 絶対禁止
- **referenceフォルダは読まない** — 実行時に不要
- **raw_json等の大きなフィールドは取得しない**

### サブエージェント3段構成で実行
メインエージェントはオーケストレーション（結果の受け渡し）のみ。全処理をサブエージェントに委譲する。

---

## 実行手順（全3ステップ）

### Step 1: サブエージェント — データ取得+整形

Taskツール（subagent_type: `general-purpose`, model: `sonnet`）で `x-trend-data-collector` エージェントの指示に従いデータ取得。

**SQL-A: 収集状況 + TOP投稿**

```sql
WITH fetch_summary AS (
  SELECT count(*) as log_count, sum(tweets_fetched) as total_fetched,
    sum(tweets_saved) as total_saved, max(fetch_date) as latest_date
  FROM x_trend_fetch_logs
  WHERE fetch_date >= CURRENT_DATE - INTERVAL '1 day'
),
scored AS (
  SELECT t.tweet_id, LEFT(t.text, 60) as text_short, t.url,
    t.author_username, t.source_keyword, t.language, t.created_at,
    s.like_count, s.retweet_count, s.reply_count, s.quote_count, s.bookmark_count,
    (s.like_count + s.retweet_count * 3 + s.quote_count * 5) as score
  FROM x_trend_tweets t
  JOIN x_trend_snapshots s ON s.tweet_id = t.tweet_id
    AND s.date = (SELECT max(date) FROM x_trend_snapshots)
  ORDER BY score DESC LIMIT 10
)
SELECT 'fetch_summary' as section, to_json(f.*) as data FROM fetch_summary f
UNION ALL
SELECT 'top_tweet', to_json(sc.*) FROM scored sc;
```

**SQL-B: カテゴリ集計 + 時間帯**

```sql
WITH cat AS (
  SELECT t.source_keyword as category, count(*) as tweet_count,
    round(avg(s.like_count),1) as avg_likes, sum(s.retweet_count) as total_retweets
  FROM x_trend_tweets t
  JOIN x_trend_snapshots s ON s.tweet_id = t.tweet_id
    AND s.date = (SELECT max(date) FROM x_trend_snapshots)
  GROUP BY t.source_keyword
  ORDER BY sum(s.like_count + s.retweet_count*3) DESC
),
hours AS (
  SELECT extract(hour from t.created_at AT TIME ZONE 'Asia/Tokyo')::int as hour_jst,
    count(*) as tweet_count, round(avg(s.like_count),1) as avg_likes
  FROM x_trend_tweets t
  JOIN x_trend_snapshots s ON s.tweet_id = t.tweet_id
    AND s.date = (SELECT max(date) FROM x_trend_snapshots)
  GROUP BY hour_jst ORDER BY avg_likes DESC LIMIT 5
)
SELECT 'category' as section, to_json(c.*) as data FROM cat c
UNION ALL
SELECT 'hour', to_json(h.*) as data FROM hours h;
```

### Step 2: サブエージェント — 各Winner投稿のニュース背景調査

Step 1の結果からTOP5投稿を取り出し、**各投稿ごとに並列で** `x-trend-news-researcher` エージェントの指示に従いTaskツールを呼ぶ。
1メッセージで最大5つのTask呼び出しを並列実行する。

### Step 3: サブエージェント — 分析+DB保存+ファイル出力

Step 1のデータ + Step 2のニュース背景を合わせて、`x-trend-analyzer` エージェントの指示に従いTaskツールで分析・保存・レポート出力。

### メインエージェントの最終処理
Step 3のサブエージェントから返ってきたファイルパスを使い、ユーザーに共有する。

### エラーハンドリング
- fetch_logsに本日データがない → 最新日で代替し注記
- ツイートが0件 → error_messageを確認し原因報告
- スナップショット1日のみ → 絶対値分析＋「初日のためデルタ分析は翌日以降」と注記
