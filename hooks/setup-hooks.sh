#!/bin/bash
# 사용법: ./setup-hooks.sh [프로젝트경로]
# 예: ./setup-hooks.sh /Users/heyoonow/Documents/Source/heynow/server/heynow.web

TARGET="${1:-.}"

mkdir -p "${TARGET}/.github/hooks"
cp /Users/heyoonow/.copilot/.github/hooks/telegram-notify.json \
   "${TARGET}/.github/hooks/telegram-notify.json"

echo "✅ 훅 설정 완료: ${TARGET}/.github/hooks/telegram-notify.json"
