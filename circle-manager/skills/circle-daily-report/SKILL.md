---
name: circle-daily-report
description: Circleコミュニティ「アイザック」の日次レポートを生成するスキル。Supabaseのcoworkプロジェクトからメンバー・投稿・コメント・エンゲージメントデータを取得し、未対応コメント・新規投稿・メンバー動向・盛り上げアクション提案を含むMarkdownレポートを生成する。「Circle日次レポート」「コミュニティレポート」「アイザックのレポート」「今日のCircle」「コミュニティの状況」「メンバーの動向」「未対応コメント確認」「Circleの分析」などのリクエストで発動。毎日の定期実行にも対応。Supabase MCP経由でデータを取得し、Claudeが分析・アクション提案を行う。
---

# Circle Daily Report Generator for アイザック

Supabaseの`cowork`プロジェクトからCircleコミュニティ「アイザック」のデータを取得し、日次レポートを生成するスキル。

## 前提情報

### コミュニティ概要
- コミュニティ名: アイザック（AI Camp）
- 運営者: 池田朋弘（いけとも）
- プラットフォーム: Circle（https://aicamp.circle.so）
- テーマ: AI活用を実践するコミュニティ


### 運営メンバー
以下は運営メンバー
・いけとも
・田中
・yayoi
・サポート担当
・諸橋



### レポートの目的
1. **コメントを漏らさず追い、対応する** — 運営者（いけとも）が返信すべきコメントを見逃さない
2. **ユーザーの活動状況を追い、盛り上げる** — 適切な打ち手を日々考える

### Supabaseプロジェクト情報
- `config.local.md` を参照して、プロジェクトID・プロジェクト名を取得すること

### テーブル構造（circle_*テーブル群）

67| テーブル名 | 内容 | 主なカラム |
|-----------|------|-----------|
| circle_community | コミュニティ基本情報 | id, name, members_count |
| circle_space_groups | スペースグループ | id, name, slug |
| circle_spaces | スペース（チャンネル） | id, name, space_type, post_count, members_count |
| circle_members | メンバー情報 | id, name, email, headline, last_seen_at, circle_created_at |
| circle_posts | 投稿 | id, name, user_name, space_id, likes_count, comments_count, url, circle_created_at |
| circle_comments | コメント | id, user_name, post_id, body_plain, likes_count, circle_created_at, **raw_json**（※） |
| circle_course_sections | コースセクション | id, space_id, name |
| circle_course_lessons | コースレッスン | id, course_section_id, name |
| circle_daily_snapshots | 日次サマリー統計 | snapshot_date, total_members, active_members, new_members_today, new_posts_today, new_comments_today |
| circle_fetch_logs | データ取得ログ | fetch_type, status, started_at |
| circle_member_activity_history | メンバー変動履歴 | member_id, snapshot_date, event_type, old_value, new_value |
| circle_post_engagement_history | 投稿エンゲージメント日次推移 | post_id, snapshot_date, likes_count, comments_count, delta_likes, delta_comments |

**※ データ品質の注意点:**
- `circle_comments` の `body_plain` と `post_id` はnullの場合がある。代わりに `raw_json` から以下のように取得する:
  - 本文HTML: `raw_json->'body'->>'body'`
  - 投稿ID: `raw_json->'post'->>'id'`
  - 投稿タイトル: `raw_json->'post'->>'name'`
  - コメント者名: `raw_json->'user'->>'name'`
  - スペース名: `raw_json->'space'->>'name'`
  - コメントURL: `raw_json->>'url'`
- `circle_members` の `status` と `role` はnullの場合がある

## 実行手順

### Step 1: 基本統計の取得

