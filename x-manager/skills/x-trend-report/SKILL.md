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

**subagent_type: `general-purpose`** で起動する（プラグイン定義エージェントはSupabase MCPにアクセスできないため、必ずgeneral-purposeを使うこと）。

プロンプトには以下を渡す：
1. エージェント定義ファイルを読んで指示に従うよう伝える（パス: `x-manager/agents/x-trend-data-collector.md`）
2. `config.local.md` のパスを伝える（プロジェクトID取得用）
3. 下記SQL-AとSQL-Bを渡し、execute_sqlで実行させる

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

### Step 2: サブエージェント — 各Winner投稿のニュース背景調査（並列5件）

Step 1の結果からTOP5投稿を取り出し、**1メッセージの中で5つのAgentツール呼び出しを同時に**実行する。
subagent_type は `x-manager:x-trend-news-researcher` を使う（WebSearchのみで軽量なのでプラグイン定義で問題ない）。

**⚠️ 必ず以下のように1メッセージで並列起動すること。順番に1件ずつ呼ぶのは禁止。**

```
# 1メッセージ内でこの5つを同時に呼び出す
Agent(x-manager:x-trend-news-researcher, prompt="投稿1: @xxx「...」スコアXXX")
Agent(x-manager:x-trend-news-researcher, prompt="投稿2: @xxx「...」スコアXXX")
Agent(x-manager:x-trend-news-researcher, prompt="投稿3: @xxx「...」スコアXXX")
Agent(x-manager:x-trend-news-researcher, prompt="投稿4: @xxx「...」スコアXXX")
Agent(x-manager:x-trend-news-researcher, prompt="投稿5: @xxx「...」スコアXXX")
```

### Step 3: サブエージェント — 分析+DB保存+ファイル出力

**subagent_type: `general-purpose`** で起動する（DB保存にexecute_sqlが必要なため、必ずgeneral-purposeを使うこと）。

プロンプトには以下を渡す：
1. エージェント定義ファイルを読んで指示に従うよう伝える（パス: `x-manager/agents/x-trend-analyzer.md`）
2. `config.local.md` のパスを伝える（プロジェクトID取得用）
3. Step 1のデータ全量
4. Step 2のニュース背景5件分

サブエージェントは分析・DB保存（execute_sql）・Markdownファイル保存を**すべて自分で完結**させる。

### メインエージェントの最終処理
Step 3のサブエージェントから返ってきたファイルパスを使い、ユーザーに共有する。

### エラーハンドリング
- fetch_logsに本日データがない → 最新日で代替し注記
- ツイートが0件 → error_messageを確認し原因報告
- スナップショット1日のみ → 絶対値分析＋「初日のためデルタ分析は翌日以降」と注記
