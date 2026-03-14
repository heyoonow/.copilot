---
name: copilot-hooks
description: "HEYNOW Copilot CLI 훅 설치 스킬. 텔레그램 알림, 작업 시간 추적, heartbeat 훅을 프로젝트에 적용한다. 'copilot 훅', '훅 적용', '훅 설치', '텔레그램 알림 설치', 'hooks 설치' 키워드에 즉시 발동. Flutter hooks 패키지(flutter_hooks)와 전혀 다른 개념임."
---

# HEYNOW Copilot CLI 훅 설치 스킬

> ⚠️ 이 스킬은 **Copilot CLI hooks** 설치 전용이다.  
> Flutter `flutter_hooks` 패키지와 **완전히 다른 개념**이다. 절대 혼동하지 말 것.

## 설치 방법

현재 작업 중인 프로젝트 루트에서 아래 스크립트를 실행한다:

```bash
~/.copilot/hooks/setup-hooks.sh .
```

또는 경로를 직접 지정:

```bash
~/.copilot/hooks/setup-hooks.sh /path/to/project
```

## 설치 결과

실행하면 프로젝트에 `.github/hooks/telegram-notify.json` 파일이 생성된다.

## 동작 방식

| 훅 | 타이밍 | 내용 |
|---|---|---|
| `userPromptSubmitted` | 프롬프트 입력 시 | 시작 시간 기록 + heartbeat 백그라운드 시작 |
| `agentStop` | 작업 완료 시 | heartbeat 종료 + 텔레그램 완료 알림 |

- **5분마다:** "아직 작업 중이에요 대표님 ㅠㅠ" 텔레그램 알림
- **30초 이상 작업 완료 시:** 프로젝트명 + 소요시간 + 작업내용 텔레그램 알림

## 설치 후 확인

```bash
cat .github/hooks/telegram-notify.json
```

## 주의사항

- `.github/hooks/` 경로를 `.gitignore`에 추가할지 여부는 대표님께 확인
- 스크립트 본체는 `~/.copilot/hooks/scripts/` 에 있으므로 각 머신마다 `~/.copilot` 레포가 클론되어 있어야 동작
