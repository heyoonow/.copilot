# App_FlashReact DB 스키마

> **DB ID:** `App_FlashReact`  
> ReactFlash 반응속도 게임 전용 데이터.  
> **앱 식별자:** `reactflash` (Core.apps.$id)

---

> ⚠️ 컬렉션 목록 조회 중 오류로 현재 스키마 미확인 상태.  
> 작업 전 반드시 MCP로 현황 조회: `listCollections(databaseId: 'App_FlashReact')`

---

## 공통 규칙

- 모든 컬렉션에 `deleted_at` datetime nullable + `idx_deleted_at` 인덱스 필수
- 모든 조회에 `Query.isNull('deleted_at')` 필수
- 컬렉션명 소문자 snake_case
