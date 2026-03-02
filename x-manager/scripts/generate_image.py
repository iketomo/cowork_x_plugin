#!/usr/bin/env python3
"""
X投稿用画像生成スクリプト
Gemini (gemini-3.1-flash-image-preview) を使用して、
X投稿の内容に合わせた1:1のイラスト画像を生成する。

使い方:
    python generate_image.py "X投稿の文章テキスト"
    python generate_image.py "X投稿の文章テキスト" --output output.png
    python generate_image.py --file post.txt
    python generate_image.py --file post.txt --output output.png

環境変数:
    GEMINI_API_KEY: Google Gemini APIキー（必須）
"""

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

try:
    from google import genai
    from google.genai import types
except ImportError:
    print("エラー: google-genai パッケージがインストールされていません。")
    print("以下のコマンドでインストールしてください:")
    print("  pip install google-genai")
    sys.exit(1)


# ── 画像スタイル固定プロンプト ──────────────────────────────────
IMAGE_STYLE_PROMPT = """
You are an expert illustrator specializing in Japanese business book illustration style.

## Image Style Requirements (MUST follow strictly)

### Overall Style
- Japanese business book / explainer book "yurui illustration" (loose, friendly illustration) style
- Lines: thin black pen lines with a hand-drawn feel, slightly uneven (digital but hand-drawn looking)
- Coloring: watercolor-style light colors (cream, light blue, light orange, light green), not flat fills but with subtle color variation/texture
- Characters: 2-3 head-tall deformed characters, round faces, simple expressions (dot eyes, line mouth)
- Icons/Objects: simple line drawings + light colors, no shadows, flat design

### Color Palette
- IMPORTANT: Background must be white (#FFFFFF)
- Main colors: black (lines), light orange/yellow (emphasis, heading backgrounds)
- Accent colors: light blue, light green, light pink
- Emphasis: red (× marks, important points), green (✓ marks, OK)

### Layout
- Information arranged in a grid layout (1-4 columns)
- Each cell contains "illustration + short text" as a set
- Headings have yellow/orange band or marker-style backgrounds
- Arrows are hand-drawn style, curved

### Character Design
- Head-to-body ratio: 2-3 heads tall
- Hair: expressed as simple masses
- Clothes: calm colors like blue and gray, simple design
- Expressions: made only with circles and lines (troubled face, smile, thinking, etc.)
- Poses: explanatory gestures (pointing, arms crossed, PC operation, etc.)

### Text in Image
- Font: round gothic style, handwritten feel
- Size: large, prioritize readability
- Placement: short captions beside or below illustrations
- Emphasis: yellow marker-style highlights, bold text
- IMPORTANT: All text in the image MUST be in Japanese

### Elements to AVOID
- Realistic human depictions
- Gradients
- Drop shadows
- Complex backgrounds
- 3D rendering

## Purpose
- Create an explanatory illustration for beginners, friendly and easy to understand
- The image should visually represent the key message of the X (Twitter) post content below
"""


def extract_key_message(post_text: str) -> str:
    """投稿テキストから画像生成用のプロンプトを構築する"""
    prompt = f"""{IMAGE_STYLE_PROMPT}

## X Post Content to Illustrate
\"\"\"
{post_text}
\"\"\"

## Instructions
Based on the X post content above, create a single square (1:1) illustration that:
1. Captures the main message or key concept of the post
2. Uses the Japanese business book illustration style described above
3. Includes 1-3 short Japanese text labels/captions that highlight the key points
4. Is visually engaging and easy to understand at a glance (even as a small thumbnail on X/Twitter)
5. Would make someone stop scrolling and want to read the accompanying post

Generate the illustration now.
"""
    return prompt


def generate_image(post_text: str, output_path: str | None = None) -> str:
    """Gemini 3.1 Flash Image で画像を生成する"""

    # APIキー取得
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("エラー: 環境変数 GEMINI_API_KEY が設定されていません。")
        print("以下のように設定してください:")
        print('  export GEMINI_API_KEY="your-api-key-here"')
        sys.exit(1)

    # 出力パス決定
    if output_path is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_dir = Path(__file__).parent / "output"
        output_dir.mkdir(exist_ok=True)
        output_path = str(output_dir / f"x_post_image_{timestamp}.png")

    # クライアント初期化
    client = genai.Client(api_key=api_key)

    # プロンプト構築
    prompt = extract_key_message(post_text)

    print("🎨 Gemini 3.1 Flash Image で画像を生成中...")
    print(f"   モデル: gemini-3.1-flash-image-preview")
    print(f"   サイズ: 1:1")

    try:
        response = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE", "TEXT"],
                image_config=types.ImageConfig(
                    aspect_ratio="1:1",
                ),
            ),
        )
    except Exception as e:
        print(f"エラー: 画像生成に失敗しました: {e}")
        sys.exit(1)

    # レスポンスから画像を抽出・保存
    image_saved = False
    for part in response.candidates[0].content.parts:
        if part.inline_data:
            with open(output_path, "wb") as f:
                f.write(part.inline_data.data)
            image_saved = True
            print(f"✅ 画像を保存しました: {output_path}")
        if part.text:
            print(f"📝 モデルからのメッセージ: {part.text}")

    if not image_saved:
        finish_reason = response.candidates[0].finish_reason
        print(f"エラー: 画像が生成されませんでした。finish_reason: {finish_reason}")
        sys.exit(1)

    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="X投稿用画像生成（Gemini 3.1 Flash Image）"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("post_text", nargs="?", help="X投稿の文章テキスト")
    group.add_argument("--file", "-f", help="投稿文章が書かれたテキストファイルのパス")
    parser.add_argument("--output", "-o", help="出力画像ファイルパス（省略時は自動生成）")

    args = parser.parse_args()

    # テキスト取得
    if args.file:
        file_path = Path(args.file)
        if not file_path.exists():
            print(f"エラー: ファイルが見つかりません: {args.file}")
            sys.exit(1)
        post_text = file_path.read_text(encoding="utf-8").strip()
    else:
        post_text = args.post_text

    if not post_text:
        print("エラー: 投稿テキストが空です。")
        sys.exit(1)

    print("=" * 60)
    print("🐦 X投稿用画像生成")
    print("=" * 60)
    print(f"投稿テキスト（先頭100文字）: {post_text[:100]}...")
    print("-" * 60)

    output = generate_image(post_text, args.output)
    print("-" * 60)
    print(f"🎉 完了！画像: {output}")


if __name__ == "__main__":
    main()
