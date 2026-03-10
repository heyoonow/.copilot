---
name: web-tester-patterns
description: "E2E(Playwright) 및 단위 테스트(Jest/Vitest) 코드 패턴 레퍼런스. web-tester 스킬 Step 4에서 참조."
---

# Web Tester — 코드 패턴

> `page.waitForTimeout()` 절대 금지 — `expect(locator).toBeVisible()` 로 대체

---

## E2E 기본 구조

```typescript
import { test, expect } from "@playwright/test";

test.use({ storageState: "e2e/.auth/user.json" }); // 세션 재사용

test.describe("[T-CORE] 아이템 관리", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/dashboard");
  });

  test("T-CORE-001: 아이템 생성 후 목록에 반영", async ({ page }) => {
    await page.getByRole("button", { name: "추가" }).click();
    await page.getByLabel("제목").fill("테스트 아이템");
    await page.getByRole("button", { name: "저장" }).click();
    await expect(page.getByText("저장되었습니다")).toBeVisible();
    await expect(page.getByText("테스트 아이템")).toBeVisible();
  });
});
```

---

## Page Object Model

반복되는 UI는 반드시 추상화한다.

```typescript
// e2e/helpers/pages/DashboardPage.ts
import { Page, expect } from "@playwright/test";

export class DashboardPage {
  constructor(readonly page: Page) {}

  async goto() {
    await this.page.goto("/dashboard");
  }

  async createItem(title: string) {
    await this.page.getByRole("button", { name: "추가" }).click();
    await this.page.getByLabel("제목").fill(title);
    await this.page.getByRole("button", { name: "저장" }).click();
    await expect(this.page.getByText("저장되었습니다")).toBeVisible();
  }
}
```

---

## API 모킹

```typescript
// 서버 에러 시뮬레이션
await page.route("**/api/items", (route) =>
  route.fulfill({
    status: 500,
    body: JSON.stringify({ error: "Server Error" }),
  }),
);

// 지연 (로딩 스켈레톤 테스트)
await page.route("**/api/items", async (route) => {
  await new Promise((r) => setTimeout(r, 1500));
  await route.continue();
});

// 요청 payload 검증
let requestBody: unknown;
await page.route("**/api/items", async (route) => {
  requestBody = JSON.parse(route.request().postData() || "{}");
  await route.continue();
});
expect(requestBody).toMatchObject({ title: "신규 아이템" });
```

---

## 보안 테스트

```typescript
// 비로그인 상태 (storageState 없는 새 컨텍스트)
const context = await browser.newContext();
const page = await context.newPage();
await page.goto("/dashboard");
await expect(page).toHaveURL(/\/login/);
await context.close();
```

---

## 반응형

```typescript
test("T-UI-001: 모바일 햄버거 메뉴", async ({ page, isMobile }) => {
  test.skip(!isMobile, "모바일만 해당");
  await page.goto("/");
  await page.getByTestId("hamburger").click();
  await expect(page.getByRole("navigation")).toBeVisible();
});
```

---

## Fixtures — 테스트 데이터 공통화

```typescript
// e2e/helpers/fixtures.ts
import { test as base } from "@playwright/test";
import { DashboardPage } from "./pages/DashboardPage";

export const test = base.extend({
  dashboard: async ({ page }, use) => {
    const d = new DashboardPage(page);
    await d.goto();
    await use(d);
  },
  uniqueTitle: async ({}, use) => {
    await use(`테스트_${Date.now()}`); // 테스트마다 고유 데이터
  },
});
export { expect } from "@playwright/test";
```

---

## 단위 테스트 (Jest / Vitest)

```typescript
// __tests__/utils/validator.test.ts
describe("이메일 유효성 검사", () => {
  it("올바른 형식 통과", () => {
    expect(validateEmail("test@example.com")).toBe(true);
  });
  it("@ 없으면 실패", () => {
    expect(validateEmail("notanemail")).toBe(false);
  });
});
```

---

## 자주 하는 실수

| 실수                           | 올바른 방법                                      |
| ------------------------------ | ------------------------------------------------ |
| `waitForTimeout(2000)`         | `expect(locator).toBeVisible()`                  |
| `page.click('#id')` CSS 셀렉터 | `getByRole()` / `getByLabel()` / `getByTestId()` |
| 매 테스트마다 로그인           | `auth.setup.ts` 세션 1회 생성 후 재사용          |
| 테스트 간 데이터 공유          | `Date.now()` 로 고유 데이터 생성                 |

---

> 테스트 실패 시 디버깅 → **debug.md** 참조
