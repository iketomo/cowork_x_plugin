---
name: mailchimp-copy-update
description: >
  This skill should be used when the user asks to "既存のメールをコピーして改版したい",
  "過去のメールを参考に新しいメールを作りたい", "メールのHTMLを修正して別キャンペーンで保存",
  "既存キャンペーンをベースに新しい告知を作りたい", or needs to copy an existing Mailchimp
  campaign, modify its HTML content, and save it as a new draft campaign.
version: 0.1.0
---

# Mailchimp 既存メールコピー・更新スキル

## 概要

既存キャンペーンのHTMLをベースに内容を更新し、新規ドラフトとして保存する。
元のキャンペーンは変更しない（安全なコピー作成フロー）。

---

## 前提情報（固定値）

- Base URL: `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1`
- from_name: `いけとも`
- reply_to: `ikeda@workstyle-evolution.co.jp`

---

## 手順

### Step 1: コピー元キャンペーンの特定

ユーザーからキャンペーンの指定方法を確認する：

- **タイトルで検索する場合**: まず一覧を取得して特定する
- **Mailchimp 管理画面の URL から特定する場合**: URL 中の `id=XXXXX` が web_id

#### キャンペーン一覧の取得

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"

# 直近20件を取得
curl -sk "$BASE/mailchimp-list-campaigns?count=20"

# ドラフトのみ
curl -sk "$BASE/mailchimp-list-campaigns?status=save"

# 送信済みのみ
curl -sk "$BASE/mailchimp-list-campaigns?status=sent"
```

レスポンスには `id`（API ID）と `web_id`（管理画面 URL の ID）が含まれる。

### Step 2: 元キャンペーンの HTML 取得

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"
curl -sk "$BASE/mailchimp-get-campaign?id=<CAMPAIGN_ID>" > C:/tmp/original_campaign.json
```

レスポンス構造：
- `campaign.settings.subject_line`: 件名
- `campaign.settings.title`: 管理タイトル
- `campaign.settings.from_name`: 差出人名
- `content.html`: メール HTML 本文

HTML を取り出す（Python 推奨）：

```python
import json

with open('C:/tmp/original_campaign.json', encoding='utf-8') as f:
    data = json.load(f)

html = data['content']['html']
subject = data['campaign']['settings']['subject_line']
title = data['campaign']['settings']['title']

with open('C:/tmp/original.html', 'w', encoding='utf-8') as f:
    f.write(html)

print(f"件名: {subject}")
print(f"管理タイトル: {title}")
print(f"HTML サイズ: {len(html)} 文字")
```

### Step 3: ユーザーへの変更内容ヒアリング

以下を確認する：

1. 新しい件名
2. 変更するテキスト・URL・日付
3. 新しいイベント情報（Luma URL、日時、場所）
4. 追加・削除するセクション

### Step 4: HTML の加工

#### 重要な注意事項

**HTML内のURLはhrefと表示テキストの2箇所を必ず置換する。**

Mailchimp の HTML では同じ URL が次のように2重に記述されている：

```html
<a href="https://luma.com/iketomo260311?utm_source=OLD" target="_blank">
  https://luma.com/iketomo260311?utm_source=OLD_TEXT
</a>
```

- `href` 属性（実際のリンク先）
- タグ内の表示テキスト（目に見える URL）

**→ 両方を別々に置換しないとズレが生じる。**

#### Python を使った URL 置換の例

```python
# C:/tmp/original.html を読み込んで加工し C:/tmp/updated.html に保存

with open('C:/tmp/original.html', encoding='utf-8') as f:
    html = f.read()

# href の置換
html = html.replace(
    'href="https://luma.com/OLD_URL?utm_source=OLD"',
    'href="https://luma.com/NEW_URL?utm_source=mailmagazine"'
)

# 表示テキストの置換
html = html.replace(
    'https://luma.com/OLD_URL?utm_source=OLD_TEXT',
    'https://luma.com/NEW_URL?utm_source=mailmagazine'
)

# テキスト・日付の置換
html = html.replace('3月11日', '4月9日')
html = html.replace('March 11', 'April 9')

with open('C:/tmp/updated.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("加工完了")
print(f"サイズ: {len(html)} 文字")
```

#### Luma イベント URL のルール

Luma イベントの URL には必ず `?utm_source=mailmagazine` を付与する：

```
https://luma.com/iketomo260409?utm_source=mailmagazine
```

### Step 5: 新規ドラフトとして保存

**元のキャンペーンは変更しない。必ず新規キャンペーンとして作成する。**

HTML が 30KB を超える場合は Python urllib を使う：

```python
import json, urllib.request

with open('C:/tmp/updated.html', encoding='utf-8') as f:
    html = f.read()

payload = {
    "title": "新しい管理タイトル（例：2026-04-09 イベント告知）",
    "subject_line": "新しい件名",
    "from_name": "いけとも",
    "reply_to": "ikeda@workstyle-evolution.co.jp",
    "html": html
}
data = json.dumps(payload).encode('utf-8')
req = urllib.request.Request(
    "https://iltymrnkqchixvtpvewm.supabase.co/functions/v1/mailchimp-create-campaign",
    data=data,
    headers={'Content-Type': 'application/json'},
    method='POST'
)
with urllib.request.urlopen(req) as res:
    result = json.loads(res.read())
    print(json.dumps(result, ensure_ascii=False, indent=2))
```

#### 小さな HTML の場合（curl）

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"
curl -sk -X POST "$BASE/mailchimp-create-campaign" \
  -H "Content-Type: application/json" \
  -d '{"title":"新タイトル","subject_line":"新件名","from_name":"いけとも","reply_to":"ikeda@workstyle-evolution.co.jp","html":"<html>...</html>"}'
```

### Step 6: テスト送信（オプション）

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"
curl -sk -X POST "$BASE/mailchimp-send-test" \
  -H "Content-Type: application/json" \
  -d '{"id":"<NEW_CAMPAIGN_ID>","test_emails":["test@example.com"]}'
```

### Step 7: 完了報告

以下を報告する：
- 新規作成したキャンペーン ID
- 新しい件名
- 変更した主な内容の要約
- Mailchimp 管理画面で確認するよう案内（本番送信は管理画面から行う）

---

## 重要な注意事項

- **元のキャンペーンは変更しない**（必ず mailchimp-create-campaign で新規作成）
- **HTML内URLはhrefと表示テキストの2箇所を必ず置換する**
- **Luma イベント URL には必ず `?utm_source=mailmagazine` を付与する**
- **一時ファイルは `C:/tmp/` に保存する**
- **Python コマンドは `python`（`python3` は使わない）**
- **curl は必ず `-sk` フラグを使う**（SSL証明書エラー回避）
- **大きな HTML は Python urllib で POST する**（curl コマンドライン引数の制限回避）
