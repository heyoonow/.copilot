# App_FlashReact DB 스키마

> **DB ID:** `App_FlashReact`  
> ReactFlash 반응속도 게임 전용 데이터.  
> **앱 식별자:** `reactflash` (Core.apps.$id)

---

## 컬렉션 목록

| 컬렉션 | 설명 |
|---|---|
| `flash_scores` | 유저별 게임타입별 **최고 기록** (1인 1레코드) |
| `flash_players` | 유저 프로필 (닉네임, 국가, 연령대 등) |
| `flash_game_logs` | 플레이 **전체 히스토리** 로그 |

---

## `flash_scores` — 최고 기록

> 유저 × 게임타입 조합으로 UNIQUE. 갱신 시 upsert.

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | Appwrite 문서 ID |
| `user_id` | String(200) | ✅ | Firebase UID |
| `game_type` | String(50) | ✅ | 게임 타입 식별자 |
| `best_ms` | Double | ✅ | 최고 반응속도 (ms, 낮을수록 좋음) |
| `attempt_count` | Integer | ✅ | 총 시도 횟수 |
| `avg_ms` | Double | ❌ | 평균 반응속도 (ms) |
| `first_played_at` | Datetime | ✅ | 최초 플레이 시각 |
| `last_played_at` | Datetime | ✅ | 최근 플레이 시각 |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `user_id_game_type_unique` (UNIQUE), `idx_deleted_at`

**Dart 모델:** `FlashScore` — `lib/data/models/flash_score.dart`

---

## `flash_players` — 유저 프로필

> `user_id` 1명당 1레코드. `nickname` UNIQUE.

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | Appwrite 문서 ID |
| `user_id` | String(200) | ✅ | Firebase UID |
| `nickname` | String(50) | ✅ | 닉네임 (UNIQUE) |
| `country_code` | String(10) | ❌ | 국가 코드 (예: `KR`) |
| `age_group` | String(10) | ❌ | 연령대 (예: `20s`) |
| `gender` | String(5) | ❌ | 성별 (`M` / `F`) |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `nickname_idx` (UNIQUE), `idx_deleted_at`

**Dart 모델:** `FlashPlayer` — `lib/data/models/flash_player.dart`

---

## `flash_game_logs` — 플레이 히스토리

> 매 플레이마다 기록. 전체 이력 보존.

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | Appwrite 문서 ID |
| `user_id` | String(200) | ✅ | Firebase UID |
| `game_type` | String(50) | ✅ | 게임 타입 식별자 |
| `log_type` | Enum | ✅ | `play` `new_best` `false_start` `timeout` |
| `score_ms` | Double | ❌ | 반응속도 (ms). false_start/timeout 시 null |
| `is_new_best` | Boolean | ❌ | 최고 기록 갱신 여부 (default: false) |
| `session_id` | String(100) | ❌ | 세션 식별자 |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `user_id_idx`, `log_type_idx`, `idx_deleted_at`

---

## 공통 규칙

- 모든 조회에 `Query.isNull('deleted_at')` 필수
- 삭제 시 `deleted_at` 업데이트 (하드 삭제 금지)
- `$updatedAt` 는 Appwrite 자동 관리 (`FlashScore.updatedAt` 매핑)

