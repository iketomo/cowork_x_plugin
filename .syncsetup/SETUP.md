# Cowork Plugin セットアップガイド

---

## プラグインのインストール・更新

### Windows（Claude Desktop が全自動管理）

Claude Desktop でプラグインマーケットプレイスからインストール/更新するだけ。
`~/.claude/plugins/cache/` にプラグインがDLされ、`installed_plugins.json` も自動更新される。

### WSL（パス変換スクリプトを実行）

Windows 側でインストール/更新した後、WSL から以下を実行：

```bash
bash /mnt/c/Users/{ユーザー名}/Dropbox/Cursor/cowork/cowork_plugin/.syncsetup/sync-plugins-to-wsl.sh
```

その後 Claude Code を再起動すればスキルが有効になる。

---

## WSL 初回セットアップ（1回だけ）

WSL の `~/.claude/` を独立ディレクトリにし、Windows と共有すべきファイルをシンボリックリンクで接続する。

**`settings.json` は共有しない:** パス表記（`C:\` と `/mnt/c/`）やエディタ・ターミナル向けの差があるため、Windows 用と WSL 用は**それぞれの環境で別ファイル**として持つ。初回は WSL 側で空または最小の `settings.json` を用意し、必要な項目だけ WSL 向けにコピー・調整する。

```bash
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
WIN_CLAUDE="/mnt/c/Users/$WIN_USER/.claude"

# ~/.claude がシンボリックリンクなら独立化
if [ -L "$HOME/.claude" ]; then
  rm "$HOME/.claude"
  mkdir -p "$HOME/.claude"
fi

# 共有項目をシンボリックリンクで接続（settings.json は含めない）
for item in CLAUDE.md rules skills commands agents settings.local.json hooks teams; do
  if [ -e "$WIN_CLAUDE/$item" ] && [ ! -e "$HOME/.claude/$item" ]; then
    ln -s "$WIN_CLAUDE/$item" "$HOME/.claude/$item"
  fi
done

# settings.json は WSL 独自（シンボリックリンクにしない）
if [ ! -f "$HOME/.claude/settings.json" ]; then
  echo '{}' > "$HOME/.claude/settings.json"
  echo "Created empty ~/.claude/settings.json (edit for WSL as needed)"
fi

# plugins は WSL 独自
mkdir -p "$HOME/.claude/plugins"
```

---

## X Manager Plugin の個別セットアップ

### 前提条件

| 必要なもの | 用途 |
|-----------|------|
| [Claude Code](https://claude.ai/claude-code) | プラグインの実行環境 |
| [Supabase](https://supabase.com) プロジェクト | データベース・Edge Functions |
| X (Twitter) API アクセス | 投稿の取得・投稿 |
| Gemini API キー（任意） | 投稿用画像の生成 |

### ローカル設定ファイルの作成

```bash
cp config.example.md config.local.md
```

`config.local.md` を開き、自分の環境の値を記入。`.gitignore` 対象のためgitにコミットされない。

### Supabase データベースの構築

Supabase の SQL Editor で以下のテーブルを作成：

#### 自分の投稿パフォーマンス追跡用

```sql
CREATE TABLE x_tweets (
  tweet_id text PRIMARY KEY,
  author_id text,
  text text,
  url text,
  created_at timestamptz,
  is_tracking boolean DEFAULT true,
  raw_json jsonb
);

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

CREATE TABLE x_fetch_logs (
  id serial PRIMARY KEY,
  fetch_date date,
  tweets_fetched int DEFAULT 0,
  tweets_saved int DEFAULT 0,
  error_message text,
  created_at timestamptz DEFAULT now()
);
```

#### トレンド分析用

```sql
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

### Supabase Edge Functions のデプロイ

Secrets に以下を設定（Dashboard → Settings → Edge Functions → Secrets）：

| Secret名 | 内容 |
|----------|------|
| `X_BEARER_TOKEN` | X API Bearer Token |
| `X_API_KEY` | X API Key (OAuth 1.0a) |
| `X_API_SECRET` | X API Secret |
| `X_ACCESS_TOKEN` | X Access Token |
| `X_ACCESS_TOKEN_SECRET` | X Access Token Secret |

| Edge Function | 用途 |
|--------------|------|
| `x-daily-fetch` | 自分の投稿メトリクス取得 |
| `x-trend-fetch` | トレンド投稿検索 |
| `x-post-tweet` | X API への投稿 |

```sql
-- pg_net 拡張の有効化（x-post-tweet 用）
CREATE EXTENSION IF NOT EXISTS pg_net;
```

### 投稿文スタイルのカスタマイズ

- `config.local.md` のXアカウント欄を自分の情報に変更
- `skills/x-writing/SKILL.md` の「投稿方針」を自分のテーマに変更
- 自分のバズ投稿を成功例として差し替えると精度向上
