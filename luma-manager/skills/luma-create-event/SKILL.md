---
name: luma-create-event
description: >
  Lumaイベント＋Zoomウェビナーを一括作成するスキル。
  「イベントを作りたい」「Lumaイベントを新規作成」「ウェビナー付きイベント作成」
  「luma-create-event」などのリクエストで発動。
---

# Lumaイベント + Zoomウェビナー 一括作成

## 前提条件
- Supabase Edge Function Secretsに `LUMA_API_KEY` が設定済み
- Zoom連携を使う場合は `ZOOM_ACCOUNT_ID`, `ZOOM_CLIENT_ID`, `ZOOM_CLIENT_SECRET` も設定済み

## 手順

### Step 1: ヒアリング

以下の情報をユーザーに確認する（未指定の項目のみ質問）:

1. **イベント名** (必須)
2. **開催日時** (必須) - 開始〜終了。例: 2026/04/20 10:00〜12:00
3. **タイムゾーン** (任意、デフォルト: Asia/Tokyo)
4. **説明文** (任意) - Markdown形式対応
5. **定員** (任意)
6. **公開設定** (任意、デフォルト: public)
7. **カバー画像URL** (任意)
8. **Zoomウェビナーを作成するか** (任意、デフォルト: はい)
9. **イベントURL スラッグ** (任意、自動生成可)

### Step 2: 確認

収集した情報をテーブル形式で表示:

```
| 項目 | 内容 |
|------|------|
| イベント名 | ... |
| 開催日時 | YYYY/MM/DD HH:MM〜HH:MM (JST) |
| Zoomウェビナー | 作成する / 作成しない |
| 定員 | XXX名 / 無制限 |
| 公開設定 | public / private |
| カバー画像 | あり / なし |
```

「この内容でイベントを作成してよいですか？」と確認する。

### Step 3: Zoomウェビナー作成（オプション）

Zoom作成が「はい」の場合、先にZoomウェビナーを作成する。

**エンドポイント:** `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1/zoom-create-webinar`

**メソッド:** POST

**リクエストボディ:**
```json
{
  "topic": "イベント名",
  "start_time": "2026-04-20T10:00:00+09:00",
  "duration": 120,
  "timezone": "Asia/Tokyo",
  "agenda": "説明文"
}
```

成功したら以下を取得:
- `webinar.id` → zoom_webinar_id
- `webinar.join_url` → zoom_join_url（Lumaのmeeting_urlに使用）
- `webinar.start_url` → zoom_start_url
- `webinar.password` → zoom_password

**Zoom作成に失敗した場合:**
- エラーを表示し、「Zoomなしでイベントのみ作成しますか？」と確認
- ユーザーが了承すればStep 4に進む（meeting_urlなし）

### Step 4: Lumaイベント作成

**エンドポイント:** `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1/luma-create-event`

**メソッド:** POST

**リクエストボディ:**
```json
{
  "name": "イベント名",
  "start_at": "2026-04-20T10:00:00+09:00",
  "end_at": "2026-04-20T12:00:00+09:00",
  "timezone": "Asia/Tokyo",
  "description_md": "説明文（Markdown）",
  "visibility": "public",
  "max_capacity": 300,
  "cover_url": "https://...",
  "zoom_webinar_id": "Step3で取得したID",
  "zoom_join_url": "Step3で取得した参加URL",
  "zoom_start_url": "Step3で取得したホストURL",
  "zoom_password": "Step3で取得したパスコード"
}
```

※ 開催日時はISO 8601形式（タイムゾーンオフセット付き）に変換すること。
例: 「2026/04/20 10:00 JST」→ `2026-04-20T10:00:00+09:00`

※ Zoom情報がある場合、`zoom_join_url`が自動的に`meeting_url`としてLumaイベントに設定される。

### Step 5: 結果報告

**完全成功時:**

| 項目 | 内容 |
|------|------|
| Lumaイベント | [イベント名](https://lu.ma/xxx) |
| Luma API ID | evt-xxx |
| Zoom ウェビナーID | 1234567890 |
| Zoom 参加URL | https://zoom.us/w/... |
| Zoom ホストURL | (ホスト用URL) |
| Zoom パスコード | xxxxxx |
| DB保存 | 成功 / 警告あり |

**Zoom成功・Luma失敗時:**
- Zoomウェビナーは作成済みであることを明示
- Zoom情報（ID, 参加URL, ホストURL, パスコード）を表示
- 「Lumaイベントの作成をリトライしますか？」と確認

**Zoomなし・Luma成功時:**

| 項目 | 内容 |
|------|------|
| Lumaイベント | [イベント名](https://lu.ma/xxx) |
| Luma API ID | evt-xxx |
| Zoom | なし |

### 注意事項
- Zoom URLは非公開情報（meeting_url）としてLumaに設定される。参加者には登録後のみ表示される
- Lumaイベントの説明文はMarkdown対応。改行は `\n` で指定
- イベント作成後、既存のluma-daily-fetchが定期同期するため、DB保存が失敗しても後から自動的に同期される
- カバー画像はURLで指定。事前にStorage等にアップロードしておく必要がある
