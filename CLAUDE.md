# Cowork Plugins マーケットプレイス

## 概要
各種サービスの運用を支援するCowork Pluginのマーケットプレイス。

## プラグイン構成

```
cowork_plugin/                              # マーケットプレイス
├── .claude-plugin/
│   └── marketplace.json                   # マーケットプレイスマニフェスト
├── x-manager/                             # プラグイン① X (Twitter) 管理
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 7スキル
│   ├── agents/                            # 5サブエージェント
│   ├── commands/                          # 7コマンド
│   ├── scripts/
│   ├── reference/
│   ├── log/
│   ├── config.example.md
│   └── config.local.md
├── circle-manager/                        # プラグイン② Circle コミュニティ管理
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 1スキル
│   ├── agents/                            # 1サブエージェント
│   ├── commands/                          # 1コマンド
│   ├── config.example.md
│   └── config.local.md
├── luma-manager/                          # プラグイン③ Luma イベント管理
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 1スキル
│   ├── agents/                            # 1サブエージェント
│   ├── commands/                          # 1コマンド
│   ├── config.example.md
│   └── config.local.md
├── youtube-ideas-manager/                 # プラグイン④ YouTube 企画生成
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 1スキル
│   ├── agents/                            # 1サブエージェント
│   ├── commands/                          # 1コマンド
│   ├── config.example.md
│   └── config.local.md
├── work-utils/                            # プラグイン⑤ 汎用業務ユーティリティ
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 16スキル
│   ├── agents/                            # 3サブエージェント
│   ├── commands/                          # 14コマンド
│   └── config.example.md
├── CLAUDE.md
├── SETUP.md
├── PROGRESS.md
└── .gitignore
```

## プラグイン一覧

---

### 1. x-manager（X / Twitter 管理）

#### スキル

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| x-daily-report | 「X日次レポート」「パフォーマンス分析」 | 自分の投稿のWinner/Watch分類・伸び分析・投稿提案 |
| x-trend-report | 「Xトレンドレポート」「AI界隈のバズ」 | AI領域バズ投稿のトレンド分析・投稿戦略提案 |
| x-post | 「Xに投稿して」「ツイートして」「下書きにして」 | 投稿モード（Edge Function経由）または下書きモード（Chrome MCP経由）でXに投稿/保存 |
| x-writing | 「X投稿を書いて」「ツイート案」 | 投稿文作成 |
| x-image | 「X投稿の画像を作って」「投稿用画像を生成」 | 投稿用1:1画像生成（Nano Banana 2） |
| x-article-image | 「記事用の画像」「カード画像」「横長ヘッダー」 | 記事用5:2横長画像生成（Nano Banana 2） |
| x-article-leadtext | 「X記事の紹介文」「記事のティザー」「元記事を踏まえて導入を」 | X記事の紹介ポスト本文（AIDA-X）生成 |

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| x-daily-analyzer | sonnet | x-daily-report | 分類・分析・ニュース検索・DB保存・レポート出力 |
| x-trend-data-collector | sonnet | x-trend-report Step1 | SQL実行・データ整形 |
| x-trend-news-researcher | sonnet | x-trend-report Step2 | バズ投稿の背景調査（並列5件） |
| x-trend-analyzer | sonnet | x-trend-report Step3 | 総合分析・DB保存・レポート出力 |
| x-writer | sonnet | x-writing (x-write) | SKILL.md要件に基づく投稿文作成・品質チェック |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/x-daily` | 日次パフォーマンスレポートを生成 | なし |
| `/x-trend` | AI領域トレンド分析レポートを生成 | なし |
| `/x-write` | X投稿の文章を作成 | テーマやニュースURL（任意） |
| `/x-post` | Xに投稿を実行 | 投稿テキスト（任意） |
| `/x-image` | 投稿用画像を生成 | 投稿テキスト or ファイルパス（任意） |
| `/x-article-image` | 記事・カード用横長画像（5:2）を生成 | 記事タイトル or 画像用テキスト（任意） |
| `/x-article-leadtext` | X記事の紹介ポスト本文を生成 | 記事URL or タイトル・要約（任意） |

#### データベース
- Supabase: `cowork`（config.local.md参照）
- DB: `x_*`, `x_trend_*` テーブル群

---

### 2. circle-manager（Circle コミュニティ管理）

#### スキル

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| circle-daily-report | 「Circle日次レポート」「アイザックのレポート」「未対応コメント確認」 | 未対応コメント・新規投稿・メンバー動向・盛り上げアクション提案を含むレポート生成 |

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| circle-daily-analyzer | sonnet | circle-daily-report | SQL結果の分析・未対応コメント特定・アクション提案・レポート出力 |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/circle-daily` | Circle日次レポートを生成 | なし |

