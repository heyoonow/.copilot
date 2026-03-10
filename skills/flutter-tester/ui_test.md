# ui_test.dart Reference

## 역할

실제 앱(`app.main()`)을 부팅하고, 사람이 손으로 쓰는 것처럼
버튼 탭, 텍스트 입력, 스크롤, 화면 전환을 순서대로 실행한다.
저장 후 목록에서 실제 텍스트가 보이는지까지 확인한다.

---

## 핵심 원칙

```
1. 하나의 testWidgets 안에 시나리오를 순서대로 넣는다
   (여러 testWidgets로 나누면 앱 상태 누적 → 예측 불가)

2. 각 시나리오 앞에 print로 진행상황 출력
   (실패 시 어디서 죽었는지 즉시 파악)

3. 저장 → 목록 확인은 절대 빠뜨리지 않는다
   가장 흔한 버그: 저장됐는데 목록에 안 보임

4. pumpAndSettle timeout: Android 3초, iOS 10초

5. 버튼 찾기: find.byKey() 우선
   다국어 앱에서 find.text()는 언어 설정에 따라 깨짐
```

---

## 완성형 ui_test.dart 템플릿

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:your_app/main.dart' as app;

// ── 앱 부팅 헬퍼 ──────────────────────────────────────────────────────────────
// pumpAndSettle 단독으로는 Firebase/로컬DB 초기화를 못 기다림 → 루프 폴링
Future<void> _bootApp(WidgetTester tester) async {
  app.main();

  // NavigationBar(또는 BottomNavigationBar)가 뜰 때까지 최대 30초 대기
  for (int i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (tester.any(find.byType(NavigationBar)) ||
        tester.any(find.byType(BottomNavigationBar))) break;
  }
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── 탭 이동 헬퍼 ──────────────────────────────────────────────────────────────
// NavigationBar descendant로 찾기 — 외부 아이콘과 충돌 방지
Future<void> _tapTab(WidgetTester tester, IconData icon) async {
  final navBar = find.byType(NavigationBar).isNotEmpty
      ? find.byType(NavigationBar)
      : find.byType(BottomNavigationBar);

  await tester.tap(
    find.descendant(
      of: navBar,
      matching: find.byIcon(icon),
    ).first,
  );
  await tester.pumpAndSettle();
}

// ── 다이얼로그 확인 버튼 헬퍼 ─────────────────────────────────────────────────
// AlertDialog 내부 TextButton last = 확인, first = 취소
Future<void> _confirmDialog(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextButton),
    ).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _cancelDialog(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextButton),
    ).first,
  );
  await tester.pumpAndSettle();
}

