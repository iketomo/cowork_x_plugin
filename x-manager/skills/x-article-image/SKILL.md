---
name: x-article-image
description: >
  記事・カード用の横長画像（5:2）をNano Banana 2（Gemini AI）で生成するスキル。
  必ず日本語のタイトル文章を引きがある形で含める。文字は中央に大きく横いっぱいにする。実行環境はエージェントが利用できるツールに合わせる。
  「記事用の画像を作って」「カード画像を生成」「横長のヘッダー画像」「記事バナー」
  「x-article-image」「記事画像生成」などのリクエストで発動。
allowed-tools: ["Bash", "Read"]
---

# 記事・カード用画像生成（5:2）

Nano Banana 2（Gemini AI）を使って記事用横長画像を生成する。**実行環境はエージェントの利用可能ツールに合わせて選ぶ**（Nano Banana 2 をデフォルトで使えるツールがあればそれを優先し、なければ Supabase Edge Function を利用する）。

## 前提条件

- **Nano Banana 2 実行環境**: エージェント環境で利用できる方法を選ぶ。
  - エージェントに Nano Banana 2（または `gemini-3.1-flash-image-preview`）を直接呼び出せる画像生成ツールがある場合 → そのツールを使用する。
  - 上記がない場合 → Supabase に Edge Function `x-generate-article-image` がデプロイ済みであること。Supabase Secrets に `GEMINI_API_KEY` が設定済みであること（未設定時は `https://aistudio.google.com/` でAPIキーを取得し、Supabase Dashboard → Edge Functions → Secrets に登録）。
- **保存**: Supabase Storage への保存は**必須ではない**。画像の生成とユーザーへの返却（URL または画像データ）ができればよい。

## 実行フロー

### Step 1: 実行環境の選択
- エージェントが利用できるツールを確認し、**Nano Banana 2（または gemini-3.1-flash-image-preview）で画像生成できるツール**があればそれを優先して使う。
- そのようなツールがない場合のみ、Step 2 以降の Supabase Edge Function 経由の手順に進む。

### Step 2: 設定値の取得（Edge Function を使う場合のみ）
`Read` で `x-manager/config.local.md` を読み込み、以下を取得する:
- `Anon Key`
- `Edge Function Base URL`

### Step 3: 画像用テキストの決定
- `$ARGUMENTS` にテキストが指定されていればそれを使用
- 指定がない場合は、直前の会話で作成した記事タイトル・要約・投稿文を使用
- テキストがない場合はユーザーに確認
- **重要**: 記事タイトル・画像用テキストは必ず日本語で指定すること。英語や他言語の場合は日本語に翻訳してから渡す

### Step 4: 画像生成の実行

**エージェントツールで Nano Banana 2 を使う場合:**  
そのツールの仕様に従い、スタイル「日本のビジネス書風ゆるいイラスト」・アスペクト比 5:2 を指定して生成する。**文字は中央に大きく、横いっぱいに配置する。** 保存はツールの挙動に任せ、Supabase Storage は必須ではない。

**Supabase Edge Function を使う場合（Step 5）:**  
以下に従い pg_net 経由で呼び出す。Edge Function が Storage に保存する場合はその URL を返せるが、保存自体は必須要件ではない。

### Step 5: Supabase SQL（pg_net）経由で Edge Function を呼び出す（Edge Function を使う場合のみ）

VMからの直接HTTP通信はプロキシブロックされるため、Supabase MCP の `execute_sql` を使って pg_net 経由で呼び出す。

**リクエスト送信（タイムアウトは60秒に設定すること）:**

```sql
SELECT net.http_post(
  url := '{Edge Function Base URL}/x-generate-article-image',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer {Anon Key}"}'::jsonb,
  body := '{"text": "{画像用テキスト}", "id_suffix": "xxx"}'::jsonb,
  timeout_milliseconds := 60000
) AS request_id;
```

**レスポンス取得（45秒待機してから実行）:**

```sql
SELECT id, status_code, content::text, error_msg
FROM net._http_response
WHERE id = {request_id};
```

### Step 6: 結果の確認と報告

- `status_code = 200` かつ `content` に `"success":true` → `image_url` をユーザーに報告
- `status_code = 500` かつ `GEMINI_API_KEY is not configured` → Supabase SecretsへのAPIキー設定を案内
- `error_msg` に Timeout → リクエストIDで再度ポーリングするか、待機時間を増やして再実行

## 生成される画像の特徴

- モデル: `gemini-3.1-flash-image-preview`（Nano Banana 2）
- スタイル: 日本のビジネス書風「ゆるいイラスト」（水彩風淡い色、手描き線）
- アスペクト比: **5:2**（横長・記事・カード用）
- テキスト: 画像内テキストはすべて日本語。中央に大きく、横いっぱいに配置する
- 保存: Supabase Storage への保存は**必須ではない**。Edge Function 利用時は `x-images` バケットに保存される場合があり、そのときの URL 形式は `https://{project}.supabase.co/storage/v1/object/public/x-images/YYYY/MM/x_article_image_YYYYMMDDHHMMSS_{suffix}.png`
