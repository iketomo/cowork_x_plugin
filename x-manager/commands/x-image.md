---
description: X投稿用の画像をGemini 3.1 Flash Imageで生成する
argument-hint: [投稿テキスト or テキストファイルパス]
allowed-tools: ["Bash", "Read", "Write"]
---

# X投稿用画像生成

scripts/generate_image.py を使って、X投稿用の画像を生成してください。

## 前提条件
- 環境変数 `GEMINI_API_KEY` が設定済みであること
- `pip install google-genai` が実行済みであること

## 実行手順

1. $ARGUMENTS にテキストが指定されている場合はそれを使用
2. テキストが指定されていない場合は、直前の会話で作成した投稿文を使用
3. 以下のコマンドで画像を生成：

```bash
python /mnt/c/Users/tomoh/Dropbox/Cursor/cowork/cowork_x_plugin/x-manager/scripts/generate_image.py "投稿テキスト"
```

4. 生成された画像のパスをユーザーに報告

## 画像スタイル（固定）
- 日本のビジネス書風「ゆるいイラスト」
- 水彩風の淡い色、手描き風の線
- 1:1（正方形）
- テキストは日本語
