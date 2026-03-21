---
name: mailchimp-list
description: >
  This skill should be used when the user asks to "メールの一覧を見たい", "送信済みのメールを確認したい",
  "ドラフト一覧を見せて", "キャンペーン一覧", "どんなメールを送ったか確認したい",
  "Mailchimpのキャンペーン状況を教えて", or wants to browse and review existing Mailchimp
  campaigns grouped by status (draft, sent, scheduled, etc.).
version: 0.1.0
---

# Mailchimp キャンペーン一覧確認スキル

## 概要

Mailchimp のキャンペーン一覧を取得し、ステータス別に整理して表示する。

---

## 前提情報（固定値）

- Base URL: `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1`

---

## 手順

### Step 1: 表示モードの確認

ユーザーの意図に応じて取得モードを選ぶ：

| ユーザーの意図 | 使用するパラメータ |
|---|---|
| すべて確認したい | `count=50`（デフォルト） |
| ドラフトのみ | `status=save` |
| 送信済みのみ | `status=sent` |
| スケジュール済みのみ | `status=scheduled` |
| 直近N件だけ | `count=N` |

### Step 2: キャンペーン一覧の取得

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"

# すべて（直近20件）
curl -sk "$BASE/mailchimp-list-campaigns?count=20"

# ドラフトのみ
curl -sk "$BASE/mailchimp-list-campaigns?status=save&count=20"

# 送信済みのみ
curl -sk "$BASE/mailchimp-list-campaigns?status=sent&count=20"

# スケジュール済みのみ
curl -sk "$BASE/mailchimp-list-campaigns?status=scheduled&count=10"
```

結果を `C:/tmp/campaigns.json` に保存して処理する：

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"
curl -sk "$BASE/mailchimp-list-campaigns?count=50" > C:/tmp/campaigns.json
```

### Step 3: 結果の整形・表示

Python で JSON を整形して一覧表示する：

```python
import json

with open('C:/tmp/campaigns.json', encoding='utf-8') as f:
    data = json.load(f)

campaigns = data.get('campaigns', [])

# ステータス別に分類
status_labels = {
    'save': 'ドラフト',
    'sent': '送信済み',
    'sending': '送信中',
    'scheduled': 'スケジュール済み',
    'paused': '一時停止',
}

grouped = {}
for c in campaigns:
    status = c.get('status', 'unknown')
    grouped.setdefault(status, []).append(c)

for status, items in grouped.items():
    label = status_labels.get(status, status)
    print(f"\n### {label}（{len(items)}件）")
    print(f"{'ID':<15} {'Web ID':<10} {'件名':<40} {'送信日時'}")
    print("-" * 90)
    for c in items:
        settings = c.get('settings', {})
        subject = settings.get('subject_line', '(件名なし)')[:38]
        title = settings.get('title', '')[:20]
        send_time = c.get('send_time', '') or c.get('create_time', '')[:10]
        api_id = c.get('id', '')
        web_id = str(c.get('web_id', ''))
        print(f"{api_id:<15} {web_id:<10} {subject:<40} {send_time}")
```

### Step 4: 詳細確認（オプション）

ユーザーが特定のキャンペーンの詳細を見たい場合：

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"
curl -sk "$BASE/mailchimp-get-campaign?id=<CAMPAIGN_ID>" > C:/tmp/campaign_detail.json
```

詳細取得後、以下を表示する：
- 件名（subject_line）
- プレビューテキスト（preview_text）
- 送信日時（send_time）
- 受信者数（emails_sent）
- 開封率（opens.open_rate）
- クリック率（clicks.click_rate）

### Step 5: 結果のサマリー報告

以下の形式でサマリーを報告する：

```
## Mailchimp キャンペーン一覧

### ドラフト（X件）
| API ID | タイトル | 件名 | 作成日 |
|---|---|---|---|
| xxxx | ... | ... | 2026-03-01 |

### 送信済み（X件）
| API ID | タイトル | 件名 | 送信日 |
|---|---|---|---|
| xxxx | ... | ... | 2026-02-15 |

合計: XX件
```

---

## ステータスの種類

| status 値 | 表示名 | 説明 |
|---|---|---|
| `save` | ドラフト | 下書き保存済み、未送信 |
| `sent` | 送信済み | 配信完了 |
| `sending` | 送信中 | 現在配信処理中 |
| `scheduled` | スケジュール済み | 予約配信設定済み |
| `paused` | 一時停止 | スケジュールを一時停止中 |

## web_id と API ID の違い

- **web_id**: Mailchimp 管理画面の URL に使われる数値 ID（例: `80631`）
  - 管理画面 URL 例: `https://us22.admin.mailchimp.com/campaigns/show-email?id=80631`
- **API ID**: REST API で使うハッシュ ID（例: `8fd02b20e0`）
  - mailchimp-get-campaign、mailchimp-update-campaign 等で使用

---

## 重要な注意事項

- **curl は必ず `-sk` フラグを使う**（SSL証明書エラー回避）
- **一時ファイルは `C:/tmp/` に保存する**
- **Python コマンドは `python`（`python3` は使わない）**
