---
name: x-post
description: X（Twitter）に投稿または下書き保存するスキル。x-writingスキル等で作成した投稿文を、API経由で投稿するか、Chrome MCP経由でXの下書きに保存する。「Xに投稿して」「ツイートして」「下書きにして」「Xの下書きに保存」「x-post」などのリクエストで発動。
version: 2.0.0
---

# X投稿スキル（x-post）

## 概要
投稿文（+ 任意で画像URL）を、X（Twitter）に投稿または下書き保存するスキル。
- **投稿モード**: Supabase Edge Function `x-post-tweet` をpg_net経由で呼び出して即時投稿
- **下書きモード**: Chrome MCP でX.comの投稿画面にテキストを入力し、下書き保存

## トリガー
- 「Xに投稿して」「ツイートして」「Xにポストして」
- 「この文章をXに投稿」「投稿を公開して」
- 「画像付きで投稿して」「生成した画像と一緒に投稿」
- 「Xの下書きにして」「下書きに保存して」「下書きをセットして」
- 「x-post」

## 前提条件

### 投稿モード
- Supabase Edge Function `x-post-tweet` がデプロイ済み（v11以降）
- X API OAuth 1.0aキーがSupabase Secretsに設定済み:
  `X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_TOKEN_SECRET`
- 画像付き投稿の場合: 画像が公開URLでアクセス可能であること
- pg_net拡張が有効化済み

### 下書きモード
- Chrome MCP（Claude in Chrome拡張）が接続済み
- X.comにブラウザでログイン済み

## モード判定

ユーザーの指示から投稿モードか下書きモードかを判定する：

| ユーザーの表現 | モード |
|---|---|
| 「投稿して」「ポストして」「ツイートして」 | 投稿モード |
| 「下書きにして」「下書き保存」「ドラフトにして」 | 下書きモード |
| 「x-post」（引数なし） | ユーザーに確認 |

判断がつかない場合は「投稿しますか？それとも下書きに保存しますか？」と確認する。

---

## 投稿モード

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

---

## 下書きモード（Chrome MCP）

### ステップ1: Chrome MCP接続確認
`tabs_context_mcp` でChrome拡張の接続を確認する。
- 接続されていない場合 → 「Chrome拡張を接続してください」とユーザーに案内
- `createIfEmpty: true` でタブグループを作成

### ステップ2: X.comの投稿画面を開く
```
navigate → https://x.com/compose/post
```
- ログインページにリダイレクトされた場合 → 「X.comにログインしてから教えてください」と案内し、待機
- 投稿画面（compose/post）が表示されたら次へ

### ステップ3: テキスト入力
1. 投稿画面のテキストエリアをクリック（「いまどうしてる？」の入力欄）
2. `type` アクションで投稿文テキストを入力
3. スクリーンショットで入力内容を確認

### ステップ4: 下書き保存
1. 投稿画面左上の `×` ボタンをクリック（座標はスクリーンショットで確認）
2. 「ポストを保存しますか？」ダイアログで「保存」をクリック
3. 「下書きが保存されました。」の確認メッセージを確認

### ステップ5: 結果の報告
```
✅ Xの下書きに保存しました！
X.com → 下書き から編集・投稿できます。
⚠️ 画像はX画面から手動で添付してください。
```

### 下書きモードの制約事項
- **画像の添付は不可** — Chrome MCP経由ではファイルアップロードができないため、画像はX画面から手動で添付する必要がある
- **X.comへのログインが必要** — ブラウザでログイン済みであること
- **Chrome MCP接続が必要** — Claude in Chrome拡張が有効であること

---

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

1. **投稿前の確認は省略しない** — 必ずユーザーの明示的承認を得る（投稿モードのみ。下書きモードはテキスト入力後に保存してよい）
2. **重複投稿を避ける** — 直前に同じ内容を投稿していないか確認
3. **エラー時のリトライは手動** — 自動リトライせず、状況を報告して判断を仰ぐ
4. **image_urlのアクセス可能性を確認** — Supabase Storage のpublicバケットのURLを推奨
5. **下書きモードの画像制約を伝える** — 画像付き投稿を下書きにする場合、画像は手動添付が必要な旨を必ず伝える

## 連携ワークフロー例

**画像付き投稿の典型フロー：**
1. x-writingスキルで投稿文を生成
2. x-imageスキルで投稿文に対応した画像を生成 → `image_url` を取得
3. x-postスキルで `text` + `image_url` を渡して投稿確認 → 投稿実行

**下書き保存フロー：**
1. x-writingスキルで投稿文を生成
2. x-postスキル（下書きモード）でXの下書きに保存
3. ユーザーがX.comから画像添付・最終確認・投稿
