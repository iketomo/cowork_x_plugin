# mailchimp-manager

Mailchimp メールマガジン管理プラグイン。Claude Code から Supabase Edge Function 経由で Mailchimp キャンペーンの作成・コピー更新・一覧確認を行う。

## スキル一覧

| スキル | 説明 | トリガーフレーズ例 |
|---|---|---|
| `mailchimp-create` | 新規メールキャンペーンを作成・下書き保存 | 「新しいメールを作成して」「メルマガを書いて」 |
| `mailchimp-copy-update` | 既存メールをコピーして内容を更新・新規保存 | 「過去のメールをコピーして改版したい」 |
| `mailchimp-list` | キャンペーン一覧をステータス別に確認 | 「メールの一覧を見たい」「ドラフト一覧を見せて」 |

## 接続先

- **Supabase Edge Function Base URL**: `https://iltymrnkqchixvtpvewm.supabase.co/functions/v1`
- **Mailchimp Audience**: Workstyle Evolution（約19,684名）

## Edge Functions

| Function | Method | 説明 |
|---|---|---|
| `mailchimp-list-campaigns` | GET | キャンペーン一覧取得 |
| `mailchimp-get-campaign` | GET | キャンペーン詳細 + HTML 取得 |
| `mailchimp-create-campaign` | POST | 新規キャンペーン作成 + HTML 一括設定 |
| `mailchimp-update-campaign` | PATCH | 既存キャンペーン更新 |
| `mailchimp-send-test` | POST | テスト送信 |

## 主なワークフロー

### 新規メール作成

1. ユーザーにテーマ・件名・イベント情報をヒアリング
2. `email_marketing_knowledge.md` を参照してHTML本文を作成
3. `mailchimp-create-campaign` で下書き保存
4. `mailchimp-send-test` でテスト送信

### 既存メールのコピー更新

1. `mailchimp-list-campaigns` で元キャンペーンを特定
2. `mailchimp-get-campaign` でHTML取得
3. Pythonで URL・テキスト・日付を置換
4. `mailchimp-create-campaign` で新規ドラフト作成

## 重要なルール

- Luma イベント URL には必ず `?utm_source=mailmagazine` を付与する
- HTML 内の URL は href と表示テキストの両方を置換する
- 元キャンペーンは変更せず、必ず新規コピーを作成する
- 大きなHTMLのPOSTはPython urllibを使う
- curl は必ず `-sk` フラグを使う（Windows環境）
- 一時ファイルは `C:/tmp/` に保存する