// ── 스크롤해서 찾기 헬퍼 ──────────────────────────────────────────────────────
Future<void> _scrollToAndTap(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

// ── 텍스트 입력 헬퍼 ──────────────────────────────────────────────────────────
Future<void> _enterAndSettle(
    WidgetTester tester, Finder field, String text) async {
  await tester.tap(field);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

// ════════════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ⚠️ 모든 시나리오를 하나의 testWidgets 안에 순서대로
  testWidgets('🎭 전체 E2E 사용자 시나리오', (tester) async {
    // CachedNetworkImage 에러 방지
    await mockNetworkImagesFor(() async {

      await _bootApp(tester);

      // ──────────────────────────────────────────────────────────────────────
      // [T-NAV-001] 하단 탭 전체 순환
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-NAV-001] 하단 탭 전체 순환');

      // NavigationBar 존재 확인
      final hasNavBar = tester.any(find.byType(NavigationBar)) ||
          tester.any(find.byType(BottomNavigationBar));
      expect(hasNavBar, isTrue,
        reason: '앱 부팅 후 NavigationBar가 보여야 함');

      // 각 탭 순서대로 이동 (앱 구조에 맞게 아이콘 교체)
      await _tapTab(tester, Icons.search);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(tester.any(find.byKey(const Key('search_screen'))), isTrue,
        reason: '검색 탭 이동 후 검색 화면이 보여야 함');

      await _tapTab(tester, Icons.home);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      print('✅ [T-NAV-001] 통과\n');

      // ──────────────────────────────────────────────────────────────────────
      // [T-CORE-001] 아이템 생성 → 목록 반영
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-CORE-001] 아이템 생성 → 목록 반영');

      // 홈 화면에서 추가 버튼 탭
      expect(find.byKey(const Key('home_btn_add')), findsOneWidget,
        reason: '홈 화면에 추가 버튼이 있어야 함');
      await tester.tap(find.byKey(const Key('home_btn_add')));
      await tester.pumpAndSettle();

      // 폼 화면 진입 확인
      expect(find.byKey(const Key('form_field_title')), findsOneWidget,
        reason: '추가 버튼 탭 후 입력 폼이 보여야 함');

      // 제목 입력
      const testItemTitle = '테스트 생성 아이템 E2E';
      await _enterAndSettle(tester,
        find.byKey(const Key('form_field_title')), testItemTitle);

      // 저장 버튼 탭
      await tester.tap(find.byKey(const Key('form_btn_save')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ 저장 후 목록에서 실제 텍스트 확인 (절대 빠뜨리지 않는다)
      expect(find.text(testItemTitle), findsAtLeastNWidgets(1),
        reason: '저장 후 목록에 아이템 텍스트가 보여야 함 — 가장 흔한 버그 지점');

      print('✅ [T-CORE-001] 통과\n');

      // ──────────────────────────────────────────────────────────────────────
      // [T-CORE-002] 아이템 수정 → 변경사항 반영
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-CORE-002] 아이템 수정 → 변경사항 반영');

      // 방금 만든 아이템 탭
      await tester.tap(find.text(testItemTitle).first);
      await tester.pumpAndSettle();

      // 수정 버튼 탭
      await tester.tap(find.byKey(const Key('detail_btn_edit')));
      await tester.pumpAndSettle();

      // 제목 수정
      const updatedTitle = '수정된 아이템 E2E';
      await tester.tap(find.byKey(const Key('form_field_title')));
      await tester.pump(const Duration(milliseconds: 100));
      // 기존 텍스트 전체 선택 후 교체
      await tester.enterText(
        find.byKey(const Key('form_field_title')), updatedTitle);
      await tester.pumpAndSettle();

      // 저장
      await tester.tap(find.byKey(const Key('form_btn_save')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ 수정된 텍스트 목록에서 확인
      expect(find.text(updatedTitle), findsAtLeastNWidgets(1),
        reason: '수정 후 목록에 변경된 텍스트가 보여야 함');
      expect(find.text(testItemTitle), findsNothing,
        reason: '수정 후 이전 텍스트가 사라져야 함');

      print('✅ [T-CORE-002] 통과\n');

      // ──────────────────────────────────────────────────────────────────────
      // [T-FORM-003] 저장 버튼 연속 3회 탭 → 중복 저장 방지
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-FORM-003] 저장 버튼 연속 탭 → 중복 방지');

      await tester.tap(find.byKey(const Key('home_btn_add')));
      await tester.pumpAndSettle();

      await _enterAndSettle(tester,
        find.byKey(const Key('form_field_title')), '중복 테스트 아이템');

      // 빠르게 3회 탭 (중복 저장 버그 유발)
      await tester.tap(find.byKey(const Key('form_btn_save')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('form_btn_save')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('form_btn_save')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 중복 아이템이 1개 이하인지 확인
      final duplicates = tester.widgetList(find.text('중복 테스트 아이템')).length;
      expect(duplicates, lessThanOrEqualTo(1),
        reason: '저장 버튼 3회 탭해도 1개만 저장돼야 함 (중복 방지)');

      print('✅ [T-FORM-003] 통과\n');

      // ──────────────────────────────────────────────────────────────────────
      // [T-CORE-003] 아이템 삭제 → 목록에서 제거
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-CORE-003] 아이템 삭제 → 목록에서 제거');

      // 수정된 아이템으로 진입
      await tester.tap(find.text(updatedTitle).first);
      await tester.pumpAndSettle();

      // 삭제 버튼 탭
      await tester.tap(find.byKey(const Key('detail_btn_delete')));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 → 확인
      if (tester.any(find.byType(AlertDialog))) {
        await _confirmDialog(tester);
      }
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ 삭제된 아이템이 목록에 없는지 확인
      expect(find.text(updatedTitle), findsNothing,
        reason: '삭제 후 해당 아이템이 목록에서 사라져야 함');

      print('✅ [T-CORE-003] 통과\n');

      // ──────────────────────────────────────────────────────────────────────
      // [T-EDGE-001] 빈 목록 상태 UI
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-EDGE-001] 빈 목록 상태 UI');

      // 모든 아이템 삭제 후 빈 상태 확인 (또는 EmptyMock 환경)
      // 프로젝트 빈 상태 메시지에 맞게 텍스트 교체
      final emptyStateVisible =
          tester.any(find.byKey(const Key('empty_state'))) ||
          tester.any(find.textContaining('없')) || // '아직 데이터가 없습니다' 등
          tester.any(find.textContaining('empty'));

      if (emptyStateVisible) {
        print('✅ [T-EDGE-001] 빈 상태 UI 확인됨\n');
      } else {
        print('⚠️ [T-EDGE-001] 빈 상태 UI 미확인 (아직 데이터 있음)\n');
      }

      // ──────────────────────────────────────────────────────────────────────
      // [T-NET-001] 로딩 → 데이터 → 로딩 종료 순서 검증
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-NET-001] 로딩 인디케이터 → 데이터 순서');

      // 새로고침 가능한 화면이 있으면 pull-to-refresh
      final scrollable = find.byType(Scrollable);
      if (tester.any(scrollable)) {
        await tester.fling(scrollable.first, const Offset(0, 300), 500);
        await tester.pump(const Duration(milliseconds: 300));

        // 로딩 인디케이터 표시 여부 (있으면 좋음, 없어도 치명적 버그는 아님)
        final hasLoading =
            tester.any(find.byType(CircularProgressIndicator)) ||
            tester.any(find.byType(RefreshIndicator));

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 로딩 완료 후 로딩 인디케이터 사라져야 함
        expect(
          tester.any(find.byType(CircularProgressIndicator).hitTestable()),
          isFalse,
          reason: '새로고침 완료 후 로딩 인디케이터가 사라져야 함',
        );

        print('✅ [T-NET-001] 로딩 → 완료 확인 (로딩 표시: $hasLoading)\n');
      }

      // ──────────────────────────────────────────────────────────────────────
      // [T-PERF-001] 동일 동작 5회 반복 → 상태 일관성
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-PERF-001] 5회 반복 생성 → 마지막 상태 정확');

      for (int i = 1; i <= 5; i++) {
        if (tester.any(find.byKey(const Key('home_btn_add')))) {
          await tester.tap(find.byKey(const Key('home_btn_add')));
          await tester.pumpAndSettle();

          await _enterAndSettle(tester,
            find.byKey(const Key('form_field_title')), '반복 테스트 $i');

          await tester.tap(find.byKey(const Key('form_btn_save')));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // 매 저장마다 실제 반영 확인
          expect(find.text('반복 테스트 $i'), findsAtLeastNWidgets(1),
            reason: '$i번째 저장 후 목록 반영 확인');
        }
      }

      // 마지막 저장 아이템 확인
      expect(find.text('반복 테스트 5'), findsAtLeastNWidgets(1),
        reason: '5회 반복 후 마지막 아이템이 정확히 보여야 함');

      print('✅ [T-PERF-001] 통과\n');

      // ──────────────────────────────────────────────────────────────────────
      // [T-NAV-003] 동일 버튼 빠른 5회 탭 → 중복 스택 없음
      // ──────────────────────────────────────────────────────────────────────
      print('▶ [T-NAV-003] 빠른 5회 탭 → 중복 스택 없음');

      // 목록 아이템이 있을 때 빠른 탭
      if (tester.any(find.text('반복 테스트 5'))) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('반복 테스트 5').first);
          await tester.pump(const Duration(milliseconds: 80));
        }
        await tester.pumpAndSettle();

        // 상세 화면이 1개만 존재하는지
        // (Key가 있으면 findsOneWidget, 없으면 뒤로가기 1회로 홈 복귀 확인)
        await tester.pageBack();
        await tester.pumpAndSettle();

        final isHome = tester.any(find.byKey(const Key('home_btn_add')));
        expect(isHome, isTrue,
          reason: '뒤로가기 1회로 홈 복귀해야 함 (중복 스택 없음)');
      }

      print('✅ [T-NAV-003] 통과\n');

      print('');
      print('════════════════════════════════════════');
      print('🎉 전체 E2E 시나리오 완료');
      print('════════════════════════════════════════');
    });
  }, timeout: const Timeout(Duration(minutes: 10)));
}
```

---

## 자주 쓰는 검증 패턴

```dart
// ✅ 화면 전환 확인 — 위젯 타입이 아닌 실제 텍스트나 Key로
expect(find.byKey(const Key('home_screen')), findsOneWidget);
expect(find.text('홈'), findsOneWidget);

