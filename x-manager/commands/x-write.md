---
description: X投稿の文章を作成する。テーマを引数に指定可能
argument-hint: [テーマやニュースURL]
allowed-tools: ["Read", "WebSearch", "Task"]
---

# X投稿文作成

x-writerサブエージェントに文章作成を委譲してください。
メインエージェントはSKILL.mdを読む必要はありません。

## 実行手順

### Step 1: テーマ確定
- $ARGUMENTS にテーマやURLが指定されている場合はそれを使う
- テーマが指定されていない場合は、ユーザーに確認

### Step 2: アカウント情報の取得
- `x-manager/config.local.md` を読み、Xアカウント情報（プロフィール・フォロワー数等）を取得

### Step 3: x-writerサブエージェントに委譲
Taskツール（sonnetモデル）を起動し、以下のプロンプトを渡す：

```
以下の手順でX投稿文を作成してください。

■ テーマ
{テーマ / ニュースURL / 関連情報}

■ Xアカウント情報
{config.local.mdから取得した内容}

■ 作業手順
1. x-manager/agents/x-writer.md をReadし、文章要件を把握
2. x-manager/reference/x-writing-guidelines.md をReadし、詳細な文章要件・NGパターンを把握
3. x-manager/reference/x-writing-examples.md をReadし、成功例のトーン・構成・文量のお手本を把握
4. URLが指定されている場合はWebSearchで関連情報を補足
5. 上記すべてを踏まえて投稿文を作成
6. x-writer.md の出力フォーマットに従って返す
```

### Step 4: 結果をユーザーに提示
- サブエージェントから返された投稿文と投稿メモをユーザーに提示
- 修正点があれば対応（修正もサブエージェントに再委譲してよい）

## 投稿後の流れ
文章確定後、ユーザーが希望すれば `/x-post` で投稿、`/x-image` で画像生成も可能です。
