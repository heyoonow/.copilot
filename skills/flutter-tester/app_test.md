# app_test.dart Reference

## 역할

Provider / 로컬 DB / 로직 계층을 **위젯 펌핑 없이** 직접 검증한다.
`ProviderContainer`로 상태를 직접 읽고 쓰며, 화면 렌더링 없이 빠르게 실행된다.

---

## 완성형 app_test.dart 템플릿

```dart
// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:your_app/...'; ← 프로젝트 import

// ── 플러그인 초기화: 하나 실패해도 전체 중단 없음 ──────────────────────────
Future<void> _initPlugins() async {
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) { print('[TEST] Firebase 초기화 실패 (무시): $e'); }
  try {
    // await MobileAds.instance.initialize();
  } catch (e) { print('[TEST] AdMob 초기화 실패 (무시): $e'); }
  try {
    // await Supabase.initialize(url: testUrl, anonKey: testKey);
  } catch (e) { print('[TEST] Supabase 초기화 실패 (무시): $e'); }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  // ── 전체 테스트에서 1회만 ──────────────────────────────────────────────────
  setUpAll(() async {
    prefs = await SharedPreferences.getInstance();
    await _initPlugins();

    // 로컬 DB 초기화 (사용하는 경우 — Hive/Isar/SQLite 프로젝트에 맞게)
    // await Hive.initFlutter('integration_test');
    // await Hive.openBox<SomeModel>('some_box');

    await prefs.clear(); // 테스트 오염 방지
    print('[TEST] 환경 초기화 완료');
  });

  tearDownAll(() async {
    // await Hive.close();
    print('[TEST] 전체 테스트 종료');
  });

  // ════════════════════════════════════════════════════════════════════════════
  // [T-CORE] Provider 상태 단위 테스트
  // ════════════════════════════════════════════════════════════════════════════
  group('[T-CORE] FeatureNotifier 상태 검증', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // featureRepositoryProvider.overrideWithValue(MockFeatureRepository()),
        ],
      );
    });

    tearDown(() async {
      // ⚠️ 진행 중인 타이머/스트림 반드시 정지 후 dispose
      // 안 하면 다음 테스트가 이전 상태를 오염시킴
      try {
        final state = container.read(featureNotifierProvider);
        if (state.isLoading) { /* 진행 중인 작업 취소 */ }
      } catch (_) {}
      container.dispose();
    });

    test('01. 초기 상태: AsyncLoading', () async {
      final state = container.read(featureNotifierProvider);
      expect(state, isA<AsyncLoading>(),
        reason: 'Provider 생성 직후 loading 상태여야 함');
    });

    test('02. 데이터 로드 완료 → AsyncData', () async {
      await container.read(featureNotifierProvider.future);
      final state = container.read(featureNotifierProvider);
      expect(state, isA<AsyncData>());
      expect(state.valueOrNull, isNotNull);
    });

    test('03. 아이템 추가 → 목록 카운트 +1', () async {
      await container.read(featureNotifierProvider.future);
      final before = container.read(featureNotifierProvider).valueOrNull?.length ?? 0;

      await container.read(featureNotifierProvider.notifier)
          .create(/* 테스트 데이터 */);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final after = container.read(featureNotifierProvider).valueOrNull?.length ?? 0;
      expect(after, equals(before + 1),
        reason: '아이템 추가 후 카운트 1 증가해야 함');
    });

    test('04. 아이템 수정 → 목록에서 변경 확인', () async {
      await container.read(featureNotifierProvider.future);
      final items = container.read(featureNotifierProvider).valueOrNull ?? [];
      expect(items, isNotEmpty, reason: '수정 테스트 전 데이터 있어야 함');

      final targetId = items.first.id;
      const newName = '수정된 아이템 이름';

      await container.read(featureNotifierProvider.notifier)
          .update(targetId, name: newName);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final updated = container.read(featureNotifierProvider).valueOrNull
          ?.firstWhere((e) => e.id == targetId);
      expect(updated?.name, equals(newName),
        reason: '수정 후 목록에서 변경된 값이 보여야 함');
    });

    test('05. 아이템 삭제 → 목록에서 제거', () async {
      await container.read(featureNotifierProvider.future);
      final items = container.read(featureNotifierProvider).valueOrNull ?? [];
      expect(items, isNotEmpty, reason: '삭제 테스트 전 데이터 있어야 함');

      final targetId = items.first.id;
      await container.read(featureNotifierProvider.notifier).delete(targetId);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final afterItems = container.read(featureNotifierProvider).valueOrNull ?? [];
      expect(afterItems.any((e) => e.id == targetId), isFalse,
        reason: '삭제 후 해당 아이템이 목록에 없어야 함');
    });

    test('06. API 실패 → AsyncError 상태', () async {
      final errorContainer = ProviderContainer(
        overrides: [
          // featureRepositoryProvider.overrideWithValue(FailingMockRepository()),
        ],
      );
      addTearDown(errorContainer.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 500));
      final state = errorContainer.read(featureNotifierProvider);
      expect(state, isA<AsyncError>(),
        reason: 'API 실패 시 AsyncError 상태여야 함');
    });

    test('07. 빈 데이터 → 빈 목록 (null 아님)', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          // featureRepositoryProvider.overrideWithValue(EmptyMockRepository()),
        ],
      );
      addTearDown(emptyContainer.dispose);

      await emptyContainer.read(featureNotifierProvider.future);
      final items = emptyContainer.read(featureNotifierProvider).valueOrNull;
      expect(items, isNotNull, reason: '빈 데이터도 null이 아닌 빈 리스트여야 함');
      expect(items, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // [T-DB] SharedPreferences 영속성 검증
  // ════════════════════════════════════════════════════════════════════════════
  group('[T-DB] 로컬 저장소 영속성', () {
    test('01. 값 저장 → 재인스턴스 후에도 유지', () async {
      await prefs.setString('test_key', 'test_value');
      await prefs.setBool('onboarding_done', true);

      final reloaded = await SharedPreferences.getInstance();
      expect(reloaded.getString('test_key'), equals('test_value'));
      expect(reloaded.getBool('onboarding_done'), isTrue);
    });

    test('02. 로그아웃 → 민감 데이터 삭제', () async {
      await prefs.setString('auth_token', 'some_token');
      await prefs.setString('user_id', 'user_123');

      // 로그아웃 처리 (프로젝트 코드 호출)
      // await ref.read(authNotifierProvider.notifier).signOut();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');

      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('user_id'), isNull);
    });

    test('03. 설정값 저장 → 앱 재시작 시뮬레이션 후 복원', () async {
      await prefs.setString('theme_mode', 'dark');
      await prefs.setString('language', 'ko');

      final reloaded = await SharedPreferences.getInstance();
      expect(reloaded.getString('theme_mode'), equals('dark'));
      expect(reloaded.getString('language'), equals('ko'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // [T-FORM] 입력 검증 로직 단위 테스트
  // ════════════════════════════════════════════════════════════════════════════
  group('[T-FORM] 입력 유효성 검증', () {
    test('01. 빈 제목 → 에러 메시지 반환', () {
      // 유효성 검증 함수가 있다면 직접 호출
      // final result = validateTitle('');
      // expect(result, isNotNull);
      // expect(result, contains('제목'));
    });

    test('02. 100자 초과 제목 → 에러 메시지 반환', () {
      final longTitle = 'a' * 101;
      // final result = validateTitle(longTitle);
      // expect(result, isNotNull);
      _ = longTitle; // ignore unused
    });

    test('03. 유효한 이메일 형식 → null 반환 (에러 없음)', () {
      // final result = validateEmail('user@example.com');
      // expect(result, isNull);
    });

    test('04. 잘못된 이메일 형식 → 에러 메시지', () {
      // final result = validateEmail('not-an-email');
      // expect(result, isNotNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // [T-PERF] 반복 동작 누적 버그 검증
  // ════════════════════════════════════════════════════════════════════════════
  group('[T-PERF] 반복 동작 상태 일관성', () {
    test('01. 아이템 5회 생성/삭제 후 상태 일관성', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(featureNotifierProvider.future);

      // 5회 생성
      for (int i = 1; i <= 5; i++) {
        await container.read(featureNotifierProvider.notifier)
            .create(/* 테스트 아이템 $i */);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final items = container.read(featureNotifierProvider).valueOrNull ?? [];
      expect(items.length, greaterThanOrEqualTo(5));

      // 전체 삭제
      for (final item in List.from(items)) {
        await container.read(featureNotifierProvider.notifier).delete(item.id);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final afterItems = container.read(featureNotifierProvider).valueOrNull ?? [];
      expect(afterItems, isEmpty,
        reason: '전체 삭제 후 빈 목록이어야 함');
    });

    test('02. Provider 10회 연속 refresh → 최종 상태 정상', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (int i = 0; i < 10; i++) {
        container.invalidate(featureNotifierProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      await container.read(featureNotifierProvider.future);
      final state = container.read(featureNotifierProvider);
      expect(state, isA<AsyncData>(),
        reason: '10회 refresh 후 최종 상태 정상이어야 함');
    });

    test('03. 동시 저장 요청 2회 → 중복 저장 방지', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(featureNotifierProvider.future);
      final before = container.read(featureNotifierProvider).valueOrNull?.length ?? 0;

      // 동시 요청
      await Future.wait([
        container.read(featureNotifierProvider.notifier).create(/* 데이터 */),
        container.read(featureNotifierProvider.notifier).create(/* 데이터 */),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final after = container.read(featureNotifierProvider).valueOrNull?.length ?? 0;
      // 중복 방지 로직이 있다면 1개, 없다면 2개 — 프로젝트 정책에 따라
      expect(after, lessThanOrEqualTo(before + 2),
        reason: '동시 저장이 무한 증가하면 안 됨');
    });
  });
}
```

