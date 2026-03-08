---
name: flutter-tester
description: Flutter 앱의 전체 테스트 시나리오를 설계하고, 실제 사용자가 버튼을 누르고 화면을 이동하는 방식 그대로 E2E 테스트를 실행하여 버그를 찾고, docs/TEST_REPORT.md에 타임스탬프와 함께 덮어씌워 문서화하는 스킬. Flutter 앱 테스트, 버그 리포트, QA 자동화, 테스트 시나리오 작성, 기능 수정 후 회귀 테스트가 필요할 때 반드시 이 스킬을 사용할 것. "테스트 해줘", "버그 찾아줘", "QA 해줘", "앱 점검", "regression test" 같은 말이 나오면 항상 이 스킬을 트리거할 것.
---

# Flutter E2E User-Flow Tester Skill

Flutter 앱의 **실제 사용자 행동을 그대로 시뮬레이션**하는 E2E 테스트를 작성한다.
위젯 존재 여부 확인(X) → 버튼 탭 → 로딩 → 결과 화면 확인(O)

---

## ❌ 이전 방식의 문제점 (하지 말 것)

```dart
// 나쁜 예: 위젯이 트리에 '존재'하는지만 확인 → 실제 동작과 무관
expect($(#homeScreen), findsOneWidget);
expect(find.text('완료'), findsOneWidget);

// 나쁜 예: pumpAndSettle 없이 바로 단언 → 비동기 처리 못 기다림
await $(#loginButton).tap();
expect(find.byType(HomePage), findsOneWidget); // 타이밍 이슈
```

---

## ✅ 올바른 E2E 테스트 원칙

### 1. 실제 사용자 흐름 전체를 하나의 시나리오로

```
앱 시작 → 스플래시 → 로그인 화면 → 이메일/비번 입력 →
버튼 탭 → 로딩 스피너 표시 → API 응답 대기 →
홈 화면 이동 → 데이터 렌더링 확인
```

중간 어느 단계에서 끊겨도 테스트가 잡아야 한다.

### 2. 탭/스와이프/스크롤은 실제 제스처로

```dart
// 좋은 예: 실제 사용자처럼 탭
await tester.tap(find.byKey(const Key('loginButton')));
await tester.pumpAndSettle(); // 애니메이션 + 비동기 완전히 끝날 때까지 대기

// 좋은 예: 스크롤해서 요소 찾기
await tester.scrollUntilVisible(
  find.text('더 보기'),
  500,
  scrollable: find.byType(ListView),
);
await tester.tap(find.text('더 보기'));
await tester.pumpAndSettle();
```

### 3. 텍스트 입력은 반드시 enterText() 사용 + 저장 후 결과 데이터까지 검증

```dart
// ❌ 나쁜 예: 그냥 저장 버튼만 탭 — 실제로 저장됐는지 모름
await tester.tap(find.byKey(Key('saveBtn')));

// ✅ 좋은 예: enterText로 실제 입력 → 저장 → 결과 화면에서 해당 텍스트 확인
await tester.enterText(find.byKey(Key('titleField')), '아침 운동');
await tester.pumpAndSettle();
await tester.tap(find.byKey(Key('saveBtn')));
await tester.pumpAndSettle();
// 저장 후 목록 화면에서 실제 데이터 검증
expect(find.text('아침 운동'), findsAtLeastNWidgets(1));
```

### 4. 보이는 텍스트/상태로 결과 검증

```dart
// 좋은 예: 사용자가 실제로 보는 텍스트로 검증
expect(find.text('홈'), findsOneWidget);
expect(find.text('로그인 실패. 이메일을 확인해주세요'), findsOneWidget);

// 좋은 예: 버튼 비활성화 상태 확인
final button = tester.widget<ElevatedButton>(find.byKey(Key('submitBtn')));
expect(button.onPressed, isNull); // 비활성화면 null
```

### 5. 반복 인터랙션으로 누적 버그 잡기