```sql
-- メンバー数・投稿数・コメント数の現在値
SELECT
  (SELECT count(*) FROM circle_members) as total_members,
  (SELECT count(*) FROM circle_members WHERE last_seen_at >= NOW() - INTERVAL '24 hours') as active_24h,
  (SELECT count(*) FROM circle_members WHERE last_seen_at >= NOW() - INTERVAL '7 days') as active_7d,
  (SELECT count(*) FROM circle_posts) as total_posts,
  (SELECT count(*) FROM circle_comments) as total_comments,
  (SELECT sum(likes_count) FROM circle_posts) as total_likes,
  (SELECT count(*) FROM circle_posts WHERE circle_created_at >= NOW() - INTERVAL '24 hours') as new_posts_24h,
  (SELECT count(*) FROM circle_comments WHERE circle_created_at >= NOW() - INTERVAL '24 hours') as new_comments_24h;
```

前日のスナップショットがあれば比較:
```sql
SELECT * FROM circle_daily_snapshots
WHERE snapshot_date >= CURRENT_DATE - 1
ORDER BY snapshot_date DESC LIMIT 2;
```

### Step 2: 未対応コメント一覧（最重要セクション）

「いけとも」以外のユーザーのコメントのうち、同じ投稿で「いけとも」の返信がないものを抽出する。`raw_json`を使って正確なデータを取得する。

```sql
WITH comment_data AS (
  SELECT
    c.id,
    c.raw_json->'user'->>'name' as commenter_name,
    (c.raw_json->'post'->>'id')::bigint as post_id,
    c.raw_json->'post'->>'name' as post_title,
    c.raw_json->'space'->>'name' as space_name,
    c.raw_json->'body'->>'body' as body_html,
    c.raw_json->>'url' as comment_url,
    c.circle_created_at
  FROM circle_comments c
  WHERE c.circle_created_at >= NOW() - INTERVAL '48 hours'
),
iketomo_replied_posts AS (
  SELECT DISTINCT (raw_json->'post'->>'id')::bigint as post_id
  FROM circle_comments
  WHERE raw_json->'user'->>'name' = 'いけとも'
    AND circle_created_at >= NOW() - INTERVAL '48 hours'
)
SELECT cd.*
FROM comment_data cd
LEFT JOIN iketomo_replied_posts ir ON cd.post_id = ir.post_id
WHERE cd.commenter_name != 'いけとも'
  AND ir.post_id IS NULL
ORDER BY cd.circle_created_at DESC;
```

未対応がある場合は「🔴 未対応あり」、ない場合は「✅ 全件対応済み」と明示する。

参考として、いけともの直近の返信一覧も添えること（返信の質を確認するため）。

### Step 3: 新規投稿一覧（過去24〜48時間）

```sql
SELECT
  p.id,
  p.name as title,
  p.user_name,
  s.name as space_name,
  p.likes_count,
  p.comments_count,
  p.url,
  p.circle_created_at
FROM circle_posts p
LEFT JOIN circle_spaces s ON p.space_id = s.id
WHERE p.circle_created_at >= NOW() - INTERVAL '48 hours'
ORDER BY p.circle_created_at DESC;
```

### Step 4: エンゲージメント急上昇投稿

```sql
SELECT
  e.post_id,
  p.name as post_title,
  p.user_name,
  s.name as space_name,
  e.likes_count,
  e.comments_count,
  e.delta_likes,
  e.delta_comments,
  p.url
FROM circle_post_engagement_history e
LEFT JOIN circle_posts p ON e.post_id = p.id
LEFT JOIN circle_spaces s ON p.space_id = s.id
WHERE e.snapshot_date >= CURRENT_DATE - 1
  AND (e.delta_likes > 0 OR e.delta_comments > 0)
ORDER BY (e.delta_likes + e.delta_comments) DESC
LIMIT 10;
```

データ蓄積が1日分の場合は、現在のいいね数TOP投稿を代わりに表示。

### Step 5: メンバー動向

#### 新規入会者
```sql
SELECT name, headline, email, last_seen_at, circle_created_at
FROM circle_members
WHERE circle_created_at >= NOW() - INTERVAL '48 hours'
ORDER BY circle_created_at DESC;
```

