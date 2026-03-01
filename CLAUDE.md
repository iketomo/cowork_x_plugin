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
│   ├── skills/                            # 4スキル
│   ├── agents/                            # 4サブエージェント
│   ├── commands/                          # 5コマンド
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
| x-post | 「Xに投稿して」「ツイートして」 | Edge Function経由でXに投稿 |
| x-writing | 「X投稿を書いて」「ツイート案」 | 投稿文作成 |

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| x-daily-analyzer | sonnet | x-daily-report | 分類・分析・ニュース検索・DB保存・レポート出力 |
| x-trend-data-collector | sonnet | x-trend-report Step1 | SQL実行・データ整形 |
| x-trend-news-researcher | sonnet | x-trend-report Step2 | バズ投稿の背景調査（並列5件） |
| x-trend-analyzer | sonnet | x-trend-report Step3 | 総合分析・DB保存・レポート出力 |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/x-daily` | 日次パフォーマンスレポートを生成 | なし |
| `/x-trend` | AI領域トレンド分析レポートを生成 | なし |
| `/x-write` | X投稿の文章を作成 | テーマやニュースURL（任意） |
| `/x-post` | Xに投稿を実行 | 投稿テキスト（任意） |
| `/x-image` | 投稿用画像を生成 | 投稿テキスト or ファイルパス（任意） |

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

#### サブエージェント

| エージェント | モデル | 呼び出し元 | 役割 |
|-------------|--------|-----------|------|
| luma-daily-analyzer | sonnet | luma-daily-report | SQL結果の分析・イベント別評価・打ち手提案・レポート出力・Slack用サマリ作成 |

#### コマンド

| コマンド | 説明 | 引数 |
|---------|------|------|
| `/luma-daily` | Luma日次レポートを生成してSlackに送信 | なし |

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
- レポート出力先: `cowork_youtube_ideas_optimize/log/`
