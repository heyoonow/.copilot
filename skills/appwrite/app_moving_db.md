# App_Moving DB 스키마

> **DB ID:** `App_Moving`  
> Moving(슬라이드 퍼즐) 게임 전용 데이터.  
> **앱 식별자:** `moving` (Core.apps.$id)

---

## 컬렉션 목록

| 컬렉션 | 설명 |
|---|---|
| `moving_players` | 유저 프로필 (닉네임, 국가코드) |
| `moving_scores` | 유저별 게임타입/모드/레벨 조합별 **최고 기록** (1인 1레코드) |
| `moving_game_logs` | 플레이 **전체 히스토리** 로그 |

---

## `moving_players` — 유저 프로필

> user_id(unique). 첫 실행 시 자동 생성 (닉네임: Puzzle_XXXX, 국가: KR).

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | Appwrite 문서 ID |
| `user_id` | String(200) | ✅ | Firebase UID (unique) |
| `nickname` | String(30) | ✅ | 닉네임 (리더보드 표시용) |
| `country_code` | String(5) | ✅ | ISO 3166-1 alpha-2 (예: KR, US) |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `user_id_unique` (unique)

---

## `moving_scores` — 최고 기록

> 유저 × gameType × gameMode × level 조합으로 UNIQUE. 갱신 시 upsert (duration 더 낮을 때만).

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | Appwrite 문서 ID |
| `user_id` | String(200) | ✅ | Firebase UID or 'guest' |
| `game_type` | String(50) | ✅ | `numeric` 또는 `image` |
| `game_mode` | String(50) | ✅ | `basic`, `rotate`, `hide` |
| `level` | Integer(0~100) | ✅ | 퍼즐 레벨 (타일 수) |
| `duration` | Integer(0~999999999) | ✅ | 완료 시간 (ms, 낮을수록 좋음) |
| `turn` | Integer(0~999999) | ✅ | 이동 횟수 |
| `nickname` | String(30) | ❌ | 비정규화 닉네임 (리더보드 표시용) |
| `country_code` | String(5) | ❌ | 비정규화 국가코드 |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `user_id_idx` (key), `idx_deleted_at` (key)

**Dart 모델:** `MovingScoreModel` — `lib/data/model/m_moving_score.dart`

---

## `moving_game_logs` — 플레이 히스토리

> 모든 완료 기록을 저장 (최고 기록 갱신 여부와 무관).

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | Appwrite 문서 ID |
| `user_id` | String(200) | ✅ | Firebase UID or 'guest' |
| `game_type` | String(50) | ✅ | `numeric` 또는 `image` |
| `game_mode` | String(50) | ✅ | `basic`, `rotate`, `hide` |
| `level` | Integer(0~100) | ✅ | 퍼즐 레벨 |
| `duration` | Integer(0~999999999) | ✅ | 완료 시간 (ms) |
| `turn` | Integer(0~999999) | ✅ | 이동 횟수 |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `user_id_idx` (key), `idx_deleted_at` (key)

---

## 랭킹 계산 방식

```
betterCount = count(game_type==X AND game_mode==Y AND level==Z AND duration < myDuration AND deleted_at==null)
total = count(game_type==X AND game_mode==Y AND level==Z AND deleted_at==null)
rank = betterCount + 1
percentile = ((total - rank + 1) / total * 100).clamp(0.0, 100.0)
```

Appwrite `listDocuments` 응답의 `.total` 필드 활용.

---

## Flutter 상수 참조

```dart
// lib/core/constants/appwrite_constants.dart
AppwriteConstants.movingDbId        // 'App_Moving'
AppwriteConstants.colMovingPlayers  // 'moving_players'
AppwriteConstants.colMovingScores   // 'moving_scores'
AppwriteConstants.colMovingGameLogs // 'moving_game_logs'
```
