# プラグインアップデート履歴

プラグインの変更内容をバージョンごとに記録する。

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
