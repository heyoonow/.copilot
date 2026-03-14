# Core DB 스키마

> **DB ID:** `core`  
> 전체 서비스 공통 데이터. 통합 로그, 앱 등록부, 방문 기록.

---

## `apps` — 전체 앱 등록부

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `$id` | String | ✅ | **PK = 앱 식별자** (예: `reactflash`, `stopwatch`) |
| `app_name` | String(100) | ✅ | 앱 표시명 |
| `platform` | String(20) | ❌ | `Flutter`, `Next.js` 등 |
| `description` | String(300) | ❌ | 앱 설명 |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `idx_deleted_at`

**현재 등록 앱:**
| $id | app_name | platform |
|---|---|---|
| `reactflash` | ReactFlash | Flutter |
| `stopwatch` | 스톱워치 | Flutter |

> ⚠️ `app_id` 필드 없음. `$id`가 앱 식별자. 신규 앱은 반드시 여기 먼저 등록.

---

## `log_events` — 통합 에러/인포 로그

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `app_id` | String(50) | ✅ | `apps.$id` 문자열 참조 |
| `user_id` | String(200) | ❌ | Firebase UID |
| `level` | Enum | ✅ | `error` `info` `warning` `debug` |
| `message` | String(2000) | ✅ | 로그 메시지 |
| `tag` | String(100) | ❌ | 태그 |
| `timestamp` | Datetime | ✅ | 발생 시각 |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `level_idx`, `app_id_idx`, `timestamp_idx`, `idx_deleted_at`

---

## `app_visit` — 앱 방문/실행 로그

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `app` | Relationship | ❌ | `apps.$id` ManyToOne FK |
| `user_id` | String(200) | ✅ | Firebase UID |
| `session_id` | String(100) | ❌ | `{timestamp}_{userId해시}` |
| `os_type` | String(20) | ❌ | `Android` / `iOS` |
| `os_version` | String(50) | ❌ | `Android 14` / `iOS 17.2` |
| `app_version` | String(20) | ❌ | `1.2.3` |
| `build_number` | String(20) | ❌ | `100` |
| `locale` | String(20) | ❌ | `ko_KR`, `en_US` |
| `timezone` | String(50) | ❌ | `KST`, `UTC` |
| `device_model` | String(100) | ❌ | `Samsung SM-S911N` |
| `is_first_launch` | Boolean | ❌ | 최초 실행 여부 (default: false) |
| `event_type` | String(30) | ❌ | default: `launch` |
| `app_env` | String(20) | ❌ | `debug` / `profile` / `release` |
| `deleted_at` | Datetime | ❌ | Soft delete |

**인덱스:** `idx_user_id`, `idx_deleted_at`

> 로그 기록: `AppLaunchLogger.logLaunch(appId: 'reactflash', ...)` 사용
