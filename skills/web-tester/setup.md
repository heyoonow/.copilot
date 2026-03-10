---
name: web-tester-setup
description: "Playwright 설치 및 playwright.config.ts 설정, 폴더 구조 생성, 로그인 세션 setup 작성. web-tester 스킬 Step 2에서 참조."
---

# Web Tester — 설치/설정

---

## 설치

```bash
npm install -D @playwright/test
npx playwright install
```

CI 환경:
```bash
npx playwright install --with-deps
```

---

## playwright.config.ts

```typescript
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,     // CI에서 test.only 실수 방지
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["html"], ["list"]],

  use: {
    baseURL: process.env.BASE_URL || "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "on-first-retry",
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
  },

  projects: [
    { name: "setup", testMatch: /.*\.setup\.ts/ },
    { name: "chromium", use: { ...devices["Desktop Chrome"] }, dependencies: ["setup"] },
    { name: "firefox", use: { ...devices["Desktop Firefox"] }, dependencies: ["setup"] },
    { name: "mobile", use: { ...devices["iPhone 14"] }, dependencies: ["setup"] },
  ],

  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

---

## 로그인 세션 Setup

`e2e/helpers/auth.setup.ts` — 1회 생성 후 전체 테스트가 재사용한다.

```typescript
import { test as setup } from "@playwright/test";

setup("로그인 세션 생성", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("이메일").fill(process.env.TEST_EMAIL!);
  await page.getByLabel("비밀번호").fill(process.env.TEST_PASSWORD!);
  await page.getByRole("button", { name: "로그인" }).click();
  await page.waitForURL("/dashboard");
  await page.context().storageState({ path: "e2e/.auth/user.json" });
});
```

---

## 환경변수 & .gitignore

**.env.test**
```env
BASE_URL=http://localhost:3000
TEST_EMAIL=test@example.com
TEST_PASSWORD=test1234!
```

**.gitignore 추가**
```gitignore
e2e/.auth/
playwright-report/
test-results/
.env.test
```
