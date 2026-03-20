# Cowork Plugin セットアップガイド

## 📦 クロス環境セットアップ（Windows / WSL / Mac）

このディレクトリ (`cowork_plugin/`) が Cowork プラグインの **真実の源泉** です。
Dropbox 経由で全マシンに同期されます。各環境で以下を一度実行してください。

### Windows (Git Bash)
```bash
bash "C:/Users/{ユーザー名}/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh"
```

### WSL
```bash
bash /mnt/c/Users/{ユーザー名}/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh
```
WSL の `~/.claude` がシンボリックリンクの場合、自動で独立化されます。
（CLAUDE.md / rules / skills / commands / agents は Windows と共有維持）

### macOS
```bash
bash ~/Dropbox/Cursor/cowork/cowork_plugin/setup-claude-plugins.sh
```

実行後、Claude Code を再起動すると全スキルが有効になります。

**プラグインを追加・更新したら毎回スクリプトを再実行してください。**

---

## 仕組み

```
Dropbox/cowork_plugin/          ← このディレクトリ（全マシン共有）
  x-manager/
    .claude-plugin/plugin.json  ← バージョン情報
    skills/ commands/ agents/   ← プラグイン本体
  ...
  setup-claude-plugins.sh       ← 環境別セットアップスクリプト

~/.claude/plugins/installed_plugins.json  ← 各環境で独立生成
  Windows:  installPath = C:\Users\...\Dropbox\...\x-manager
  WSL:      installPath = /mnt/c/Users/.../Dropbox/.../x-manager
  macOS:    installPath = ~/Dropbox/.../x-manager
```

---

## X Manager Plugin セットアップガイド

このプラグインを自分の環境で使うための設定手順です。

---

## 1. 前提条件

