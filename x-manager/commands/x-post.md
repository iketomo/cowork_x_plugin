---
description: X（Twitter）に投稿する。投稿文テキストと任意で画像URLを指定可能
argument-hint: [投稿テキスト] [--image 画像URL]
allowed-tools: ["Skill", "Read", "AskUserQuestion"]
---

# X投稿実行

x-postスキルを使って、X（Twitter）に投稿してください。

## 実行手順

1. `$ARGUMENTS` にテキストが指定されている場合はそれを投稿文として使用
2. テキストが指定されていない場合は、直前の会話で作成した投稿文を使用
3. 直前の会話で `x-image` スキルにより `image_url` が生成されている場合は、画像付き投稿を提案する
4. **必ず**ユーザーに投稿内容の最終確認を行う（テキスト + 画像有無を明示）
5. 承認後、Supabase MCP の execute_sql で pg_net 経由で Edge Function を呼び出し投稿
6. レスポンスを確認し、投稿URLを報告

## 画像付き投稿について

- x-imageスキルで生成された `image_url`（Supabase Storage の公開URL）を `image_url` フィールドに渡すと画像付きツイートになる
- Edge Function内部で X API v1.1 media upload → v2 tweet の順に処理される
- 画像付きの場合は `timeout_milliseconds := 30000` を pg_net に指定すること

**重要**: ユーザーの明示的な承認なしに絶対に投稿しないこと。