```dart
// 같은 동작 N회 반복 — 리스너 누적, 메모리 누수, 상태 꼬임 등 잡힘
for (int i = 1; i <= 5; i++) {
  await tester.tap(find.byKey(Key('editBtn')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(Key('titleField')), '제목 $i');
  await tester.tap(find.byKey(Key('confirmBtn')));
  await tester.pumpAndSettle();
}
// 마지막 상태가 정확한지 검증
expect(find.text('제목 5'), findsOneWidget);
```

### 6. 네트워크 응답 대기를 명시적으로

```dart
// 좋은 예: 로딩 후 결과 검증
await tester.tap(find.byKey(Key('fetchButton')));
await tester.pump(); // 로딩 시작
expect(find.byType(CircularProgressIndicator), findsOneWidget); // 로딩 중
await tester.pumpAndSettle(const Duration(seconds: 5)); // 완료까지 대기
expect(find.byType(CircularProgressIndicator), findsNothing); // 로딩 끝
expect(find.byType(ListView), findsOneWidget); // 데이터 표시
```

---

## Step 1: 앱 구조 파악

```bash
find . -name "*.dart" | grep -v ".dart_tool" | grep -v "test" | head -60
cat pubspec.yaml
cat lib/main.dart
ls lib/screens/ lib/pages/ lib/features/ 2>/dev/null
```

파악할 것:

- 전체 화면 목록과 각 화면의 주요 인터랙션
- 라우팅 구조 (GoRouter, Navigator 등)
- 상태관리 (Provider, Riverpod, Bloc 등) → mock 전략 결정
- 실제 API 호출 여부 → mockito/mocktail 필요 여부

---

## Step 2: 테스트 툴 설정

### pubspec.yaml 추가

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  patrol: ^3.0.0 # 네이티브 제스처, 권한 처리
  mocktail: ^1.0.0 # API 모킹 (실제 서버 없이 테스트)
  network_image_mock: ^2.1.1 # 이미지 로딩 에러 방지
```

### patrol 초기화

```bash
flutter pub get
dart run patrol_cli:main bootstrap
```

---

## Step 3: 시나리오 설계 — 사용자 행동 기준으로

화면 단위가 아니라 **사용자가 실제로 하는 행동 흐름** 기준으로 설계.

### 시나리오 분류

```
T-AUTH   : 로그인/로그아웃/회원가입/토큰 만료
T-NAV    : 탭바/뒤로가기/딥링크/화면 전환
T-CORE   : 핵심 기능 (앱의 메인 가치)
T-FORM   : 입력 → 제출 → 피드백 전체 흐름
T-NET    : 로딩 → 성공/실패 → 재시도
T-PERM   : 카메라/위치/알림 권한 요청 & 거부
T-EDGE   : 빈 목록, 오프라인, 세션 만료
```

### 시나리오 작성 기준

```
[T-XXX-001] 시나리오 이름
- 사용자 행동: (탭/입력/스와이프 등 구체적 행동)
- 거쳐야 할 화면: A → B → C
- 최종 확인: 사용자가 보게 되는 텍스트/UI 상태
- 실패 시 현상: 어떤 에러가 나야 정상인지
- Priority: Critical / High / Medium
```

---

## Step 4: E2E 테스트 코드 작성

### 파일 구조

```
integration_test/
├── app_test.dart              # 전체 테스트 러너
├── flows/
│   ├── auth_flow_test.dart    # 로그인 전체 흐름
│   ├── core_flow_test.dart    # 핵심 기능 흐름
│   ├── form_flow_test.dart    # 폼 입력 흐름
│   └── error_flow_test.dart   # 에러/엣지케이스
└── helpers/
    ├── app_helper.dart        # 앱 시작 공통 처리
    ├── mock_service.dart      # API 목 설정
    └── finders.dart           # 자주 쓰는 Finder 모음
