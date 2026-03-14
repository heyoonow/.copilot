#!/bin/bash
# userPromptSubmitted 훅: 작업 시작 시간 기록

INPUT="$(cat)"
TIMESTAMP_MS="$(echo "$INPUT" | jq -r '.timestamp // empty')"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty')"

# 세션별 임시 파일에 시작 시간 저장
TMPFILE="/tmp/copilot_task_start_$$"
echo "${TIMESTAMP_MS}|${PROMPT}" > "/tmp/copilot_task_start"

exit 0
