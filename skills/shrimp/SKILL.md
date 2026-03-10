---
name: shrimp
description: "Shrimp Task Manager MCP를 활용해 복잡한 개발 작업을 구조화된 태스크로 분해하고 실행한다. 사용자가 기능 개발, 버그 수정, 리팩토링, 플랜 요청 등 복잡한 작업을 요청할 때 사용한다. 플랜 요청 시 PRD/로드맵 문서 작성 후 vibe coding 단위로 태스크를 분류한다."
---

# Shrimp Task Manager

> 모델은 Claude Sonnet 4.6 기준으로 동작한다.

---

> # ⛔️ STOP — 절대 규칙
>
> **플랜(plan_task / split_tasks) 완료 후 반드시 멈춘다.**
> **execute_task는 사용자가 명시적으로 실행을 지시할 때만 진행한다.**
> **태스크 번호를 언급해도, 다음 단계가 논리적으로 보여도, 어떤 이유로도 자동 실행 금지.**
> **플랜 결과만 보여주고 무조건 멈춘다.**

---

## 플랜 요청 워크플로우

사용자가 **"XXX 플랜해줘"**, **"XXX 기획해줘"**, **"XXX 설계해줘"** 같은 요청을 하면 아래 순서로 진행한다.

### 0단계: 기존 문서 확인 (재플랜 시)

`docs/PRD.md` 또는 `docs/ROADMAP.md`가 이미 존재하면 먼저 물어본다:

> "기존 PRD/Roadmap 문서가 있어요. 백업할까요?"

- **백업 O** → `docs/backup/YYYYMMDD_기능명/` 폴더에 기존 문서 전체 복사 후 새 문서 작성
- **백업 X** → 바로 덮어쓰기

백업 폴더명 예시:

```
docs/backup/20250307_user-auth/
docs/backup/20250307_payment/
```

### 1단계: 문서 작성

`plan_task` 실행 전에 반드시 두 문서를 먼저 작성한다.

**PRD (Product Requirements Document)** — `docs/PRD.md`

```
# PRD: [기능명]

## 개요
무엇을 왜 만드는가

## 사용자 스토리
- As a [user], I want to [action] so that [benefit]

## 기능 요구사항
- 핵심 기능 목록

## 비기능 요구사항
- 성능, 보안, 확장성 등

## 범위 외 (Out of Scope)
- 이번 버전에서 하지 않는 것
```

**Roadmap** — `docs/ROADMAP.md`

```
# Roadmap: [기능명]

## Phase 1 - MVP
- [ ] 핵심 기능

## Phase 2 - 고도화
- [ ] 추가 기능

## Phase 3 - 최적화
- [ ] 성능/UX 개선
```

### 2단계: plan_task 실행

작성한 PRD/Roadmap을 컨텍스트로 넣어 `plan_task`를 실행한다.

### 3단계: 프로젝트 타입 확인 후 태스크 분류

**먼저 현재 프로젝트가 뭔지 확인한다:**

- `pubspec.yaml` 존재 → **Flutter 프로젝트**
- `package.json` + `next.config.*` 존재 → **Web(Next.js) 프로젝트**

확인 후 아래 해당 섹션만 따른다.

---

## Flutter 프로젝트 태스크 분류

> 스택: Flutter + Supabase + hooks_riverpod + go_router

**의존성 규칙:** Design → Backend → Frontend 순서 엄수

### Phase 1 — Design

- 어떤 화면이 필요한지 목록 정의
- 각 화면의 컴포넌트 스펙 (Widget props, 상태)
- Supabase 테이블 스키마 초안 (컬럼, 타입, 관계)
- RLS 정책 초안

### Phase 2 — Backend

클린 아키텍처 레이어 순서:

1. Domain 엔티티 + Repository 인터페이스 (`domain/entities/`, `domain/repositories/`)
2. Usecase 구현 (`domain/usecases/`)
3. Supabase 테이블/RLS 실제 적용
4. SupabaseDataSource 구현 (`data/datasources/`)
5. Repository 구현체 (`data/repositories/`)

### Phase 3 — Frontend

1. Riverpod Notifier 구현 (`presentation/providers/`)
2. Screen 구현 (`presentation/screens/`) — HookConsumerWidget
3. 재사용 Widget 분리 (`presentation/widgets/`)
4. go_router 라우트 등록 (`router/app_router.dart`)
5. Android/iOS 플랫폼별 UX 처리

**태스크 예시:**