```

### 실제 사용자 흐름 테스트 예시

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('[T-AUTH] 로그인 전체 흐름', () {

    patrolTest('T-AUTH-001: 이메일+비번 입력 → 로그인 버튼 탭 → 홈 이동', ($) async {
      await $.pumpWidgetAndSettle(const MyApp());

      // 1. 스플래시 끝나고 로그인 화면 진입 확인
      await $.waitUntilVisible($(#loginScreen));

      // 2. 실제 키보드 입력처럼 텍스트 입력
      await $(#emailField).enterText('user@test.com');
      await $.tester.pumpAndSettle();

      await $(#passwordField).enterText('password123');
      await $.tester.pumpAndSettle();

      // 3. 버튼 탭
      await $(#loginButton).tap();
      await $.tester.pump(); // 로딩 시작

      // 4. 로딩 표시 확인 (사용자가 실제로 보는 것)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 5. API 응답 대기 + 화면 전환 완료
      await $.tester.pumpAndSettle(const Duration(seconds: 5));

      // 6. 홈 화면 텍스트로 확인 (위젯 타입이 아닌 실제 보이는 내용)
      expect(find.text('안녕하세요'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    patrolTest('T-AUTH-002: 잘못된 비번 → 에러 메시지 표시 → 입력 유지', ($) async {
      await $.pumpWidgetAndSettle(const MyApp());
      await $.waitUntilVisible($(#loginScreen));

      await $(#emailField).enterText('user@test.com');
      await $(#passwordField).enterText('wrongpassword');
      await $(#loginButton).tap();
      await $.tester.pumpAndSettle(const Duration(seconds: 5));

      // 에러 메시지가 실제로 화면에 보이는지
      expect(find.text('비밀번호가 올바르지 않습니다'), findsOneWidget);

      // 홈으로 이동하지 않았는지
      expect(find.byType(BottomNavigationBar), findsNothing);

      // 이메일 입력값이 유지되는지
      expect(find.text('user@test.com'), findsOneWidget);
    });

    patrolTest('T-AUTH-003: 로그인 후 뒤로가기 → 로그인 화면 복귀 불가', ($) async {
      // 로그인 성공 후
      await _doLogin($, 'user@test.com', 'password123');

      // 뒤로가기 제스처
      await $.tester.pageBack();
      await $.tester.pumpAndSettle();

      // 로그인 화면으로 돌아가면 안 됨
      expect(find.byKey(const Key('loginScreen')), findsNothing);
    });
  });


  group('[T-CORE] 핵심 기능 흐름', () {

    patrolTest('T-CORE-001: 아이템 추가 → 목록에 즉시 반영', ($) async {
      await _doLogin($, 'user@test.com', 'password123');

      // 홈에서 추가 버튼 탭
      await $(#addButton).tap();
      await $.tester.pumpAndSettle();

      // 입력 화면 진입 확인
      expect(find.byKey(const Key('inputScreen')), findsOneWidget);

      // 내용 입력
      await $(#titleField).enterText('새 아이템');
      await $(#saveButton).tap();
      await $.tester.pumpAndSettle(const Duration(seconds: 3));

      // 성공 토스트/스낵바 확인
      expect(find.text('저장되었습니다'), findsOneWidget);

      // 목록으로 돌아와서 새 아이템 보이는지 확인
      await $.tester.pumpAndSettle();
      expect(find.text('새 아이템'), findsOneWidget);
    });

    patrolTest('T-CORE-002: 스크롤해서 더 불러오기 (페이지네이션)', ($) async {
      await _doLogin($, 'user@test.com', 'password123');

      // 리스트 맨 아래까지 스크롤
      await $.tester.scrollUntilVisible(
        find.byKey(const Key('loadMoreIndicator')),
        500,
        scrollable: find.byType(ListView).first,
      );
      await $.tester.pumpAndSettle(const Duration(seconds: 3));

      // 추가 데이터 로드됐는지 확인
      expect(find.byKey(const Key('loadMoreIndicator')), findsNothing);
    });
  });


  group('[T-NET] 네트워크 에러 처리', () {

    patrolTest('T-NET-001: API 실패 → 에러 UI → 재시도 버튼', ($) async {
      // 네트워크 실패 상황 시뮬레이션
      await $.pumpWidgetAndSettle(MyApp(
        apiClient: FailingMockApiClient(), // 항상 실패하는 mock
      ));

      await _doLogin($, 'user@test.com', 'password123');

      // 에러 상태 UI 표시 확인
      expect(find.text('데이터를 불러올 수 없습니다'), findsOneWidget);
      expect(find.byKey(const Key('retryButton')), findsOneWidget);

      // 재시도 버튼 탭 → 다시 로딩 시작
      await $(#retryButton).tap();
      await $.tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });


  group('[T-EDGE] 엣지 케이스', () {

    patrolTest('T-EDGE-001: 빈 목록 상태 표시', ($) async {
      await $.pumpWidgetAndSettle(MyApp(
        apiClient: EmptyDataMockApiClient(),
      ));
      await _doLogin($, 'user@test.com', 'password123');

      expect(find.text('아직 데이터가 없습니다'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    patrolTest('T-EDGE-002: 세션 만료 → 자동 로그아웃 → 로그인 화면', ($) async {
      await $.pumpWidgetAndSettle(MyApp(
        apiClient: SessionExpiredMockApiClient(),
      ));
      await _doLogin($, 'user@test.com', 'password123');

      // 어떤 액션 실행
      await $(#someButton).tap();
      await $.tester.pumpAndSettle(const Duration(seconds: 3));

      // 세션 만료로 자동 로그아웃 → 로그인 화면 복귀
      expect(find.byKey(const Key('loginScreen')), findsOneWidget);
      expect(find.text('세션이 만료되었습니다'), findsOneWidget);
    });
  });
}

// 공통 로그인 헬퍼
Future<void> _doLogin(PatrolIntegrationTester $, String email, String pw) async {
  await $.waitUntilVisible($(#loginScreen));
  await $(#emailField).enterText(email);
  await $(#passwordField).enterText(pw);
  await $(#loginButton).tap();
  await $.tester.pumpAndSettle(const Duration(seconds: 5));
}
```

