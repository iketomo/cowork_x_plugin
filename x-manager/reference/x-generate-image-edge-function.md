# Supabase Edge Function `x-generate-image` 実装・デプロイ指示書

Cowork / Claude から Supabase の Edge Function に **直接アップロード & デプロイ** してもらうための作業手順です。

## 1. 目的

- X投稿用の画像を **Gemini 3.1 Flash Image** で生成し、Supabase Storage に保存して **公開URL** を返す Edge Function を用意する。
- ClaudeVM 側（`/x-image` コマンド）は、この Edge Function を `POST` で叩くだけで画像URLを取得できるようにする。

---

## 2. 事前情報（このリポジトリ側）

- Supabase プロジェクト情報は `x-manager/config.local.md` を参照。
  - Project ID
  - Anon Key
  - Edge Function Base URL (`https://<project-id>.supabase.co/functions/v1`)
- `x-image` コマンド仕様は `x-manager/commands/x-image.md` に記載済み。

---

## 3. Supabase 側でやること（高レベル）

1. Supabase プロジェクトのリポジトリに Edge Function ディレクトリを用意:
   - `supabase/functions/x-generate-image/index.ts`
2. 下記「コード全文」を `index.ts` に貼り付ける。
3. Supabase の Secrets に以下を設定:
   - `GEMINI_API_KEY`（Google AI Studio の Gemini APIキー）
   - `SUPABASE_SERVICE_ROLE_KEY`（Service Role Key）
   - （任意）`X_IMAGE_BUCKET`（デフォルト `x-images`）
4. Storage に画像用の public バケットを作成:
   - バケット名: `x-images`（または `X_IMAGE_BUCKET` と一致させる）
   - 公開設定: public
5. Supabase CLI で Edge Function をデプロイ:
   - `supabase functions deploy x-generate-image`
6. 動作確認用のテストリクエストを1回実行し、`image_url` が返ってくることを確認。

---

## 4. Edge Function コード全文（`supabase/functions/x-generate-image/index.ts`）

```ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const IMAGE_BUCKET = Deno.env.get("X_IMAGE_BUCKET") ?? "x-images";

if (!GEMINI_API_KEY) {
  console.warn("GEMINI_API_KEY is not set. Image generation will fail.");
}
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.warn(
    "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set. Storage upload will fail.",
  );
}

const supabase =
  SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
    ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    : null;

const IMAGE_STYLE_PROMPT = `
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
`;

function buildPrompt(postText: string): string {
  return `${IMAGE_STYLE_PROMPT}

## X Post Content to Illustrate
\"\"\"
${postText}
\"\"\"

## Instructions
Based on the X post content above, create a single square (1:1) illustration that:
1. Captures the main message or key concept of the post
2. Uses the Japanese business book illustration style described above
3. Includes 1-3 short Japanese text labels/captions that highlight the key points
4. Is visually engaging and easy to understand at a glance (even as a small thumbnail on X/Twitter)
5. Would make someone stop scrolling and want to read the accompanying post

Generate the illustration now.
`;
}

async function callGeminiImageAPI(prompt: string): Promise<{
  mimeType: string;
  imageBytes: Uint8Array;
}> {
  if (!GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not configured");
  }

  const endpoint =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent";

  const res = await fetch(`${endpoint}?key=${GEMINI_API_KEY}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        responseModalities: ["IMAGE", "TEXT"],
        imageConfig: {
          aspectRatio: "1:1",
        },
      },
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(
      `Gemini API error: ${res.status} ${res.statusText} - ${text}`,
    );
  }

  const json = await res.json();

  const candidates = json.candidates ?? [];
  if (!candidates.length) {
    throw new Error("Gemini API response has no candidates");
  }

  const parts = candidates[0].content?.parts ?? [];
  for (const part of parts) {
    const inline = part.inlineData ?? part.inline_data;
    if (inline?.data) {
      const mimeType = inline.mimeType ?? inline.mime_type ?? "image/png";
      const b64 = inline.data as string;
      const binary = Uint8Array.from(
        atob(b64),
        (c) => c.charCodeAt(0),
      );
      return { mimeType, imageBytes: binary };
    }
  }

  throw new Error("Gemini API response has no inline image data");
}

async function uploadToStorage(
  bytes: Uint8Array,
  mimeType: string,
  idSuffix?: string,
): Promise<string> {
  if (!supabase) {
    throw new Error("Supabase client is not initialized");
  }

  const now = new Date();
  const ts = now.toISOString().replace(/[-:T.Z]/g, "").slice(0, 14);
  const safeSuffix = idSuffix?.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 32);
  const filenameBase = safeSuffix
    ? `x_post_image_${ts}_${safeSuffix}`
    : `x_post_image_${ts}`;
  const path = `${now.getUTCFullYear()}/${(
    now.getUTCMonth() + 1
  ).toString().padStart(2, "0")}/${filenameBase}.png`;

  const { error } = await supabase.storage.from(IMAGE_BUCKET).upload(
    path,
    bytes,
    {
      contentType: mimeType || "image/png",
      upsert: false,
    },
  );

  if (error) {
    throw new Error(`Failed to upload image to storage: ${error.message}`);
  }

  const baseUrl = SUPABASE_URL?.replace(/\/+$/, "") ?? "";
  const publicUrl =
    `${baseUrl}/storage/v1/object/public/${IMAGE_BUCKET}/${path}`;

  return publicUrl;
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        ...corsHeaders,
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Method Not Allowed" }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }

  try {
    const body = await req.json().catch(() => ({}));
    const text = (body?.text ?? "").toString().trim();
    const idSuffix = body?.id_suffix
      ? String(body.id_suffix)
      : undefined;

    if (!text) {
      return new Response(
        JSON.stringify({ success: false, error: "`text` is required" }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const prompt = buildPrompt(text);

    const { mimeType, imageBytes } = await callGeminiImageAPI(prompt);
    const imageUrl = await uploadToStorage(imageBytes, mimeType, idSuffix);

    return new Response(
      JSON.stringify({
        success: true,
        image_url: imageUrl,
        mime_type: mimeType,
        prompt_preview: prompt.slice(0, 300),
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (e) {
    console.error("x-generate-image error:", e);
    return new Response(
      JSON.stringify({
        success: false,
        error: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});
```

---

## 5. 呼び出し仕様（ClaudeVM / `/x-image` 側）

- エンドポイント:
  - `POST {Edge Function Base URL}/x-generate-image`
    - 例: `https://<project-id>.supabase.co/functions/v1/x-generate-image`
- ヘッダー:
  - `Authorization: Bearer {Supabase Anon Key}`
  - `Content-Type: application/json`
- リクエストボディ:
  - `{"text": "投稿テキスト"}`（必要に応じて `id_suffix` を追加）
- レスポンス（成功時）:
  - `{"success": true, "image_url": "https://.../x-images/...", "mime_type": "image/png", ...}`

この仕様に合わせて `x-manager/commands/x-image.md` は既に更新済みのため、Edge Function を反映すれば `/x-image` コマンドからそのまま利用できます。

