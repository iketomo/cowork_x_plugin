---
name: luma-get-event
description: 特定のLumaイベントの詳細情報をSupabaseから取得して表示するスキル。「このイベントの詳細」「[イベント名]の情報を見せて」「次のイベントを見せて」「luma-get-event」などのリクエストで発動。
---

特定のLumaイベントの詳細情報を `config.local.md` に記載のSupabaseプロジェクトから取得して表示してください。

## 手順

### Step 1: 検索キーの特定

ユーザーの入力から検索に使うキーを判断する：
- URLが含まれている → URLのスラッグ部分（例: `iketomo260311`）で `url ILIKE '%スラッグ%'`
- イベントIDが含まれている（`evt-` で始まる文字列）→ `api_id = '...'`
- イベント名・キーワードが含まれている → `name ILIKE '%キーワード%'`
- 「最新」「直近」「今度」「次」など → `start_at >= NOW() ORDER BY start_at ASC LIMIT 1`

### Step 2: イベント情報の取得

Supabase MCPの `execute_sql` ツールを使い、`config.local.md` のプロジェクトIDに対して以下のSQLを実行する（検索キーに応じて WHERE 句を変える）。

**名前検索の例:**
```sql
SELECT
  e.api_id,
  e.name,
  e.description,
  e.cover_url,
  e.url,
  e.event_type,
  e.start_at AT TIME ZONE 'Asia/Tokyo' AS start_jst,
  e.end_at AT TIME ZONE 'Asia/Tokyo' AS end_jst,
  e.timezone,
  e.location_type,
  e.meeting_url,
  e.geo_address_json,
  e.guest_count,
  e.waitlist_count,
  e.registration_limit,
  e.ticket_info,
  e.visibility,
  e.luma_created_at,
  e.luma_updated_at,
  e.fetched_at
FROM luma_events e
WHERE e.name ILIKE '%キーワード%'
ORDER BY e.start_at DESC
LIMIT 5;
```

複数件ヒットした場合はユーザーに選択を促す。1件の場合はStep 3へ進む。

### Step 3: 登録トレンドの取得（直近14日）

イベントの `api_id` が確定したら、登録状況のトレンドを取得する：

```sql
SELECT
  DATE(g.registered_at AT TIME ZONE 'Asia/Tokyo') AS reg_date,
  COUNT(*) AS new_registrations,
  SUM(COUNT(*)) OVER (ORDER BY DATE(g.registered_at AT TIME ZONE 'Asia/Tokyo')) AS cumulative
FROM luma_guests g
WHERE g.event_api_id = '[対象のapi_id]'
  AND g.registered_at >= NOW() - INTERVAL '14 days'
GROUP BY DATE(g.registered_at AT TIME ZONE 'Asia/Tokyo')
ORDER BY reg_date DESC;
```

### Step 4: 結果を表示

以下の形式でイベント詳細を表示する：

```
## [イベント名]

| 項目 | 内容 |
|------|------|
| 開催日時 | YYYY/MM/DD(曜) HH:MM〜HH:MM（JST） |
| 形式 | オンライン / オフライン / ハイブリッド |
| 登録者数 | XXX名（定員: XXX名 / 充足率: XX%） |
| ウェイトリスト | XX名 |
| URL | https://luma.com/... |

### 説明文
[description の内容をそのまま表示]

### 直近14日の登録トレンド
| 日付 | 新規 | 累計 |
|------|------|------|
| MM/DD | XX | XXX |
...

### サムネイル
[cover_url が存在する場合]: ![サムネイル](cover_url)
```

表示ルール：
- `description` は全文表示
- `cover_url` がある場合は `![サムネイル](URL)` 形式で画像表示
- `ticket_info` がある場合はチケット情報（料金など）も表示
- `meeting_url` は非表示（非公開情報のため）
- 登録トレンドが取得できない場合は「登録データなし」と表示

### 注意事項
- 複数のイベントがヒットした場合は一覧を示し、どれを詳しく見るか確認する
- 「この内容でLINE告知文を作って」などの後続リクエストには積極的に対応する