// ✅ 버튼 활성화 여부
final btn = tester.widget<ElevatedButton>(find.byKey(const Key('save_btn')));
expect(btn.onPressed, isNotNull, reason: '버튼이 활성화 상태여야 함');

// ✅ 버튼 비활성화 (로딩 중, 조건 미충족)
final disabledBtn = tester.widget<ElevatedButton>(find.byKey(const Key('save_btn')));
expect(disabledBtn.onPressed, isNull, reason: '조건 미충족 시 버튼 비활성화여야 함');

// ✅ 로딩 표시 확인
await tester.tap(find.byKey(const Key('fetch_btn')));
await tester.pump();
expect(find.byType(CircularProgressIndicator), findsOneWidget);
await tester.pumpAndSettle(const Duration(seconds: 5));
expect(find.byType(CircularProgressIndicator), findsNothing);

// ✅ SnackBar / Toast 확인
expect(find.byType(SnackBar), findsOneWidget);
expect(find.text('저장되었습니다'), findsOneWidget);

// ✅ 다이얼로그 표시 확인
expect(find.byType(AlertDialog), findsOneWidget);
expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);

// ✅ 스크롤해서 요소 찾기
await tester.scrollUntilVisible(
  find.text('맨 아래 아이템'),
  300,
  scrollable: find.byType(ListView).first,
);

// ✅ 여러 개 중 특정 인덱스
find.byKey(const Key('list_item')).at(2); // 3번째 아이템

// ✅ 텍스트가 N개 이상 있는지 (목록 반영 확인)
expect(find.text('테스트 아이템'), findsAtLeastNWidgets(1));

// ✅ 텍스트가 정확히 없는지 (삭제 확인)
expect(find.text('삭제된 아이템'), findsNothing);
```

---

## iOS vs Android 타임아웃 차이

```dart
// iOS: 빌드/렌더링이 Android보다 느림 → timeout을 더 길게
final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
final timeout = isIOS
    ? const Duration(seconds: 10)
    : const Duration(seconds: 3);

await tester.pumpAndSettle(timeout);
```
