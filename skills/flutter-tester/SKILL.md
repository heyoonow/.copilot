---
name: flutter-tester
description: "Flutter 앱의 전체 테스트 시나리오를 설계하고, 실제 사용자가 버튼을 누르고 화면을 이동하는 방식 그대로 E2E 테스트를 실행하여 버그를 찾고, docs/TEST_REPORT.md에 타임스탬프와 함께 덮어씌워 문서화하는 스킬. Flutter 앱 테스트, 버그 리포트, QA 자동화, 테스트 시나리오 작성, 기능 수정 후 회귀 테스트가 필요할 때 반드시 이 스킬을 사용한다. '테스트 해줘', '버그 찾아줘', 'QA 해줘', '앱 점검', 'regression test' 같은 말이 나오면 항상 이 스킬을 트리거한다."
---

# Flutter E2E User-Flow Tester

## 이 스킬은 배포 전 마지막 관문이다

통과 = 배포 가능. CRITICAL/HIGH 버그 = 배포 금지.

사람이 손으로 앱을 직접 쓰는 것과 똑같이 테스트한다.
위젯이 트리에 존재하는지 확인하는 것이 아니다.
버튼을 탭하고, 텍스트를 입력하고, 저장하고, 목록에서 실제로 보이는지 확인한다.
그 사이에 크래시, 빈 화면, 잘못된 데이터, 누락된 피드백을 하나도 빠뜨리지 않는다.

---

## 참조 문서 — 전부 읽는다 (건너뛰기 없음)

배포 관문이므로 조건부 로딩 없이 전부 읽는다.

| 파일 | 내용 |
|------|------|
| `./scenarios.md` | 시나리오 ID 체계 + 전체 시나리오 목록 + 버그 등급 기준 |
| `./app_test.md` | app_test.dart 전체 패턴 (Provider / DB / Logic 단위) |
| `./ui_test.md` | ui_test.dart 전체 패턴 (앱 부팅 후 실제 E2E) |
| `./report.md` | TEST_REPORT.md 작성법 + 완성 템플릿 |
| `./troubleshooting.md` | 실전 검증된 에러 패턴 + 즉시 적용 해결책 |

---

## 테스트 7단계

```
STEP 1  앱 구조 파악           → 화면 목록, 라우팅, 상태관리, API 여부
STEP 2  테스트 환경 셋업       → pubspec, patrol, mock 구성
STEP 3  시나리오 설계          → scenarios.md
STEP 4  app_test.dart 작성     → app_test.md
STEP 5  ui_test.dart 작성      → ui_test.md
STEP 6  실기기/시뮬레이터 실행 → 아래 실행 명령어
STEP 7  TEST_REPORT.md 작성    → report.md
```

---

## STEP 1 — 앱 구조 파악

```bash
# 전체 화면 목록
find lib -name "*screen*.dart" -o -name "*page*.dart" | grep -v ".g.dart" | sort

# 전체 dart 파일
find lib -name "*.dart" | grep -v ".g.dart" | sort

# 라우팅 구조
find lib -name "*router*" | xargs cat 2>/dev/null | head -80

# Notifier/Provider 목록
find lib -name "*notifier*.dart" -o -name "*provider*.dart" | grep -v ".g.dart"

# 의존성 확인
cat pubspec.yaml

# 기존 테스트 파일
find integration_test test -name "*.dart" 2>/dev/null
```

파악 후 결정:
- 모든 화면과 주요 인터랙션 목록
- GoRouter/Navigator → 화면 전환 방식
- Riverpod/Bloc → mock 전략
- Supabase/Firebase → 실호출 여부 → mockApiClient 필요 여부

---

## STEP 2 — 테스트 환경 셋업

```yaml
# pubspec.yaml dev_dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  patrol: ^3.0.0             # 네이티브 제스처, 시스템 팝업
  mocktail: ^1.0.0           # API mock
  network_image_mock: ^2.1.1 # CachedNetworkImage 에러 방지
```

```bash
fvm flutter pub get
dart run patrol_cli:main bootstrap
```

파일 구조:
```
integration_test/
├── app_test.dart   ← Provider/DB/Logic 단위
└── ui_test.dart    ← 앱 부팅 후 E2E 인터랙션
```

---

## STEP 6 — 테스트 실행

```bash
# ① 반드시 먼저 디바이스 확인
fvm flutter devices

# ② 실기기/시뮬레이터가 있으면 무조건 -d 옵션 (절대 생략 금지)
fvm flutter test integration_test/app_test.dart -d <deviceId>
fvm flutter test integration_test/ui_test.dart -d <deviceId>

# ③ Android + iOS 양쪽 모두 실행 (한쪽만 통과는 의미없다)
fvm flutter test integration_test/ -d <android_id>
fvm flutter test integration_test/ -d <ios_simulator_id>

# ④ 특정 시나리오만 (디버깅 시)
fvm flutter test integration_test/ -d <deviceId> --name "T-CORE"

# ⑤ 상세 로그 (실패 원인 파악)
fvm flutter test integration_test/ -d <deviceId> --reporter expanded

# iOS 빌드 폴더 충돌 시
rm -rf build/ios
fvm flutter test integration_test/ -d <ios_simulator_id>
```

> 절대 원칙: 디바이스가 잡히면 무조건 실기기 실행. 디바이스 없을 때만 로컬 폴백.

---

## 핵심 원칙

| ❌ 하지 말 것 | ✅ 이렇게 |
|--------------|----------|
| `findsOneWidget`으로 화면 전환 확인 | 전환 후 실제 보이는 텍스트로 확인 |
| `pump()` 한 번만 호출 | `pumpAndSettle()` + timeout 설정 |
| 위젯 타입으로만 검증 | `find.text()`, `find.byKey()` 사용 |
| 저장 버튼 탭만 확인 | 저장 후 목록에서 실제 텍스트 검증 (절대 빠뜨리지 않는다) |
| 해피패스만 테스트 | 에러/빈 상태/오프라인 반드시 포함 |
| 실제 API 사용 | mock으로 제어 |
| testWidgets 여러 개 분리 | 하나의 testWidgets 안에 순서대로 |
| 텍스트로 버튼 찾기 (다국어 앱) | `find.byKey()` 사용 |
| Android만 테스트 | Android + iOS 양쪽 모두 |

---

## Widget Key 네이밍 규칙

```
형식: '<화면약어>_<타입>_<용도>'

home_btn_add          홈 추가 버튼
form_field_title      폼 제목 입력 필드
list_item_0           리스트 첫 아이템
detail_btn_save       상세 저장 버튼
dialog_btn_confirm    다이얼로그 확인
dialog_btn_cancel     다이얼로그 취소
tab_home / tab_search 하단 탭
nav_back              뒤로가기
```

---

## 실행 체크리스트

```
[ ] STEP 1  화면 목록 + 인터랙션 전체 파악
[ ] STEP 2  pubspec 추가 + pub get + patrol bootstrap
[ ] STEP 3  시나리오 전체 설계 (T-AUTH ~ T-PERF 포함)
[ ] STEP 4  app_test.dart 작성 (Provider 단위 + DB + 반복 성능)
[ ] STEP 5  ui_test.dart 작성 (앱 부팅 + 전체 E2E)
[ ] STEP 5  모든 인터랙션 요소에 Key 부여 확인
[ ] STEP 6  Android 실행 + 통과 확인
[ ] STEP 6  iOS 시뮬레이터 실행 + 통과 확인
[ ] STEP 7  docs/TEST_REPORT.md 덮어쓰기 (타임스탬프 포함)
[ ] STEP 7  CRITICAL 0건 + HIGH 0건 확인 후 배포 승인
```
