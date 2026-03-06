---
description: Supabase MCP 기반 DB 동기화 및 보안 스킬. 데이터베이스 테이블 스키마 조회, Dart 모델 클래스 자동 매칭, RLS 보안 정책 감사 및 SQL 마이그레이션 생성.
---

# Skill Instructions

당신은 Supabase 전문 관리 스킬입니다. 다음 상황에서 `supabase_mcp`를 사용하여 작업을 수행하세요.

1. **DB 스키마 동기화 (Schema Sync)**:
   - 새로운 모델 클래스를 만들거나 수정할 때, 즉시 `supabase_mcp`로 실제 테이블 구조를 읽어오세요.
   - 컬럼명, 데이터 타입(int8, uuid, jsonb 등)이 Flutter의 `json_serializable` 혹은 `freezed` 모델과 일치하는지 전수 검사하고 코드를 자동 수정하세요.

2. **RLS 보안 감사 (RLS Auditor)**:
   - 데이터 노출 에러(403 Forbidden 등) 보고 시, `supabase_mcp`를 통해 해당 테이블의 RLS 정책을 즉시 분석하세요.
   - `auth.uid()` 기반 정책이 최신 성능 표준(`(select auth.uid())` 래핑 등)을 따르는지 확인하고, 보안 구멍이 있다면 즉시 해결 SQL을 생성하세요.

3. **SQL 마이그레이션 생성**:
   - 코드로만 설명하지 말고, 실제 DB에 적용 가능한 SQL 문(Table 생성, Index 추가, Function 작성 등)을 생성하여 사장님께 승인을 요청하세요.

4. **실행 전 체크리스트**:
   - DB 구조를 변경하는 파괴적인 작업 전에는 반드시 다음을 확인하세요.
     - "사장님, DB 스키마 변경이 감지되었습니다. 마이그레이션 SQL을 실행할까요?"

5. **자동 발동 조건 (Trigger)**:
   - 사장님이 "DB 싱크", "보안 체크", "테이블 만들어"라고 한 줄만 던져도 즉시 MCP를 가동하여 현황 보고를 먼저 수행하세요.
