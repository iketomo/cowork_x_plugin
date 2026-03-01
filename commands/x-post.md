---
description: X（Twitter）に投稿する。投稿文テキストを引数に指定可能
argument-hint: [投稿テキスト]
allowed-tools: ["Skill", "Read", "AskUserQuestion"]
---

# X投稿実行

x-postスキルを使って、X（Twitter）に投稿してください。

## 実行手順

1. $ARGUMENTS にテキストが指定されている場合はそれを投稿文として使用
2. テキストが指定されていない場合は、直前の会話で作成した投稿文を使用
3. **必ず**ユーザーに投稿内容の最終確認を行う（AskUserQuestion）
4. 承認後、Supabase MCP の execute_sql で pg_net 経由で Edge Function を呼び出し投稿
5. レスポンスを確認し、投稿URLを報告

**重要**: ユーザーの明示的な承認なしに絶対に投稿しないこと。
