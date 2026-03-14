---
name: appwrite
description: "HEYNOW 생태계 통합 인프라 및 데이터 설계 스킬. Core/App/Web 계층화, 통합 로그 시스템, Appwrite UID 중심 사용자 식별 및 Flutter/Next.js 개발 자동화. 'DB 생성', '컬렉션 추가', '로그 연동', '앱 등록', 'Appwrite' 키워드에 즉시 발동."
---

# HEYNOW Appwrite 스킬

> **핵심 원칙:** "Centralized Identity, Distributed Data"  
> **추측 금지 — MCP 조회 후 작업 시작.**

## 📁 DB별 상세 스키마 — 작업 전 반드시 해당 파일을 읽어라

> ⚠️ 아래 파일들은 작업 대상 DB가 결정되는 즉시 **view 툴로 직접 열어서 읽어야 한다.**  
> 읽지 않고 작업하면 스키마 불일치, 필드 누락 등의 오류가 발생한다.

| 작업 대상 DB | 반드시 읽을 파일 |
|---|---|
| `core` (Core DB) | `/Users/heyoonow/.copilot/skills/appwrite/core_db.md` |
| `App_FlashReact` | `/Users/heyoonow/.copilot/skills/appwrite/app_flashreact_db.md` |

- 신규 DB 추가 시 → `[db_id]_db.md` 파일 생성 후 이 표에 추가

---

> # ‼️‼️‼️ 문서 갱신 규칙 — 절대 빠뜨리지 말 것 ‼️‼️‼️
>
> **DB/컬렉션/필드/인덱스를 추가·수정·삭제한 경우, 작업 완료 후 반드시 해당 스키마 문서를 즉시 업데이트한다.**
>
> | 변경 작업 | 업데이트할 파일 |
> |---|---|
> | Core DB 변경 | `core_db.md` |
> | App_FlashReact 변경 | `app_flashreact_db.md` |
> | 신규 DB 추가 | `[db_id]_db.md` 생성 + SKILL.md 표에 추가 |
> | AppLaunchLogger 변경 | `app_launch_logger.md` + `app_library/docs/APP_LAUNCH_LOGGER_GUIDE.md` |
> | 앱 규칙/공통 규칙 변경 | `SKILL.md` |
>
> **문서 미갱신 = 다음 작업자(또는 나)가 잘못된 정보로 작업하게 됨. 절대 건너뛰지 않는다.**

---

## 🛠️ MCP 환경

- **서버:** `appwrite`
- **서버 주소:** `https://db.heynow.co.kr/v1`
- **Project ID:** `69b28d67001362751f86`

---

## 🏷️ DB 네이밍 규칙

| 접두어 | 대상 | 예시 |
|---|---|---|
| **`Core`** | 전 서비스 공통 | `core` |
| **`App_[Name]`** | Flutter 모바일 | `App_FlashReact` |
| **`Web_[Name]`** | Next.js 웹 | `Web_Admin` |

---

## 📂 컬렉션 네이밍 규칙

### ⚠️ 소문자 snake_case 필수 (예외 없음)

| ❌ 잘못된 예 | ✅ 올바른 예 |
|---|---|
| `Log_Events` | `log_events` |
| `FlashScores` | `flash_scores` |
| `UserProfiles` | `user_profiles` |

### ⚠️ Soft Delete 필수

> **하드 삭제(deleteDocument 호출) 절대 금지.**  
> 삭제 = `deleted_at`에 타임스탬프 업데이트.  
> 모든 컬렉션에 `deleted_at` (datetime, nullable) + `idx_deleted_at` 인덱스 필수.

```dart
// ✅ 삭제
await db.updateDocument(data: {'deleted_at': DateTime.now().toUtc().toIso8601String()});

// ✅ 조회 — 반드시 포함
queries: [Query.isNull('deleted_at'), ...]
```

---

## ⚙️ Flutter 코드 규칙

### AppwriteConstants 구조

```dart
abstract class AppwriteConstants {
  static const String endpoint = 'https://db.heynow.co.kr/v1';
  static const String projectId = '69b28d67001362751f86';

  // Core DB
  static const String coreDbId = 'core';
  static const String colApps = 'apps';
  static const String colLogEvents = 'log_events';
  static const String colAppVisit = 'app_visit';

  // App_FlashReact DB
  static const String flashDbId = 'App_FlashReact';

  // 앱 식별자 (apps.$id와 일치)
  static const String appId = 'reactflash'; // 앱마다 변경
}
```

### 모델 직렬화

```dart
factory MyModel.fromAppwrite(Map<String, dynamic> json) {
  return MyModel(id: json['\$id'] as String, ...);
}

Map<String, dynamic> toAppwrite() => {
  // $id, $createdAt 등 $ 필드 제외
};
```

### Appwrite SDK 주의사항
- `required: true` + `default` 동시 불가
- `import 'package:appwrite/models.dart' as models;` — `models.Document`로 충돌 방지

---

## 👤 사용자 식별

- **Source of Truth:** Firebase Auth UID → `user_id` 필드
- **미로그인:** `user_id = "guest"`

---

## 📋 신규 앱 추가 체크리스트

1. **`Core.apps` 등록** — `$id` = 앱 식별자 (소문자)
2. **`App_[Name]` DB 생성** — PascalCase
3. **컬렉션 생성** — snake_case, `deleted_at` 필수
4. **`[db_id]_db.md` 생성** — 스킬 문서 업데이트
5. **`AppwriteConstants` 업데이트**
6. **`AppLaunchLogger` 연동**
7. **Appwrite 콘솔 플랫폼 등록** (MCP 불가, 콘솔 직접)

---

## 🔄 워크플로우

```
1. listDatabases / listCollections → 현황 파악
2. core_db.md / [app]_db.md → 스키마 확인
3. 설계 → 생성 → 코드 반영
```

---

## ⚠️ 안전 수칙

- **하드 삭제 절대 금지**
- **모든 조회에 `Query.isNull('deleted_at')` 필수**
- **공유 라이브러리(`app_library`) 수정 시 전체 사용처 먼저 확인**

```bash
grep -r "메서드명" /Users/heyoonow/Documents/Source/heynow/app --include="*.dart" -l
```
