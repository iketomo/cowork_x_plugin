---
name: research-save
description: >
  会話の中で得られたリサーチ・調査・議論の内容をSupabaseのresearch_itemsテーブルに
  構造化して保存するスキル。メインエージェントはリクエスト受け付けのみ行い、
  会話内容の分析・構造化・INSERT実行はresearch-save-analyzerサブエージェントに委譲する。
  「リサーチを保存」「調査結果を保存」「リサーチデータを保存して」「save research」
  「この調査を記録して」「研究メモを保存」「今の議論を保存」「調べた内容を保存」
  「リサーチ保存」「調査をDBに保存」「この分析を保存して」
  「調査内容を記録」「リサーチ内容を蓄積して」などのフレーズで発動する。
  ※「Supabaseに保存」「長期メモリに保存」はmemory-saveスキルの領域。
  ※「アンケート結果を保存」「フォーム回答を保存」はenquete-saveスキルの領域。
  ※検索・参照は research-read スキルを使う。
  本スキルは「会話内での調査・議論・リサーチ内容の保存」に特化する。
version: 1.0.1
---

# リサーチ保存スキル

会話の中で得られたリサーチ・調査データをSupabaseの`research_items`テーブルに構造化して保存する。
重い処理（会話分析・構造化・INSERT）は `research-save-analyzer` サブエージェントに委譲し、
メインエージェントのコンテキストを節約する。

## 保存先

- Supabaseプロジェクト: **cowork** (project_id: `iltymrnkqchixvtpvewm`)
- テーブル: `public.research_items`

## 他スキルとの棲み分け

| スキル | 対象データ | 保存方式 |
|--------|-----------|---------|
| **research-save**（本スキル） | 会話・議論・調査の内容 | title/summary/facts/insightsに分解して保存。素早く保存（確認不要） |
| **memory-save** | 重要な設計決定・長期的な知見 | memoriesテーブル。カテゴリ・重要度付きで保存 |
| **enquete-save** | アンケート・インタビューの生データ | enquete_summaryテーブル。1示唆=1レコード。必ずユーザー確認あり |

## コンテキスト節約アーキテクチャ

- **メインエージェント**: 保存リクエストの受け付けのみ（保存対象が不明な場合のみ確認質問）
- **research-save-analyzerサブエージェント**: 会話の分析・構造化・content_hash生成・INSERT実行・結果報告

## 実行手順

### ステップ1: 保存対象を確認する

ユーザーが「リサーチを保存して」と言ったとき、直前の会話からリサーチ・調査・議論された内容を特定する。

- 保存対象が明確な場合は、すぐにステップ2へ進む（確認不要）
- 「どの部分を保存するか」が曖昧な場合のみ、ユーザーに1点だけ確認する

### ステップ2: research-save-analyzerサブエージェントを起動する

Taskツールで `research-save-analyzer` サブエージェントを起動し、以下のデータを渡す：

```
【保存対象の会話内容】
{ユーザーとの会話から特定したリサーチ・調査の内容をそのまま貼り付ける}

【Supabase接続情報】
- project_id: iltymrnkqchixvtpvewm
- テーブル: public.research_items
```

サブエージェントに以下の処理を委譲する：
- 複数トピックへの分割判断
- 各トピックのtitle/summary/facts/insights/raw_content/source_toolへの構造化
- content_hash（md5）の生成
- INSERT SQLの実行（ON CONFLICT DO NOTHING）
- 保存結果のユーザーへの報告

### ステップ3: 結果を確認する

サブエージェントの完了報告を受け取り、ユーザーに伝える。
サブエージェントが直接報告する設計のため、メインエージェントは中継のみ行う。

## research-save-analyzerサブエージェントへの委譲仕様

### テーブル構造（INSERTフィールド）

| フィールド | 必須 | 内容 |
|-----------|------|------|
| `title` | YES | リサーチのタイトル（簡潔に、30文字以内目安） |
| `summary` | YES | 要約（2〜5文で核心をまとめる） |
| `facts` | NO | 客観的な事実・データ・数値。箇条書きテキスト |
| `insights` | NO | 主観的な洞察・考察・示唆。箇条書きテキスト |
| `raw_content` | YES | 元の議論テキスト全体（トピック単位の原文） |
| `source_tool` | NO | 情報源ツール。言及があればそれを使う。なければ `claude` |
| `content_hash` | YES | `md5(raw_content)` で生成。重複防止に使用 |

**source_toolの許容値:** `chatgpt`, `claude`, `gemini`, `perplexity`, `grok`, `manus`, `genspark`, `skywork`, `other`

### INSERT SQL（サブエージェントが実行）

```sql
INSERT INTO public.research_items (title, summary, facts, insights, raw_content, source_tool, content_hash)
VALUES (
  '（タイトル）',
  '（要約）',
  '（事実・データ。なければNULL）',
  '（洞察。なければNULL）',
  '（元テキスト）',
  '（ソースツール）',
  md5('（元テキストと同じ値）')
)
ON CONFLICT (content_hash) WHERE content_hash IS NOT NULL
DO NOTHING
RETURNING id, title;
```

**SQLインジェクション防止**: テキスト中のシングルクォートは `''`（2つ重ねる）にエスケープすること。

複数トピックがある場合は、1トピック1 INSERTで複数回実行する。

### 完了報告フォーマット（サブエージェントが出力）

```
リサーチをN件保存しました:
1. 「{title}」(id: xxx...)
2. 「{title}」(id: xxx...)

（重複スキップがあった場合）
スキップ: 「既存タイトル」（同一内容が登録済み）
```

## 重要ルール

- 保存前にユーザーに構造化結果を見せて確認を取らない（素早く保存する）
- ただし保存対象が不明確な場合のみ確認する（enquete-saveとの違い）
- タグ付け（research_tags, research_item_tags）は本スキルのスコープ外。保存のみ行う
- `captured_at`はデフォルト（now()）で良い。ユーザーが「昨日の調査」など時期を指定した場合のみ設定する
- Supabase MCP の `execute_sql` ツールを使用する（project_id: `iltymrnkqchixvtpvewm`）
- **検索は別スキル**: 検索・参照は `research-read` スキルを使う
