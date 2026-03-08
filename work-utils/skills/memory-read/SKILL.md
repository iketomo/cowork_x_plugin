---
name: memory-read
description: >
  Supabase長期メモリ（memoriesテーブル）から過去の議論・知見・設計決定を検索・参照するスキル。
  「過去の議論を探して」「関連するナレッジを確認して」「記録を検索して」「何か保存してある？」
  「以前の設計を確認したい」「過去の知見を参照して」「長期メモリから探して」
  「メモリを検索」「保存した知見を見せて」「ナレッジ一覧」「記録の一覧」
  ※保存は memory-save スキルを使う。
version: 1.0.1
---

# Memory Read スキル

## 概要

Supabase（coworkプロジェクト）の `memories` テーブルから、保存済みの議論・知見を検索・参照する。
Supabase MCP経由の `execute_sql` で操作する。

## 接続情報

- **Project ID**: `iltymrnkqchixvtpvewm`（cowork）
- **取得方法**: Supabase MCP → `execute_sql`

## コンテキスト節約アーキテクチャ

- メインエージェント: 直接実行（軽量なSQL操作のみ）
- サブエージェント: 不使用

---

## 実行手順

### ステップ1: トリガー判定

下記フレーズが出たら検索モードを開始する：
「過去の議論を探して」「関連するナレッジを確認して」「記録を検索して」「何か保存してある？」
「以前の設計を確認したい」「過去の知見を参照して」「長期メモリから探して」
「メモリを検索」「保存した知見を見せて」「ナレッジ一覧」「記録の一覧」

### ステップ2: 検索パターンを選択してSQL実行

状況に応じて以下のパターンを使い分ける。

**パターンA: 最近の記録を一覧表示**
```sql
SELECT id, title, category, tags, importance, created_at
FROM memories
ORDER BY importance DESC, created_at DESC
LIMIT 20;
```

**パターンB: キーワード検索**
```sql
SELECT id, title, summary, category, importance, created_at
FROM memories
WHERE title ILIKE '%キーワード%' OR summary ILIKE '%キーワード%'
ORDER BY importance DESC, created_at DESC
LIMIT 10;
```

**パターンC: カテゴリ絞り込み**
```sql
SELECT id, title, summary, importance, created_at
FROM memories
WHERE category = '技術'
ORDER BY importance DESC, created_at DESC;
```

**パターンD: タグ絞り込み（タグ付け後）**
```sql
SELECT id, title, summary, category, importance
FROM memories
WHERE tags && ARRAY['Dify', 'ワークフロー']
ORDER BY importance DESC;
```

**パターンE: embeddingベクトル類似検索（バッチ後）**
```sql
SELECT * FROM search_memories_by_filter(
  p_keyword := 'キーワード',
  p_category := NULL,
  p_tags := NULL,
  p_limit := 10
);
```

### ステップ3: 結果の表示

#### 一覧モードの場合

```
保存済みメモリ一覧（計N件）:

| # | タイトル | カテゴリ | 重要度 | 保存日 |
|---|---------|---------|--------|--------|
| 1 | Dify並列ナレッジ検索の設計 | 技術 | ⭐5 | 2026-03-01 |
| 2 | ... | ... | ... | ... |
```

#### キーワード検索の場合

```
「{キーワード}」の検索結果（N件ヒット）:

1. **{title}** [{category} / 重要度{importance}]
   {summary}

2. ...
```

### ステップ4: 結果の活用

取得したメモリを会話のコンテキストとして使い、「過去にこういう議論がありました」と要約して提示する。

---

## 重要ルール

- **読み込み専用**: データの保存は `memory-save` スキルを使う
- 検索結果が多い場合は、重要度の高いものを優先して表示し、全件は省略してよい
- 検索結果が0件の場合は、その旨を伝え、キーワードの変更を提案する
- **曖昧なリクエスト**: ユーザーの検索意図が不明確な場合は、まずパターンA（一覧）を実行して候補を提示する
