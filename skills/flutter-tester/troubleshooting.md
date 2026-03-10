# Troubleshooting Reference

실전 테스트 세션에서 실제로 발생한 에러들과 즉시 적용 가능한 해결책.

---

## 1. iOS 시뮬레이터 빌드 폴더 권한 충돌

**증상**
```
Failed to delete '/path/to/build/ios/Debug-iphonesimulator': 
PathAccessException: Cannot delete file
```

**원인**: Xcode로 먼저 빌드한 폴더를 flutter가 덮어쓰려 할 때 발생.

**즉시 해결**
```bash
rm -rf build/ios
fvm flutter test integration_test/ -d <iOS_simulator_id>
```

---

## 2. OS 권한 팝업이 테스트를 막음

**증상**: 알림/카메라/위치 권한 요청 팝업이 뜨면서 `pumpAndSettle` timeout.

**해결책 1 — patrol로 시스템 팝업 처리**
```dart
// patrol 사용 시 (권장)
await $.native.grantPermissionWhenInUse();
// 또는
await $.native.denyPermission();
```

**해결책 2 — 시뮬레이터 권한 미리 허용**
```bash
# 알림 권한 미리 허용
xcrun simctl privacy booted grant notifications com.your.bundleid

# 카메라 권한 미리 허용
xcrun simctl privacy booted grant camera com.your.bundleid

# 모든 권한 초기화 (클린 테스트 시)
xcrun simctl privacy booted reset all com.your.bundleid
```

**해결책 3 — 권한 요청 코드 mock으로 bypass**
```dart
// 테스트 환경에서 권한 요청을 건너뜀
// app_providers.dart에서 isTestMode 플래그로 분기
```

---

## 3. pumpAndSettle이 영원히 끝나지 않음

**증상**: 테스트가 `pumpAndSettle` 에서 멈추고 timeout.

**원인 1 — 무한 애니메이션 (로딩 스피너)**
```dart
// CircularProgressIndicator가 돌고 있으면 pumpAndSettle이 끝나지 않음
// 해결: pump을 여러 번 호출
await tester.pump(const Duration(milliseconds: 500));
await tester.pump(const Duration(milliseconds: 500));
await tester.pump(const Duration(milliseconds: 500));
// pumpAndSettle 대신 pump 여러 번
```

**원인 2 — 비동기 작업이 계속 진행 중**
```dart
// 충분한 timeout 설정
await tester.pumpAndSettle(const Duration(seconds: 10));
```

**원인 3 — 권한 팝업** → 위 2번 해결책 참조

---

## 4. ListView 안에서 렌더 에러

**증상**: `RenderFlex children have non-zero flex but incoming height constraints are unbounded`

**테스트에서 강제 화면 크기 지정**
```dart
await tester.binding.setSurfaceSize(const Size(400, 800));
addTearDown(() => tester.binding.setSurfaceSize(null));
```

**근본 원인 — 소스 코드 수정**
```dart
// ❌ Column 안에 unbounded ListView
Column(
  children: [
    ListView(...) // 높이 모름
  ],
)

// ✅ Expanded로 감싸기
Column(
  children: [
    Expanded(
      child: ListView(...),
    ),
  ],
)
```

---

## 5. Dialog 안 TextEditingController 값이 저장 안 됨

**증상**: Dialog에서 텍스트 입력 후 저장 버튼 눌러도 빈 값 저장.

**테스트로 정확히 잡는 법**
```dart
await tester.tap(find.byKey(const Key('edit_btn')));
await tester.pumpAndSettle();

// Dialog 안 필드에 입력
await tester.enterText(find.byKey(const Key('dialog_field_title')), '테스트 입력값');
await tester.pump(const Duration(milliseconds: 200)); // 입력 반영 대기

await tester.tap(find.byKey(const Key('dialog_btn_confirm')));
await tester.pumpAndSettle(const Duration(seconds: 3));

// ✅ 저장 후 목록에서 실제 값 검증 — 이게 없으면 버그 못 잡음
expect(find.text('테스트 입력값'), findsAtLeastNWidgets(1),
  reason: 'Dialog 입력 후 저장된 값이 목록에 보여야 함');
```

**근본 원인 분석**
- `showDialog` 내부에서 controller가 매번 새로 생성
- `ref` 참조 시점 문제
- `StatefulBuilder` 없이 Dialog 작성 → 상태 없음

---

## 6. iOS가 Android보다 훨씬 느림

**증상**: Android에서는 통과, iOS에서 timeout.

