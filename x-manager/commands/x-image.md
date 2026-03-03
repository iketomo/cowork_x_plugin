---
description: X投稿用の画像をSupabase Edge Function経由で生成する
argument-hint: [投稿テキスト or テキストファイルパス]
allowed-tools: ["Bash", "Read", "Write"]
---

# X投稿用画像生成

Gemini API を直接呼び出さず、**Supabase の Edge Function 側で画像生成を行い、ClaudeVM からはその Edge Function を叩くだけ**にしてください。

## 前提条件
- Supabase プロジェクトと Edge Function がセットアップ済みであること
- `x-manager/config.local.md` に以下が設定されていること
  - Supabase プロジェクトID
  - Supabase Anon Key
  - Edge Function Base URL（例: `https://your-project-id.supabase.co/functions/v1`）
- Supabase 側に、Gemini で画像を生成する Edge Function（例: `x-generate-image`）がデプロイ済みであること  
  - リクエスト仕様（例）:
    - URL: `{Edge Function Base URL}/x-generate-image`
    - メソッド: `POST`
    - ヘッダー:
      - `Authorization: Bearer {Supabase Anon Key}`
      - `Content-Type: application/json`
    - ボディ:
      - `{"text": "投稿テキスト"}` （必要に応じて追加フィールドを拡張）
  - レスポンス仕様（例）:
    - 正常時: `{"image_url": "https://.../public/x_images/xxx.png"}` のような公開URLまたはファイルパスを返す

※ `scripts/generate_image.py` はローカル実行用サンプルとして残しても構いませんが、ClaudeVM 上のコマンド実行では **使わず**、必ず Edge Function 経由にしてください。

## 実行手順

1. **投稿テキストの決定**
   - `$ARGUMENTS` にテキストが指定されている場合はそれを使用
   - テキストが指定されていない場合は、直前の会話で作成した投稿文を使用

2. **Supabase 設定値の取得**
   - `x-manager/config.local.md` を `Read` し、以下の値をメモ
     - Supabase プロジェクトID
     - Supabase Anon Key
     - Edge Function Base URL
   - Edge Function のフルURLは、`{Edge Function Base URL}/x-generate-image` のように組み立てる

3. **Bash で Edge Function を呼び出し**

   呼び出しイメージ（擬似コード）:

   ```bash
   SUPABASE_FUNCTION_URL="https://your-project-id.supabase.co/functions/v1/x-generate-image"
   SUPABASE_ANON_KEY="your-supabase-anon-key"
   POST_TEXT="ここに投稿テキスト"

   curl -s -X POST "$SUPABASE_FUNCTION_URL" \
     -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
     -H "Content-Type: application/json" \
     -d "{\"text\": \"$POST_TEXT\"}"
   ```

   - 実際には、`config.local.md` から取得した値と、Step1 で決めた投稿テキストでコマンドを組み立てて実行すること
   - レスポンスが JSON の場合は、`Write` + `Read` などを使って `image_url` を抽出してもよいし、そのまま標準出力を確認してもよい

4. **生成結果の報告**
   - レスポンスに `image_url`（または画像ファイルパス）が含まれている場合、それをユーザーに報告する
   - 画像が Supabase Storage に保存されている場合は、「公開URL」または「ダウンロード手順」も簡潔に伝える
   - エラーが返ってきた場合は、HTTPステータスコードとレスポンス本文をユーザーに共有する

## 画像スタイル（固定）
- 日本のビジネス書風「ゆるいイラスト」
- 水彩風の淡い色、手描き風の線
- 1:1（正方形）
- テキストは日本語
- 上記スタイル要件は **Edge Function 内でのプロンプト設計** に反映すること（ClaudeVM 側ではスタイル詳細を意識せず、投稿テキストのみ渡せばよい構成にしておくと扱いやすい）

