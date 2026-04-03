---
name: slide-excel
description: "いけともch（YouTube）の動画企画を3列構成のExcelにまとめるスキル。テーマについて議論・構成を詰めた後、「タイトル / 内容（具体的に） / 備考・分かりやすい説明の補足」の3列Excelを生成する。「YouTube企画をExcelにまとめて」「動画構成を表にして」「3列Excelを作って」「企画をExcelに落とし込んで」「構成表を作って」などのリクエストで発動。企画の議論・壁打ちから最終Excelアウトプットまでを一気通貫で行う。"
---

# YouTube企画 3列Excel生成スキル

## 概要
いけともch向けのYouTube動画企画を、議論・構成検討を経て、最終的に3列構成のExcelファイルとして出力するスキル。

---

## 作業フロー

### Step 1: テーマフォルダの確認・作成
- `youtube_plan/` 配下に `{YYYYMMDD}_{テーマ名}/` フォルダを作成する
- 既にフォルダが存在する場合はそのまま使用する
- フォルダ内に `CLAUDE.md` を作成し、検討経緯を記録する

### Step 2: 企画の議論・構成検討
- ユーザーと対話しながら動画構成を詰める
- 必要に応じてSupabase（youtube_idea_generator）からいけともchの再生データを参照し、視聴者傾向を分析する
  - project_id: `lkmmjdgaqwztqykxxlaq`
  - channel UUID: `f16734a7-8174-41c4-8931-f882e3c21bc8`
- 検討経緯はテーマフォルダの `CLAUDE.md` に随時記録する

### Step 3: 3列Excelの生成
- 下記「Excel仕様」に従い、openpyxlで生成する
- 生成後、必要に応じて `scripts/recalc.py` で数式を再計算する

### Step 4: 関連ファイルの生成（任意）
- デモ用のテンプレートファイル（Excel, PPTX等）が必要な場合は同梱する
- 生成ファイルの一覧を `CLAUDE.md` に記録する

---

## Excel仕様

### 列構成（必須）

| 列 | 内容 | 幅目安 |
|---|---|---|
| A列 | **タイトル** — パートやセクションの見出し | 28 |
| B列 | **内容（具体的に）** — 話す内容・台本メモを具体的に記述 | 60 |
| C列 | **備考・分かりやすい説明の補足** — たとえ話、視聴者への伝え方のコツ、注意点など | 50 |

### デザイン・フォーマット規約

#### カラーパレット
```python
NAVY = "1E2761"        # ヘッダー背景、セクション文字色
ACCENT = "4A4FC4"      # セクション背景、アクセント
WHITE = "FFFFFF"        # ヘッダー文字色
LIGHT_BG = "F5F7FA"    # 交互行の背景色
SECTION_BG = "E8EAFF"  # セクション見出し行の背景色
DARK_TEXT = "1E2761"    # タイトル列の文字色
BODY_TEXT = "333333"    # 内容列の文字色
NOTE_TEXT = "555555"    # 備考列の文字色
```

#### ヘッダー行（1行目）
- フォント: Arial, 11pt, Bold, 白文字
- 背景: NAVY（`1E2761`）
- 配置: 中央揃え、上下中央、折り返し有効
- 行高: 28px
- フリーズペイン: A2（ヘッダー固定）

#### セクション見出し行
- 3列を結合（merge_cells）
- フォント: Arial, 11pt, Bold, DARK_TEXT
- 背景: SECTION_BG（`E8EAFF`）
- 行高: 26px
- 形式: `パート{N}｜{セクションタイトル}`

#### データ行
- **A列（タイトル）**: Arial, 10pt, Bold, DARK_TEXT
- **B列（内容）**: Arial, 10pt, BODY_TEXT
- **C列（備考）**: Arial, 10pt, NOTE_TEXT
- 共通: 上揃え、折り返し有効
- 行高: 70px（内容量に応じて85pxまで拡大可）
- 罫線: 下辺のみ thin、色 `D0D5DD`
- 交互行: 偶数行に LIGHT_BG（`F5F7FA`）を適用

### コード構造テンプレート

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = Workbook()
ws = wb.active
ws.title = "動画構成（全体）"

# --- 定数定義 ---
NAVY = "1E2761"
ACCENT = "4A4FC4"
WHITE = "FFFFFF"
LIGHT_BG = "F5F7FA"
SECTION_BG = "E8EAFF"
DARK_TEXT = "1E2761"
BODY_TEXT = "333333"
NOTE_TEXT = "555555"

hdr_font = Font(name="Arial", bold=True, color=WHITE, size=11)
hdr_fill = PatternFill("solid", fgColor=NAVY)
sec_font = Font(name="Arial", bold=True, color=DARK_TEXT, size=11)
sec_fill = PatternFill("solid", fgColor=SECTION_BG)
title_f = Font(name="Arial", bold=True, color=DARK_TEXT, size=10)
body_f = Font(name="Arial", color=BODY_TEXT, size=10)
note_f = Font(name="Arial", color=NOTE_TEXT, size=10)
border_b = Border(bottom=Side(style="thin", color="D0D5DD"))
alt_fill = PatternFill("solid", fgColor=LIGHT_BG)

