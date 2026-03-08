---
name: web-tester
description: 웹 앱의 전체 테스트 시나리오를 Playwright로 설계하고 실행하여 버그를 찾고, 발견된 내용을 docs/TEST_REPORT.md에 타임스탬프와 함께 덮어씌워 문서화하는 스킬. 웹 앱 테스트, E2E 테스트, 버그 리포트, QA 자동화, 테스트 시나리오 작성, 기능 수정 후 회귀 테스트가 필요할 때 반드시 이 스킬을 사용할 것. "테스트 해줘", "버그 찾아줘", "QA 해줘", "E2E", "playwright", "웹 점검", "regression" 같은 말이 나오면 항상 이 스킬을 트리거할 것.
---

# Web Playwright Tester Skill

웹 앱의 **전체 사용자 흐름을 커버하는 E2E 테스트**를 Playwright로 작성하고,
버그를 찾아 `docs/TEST_REPORT.md`에 **매번 덮어씌워** 문서화한다.

---

## 핵심 원칙

- **파일은 항상 덮어씌운다** — `docs/TEST_REPORT.md` 하나만 유지
- **문서 상단에 실행 시각** (YYYY-MM-DD HH:mm 형식) 기록
- **Playwright E2E 우선** — 실제 브라우저 기반 사용자 흐름 전체 검증
- **기능 수정 후 반드시 이 테스트를 통과**해야 배포 가능

---

## 왜 Playwright인가

| 툴                | 특징                                                                                    |
| ----------------- | --------------------------------------------------------------------------------------- |
| **Playwright** ⭐ | Chromium/Firefox/Safari 멀티 브라우저, 자동 대기, 네트워크 모킹, 스크린샷/영상 녹화까지 |
| Cypress           | 단일 브라우저, 설정 간단하지만 멀티탭/iframe 약함                                       |
| Selenium          | 구식, 느림, 불안정                                                                      |

> Playwright는 `waitForSelector` 같은 수동 대기 없이 **자동으로 요소 준비를 기다림** → 플레이키 테스트 최소화

---

## Step 1: 프로젝트 구조 파악

```bash
ls
cat package.json
ls src/ pages/ app/ components/ 2>/dev/null | head -40
```

파악할 것:

- 프레임워크 (Next.js, React, Vue, Nuxt 등)
- 주요 페이지/라우트 목록
- 인증 방식 (JWT, Session, OAuth)
- API 구조 (REST, GraphQL)
- 기존 테스트 존재 여부

---

## Step 2: Playwright 설치 & 설정

```bash
# 신규 설치
npm init playwright@latest

# 기존 프로젝트에 추가
npm install -D @playwright/test
npx playwright install
```

### 권장 playwright.config.ts

```typescript
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: [["html"], ["list"]],

  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000",
    trace: "on-first-retry", // 실패 시 trace 자동 저장
    screenshot: "only-on-failure", // 실패 시 스크린샷
    video: "on-first-retry", // 실패 시 영상 녹화
  },

  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "mobile", use: { ...devices["iPhone 14"] } },
  ],

  // 로컬에서 자동으로 dev 서버 실행
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## Step 3: 테스트 시나리오 설계

### 시나리오 분류 기준

```
T-AUTH   : 로그인/로그아웃/회원가입/권한
T-NAV    : 페이지 이동/라우팅/브레드크럼
T-CORE   : 핵심 비즈니스 기능
T-FORM   : 입력 폼 & 유효성 검사
T-API    : API 호출 & 에러 처리
T-UI     : 반응형/레이아웃/모달/토스트
T-EDGE   : 빈 상태/오프라인/권한없음
T-PERF   : 로딩 속도/LCP 기준
```

### 시나리오 템플릿

```
[T-XXX-001] 시나리오 이름
- Given: 사전 조건
- When: 사용자 행동
- Then: 기대 결과
- Browser: All / Chrome only
- Priority: Critical / High / Medium
```

---

## Step 4: E2E 테스트 코드 생성

### 파일 구조

```
e2e/
├── auth/
│   ├── login.spec.ts
│   └── signup.spec.ts
├── core/
│   ├── main-flow.spec.ts
│   └── data-crud.spec.ts
├── ui/
│   ├── responsive.spec.ts
│   └── edge-cases.spec.ts
└── helpers/
    ├── auth.setup.ts    # 로그인 상태 저장 (세션 재사용)
    └── fixtures.ts      # 공통 테스트 데이터
```

### 핵심 패턴

```typescript
import { test, expect } from "@playwright/test";

// 로그인 상태 재사용 (매 테스트마다 로그인 X)
test.use({ storageState: "e2e/.auth/user.json" });

