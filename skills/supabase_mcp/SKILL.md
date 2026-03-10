---
name: supabase
description: "Supabase MCP 기반 DB 동기화 및 보안 스킬. 데이터베이스 테이블 스키마 조회, Dart 모델 클래스 자동 매칭, RLS 보안 정책 감사 및 SQL 마이그레이션 생성. 'DB 싱크', '보안 체크', '테이블 만들어', 'RLS 확인', '403 에러' 등의 키워드에 즉시 발동."
---

# Supabase MCP 관리 스킬

> 추측하지 않는다. `supabase_mcp`로 실제 DB 상태를 먼저 읽고, 그 다음에 말한다.

---

## 핵심 원칙

- **코드보다 DB가 먼저다** — 모델 작성 전 반드시 실제 테이블 스키마를 읽어올 것
- **SQL은 항상 생성까지만** — 파괴적 변경은 대표님 승인 후 적용
- **현황 보고 → 문제 진단 → 해결 SQL 제시** 순서를 반드시 지킬 것
- **가정하지 말 것** — 컬럼 타입, RLS 정책, 인덱스 유무는 항상 MCP로 직접 확인

---

## 자동 발동 트리거

아래 키워드가 나오면 즉시 `supabase_mcp`를 가동해 현황 보고를 먼저 수행한다.

| 키워드                                        | 즉시 수행                                        |
| --------------------------------------------- | ------------------------------------------------ |
| "DB 싱크", "스키마 맞춰", "모델 맞춰줘"       | 해당 테이블 스키마 조회 후 Dart 모델과 전수 비교 |
| "보안 체크", "RLS 확인", "권한 봐줘"          | 전체 테이블 RLS 정책 조회 후 감사 보고           |
| "테이블 만들어", "컬럼 추가해", "인덱스 걸어" | 현재 스키마 확인 후 마이그레이션 SQL 생성        |
| "403", "Forbidden", "권한 없음 에러"          | 해당 테이블 RLS 정책 즉시 분석                   |
| "함수 만들어", "Function 추가"                | 기존 Function 목록 조회 후 SQL 생성              |

---

## 1. DB 스키마 동기화 (Schema Sync)

### 언제

Dart 모델 클래스 신규 생성 / 수정 / 에러 발생 시

### 수행 순서

1. `supabase_mcp`로 해당 테이블 실제 스키마 조회
2. 컬럼명 / 데이터 타입 전수 비교

   | Supabase 타입   | Dart 타입              | 주의사항                       |
   | --------------- | ---------------------- | ------------------------------ |
   | `uuid`          | `String`               | `UuidConverter` 필요 여부 확인 |
   | `int8 / bigint` | `int`                  | overflow 주의                  |
   | `jsonb`         | `Map<String, dynamic>` | `JsonConverter` 필요           |
   | `timestamptz`   | `DateTime`             | timezone 처리 확인             |
   | `text[]`        | `List<String>`         | `json_serializable` 설정 확인  |

3. 불일치 항목 목록화 후 코드 자동 수정
4. `json_serializable` / `freezed` 어노테이션 정합성 최종 확인

### 보고 형식

```
✅ 일치: id (uuid → String), created_at (timestamptz → DateTime)
⚠️ 불일치: score (int8 → double로 선언됨) → int로 수정 필요
❌ 누락: deleted_at 컬럼이 모델에 없음 → 추가 필요
```

---

## 2. RLS 보안 감사 (RLS Auditor)

### 언제

403 에러, 데이터 노출 이슈, 신규 테이블 생성 후, 정기 보안 점검 시

### 수행 순서

1. `supabase_mcp`로 해당 테이블 RLS 활성화 여부 확인
2. 정책별 `USING` / `WITH CHECK` 조건 분석
3. 아래 기준으로 문제 항목 탐지

**체크 항목:**

```
□ RLS 자체가 비활성화된 테이블은 없는가
□ auth.uid() 직접 호출 → (select auth.uid()) 래핑으로 교체되었는가  (성능 기준)
□ SELECT 정책 없이 INSERT만 있는 테이블은 없는가
□ anon role에 과도한 권한이 부여된 테이블은 없는가
□ service_role 우회가 의도된 것인지 확인
```

4. 문제 발견 시 즉시 수정 SQL 생성 (적용은 대표님 승인 후)

**성능 기준 예시:**

```sql
-- ❌ 기존 (매 row마다 auth.uid() 함수 호출)
USING (user_id = auth.uid())

-- ✅ 권장 (서브쿼리로 1회만 호출)
USING (user_id = (select auth.uid()))
```

---

## 3. SQL 마이그레이션 생성

### 원칙

- 코드로 설명하지 않는다. 실제 실행 가능한 SQL을 생성한다.
- 생성 후 반드시 대표님 승인 요청 → 승인 시 `supabase_mcp`로 적용

### 생성 가능한 SQL 유형

```
- CREATE TABLE (컬럼 타입, NOT NULL, DEFAULT 포함)
- ALTER TABLE (컬럼 추가 / 수정 / 삭제)
- CREATE INDEX / DROP INDEX
- CREATE OR REPLACE FUNCTION
- RLS ENABLE / POLICY 추가 / 수정
- TRIGGER 생성
```

### 마이그레이션 SQL 형식

```sql
-- Migration: [작업명]
-- Date: YYYY-MM-DD
-- Description: 무엇을 왜 변경하는가

-- [실행 가능한 SQL]

-- Rollback:
-- [되돌리는 SQL]
```

> Rollback SQL을 항상 함께 제공한다. 되돌릴 수 없는 작업(DROP 등)은 반드시 명시.

---

## 4. 파괴적 작업 전 체크리스트

아래에 해당하는 작업은 반드시 대표님 승인을 먼저 받는다.

```
□ DROP TABLE / DROP COLUMN
□ 기존 컬럼 타입 변경 (ALTER COLUMN TYPE)
□ RLS 정책 삭제 또는 비활성화
□ 대량 데이터에 영향을 주는 UPDATE / DELETE
□ Index 삭제 (성능 저하 가능)
```

승인 요청 멘트:

> "대표님, [작업명] 작업은 기존 데이터에 영향을 줄 수 있습니다. 마이그레이션 SQL을 확인해 주시고 승인해 주시면 적용하겠습니다."

---

## 자주 발생하는 문제 & 즉시 처방

| 증상                  | 원인                              | 처방 SQL                                                             |
| --------------------- | --------------------------------- | -------------------------------------------------------------------- |
| 403 Forbidden         | RLS 정책 누락 또는 user_id 불일치 | `SELECT * FROM pg_policies WHERE tablename = '[table]'` 로 정책 확인 |
| INSERT 후 빈 응답     | RLS SELECT 정책 없음              | SELECT 정책 추가                                                     |
| 쿼리 느림             | `auth.uid()` 직접 호출            | `(select auth.uid())` 래핑으로 교체                                  |
| 모델 파싱 에러        | Dart 타입 ↔ DB 타입 불일치        | Schema Sync 수행                                                     |
| anon 유저 데이터 접근 | anon role 정책 과다 허용          | RLS 감사 후 정책 축소                                                |