```dart
import 'package:flutter/foundation.dart';

// 플랫폼별 timeout 분기
final timeout = defaultTargetPlatform == TargetPlatform.iOS
    ? const Duration(seconds: 10)
    : const Duration(seconds: 3);

await tester.pumpAndSettle(timeout);
```

---

## 7. 테스트 순서 의존성 — 전체 실행 시 실패

**증상**: 개별 실행 → 통과, 전체 실행 → 실패.

**원인**: 이전 테스트의 로컬 DB / SharedPreferences 상태 오염.

```dart
setUp(() async {
  // SharedPreferences 초기화
  SharedPreferences.setMockInitialValues({});

  // 로컬 DB 초기화 (Hive 예시)
  // await Hive.deleteFromDisk();
  // await Hive.initFlutter('test_hive');
});

tearDown(() async {
  // 각 테스트 후 ProviderContainer dispose 반드시
  container.dispose();
});
```

---

## 8. find.byKey()로 못 찾음

**증상**: `find.byKey(const Key('some_key'))` → `findsNothing`.

**원인 1 — Key 부여 안 됨**: 소스에 `key: const Key('some_key')` 추가.

**원인 2 — 화면에 아직 안 그려짐**: `pumpAndSettle` 추가.

**원인 3 — 스크롤 아래에 있음**:
```dart
await tester.scrollUntilVisible(
  find.byKey(const Key('some_key')),
  200,
  scrollable: find.byType(Scrollable).first,
);
```

**원인 4 — 조건부 렌더링으로 위젯이 숨어있음**:
```dart
// Visibility / Opacity / Offstage 체크
// 또는 find.byKey(key).hitTestable() 사용
```

---

## 9. CachedNetworkImage 에러

**증상**: 네트워크 이미지 로드 실패 에러로 테스트 실패.

```dart
import 'package:network_image_mock/network_image_mock.dart';

testWidgets('테스트', (tester) async {
  // 전체 테스트를 mockNetworkImagesFor로 감싸기
  await mockNetworkImagesFor(() async {
    // 여기서 테스트 실행
  });
});
```

---

## 10. NavigationBar 탭 찾기 실패

**증상**: `find.byIcon(Icons.home)` 여러 개 충돌.

```dart
// ❌ 외부 아이콘과 충돌
await tester.tap(find.byIcon(Icons.home));

// ✅ NavigationBar 안에서만 찾기
await tester.tap(
  find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(Icons.home),
  ).first,
);
```

---

## 11. 비동기 Provider 초기화 전 테스트 실행

**증상**: `ProviderContainer` 생성 직후 상태 접근 → 아직 초기화 중.

```dart
// ❌ 초기화 기다리지 않음
final state = container.read(featureNotifierProvider);
expect(state.valueOrNull, isNotNull); // 아직 loading 중

// ✅ future로 완료 대기
await container.read(featureNotifierProvider.future);
final state = container.read(featureNotifierProvider);
expect(state.valueOrNull, isNotNull);
```

---

## 12. 앱 부팅 타임아웃 (Firebase/Supabase 초기화 느릴 때)

```dart
// ❌ pumpAndSettle만으로 초기화 대기 불가
await tester.pumpAndSettle();

// ✅ NavigationBar 뜰 때까지 루프 폴링
Future<void> _bootApp(WidgetTester tester) async {
  app.main();
  for (int i = 0; i < 60; i++) {  // 최대 30초 (0.5초 * 60)
    await tester.pump(const Duration(milliseconds: 500));
    if (tester.any(find.byType(NavigationBar))) break;
    if (i == 59) {
      fail('앱 부팅 30초 초과 — NavigationBar 미표시');
    }
  }
  await tester.pumpAndSettle(const Duration(seconds: 3));
}
```

---

## 에러 메시지 → 해결책 빠른 참조

| 에러 메시지 | 원인 | 해결 |
|------------|------|------|
| `pumpAndSettle timed out` | 무한 애니메이션 or 권한 팝업 | pump 여러 번 or 권한 미리 허용 |
| `Cannot delete file build/ios` | Xcode 빌드 폴더 충돌 | `rm -rf build/ios` |
| `FlutterError: No Material widget found` | MaterialApp 외부에서 위젯 사용 | 테스트 앱 래핑 확인 |
| `Finder found nothing` | Key 없음 or 미렌더링 | Key 부여 or scrollUntilVisible |
| `Already disposed` | ProviderContainer 이중 dispose | tearDown에서 1회만 |
| `image_picker` error in test | 카메라 플러그인 테스트 환경 미지원 | mock으로 bypass |
| `setState after dispose` | 비동기 완료 시점에 위젯 사라짐 | mounted 확인 or Riverpod 사용 |