---

## Mock 패턴 (mocktail)

```dart
// integration_test/helpers/mock_repositories.dart

import 'package:mocktail/mocktail.dart';

// ── 성공 Mock ────────────────────────────────────────────────────────────────
class MockFeatureRepository extends Mock implements FeatureRepository {
  @override
  Future<List<FeatureEntity>> getAll() async => [
    FeatureEntity(id: '1', name: '테스트 아이템 1', createdAt: DateTime.now()),
    FeatureEntity(id: '2', name: '테스트 아이템 2', createdAt: DateTime.now()),
    FeatureEntity(id: '3', name: '테스트 아이템 3', createdAt: DateTime.now()),
  ];

  @override
  Future<FeatureEntity> create(CreateFeatureInput input) async =>
      FeatureEntity(id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: input.name, createdAt: DateTime.now());

  @override
  Future<FeatureEntity> update(String id, UpdateFeatureInput input) async =>
      FeatureEntity(id: id, name: input.name ?? '', createdAt: DateTime.now());

  @override
  Future<void> delete(String id) async {}
}

// ── 항상 실패하는 Mock ────────────────────────────────────────────────────────
class FailingMockRepository extends Mock implements FeatureRepository {
  @override
  Future<List<FeatureEntity>> getAll() async =>
      throw const ServerFailure('테스트: 서버 오류');

  @override
  Future<FeatureEntity> create(CreateFeatureInput input) async =>
      throw const NetworkFailure();

  @override
  Future<void> delete(String id) async =>
      throw const ServerFailure('테스트: 삭제 실패');
}

// ── 빈 데이터 Mock ────────────────────────────────────────────────────────────
class EmptyMockRepository extends Mock implements FeatureRepository {
  @override
  Future<List<FeatureEntity>> getAll() async => [];

  @override
  Future<FeatureEntity> create(CreateFeatureInput input) async =>
      FeatureEntity(id: '1', name: input.name, createdAt: DateTime.now());

  @override
  Future<void> delete(String id) async {}
}

// ── 세션 만료 Mock ────────────────────────────────────────────────────────────
class SessionExpiredMockRepository extends Mock implements FeatureRepository {
  @override
  Future<List<FeatureEntity>> getAll() async =>
      throw const AuthFailure('세션이 만료되었습니다');

  @override
  Future<FeatureEntity> create(CreateFeatureInput input) async =>
      throw const AuthFailure();

  @override
  Future<void> delete(String id) async => throw const AuthFailure();
}

// ── 지연 응답 Mock (느린 네트워크 시뮬레이션) ──────────────────────────────
class SlowMockRepository extends Mock implements FeatureRepository {
  @override
  Future<List<FeatureEntity>> getAll() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    return [FeatureEntity(id: '1', name: '느린 로딩 아이템', createdAt: DateTime.now())];
  }

  @override
  Future<FeatureEntity> create(CreateFeatureInput input) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return FeatureEntity(id: '2', name: input.name, createdAt: DateTime.now());
  }

  @override
  Future<void> delete(String id) async =>
      Future<void>.delayed(const Duration(seconds: 2));
}
```
