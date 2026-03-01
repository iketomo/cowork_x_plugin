# Xトレンドトラッカー 全体設計書

## 1. プロジェクト概要

### 目的
AI・生成AI領域でバズっている投稿を日次で自動収集・分析し、「いけともch」のX投稿戦略に活かすためのインサイトを毎日Slackに配信する。

### 既存システムとの関係
- **既存**: `x_tweets` / `x_tweet_metrics_daily` → 自分の投稿パフォーマンス分析
- **新規**: `x_trend_*` テーブル群 → 市場のバズ投稿トレンド分析
- 両者は独立して動作し、日次レポートで連携（自分の投稿方針にトレンドを反映）

---

## 2. システムアーキテクチャ

```
┌─────────────────────────────────────────────────────┐
│  X API (Pay-Per-Use)                                │
│  Search Recent Tweets / User Tweets                  │
└──────────────┬──────────────────────────────────────┘
               │ 毎日 AM 7:00 JST
               ▼
┌─────────────────────────────────────────────────────┐
│  Supabase Edge Function: x-trend-fetch               │
│  ・キーワード検索（5〜10クエリ）                       │
│  ・特定アカウント投稿取得                              │
│  ・エンゲージメント閾値フィルタ                         │
│  ・Supabaseへ保存                                     │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│  Supabase (cowork プロジェクト)                       │
│  x_trend_tweets / x_trend_accounts /                 │
│  x_trend_keywords / x_trend_snapshots /              │
│  x_trend_daily_report                                │
└──────────────┬──────────────────────────────────────┘
               │ 毎日 AM 8:00 JST
               ▼
┌─────────────────────────────────────────────────────┐
│  Cowork スケジュールタスク: x-trend-report            │
│  ・DBからデータ取得                                   │
│  ・Claude分析（バズ要因・パターン・投稿提案）          │
│  ・レポート生成 → Slack通知                           │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│  Slack Incoming Webhook                              │
│  #x-trend-report チャンネル                          │
└─────────────────────────────────────────────────────┘
```

---

## 3. データ収集設計

### 3-1. 検索キーワード（x_trend_keywords テーブルで管理）

| カテゴリ | キーワード例 | 検索クエリ |
|---------|-------------|-----------|
| AIエージェント | AIエージェント, AI agent, MCP, Claude Code, Cursor, Devin | `"AIエージェント" OR "AI agent" min_faves:100 lang:ja` |
| 生成AI全般 | ChatGPT, Claude, Gemini, 生成AI, LLM | `"ChatGPT" OR "Claude" OR "生成AI" min_faves:100 lang:ja` |
| 画像/動画生成 | 画像生成, Midjourney, Sora, 動画生成 | `"画像生成" OR "Midjourney" OR "Sora" min_faves:50 lang:ja` |
| AI活用 | AI活用, AI業務効率化, プロンプト | `"AI活用" OR "プロンプト" min_faves:100 lang:ja` |
| 英語圏トレンド | AI agent, agentic AI, vibe coding | `"AI agent" OR "agentic AI" min_faves:500 lang:en` |

**注意**: `min_faves` や `min_retweets` はX API v2の検索クエリでは直接使えない。取得後にコード側でフィルタリングする。

### 3-2. 追跡アカウント（x_trend_accounts テーブルで管理）

| アカウント | ジャンル | フォロワー規模 |
|-----------|---------|--------------|
| @kaboratory（けんすう） | AI起業/プロダクト | 大 |
| @faboratory（深津貴之） | AIデザイン/UX | 大 |
| @masahirochaen（茶圓） | AI全般/初心者向け | 大 |
| @ochyai（落合陽一） | AI/テクノロジー | 大 |
| @shi3z（清水亮） | AI技術/エンジニア | 中 |
| @tokoroten（ところてん） | AI技術/データ | 中 |
| @npaka123（npaka） | AI実装/ハウツー | 中 |

※ アカウントは随時追加・変更可能（DBで管理）

### 3-3. 収集ロジック

