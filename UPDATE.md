# プラグインアップデート履歴

プラグインの変更内容をバージョンごとに記録する。

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
