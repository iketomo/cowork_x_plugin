---
name: enquete-save
description: >
  アンケート・インタビュー・フォーム回答などのリサーチデータを分析し、
  Supabaseのenquete_summaryテーブルに「1示唆 = 1レコード」の粒度で
  構造化サマリとして保存するスキル。
  「アンケート結果を保存」「調査データを登録」「インタビュー結果をDBに保存」
  「enquete-save」「アンケートサマリを登録して」「リサーチデータを保存」
  「フォーム回答を分析して保存」「アンケートの示唆を登録」
  「この調査結果を記録して」「アンケート分析して保存して」
  「フィードバックをDBに整理して」「survey saveして」などのリクエストで発動。
  ローデータではなく、抽象化・構造化されたサマリとして保存する。
  重要：勝手には保存しない。必ずユーザーに確認してから登録する。
version: 1.0.0
---

# アンケートデータ保存スキル

アンケート・インタビュー・フォーム回答などのリサーチデータを受け取り、
Supabaseの`enquete_summary`テーブルに「1示唆 = 1レコード」の粒度で構造化して保存する。

## 保存先

- Supabaseプロジェクト: **cowork** (project_id: `iltymrnkqchixvtpvewm`)
- テーブル: `public.enquete_summary`

## テーブル構成

| カラム | 型 | 説明 |
|--------|------|------|
| `id` | UUID (PK) | 自動生成 |
| `survey_name` | TEXT | 対象アンケート名（日本語、一意） |
| `survey_date` | DATE | アンケート実施日 |
| `result_title` | TEXT | 結果の要点（1行で把握できる粒度） |
| `result_detail` | TEXT | 結果の詳細説明（2〜5文程度） |
| `created_at` | TIMESTAMPTZ | 自動 |

---

## コンテキスト節約アーキテクチャ

**メインエージェントの役割は最小限にする。**

| 担当 | 処理内容 |
|------|----------|
| メインエージェント | 生データ受け取り → 既存survey_name一覧取得（SQL 1本）→ サブエージェント起動 → 完了報告 |
| サブエージェント（enquete-save-analyzer） | 分析・構造化・survey_name決定・ユーザー確認・INSERT実行・完了報告 すべて |

メインエージェントは **SQLの結果と生データをそのままサブエージェントに渡し、返り値の報告内容だけ受け取る**。
分析・構造化・INSERT処理には一切関与しない。

---

## 実行手順

### ステップ1: 生データを受け取る

ユーザーからアンケートの生データを受け取る。

受け取るデータの例:
- CSV形式のフォーム回答
- インタビューの書き起こし
- 自由記述の回答テキスト
- 集計済みの数値データと自由記述の組み合わせ

### ステップ2: 既存のsurvey_nameを確認する（SQL 1本のみ）

重複防止のため、Supabase MCPの`execute_sql`で以下を実行する（project_id: `iltymrnkqchixvtpvewm`）。

```sql
SELECT DISTINCT survey_name, survey_date
FROM enquete_summary
ORDER BY survey_date DESC;
```

### ステップ3: サブエージェント起動

SQL結果と生データを受け取ったら、**すぐにTaskツールでサブエージェント `enquete-save-analyzer` を起動**する。
メインエージェントでの分析・構造化・ユーザー確認・INSERT処理は一切行わない。

Taskツールの呼び出し:
- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"Enquete data analysis and save"`

**promptに含める内容:**
1. ユーザーから受け取ったアンケートの生データ（全文）
2. Step 2で取得した既存のsurvey_name一覧（SQLの結果をそのまま貼り付け）
3. `agents/enquete-save-analyzer.md` に定義されたサブエージェント指示に従って処理を実行するよう指示

### ステップ4: 完了報告

サブエージェントから返ってきた保存結果（保存件数・survey_name・各レコードのresult_title）をユーザーに提示する。

**以上で完了。** メインエージェントは分析内容やINSERT処理に関与しない。

---

## 重要ルール

- **勝手に保存しない** — ユーザー確認はサブエージェント内で必ず行う
- **ローデータの転記は禁止** — パターン・傾向として抽象化して保存する
- **粒度**: 1アンケートあたり 3〜8件 のレコードが目安（個人単位・全体まとめはNG）
- **同じsurvey_nameで追加保存は可能** — 同じアンケートに後から示唆を追加できる
- **このスキルは保存専用** — 読み込み・検索は `enquete-read` スキルを使う
