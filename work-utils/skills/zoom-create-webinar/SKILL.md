---
name: zoom-create-webinar
description: >
  Zoomウェビナーを作成する汎用スキル。
  「Zoomウェビナーを作って」「ウェビナーを作成」「zoom-create-webinar」などのリクエストで発動。
---

# Zoomウェビナー作成

## 前提条件
- Zoom S2S OAuthアプリが作成済みであること
- Supabase Edge Function Secretsに以下が設定済みであること:
  - `ZOOM_ACCOUNT_ID`
  - `ZOOM_CLIENT_ID`
  - `ZOOM_CLIENT_SECRET`

## 手順

### Step 1: ヒアリング

以下の情報をユーザーに確認する（未指定の項目のみ質問）:

1. **ウェビナー名** (必須)
2. **開催日時** (必須) - 例: 2026/04/20 10:00
3. **所要時間（分）** (必須) - 例: 120
4. **タイムゾーン** (任意、デフォルト: Asia/Tokyo)
5. **説明文（agenda）** (任意)
6. **パスコード** (任意、未指定なら自動生成)

### Step 2: 確認

収集した情報をテーブル形式で表示し確認:

```
| 項目 | 内容 |
|------|------|
| ウェビナー名 | ... |
| 開催日時 | YYYY/MM/DD HH:MM (JST) |
| 所要時間 | XXX 分 |
| パスコード | 自動生成 / 指定値 |
```

「この内容でZoomウェビナーを作成してよいですか？」

### Step 3: Edge Function呼び出し

確認が取れたら、Supabase Edge Functionを呼び出す。

**エンドポイント:** `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1/zoom-create-webinar`

**メソッド:** POST

**リクエストボディ例:**
```json
{
  "topic": "ウェビナー名",
  "start_time": "2026-04-20T10:00:00+09:00",
  "duration": 120,
  "timezone": "Asia/Tokyo",
  "agenda": "説明文"
}
```

**呼び出し方法（Bash）:**
```bash
curl -sk "https://iltymrnkqchixvtpvewm.supabase.co/functions/v1/zoom-create-webinar" \
  -H "Content-Type: application/json" \
  -d '{"topic":"テスト","start_time":"2026-04-20T10:00:00+09:00","duration":120,"timezone":"Asia/Tokyo"}'
```

※ 開催日時はISO 8601形式（タイムゾーンオフセット付き）に変換すること。
例: 「2026/04/20 10:00 JST」→ `2026-04-20T10:00:00+09:00`

### Step 4: 結果報告

**成功時:**

| 項目 | 内容 |
|------|------|
| ウェビナーID | (webinar.id) |
| 参加URL | (webinar.join_url) |
| ホストURL | (webinar.start_url) |
| パスコード | (webinar.password) |
| 開始時間 | (webinar.start_time) |

**失敗時:**
- エラーメッセージを表示
- よくある原因:
  - Zoom S2S OAuthの認証情報が未設定 → Supabase Edge Function Secretsを確認
  - Webinarライセンスがない → Zoomアカウントの契約プランを確認
  - スコープ不足 → Zoom AppのScopesに`webinar:write:admin`を追加

### 注意事項
- Zoomウェビナーには**Zoom Webinar アドオンライセンス**が必要（通常のZoomプランでは使用不可）
- S2S OAuthトークンはEdge Function内で自動取得（キャッシュ不要）
- このスキルは単独でも、luma-create-eventスキルからの内部呼び出しでも使用可能