---

## Step 5: 테스트 실행

```bash
# ① 반드시 먼저 연결된 디바이스 확인
fvm flutter devices

# ② 연결된 실기기/시뮬레이터가 있으면 반드시 -d <deviceId> 붙여서 실행
#    절대 에뮬레이터 없이 로컬 테스트로 때우지 말 것
fvm flutter test integration_test/app_test.dart -d <deviceId>
fvm flutter test integration_test/ui_test.dart -d <deviceId>

# ③ 여러 디바이스가 있으면 Android + iOS 모두 실행
fvm flutter test integration_test/ -d RFCWA19E29M       # Android 실기기
fvm flutter test integration_test/ -d <iOS_simulator_id> # iOS 시뮬레이터

# 특정 시나리오만
fvm flutter test integration_test/ -d <deviceId> --name "T-SW"

# 실패 시 상세 로그
fvm flutter test integration_test/ -d <deviceId> --reporter expanded
```

> **⚠️ 절대 원칙**
> - `fvm flutter devices`에서 디바이스가 잡히면 **무조건 -d 옵션으로 실기기 실행**
> - 디바이스가 없을 때만 로컬 `flutter test`로 폴백
> - iOS 시뮬레이터가 떠 있으면 Android + iOS 양쪽 모두 돌릴 것

---

## Step 6: 버그 판별 기준

| 등급        | 기준                          | 예시                             |
| ----------- | ----------------------------- | -------------------------------- |
| 🔴 CRITICAL | 사용자가 주요 기능 사용 불가  | 로그인 안 됨, 앱 크래시          |
| 🟠 HIGH     | 기능은 동작하지만 결과가 틀림 | 저장은 됐는데 목록 미반영        |
| 🟡 MEDIUM   | UI 피드백 누락                | 로딩 표시 없음, 에러 메시지 없음 |
| 🟢 LOW      | 엣지케이스 미처리             | 빈 목록 UI 없음                  |

---

## Step 7: TEST_REPORT.md 덮어쓰기

`docs/TEST_REPORT.md`를 **항상 새로 덮어쓴다** (docs 폴더 없으면 생성).

