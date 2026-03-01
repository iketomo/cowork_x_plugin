---
name: weekly-youtube-ideas
description: いけともch（YouTube 17万人登録のAI活用チャンネル）向けに、Supabaseのyoutube_idea_generatorプロジェクトからトレンド動画を取得し、傾向を分析した上で企画案10個を生成するスキル。「YouTube企画」「今週のトレンドから企画」「いけともchの企画案」「動画ネタ出し」「週次の企画生成」「トレンド分析して企画」などのリクエストで発動。毎週の定期実行にも対応。Supabase MCP経由でデータを取得し、Claudeが分析・企画立案を行う。
---

# Weekly YouTube Ideas Generator for いけともch（最適化版）

## アーキテクチャ概要

**コンテキスト節約のため、2段階構成で実行する。**

```
メインエージェント
  ├─ サブエージェント（Task: general-purpose）: データ取得＋トレンド分析 → 結果をテキストで返す
  └─ メインエージェント: 分析結果を読み、企画10本生成＋Slack通知
```

- SQL側のビュー（`weekly_trending_summary`）で事前集約し、生データの取得を最小化
- サブエージェントが分析を担当し、メインエージェントのコンテキストにはコンパクトなサマリのみ

## 前提情報

### いけともchプロフィール
- チャンネル名: いけともch / 登録者: 17万人超
- テーマ: ChatGPTや最新AIツールの活用法を、独自のビジネス視点から解説
- ターゲット: ビジネスパーソン、経営者、フリーランス（非エンジニア中心）
- 強み: 起業経験 × 生成AI知見、実務に直結する具体例
- 著書: 『ChatGPT最強の仕事術』（4万部）、『Perplexity 最強のAI検索術』
- 動画の長さ: 10〜25分が主流

### Supabaseプロジェクト情報
- `config.local.md` を参照して、プロジェクトID・プロジェクト名を取得すること

### 主要テーブル・ビュー
詳細は `references/db-schema.md` を参照。

**集約ビュー（最適化用に作成済み）:**
- `weekly_trending_compact`: トレンド動画を最新スナップショットとJOINし、再生数順で返すビュー
- `weekly_trending_summary`: **1行で全集約を返すサマリビュー**（統計＋TOP15＋競合＋急上昇をJSON配列で格納）

## 実行手順

### Step 1: サブエージェントでデータ取得＋トレンド分析

**Taskツール（subagent_type: general-purpose）を起動し、以下のプロンプトを渡す。**

プロンプト:

---

あなたはYouTubeトレンド分析の専門家です。以下の手順でデータ取得と分析を行い、結果をコンパクトなMarkdownで返してください。

## 手順

### 1. サマリデータの取得
Supabase MCPの`execute_sql`（project_idは`config.local.md`を参照）で以下を実行:

```sql
SELECT * FROM weekly_trending_summary;
```

これにより1行で以下が得られます:
- total_videos, jp_videos, en_videos, competitor_videos
- shorts_count, medium_count, long_count, avg_views, max_views
- top15_by_views（JSON配列: title, channel_name, channel_type, view_count, like_count, growth_rate, is_japanese, duration_seconds, youtube_video_id）
- competitor_highlights（JSON配列）
- top5_by_growth（JSON配列）

### 2. ニュース情報の取得
```sql
SELECT title, source_name, received_at
FROM news
WHERE is_processed = false
ORDER BY received_at DESC
LIMIT 15;
```

### 3. 既存企画の重複チェック用
```sql
SELECT title_main, direction FROM ideas ORDER BY created_at DESC LIMIT 20;
```

### 4. 分析と出力

取得データを以下の観点で分析し、**以下のフォーマットのMarkdownだけを返してください**:

```markdown
## 今週のトレンド分析（MM/DD〜MM/DD）

### 基本統計
- トレンド動画数: X本（日本語X / 英語X / 競合X）
- 平均再生数: X / 最高再生数: X
- 動画長分布: ショートX / 中尺X / 長尺X

### 🔥 注目トピック TOP3
1. [トピック名] - [根拠: 動画X本、代表「タイトル」XX万再生]
2. ...
3. ...

### 📊 高再生TOP5（企画のヒント用）
| # | タイトル | CH名 | 再生数 | 伸び率 | 日本語 |
|---|---------|------|--------|--------|--------|
| 1 | ... | ... | ... | ... | ... |

### ⚡ 急上昇TOP3（伸び率順）
| # | タイトル | CH名 | 伸び率 | 再生数 |
|---|---------|------|--------|--------|
| 1 | ... | ... | ... | ... |

### ⚔️ 競合の動き
- [チャンネル名]「[タイトル]」XX万再生
- ...

### 📰 未処理ニュース（企画ネタ候補）
- [タイトル]（ソース名）
- ...

### 🚫 既存企画（重複回避用）
- [タイトル]（方向性）
- ...

### 📝 コンテンツ形式の推定分布
- 速報系: X本 / 解説系: X本 / 比較系: X本 / ハウツー系: X本 / その他: X本
（※タイトルから推定）
```

**重要: 余計な前置きや説明は不要。上記フォーマットのMarkdownだけを返すこと。**

---

### Step 2: 企画案10個の生成（メインエージェント）

サブエージェントから返された分析結果を読み、以下のルールで企画案を10個生成する。

#### 企画の方向性バランス（目安）
- 速報系: 2〜3本（直近1週間の新機能・新ツールに反応）
- 解説系: 2〜3本（トレンドトピックの深掘り）
- 比較系: 1〜2本（ツール比較、新旧比較）
- ハウツー系: 2〜3本（実務活用の具体例）
- 検証系/まとめ系: 1〜2本（実際に試してみた系）

#### いけともchフィルター（全企画に適用）
- 非エンジニアのビジネスパーソンが理解・実践できる内容か？
- 「池田さんならでは」の切り口（起業家視点、60社支援の経験）があるか？
- 既存企画リストとネタ被りしていないか？
- サムネ映えするキーワードが入っているか？
- 10〜25分で収まる内容量か？

#### 出力フォーマット（1企画あたり）

```
### 企画 X: [title_main]

**方向性**: [direction] ※速報系/解説系/比較系/ハウツー系/検証系/まとめ系/予測系
**想定視聴者**: [target_audience]

**概要**: [summary]（2〜3文）

**なぜ今これか**: [reasoning]（トレンドデータに基づく根拠）

**サムネワード**: [thumbnail_words]（3つ）

**タイトル案**:
- 案1: ...
- 案2: ...
- 案3: ...

**章立て案**:
1. ...
2. ...
3. ...
4. ...
5. ...

**参考元**: [動画タイトル]（チャンネル名 / XX万再生）
```

### Step 3: Markdownレポートの出力

分析結果と企画案10個をまとめたMarkdownファイルを生成する。ファイル名は `weekly_ideas_YYYYMMDD.md` とする。
場所は `config.local.md` の「レポート出力先」フォルダに保存する（デフォルト: `cowork_youtube_ideas_optimize/log/`）。



## 注意事項

- トレンド動画が少ない週（5本未満）は、サブエージェントに「期間を14日に拡大してweekly_trending_compactから直接取得」と指示する
- 再生数やいいね数はスナップショット時点の値
- 企画の優先度付けは行わない（ユーザーが自分の感覚で選ぶ前提）
- ニュースデータが0件でも、動画トレンドだけで企画生成は可能
