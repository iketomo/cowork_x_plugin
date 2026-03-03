---
name: x-image
description: >
  X投稿用の画像をGemini AIで生成するスキル。
  Supabase Edge Function `x-generate-image` を呼び出し、
  日本のビジネス書風「ゆるいイラスト」スタイルの正方形画像を生成してSupabase Storageに保存し、公開URLを返す。
  「X投稿の画像を作って」「投稿用の画像を生成」「ツイートに画像を添付したい」
  「Xの画像生成」「x-image」などのリクエストで発動。
allowed-tools: ["Bash", "Read"]
---

# X投稿用画像生成

Supabase Edge Function (`x-generate-image`) 経由で Gemini AI を使って投稿用画像を生成する。

## 前提条件

- Supabase に Edge Function `x-generate-image` がデプロイ済み（モデル: `gemini-3.1-flash-image-preview`）
- Supabase Secrets に `GEMINI_API_KEY` が設定済み
  - 未設定の場合は `https://aistudio.google.com/` でAPIキーを取得し、
    Supabase Dashboard → Settings → Edge Functions → Secrets に `GEMINI_API_KEY` として登録する

## 実行フロー

### Step 1: 設定値の取得
`Read` で `x-manager/config.local.md` を読み込み、以下を取得する:
- `Anon Key`
- `Edge Function Base URL`

### Step 2: 投稿テキストの決定
- `$ARGUMENTS` にテキストが指定されていればそれを使用
- 指定がない場合は、直前の会話で作成した投稿文を使用
- テキストがない場合はユーザーに確認

### Step 3: Supabase SQL（pg_net）経由で Edge Function を呼び出す

VMからの直接HTTP通信はプロキシブロックされるため、Supabase MCP の `execute_sql` を使って pg_net 経由で呼び出す。

**リクエスト送信（タイムアウトは60秒に設定すること）:**

```sql
SELECT net.http_post(
  url := '{Edge Function Base URL}/x-generate-image',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer {Anon Key}"}'::jsonb,
  body := '{"text": "{投稿テキスト}", "id_suffix": "xxx"}'::jsonb,
  timeout_milliseconds := 60000
) AS request_id;
```

**レスポンス取得（45秒待機してから実行）:**

```sql
SELECT id, status_code, content::text, error_msg
FROM net._http_response
WHERE id = {request_id};
```

### Step 4: 結果の確認と報告

- `status_code = 200` かつ `content` に `"success":true` → `image_url` をユーザーに報告
- `status_code = 500` かつ `GEMINI_API_KEY is not configured` → Supabase SecretsへのAPIキー設定を案内
- `error_msg` に Timeout → リクエストIDで再度ポーリングするか、待機時間を増やして再実行

## 生成される画像の特徴

- モデル: `gemini-3.1-flash-image-preview`
- スタイル: 日本のビジネス書風「ゆるいイラスト」（水彩風淡い色、手描き線）
- サイズ: 1:1 正方形（X/Twitter最適化）
- テキスト: 画像内テキストはすべて日本語
- 保存先: Supabase Storage `x-images` バケット（public）
- URL形式: `https://iltymrnkqchixvtpvewm.supabase.co/storage/v1/object/public/x-images/YYYY/MM/x_post_image_YYYYMMDDHHMMSS_{suffix}.png`
