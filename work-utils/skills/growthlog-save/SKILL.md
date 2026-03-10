---
name: growthlog-save
description: >
  ユーザーの反省・学び・成功体験をSupabaseのgrowth_log_learningsテーブルに
  構造化して保存するスキル。メインエージェントはリクエスト受け付けのみ行い、
  内容の分析・構造化・INSERT実行はgrowthlog-save-analyzerサブエージェントに委譲する。
  「グロースログを保存」「反省を記録して」「学びを保存」「今日の振り返りを保存」
  「growthlog save」「反省ログを登録」「学びの記録を保存して」
  「グロースログに追加」「今日の学びを記録」「振り返りを保存して」
  「反省メモを保存」「成功体験を記録」「学んだことを保存」
  などのフレーズで発動する。
  ※検索・参照は growthlog-read スキルを使う。
  ※「Supabaseに保存」「長期メモリに保存」はmemory-saveスキルの領域。
  ※「リサーチを保存」はresearch-saveスキルの領域。
  本スキルは「日々の反省・学び・成功体験の保存」に特化する。
version: 1.0.0
---

# グロースログ保存スキル

ユーザーの反省・学び・成功体験をSupabaseの`growth_log_learnings`テーブルに構造化して保存する。
重い処理（内容分析・構造化・AIコメント生成・INSERT）は `growthlog-save-analyzer` サブエージェントに委譲し、
メインエージェントのコンテキストを節約する。

## 保存先

- Supabaseプロジェクト: **cowork** (project_id: `iltymrnkqchixvtpvewm`)
- テーブル: `public.growth_log_learnings`

## 他スキルとの棲み分け

| スキル | 対象データ | 保存方式 |
|--------|-----------|---------|
| **growthlog-save**（本スキル） | 日々の反省・学び・成功体験 | title/content/category/ai_commentに構造化して保存 |
| **research-save** | 会話・議論・調査の内容 | research_itemsテーブル。title/summary/facts/insightsに分解 |
| **memory-save** | 重要な設計決定・長期的な知見 | memoriesテーブル。カテゴリ・重要度付きで保存 |
| **enquete-save** | アンケート・インタビューの生データ | enquete_summaryテーブル。必ずユーザー確認あり |

## コンテキスト節約アーキテクチャ

- **メインエージェント**: 保存リクエストの受け付けのみ（保存対象が不明な場合のみ確認質問）
- **growthlog-save-analyzerサブエージェント**: 内容の分析・構造化・category判定・ai_comment生成・INSERT実行・結果報告

## 実行手順

### ステップ1: 保存対象を確認する

ユーザーが「グロースログを保存して」「学びを記録して」と言ったとき、保存対象を特定する。

- ユーザーが直接テキストを提供した場合 → そのテキストを raw_content として渡す
- 会話の中で反省・学びが語られた場合 → その部分を抽出して渡す
- 保存対象が不明確な場合のみ、ユーザーに1点だけ確認する

### ステップ2: growthlog-save-analyzerサブエージェントを起動する

Taskツールで `growthlog-save-analyzer` サブエージェントを起動し、以下のデータを渡す：

```
【保存対象のテキスト】
{ユーザーが提供した反省・学びの内容をそのまま貼り付ける}

【日付】
{ユーザーが日付を指定していればその日付。なければ「今日」}

【Supabase接続情報】
- project_id: iltymrnkqchixvtpvewm
- テーブル: public.growth_log_learnings
```

サブエージェントに以下の処理を委譲する：
- 内容の分析・要点抽出（content の箇条書き化）
- カテゴリの判定
- AIコメント（励ましや名言を含む一言）の生成
- INSERT SQLの実行
- 保存結果のユーザーへの報告

### ステップ3: 結果を確認する

サブエージェントの完了報告を受け取り、ユーザーに伝える。

## growthlog-save-analyzerサブエージェントへの委譲仕様

### テーブル構造（INSERTフィールド）

| フィールド | 必須 | 内容 |
|-----------|------|------|
| `date` | YES | 学びの日付（YYYY-MM-DD）。指定なければ今日の日付 |
| `title` | YES | タイトル（簡潔に、20文字以内目安） |
| `content` | YES | 学びの要点を箇条書きで構造化（「・」で始まる各行） |
| `category` | YES | カテゴリ。既存カテゴリから選択するか、適切な新カテゴリを設定 |
| `ai_comment` | YES | AI生成の励まし・コメント。関連する名言や格言を含める |
| `raw_content` | YES | ユーザーの元テキストをそのまま保存 |
| `want_more_retention` | NO | 定着強化フラグ。デフォルトfalse |

**既存カテゴリ例:** `マインド`, `コミュニケーション・人間関係`, `仕事術`, `健康・生活習慣`, `自己管理`, `リーダーシップ`
（新しいカテゴリも必要に応じて作成可）

### INSERT SQL（サブエージェントが実行）

```sql
INSERT INTO public.growth_log_learnings (date, title, content, category, ai_comment, raw_content, want_more_retention)
VALUES (
  '（YYYY-MM-DD）',
  '（タイトル）',
  '（要点の箇条書き）',
  '（カテゴリ）',
  '（AIコメント）',
  '（元テキスト）',
  false
)
RETURNING id, date, title, category;
```

**SQLインジェクション防止**: テキスト中のシングルクォートは `''`（2つ重ねる）にエスケープすること。

複数の学びが含まれている場合は、1つの学びにつき1 INSERTで複数回実行する。

### 完了報告フォーマット（サブエージェントが出力）

```
グロースログをN件保存しました:

1. [{date}] 「{title}」（{category}）
   要点: {contentの先頭行}
   AI: {ai_commentの冒頭50文字}...

2. [{date}] 「{title}」（{category}）
   ...
```

## 重要ルール

- 保存前にユーザーに構造化結果を見せて確認を取らない（素早く保存する）
- ただし保存対象が不明確な場合のみ確認する
- ai_commentは必ず関連する名言や格言を1つ含め、励ましや前向きな一言を添える
- categoryは既存カテゴリとなるべく一致させる（表記ゆれ防止）
- contentは「・」で始まる箇条書き形式で3〜5行程度にまとめる
- review_count, review_*_at は保存時に設定しない（デフォルト値を使用）
- Supabase MCP の `execute_sql` ツールを使用する（project_id: `iltymrnkqchixvtpvewm`）
- **検索は別スキル**: 検索・参照は `growthlog-read` スキルを使う
