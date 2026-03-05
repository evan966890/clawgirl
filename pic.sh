#!/bin/bash
# 虾妹发图片脚本 — 发送网络图片到飞书
# 用法: bash pic.sh "图片URL" "配文"
# 例: bash pic.sh "https://xxx.jpg" "哈哈哈哈这只猫太搞笑了"

IMG_URL="$1"
CAPTION="$2"

if [ -z "$IMG_URL" ] || [ -z "$CAPTION" ]; then
  echo "用法: bash pic.sh '图片URL' '配文'"
  exit 1
fi

openclaw message send \
  --channel feishu \
  --account gf \
  -t "ou_614f12c07f8a1fc9e83dfaa91b8c6ee6" \
  --media "$IMG_URL" \
  -m "$CAPTION"

echo "图片已发送"
