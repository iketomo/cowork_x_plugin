---
name: research-read
description: >
  Supabaseのresearch_itemsテーブルから保存済みのリサーチ・調査結果を
  読み込み・検索・一覧表示するスキル。
  「リサーチを見せて」「過去の調査を検索」「リサーチ結果を確認」
  「保存したリサーチ一覧」「調査データを探して」「リサーチを参照」
  「research read」「過去のリサーチを見たい」「調査記録を検索」
  「リサーチ履歴」「どんなリサーチが保存されてる？」「調べた内容を確認」
  「リサーチデータを参照して」などのリクエストで発動。
  ※保存は research-save スキルを使う。
version: 1.0.1
---

# リサーチデータ読み込みスキル

## 概要

Supabaseの`research_items`テーブルから、保存済みのリサーチ・調査結果を読み込み・検索・表示する。
ユーザーのリクエストに応じて「一覧表示」「特定リサーチの取得」「テーマ横断検索」の3つのモードで動作する。

## コンテキスト節約アーキテクチャ

- メインエージェントで直接実行（軽量処理のため委譲不要）
- SQL実行・結果整形・表示をメインエージェントが一貫して担当する

## データソース

- Supabaseプロジェクト: **cowork** (project_id: `iltymrnkqchixvtpvewm`)
- テーブル: `public.research_items`

---

## 実行手順

### ステップ1: ユーザーの意図を判別する

ユーザーのリクエストに応じて、以下の3つのモードから適切なものを選択する。

| モード | ユーザーの意図 | 例 |
|--------|---------------|-----|
| **一覧** | 保存済みリサーチの全体像を把握したい | 「どんなリサーチが保存されてる？」「一覧見せて」 |
| **特定取得** | 特定のリサーチの詳細を見たい | 「LLM比較の調査結果は？」 |
| **横断検索** | テーマやキーワードで横断的に探したい | 「RAGに関するリサーチを全部見せて」 |

### ステップ2: SQLを実行する

Supabase MCPの`execute_sql`で実行する（project_id: `iltymrnkqchixvtpvewm`）。

#### モード1: 保存済みリサーチ一覧

```sql
SELECT id, title, source_tool, captured_at
FROM research_items
ORDER BY captured_at DESC
LIMIT 20;
```

#### モード2: 特定リサーチの詳細取得

```sql
SELECT id, title, summary, facts, insights, source_tool, captured_at
FROM research_items
WHERE title ILIKE '%（キーワード）%'
ORDER BY captured_at DESC;
```

IDで直接取得する場合：

```sql
SELECT id, title, summary, facts, insights, raw_content, source_tool, captured_at
FROM research_items
WHERE id = '（UUID）';
```

#### モード3: テーマ横断検索

```sql
SELECT id, title, summary, facts, insights, source_tool, captured_at
FROM research_items
WHERE title ILIKE '%（キーワード）%'
   OR summary ILIKE '%（キーワード）%'
   OR facts ILIKE '%（キーワード）%'
   OR insights ILIKE '%（キーワード）%'
ORDER BY captured_at DESC
LIMIT 10;
```

複数キーワードで検索する場合：

```sql
SELECT id, title, summary, source_tool, captured_at
FROM research_items
WHERE (title ILIKE '%キーワード1%' OR summary ILIKE '%キーワード1%' OR facts ILIKE '%キーワード1%')
  AND (title ILIKE '%キーワード2%' OR summary ILIKE '%キーワード2%' OR facts ILIKE '%キーワード2%')
ORDER BY captured_at DESC;
```

### ステップ3: 結果をユーザーに見やすく表示する

#### 一覧モードの場合

```
保存済みリサーチ一覧（計N件）:

| # | タイトル | ソース | 保存日 |
|---|---------|--------|--------|
| 1 | LLMのコンテキストウィンドウ比較 | claude | 2026-03-05 |
| 2 | RAGの精度向上テクニック | perplexity | 2026-03-01 |
```

#### 特定取得モードの場合

```
「LLMのコンテキストウィンドウ比較」の詳細:

📋 要約:
{summary}

📊 事実・データ:
{facts}

💡 洞察:
{insights}

ソース: {source_tool} / 保存日: {captured_at}
```

#### 横断検索モードの場合

```
「{キーワード}」に関するリサーチ（N件ヒット）:

1. **{title}** [{source_tool} / {captured_at}]
   {summary}

2. **{title}** [{source_tool} / {captured_at}]
   {summary}
```

---

## 活用シーン

- **過去の調査の再利用**: 以前調べた内容を再確認して議論に活かす
- **知識の横断検索**: 複数回のリサーチから共通テーマの知見をまとめる
- **レポート作成**: 蓄積されたリサーチデータからレポートの素材を収集する
- **意思決定の根拠確認**: 過去の調査結果を参照して判断材料にする

---

## 重要ルール

- **読み込み専用**: データの保存・登録は `research-save` スキルを使う
- 検索結果が多い場合は、新しいものを優先して表示し、全件は省略してよい
- ユーザーが特定のリサーチを指定しているがタイトルが曖昧な場合、部分一致で候補を提示する
- 検索結果が0件の場合は、その旨を伝え、キーワードの変更を提案する
- raw_contentは長いため、一覧・検索モードでは表示しない。ユーザーが詳細を求めた場合のみ表示する
