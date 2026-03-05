#!/bin/bash
# 虾妹发消息脚本 — 发送文字到飞书
# 用法: bash send.sh "消息内容"

MSG="$1"
if [ -z "$MSG" ]; then
  echo "用法: bash send.sh '消息内容'"
  exit 1
fi

openclaw message send \
  --channel feishu \
  --account gf \
  -t "ou_614f12c07f8a1fc9e83dfaa91b8c6ee6" \
  -m "$MSG"