```
[Design] 로그인/회원가입 화면 스펙 정의
[Design] Supabase users 테이블 스키마 + RLS 정책 설계
[Backend] User 엔티티 + AuthRepository 인터페이스 정의
[Backend] LoginUsecase, SignupUsecase 구현
[Backend] Supabase users 테이블 생성 + RLS 적용
[Backend] SupabaseAuthDataSource 구현
[Backend] AuthRepositoryImpl 구현
[Frontend] AuthNotifier (Riverpod) 구현
[Frontend] LoginScreen 구현 (HookConsumerWidget)
[Frontend] SignupScreen 구현
[Frontend] go_router 인증 라우트 가드 적용
```

---

## Web(Next.js) 프로젝트 태스크 분류

> 스택: Next.js(App Router) + MongoDB(Docker) + Mongoose + shadcn/ui

**의존성 규칙:** Design → Backend → Frontend 순서 엄수

### Phase 1 — Design

- 어떤 페이지/화면이 필요한지 목록 정의
- 각 페이지 레이아웃 스펙 (컴포넌트 구조)
- API Route or Server Action 계약 정의 (URL, method, request/response 스펙)
- MongoDB 컬렉션 스키마 초안

### Phase 2 — Backend

1. Mongoose 모델 정의 (`lib/db/models/`)
2. API Route 구현 (`app/api/[resource]/route.ts`)
   - 또는 Server Action 구현 (`lib/actions/`)
3. DB 인덱스 설정 (필요 시)

### Phase 3 — Frontend

1. Server Component로 데이터 fetch (기본)
2. Client Component로 인터랙션 처리 (`'use client'`)
3. shadcn/ui 컴포넌트 조합 + Tailwind 스타일링
4. 로딩(스켈레톤) / 에러 / 빈 상태 처리
5. 반응형 레이아웃 (mobile-first)

**태스크 예시:**

```
[Design] 상품 목록/상세 페이지 레이아웃 스펙 정의
[Design] /api/products API 계약 정의 (request/response)
[Backend] Product Mongoose 모델 정의
[Backend] GET /api/products + POST /api/products Route 구현
[Backend] GET /api/products/[id] + DELETE Route 구현
[Frontend] ProductListPage Server Component 구현
[Frontend] ProductCard Client Component (hover 인터랙션)
[Frontend] ProductForm (shadcn Form + Server Action 연동)
[Frontend] 로딩 스켈레톤 + 에러 상태 처리
```

---

**Vibe coding 단위 원칙:**

- 태스크 하나 = 한 번의 프롬프트로 완성 가능한 크기
- 기준: 파일 1~3개 수준, 30분 내 완료 가능한 작업

---

## 일반 작업 워크플로우

### 단순 작업

```
plan_task → execute_task → verify_task → complete_task
```

### 복잡한 작업 (권장)

```
plan_task → analyze_task → reflect_task → split_tasks → execute_task(반복) → verify_task → complete_task
```

---

## 툴 레퍼런스

### 계획 단계

| 툴             | 설명                        | 언제 쓰나            |
| -------------- | --------------------------- | -------------------- |
| `plan_task`    | 요구사항 분석, 범위 파악    | 작업 시작 시 항상    |
| `analyze_task` | 기존 코드 확인, 중복 방지   | 코드베이스가 있을 때 |
| `reflect_task` | 분석 결과 재검토, 누락 보완 | 복잡한 작업 전       |

### 실행 단계

| 툴              | 설명                        | 언제 쓰나              |
| --------------- | --------------------------- | ---------------------- |
| `split_tasks`   | 큰 작업을 서브태스크로 분해 | 작업이 2단계 이상일 때 |
| `execute_task`  | 특정 태스크 실행            | 각 서브태스크마다      |
| `verify_task`   | 완료 여부 검증              | execute 후             |
| `complete_task` | 완료 처리 + 요약 자동 저장  | verify 통과 후         |

### 관리

| 툴                | 설명                          |
| ----------------- | ----------------------------- |
| `list_tasks`      | 전체 태스크 목록 및 상태 조회 |
| `query_task`      | 키워드로 과거 태스크 검색     |
| `get_task_detail` | 특정 태스크 상세 내용 확인    |
| `delete_task`     | 미완료 태스크 삭제            |

---

## 주의사항

- `DATA_DIR`은 반드시 절대경로로 설정 (상대경로 불가)
- 완료된 태스크는 삭제 불가 — 메모리로 영구 보존됨
- `split_tasks` 시 의존성 순서 명확히 지정 (Design -> Backend -> Frontend 순서 권장)
- 태스크가 너무 크면 vibe coding 품질 저하 — 과감하게 쪼갤 것