#### データベース
- Supabase: `cowork`（config.local.md参照）
- DB: `circle_*` テーブル群
- レポート出力先: `cowork_circle/log/`

---

### 3. luma-manager（Luma イベント管理）

#### スキル

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| luma-daily-report | 「Luma日次レポート」「イベント登録状況」 | イベント登録データの分析・サマリ・傾向分析・打ち手提案をSlack DMで報告 |
| luma-create-event | 「イベントを作りたい」「Lumaイベントを新規作成」「ウェビナー付きイベント作成」 | Lumaイベント＋Zoomウェビナーの一括作成（Zoom失敗時フォールバック対応） |
| luma-mail-update | 「メール更新」「イベント紹介を更新」「luma-mail-update」 | Lumaイベント登録確認メールのイベント紹介リストをChrome MCP経由で一括更新 |

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| luma-daily-analyzer | sonnet | luma-daily-report | SQL結果の分析・イベント別評価・打ち手提案・レポート出力・Slack用サマリ作成 |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/luma-daily` | Luma日次レポートを生成してSlackに送信 | なし |
| `/luma-create-event` | Lumaイベント＋Zoomウェビナーを一括作成 | イベント名・日時など（任意） |
| `/luma-mail-update` | Lumaイベント登録確認メールのイベント紹介リストを一括更新 | 更新するイベント紹介リスト（任意） |

#### データベース
- Supabase: `cowork`（config.local.md参照）
- DB: `luma_*` テーブル群
- Slack: Canvas作成 + DM送信（channel_idはconfig.local.md参照）
- レポート出力先: `cowork_luma/log/`

---

### 4. youtube-ideas-manager（YouTube 企画生成）

#### スキル

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| weekly-youtube-ideas | 「YouTube企画」「今週のトレンドから企画」「動画ネタ出し」 | トレンド動画分析 → 企画案10本生成 |

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| youtube-trend-analyzer | sonnet | weekly-youtube-ideas Step1 | SQL実行・トレンドデータ取得・分析サマリ作成 |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/youtube-ideas` | YouTube企画案を週次で生成 | なし |

#### データベース
- Supabase: `youtube_idea_generator`（config.local.md参照）
- DB: `weekly_trending_summary`, `weekly_trending_compact`, `news`, `ideas`
- レポート出先: `cowork_youtube_ideas_optimize/log/`

---

### 5. work-utils（汎用業務ユーティリティ）

