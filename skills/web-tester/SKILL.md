---
name: web-tester
description: "웹 앱 전체 테스트 전략을 설계하고 실행하여 버그를 찾고, 결과를 docs/TEST_REPORT.md에 기록하는 스킬. '테스트 해줘', '버그 찾아줘', 'QA 해줘', 'E2E', '웹 점검', '회귀 테스트', 'regression' 키워드에 발동."
---

# Web Tester — 메인

> 테스터의 역할은 동작을 확인하는 게 아니라 시스템의 신뢰를 증명하는 것이다.

---

## 핵심 원칙

- **추측하지 않는다** — 실제 브라우저 + 실제 코드로 실행하고 결과를 본다
- **전체 흐름을 커버한다** — 단위 기능이 아닌 사용자 시나리오 전체 검증
- **기능 수정 후 반드시 전체 PASS** — 통과 전 배포 불가
- **`docs/TEST_REPORT.md` 항상 덮어씌운다** — 누적하지 않음, 타임스탬프 포함

---

## 전체 흐름

```
1. 프로젝트 파악
2. Playwright 설치/설정   → setup.md 참조
3. 시나리오 설계          → scenarios.md 참조
4. 테스트 코드 작성       → patterns.md 참조
5. 실행 & 버그 수집
6. TEST_REPORT.md 작성   → report.md 참조
```

---

## Step 1. 프로젝트 파악

```bash
cat package.json
ls src/ pages/ app/ components/ 2>/dev/null | head -40
```

확인할 것:
- 프레임워크 (Next.js / React / Vue / Nuxt)
- 주요 라우트 목록
- 인증 방식 (JWT / Session / OAuth / Supabase)
- 기존 테스트 존재 여부

---

## 테스트 파일 구조

```
e2e/                      ← Playwright E2E
├── auth/
├── core/
├── ui/
└── helpers/
    ├── auth.setup.ts
    ├── fixtures.ts
    └── pages/            ← Page Object Model

__tests__/                ← Jest / Vitest 단위·통합
├── components/
├── hooks/
└── utils/

docs/
└── TEST_REPORT.md        ← 항상 덮어씌움
```

---

## 실행 커맨드

```bash
# E2E 전체
npx playwright test

# UI 모드 (시각적 디버깅)
npx playwright test --ui

# 특정 분류만
npx playwright test --grep "T-CORE"

# 실패한 것만 재실행
npx playwright test --last-failed

# 단위 테스트
npx jest  /  npx vitest

# trace 분석
npx playwright show-trace test-results/.../trace.zip
```
