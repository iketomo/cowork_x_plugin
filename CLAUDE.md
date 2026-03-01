# X Manager Plugin（cowork_x_plugin）

## 概要
X（Twitter）投稿の作成・投稿・パフォーマンス分析・トレンド分析を一括管理するCowork Plugin。

## プラグイン構成

```
cowork_x_plugin/                          # マーケットプレイス（カタログ）
├── .claude-plugin/
│   └── marketplace.json                  # マーケットプレイスマニフェスト
├── x-manager/                            # プラグイン本体
│   ├── .claude-plugin/
│   │   └── plugin.json                   # プラグインマニフェスト
│   ├── skills/                           # スキル定義（4つ）
│   │   ├── x-daily-report/SKILL.md
│   │   ├── x-trend-report/SKILL.md
│   │   ├── x-post/SKILL.md
│   │   └── x-writing/SKILL.md
│   ├── agents/                           # サブエージェント定義（4つ）
│   │   ├── x-daily-analyzer.md
│   │   ├── x-trend-data-collector.md
│   │   ├── x-trend-news-researcher.md
│   │   └── x-trend-analyzer.md
│   ├── commands/                         # スラッシュコマンド（5つ）
│   │   ├── x-daily.md
│   │   ├── x-trend.md
│   │   ├── x-post.md
│   │   ├── x-write.md
│   │   └── x-image.md
│   ├── scripts/
│   │   └── generate_image.py
│   ├── reference/
│   │   └── x-trend-tracker-design.md
│   ├── log/                              # レポート出力先
│   ├── config.local.md                   # ローカル設定（gitignore）
│   └── config.example.md                 # 設定テンプレート
├── CLAUDE.md                             # このファイル
├── SETUP.md                              # セットアップガイド
├── PROGRESS.md                           # 作業過程
└── .gitignore
```

## スキル一覧

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| x-daily-report | 「X日次レポート」「パフォーマンス分析」 | 自分の投稿のWinner/Watch分類・伸び分析・投稿提案 |
| x-trend-report | 「Xトレンドレポート」「AI界隈のバズ」 | AI領域バズ投稿のトレンド分析・投稿戦略提案 |
| x-post | 「Xに投稿して」「ツイートして」 | Edge Function経由でXに投稿 |
| x-writing | 「X投稿を書いて」「ツイート案」 | 投稿文作成（プロフィールは config.local.md 参照） |

## サブエージェント一覧

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| x-daily-analyzer | sonnet | x-daily-report | 分類・分析・ニュース検索・DB保存・レポート出力 |
| x-trend-data-collector | sonnet | x-trend-report Step1 | SQL実行・データ整形 |
| x-trend-news-researcher | sonnet | x-trend-report Step2 | バズ投稿の背景調査（並列5件） |
| x-trend-analyzer | sonnet | x-trend-report Step3 | 総合分析・DB保存・レポート出力 |

## コマンド一覧（スラッシュコマンド）

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/x-daily` | 日次パフォーマンスレポートを生成 | なし |
| `/x-trend` | AI領域トレンド分析レポートを生成 | なし |
| `/x-write` | X投稿の文章を作成 | テーマやニュースURL（任意） |
| `/x-post` | Xに投稿を実行 | 投稿テキスト（任意） |
| `/x-image` | 投稿用画像を生成 | 投稿テキスト or ファイルパス（任意） |

## Supabase設定
- プロジェクトID・認証情報: `config.local.md` を参照
- MCP: `execute_sql` を使用

## データベース構成

### 日次パフォーマンス系テーブル（x_*）

| テーブル名 | 内容 | PK |
|-----------|------|-----|
| x_tweets | 投稿マスタ（最新100件追跡） | tweet_id |
| x_tweet_metrics_daily | 日次メトリクススナップショット | (tweet_id, date) |
| x_tweet_analysis | 日次分析結果（Winner/Watch/示唆） | id (date UNIQUE) |
| x_fetch_logs | データ取得ログ | id |

### トレンド分析系テーブル（x_trend_*）

| テーブル名 | 内容 | PK |
|-----------|------|-----|
| x_trend_keywords | 追跡キーワード管理 | id (uuid) |
| x_trend_accounts | 追跡アカウント管理 | id (uuid) |
| x_trend_tweets | バズ投稿マスタ | tweet_id (text) |
| x_trend_snapshots | エンゲージメント推移 | id (uuid), UNIQUE(tweet_id, date) |
| x_trend_daily_report | 日次分析レポート | id (uuid), UNIQUE(date) |
| x_trend_fetch_logs | データ取得ログ | id (uuid) |

### 主要カラム

**x_tweets**: tweet_id, author_id, text, url, created_at, is_tracking, raw_json

**x_tweet_metrics_daily**: tweet_id, date, like_count, repost_count, reply_count, quote_count, impression_count, bookmark_count

**x_tweet_analysis**: id, date, total_tracked, winners(jsonb), watch_list(jsonb), summary, suggestions, run_log(jsonb)

**x_trend_tweets**: tweet_id, author_username, text, url, language, created_at, source_type, source_keyword, like_count, retweet_count, reply_count, quote_count, bookmark_count

**x_trend_daily_report**: id, date, total_collected, total_after_filter, top_tweets(jsonb), category_breakdown(jsonb), format_analysis(jsonb), time_analysis(jsonb), trending_topics(jsonb), posting_strategy, post_ideas(jsonb)

## スコアリングロジック
- **score_3d** = likes_3d + (reposts_3d x 3) + (quotes_3d x 5)
- **Winner条件**: score_3d上位5件 OR (24h_likes >= 50 OR 24h_reposts >= 10)

## Edge Functions
- `x-daily-fetch`: X API → x_tweets/x_tweet_metrics_daily
- `x-trend-fetch`: X API → x_trend_tweets/x_trend_snapshots
- `x-post-tweet`: 投稿テキスト → X API POST

## 画像生成
- スクリプト: `scripts/generate_image.py`
- モデル: Gemini 3 Pro (gemini-3-pro-image-preview)
- スタイル: 日本のビジネス書風「ゆるいイラスト」
- サイズ: 1:1 (2K)
- 環境変数: `GEMINI_API_KEY`