# --- ヘッダー ---
headers = ["タイトル", "内容（具体的に）", "備考・分かりやすい説明の補足"]
widths = [28, 60, 50]
for ci, (h, w) in enumerate(zip(headers, widths), 1):
    c = ws.cell(row=1, column=ci, value=h)
    c.font = hdr_font
    c.fill = hdr_fill
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.column_dimensions[get_column_letter(ci)].width = w
ws.row_dimensions[1].height = 28
ws.freeze_panes = "A2"

# --- ヘルパー関数 ---
row = 2

def add_section(title):
    """セクション見出し行を追加"""
    global row
    ws.merge_cells(start_row=row, start_column=1, end_row=row, end_column=3)
    c = ws.cell(row=row, column=1, value=title)
    c.font = sec_font
    c.fill = sec_fill
    c.alignment = Alignment(vertical="center")
    ws.row_dimensions[row].height = 26
    row += 1

def add_row(t, content, note, height=70):
    """データ行を追加"""
    global row
    fonts = [title_f, body_f, note_f]
    for ci, (val, ft) in enumerate(zip([t, content, note], fonts), 1):
        c = ws.cell(row=row, column=ci, value=val)
        c.font = ft
        c.alignment = Alignment(vertical="top", wrap_text=True)
        c.border = border_b
        if row % 2 == 0:
            c.fill = alt_fill
    ws.row_dimensions[row].height = height
    row += 1

# --- データ投入 ---
# add_section("パート1｜導入")
# add_row("タイトル", "内容...", "備考...")

# --- 保存 ---
# wb.save("output.xlsx")
```

---

## コンテンツ作成ルール

### セクション（パート）の粒度
- 動画の大きな流れに沿って、パート単位でセクション見出しを入れる
- 一般的には3〜8パート程度
- 形式: `パート{N}｜{概要}`（例: `パート1｜導入 — Claude Codeとは何か`）

### タイトル列の書き方
- 短く端的に。そのセクション内で話すトピックの見出し
- 1行〜2行で収まる長さ（改行は`\n`で明示可）
- 例: `Claude Codeの全体像を一言で`、`切り分けの2つの軸`

### 内容列の書き方
- **具体的に**書く。台本レベルの詳細さを目指す
- 箇条書き（`\n`区切り）と文章を組み合わせてOK
- 数字・固有名詞・具体例を積極的に含める
- 「何を」「なぜ」「どうやって」が伝わる粒度

### 備考列の書き方
- 視聴者への伝え方のコツ、たとえ話、補足情報を記載
- 【タグ】で分類すると見やすい
  - `【たとえ話】` — アナロジーで伝える場合
  - `【重要概念】` — 特に強調すべきポイント
  - `【デモ注記】` — デモ映像で補足すべき箇所
  - `【視聴者心理】` — 離脱防止・興味喚起のテクニック
- 動画撮影・編集時の参考情報としても機能させる

---

## いけともchの視聴者傾向（参考情報）

企画立案時に以下の傾向を踏まえること：

### よく反応するキーワード・切り口
- 「非エンジニアでもできる」「ビジネスパーソン向け」
- 「実務で使える」「実践的」
- 「N選」「決定版」「神機能」（リスト形式）
- Claude / ChatGPT / Gemini 等の具体的なツール名

### 過去の高再生動画パターン（2026年1月〜）
- Claude神機能19選: 11.7万再生（特定ツール × 網羅的紹介）
- NotebookLM活用術12選: 6.6万再生（ツール × 実践ユースケース）
- Claude Coworkの衝撃: 4.4万再生（新機能 × 非エンジニア訴求）
- Gemini神機能28選: 3.8万再生（網羅的 × 無料〜有料カバー）
- AI資料作成のやり方: 3.3万再生（実務直結の具体テーマ）

### 企画設計への示唆
- 「非エンジニアでもできる」は必ず入れる
- 具体的なビジネスシーン（資料作成、レポート、メール等）を絡める
- デモや実演パートを含めると反応が良い

---

## ファイル命名規約

| ファイル | 命名パターン | 例 |
|---|---|---|
| 最終Excel | `{テーマ名}_full.xlsx` | `claude_code_automation_full.xlsx` |
| テーマCLAUDE.md | `CLAUDE.md`（フォルダ内に配置） | — |
| デモ用テンプレート | 内容に応じて自由 | `news_digest_template.xlsx` |

---

## チェックリスト（生成前の最終確認）

- [ ] セクション見出しが動画の流れに沿っているか
- [ ] 内容列が「台本レベル」の具体性を持っているか
- [ ] 備考列にたとえ話・視聴者心理への配慮が含まれているか
- [ ] カラーパレット・フォント・罫線が規約通りか
- [ ] テーマフォルダの CLAUDE.md に検討経緯が記録されているか
- [ ] ファイル名が命名規約に従っているか
