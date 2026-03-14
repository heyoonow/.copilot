#!/bin/bash
# agentStop 훅: 작업 완료 후 소요 시간 계산 → 오래 걸리면 텔레그램 알림

TELEGRAM_TOKEN="8721505891:AAE8EiP2Lr-6jPFXxfpIDDND-hPm8eI9gj4"
TELEGRAM_CHAT_ID="7747196424"
THRESHOLD_SEC="${COPILOT_NOTIFY_THRESHOLD_SEC:-30}"

INPUT="$(cat)"
NOW_MS="$(echo "$INPUT" | jq -r '.timestamp // empty')"

START_FILE="/tmp/copilot_task_start"

# 시작 시간 파일 없으면 종료
if [ ! -f "$START_FILE" ]; then
  exit 0
fi

START_LINE="$(cat "$START_FILE")"
START_MS="$(echo "$START_LINE" | cut -d'|' -f1)"
PROMPT="$(echo "$START_LINE" | cut -d'|' -f2-)"

# 소요 시간 계산 (초)
if [ -z "$START_MS" ] || [ -z "$NOW_MS" ]; then
  exit 0
fi

ELAPSED_SEC=$(( (NOW_MS - START_MS) / 1000 ))

# 임시 파일 정리
rm -f "$START_FILE"

# 임계값 미만이면 알림 없음
if [ "$ELAPSED_SEC" -lt "$THRESHOLD_SEC" ]; then
  exit 0
fi

# 소요 시간 포맷
if [ "$ELAPSED_SEC" -ge 60 ]; then
  ELAPSED_STR="$((ELAPSED_SEC / 60))분 $((ELAPSED_SEC % 60))초"
else
  ELAPSED_STR="${ELAPSED_SEC}초"
fi

# 프로젝트 이름 추출 (cwd의 마지막 폴더명)
CWD="$(echo "$INPUT" | jq -r '.cwd // "unknown"')"
PROJECT_NAME="$(basename "$CWD")"

# 프롬프트 요약 (너무 길면 자름)
PROMPT_SUMMARY="${PROMPT:0:150}"
if [ ${#PROMPT} -gt 150 ]; then
  PROMPT_SUMMARY="${PROMPT_SUMMARY}..."
fi

# 텔레그램 메시지 전송
MESSAGE="✅ *Copilot 작업 완료*

🗂 프로젝트: *${PROJECT_NAME}*
⏱ 소요 시간: *${ELAPSED_STR}*
📝 작업 내용: ${PROMPT_SUMMARY}"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg chat_id "$TELEGRAM_CHAT_ID" \
    --arg text "$MESSAGE" \
    '{chat_id: $chat_id, text: $text, parse_mode: "Markdown"}')" \
  > /dev/null 2>&1 &

exit 0
