---
name: memory-manager
description: >
  Claudeとの議論・知見・設計決定をSupabase長期メモリに保存・検索・活用するスキル。
  保存モード: 「Supabaseに保存して」「議論を記録して」「長期メモリに登録して」「ナレッジを保存して」
  「この決定を保存して」「記録しておいて」「知見をストックして」「後で使えるように保存して」
  検索モード: 「過去の議論を探して」「関連するナレッジを確認して」「記録を検索して」「何か保存してある？」
  「以前の設計を確認したい」「過去の知見を参照して」「長期メモリから探して」
  会話の中で重要な決定・設計・知見が生まれたと判断した場合も積極的に保存を提案する。
  ※「メモリに保存して」という単純なフレーズはClaude標準メモリと混同しやすいため、
  ユーザーが「メモリ」と言った場合はどちらに保存するか確認してからこのスキルを使う。
version: 1.0.0
---

# Memory Manager スキル

## 概要

Supabase（coworkプロジェクト）の `memories` テーブルに、Claudeとの議論を長期記憶として蓄積・再利用する。
保存と検索の2モードがあり、いずれもSupabase MCP経由の `execute_sql` で操作する。
embeddingは日次バッチで自動生成される。

## 接続情報

- **Project ID**: `iltymrnkqchixvtpvewm`（cowork）
- **保存・取得方法**: Supabase MCP → `execute_sql`
- **embedding生成**: 毎日 3:00 JST（18:00 UTC）に自動バッチ処理

## コンテキスト節約アーキテクチャ

- メインエージェント: 直接実行（SQL操作中心のため委譲不要）
- サブエージェント: 不使用（保存・検索ともに軽量なSQL操作のみ）

---

## 実行手順

### 保存モード

#### ステップ1: トリガー判定・曖昧性ガード

下記フレーズが出たら保存モードを開始する：
「Supabaseに保存して」「議論を記録して」「長期メモリに登録して」「ナレッジを保存して」
「この決定を保存して」「記録しておいて」「知見をストックして」「後で使えるように保存して」

> ユーザーが単に「メモリに保存して」と言った場合は、以下を確認してから進む：
> 「Supabase長期メモリとClaude標準メモリのどちらに保存しますか？」

#### ステップ2: フィールドを決定してINSERT

会話の流れからタイトル・サマリー・カテゴリ・重要度を判断し、以下のSQLを実行する。

```sql
INSERT INTO memories (title, summary, full_content, category, importance)
VALUES (
  'タイトル（30字以内）',
  '結論・要点（300字以内）',
  '詳細内容（不要ならNULL）',
  'カテゴリ',  -- 戦略/技術/研修/ビジネス/アイデア/書籍/YouTube/その他
  3            -- 重要度 1〜5（5が最重要）
)
RETURNING id, title, created_at;
```

**タグはINSERT時に設定しない。** データ蓄積後にボトムアップで追加する。

#### ステップ3: 完了報告

```
✅ Supabase長期メモリに保存：「{title}」
   カテゴリ: {category} ／ 重要度: {importance}
   ※ embedding は次回バッチ（毎日3:00 JST）で自動付与
```

---

### 検索モード

#### ステップ1: トリガー判定

下記フレーズが出たら検索モードを開始する：
「過去の議論を探して」「関連するナレッジを確認して」「記録を検索して」「何か保存してある？」
「以前の設計を確認したい」「過去の知見を参照して」「長期メモリから探して」

#### ステップ2: 検索パターンを選択してSQL実行

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

#### ステップ3: 結果の活用

取得したメモリを会話のコンテキストとして使い、「過去にこういう議論がありました」と要約して提示する。

---

## 重要ルール

- **曖昧性ガード**: 「メモリに保存して」という単純なフレーズではこのスキルを即時起動しない。Supabase長期メモリかClaude標準メモリかを確認してから動作する
- **タグはINSERT時不要**: タグはデータ蓄積後にボトムアップで後付けする。INSERTのSQL文にはtagsフィールドを含めない
- **embedding遅延**: INSERTから最大24時間でembeddingが付与される。キーワード検索（パターンB）は即日使用可能
- **自発的な保存提案**: 技術的設計の決定・合意形成・重要方針の確定が生じたとき、能動的に「Supabase長期メモリに保存しますか？」と提案する

---

## フィールド定義

| フィールド | 内容 | 例 |
|---|---|---|
| `title` | 議論のタイトル（30字以内） | "Dify並列ナレッジ検索の設計" |
| `summary` | 結論・要点（300字以内） | "Variable Aggregatorで..." |
| `full_content` | 詳細内容（任意・NULLでも可） | 議論の詳細テキスト |
| `category` | カテゴリ（下記一覧） | "技術" |
| `importance` | 重要度 1〜5（5が最重要） | 3 |

**カテゴリ一覧**: `戦略` / `技術` / `研修` / `ビジネス` / `アイデア` / `書籍` / `YouTube` / `その他`

---

## タグの後付け運用

```sql
-- タグを後から追加
UPDATE memories
SET tags = ARRAY['タグ1', 'タグ2']
WHERE id = 'uuid';

-- タグ使用数を集計
SELECT sync_tag_usage_counts();
```

---

## embedding・バッチの仕様

- 毎日 **3:00 JST**（18:00 UTC）に自動実行
- `batch-generate-embeddings` Edge Function が `embedding IS NULL` のレコードを最大100件処理
- INSERTからembeddingが付くまで最大24時間。キーワード検索は即日使用可能
