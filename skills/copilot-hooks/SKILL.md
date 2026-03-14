---
name: copilot-hooks
description: "HEYNOW Copilot CLI 훅 설치 스킬. 텔레그램 알림, 작업 시간 추적, heartbeat 훅을 현재 프로젝트에 자동 설치한다. 'copilot 훅 설치', '훅 적용', '알림 훅 설치', 'hooks 설치' 키워드에 즉시 발동. Flutter hooks 패키지(flutter_hooks)와 전혀 다른 개념임."
---

# HEYNOW Copilot CLI 훅 설치 스킬

> ⚠️ 이 스킬은 **Copilot CLI hooks** 설치 전용이다.  
> Flutter `flutter_hooks` 패키지와 **완전히 다른 개념**이다. 절대 혼동하지 말 것.

## 🚀 설치 절차 — 스킬 호출 즉시 아래 순서대로 실행한다

### STEP 1 — 설치 스크립트 실행

현재 작업 디렉토리(cwd)를 확인한 뒤 아래 명령어를 즉시 실행한다:

```bash
~/.copilot/hooks/setup-hooks.sh .
```

### STEP 2 — 설치 확인

```bash
cat .github/hooks/telegram-notify.json
```

### STEP 3 — 완료 보고

설치된 파일 경로와 함께 완료 메시지를 대표님께 보고한다.

---

## 동작 방식 (참고용)

| 훅 | 타이밍 | 내용 |
|---|---|---|
| `userPromptSubmitted` | 프롬프트 입력 시 | 시작 시간 기록 + 5분마다 heartbeat 알림 시작 |
| `agentStop` | 작업 완료 시 | heartbeat 종료 + 텔레그램 완료 알림 (30초 이상 시) |

- **5분마다:** "아직 작업 중이에요 대표님 ㅠㅠ" 텔레그램
- **30초 이상 완료 시:** 프로젝트명 + 소요시간 + 작업내용 텔레그램
