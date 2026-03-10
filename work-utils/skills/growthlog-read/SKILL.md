---
name: growthlog-read
description: >
  Supabaseのgrowth_log_learningsテーブルからグロースログ（反省・学び）を
  読み込み・検索・一覧表示するスキル。
  「グロースログを見せて」「反省・学びの一覧」「学びを検索」
  「過去の振り返りを見たい」「グロースログ一覧」「学びの記録を確認」
  「growthlog read」「反省ログを表示」「学びを探して」
  「カテゴリ別の学び」「復習が必要な学び」「最近の反省」
  「グロースログを参照」「学びの履歴」などのリクエストで発動。
  ※保存は growthlog-save スキルを使う。
version: 1.0.0
---

# グロースログ読み込みスキル

## 概要

Supabaseの`growth_log_learnings`テーブルから、グロースログ（反省・学び・成功体験）を読み込み・検索・表示する。
ユーザーのリクエストに応じて「一覧表示」「特定ログの取得」「キーワード検索」「カテゴリ絞り込み」「復習対象の抽出」の5つのモードで動作する。

## コンテキスト節約アーキテクチャ

- メインエージェントで直接実行（軽量処理のため委譲不要）
- SQL実行・結果整形・表示をメインエージェントが一貫して担当する

## データソース

- Supabaseプロジェクト: **cowork** (project_id: `iltymrnkqchixvtpvewm`)
- テーブル: `public.growth_log_learnings`

---

## 実行手順

### ステップ1: ユーザーの意図を判別する

ユーザーのリクエストに応じて、以下の5つのモードから適切なものを選択する。

| モード | ユーザーの意図 | 例 |
|--------|---------------|-----|
| **一覧** | 最近のグロースログを一覧で見たい | 「最近の学び」「グロースログ一覧」 |
| **特定取得** | 特定のログの詳細を見たい | 「家族時間の学びの詳細は？」 |
| **キーワード検索** | キーワードでログを横断検索 | 「コミュニケーションに関する学び」 |
| **カテゴリ絞り込み** | カテゴリで絞り込みたい | 「マインド系の学びだけ表示して」 |
| **復習対象抽出** | 復習すべきログを見たい | 「復習が必要な学びは？」「1週間復習まだのもの」 |

### ステップ2: SQLを実行する

Supabase MCPの`execute_sql`で実行する（project_id: `iltymrnkqchixvtpvewm`）。

#### モード1: 最近のグロースログ一覧

```sql
SELECT id, date, title, category, review_count, want_more_retention
FROM growth_log_learnings
ORDER BY date DESC, created_at DESC
LIMIT 20;
```

#### モード2: 特定ログの詳細取得

タイトルで検索:
```sql
SELECT id, date, title, content, category, ai_comment, raw_content,
       review_count, want_more_retention,
       review_1w_at, review_1m_at, review_3m_at, last_continuous_review_at
FROM growth_log_learnings
WHERE title ILIKE '%（キーワード）%'
ORDER BY date DESC;
```

IDで直接取得:
```sql
SELECT *
FROM growth_log_learnings
WHERE id = （ID）;
```

#### モード3: キーワード検索

```sql
SELECT id, date, title, content, category
FROM growth_log_learnings
WHERE title ILIKE '%（キーワード）%'
   OR content ILIKE '%（キーワード）%'
   OR raw_content ILIKE '%（キーワード）%'
ORDER BY date DESC
LIMIT 15;
```

#### モード4: カテゴリ絞り込み

カテゴリ一覧の確認:
```sql
SELECT category, COUNT(*) as count
FROM growth_log_learnings
GROUP BY category
ORDER BY count DESC;
```

特定カテゴリの取得:
```sql
SELECT id, date, title, content, review_count
FROM growth_log_learnings
WHERE category = '（カテゴリ名）'
ORDER BY date DESC;
```

#### モード5: 復習対象の抽出

1週間復習が未実施のもの:
```sql
SELECT id, date, title, category, content
FROM growth_log_learnings
WHERE review_1w_at IS NULL
  AND created_at <= NOW() - INTERVAL '7 days'
ORDER BY date ASC;
```

1ヶ月復習が未実施のもの:
```sql
SELECT id, date, title, category, content
FROM growth_log_learnings
WHERE review_1m_at IS NULL
  AND review_1w_at IS NOT NULL
  AND created_at <= NOW() - INTERVAL '30 days'
ORDER BY date ASC;
```

定着強化フラグが立っているもの:
```sql
SELECT id, date, title, category, content, review_count
FROM growth_log_learnings
WHERE want_more_retention = true
ORDER BY date DESC;
```

### ステップ3: 結果をユーザーに見やすく表示する

#### 一覧モードの場合

```
グロースログ一覧（計N件）:

| # | 日付 | タイトル | カテゴリ | 復習回数 |
|---|------|---------|---------|---------|
| 1 | 2026-03-10 | 成功も記録しよう | マインド | 0回 |
| 2 | 2026-03-10 | 家族時間の大切さ | コミュニケーション | 0回 |
```

#### 特定取得モードの場合

```
「{title}」の詳細:

日付: {date}
カテゴリ: {category}

学びの要点:
{content}

AIコメント:
{ai_comment}

復習状況: {review_count}回（1w: {status} / 1m: {status} / 3m: {status}）
```

#### キーワード検索モードの場合

```
「{キーワード}」に関するグロースログ（N件ヒット）:

1. **{title}** [{date} / {category}]
   {content の先頭2行}

2. **{title}** [{date} / {category}]
   {content の先頭2行}
```

#### 復習対象モードの場合

```
復習が必要なグロースログ（N件）:

■ 1週間復習が未実施:
1. [{date}] {title}（{category}）
   {content の先頭2行}

■ 定着強化フラグあり:
1. [{date}] {title}（{category}）
```

---

## 活用シーン

- **定期的な振り返り**: 最近の学びを一覧で確認して定着を促進
- **テーマ別の整理**: カテゴリやキーワードで学びを体系的に把握
- **復習サイクル管理**: 復習が必要なログを抽出して定着を強化
- **成長の可視化**: 過去のログを振り返って自己成長を実感

---

## 重要ルール

- **読み込み専用**: データの保存・登録は `growthlog-save` スキルを使う
- 検索結果が多い場合は、新しいものを優先して表示し、全件は省略してよい
- raw_contentは長いため、一覧・検索モードでは表示しない。ユーザーが詳細を求めた場合のみ表示する
- 復習ステータスの更新は本スキルのスコープ外（将来的に別スキルで対応）
- 検索結果が0件の場合は、その旨を伝え、キーワードの変更やカテゴリ一覧の確認を提案する
