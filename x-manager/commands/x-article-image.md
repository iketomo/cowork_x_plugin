---
description: 記事・カード用の横長画像（5:2）をNano Banana 2で生成する
argument-hint: [記事タイトル or 画像用テキスト or テキストファイルパス]
allowed-tools: ["Bash", "Read", "Write"]
---

# 記事・カード用画像生成（5:2）

Nano Banana 2（Gemini AI）を Supabase Edge Function 経由で呼び出し、5:2 比率の横長画像を生成する。

## 前提条件
- Supabase プロジェクトと Edge Function がセットアップ済みであること
- `x-manager/config.local.md` に以下が設定されていること
  - Supabase プロジェクトID
  - Supabase Anon Key
  - Edge Function Base URL（例: `https://your-project-id.supabase.co/functions/v1`）
- Supabase 側に、`x-generate-article-image` Edge Function がデプロイ済みであること
  - リクエスト仕様:
    - URL: `{Edge Function Base URL}/x-generate-article-image`
    - メソッド: `POST`
    - ヘッダー:
      - `Authorization: Bearer {Supabase Anon Key}`
      - `Content-Type: application/json`
    - ボディ: `{"text": "画像用テキスト"}`（必要に応じて `id_suffix` を追加）
  - レスポンス仕様:
    - 正常時: `{"success": true, "image_url": "https://.../x-images/...", ...}`

## 実行手順

1. **x-article-image スキル**（`skills/x-article-image/SKILL.md`）に従って処理する
2. VMからの直接HTTP通信はプロキシブロックされるため、Supabase MCP の `execute_sql` で pg_net 経由で Edge Function を呼び出す
3. 生成された `image_url` をユーザーに報告する

## 画像仕様
- モデル: Nano Banana 2（`gemini-3.1-flash-image-preview`）
- アスペクト比: **5:2**（横長・記事バナー向け）
- スタイル: 日本のビジネス書風「ゆるいイラスト」
