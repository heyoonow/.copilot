# Web Tester — 디버깅

> 대부분의 버그 원인은 Trace의 Network 탭에 있다.

---

## 디버깅 플로우

```
1. npx playwright test --ui         ← 먼저. 어디서 실패하는지 시각적으로 확인
2. 실패 액션 특정 → locator 문제 vs 타이밍 문제 판단
3. locator 문제 → UI 모드 Pick locator 기능으로 올바른 셀렉터 복사
4. 타이밍 문제 → waitForResponse() / waitForLoadState() 추가
5. npx playwright test --last-failed  ← 실패한 것만 재실행
```

---

## 커맨드

```bash
# UI 모드 — 가장 먼저 쓸 것. 단계별 실행 + locator 실시간 확인
npx playwright test --ui

# 브라우저 실제로 띄워서 눈으로 확인
npx playwright test --headed

# 느리게 실행 (단계 추적용)
npx playwright test --headed --slowmo=500

# 디버거 연결 — 중단점마다 멈춤
npx playwright test --debug

# 코드 특정 라인에서 멈추기
await page.pause();

# 실패 trace 열기
npx playwright show-trace test-results/.../trace.zip
npx playwright show-report
```

---

## 증상별 처방

| 증상                           | 원인                                | 처방                                        |
| ------------------------------ | ----------------------------------- | ------------------------------------------- |
| `Timeout: waiting for locator` | 요소 없음 or 셀렉터 틀림            | `--ui` 모드로 Pick locator 확인             |
| `strict mode violation`        | 같은 셀렉터 2개 이상 매칭           | `getByRole()` + `{ name }` 으로 범위 좁히기 |
| `Error: page was closed`       | 페이지가 먼저 닫힘                  | `waitForURL()` or `waitForLoadState()` 추가 |
| setup 통과 → 테스트 실패       | 세션 만료 or storageState 경로 오류 | `e2e/.auth/user.json` 존재 여부 확인        |
| CI에서만 실패                  | 타이밍 이슈 or 해상도 차이          | `retries: 2` + `actionTimeout` 늘리기       |
| 특정 브라우저에서만 실패       | 브라우저 렌더링 차이                | `--project=chromium` 단독 실행으로 격리     |

---

## Trace 읽는 법

`trace: "on-first-retry"` 설정 시 실패한 테스트 trace가 `test-results/`에 자동 저장.

리포트에서 실패한 테스트 클릭 → Trace 탭:

| 탭              | 볼 것                                               |
| --------------- | --------------------------------------------------- |
| **Actions**     | 어떤 액션이 어느 시점에 실행됐는지 타임라인         |
| **Network**     | 각 액션 시점의 API 요청/응답 — **원인 대부분 여기** |
| **Screenshots** | 매 액션 전후 스냅샷                                 |
| **Console**     | 브라우저 콘솔 에러                                  |
