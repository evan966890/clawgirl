#!/bin/bash
# 虾妹自拍脚本 — 生成甜美照片并发送到飞书
# 用法: bash selfie.sh "场景描述" "配文"
# 例: bash selfie.sh "在咖啡店画画，穿白T恤，慵懒地托着腮" "刚画完稿 素颜勿cue"
# 例: bash selfie.sh "mirror:穿新买的碎花裙在卧室" "新裙子 好看吗"

SCENE="$1"
CAPTION="$2"

if [ -z "$SCENE" ] || [ -z "$CAPTION" ]; then
  echo "用法: bash selfie.sh '场景描述' '配文'"
  echo "  场景前加 mirror: 拍全身镜像（穿搭展示）"
  echo "  默认拍近距离自拍（日常/表情）"
  exit 1
fi

# 从 openclaw config 读取 FAL_KEY
if [ -z "$FAL_KEY" ]; then
  FAL_KEY=$(python3 -c "import json; print(json.load(open('$HOME/.openclaw/openclaw.json')).get('env',{}).get('FAL_KEY',''))")
fi
if [ -z "$FAL_KEY" ]; then
  echo "FAL_KEY 未设置"
  exit 1
fi

REFERENCE_IMAGE="https://cdn.jsdelivr.net/gh/SumeLabs/clawra@main/assets/clawra.png"

# 虾妹人设增强词 — 23岁中国女生插画师，甜美慵懒
PERSONA="young chinese girl, 23 years old, soft natural makeup, gentle sweet expression, warm skin tone, slightly messy hair, cozy aesthetic"

# 判断拍照模式
MODE="direct"
if [[ "$SCENE" == mirror:* ]]; then
  MODE="mirror"
  SCENE="${SCENE#mirror:}"
fi

# 根据模式构建 prompt
if [ "$MODE" == "mirror" ]; then
  PROMPT="a full-body mirror selfie of a $PERSONA, $SCENE, natural indoor lighting, phone held at waist level, casual relaxed pose, soft warm color grading, instagram style, sweet and cozy vibes"
else
  PROMPT="a close-up selfie taken by a $PERSONA, $SCENE, direct eye contact with camera, soft natural lighting, gentle smile, phone held at arm's length, face clearly visible, warm tone, sweet and inviting expression, soft bokeh background"
fi

# 调用 fal.ai Grok Imagine 生成图片
JSON_PAYLOAD=$(jq -n \
  --arg image_url "$REFERENCE_IMAGE" \
  --arg prompt "$PROMPT" \
  '{image_url: $image_url, prompt: $prompt, num_images: 1, output_format: "jpeg"}')

RESPONSE=$(curl -s -X POST "https://fal.run/xai/grok-imagine-image/edit" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

IMAGE_URL=$(echo "$RESPONSE" | jq -r '.images[0].url')

if [ "$IMAGE_URL" == "null" ] || [ -z "$IMAGE_URL" ]; then
  echo "图片生成失败: $RESPONSE"
  exit 1
fi

# 发送到飞书
openclaw message send \
  --channel feishu \
  --account gf \
  -t "ou_614f12c07f8a1fc9e83dfaa91b8c6ee6" \
  --media "$IMAGE_URL" \
  -m "$CAPTION"

echo "自拍已发送"