```markdown
# Flutter 앱 E2E 테스트 리포트

> 마지막 실행: YYYY-MM-DD HH:mm
> 작성자: Claude (flutter-tester)
> 테스트 환경: Flutter X.X / 에뮬레이터명 또는 실기기명
> 상태: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL

---

## 요약

| 항목             | 수치 |
| ---------------- | ---- |
| 전체 시나리오 수 | N    |
| 통과             | N    |
| 실패             | N    |
| 🔴 CRITICAL      | N    |
| 🟠 HIGH          | N    |

---

## 발견된 버그

### 🔴 CRITICAL

#### BUG-001: [버그 제목]

- **사용자 행동**: 어떤 버튼을 눌렀을 때
- **거친 화면**: 로그인 → 홈 → 상세
- **기대 동작**: 사용자가 봐야 하는 것
- **실제 동작**: 실제로 일어난 것
- **테스트 케이스**: T-XXX-001
- **에러 로그**: (있을 경우)

---

## 전체 시나리오 결과

| ID         | 시나리오         | 결과 | 버그    |
| ---------- | ---------------- | ---- | ------- |
| T-AUTH-001 | 정상 로그인 흐름 | ✅   |         |
| T-AUTH-002 | 잘못된 비번 에러 | ❌   | BUG-001 |

---

## 다음 작업자에게

- [ ] BUG-001 수정 필요
- 수정 후 반드시 `flutter test integration_test/` 전체 PASS 확인
- **테스트 통과 = 위젯 존재 확인이 아니라 사용자 흐름 전체 통과**
```

---

## 실행 체크리스트

```
[ ] 앱 구조 파악 (화면 목록 + 인터랙션)
[ ] pubspec.yaml 의존성 추가 (patrol, mocktail)
[ ] Mock 서비스 구현 (성공/실패/빈 데이터/세션만료)
[ ] 사용자 흐름 기반 시나리오 작성
[ ] integration_test/ 코드 생성
[ ] 실 기기 또는 에뮬레이터에서 실행
[ ] docs/TEST_REPORT.md 덮어쓰기 (타임스탬프 포함)
```

---

## 📁 검증된 integration_test 파일 구조

Flutter 프로젝트에서 실제로 동작이 검증된 2-파일 구조. 새 프로젝트에서도 이 구조를 그대로 따를 것.

```
integration_test/
├── app_test.dart   ← Provider/DB/Logic 단위 테스트 (WidgetTester 없이 순수 Dart)
└── ui_test.dart    ← 실제 앱 부팅 후 사용자 인터랙션 E2E 테스트
```

### app_test.dart 핵심 패턴

Provider/로컬DB/알림 등 로직 계층을 직접 검증. **위젯 펌핑 없이** `ProviderContainer`로 상태를 직접 읽고 쓴다.

```dart
// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── 플러그인 초기화 (테스트 환경 실패 허용) ──────────────────────────────
Future<void> _initPlugin() async {
  try { await SomePlugin().initialize(...); }
  catch (e) { print('[TEST] 플러그인 초기화 실패 (무시): $e'); }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 전체 테스트에서 한 번만 실행
  setUpAll(() async {
    // 1. SharedPreferences
    prefs = await SharedPreferences.getInstance();
    // 2. 전역 변수 세팅 (global_data.dart 등)
    // 3. Firebase (실패 허용)
    try { await Firebase.initializeApp(...); } catch (e) { print(e); }
    // 4. 로컬 DB (프로젝트에서 사용하는 경우만 — Hive, Isar, SQLite 등)
    //    예: await Hive.initFlutter('integration_test_hive');
    // 5. 플러그인
    await _initPlugin();
    // 6. 기존 데이터 초기화 (테스트 오염 방지)
    //    예: await someBox.clear();
  });

  tearDownAll(() async {
    // 로컬 DB 사용 시 닫기
    // 예: await Hive.close();
  });

  group('기능명 Provider', () {
    late ProviderContainer container;

    setUp(() { container = ProviderContainer(); });
    tearDown(() {
      // ⚠️ 진행 중인 타이머/스트림 반드시 정지 후 dispose (안 하면 다음 테스트 오염)
      final state = container.read(someProvider);
      if (state is RunningState) container.read(someProvider.notifier).stop();
      container.dispose();
    });

    test('01. 초기 상태 검증', () {
      final state = container.read(someProvider);
      expect(state, isA<ReadyState>(), reason: '이유를 반드시 명시');
      expect(state.value, 0);
    });

    test('02. 비동기 동작 검증', () async {
      container.read(someProvider.notifier).start();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final state = container.read(someProvider);
      expect(state, isA<RunningState>());
      expect(state.elapsed, greaterThan(0));
    });
  });
}
```

