# Supabase Edge Function `x-generate-article-image` 実装・デプロイ指示書

記事・カード用の横長画像（5:2）を **Nano Banana 2（Gemini 3.1 Flash Image）** で生成する Edge Function。

## 1. 目的

- 記事・カード用の横長画像（5:2）を Nano Banana 2 で生成し、Supabase Storage に保存して公開URLを返す
- x-article-image スキル・コマンドから `POST` で呼び出す

## 2. 事前情報

- Supabase プロジェクト情報は `x-manager/config.local.md` を参照
- x-article-image スキル: `x-manager/skills/x-article-image/SKILL.md`

## 3. Supabase 側でやること

1. Edge Function ディレクトリ: `supabase/functions/x-generate-article-image/index.ts`
2. 下記コードを `index.ts` に貼り付ける
3. Secrets: `GEMINI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
4. Storage: public バケット `x-images`（x-generate-image と共有可）
5. デプロイ: `supabase functions deploy x-generate-article-image`

## 4. Edge Function コード全文

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
- Lines: thin black pen lines with a hand-drawn feel
- Coloring: watercolor-style light colors (cream, light blue, light orange, light green)
- Layout: horizontal banner style for article headers or social cards (5:2 aspect ratio)

### Color Palette
- IMPORTANT: Background must be white (#FFFFFF)
- Main colors: black (lines), light orange/yellow (emphasis)
- Accent colors: light blue, light green, light pink

### Layout (5:2 horizontal)
- Wide horizontal composition for article/card header
- Key message on the left or center, illustration/element on the right or center
- Text: round gothic style, large and readable
- IMPORTANT: All text in the image MUST be in Japanese

### Elements to AVOID
- Realistic human depictions, gradients, drop shadows, complex backgrounds, 3D rendering
`;

function buildPrompt(postText: string): string {
  return `${IMAGE_STYLE_PROMPT}

## Content to Illustrate (Article / Card)
\"\"\"
${postText}
\"\"\"

## Instructions
Create a single horizontal (5:2) illustration that:
1. Captures the main message for an article or social card header
2. Uses the Japanese business book illustration style
3. Has 1-3 short Japanese text labels
4. Is visually engaging for a wide banner layout

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
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        responseModalities: ["IMAGE", "TEXT"],
        imageConfig: {
          aspectRatio: "5:2",
        },
      },
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Gemini API error: ${res.status} ${res.statusText} - ${text}`);
  }

  const json = await res.json();
  const candidates = json.candidates ?? [];
  if (!candidates.length) throw new Error("Gemini API response has no candidates");

  const parts = candidates[0].content?.parts ?? [];
  for (const part of parts) {
    const inline = part.inlineData ?? part.inline_data;
    if (inline?.data) {
      const mimeType = inline.mimeType ?? inline.mime_type ?? "image/png";
      const binary = Uint8Array.from(atob(inline.data as string), (c) => c.charCodeAt(0));
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
  if (!supabase) throw new Error("Supabase client is not initialized");

  const now = new Date();
  const ts = now.toISOString().replace(/[-:T.Z]/g, "").slice(0, 14);
  const safeSuffix = idSuffix?.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 32);
  const filenameBase = safeSuffix ? `x_article_image_${ts}_${safeSuffix}` : `x_article_image_${ts}`;
  const path = `${now.getUTCFullYear()}/${(now.getUTCMonth() + 1).toString().padStart(2, "0")}/${filenameBase}.png`;

  const { error } = await supabase.storage.from(IMAGE_BUCKET).upload(path, bytes, {
    contentType: mimeType || "image/png",
    upsert: false,
  });
  if (error) throw new Error(`Failed to upload: ${error.message}`);

  const baseUrl = SUPABASE_URL?.replace(/\/+$/, "") ?? "";
  return `${baseUrl}/storage/v1/object/public/${IMAGE_BUCKET}/${path}`;
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: { ...corsHeaders } });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ success: false, error: "Method Not Allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const text = (body?.text ?? "").toString().trim();
    const idSuffix = body?.id_suffix ? String(body.id_suffix) : undefined;
    if (!text) {
      return new Response(JSON.stringify({ success: false, error: "`text` is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const prompt = buildPrompt(text);
    const { mimeType, imageBytes } = await callGeminiImageAPI(prompt);
    const imageUrl = await uploadToStorage(imageBytes, mimeType, idSuffix);

    return new Response(
      JSON.stringify({ success: true, image_url: imageUrl, mime_type: mimeType }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("x-generate-article-image error:", e);
    return new Response(
      JSON.stringify({ success: false, error: e instanceof Error ? e.message : String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
```

## 5. 呼び出し仕様

- エンドポイント: `POST {Edge Function Base URL}/x-generate-article-image`
- ヘッダー: `Authorization: Bearer {Anon Key}`, `Content-Type: application/json`
- ボディ: `{"text": "画像用テキスト", "id_suffix": "xxx"}`（id_suffix は任意）
- レスポンス（成功）: `{"success": true, "image_url": "https://.../x-images/...", "mime_type": "image/png"}`

## 補足

- アスペクト比 5:2 が API でサポートされない場合は、`3:2` や `16:9` など近い比率への変更を検討してください。
