---
name: x-post
description: X（Twitter）に投稿するスキル。x-writingスキル等で作成した投稿文を、Supabase Edge Function経由でX APIに送信して実際に投稿する。画像URLを渡すと画像付き投稿も可能。「Xに投稿して」「ツイートして」「Xにポストして」「投稿を公開して」「ツイートを送信」「画像付きで投稿」「x-post」などのリクエストで発動。
version: 1.1.0
---

# X投稿スキル（x-post）

## 概要
投稿文（+ 任意で画像URL）を、X（Twitter）APIを通じて実際に投稿するスキル。
Supabase Edge Function `x-post-tweet` を、pg_net経由で呼び出してツイートを投稿する。
画像URLを渡すと、X API v1.1 media upload を経由して画像付きツイートを投稿できる。

## トリガー
- 「Xに投稿して」「ツイートして」「Xにポストして」
- 「この文章をXに投稿」「投稿を公開して」
- 「画像付きで投稿して」「生成した画像と一緒に投稿」
- 「x-post」

## 前提条件
- Supabase Edge Function `x-post-tweet` がデプロイ済み（v11以降）
- X API OAuth 1.0aキーがSupabase Secretsに設定済み:
  `X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_TOKEN_SECRET`
- 画像付き投稿の場合: 画像が公開URLでアクセス可能であること（Supabase Storage public URLなど）
- pg_net拡張が有効化済み

## 投稿フロー

### ステップ1: 投稿文と画像URLの準備
ユーザーから投稿文と（任意で）画像URLを受け取る：
1. ユーザーが直接テキストを指定
2. x-writingスキルで生成した投稿文を使用
3. x-imageスキルで生成した `image_url` を画像として使用

### ステップ2: 投稿前の確認（必須）
投稿前に**必ず**ユーザーに最終確認を行う：

```
📝 以下の内容でXに投稿します：

---
{投稿文テキスト}
---

文字数: {文字数}文字
画像: {image_urlがあれば "あり（{URL}）" / なければ "なし"}

投稿してよろしいですか？
```

**ユーザーの明示的な承認なしに絶対に投稿しない。**

### ステップ3: 投稿実行（pg_net方式）
ユーザーの承認後、Supabase MCPの `execute_sql` で pg_net を使ってEdge Functionを呼び出す。

#### テキストのみ投稿

```sql
SELECT net.http_post(
  url := '{EDGE_FUNCTION_URL}/x-post-tweet',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer {ANON_KEY}"}'::jsonb,
  body := '{"text": "投稿テキスト"}'::jsonb
) AS request_id;
```

#### 画像付き投稿

```sql
SELECT net.http_post(
  url := '{EDGE_FUNCTION_URL}/x-post-tweet',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer {ANON_KEY}"}'::jsonb,
  body := '{"text": "投稿テキスト", "image_url": "https://...supabase.co/storage/v1/object/public/x-images/..."}'::jsonb,
  timeout_milliseconds := 30000
) AS request_id;
```

- `EDGE_FUNCTION_URL` と `ANON_KEY` は `config.local.md` から取得
- 画像付きの場合はメディアアップロードが入るため `timeout_milliseconds := 30000` を指定

#### レスポンスの確認

リクエスト送信後、5秒程度待ってから確認：

```sql
SELECT id, status_code, content::text, timed_out
FROM net._http_response
WHERE id = {リクエストID};
```

### ステップ4: 結果の報告

成功時（status_code=200, success=true）：
```
✅ Xに投稿しました！
🔗 {投稿URL}
🖼 画像: あり / なし
```

失敗時：
```
❌ 投稿に失敗しました
エラー: {エラー内容}
```

## Edge Function仕様（x-post-tweet v11）

### エンドポイント
`POST {EDGE_FUNCTION_URL}/x-post-tweet`

### リクエスト
```json
{
  "text": "投稿テキスト",
  "image_url": "https://...supabase.co/storage/v1/object/public/x-images/...png"
}
```
- `text`: 必須
- `image_url`: 任意。公開アクセス可能なURL。Supabase Storage public URLが推奨。

### 内部フロー（image_url指定時）
1. `image_url` の画像をダウンロード
2. X API v1.1 `POST https://upload.twitter.com/1.1/media/upload.json` に multipart/form-data でアップロード
3. 取得した `media_id_string` を `media: { media_ids: [id] }` として X API v2 に渡して投稿

### レスポンス（成功）
```json
{
  "success": true,
  "tweet_id": "1234567890",
  "url": "https://x.com/iketomo2/status/1234567890",
  "text": "投稿テキスト",
  "char_count": 10,
  "has_image": true,
  "media_ids": ["9876543210"]
}
```

## 重要ルール

1. **投稿前の確認は省略しない** — 必ずユーザーの明示的承認を得る
2. **重複投稿を避ける** — 直前に同じ内容を投稿していないか確認
3. **エラー時のリトライは手動** — 自動リトライせず、状況を報告して判断を仰ぐ
4. **image_urlのアクセス可能性を確認** — Supabase Storage のpublicバケットのURLを推奨

## 連携ワークフロー例

**画像付き投稿の典型フロー：**
1. x-writingスキルで投稿文を生成
2. x-imageスキルで投稿文に対応した画像を生成 → `image_url` を取得
3. x-postスキルで `text` + `image_url` を渡して投稿確認 → 投稿実行
