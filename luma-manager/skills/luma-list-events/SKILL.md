---
name: luma-list-events
description: Lumaイベントの一覧をSupabaseから取得して表示するスキル。「イベント一覧」「Lumaのイベントを見せて」「今後のイベントは？」「過去のイベント一覧」「luma-list-events」などのリクエストで発動。
---

Lumaイベントの一覧を `config.local.md` に記載のSupabaseプロジェクトから取得して表示してください。

## 手順

### Step 1: フィルター条件の確認

ユーザーの指示から、どのイベントを表示するか判断する：
- 「今後」「upcoming」「これから」→ `upcoming` フィルター（start_at >= NOW()）
- 「過去」「past」「終了済み」 → `past` フィルター（start_at < NOW()）
- 指定なし → `all`（全件）

### Step 2: Supabaseからデータ取得

Supabase MCPの `execute_sql` ツールを使い、`config.local.md` のプロジェクトIDに対して以下のSQLを実行する。

**全件取得（デフォルト）:**
```sql
SELECT
  api_id,
  name,
  start_at AT TIME ZONE 'Asia/Tokyo' AS start_jst,
  end_at AT TIME ZONE 'Asia/Tokyo' AS end_jst,
  guest_count,
  waitlist_count,
  registration_limit,
  url,
  cover_url,
  event_type,
  location_type,
  visibility
FROM luma_events
ORDER BY start_at DESC;
```

**今後のイベントのみ:**
```sql
SELECT
  api_id,
  name,
  start_at AT TIME ZONE 'Asia/Tokyo' AS start_jst,
  end_at AT TIME ZONE 'Asia/Tokyo' AS end_jst,
  guest_count,
  waitlist_count,
  registration_limit,
  url,
  cover_url,
  event_type,
  location_type,
  visibility
FROM luma_events
WHERE start_at >= NOW()
ORDER BY start_at ASC;
```

**過去のイベントのみ:**
```sql
SELECT
  api_id,
  name,
  start_at AT TIME ZONE 'Asia/Tokyo' AS start_jst,
  end_at AT TIME ZONE 'Asia/Tokyo' AS end_jst,
  guest_count,
  waitlist_count,
  registration_limit,
  url,
  cover_url,
  event_type,
  location_type
FROM luma_events
WHERE start_at < NOW()
ORDER BY start_at DESC;
```

### Step 3: 結果を表示

以下の形式でMarkdownテーブルとして表示する。

```
## Lumaイベント一覧（今後 / 過去 / 全件）

| # | イベント名 | 開催日時（JST） | 登録者 | 定員 | 充足率 | URL |
|---|-----------|--------------|-------|------|--------|-----|
| 1 | [名前] | MM/DD(曜) HH:MM | XXX名 | XXX名 | XX% | [開く] |
...

**合計: X件**
```

表示ルール：
- 日時は `MM/DD(曜) HH:MM` 形式（例: `03/21(金) 10:00`）
- 定員なし（NULL）の場合は「-」と表示
- 充足率 = guest_count / registration_limit × 100（定員なしなら「-」）
- 充足率80%超なら `🔥` を付ける
- URLは `[開く](URL)` でリンク化

### 注意事項
- 「特定のイベント詳細を見たい」と言われた場合は `luma-get-event` スキルに誘導する
