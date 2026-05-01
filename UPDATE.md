# プラグインアップデート履歴

プラグインの変更内容をバージョンごとに記録する。

---

## 2026-05-01

### work-utils `1.0.11`

`line-message` スキルを実配信のCTR分析データに基づいてアップデート。

- 「読者の内声代弁」型冒頭を最重要フレームとして追加（実測CTR 13.1%・他の約2倍）
- CTAボタン文言「気になる」を関心表明用CTAのデフォルトに変更（「興味ある」よりCTR +4〜6pt）
- 「カルーセル複数告知」「情報告知型冒頭」「ベネフィット→課題順」をNGパターンとして明記
- 個人イベント勝ちパターンの実証テンプレート（CTR 13.1%）を追加
- 配信チェックリストに「内声代弁から始まっているか」「『気になる』を最優先で検討したか」を追加
- スキル version: `1.0.0` → `1.0.1`

---

## 2026-04-03

### work-utils `1.0.10`

slide-excel スキルを新規追加。

- `slide-excel` スキル新規追加: いけともch向けYouTube動画企画を議論・構成検討し、3列構成（タイトル/内容/備考）のExcelファイルとして出力。openpyxlでデザイン規約に沿ったExcelを生成
- `/slide-excel` コマンド新規追加
- スキル数: 14 → 15、コマンド数: 13 → 14

### luma-manager `1.0.6`

luma-mail-update スキルを新規追加。

- `luma-mail-update` スキル新規追加: Lumaイベント登録確認メールのイベント紹介リストをChrome MCP経由で一括更新。既存メール設定の差替・新規作成に対応
- `/luma-mail-update` コマンド新規追加
- スキル数: 4 → 5、コマンド数: 2 → 3

### luma-manager `1.0.5`

luma-create-event スキルを新規追加。

- `luma-create-event` スキル新規追加: Lumaイベント＋Zoomウェビナーの一括作成。ヒアリング→確認→Zoom作成→Luma作成→結果報告のフロー。Zoom失敗時のフォールバック（Lumaのみ作成）にも対応
- `/luma-create-event` コマンド新規追加
- スキル数: 3 → 4、コマンド数: 1 → 2

### work-utils `1.0.9`

zoom-create-webinar スキルを新規追加。

- `zoom-create-webinar` スキル新規追加: Supabase Edge Function経由でZoomウェビナーを作成する汎用スキル。単独利用もluma-create-eventからの内部呼び出しも可能
- `/zoom-create-webinar` コマンド新規追加
- スキル数: 13 → 14、コマンド数: 11 → 12

---

## 2026-03-27

### work-utils `1.0.8`

browser-use スキルを新規追加。

- `browser-use` スキル新規追加: Browser Use 2.0 (bu-2-0) を使ったブラウザ自動操作。Chrome CDP接続によるログイン済みセッション再利用、Webスクレイピング・情報収集・フォーム操作等に対応
- コマンド `/browser-use` を追加

---

## 2026-03-26

### x-manager `1.0.8`

x-post スキルに下書きモード（Chrome MCP）を追加。

- `x-post` スキル: 投稿モード（Edge Function経由）に加え、下書きモード（Chrome MCP経由でX.comの下書きに保存）を追加。モード判定・Chrome MCP接続確認・テキスト入力・下書き保存の手順を定義
- SKILL.md を v2.0.0 に更新

### work-utils `1.0.7`

ai-buzz-title-generator スキルを新規追加。

- `ai-buzz-title-generator` スキル新規追加: AIノウハウ系コンテンツ（X・YouTube・ブログ等）のバズるタイトル・冒頭文・サムネイル案を生成。心理学的フック（好奇心ギャップ・損失回避・権威性）、プラットフォーム別最適化、パワーワードリスト、NGパターンを定義
- `/ai-buzz-title-generator` コマンド新規追加
- スキル数: 12 → 13、コマンド数: 10 → 11

---

## 2026-03-17

### work-utils `1.0.6`

multi-stage-research スキルを新規追加。

- `multi-stage-research` スキル新規追加: テーマを受け取り多段階（設計→並列調査→統合→批判チェック→レポート化）でリサーチを実行。並列エージェント調査・批判チェック・ビジネス読み物スタイルのレポート出力に対応
- `/research` コマンド新規追加
- スキル数: 11 → 12、コマンド数: 9 → 10

---

## 2026-03-15

### x-manager `1.0.6`

レポートのチャット内閲覧対応。

- `x-daily-report` スキル: レポート保存後にReadツールでファイルを読み込み、Claude Code上で折りたたみ式に閲覧可能に
- `x-trend-report` スキル: 同上

### circle-manager `1.0.3`

レポートのチャット内閲覧対応。

- `circle-daily-report` スキル: サブエージェント完了後にReadツールでレポートファイルを読み込み、Claude Code上で折りたたみ式に閲覧可能に

### luma-manager `1.0.3`

レポートのチャット内閲覧対応。

