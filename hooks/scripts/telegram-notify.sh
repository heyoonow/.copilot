#!/bin/bash
TELEGRAM_TOKEN="8721505891:AAE8EiP2Lr-6jPFXxfpIDDND-hPm8eI9gj4"
TELEGRAM_CHAT_ID="7747196424"
THRESHOLD_SEC="${COPILOT_NOTIFY_THRESHOLD_SEC:-30}"

INPUT="$(cat)"
exec < /dev/null  # ← 핵심! stdin 즉시 해제

NOW_MS="$(date +%s)"  # macOS 호환 (초 단위)

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

if [ -z "$START_MS" ]; then
  exit 0
fi

ELAPSED_SEC=$(( NOW_MS - START_MS ))
ELAPSED_SEC=${ELAPSED_SEC:-0}
if [ "$ELAPSED_SEC" -lt 0 ]; then ELAPSED_SEC=0; fi
rm -f "$START_FILE"

CWD="$(echo "$INPUT" | jq -r '.cwd // "unknown"')"
PROJECT_NAME="$(basename "$CWD")"
PROMPT_SUMMARY="${PROMPT:0:150}"
if [ ${#PROMPT} -gt 150 ]; then
  PROMPT_SUMMARY="${PROMPT_SUMMARY}..."
fi
PROMPT_SUMMARY="$(echo "$PROMPT_SUMMARY" | tr -d '*_`[]')"
PROJECT_NAME="$(echo "$PROJECT_NAME" | tr -d '*_`[]')"

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

# 오류가 없고 소요 시간이 짧으면 알림 생략
# 오류가 있으면 소요 시간 관계없이 항상 알림
if [ -z "$ISSUE_LINE" ] && [ "$ELAPSED_SEC" -lt "$THRESHOLD_SEC" ]; then
  exit 0
fi

if [ "$ELAPSED_SEC" -ge 60 ]; then
  ELAPSED_STR="$((ELAPSED_SEC / 60))분 $((ELAPSED_SEC % 60))초"
else
  ELAPSED_STR="${ELAPSED_SEC}초"
fi

if [ -n "$ISSUE_LINE" ]; then
  MESSAGE="🚨 *오류 발생했어요 대표님!*

🗂 프로젝트: *${PROJECT_NAME}*
⏱ 소요 시간: *${ELAPSED_STR}*
📋 작업 지시: ${PROMPT_SUMMARY}
${ISSUE_LINE}"
else
  MESSAGE="✅ *작업 완료됐어요 대표님!*

🗂 프로젝트: *${PROJECT_NAME}*
⏱ 소요 시간: *${ELAPSED_STR}*
📋 작업 지시: ${PROMPT_SUMMARY}"
fi

curl -s --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg chat_id "$TELEGRAM_CHAT_ID" \
    --arg text "$MESSAGE" \
    '{chat_id: $chat_id, text: $text, parse_mode: "Markdown"}')" \
  > /dev/null 2>&1 &
disown $!

exit 0