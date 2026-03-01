---
name: x-post
description: X（Twitter）に投稿するスキル。x-writingスキル等で作成した投稿文を、Supabase Edge Function経由でX APIに送信して実際に投稿する。「Xに投稿して」「ツイートして」「Xにポストして」「投稿を公開して」「ツイートを送信」「x-post」などのリクエストで発動。
version: 1.0.0
---

# X投稿スキル（x-post）

## 概要
x-writingスキル等で作成した投稿文を、X（Twitter）APIを通じて実際に投稿するスキル。
Supabase Edge Function `x-post-tweet` を、pg_net経由で呼び出してツイートを投稿する。

## トリガー
以下のようなリクエストで発動する：
- 「Xに投稿して」「ツイートして」「Xにポストして」
- 「この文章をXに投稿」「投稿を公開して」
- 「ツイートを送信」「Xに送って」
- 「x-post」

## 前提条件
- Supabase Edge Function `x-post-tweet` がデプロイ済み
- X API OAuth 1.0aキー（X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET）がSupabase Secretsに設定済み
- Supabaseプロジェクト: `config.local.md` の Supabase 設定を参照
- pg_net拡張が有効化済み（v0.20.0）

## 投稿フロー

### ステップ1: 投稿文の準備
ユーザーから投稿文を受け取る。以下のいずれかの方法：
1. ユーザーが直接テキストを指定
2. x-writingスキルで生成した投稿文を使用
3. 会話の中で確定した投稿文を使用

### ステップ2: 投稿前の確認（必須）
投稿前に**必ず**ユーザーに最終確認を行う：

```
📝 以下の内容でXに投稿します：

---
{投稿文テキスト}
---

文字数: {文字数}文字
投稿してよろしいですか？
```

**ユーザーの明示的な承認なしに絶対に投稿しない。**

### ステップ3: 投稿実行（pg_net方式）
ユーザーの承認後、Supabase MCPの `execute_sql` で pg_net を使ってEdge Functionを呼び出す。

#### 呼び出し方法

Supabase MCPの `execute_sql` ツールで以下のSQLを実行する：

```sql
-- ※ {EDGE_FUNCTION_URL} と {ANON_KEY} は config.local.md から取得すること
SELECT net.http_post(
  url := '{EDGE_FUNCTION_URL}/x-post-tweet',
  headers := '{
    "Content-Type": "application/json",
    "Authorization": "Bearer {ANON_KEY}"
  }'::jsonb,
  body := '{"text": "ここに投稿テキスト"}'::jsonb
);
```

- `project_id` は `config.local.md` の Supabase プロジェクトID を参照
- 戻り値はリクエストID（整数）

#### レスポンスの確認

投稿リクエスト送信後、2〜3秒待ってからレスポンスを確認する：

```sql
SELECT id, status_code, content::text, timed_out
FROM net._http_response
WHERE id = {リクエストID};
```

- `status_code = 200` かつ contentに `"success": true` があれば投稿成功
- contentにはtweet_id, url, text, char_countが含まれる

### ステップ4: 結果の報告
投稿成功時（status_code=200, success=true）：
```
✅ Xに投稿しました！
🔗 {投稿URL}
```

投稿失敗時：
```
❌ 投稿に失敗しました
エラー: {エラー内容}
```

## 重要ルール

### 文字数について
- X Premium加入済みのため、長文投稿が可能（文字数上限なし）
- 投稿前に文字数を表示するが、制限チェックは行わない

### 改行・絵文字の扱い
- 改行（`\n`）はそのままJSON文字列に含める
- 絵文字はUnicodeそのまま送信（エスケープ不要）
- Edge Functionが `Content-Type: application/json` でPOSTするため、日本語・絵文字は正しく処理される

### 安全対策
1. **投稿前の確認は省略しない** — 必ずユーザーの「はい」「OK」等の明示的承認を得る
2. **同一テキストの重複投稿を避ける** — 直前に同じ内容を投稿していないか確認
3. **エラー時のリトライは手動** — 自動リトライせず、ユーザーに状況を報告して判断を仰ぐ

## Edge Function仕様

### エンドポイント
`POST {EDGE_FUNCTION_URL}/x-post-tweet`（※ config.local.md 参照）

### リクエスト
```json
{
  "text": "投稿テキスト"
}
```

### レスポンス（成功）
```json
{
  "success": true,
  "tweet_id": "1234567890",
  "url": "https://x.com/{X_USERNAME}/status/1234567890",
  "text": "投稿テキスト",
  "char_count": 7
}
```

### レスポンス（エラー）
```json
{
  "error": "エラーメッセージ",
  "status": 403,
  "detail": { ... }
}
```

### 認証
- `Authorization: Bearer {SUPABASE_ANON_KEY}` ヘッダーが必要
- Edge Function内部でOAuth 1.0aを使ってX APIに認証

## x-writingスキルとの連携例

典型的なワークフロー：
1. ユーザー: 「AIエージェントについてX投稿を書いて、そのまま投稿して」
2. Claude: x-writingスキルで投稿文を生成
3. Claude: 生成した投稿文をユーザーに提示し確認
4. ユーザー: 「OK、投稿して」
5. Claude: x-postスキルで `execute_sql` + pg_net でEdge Functionを呼び出し投稿
6. Claude: レスポンス確認後、投稿結果（URL）を報告