```
1. x_trend_keywords から有効なキーワード一覧を取得
2. 各キーワードで Search Recent Tweets API を呼び出し
   - 期間: 過去24時間
   - 取得件数: 各100件（max_results=100）
   - 取得フィールド: text, author_id, created_at,
     public_metrics (like_count, retweet_count, reply_count, quote_count, bookmark_count)
   - expansions: author_id（著者情報も取得）
3. x_trend_accounts から有効なアカウント一覧を取得
4. 各アカウントの直近24h投稿を取得（User Tweets API）
5. 全取得データをマージ・重複排除
6. エンゲージメントフィルタ:
   - 日本語投稿: いいね100以上 OR RT30以上
   - 英語投稿: いいね500以上 OR RT100以上
7. フィルタ通過した投稿を x_trend_tweets に upsert
8. 取得ログを x_trend_fetch_logs に記録
```

### 3-4. コスト見積もり

| 項目 | 1日あたり | 月あたり |
|------|----------|---------|
| キーワード検索 (5クエリ × 100件) | 500件 × $0.005 = $2.50 | $75 |
| アカウント投稿取得 (7アカウント × 20件) | 140件 × $0.005 = $0.70 | $21 |
| ユーザー情報展開 | ~100件 × $0.010 = $1.00 | $30 |
| **合計（概算）** | **~$4.20/日** | **~$126/月** |

※ デデュプリケーション適用で実際はこれより安くなる可能性あり
※ Developer Consoleで実際の単価を確認して調整すること

---

## 4. テーブル設計

### 4-1. x_trend_keywords（追跡キーワード管理）

```sql
CREATE TABLE x_trend_keywords (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  category text NOT NULL,          -- カテゴリ（AIエージェント/生成AI全般/etc）
  keyword text NOT NULL,           -- 表示用キーワード
  search_query text NOT NULL,      -- X API検索クエリ文字列
  language text DEFAULT 'ja',      -- 対象言語
  min_likes int DEFAULT 100,       -- いいね閾値
  min_retweets int DEFAULT 30,     -- RT閾値
  is_active boolean DEFAULT true,  -- 有効フラグ
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### 4-2. x_trend_accounts（追跡アカウント管理）

```sql
CREATE TABLE x_trend_accounts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  x_user_id text,                  -- X API user ID
  username text NOT NULL,          -- @ユーザー名
  display_name text,               -- 表示名
  category text,                   -- ジャンル
  follower_count int,              -- フォロワー数（参考）
  is_active boolean DEFAULT true,  -- 有効フラグ
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### 4-3. x_trend_tweets（バズ投稿マスタ）

```sql
CREATE TABLE x_trend_tweets (
  tweet_id text PRIMARY KEY,
  author_id text,                  -- X API author ID
  author_username text,            -- @ユーザー名
  author_display_name text,        -- 表示名
  text text NOT NULL,              -- 投稿本文
  url text,                        -- 投稿URL
  language text,                   -- 言語
  created_at timestamptz,          -- 投稿日時
  first_seen_at timestamptz DEFAULT now(), -- 初回検出日時
  source_type text,                -- 検出元（keyword_search / account_track）
  source_keyword text,             -- 検出キーワード or アカウント名
  -- 初回取得時のメトリクス
  like_count int DEFAULT 0,
  retweet_count int DEFAULT 0,
  reply_count int DEFAULT 0,
  quote_count int DEFAULT 0,
  bookmark_count int DEFAULT 0,
  -- 分類
  content_category text,           -- コンテンツカテゴリ（後述の分析で付与）
  content_format text,             -- フォーマット（スレッド/単発/画像付き/etc）
  raw_json jsonb                   -- APIレスポンス全体
);
```

### 4-4. x_trend_snapshots（エンゲージメント推移）

```sql
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
```

### 4-5. x_trend_daily_report（日次分析レポート）

```sql
CREATE TABLE x_trend_daily_report (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  date date NOT NULL UNIQUE,
  -- 集計データ
  total_collected int,             -- 収集投稿数
  total_after_filter int,          -- フィルタ後投稿数
  -- 分析結果
  top_tweets jsonb,                -- TOP10投稿（JSON配列）
  category_breakdown jsonb,        -- カテゴリ別傾向
  format_analysis jsonb,           -- フォーマット別傾向
  time_analysis jsonb,             -- 投稿時間帯分析
  trending_topics jsonb,           -- 急上昇トピック
  -- 投稿提案
  posting_strategy text,           -- 投稿戦略サマリ
  post_ideas jsonb,                -- 具体的投稿案（3〜5案）
  -- メタ
  api_cost_estimate numeric,       -- 推定API消費額
  created_at timestamptz DEFAULT now()
);
```

