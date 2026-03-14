#!/bin/bash
# agentStop 훅: heartbeat 종료 + 완료 알림

TELEGRAM_TOKEN="8721505891:AAE8EiP2Lr-6jPFXxfpIDDND-hPm8eI9gj4"
TELEGRAM_CHAT_ID="7747196424"
THRESHOLD_SEC="${COPILOT_NOTIFY_THRESHOLD_SEC:-30}"

INPUT="$(cat)"
NOW_MS="$(echo "$INPUT" | jq -r '.timestamp // empty')"

# heartbeat 프로세스 종료
PID_FILE="/tmp/copilot_heartbeat_pid"
if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE")"
  kill "$OLD_PID" 2>/dev/null
  rm -f "$PID_FILE"
fi

START_FILE="/tmp/copilot_task_start"
if [ ! -f "$START_FILE" ]; then
  exit 0
fi

START_LINE="$(cat "$START_FILE")"
START_MS="$(echo "$START_LINE" | cut -d'|' -f1)"
PROMPT="$(echo "$START_LINE" | cut -d'|' -f2-)"

if [ -z "$START_MS" ] || [ -z "$NOW_MS" ]; then
  exit 0
fi

ELAPSED_SEC=$(( (NOW_MS - START_MS) / 1000 ))
rm -f "$START_FILE"

if [ "$ELAPSED_SEC" -lt "$THRESHOLD_SEC" ]; then
  exit 0
fi

# 소요 시간 포맷
if [ "$ELAPSED_SEC" -ge 60 ]; then
  ELAPSED_STR="$((ELAPSED_SEC / 60))분 $((ELAPSED_SEC % 60))초"
else
  ELAPSED_STR="${ELAPSED_SEC}초"
fi

CWD="$(echo "$INPUT" | jq -r '.cwd // "unknown"')"
PROJECT_NAME="$(basename "$CWD")"

PROMPT_SUMMARY="${PROMPT:0:150}"
if [ ${#PROMPT} -gt 150 ]; then
  PROMPT_SUMMARY="${PROMPT_SUMMARY}..."
fi

# 에러 감지
EXIT_CODE="$(echo "$INPUT" | jq -r '.exitCode // empty')"
STOP_REASON="$(echo "$INPUT" | jq -r '.reason // empty')"
ERROR_MSG="$(echo "$INPUT" | jq -r '.error // empty')"

if [ -n "$ERROR_MSG" ] && [ "$ERROR_MSG" != "null" ]; then
  ISSUE_LINE="🚨 이슈: ${ERROR_MSG:0:100}"
elif [ -n "$STOP_REASON" ] && [ "$STOP_REASON" != "null" ] && [ "$STOP_REASON" != "success" ]; then
  ISSUE_LINE="⚠️ 이슈: ${STOP_REASON}"
elif [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "null" ]; then
  ISSUE_LINE="⚠️ 이슈: 비정상 종료 (exit ${EXIT_CODE})"
else
  ISSUE_LINE=""
fi

MESSAGE="✅ *작업 완료됐어요 대표님!*

🗂 프로젝트: *${PROJECT_NAME}*
⏱ 소요 시간: *${ELAPSED_STR}*
📋 작업 지시: ${PROMPT_SUMMARY}"

if [ -n "$ISSUE_LINE" ]; then
  MESSAGE="${MESSAGE}
${ISSUE_LINE}"
fi

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg chat_id "$TELEGRAM_CHAT_ID" \
    --arg text "$MESSAGE" \
    '{chat_id: $chat_id, text: $text, parse_mode: "Markdown"}')" \
  > /dev/null 2>&1 &

exit 0