#### スキル

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| enquete-read | 「アンケート結果を見せて」「過去のアンケートを検索」 | Supabaseからアンケートサマリを読み込み・検索・一覧表示 |
| enquete-save | 「アンケート結果を保存」「調査データを登録」 | アンケート生データを分析し構造化サマリとしてDB保存 |
| memory-save | 「Supabaseに保存して」「長期メモリに登録」「ナレッジを保存して」 | Supabase長期メモリへの保存 |
| memory-read | 「過去の議論を探して」「長期メモリから探して」「記録を検索」 | Supabase長期メモリの検索・参照 |
| research-save | 「リサーチを保存」「調査結果を保存」 | 会話中のリサーチ・調査結果をDB保存 |
| research-read | 「リサーチを見せて」「過去の調査を検索」「リサーチ一覧」 | 保存済みリサーチの読み込み・検索・一覧表示 |
| growthlog-read | 「グロースログを見せて」「反省・学びの一覧」「学びを検索」 | グロースログの読み込み・検索・復習対象抽出 |
| growthlog-save | 「グロースログを保存」「反省を記録して」「学びを保存」 | 反省・学び・成功体験をDB保存 |
| story-writing | 「ビジネス記事を書いて」「読み物スタイルで」「東洋経済風の文章」 | 東洋経済オンライン・NewsPicks風のビジネス読み物スタイルで文章作成 |
| fact-check-rewrite | 「ファクトチェックして」「事実確認して」「この記事を検証して」 | 記事のファクト抽出→並列検証→story-writing準拠の修正記事をGoogleドキュメント/Wordで出力 |
| line-message | 「LINEメッセージを作って」「LINE配信文を書いて」「関心引き出しメッセージ」 | 行動経済学・心理学に基づくLINE公式アカウントの関心引き出しメッセージを3パターン作成 |
| multi-stage-research | 「調査して」「リサーチして」「レポート作って」 | テーマを受け取り多段階（設計→並列調査→統合→批判チェック→レポート化）でリサーチを実行 |
| ai-buzz-title-generator | 「バズるタイトルを考えて」「YouTube用のタイトル案」「サムネ案」 | AIノウハウ系コンテンツのバズるタイトル・冒頭文・サムネイル案を心理学的フック活用で生成 |
| browser-use | 「ブラウザで○○して」「Webで○○を調べて」「ブラウザ自動化」 | Browser Use 2.0でChrome CDP接続によるブラウザ自動操作（スクレイピング・情報収集・フォーム操作等） |
| zoom-create-webinar | 「Zoomウェビナーを作って」「ウェビナーを作成」 | Supabase Edge Function経由でZoomウェビナーを作成（単独利用・luma-create-eventからの内部呼び出し両対応） |
| slide-excel | 「YouTube企画をExcelにまとめて」「動画構成を表にして」「3列Excelを作って」 | YouTube動画企画を議論・構成検討し、3列構成（タイトル/内容/備考）のExcelをopenpyxlで生成 |

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| enquete-save-analyzer | sonnet | enquete-save | アンケート生データの分析・構造化・ユーザー確認・INSERT実行 |
| research-save-analyzer | sonnet | research-save | 会話内容の分析・構造化・INSERT実行 |
| growthlog-save-analyzer | sonnet | growthlog-save | 反省・学びの分析・構造化・AIコメント生成・INSERT実行 |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/enquete-read` | アンケートサマリの一覧・検索・取得 | アンケート名やキーワード（任意） |
| `/enquete-save` | アンケートデータを分析して構造化保存 | データソースの説明（任意） |
| `/memory-save` | Supabase長期メモリへの保存 | 保存内容（任意） |
| `/memory-read` | Supabase長期メモリの検索・参照 | 検索キーワード（任意） |
| `/research-save` | リサーチ結果を構造化して保存 | 保存対象の補足（任意） |
| `/research-read` | 保存済みリサーチの一覧・検索・取得 | 検索キーワード（任意） |
| `/growthlog-read` | グロースログの一覧・検索・復習対象抽出 | 検索キーワード（任意） |
| `/growthlog-save` | 反省・学び・成功体験をグロースログとして保存 | 保存したい内容（任意） |
| `/line-message` | LINE関心引き出しメッセージを3パターン作成 | 配信目的・ターゲット・訴求内容（任意） |
| `/research` | 多段階リサーチを実行してレポート作成 | 調査テーマ（任意） |
| `/ai-buzz-title-generator` | AIノウハウ系バズタイトル・サムネイル案を生成 | テーマ・プラットフォーム・ターゲット（任意） |
| `/browser-use` | Browser Use 2.0でブラウザ操作タスクを実行 | タスク内容（任意） |
| `/zoom-create-webinar` | Zoomウェビナーを作成 | ウェビナー名・日時など（任意） |
| `/slide-excel` | YouTube企画を3列構成のExcelにまとめる | テーマや企画内容（任意） |

#### データベース
- Supabase: `cowork`（config.local.md参照）
- DB: `enquete_summary`, `research_items`, `memories`, `growth_log_learnings` テーブル

---

## バージョン運用ルール

- バージョンは **アップデートしたプラグインのみ** 個別にバンプする（全プラグイン同期は不要）
- 更新時は以下の2箇所を一致させる：
  - `.claude-plugin/marketplace.json` の該当 `plugins[].version`
  - 該当プラグイン直下の `.claude-plugin/plugin.json` の `version`
- バージョンは `1.0.0` → `1.0.1` のように段階的にアップデートする
- アップデート内容は `UPDATE.md` に日付・プラグイン名・バージョン・変更内容を記録する
