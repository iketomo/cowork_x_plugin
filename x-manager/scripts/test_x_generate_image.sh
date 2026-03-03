#!/bin/bash
# x-generate-image Edge Function テストスクリプト
# 使い方: bash scripts/test_x_generate_image.sh

SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsdHltcm5rcWNoaXh2dHB2ZXdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5ODQ4NDAsImV4cCI6MjA4NzU2MDg0MH0.3jhu_WcThF2PS2f5ha05D3ZPiG_9M_eW7E7zfm9tL1A"
FUNCTION_URL="https://iltymrnkqchixvtpvewm.supabase.co/functions/v1/x-generate-image"

echo "===== x-generate-image Edge Function テスト ====="
echo ""

# --- Test 1: バリデーションエラー（textなし）---
echo "▶ Test 1: textなしリクエスト（400エラー期待）"
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{}')
echo "Response: $RESPONSE"
echo ""

# --- Test 2: 実際の画像生成 ---
echo "▶ Test 2: 実際の画像生成（GEMINI_API_KEY必須）"
POST_TEXT="AIエージェントが仕事を変える3つの方法：①メール自動返信 ②データ分析 ③スケジュール管理。人間はより創造的な仕事に集中できます。"
RESPONSE=$(curl -s -X POST "$FUNCTION_URL" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$POST_TEXT\", \"id_suffix\": \"test\"}")
echo "Response: $RESPONSE"
echo ""

# image_url抽出
IMAGE_URL=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('image_url', 'N/A'))" 2>/dev/null)
if [ "$IMAGE_URL" != "N/A" ] && [ -n "$IMAGE_URL" ]; then
  echo "✅ 成功！画像URL: $IMAGE_URL"
else
  echo "⚠️  image_urlが取得できませんでした。GEMINI_API_KEYがSupabase Secretsに設定されているか確認してください。"
  echo "   設定場所: Supabase Dashboard → Settings → Edge Functions → Secrets"
  echo "   Secret名: GEMINI_API_KEY"
fi
