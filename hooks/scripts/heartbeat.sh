#!/bin/bash
TELEGRAM_TOKEN="8721505891:AAE8EiP2Lr-6jPFXxfpIDDND-hPm8eI9gj4"
TELEGRAM_CHAT_ID="7747196424"
INTERVAL_SEC=300

INPUT="$(cat)"
exec < /dev/null  # ← 핵심! stdin 즉시 해제

CWD="$(echo "$INPUT" | jq -r '.cwd // "unknown"')"
PROJECT_NAME="$(basename "$CWD")"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' | head -1)"
PROMPT_SHORT="${PROMPT:0:80}"
if [ ${#PROMPT} -gt 80 ]; then
  PROMPT_SHORT="${PROMPT_SHORT}..."
fi
PROMPT_SHORT="$(echo "$PROMPT_SHORT" | tr -d '*_`[]')"
PROJECT_NAME="$(echo "$PROJECT_NAME" | tr -d '*_`[]')"

PID_FILE="/tmp/copilot_heartbeat_pid"

if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE")"
  kill "$OLD_PID" 2>/dev/null
  rm -f "$PID_FILE"
fi

(
  COUNT=0
  while true; do
    sleep "$INTERVAL_SEC"
    COUNT=$((COUNT + 1))
    ELAPSED_MIN=$((COUNT * INTERVAL_SEC / 60))
    MESSAGE="⏳ *아직 작업 중이에요 대표님 ㅠㅠ*

🗂 프로젝트: *${PROJECT_NAME}*
🕐 경과 시간: *${ELAPSED_MIN}분째 작업 중...*
📋 작업 지시: ${PROMPT_SHORT}"

    curl -s --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg chat_id "$TELEGRAM_CHAT_ID" \
        --arg text "$MESSAGE" \
        '{chat_id: $chat_id, text: $text, parse_mode: "Markdown"}')" \
      > /dev/null 2>&1
  done
) </dev/null >/dev/null 2>&1 &
BG_PID=$!
disown $BG_PID

echo $BG_PID > "$PID_FILE"
exit 0