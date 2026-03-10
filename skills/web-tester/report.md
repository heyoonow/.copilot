---
name: web-tester-report
description: "버그 분류 기준 및 TEST_REPORT.md 작성 형식. web-tester 스킬 Step 6에서 참조."
---

# Web Tester — 버그 분류 & 리포트

---

## 버그 등급

| 등급 | 코드 | 기준 |
|---|---|---|
| 🔴 Critical | CRASH | 페이지 오류 / 500 / 흰 화면 / 데이터 유실 |
| 🟠 High | WRONG | 잘못된 데이터 노출 / 기대와 다른 동작 |
| 🟡 Medium | UI | 레이아웃 깨짐 / 모바일 깨짐 / 요소 겹침 |
| 🟡 Medium | LOGIC | 폼 검증 우회 / 권한 없이 접근 가능 |
| 🔵 Low | PERF | LCP 3초 초과 / 버튼 반응 1초 초과 |

---

## TEST_REPORT.md 형식

`docs/TEST_REPORT.md` — **항상 덮어씌운다. 누적 금지.**

```markdown
# E2E 테스트 리포트

> 마지막 실행: YYYY-MM-DD HH:mm
> 환경: Playwright vX.X / Chrome + Firefox + Mobile
> 상태: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL

## 요약

| 전체 | 통과 | 실패 | Critical |
|---|---|---|---|
| N | N | N | N |

---

## 발견된 버그

### 🔴 CRITICAL

#### BUG-001: [제목]
- **위치**: /path > 액션
- **재현**: 1. ... 2. ...
- **기대**: ~해야 함
- **실제**: ~가 발생함
- **브라우저**: Chrome / 전체
- **케이스**: T-XXX-001
- **증거**: test-results/.../screenshot.png

---

## 전체 시나리오 결과

| ID | 시나리오 | 도구 | Chrome | Firefox | Mobile | 비고 |
|---|---|---|---|---|---|---|
| T-AUTH-001 | 정상 로그인 | Playwright | ✅ | ✅ | ✅ | |
| T-UNIT-001 | 이메일 검증 | Jest | ✅ | - | - | |
| T-CORE-001 | 아이템 생성 | Playwright | ❌ | ✅ | ✅ | BUG-001 |

---

## 다음 액션

- [ ] BUG-001 수정 필요
- trace 분석: `npx playwright show-trace test-results/.../trace.zip`
- 실패 스크린샷: `playwright-report/` 폴더 확인
```