test.describe("[T-CORE] 핵심 기능", () => {
  test("T-CORE-001: 아이템 생성 후 목록에 표시", async ({ page }) => {
    await page.goto("/dashboard");

    await page.getByRole("button", { name: "추가" }).click();
    await page.getByLabel("제목").fill("테스트 아이템");
    await page.getByRole("button", { name: "저장" }).click();

    // 토스트 메시지 확인
    await expect(page.getByText("저장되었습니다")).toBeVisible();

    // 목록에 아이템 존재 확인
    await expect(page.getByText("테스트 아이템")).toBeVisible();
  });

  test("T-FORM-001: 필수값 누락 시 에러 표시", async ({ page }) => {
    await page.goto("/form");
    await page.getByRole("button", { name: "제출" }).click();

    await expect(page.getByText("필수 입력 항목입니다")).toBeVisible();
  });
});
```

### API 모킹 패턴

```typescript
test("T-API-001: API 에러 시 에러 UI 표시", async ({ page }) => {
  // 특정 API 실패 시뮬레이션
  await page.route("**/api/items", (route) => {
    route.fulfill({ status: 500, body: "Server Error" });
  });

  await page.goto("/dashboard");
  await expect(page.getByText("오류가 발생했습니다")).toBeVisible();
});
```

### 로그인 세션 저장 (setup)

```typescript
// e2e/helpers/auth.setup.ts
import { test as setup } from "@playwright/test";

setup("로그인 상태 저장", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("이메일").fill(process.env.TEST_EMAIL!);
  await page.getByLabel("비밀번호").fill(process.env.TEST_PASSWORD!);
  await page.getByRole("button", { name: "로그인" }).click();
  await page.waitForURL("/dashboard");

  // 세션 저장 → 다른 테스트에서 재사용
  await page.context().storageState({ path: "e2e/.auth/user.json" });
});
```

---

## Step 5: 테스트 실행 & 버그 수집

```bash
# 전체 실행
npx playwright test

# UI 모드 (시각적 디버깅)
npx playwright test --ui

# 특정 파일만
npx playwright test e2e/auth/

# 실패한 것만 재실행
npx playwright test --last-failed

# HTML 리포트 열기
npx playwright show-report
```

버그 분류 기준:

- **CRASH**: 페이지 오류/500/흰 화면
- **WRONG**: 기대와 다른 동작/잘못된 데이터
- **UI**: 레이아웃 깨짐/요소 겹침/모바일 깨짐
- **PERF**: LCP 3초 초과/버튼 반응 1초 초과
- **LOGIC**: 폼 검증 우회/권한 없이 접근 가능

---

## Step 6: TEST_REPORT.md 생성/덮어씌우기

`docs/TEST_REPORT.md`를 **항상 새로 덮어쓴다**.

### 문서 구조

```markdown
# 웹 앱 E2E 테스트 리포트

> 마지막 실행: YYYY-MM-DD HH:mm
> 작성자: Claude (web-playwright-tester)
> 테스트 환경: Node vXX / Playwright vX.X / Chrome + Firefox + Mobile
> 상태: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL

---

## 요약

| 항목              | 수치                      |
| ----------------- | ------------------------- |
| 전체 시나리오 수  | N                         |
| 통과              | N                         |
| 실패              | N                         |
| 치명적 버그       | N                         |
| 브라우저 커버리지 | Chrome / Firefox / Mobile |

---

## 발견된 버그

### 🔴 CRITICAL

#### BUG-001: [버그 제목]

- **발생 위치**: /path > 액션명
- **재현 단계**:
  1. 단계1
  2. 단계2
- **기대 동작**: ~해야 함
- **실제 동작**: ~가 발생함
- **영향 브라우저**: Chrome / Firefox / 전체
- **테스트 케이스**: T-XXX-001
- **스크린샷**: (자동 첨부 경로)

---

## 테스트 시나리오 전체 결과

| ID         | 시나리오    | Chrome | Firefox | Mobile | 비고    |
| ---------- | ----------- | ------ | ------- | ------ | ------- |
| T-AUTH-001 | 정상 로그인 | ✅     | ✅      | ✅     |         |
| T-CORE-002 | 아이템 생성 | ❌     | ✅      | ✅     | BUG-001 |

---

## 다음 작업자에게

- [ ] BUG-001 수정 필요 (담당: ?)
- [ ] Chrome에서만 발생하는 이슈 원인 조사
- 기능 수정 후 반드시 `npx playwright test` 실행 후 전체 PASS 확인
- 실패 영상/스크린샷: `playwright-report/` 폴더 확인
```

---

## 실행 체크리스트

```
[ ] 프로젝트 구조 파악 완료
[ ] Playwright 설치 및 playwright.config.ts 설정
[ ] 전체 시나리오 목록 작성
[ ] e2e/ 테스트 코드 생성
[ ] 로그인 세션 setup 처리
[ ] 테스트 실행 & 결과 수집
[ ] docs/TEST_REPORT.md 덮어쓰기 완료 (타임스탬프 포함)
```

---

## 주의사항

- `.env.test` 파일에 `TEST_EMAIL`, `TEST_PASSWORD` 분리 관리
- `e2e/.auth/` 폴더는 `.gitignore`에 추가 (세션 토큰 노출 방지)
- CI에서는 `npx playwright install --with-deps` 필요
- `page.waitForTimeout()` 사용 금지 → `waitForSelector` / `expect().toBeVisible()` 사용
- 테스트 간 데이터 격리: 각 테스트마다 고유 데이터 생성 또는 teardown 처리
