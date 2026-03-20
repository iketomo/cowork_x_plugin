---
name: luma-daily-report
description: Lumaイベントの登録データを分析し、実績サマリ・傾向分析・打ち手提案を行い、作業フォルダ内のlogフォルダに日次レポートを保存する
---

Lumaイベントの日次レポートを生成し、このプラグインの作業フォルダ内にある`log`フォルダに日次レポートファイルとして保存してください（Slack通知は行わない）。

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

取得したデータを分析し、コンパクトなMarkdownレポートを生成する。

分析の観点:
- 登録ペースの変化（告知直後スパイク→安定期→直前駆け込みのどのフェーズか）
- 充足率80%超なら「満席見込み」、50%未満で開催2週間以内なら「追加告知が必要」
- ウェイトリスト多数なら追加開催を提案
- 個人情報（メールアドレス等）はレポートに含めない

### Step 3: ログファイルとして保存（厳守）

- **保存先ディレクトリ**: `/mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_plugin/luma-manager/log/`
- **ファイル名**: `luma-daily-report_YYYY-MM-DD.md`
- logフォルダがなければ作成
- **このパス以外に保存してはならない**

### Step 4: チャット内表示（厳守）

1. **Readツールで上記パスのファイルを読み込む**（このステップは絶対にスキップしない）
   - Readツールで読み込むことで、Claude Code上で折りたたみ式に表示される
2. 1〜2行の簡潔なサマリだけテキストで出力する。レポート全文をテキストとして出力するのは**禁止**。

### 注意事項
- スナップショットが当日分のみの場合は前日比の代わりに「初回取得」と表示
- ゲスト数0のイベントも除外せず含める
