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
│   ├── commands/                          # 1コマンド
│   └── log/
├── luma-manager/                          # プラグイン③ Luma イベント管理
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 1スキル
│   ├── commands/                          # 1コマンド
│   └── log/
├── youtube-ideas-manager/                 # プラグイン④ YouTube 企画生成
│   ├── .claude-plugin/plugin.json
│   ├── skills/                            # 1スキル
│   ├── commands/                          # 1コマンド
│   └── log/
├── CLAUDE.md
├── SETUP.md
├── PROGRESS.md
└── .gitignore
```

## プラグイン一覧

### 1. x-manager（X / Twitter 管理）

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| x-daily-report | 「X日次レポート」「パフォーマンス分析」 | 自分の投稿のWinner/Watch分類・伸び分析・投稿提案 |
| x-trend-report | 「Xトレンドレポート」「AI界隈のバズ」 | AI領域バズ投稿のトレンド分析・投稿戦略提案 |
| x-post | 「Xに投稿して」「ツイートして」 | Edge Function経由でXに投稿 |
| x-writing | 「X投稿を書いて」「ツイート案」 | 投稿文作成 |

| コマンド | 説明 |
|---------|------|
| `/x-daily` | 日次パフォーマンスレポートを生成 |
| `/x-trend` | AI領域トレンド分析レポートを生成 |
| `/x-write` | X投稿の文章を作成 |
| `/x-post` | Xに投稿を実行 |
| `/x-image` | 投稿用画像を生成 |

- Supabase: `cowork`（config.local.md参照）
- DB: `x_*`, `x_trend_*` テーブル群

### 2. circle-manager（Circle コミュニティ管理）

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| circle-daily-report | 「Circle日次レポート」「アイザックのレポート」「未対応コメント確認」 | 未対応コメント・新規投稿・メンバー動向・盛り上げアクション提案を含むレポート生成 |

| コマンド | 説明 |
|---------|------|
| `/circle-daily` | Circle日次レポートを生成 |

- Supabase: `cowork`（project_id: `iltymrnkqchixvtpvewm`）
- DB: `circle_*` テーブル群

### 3. luma-manager（Luma イベント管理）

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| luma-daily-report | 「Luma日次レポート」「イベント登録状況」 | イベント登録データの分析・サマリ・傾向分析・打ち手提案をSlack DMで報告 |

| コマンド | 説明 |
|---------|------|
| `/luma-daily` | Luma日次レポートを生成してSlackに送信 |

- Supabase: `cowork`（project_id: `iltymrnkqchixvtpvewm`）
- DB: `luma_*` テーブル群
- Slack: Canvas作成 + DM送信

### 4. youtube-ideas-manager（YouTube 企画生成）

| スキル | トリガー例 | 処理概要 |
|--------|-----------|---------|
| weekly-youtube-ideas | 「YouTube企画」「今週のトレンドから企画」「動画ネタ出し」 | トレンド動画分析 → 企画案10本生成 |

| コマンド | 説明 |
|---------|------|
| `/youtube-ideas` | YouTube企画案を週次で生成 |

- Supabase: `youtube_idea_generator`（project_id: `lkmmjdgaqwztqykxxlaq`）
- DB: `weekly_trending_summary`, `weekly_trending_compact`, `news`, `ideas`