| 必要なもの | 用途 |
|-----------|------|
| [Claude Code](https://claude.ai/claude-code) | プラグインの実行環境 |
| [Supabase](https://supabase.com) プロジェクト | データベース・Edge Functions |
| X (Twitter) API アクセス | 投稿の取得・投稿 |
| Gemini API キー（任意） | 投稿用画像の生成 |
| Slack Incoming Webhook（任意） | レポートのSlack通知 |

---

## 2. ローカル設定ファイルの作成

```bash
cp config.example.md config.local.md
```

`config.local.md` を開き、自分の環境の値を記入してください。
このファイルは `.gitignore` に含まれるため、gitにコミットされません。

### 設定項目の取得方法

| 項目 | 取得場所 |
|------|---------|
| Supabase プロジェクトID | Supabase Dashboard → Settings → General → Reference ID |
| Supabase Anon Key | Supabase Dashboard → Settings → API → `anon` `public` キー |
| X ユーザー名 | 自分のXプロフィール（`@` 以降） |
| Slack Webhook URL | Slack App → Incoming Webhooks → Webhook URL |
| Gemini API Key | [Google AI Studio](https://aistudio.google.com/) → Get API Key |

---

## 3. Supabase データベースの構築

Supabase の SQL Editor で以下のテーブルを作成してください。

### 3-1. 自分の投稿パフォーマンス追跡用テーブル

```sql
-- 投稿マスタ
CREATE TABLE x_tweets (
  tweet_id text PRIMARY KEY,
  author_id text,
  text text,
  url text,
  created_at timestamptz,
  is_tracking boolean DEFAULT true,
  raw_json jsonb
);

-- 日次メトリクススナップショット
CREATE TABLE x_tweet_metrics_daily (
  tweet_id text NOT NULL REFERENCES x_tweets(tweet_id),
  date date NOT NULL,
  like_count int DEFAULT 0,
  repost_count int DEFAULT 0,
  reply_count int DEFAULT 0,
  quote_count int DEFAULT 0,
  impression_count int DEFAULT 0,
  bookmark_count int DEFAULT 0,
  PRIMARY KEY (tweet_id, date)
);

-- 日次分析結果
CREATE TABLE x_tweet_analysis (
  id serial PRIMARY KEY,
  date date NOT NULL UNIQUE,
  total_tracked int,
  winners jsonb,
  watch_list jsonb,
  summary text,
  suggestions text,
  run_log jsonb
);

-- データ取得ログ
CREATE TABLE x_fetch_logs (
  id serial PRIMARY KEY,
  fetch_date date,
  tweets_fetched int DEFAULT 0,
  tweets_saved int DEFAULT 0,
  error_message text,
  created_at timestamptz DEFAULT now()
);
```

### 3-2. トレンド分析用テーブル

```sql
-- 追跡キーワード管理
CREATE TABLE x_trend_keywords (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  category text NOT NULL,
  keyword text NOT NULL,
  search_query text NOT NULL,
  language text DEFAULT 'ja',
  min_likes int DEFAULT 100,
  min_retweets int DEFAULT 30,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 追跡アカウント管理
CREATE TABLE x_trend_accounts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  x_user_id text,
  username text NOT NULL,
  display_name text,
  category text,
  follower_count int,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- バズ投稿マスタ
CREATE TABLE x_trend_tweets (
  tweet_id text PRIMARY KEY,
  author_id text,
  author_username text,
  author_display_name text,
  text text NOT NULL,
  url text,
  language text,
  created_at timestamptz,
  first_seen_at timestamptz DEFAULT now(),
  source_type text,
  source_keyword text,
  like_count int DEFAULT 0,
  retweet_count int DEFAULT 0,
  reply_count int DEFAULT 0,
  quote_count int DEFAULT 0,
  bookmark_count int DEFAULT 0,
  content_category text,
  content_format text,
  raw_json jsonb
);

-- エンゲージメント推移
CREATE TABLE x_trend_snapshots (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tweet_id text NOT NULL REFERENCES x_trend_tweets(tweet_id),
  date date NOT NULL,
  like_count int DEFAULT 0,
  retweet_count int DEFAULT 0,
  reply_count int DEFAULT 0,
  quote_count int DEFAULT 0,
  bookmark_count int DEFAULT 0,
  collected_at timestamptz DEFAULT now(),
  UNIQUE(tweet_id, date)
);

-- 日次分析レポート
CREATE TABLE x_trend_daily_report (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  date date NOT NULL UNIQUE,
  total_collected int,
  total_after_filter int,
  top_tweets jsonb,
  category_breakdown jsonb,
  format_analysis jsonb,
  time_analysis jsonb,
  trending_topics jsonb,
  posting_strategy text,
  post_ideas jsonb,
  api_cost_estimate numeric,
  created_at timestamptz DEFAULT now()
);

-- データ取得ログ
CREATE TABLE x_trend_fetch_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  fetch_date date NOT NULL,
  fetch_type text,
  query_or_account text,
  tweets_fetched int DEFAULT 0,
  tweets_saved int DEFAULT 0,
  api_credits_used numeric,
  error_message text,
  duration_ms int,
  created_at timestamptz DEFAULT now()
);
```

---

## 4. Supabase Edge Functions のデプロイ

以下の3つの Edge Function が必要です。Supabase の Secrets に X API のキーを事前に設定してください。

### Secrets の設定

Supabase Dashboard → Settings → Edge Functions → Secrets に以下を追加：

| Secret名 | 内容 |
|----------|------|
| `X_BEARER_TOKEN` | X API Bearer Token |
| `X_API_KEY` | X API Key (OAuth 1.0a) |
| `X_API_SECRET` | X API Secret |
| `X_ACCESS_TOKEN` | X Access Token |
| `X_ACCESS_TOKEN_SECRET` | X Access Token Secret |

### Edge Functions

| 関数名 | 用途 |
|--------|------|
| `x-daily-fetch` | X APIから自分の投稿メトリクスを取得し、x_tweets / x_tweet_metrics_daily に保存 |
| `x-trend-fetch` | X APIからトレンド投稿を検索し、x_trend_tweets / x_trend_snapshots に保存 |
| `x-post-tweet` | テキストを受け取り、OAuth 1.0a で X API に投稿 |

### pg_net 拡張の有効化

`x-post-tweet` を SQL から呼び出すために、pg_net 拡張を有効にしてください：

```sql
CREATE EXTENSION IF NOT EXISTS pg_net;
```

---

## 5. 画像生成（任意）

投稿用画像を生成するには：

```bash
# 依存パッケージのインストール
pip install google-genai

# 環境変数の設定
export GEMINI_API_KEY="your-api-key"

# 画像生成
python scripts/generate_image.py "投稿テキスト"
```

---

## 6. 投稿文スタイルのカスタマイズ

`skills/x-writing/SKILL.md` にはX投稿の文章スタイルガイドが定義されています。
自分のアカウントに合わせて以下をカスタマイズしてください：

- **プロフィール情報**: `config.local.md` のXアカウント欄を自分の情報に変更
- **投稿方針**: SKILL.md内の「X投稿の方向性」セクションを自分のテーマに変更
- **成果が出た投稿例**: 自分のバズ投稿に差し替えるとより精度が上がります

---

## 7. 使い方

プラグインが設置されたディレクトリで Claude Code を起動すると、以下のコマンドが使えます：

| コマンド | 説明 |
|---------|------|
| `/x-daily` | 日次パフォーマンスレポートを生成 |
| `/x-trend` | AI領域トレンド分析レポートを生成 |
| `/x-write [テーマ]` | X投稿の文章を作成 |
| `/x-post [テキスト]` | Xに投稿を実行 |
| `/x-image [テキスト]` | 投稿用画像を生成 |
