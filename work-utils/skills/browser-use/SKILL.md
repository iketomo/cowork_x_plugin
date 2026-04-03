---
name: browser-use
description: >
  Browser Use 2.0 (bu-2-0) を使ってブラウザ操作タスクを実行するスキル。
  Webスクレイピング、情報収集、フォーム操作、サイト監視など、
  ブラウザ上のあらゆる操作を自然言語の指示で自動化する。
  「ブラウザで○○して」「Webで○○を調べて」「サイトから○○を取得して」
  「browser-use」「ブラウザ自動化」などのリクエストで発動。
  Chrome CDP接続によりログイン済みセッションの再利用が可能。
---

# browser-use — ブラウザ自動操作スキル

Browser Use 2.0 (bu-2-0 モデル) を使い、Chromeブラウザを自動操作してタスクを実行する。

## 前提条件

- 作業ディレクトリ: `C:/Users/tomoh/Dropbox/Cursor/cowork/browseruse2`
- Python仮想環境: `browseruse2/.venv`（browser-use, openpyxl インストール済み）
- API Key: `.env` に `BROWSER_USE_API_KEY` を設定済み
- Chrome: `C:\Program Files\Google\Chrome\Application\chrome.exe`

## 実行フロー

### Step 1: Chrome をリモートデバッグモードで起動

ログイン済みセッションを使うため、Chrome を CDP モードで起動する。
**重要**: 既にChromeが起動中の場合は先に閉じる必要がある。

```bash
# 既存Chromeを終了
taskkill //F //IM chrome.exe 2>/dev/null; sleep 2

# プロファイルコピー用ディレクトリ（初回のみCookieをコピー）
CHROME_SRC="C:/Users/tomoh/AppData/Local/Google/Chrome/User Data"
CHROME_DST="C:/Users/tomoh/Dropbox/Cursor/cowork/browseruse2/chrome_debug_profile"

# 初回のみ: 必要ファイルをコピー（ログイン情報含む）
if [ ! -d "$CHROME_DST" ]; then
  mkdir -p "$CHROME_DST/Default/Network"
  for f in "Local State" "Default/Login Data" "Default/Preferences" "Default/Secure Preferences" "Default/Web Data" "Default/Network/Cookies"; do
    src="$CHROME_SRC/$f"
    dst="$CHROME_DST/$f"
    [ -f "$src" ] && mkdir -p "$(dirname "$dst")" && cp "$src" "$dst"
  done
fi

# Chrome起動（リモートデバッグ有効）
"C:/Program Files/Google/Chrome/Application/chrome.exe" \
  --remote-debugging-port=9222 \
  --user-data-dir="$CHROME_DST" \
  --no-first-run \
  --no-default-browser-check \
  --disable-extensions &

sleep 5

# CDP接続を確認
curl -sk http://127.0.0.1:9222/json/version
```

**ログインが必要な場合**: Chrome が開いたらユーザーに手動ログインを依頼し、完了を待ってから Step 2 へ進む。

### Step 2: browser_use_runner.py でタスク実行

```bash
cd "C:/Users/tomoh/Dropbox/Cursor/cowork/browseruse2"
source .venv/Scripts/activate

# タスク内容を引数で指定
python browser_use_runner.py --task "ここにタスク内容を記述"

# 出力形式を指定する場合（json / excel / text）
python browser_use_runner.py --task "..." --output json
python browser_use_runner.py --task "..." --output excel --filename result.xlsx

# 結果をファイルに保存
python browser_use_runner.py --task "..." --output json > result.json
```

### Step 3: 結果を取得・加工

`browser_use_runner.py` は以下を返す:
- **stdout**: タスク結果（テキストまたはJSON）
- **exit code 0**: 成功 / **1**: 失敗
- **--output excel**: 指定ファイル名でExcelを保存

## タスクの書き方（ユーザー指示 → プロンプト変換のコツ）

ユーザーの依頼をそのままタスクに渡すのではなく、以下の構造で組み立てる:

```
1. 具体的な手順（URLへのアクセス、検索クエリ、クリック対象など）
2. 収集する情報の項目リスト
3. 出力形式（JSON形式のスキーマを明示）
```

### タスク例

**Xのバズ投稿収集**:
```
X.comの検索機能で「AI min_faves:1000 lang:ja」を検索し、
AI・Claude Code関連のバズっている記事ポストを3つ見つけて、
各ポストのアカウント名、本文、いいね数、リポスト数、閲覧数、ポストURLを
JSON配列で返してください。
```

**Amazon最安値調査**:
```
Amazon.co.jp で「ワイヤレスイヤホン ノイズキャンセリング」を検索し、
価格が安い順に並べ替え、上位3商品の商品名、価格、レビュー評価、URLを
JSON配列で返してください。
```

**Webサイト情報取得**:
```
https://example.com にアクセスし、
ページのタイトル、メインコンテンツの見出し一覧、最新ニュース3件を
JSON形式で返してください。
```

## 注意事項

- **クレジット消費**: bu-2-0 は1タスクあたり数円〜数十円のAPI費用が発生する
- **ログイン必須サイト**: 事前に Chrome で手動ログインし、ユーザーに確認を取る
- **プロファイルコピーの注意**: Chrome の暗号化Cookieは別ディレクトリでは復号できないため、CDPモードで起動した Chrome に手動ログインする必要がある
- **タイムアウト**: 複雑なタスクは最大10分（600秒）で打ち切られる
- **CDP接続確認**: `curl -sk http://127.0.0.1:9222/json/version` で接続状態を確認可能
