---
name: mailchimp-create
description: >
  This skill should be used when the user asks to "メールを作成して", "新しいメールマガジンを作りたい",
  "キャンペーンを新規作成", "メルマガを書いて", "Mailchimpにメールを下書き保存", or requests
  creating a new Mailchimp email campaign from scratch. It handles drafting the HTML content
  and saving it as a draft campaign via the Supabase Edge Function.
version: 0.1.0
---

# Mailchimp 新規キャンペーン作成スキル

## 概要

新規メールキャンペーンを作成し、Mailchimp に下書きとして保存する。

---

## 前提情報（固定値）

- Base URL: `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1`
- from_name: `いけとも`
- reply_to: `ikeda@workstyle-evolution.co.jp`
- Audience ID: `7dff89cacc`

---

## 手順

### Step 1: ユーザーへのヒアリング

以下を確認する（未指定の場合のみ質問する）：

1. メールの目的・テーマ（例：イベント告知、ウェビナー告知、お礼メール）
2. 件名の候補（なければ提案する）
3. 掲載するイベント情報（Luma URL、日時、場所など）
4. テスト送信先メールアドレス（希望する場合）

### Step 2: email_marketing_knowledge.md の参照

必ず `C:/Users/tomoh/Dropbox/Cursor/cowork/mailchimp/email_marketing_knowledge.md` を読み込み、
以下の観点でメール本文を作成する：

- 件名は15〜25文字、最初の15文字で価値を伝える
- プレビューテキストを設定する
- 本文構成: 冒頭フック → 本題 → CTA（申し込みボタン）→ イベント詳細
- CTAボタンは目立つ色（#00A896）で配置
- Luma イベント URL には必ず `?utm_source=mailmagazine` を付与する

### Step 3: HTML メール本文の作成

メールデザイン仕様（Workstyle Evolution ブランドガイド）に従って HTML を生成する：

#### カラーパレット
- Brand Teal: `#2BBAB4`（見出しアクセント、リンク）
- Dark Navy: `#1E3560`（日付バッジ、見出し）
- CTA Green-Teal: `#00A896`（申し込みボタン）
- Light Teal BG: `#E8F7F6`（サブセクション背景）
- Body Text: `#333333`
- Background: `#F0F7F7`
- Border: `#D6ECEB`

#### フォント
`'Helvetica Neue', Arial, 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', Meiryo, sans-serif`

#### 構成要素
- 本文: 15px, line-height:1.8
- CTAボタン: background-color:#00A896, border-radius:6px, padding:14px 28px
- フッター: YouTube 登録者数は「20万人超」と記載
- LumaイベントURLは必ず `?utm_source=mailmagazine` を付与

### Step 4: キャンペーン作成（Edge Function 呼び出し）

HTML が 30KB を超える場合は Python urllib を使う（curl 引数に直接渡せないため）。

#### Python を使った POST（推奨）

```python
import json, urllib.request

# HTML を C:/tmp/mail_body.html に保存してから読み込む
with open('C:/tmp/mail_body.html', 'w', encoding='utf-8') as f:
    f.write(html_content)

with open('C:/tmp/mail_body.html', encoding='utf-8') as f:
    html = f.read()

payload = {
    "title": "管理用タイトル（例：2026-03-21 イベント告知）",
    "subject_line": "件名",
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
  -d '{"title":"管理タイトル","subject_line":"件名","from_name":"いけとも","reply_to":"ikeda@workstyle-evolution.co.jp","html":"<html>...</html>"}'
```

### Step 5: 結果の確認とテスト送信

作成成功後、キャンペーン ID を取得し、テスト送信を提案する：

```bash
BASE="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1"
curl -sk -X POST "$BASE/mailchimp-send-test" \
  -H "Content-Type: application/json" \
  -d '{"id":"<CAMPAIGN_ID>","test_emails":["test@example.com"]}'
```

### Step 6: 完了報告

以下を報告する：
- 作成したキャンペーン ID
- 件名
- Mailchimp 管理画面で確認するよう案内（本番送信は管理画面から行う）

---

## 重要な注意事項

- **一時ファイルは `C:/tmp/` に保存する**（Windowsの `/tmp/` は使えない場合がある）
- **Python コマンドは `python`（`python3` は使わない）**
- **curl は必ず `-sk` フラグを使う**（SSL証明書エラー回避）
- **元メールを直接 update するより、コピーを新規作成して確認するほうが安全**
- **Luma イベント URL には必ず `?utm_source=mailmagazine` を付与する**
