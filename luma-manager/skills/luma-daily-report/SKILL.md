---
name: luma-daily-report
description: Lumaイベントの登録データを分析し、実績サマリ・傾向分析・打ち手提案をSlack DMでレポートする
---

Lumaイベントの日次レポートを生成してSlackで報告してください。

## 手順

### Step 1: Supabaseからデータ取得
Supabase MCPの`execute_sql`ツールを使い、`config.local.md` に記載のプロジェクトIDに対して以下のSQLを実行する。

**1-1: 直近7日分のスナップショット**
```sql
SELECT * FROM luma_daily_snapshots
WHERE snapshot_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY snapshot_date DESC;
```

**1-2: イベント別の基本情報**
```sql
SELECT e.api_id, e.name, e.start_at, e.end_at,
       e.guest_count, e.waitlist_count, e.registration_limit,
       e.url, e.event_type
FROM luma_events e
WHERE e.start_at >= NOW() - INTERVAL '7 days'
ORDER BY e.start_at ASC;
```

**1-3: 日別新規登録数（イベント別）**
```sql
SELECT g.event_api_id, e.name as event_name,
       DATE(g.registered_at) as reg_date,
       COUNT(*) as new_registrations
FROM luma_guests g
JOIN luma_events e ON e.api_id = g.event_api_id
WHERE g.registered_at >= NOW() - INTERVAL '7 days'
GROUP BY g.event_api_id, e.name, DATE(g.registered_at)
ORDER BY reg_date DESC, new_registrations DESC;
```

**1-4: 流入元分析**
```sql
SELECT e.name as event_name,
       COALESCE(g.utm_source, '(direct/unknown)') as source,
       COALESCE(g.utm_medium, '-') as medium,
       COUNT(*) as count
FROM luma_guests g
JOIN luma_events e ON e.api_id = g.event_api_id
WHERE e.start_at >= NOW() - INTERVAL '30 days'
GROUP BY e.name, g.utm_source, g.utm_medium
ORDER BY count DESC LIMIT 30;
```

### Step 2: レポート生成

取得したデータを分析し、以下の構成でMarkdownレポートを生成する。
```
# Lumaイベント日次レポート（YYYY/MM/DD）

## 📊 本日のサマリ
| 指標 | 今日 | 前日比 | 7日前比 |
|------|------|--------|---------|
| 総ゲスト数 | X,XXX | +XX | +XXX |
| 本日の新規登録 | XX | - | - |
| 今後のイベント数 | X | - | - |

## 📈 イベント別ステータス
### [イベント名]（MM/DD開催）
- 登録者数: XXX名 / 定員XXX名（充足率XX%）
- 直近7日の新規登録: XX名（1日平均X.X名）
- ウェイトリスト: XX名
- 勢い: [🔥加速中 / ➡️横ばい / ⚠️鈍化]

## 🔍 傾向分析
（登録ペースの推移、流入元の傾向、イベントテーマ別の比較）

## 💡 打ち手の提案
### 即効性のあるアクション
1. [具体的なアクション]（理由: [データに基づく根拠]）
### 中期的な施策
1. [施策提案]
```

分析の観点:
- 登録ペースの変化（告知直後スパイク→安定期→直前駆け込みのどのフェーズか）
- 充足率80%超なら「満席見込み」、50%未満で開催2週間以内なら「追加告知が必要」
- ウェイトリスト多数なら追加開催を提案
- 流入チャネル比率から追加投下先を提案
- 個人情報（メールアドレス等）はレポートに含めない

### Step 3: Slack通知

**3-1: Canvas作成**
`slack_create_canvas`ツールでレポート全文をCanvasとして作成する。
title: "Lumaイベント日次レポート YYYY/MM/DD"

**3-2: SlackのDMに送信**
`slack_send_message`ツールでサマリメッセージを送信する。
channel_id: `config.local.md` の「Slack > DM channel_id」を参照

メッセージフォーマット（mrkdwn形式）:
```
📊 *Lumaイベント日次レポート（MM/DD）*

*本日のサマリ*
- 総登録者: X,XXX名（前日比 +XX）
- 本日の新規登録: XX名

*イベント別*
- [イベント名1]: XXX名 / XXX名（XX%）[🔥/➡️/⚠️]

*💡 今日の打ち手*
- [最も優先度の高いアクション1つ]

👉 詳細レポート: [CanvasのURL]
```

### 注意事項
- データ取得は毎朝6:00 JSTにEdge Functionが自動実行済み。このタスクはその結果を読み取ってレポート生成する
- スナップショットが当日分のみの場合は前日比の代わりに「初回取得」と表示
- ゲスト数0のイベントも除外せず含める
- 打ち手は必ずデータに基づく根拠を示す