#### 週間アクティブ投稿者
```sql
SELECT user_name, count(*) as post_count
FROM circle_posts
WHERE circle_created_at >= NOW() - INTERVAL '7 days'
GROUP BY user_name
ORDER BY post_count DESC
LIMIT 10;
```

#### 長期未ログインメンバー（離脱予兆）
```sql
SELECT name, email, last_seen_at,
  EXTRACT(DAY FROM NOW() - last_seen_at) as days_since_last_seen
FROM circle_members
WHERE last_seen_at < NOW() - INTERVAL '30 days'
  AND last_seen_at IS NOT NULL
ORDER BY last_seen_at ASC
LIMIT 10;
```

#### アクティブ率推移（daily_snapshotsがあれば）
```sql
SELECT snapshot_date, total_members, active_members,
  ROUND(active_members::numeric / NULLIF(total_members, 0) * 100, 1) as active_rate_pct
FROM circle_daily_snapshots
ORDER BY snapshot_date DESC
LIMIT 7;
```

### Step 6: 盛り上げアクション提案（AIが生成）

データを分析した上で、以下の観点から具体的なアクション提案を3〜5個生成する。

#### 提案の観点
1. **未対応への対応**: 返信すべきコメントがあれば最優先で提案
2. **反応ゼロ投稿へのリアクション**: いいね0・コメント0の投稿にいけともがリアクションすることで投稿者のモチベーション維持
3. **新規メンバーへのウェルカム**: headline未設定の新規メンバーには自己紹介を促す
4. **アクティブメンバーの承認**: 連続投稿しているメンバーへの感謝コメント
5. **沈黙スペースの活性化**: 投稿がないスペースへのお題投稿
6. **離脱予防**: 長期未ログインメンバーへのアプローチ（DM or 全体投稿での呼びかけ）

#### 提案フォーマット
「今日やるべきこと」（即アクション可能）と「中期的な施策案」に分けて記述する。

## レポート出力フォーマット

Markdownファイルとして以下の構成で出力する。ファイル名は `circle_daily_report_YYYY-MM-DD.md`。

```markdown
# 📊 アイザック 日次レポート（YYYY-MM-DD）

---

## ① サマリー数値
（テーブル形式で主要KPIを前日比付きで表示）
（アクティブ率のセグメント別テーブルも含む）

## ② 未対応コメント一覧 🔴
（最重要。未対応の有無を明示し、コメント詳細をリスト化）
（参考として、いけともの直近返信一覧も添える）

## ③ 新規投稿一覧（過去48時間）
（テーブル形式。スペース名・投稿者・タイトル・いいね数・コメント数・URL）

## ④ エンゲージメント急上昇投稿
（delta_likes / delta_commentsが大きい投稿をリスト化）

## ⑤ メンバー動向
（新規入会者リスト、週間アクティブ投稿者TOP、長期未ログインメンバー）

## ⑥ 盛り上げアクション提案 🎯
（「今日やるべきこと」と「中期的な施策案」に分けて記述）

## ⚠️ データ品質メモ
（データに問題がある場合のみ記載）

---
*レポート生成日時: YYYY-MM-DD*
```

### 出力先
- Markdownファイル: `config.local.md` の「レポート出力先」フォルダに保存（デフォルト: `cowork_circle/log/`）

## 注意事項

- circle_commentsのbody_plainやpost_idがnullの場合は必ずraw_jsonから取得すること
- 新規投稿・コメントが0件の場合も「0件」と明示する（データ取得エラーとの区別のため）
- daily_snapshotsの蓄積が少ない初期は「データ蓄積中」と表示し、前日比は省略可
- メンバーのメールアドレスはレポートに含めない（プライバシー配慮）
- アクション提案はデータに基づく具体的な内容にし、抽象的な提案は避ける
