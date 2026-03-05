#!/bin/bash
# 虾妹语音脚本 — MiniMax Sweet_Girl_2 + 飞书原生语音消息
# 用法: bash voice.sh "要说的话"

TEXT="$1"
if [ -z "$TEXT" ]; then
  echo "用法: bash voice.sh '要说的话'"
  exit 1
fi

APP_ID="cli_a929292943781cc9"
APP_SECRET="HMBgEOx8vE5HUM3DpCbJWhevJwYSIp51"
TARGET="ou_614f12c07f8a1fc9e83dfaa91b8c6ee6"

# 读取 FAL_KEY
FAL_KEY="${FAL_KEY:-$(python3 -c "import json; c=json.load(open('$HOME/.openclaw/openclaw.json')); print(c.get('env',{}).get('FAL_KEY',''))" 2>/dev/null)}"
if [ -z "$FAL_KEY" ]; then
  echo "FAL_KEY 未配置"
  exit 1
fi

TS=$(date +%s)
MP3_FILE="$HOME/.openclaw/media/voice_${TS}.mp3"
OPUS_FILE="$HOME/.openclaw/media/voice_${TS}.opus"

mkdir -p "$HOME/.openclaw/media"

# 1. MiniMax TTS via fal.ai
TTS_RESULT=$(curl -s -X POST "https://fal.run/fal-ai/minimax/speech-02-hd" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"$TEXT\",\"voice_setting\":{\"voice_id\":\"Sweet_Girl_2\",\"speed\":1.0,\"emotion\":\"happy\"},\"language_boost\":\"Chinese\"}")

AUDIO_URL=$(echo "$TTS_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('audio',{}).get('url',''))" 2>/dev/null)

if [ -z "$AUDIO_URL" ]; then
  echo "TTS 生成失败: $TTS_RESULT"
  exit 1
fi

curl -sL "$AUDIO_URL" -o "$MP3_FILE"
if [ ! -f "$MP3_FILE" ] || [ ! -s "$MP3_FILE" ]; then
  echo "音频下载失败"
  exit 1
fi

# 2. 转 opus
ffmpeg -y -i "$MP3_FILE" -c:a libopus -b:a 32k -ar 16000 -ac 1 "$OPUS_FILE" 2>/dev/null
rm -f "$MP3_FILE"
if [ ! -f "$OPUS_FILE" ]; then
  echo "opus 转换失败"
  exit 1
fi

# 获取音频时长（秒）
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OPUS_FILE" 2>/dev/null | cut -d. -f1)
if [ -z "$DURATION" ] || [ "$DURATION" -eq 0 ]; then
  DURATION=3
fi
DURATION_MS=$((DURATION * 1000))

# 3. 获取 tenant_access_token
TOKEN=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}" | jq -r '.tenant_access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "获取 token 失败"
  rm -f "$OPUS_FILE"
  exit 1
fi

# 4. 上传音频文件
FILE_KEY=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/files" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file_type=opus" \
  -F "file_name=voice.opus" \
  -F "file=@$OPUS_FILE" | jq -r '.data.file_key')

rm -f "$OPUS_FILE"

if [ -z "$FILE_KEY" ] || [ "$FILE_KEY" = "null" ]; then
  echo "文件上传失败"
  exit 1
fi

# 5. 发送语音消息
RESULT=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"receive_id\":\"$TARGET\",\"content\":\"{\\\"file_key\\\":\\\"$FILE_KEY\\\",\\\"duration\\\":$DURATION_MS}\",\"msg_type\":\"audio\"}")

CODE=$(echo "$RESULT" | jq -r '.code')
if [ "$CODE" = "0" ]; then
  echo "语音已发送"
else
  echo "发送失败: $RESULT"
  exit 1
fi
