#!/bin/bash
INPUT="$(cat)"
exec < /dev/null  # ← 핵심! stdin 즉시 해제

TIMESTAMP_MS="$(echo "$INPUT" | jq -r '.timestamp // empty')"
PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' | head -1)"

echo "${TIMESTAMP_MS}|${PROMPT}" > "/tmp/copilot_task_start"

exit 0