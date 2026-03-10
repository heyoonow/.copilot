---
name: flutter-task
description: "Flutter 앱 개발 작업을 실행한다. 새 화면, 위젯, 기능 구현, 상태관리, UI 개선 등 Flutter 관련 모든 작업 요청에 사용한다. 클린 아키텍처와 디자인 시스템을 반드시 준수하며, 1억 다운로드 앱 수준의 UX와 애니메이션을 기준으로 구현한다."
---

# Flutter Task Executor

## STEP 1 — 참조 문서 로딩 (작업 유형별 필요한 것만 읽는다)

| 작업 유형 | 읽을 파일 | 해당 작업 예시 |
|-----------|-----------|----------------|
| 새 화면 / 위젯 / UI / 애니메이션 / 공통 위젯 | `./design.md` | 화면 구현, 버튼·카드·다이얼로그, 로딩·에러·빈 상태 UI |
| 폴더 구조 / 신규 feature / 아키텍처 / main.dart · app.dart | `./arch.md` | feature 폴더 구성, ThemeData, context extension |
| Android·iOS 차이 / 화면 전환 / 제스처 / 이미지 / 키보드 | `./platform.md` | 뒤로가기, 스와이프, SafeArea, 딥링크 |
| 상태관리 / API / 페이지네이션 / 인증 / 에러처리 / 로컬저장소 | `./patterns.md` | Riverpod Notifier, Supabase CRUD, go_router |

**여러 유형에 해당하면 해당하는 파일 모두 읽는다.**

예시: 새 화면 + Riverpod 연결 → `./design.md` + `./arch.md` + `./patterns.md`
예시: Notifier 추가만 → `./patterns.md`만

---

## STEP 2 — 프로젝트 실제 파일 파악

### 항상 확인 (전체 작업 공통)
```bash
# 폴더 구조 파악
find lib -type d | head -30

# 기존 Provider 목록
find lib -name "*notifier*" -o -name "*provider*" | grep -v ".g.dart"
```

### UI 작업 시 추가 확인
```bash
# 실제 토큰 값 파악 (절대 추측 금지)
cat lib/core/constants/app_colors.dart
cat lib/core/constants/app_typography.dart
cat lib/core/constants/app_values.dart

# 기존 공통 위젯 목록 (재사용 필수)
find lib/core/widgets lib/shared/widgets -name "*.dart" 2>/dev/null

# 비슷한 기존 화면 패턴 참고
find lib/features -name "*screen*.dart" | head -5
```

### 새 Feature 생성 시 추가 확인
```bash
# 기존 feature 구조 참고
ls lib/features/

# router 현재 상태
cat lib/router/app_router.dart

# 공통 Provider 현재 상태
cat lib/core/providers/app_providers.dart 2>/dev/null
```

---

## STEP 3 — 구현 순서

```
Domain (Entity → Repository interface → Usecase)
  ↓
Data (Model → Datasource → Repository 구현체)
  ↓
Presentation (Provider/Notifier → Screen → Widget)
```

Presentation부터 시작하지 않는다. Domain이 없으면 먼저 만든다.

**모델 생성·수정 직후 즉시 실행:**
```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

## STEP 4 — 구현 완료 후 체크리스트

```
□ 색상 하드코딩 없음        (Color(0x...), Colors.blue 등 없는지 grep으로 확인)
□ 텍스트 스타일 하드코딩 없음 (TextStyle(fontSize: ...) 없는지 확인)
□ 간격 하드코딩 없음         (EdgeInsets.all(16) 등 없는지 확인)
□ SafeArea 적용됨
□ 로딩 상태 → Shimmer 처리됨
□ 에러 상태 → 재시도 버튼 포함 처리됨
□ 빈 상태 → AppEmptyState 처리됨
□ 키보드 침범 없음
□ Android·iOS 레이아웃 양쪽 확인
□ 터치 타겟 최소 48×48dp
□ 모델 수정 → build_runner 실행했는지 확인
□ 새 문자열 → assets/translations/ 모든 언어 파일에 추가했는지 확인
□ 새 화면 → router/app_router.dart에 등록했는지 확인
```

---

## 절대 규칙 (하나라도 어기면 처음부터 다시)

| 규칙 | 이유 |
|------|------|
| `fvm flutter` 사용, `flutter` 직접 호출 금지 | fvm 버전 관리 |
| 하드코딩 색상·타이포·간격 금지 | 디자인 시스템 일관성 |
| 새 위젯 전 기존 위젯 확인 필수 | 중복 방지 |
| SafeArea 항상 적용 | 노치·Dynamic Island 대응 |
| 화면 세로 고정 | `DeviceOrientation.portraitUp` |
| `flutter` 직접 호출 금지 | 항상 `fvm flutter` |
| Image.network 금지 | CachedNetworkImage 사용 |
| build_runner 생성 파일 커밋 O | `.g.dart` 파일은 커밋한다 |
