---
name: enquete-read
description: >
  Supabaseのenquete_summaryテーブルからアンケート・インタビュー等のリサーチサマリを
  読み込み・検索・一覧表示するスキル。
  「アンケート結果を見せて」「過去のアンケートを検索」「調査結果を確認」
  「enquete-read」「アンケートサマリを取得」「インタビュー結果を探して」
  「満足度に関するアンケートを横断検索」「登録済みアンケート一覧」
  「過去のリサーチデータを確認」「アンケートの傾向を調べて」
  「どんなアンケートが登録されてる？」「一覧見せて」「リサーチ結果を参照」
  「フィードバックデータを確認」「ユーザーインタビューの結果は？」などのリクエストで発動。
version: 1.0.0
---

# アンケートデータ読み込みスキル

## 概要

Supabaseの`enquete_summary`テーブルから、保存済みのアンケート・インタビューサマリを読み込み・検索・表示する。
ユーザーのリクエストに応じて「一覧表示」「特定アンケートの取得」「テーマ横断検索」の3つのモードで動作する。

## コンテキスト節約アーキテクチャ

- メインエージェントで直接実行（軽量処理のため委譲不要）
- SQL実行・結果整形・表示をメインエージェントが一貫して担当する

## データソース

- Supabaseプロジェクト: **cowork** (project_id: `iltymrnkqchixvtpvewm`)
- テーブル: `public.enquete_summary`

---

## 実行手順

### ステップ1: ユーザーの意図を判別する

ユーザーのリクエストに応じて、以下の3つのモードから適切なものを選択する。

| モード | ユーザーの意図 | 例 |
|--------|---------------|-----|
| **一覧** | 登録済みアンケートの全体像を把握したい | 「どんなアンケートが登録されてる？」「一覧見せて」 |
| **特定取得** | 特定のアンケートの全サマリを見たい | 「3月のミートアップのアンケート結果は？」 |
| **横断検索** | テーマやキーワードで横断的に探したい | 「満足度に関する結果を全部見せて」 |

### ステップ2: SQLを実行する

Supabase MCPの`execute_sql`で実行する（project_id: `iltymrnkqchixvtpvewm`）。

#### モード1: 登録済みアンケート一覧

```sql
SELECT DISTINCT survey_name, survey_date, COUNT(*) as record_count
FROM enquete_summary
GROUP BY survey_name, survey_date
ORDER BY survey_date DESC;
```

#### モード2: 特定アンケートの全サマリ取得

```sql
SELECT id, result_title, result_detail, created_at
FROM enquete_summary
WHERE survey_name = '（対象のsurvey_name）'
ORDER BY created_at;
```

survey_nameが正確にわからない場合は、部分一致で検索する：

```sql
SELECT DISTINCT survey_name, survey_date
FROM enquete_summary
WHERE survey_name ILIKE '%（キーワード）%'
ORDER BY survey_date DESC;
```

#### モード3: テーマ横断検索

```sql
SELECT survey_name, survey_date, result_title, result_detail
FROM enquete_summary
WHERE result_title ILIKE '%（キーワード）%'
   OR result_detail ILIKE '%（キーワード）%'
ORDER BY survey_date DESC;
```

複数キーワードで検索する場合：

```sql
SELECT survey_name, survey_date, result_title, result_detail
FROM enquete_summary
WHERE (result_title ILIKE '%キーワード1%' OR result_detail ILIKE '%キーワード1%')
  AND (result_title ILIKE '%キーワード2%' OR result_detail ILIKE '%キーワード2%')
ORDER BY survey_date DESC;
```

### ステップ3: 結果をユーザーに見やすく表示する

#### 一覧モードの場合

```
登録済みアンケート一覧（計N件）:

| # | アンケート名 | 実施日 | サマリ件数 |
|---|-------------|--------|-----------|
| 1 | 3月AIミートアップ_参加後アンケート | 2026-03-01 | 5件 |
| 2 | 2月14日バイブコーディング_フォロー | 2026-02-21 | 4件 |
```

#### 特定取得モードの場合

```
「3月AIミートアップ_参加後アンケート」のサマリ（5件）:

1. **参加動機の最多は実務活用**
   全回答の約45%が実務活用を動機として挙げた。次点は...

2. **満足度4.2/5.0で高水準**
   全体満足度は4.2/5.0。一方、自由記述では...

3. ...
```

#### 横断検索モードの場合

```
「満足度」に関するサマリ（3件ヒット）:

1. [3月AIミートアップ_参加後アンケート / 2026-03-01]
   **満足度4.2/5.0で高水準**
   全体満足度は4.2/5.0。一方...

2. [Coworkベータ版_フィードバック / 2026-02-15]
   **UI満足度は高いがオンボーディングに課題**
   ...
```

---

## 活用シーン

このスキルは以下のような場面で役立つ：

- **新しいアンケートの設計時**: 過去に似たアンケートで何がわかったか確認する
- **イベント企画時**: 過去のイベントフィードバックから改善点を洗い出す
- **レポート作成時**: 複数アンケートの横断的な傾向をまとめる
- **意思決定時**: 特定テーマに関する過去の調査結果を参照する

---

## 重要ルール

- このスキルは読み込み専用。データの保存・登録は `enquete-save` スキルを使う
- 検索結果が多い場合は、重要度の高いものを優先して表示し、全件は省略してよい
- ユーザーが特定のアンケートを指定しているが名前が曖昧な場合、部分一致で候補を提示する
- 検索結果が0件の場合は、その旨を伝え、キーワードの変更を提案する
