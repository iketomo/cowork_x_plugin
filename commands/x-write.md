---
description: X投稿の文章を作成する。テーマを引数に指定可能
argument-hint: [テーマやニュースURL]
allowed-tools: ["Skill", "Read", "Write", "WebSearch", "Bash"]
---

# X投稿文作成

x-writingスキルを使って、X投稿の文章を作成してください。

## 実行手順

1. $ARGUMENTS にテーマやURLが指定されている場合はそれをベースに作成
2. テーマが指定されていない場合は、ユーザーに確認
3. x-writingスキルの文章要件・成功パターンに従って投稿文を作成
4. 作成後、ユーザーに提示して修正点を確認

## 投稿後の流れ
文章確定後、ユーザーが希望すれば `/x-post` で投稿、`/x-image` で画像生成も可能です。
