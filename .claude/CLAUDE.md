# Cowork Plugin 開発ガイドライン

## プラグイン作成時の必須参照ドキュメント

プラグインの新規作成・修正を行う際は、**必ず最初に** 以下のガイドを読み込んでから作業を開始すること：

```
.claude/plugin-creation-guide.md
```

このガイドには以下が定義されている：
- フォルダ構成ルール（marketplace.json と plugin.json の配置）
- JSON マニフェストの仕様とテンプレート
- SKILL.md / Agent / Command の作成テンプレート
- 機密情報の管理方法（config.example.md / config.local.md パターン）
- コンテキスト節約アーキテクチャ（サブエージェント委譲の設計方針）
- バージョン管理ルール（全プラグインのバージョン同期）
- セキュリティチェックリスト

## 作業フロー

1. `.claude/plugin-creation-guide.md` を Read ツールで読み込む
2. ガイドの「Phase 1〜8」に沿って作業を進める
3. 既存プラグイン（x-manager 等）を実装パターンのリファレンスとして参照する
4. 完了後、`cowork_plugin/CLAUDE.md` のプラグイン一覧を更新する

## 重要ルール

- **コンテキスト節約**: 重い処理はサブエージェントに委譲する。メインエージェントは最小限の処理のみ行う
- **バージョン同期**: marketplace.json と全 plugin.json のバージョンは常に一致させる
- **機密情報**: config.local.md に集約し、gitignore 対象とする。公開ファイルに機密情報を含めない
- **命名規則**: プラグイン名・スキル名・コマンド名はすべて kebab-case
- **データベース**: Supabase を使用し、テーブル名は `{plugin}_*` プレフィックスとする