### 4-6. x_trend_fetch_logs（取得ログ）

```sql
CREATE TABLE x_trend_fetch_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  fetch_date date NOT NULL,
  fetch_type text,                 -- keyword_search / account_track
  query_or_account text,           -- 検索クエリ or アカウント名
  tweets_fetched int DEFAULT 0,    -- 取得件数
  tweets_saved int DEFAULT 0,      -- 保存件数（フィルタ後）
  api_credits_used numeric,        -- 消費クレジット（概算）
  error_message text,              -- エラー時のメッセージ
  duration_ms int,                 -- 処理時間
  created_at timestamptz DEFAULT now()
);
```

---

## 5. Edge Function設計: x-trend-fetch

### エンドポイント
`POST /functions/v1/x-trend-fetch`

### 環境変数（Supabase Secrets）
- `X_BEARER_TOKEN` — X API Bearer Token（既存と共有可）
- `SUPABASE_URL` — Supabase URL
- `SUPABASE_SERVICE_ROLE_KEY` — Service Role Key

### 処理フロー

```typescript
// 概要フロー
async function main() {
  // 1. DBからアクティブなキーワード一覧取得
  const keywords = await getActiveKeywords();

  // 2. 各キーワードで検索
  for (const kw of keywords) {
    const tweets = await searchRecentTweets(kw.search_query, {
      max_results: 100,
      "tweet.fields": "created_at,public_metrics,author_id,lang",
      "user.fields": "username,name,public_metrics",
      "expansions": "author_id"
    });
    // フィルタ＆保存
    const filtered = filterByEngagement(tweets, kw.min_likes, kw.min_retweets);
    await upsertTrendTweets(filtered, "keyword_search", kw.keyword);
    await logFetch("keyword_search", kw.keyword, tweets.length, filtered.length);
  }

  // 3. DBからアクティブなアカウント一覧取得
  const accounts = await getActiveAccounts();

  // 4. 各アカウントの最新投稿取得
  for (const acc of accounts) {
    const tweets = await getUserTweets(acc.x_user_id, {
      max_results: 20,
      "tweet.fields": "created_at,public_metrics,lang",
      start_time: last24hISO()
    });
    await upsertTrendTweets(tweets, "account_track", acc.username);
    await logFetch("account_track", acc.username, tweets.length, tweets.length);
  }

  // 5. 既存のトレンド投稿のスナップショット更新（過去3日分）
  await updateSnapshots();
}
```

### レートリミット対策
- 各APIコール間に1秒のwait
- 429エラー時は指数バックオフ（1s → 2s → 4s、最大3回リトライ）
- 1日の総リクエスト数上限を設定（200リクエスト/日）

---

## 6. 分析ロジック設計: x-trend-report

### 実行タイミング
毎日 AM 8:00 JST（データ収集の1時間後）

### 分析の流れ

#### Step 1: データ取得
```sql
-- 直近24hで新規収集されたトレンド投稿
SELECT * FROM x_trend_tweets
WHERE first_seen_at >= NOW() - INTERVAL '24 hours'
ORDER BY (like_count + retweet_count * 3 + quote_count * 5) DESC;

-- 過去7日のカテゴリ別集計
SELECT
  source_keyword,
  COUNT(*) as tweet_count,
  AVG(like_count) as avg_likes,
  AVG(retweet_count) as avg_retweets,
  MAX(like_count) as max_likes
FROM x_trend_tweets
WHERE first_seen_at >= NOW() - INTERVAL '7 days'
GROUP BY source_keyword
ORDER BY avg_likes DESC;
```

#### Step 2: Claude分析（以下の観点）

1. **今日のバズ投稿TOP10**
   - エンゲージメント総合スコア順
   - 各投稿の「なぜバズったか」仮説