- `luma-daily-report` スキル: Step 4「チャット内表示」を追加。Readツールでログファイルを読み込み、Claude Code上で折りたたみ式に閲覧可能に

### youtube-ideas-manager `1.0.3`

レポートのチャット内閲覧対応。

- `weekly-youtube-ideas` スキル: Step 4「チャット内表示」を追加。Readツールでログファイルを読み込み、Claude Code上で折りたたみ式に閲覧可能に

---

## 2026-03-14

### work-utils `1.0.5`

line-message スキルを新規追加。

- `line-message` スキル新規追加: LINE公式アカウントの「関心引き出しメッセージ」作成。行動経済学・心理学の知見（6種の心理トリガー、3種のフォーミュラ、CTA6原則、売り込み感排除技法）に基づき、1画面150〜300文字のメッセージを3パターン提案
- `/line-message` コマンド新規追加
- スキル数: 10 → 11、コマンド数: 8 → 9

---

## 2026-03-12

### work-utils `1.0.4`

fact-check-rewrite スキルを新規追加。

- `fact-check-rewrite` スキル新規追加: 記事・リサーチレポートのファクト抽出→並列サブエージェントによる検証→統合結果リスト→story-writing準拠の修正記事をGoogleドキュメントまたはWordで出力
- スキル数: 9 → 10

### x-manager `1.0.5`

x-article-leadtext と x-article-image スキルを新規追加。

- `x-article-leadtext` スキル新規追加: X記事の紹介ポスト本文（ティザー/リード文）をAIDA-Xフレームワークで生成。5パターン（問題解決型・成果数字型・好奇心ギャップ型・ストーリー型・リスト型）と実践ルールを定義
- `x-article-image` スキル新規追加: 記事・カード用横長画像（5:2）をNano Banana 2で生成。Edge Function `x-generate-article-image` の reference を追加
- `/x-article-leadtext`、`/x-article-image` コマンド新規追加
- スキル数: 5 → 7、コマンド数: 5 → 7

### work-utils `1.0.3`

story-writing スキルを新規追加。

- `story-writing` スキル新規追加: 東洋経済オンライン・NewsPicks風のビジネス読み物スタイルで文章を作成
- 基本原則・構成パターン（フック→ナットグラフ→本論→統合→回帰）、5つの詳細ルール、最終レポートテンプレートを定義
- スキル数: 8 → 9

---

## 2026-03-11

### work-utils `1.0.2`

グロースログ（反省・学び）の読み込み・保存スキルを新規追加。

- `growthlog-read` スキル新規追加: growth_log_learningsテーブルからの読み込み・検索・カテゴリ絞り込み・復習対象抽出
- `growthlog-save` スキル新規追加: 反省・学び・成功体験の構造化保存（サブエージェント委譲型）
- `growthlog-save-analyzer` サブエージェント新規追加: 内容分析・構造化・AIコメント生成・INSERT実行
- `/growthlog-read`, `/growthlog-save` コマンド新規追加
- スキル数: 6 → 8、コマンド数: 6 → 8、サブエージェント数: 2 → 3

---

## 2026-03-08

### work-utils `1.0.1`

スキル分割・リネーム・新規追加による構成改善。

- `memory-manager` を `memory-save`（保存専用）と `memory-read`（検索専用）に分割
- `save-research` を `research-save` にリネーム（save/read の命名規則統一）
- `research-read` を新規追加（research_items テーブルの検索・一覧表示）
- コマンドも対応して更新: `/memory` → `/memory-save` + `/memory-read`, `/save-research` → `/research-save`, `/research-read` 新規追加
- サブエージェント `research-save-analyzer` の参照先をリネームに合わせて更新
- スキル数: 4 → 6、コマンド数: 4 → 6

---

## 2026-03-07

### x-manager `1.0.4`

x-manager のアップデート。

- バージョンを 1.0.3 → 1.0.4 に更新

### work-utils `1.0.0`（新規作成）

`others` フォルダを `work-utils` プラグインとして構成。

- **スキル（4つ）**
  - `enquete-read`: アンケートサマリの読み込み・検索・一覧表示
  - `enquete-save`: アンケート生データの分析→構造化サマリとしてDB保存（サブエージェント委譲型）
  - `memory-manager`: Supabase長期メモリの保存・検索・活用
  - `save-research`: 会話中のリサーチ・調査結果のDB保存（サブエージェント委譲型）
- **サブエージェント（2つ）**
  - `enquete-save-analyzer`: アンケート生データの分析・構造化・ユーザー確認・INSERT実行
  - `research-save-analyzer`: 会話内容の分析・構造化・INSERT実行
- **コマンド（4つ）**
  - `/enquete-read`, `/enquete-save`, `/memory`, `/save-research`
- 全スキルをプラグイン作成ガイド（plugin-creation-guide.md）のテンプレートに準拠させリファクタリング
- コンテキスト節約アーキテクチャを適用（enquete-save, save-research はサブエージェント委譲型）
