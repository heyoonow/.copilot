---
name: web-task
description: "Next.js 웹 앱 개발 작업을 실행한다. 새 페이지, 컴포넌트, API Route, DB 연동, UI 개선 등 Next.js 관련 모든 작업 요청에 사용한다. App Router 구조와 shadcn/ui 디자인 시스템을 반드시 준수하며, 1억 다운로드 앱 기준의 디자인과 UX를 목표로 구현한다."
---

# Web Task Executor

## STEP 1 — 참조 문서 로딩 (작업 유형별 필요한 것만 읽는다)

| 작업 유형                                              | 읽을 파일       | 해당 작업 예시                                |
| ------------------------------------------------------ | --------------- | --------------------------------------------- |
| 새 페이지 / 컴포넌트 / UI / 애니메이션 / 스켈레톤      | `./design.md`   | 화면 구현, 카드·버튼·폼, 로딩·에러·빈 상태 UI |
| 프로젝트 구조 / MongoDB 설정 / 환경변수 / 신규 기능    | `./stack.md`    | 폴더 구조 확인, DB 연결, Docker, .env         |
| Server/Client 판단 / App Router / Next.js 버전 이슈    | `./nextjs.md`   | params Promise, ISR, HMR, ShellLayout         |
| API Route / Server Action / Mongoose / 인증 / 에러처리 | `./patterns.md` | CRUD API, Server Action, 모델 정의, NextAuth  |

**여러 유형에 해당하면 해당하는 파일 모두 읽는다.**

예시: 새 페이지 + DB 연동 → `./design.md` + `./stack.md` + `./patterns.md` + `./nextjs.md`
예시: UI 컴포넌트만 → `./design.md`만
예시: API Route 추가만 → `./patterns.md` + `./stack.md`

---

## STEP 2 — 프로젝트 실제 파일 파악

### 항상 확인 (전체 작업 공통)

```bash
# 프로젝트 구조 파악
find app components lib -type f -name "*.tsx" -o -name "*.ts" | head -30

# Next.js 버전 확인 (params Promise 여부 결정)
cat package.json | grep '"next"'

# 현재 환경변수 파악
cat .env.local 2>/dev/null || echo "없음"
```

### UI 작업 시 추가 확인

```bash
# 설치된 shadcn 컴포넌트 목록 (재사용 우선)
ls components/ui/

# 기존 비슷한 컴포넌트 확인 (중복 방지)
find components -name "*.tsx" | grep -v "ui/" | head -20

# tailwind.config 확인 (커스텀 색상, 폰트)
cat tailwind.config.ts 2>/dev/null || cat tailwind.config.js 2>/dev/null
```

### 새 기능 추가 시 추가 확인

```bash
# 기존 모델 확인
find lib/db/models -name "*.ts" 2>/dev/null

# 기존 API Route 확인
find app/api -name "route.ts" 2>/dev/null

# 기존 Server Action 확인
find lib/actions -name "*.ts" 2>/dev/null
```

---

## STEP 3 — 구현 순서

### 데이터 있는 기능

```
Mongoose 모델 정의
  ↓
API Route or Server Action
  ↓
Server Component (데이터 fetch)
  ↓
Client Component (인터랙티브 UI)
```

### UI만 있는 기능

```
shadcn 컴포넌트 조합
  ↓
커스텀 Tailwind 스타일링
  ↓
애니메이션 + 반응형
```

---

## STEP 4 — 구현 완료 후 체크리스트

```
□ TypeScript 에러 없음
□ Server / Client 경계 올바름 ('use client' 불필요한 곳에 없는지)
□ Next.js 버전에 맞게 params await 처리했는지
□ connectDB() 모든 API Route / Server Action 시작 시 호출
□ Mongoose 모델 models.X || model(...) 패턴 적용
□ 로딩 상태 → Skeleton 처리됨 (스피너 금지)
□ 에러 상태 처리됨
□ 모바일 반응형 확인 (mobile-first)
□ revalidatePath() / revalidateTag()로 캐시 무효화
□ 민감 정보 서버 사이드에서만 접근 (.env.local)
□ 이미지 next/image, 링크 next/link 사용
```

---

## 절대 규칙

| 규칙                                    | 이유                             |
| --------------------------------------- | -------------------------------- |
| `use client` 최대한 아래로 내리기       | Server Component 최대 활용, 성능 |
| shadcn/ui 먼저 확인, 없으면 직접 구현   | 디자인 일관성                    |
| 스피너 금지 → Skeleton 사용             | UX 일관성                        |
| `connectDB()` 매 API Route 시작 시 호출 | 연결 안정성                      |
| 이미지 반드시 `next/image`              | 자동 최적화                      |
| 링크 반드시 `next/link`                 | SPA 라우팅                       |
| 모델 `models.X \|\| model(...)` 패턴    | HMR 중복 등록 방지               |
