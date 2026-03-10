---
name: web-tester-scenarios
description: "테스트 시나리오 분류 기준 및 작성 형식. web-tester 스킬 Step 3에서 참조."
---

# Web Tester — 시나리오 설계

---

## 시나리오 분류

| 코드 | 분류 | 커버 도구 | 설명 |
|---|---|---|---|
| `T-AUTH` | 인증 | Playwright | 로그인/로그아웃/세션 만료/권한 |
| `T-NAV` | 네비게이션 | Playwright | 라우팅/딥링크/뒤로가기 |
| `T-CORE` | 핵심 기능 | Playwright | 비즈니스 로직 전체 흐름 CRUD |
| `T-FORM` | 폼 | Playwright + Jest | 유효성/에러 메시지/제출 |
| `T-API` | API | Playwright (모킹) | 성공/실패/지연/빈 응답 |
| `T-UI` | UI/반응형 | Playwright | 모바일/레이아웃/모달/토스트 |
| `T-UNIT` | 단위 | Jest / Vitest | 컴포넌트/훅/유틸 함수 |
| `T-SEC` | 보안 | Playwright | 미인증 접근/권한 없는 리소스 |
| `T-EDGE` | 엣지케이스 | Playwright | 빈 상태/오프라인/동시 클릭 |
| `T-PERF` | 성능 | Playwright | LCP 3초 이하/버튼 반응 1초 이하 |

---

## 시나리오 작성 형식

```
[T-XXX-001] 시나리오 이름
- Given   : 사전 조건
- When    : 사용자 행동
- Then    : 기대 결과
- 도구    : Playwright / Jest
- Priority: Critical / High / Medium
```

---

## 우선순위 판단 기준

| Priority | 기준 |
|---|---|
| Critical | 이게 안 되면 서비스 불가 (로그인, 결제, 핵심 CRUD) |
| High | 주요 사용자 흐름에 영향 (폼 제출, 데이터 조회) |
| Medium | UX 영향, 대안 경로 존재 (반응형, 엣지케이스) |