2. **コンテンツカテゴリ分析**
   - ニュース速報系 / ハウツー・Tips系 / 意見・考察系 / ネタ・ユーモア系 / 事例紹介系
   - どのカテゴリが今伸びているか

3. **フォーマット分析**
   - スレッド vs 単発
   - 画像付き vs テキストのみ
   - 短文(〜140字) vs 長文
   - フック（書き出し）のパターン

4. **投稿タイミング分析**
   - 曜日×時間帯のヒートマップ的分析
   - 最も伸びやすい投稿時間帯

5. **トピックトレンド**
   - 今週急上昇しているキーワード
   - 先週との比較

6. **投稿戦略提案**
   - 「いけとも」アカウントとして取るべきポジション
   - 具体的な投稿案3〜5件
     - タイトル/書き出し
     - 想定フック
     - 推奨投稿時間帯
     - 参考にしたバズ投稿

---

## 7. Slack通知設計

### Webhook
既存のX日次レポートと同じWebhookを使用（または別チャンネル作成）
```
https://hooks.slack.com/services/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
```

### レポートフォーマット

```
🔥 Xトレンドレポート（YYYY-MM-DD）
━━━━━━━━━━━━━━━━━━━━━━━━━━

■ 今日の収集サマリ
- 収集投稿数: XXX件 → フィルタ後: XX件
- 新規バズ投稿: X件
- 推定APIコスト: $X.XX

■ バズ投稿 TOP 5
1. @username「投稿本文の冒頭80文字...」
   ❤️ XXX  🔄 XX  💬 XX  🔗 URL
   💡 バズ要因: ○○の話題 × ○○なフック

2. [同様に2-5]

■ 今週のトレンド
- 急上昇: AIエージェント関連（前週比+40%）
- 安定: ChatGPT Tips系
- 下降: 画像生成系

■ 伸びパターン分析
- フック: 「〇〇してみた結果」系が好調
- フォーマット: スレッド形式の事例紹介が伸びている
- 時間帯: 7-8時台 / 12時台 / 20-21時台が高エンゲージメント

■ 投稿提案（3案）
案1: [タイトル]
  書き出し: 「...」
  参考: @xxxの投稿 (URL)
  推奨時間: 7:30

案2: [同様]
案3: [同様]
```

---

## 8. 実装ロードマップ

### Phase 1: 基盤構築（1-2日）
- [ ] Supabase テーブル6つ作成
- [ ] 初期キーワード・アカウントデータ投入
- [ ] X API Bearer Tokenの確認（既存と共有 or 新規）

### Phase 2: データ収集（2-3日）
- [ ] Edge Function `x-trend-fetch` 開発
- [ ] テスト実行（1キーワード・1アカウントで試行）
- [ ] コスト確認（Developer Consoleで実消費チェック）
- [ ] 全キーワード・アカウントでの本番実行

### Phase 3: 分析・レポート（1-2日）
- [ ] Coworkスキル `x-trend-report` 作成
- [ ] 分析ロジックのテスト
- [ ] Slack通知テスト

### Phase 4: 自動化（1日）
- [ ] Edge Functionのcronスケジュール設定（AM 7:00 JST）
- [ ] Coworkスケジュールタスク設定（AM 8:00 JST）
- [ ] エラー通知の設定

### Phase 5: 運用・改善（継続）
- [ ] キーワード・アカウントの追加・調整
- [ ] エンゲージメント閾値のチューニング
- [ ] 既存の自分投稿レポートとの統合検討
- [ ] コスト最適化（不要なクエリの削除等）

---

## 9. 注意事項・リスク

### コスト管理
- Developer Consoleで日次の消費額を監視
- Spending Limitを月$200に設定（初期）
- 不要なキーワードは早めにis_active=falseにする

### API制限
- Search Recent Tweets は過去7日分のみ（フルアーカイブは不可）
- レートリミットに注意（429エラー対策を実装済み）
- インプレッション数は他人の投稿では取得不可

### データ品質
- 日本語検索の精度（ノイズ混入の可能性）→ フィルタ閾値で調整
- スパム・宣伝投稿の混入 → 分析時にClaude判定で除外
- アカウント凍結・削除への対応 → エラーハンドリングで対処