### ui_test.dart 핵심 패턴

실제 앱(`app.main()`)을 부팅해서 사용자가 버튼 누르는 것처럼 테스트.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

// ── 앱 부팅 헬퍼: NavigationBar가 뜰 때까지 폴링 ─────────────────────────
// pumpAndSettle 단독으로는 앱 초기화(Firebase/로컬DB 등)를 못 기다림 → 루프 폴링 사용
Future<void> _bootApp(WidgetTester tester) async {
  app.main();
  for (int i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (tester.any(find.byType(NavigationBar))) break;
  }
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── 탭 이동 헬퍼: NavigationBar의 descendant 아이콘으로 탭 찾기 ───────────
// find.byIcon() 단독은 BottomNav 외 아이콘과 충돌할 수 있음 → descendant 조합
Future<void> _goToSomeTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.someIcon),
    ).first,
  );
  await tester.pumpAndSettle();
}

// ── 다이얼로그 헬퍼: AlertDialog 내부 버튼 last/first로 찾기 ────────────
Future<void> _confirmDialog(WidgetTester tester) async {
  final btn = find
      .descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton))
      .last; // 마지막 = 확인/저장, first = 취소
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

// ── 반복 인터랙션 헬퍼: 자주 쓰는 흐름은 함수로 묶기 ───────────────────
Future<void> _doSomeAction(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('action_btn')));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.byKey(const Key('stop_btn')));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ⚠️ UI 테스트는 시나리오를 하나의 testWidgets 안에 순서대로 넣는다
  // (여러 testWidgets로 나누면 앱 상태가 누적되어 예측 불가)
  testWidgets('🎭 전체 UI 인터랙션 시나리오', (tester) async {
    await _bootApp(tester);

    // 시나리오마다 print로 진행상황 출력 (테스트 실패 시 어디서 죽었는지 파악)
    print('▶ [T-NAV-001] 탭 전환 검증');
    expect(find.byType(NavigationBar), findsOneWidget);
    print('✅ [T-NAV-001] 통과\n');

    print('▶ [T-CORE-001] 핵심 기능 검증');
    await _goToSomeTab(tester);
    // Key 기반으로 버튼 찾기 (텍스트는 다국어 앱에서 깨질 수 있음)
    expect(find.byKey(const Key('start_btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('start_btn')));
    await tester.pump(const Duration(milliseconds: 800));
    // 상태 전환 후 UI 변화 검증
    expect(find.byKey(const Key('stop_btn')), findsOneWidget);
    expect(find.byKey(const Key('start_btn')), findsNothing);
    print('✅ [T-CORE-001] 통과\n');
  });
}
```

### Widget Key 네이밍 규칙

테스트에서 안정적으로 찾으려면 **반드시 Key를 위젯에 부여**해야 한다. 다국어 앱은 텍스트로 찾으면 깨진다.

```
Key 형식: '<화면약어>_<타입>_<액션>'

스톱워치: sw_btn_start / sw_btn_stop / sw_btn_lap / sw_btn_init
타이머:   tm_btn_add / tm_btn_play / tm_btn_delete
다이얼로그: sw_dialog_title_field / tm_dialog_confirm
탭바:     tab_stopwatch / tab_timer / tab_history / tab_setting
```

### 시나리오 ID 체계

```
T-NAV    : 탭 전환 / 화면 이동
T-SW     : 스톱워치 기능
T-TM     : 타이머 기능
T-HIST   : 기록 탭
T-SET    : 설정 탭
T-DB     : DB 영속성 검증
T-NOTIF  : 알림 검증
T-EDGE   : 빈 상태 / 오류 처리
```

| 하지 말 것                          | 대신 이렇게                        |
| ----------------------------------- | ---------------------------------- |
| `findsOneWidget`으로 화면 전환 확인 | 전환 후 실제 보이는 텍스트로 확인  |
| `pump()` 한 번만 호출               | `pumpAndSettle()` + timeout 설정   |
| 위젯 타입으로 검증                  | `find.text()`, `find.byKey()` 사용 |
| 해피패스만 테스트                   | 에러/빈상태/오프라인 필수 포함     |
| 실제 API 사용                       | mock으로 제어 가능한 환경 구성     |
| `waitForTimeout` 하드코딩           | `pumpAndSettle` + 합리적 Duration  |

---

## 🔍 실전 트러블슈팅 노트 (테스트 세션에서 발견)

### ① iOS 시뮬레이터 빌드 폴더 권한 충돌
- **증상**: `flutter test integration_test/` 실행 시 `build/ios/Debug-iphonesimulator` 삭제 권한 에러
- **원인**: Xcode로 먼저 빌드한 폴더를 flutter가 덮어쓰려 할 때 발생
- **해결**: 테스트 전 `rm -rf build/ios` 실행 후 재시도
```bash
rm -rf build/ios
fvm flutter test integration_test/app_test.dart -d <iOS_simulator_id>
```

### ② 알림/권한 팝업이 테스트를 막음
- **증상**: 테스트 중 OS 권한 팝업(알림, 카메라 등)이 뜨면서 `pumpAndSettle` timeout
- **원인**: 실기기/시뮬레이터에서 최초 실행 시 권한 요청 코드가 테스트 흐름과 충돌
- **해결책**:
  1. 테스트 전 시뮬레이터 권한을 미리 허용해두기 (`xcrun simctl privacy booted grant`)
  2. 권한 요청 로직을 mock으로 bypass
  3. 또는 테스트 코드에서 팝업 dismiss 처리:
```dart
// patrol로 시스템 팝업 처리
await $.native.grantPermissionWhenInUse();
// 또는
await $.native.denyPermission();
```

### ③ ListView/Column 안 unbounded height 에러
- **증상**: `RenderFlex children have non-zero flex but incoming height constraints are unbounded`
- **원인**: `Column` 안에 `Expanded` 없이 `ListView` 직접 사용
- **해결**: `SizedBox(height: N)` 또는 `Expanded`로 감싸기, 테스트 코드에서 `tester.binding.setSurfaceSize`로 화면 크기 강제 지정
```dart
// 테스트에서 화면 크기 강제 지정
await tester.binding.setSurfaceSize(const Size(400, 800));
addTearDown(() => tester.binding.setSurfaceSize(null));
```

### ④ Dialog 안 TextEditingController 값 저장 안 됨
- **증상**: Dialog에서 텍스트 입력 후 저장 버튼 눌러도 빈 값 저장
- **원인**: `showDialog` 내부에서 controller가 새로 생성되거나 ref 참조 문제
- **테스트로 잡는 법**:
```dart
// Dialog에서 입력 후 실제 저장값 검증
await tester.tap(find.byKey(Key('editBtn')));
await tester.pumpAndSettle();
await tester.enterText(find.byKey(Key('inputField')), '테스트 입력값');
await tester.tap(find.byKey(Key('saveBtn')));
await tester.pumpAndSettle();
// 저장 후 목록/화면에서 실제 값 검증 (이걸 빠뜨리면 버그 못 잡음)
expect(find.text('테스트 입력값'), findsOneWidget);
```

### ⑤ iOS가 Android보다 pumpAndSettle 훨씬 느림
- **증상**: Android에서는 통과하는 테스트가 iOS에서 timeout
- **해결**: iOS 테스트 시 timeout을 더 길게 잡을 것
```dart
// Android: 3초면 충분
await tester.pumpAndSettle(const Duration(seconds: 3));

// iOS: 최소 5~10초
await tester.pumpAndSettle(const Duration(seconds: 10));
```

### ⑥ 테스트 순서 의존성 주의
- **증상**: 테스트를 개별로 실행하면 통과, 전체 실행하면 실패
- **원인**: 이전 테스트의 상태(로컬DB, SharedPreferences 등)가 다음 테스트에 오염
- **해결**: 각 테스트 그룹에 `setUp`/`tearDown`으로 상태 초기화
```dart
setUp(() async {
  // 로컬 DB 사용 시 클리어 (Hive, Isar, SQLite 등 프로젝트에 맞게)
  // 예: await Hive.deleteFromDisk();
  // SharedPreferences 초기화
  SharedPreferences.setMockInitialValues({});
});
```
