---
name: luma-mail-update
description: >
  Lumaイベントの登録確認メールのイベント紹介リストを一括更新するスキル。
  「メール更新」「イベント紹介を更新」「luma-mail-update」などのリクエストで発動。
  Chrome MCPを使ってLumaダッシュボード上のメール設定を自動操作する。
---

# Lumaイベント メール設定 一括更新

## 前提条件
- Chrome MCPが接続済み（Lumaにログイン状態のブラウザ）
- Supabase `luma_events` テーブルにイベントデータがある（DBにないイベントはスラッグからapi_idを取得）
- 手順書: `mail_update.md` を必ず参照すること

## 手順

### Step 1: 更新内容のヒアリング

ユーザーに以下を確認する（未指定の項目のみ質問）:

1. **新しいイベント紹介リスト** (必須) - 掲載するイベント一覧（タイトル + LumaスラッグURL）
2. **対象イベント** (任意、デフォルト: 全未終了イベント) - 特定イベントのみ更新する場合

紹介リストのURL形式:
- `https://luma.com/{slug}?utm_source=lumamail`（`utm_source=lumamail` 必須）

### Step 2: 対象イベントの取得

Supabase MCPで未終了イベントを取得:

```sql
SELECT api_id, name, start_at FROM luma_events
WHERE start_at >= CURRENT_DATE ORDER BY start_at
```

DBにないイベント（スラッグのみ分かる場合）:
1. `https://lu.ma/{slug}` に Chrome MCP でナビゲート
2. `__NEXT_DATA__` から `api_id` を取得:
```javascript
const data = JSON.parse(document.getElementById('__NEXT_DATA__').textContent);
data?.props?.pageProps?.event?.api_id
```

### Step 3: 各イベントのメール設定を更新

各イベントについて以下を繰り返す:

#### 3a. メール設定エディタを開く

```
1. Chrome MCP で navigate: https://luma.com/event/manage/{api_id}/registration
2. find: 「メール設定」ボタン → click
3. wait 2秒
```

#### 3b. 現在のメール内容を確認

```javascript
const editor = document.querySelector('[contenteditable="true"][role="textbox"]');
editor.innerText  // innerHTML はChrome拡張にブロックされるため使わない
```

#### 3c-1. 既存メール設定がある場合（差替）

▼で始まる `<p>` 要素を特定し、新しいイベントリストに差し替える:

```javascript
const editor = document.querySelector('[contenteditable="true"][role="textbox"]');
const children = Array.from(editor.children);

// ▼で始まる要素のインデックスを収集
const oldIndices = [];
children.forEach((el, i) => {
  if (el.innerText && el.innerText.trim().startsWith('▼')) {
    oldIndices.push(i);
  }
});

const firstOld = children[oldIndices[0]];

// 新しいイベントを挿入
const events = [
  { title: '▼...', url: 'https://luma.com/...?utm_source=lumamail' },
  // ... 全イベント
];

const newElements = events.map(ev => {
  const p = document.createElement('p');
  const textNode = document.createTextNode(ev.title + '\n');
  const link = document.createElement('a');
  link.href = ev.url;
  link.textContent = ev.url;
  p.appendChild(textNode);
  p.appendChild(link);
  return p;
});

for (const el of newElements) {
  editor.insertBefore(el, firstOld);
}

for (const idx of oldIndices.reverse()) {
  children[idx].remove();
}

editor.dispatchEvent(new Event('input', { bubbles: true }));
```

#### 3c-2. メール設定が空の場合（新規作成）

テンプレートに従いフル構成を作成する:

```javascript
const editor = document.querySelector('[contenteditable="true"][role="textbox"]');
editor.innerHTML = '';

const parts = [
  { text: '応募有難うございます！' },
  { text: '' },
  { text: '2時間で「{イベント内容に合った表現}」という実感・自信が持てるようなイベントにしますので、ぜひお楽しみに！' },
  { text: '' },
  { text: '他にも多数イベントをやっていきますので、ぜひご検討くださいませ！' },
  { text: '' },
  // ... イベント紹介リスト（titleとurlのペア）
  { text: '' },
  { text: 'また領収書は以下より発行いただけます。\nLumaログイン → 右上プロフィールアイコン → 設定 → 支払い → 「Download Receipt」' }
];

parts.forEach(part => {
  const p = document.createElement('p');
  if (part.url) {
    p.appendChild(document.createTextNode(part.title + '\n'));
    const link = document.createElement('a');
    link.href = part.url;
    link.textContent = part.url;
    p.appendChild(link);
  } else {
    p.textContent = part.text || '\u00A0';
  }
  editor.appendChild(p);
});

editor.dispatchEvent(new Event('input', { bubbles: true }));
```

**挨拶文（パート1）のカスタマイズ:**
- イベント名・内容に合わせて「{イベント内容に合った表現}」部分を変更
- 例: Excelイベント → 「Excel自動化、自分でもできる」
- 例: Claude Codeイベント → 「Claude Codeの自動化の仕組み、自分でも理解できる！」

#### 3d. 保存

```
find: 「メールアドレスを更新」ボタン → click
wait 2秒
```

**注意:** 保存ボタンのラベルは「メールアドレスを更新」であり「保存」ではない。

### Step 4: 結果報告

更新結果をテーブル形式で報告:

```
| イベント | 日付 | 状態 |
|---------|------|------|
| イベント名 | MM/DD | 更新済み / 新規作成 / 既に最新 / エラー |
```

### Step 5: mail_update.md の更新

イベント紹介リストが変わった場合、`mail_update.md` のパート2（現在の紹介リスト）を更新し、更新日を記載する。

## 注意事項
- `editor.innerHTML` はChrome拡張にブロックされる場合あり → `editor.innerText` で内容確認
- Lumaダッシュボードはスティッキーヘッダーが大きい → `find` でボタンを探す（スクロールより確実）
- DBにないイベントは `lu.ma/{slug}` → `__NEXT_DATA__` で api_id を取得
- URLには必ず `?utm_source=lumamail` を付与
