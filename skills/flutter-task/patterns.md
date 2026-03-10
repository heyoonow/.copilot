# Patterns Reference

## Riverpod — Notifier 패턴 (기본)

```dart
// features/[feature]/presentation/providers/feature_notifier.dart

part 'feature_notifier.g.dart';

@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  AsyncValue<List<FeatureEntity>> build() {
    _fetch();
    return const AsyncValue.loading();
  }

  Future<void> _fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(featureUsecaseProvider).getAll(),
    );
  }

  Future<void> refresh() => _fetch();

  Future<void> create(CreateFeatureInput input) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimistic = FeatureEntity(id: tempId, name: input.name, createdAt: DateTime.now());

    // 낙관적 업데이트
    final previous = state;
    state = AsyncValue.data([optimistic, ...state.valueOrNull ?? []]);

    try {
      final created = await ref.read(featureUsecaseProvider).create(input);
      // 임시 데이터 → 실제 데이터로 교체
      state = AsyncValue.data(
        state.valueOrNull!.map((e) => e.id == tempId ? created : e).toList(),
      );
    } catch (e, st) {
      state = previous; // 실패 시 롤백
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final previous = state;
    state = AsyncValue.data(
      state.valueOrNull!.where((e) => e.id != id).toList(),
    );

    try {
      await ref.read(featureUsecaseProvider).delete(id);
    } catch (e, st) {
      state = previous;
      rethrow;
    }
  }
}
```

---

## Riverpod — 단순 조회 (AsyncNotifierProvider 불필요할 때)

```dart
@riverpod
Future<FeatureEntity> featureDetail(
  FeatureDetailRef ref,
  String id,
) async {
  return ref.read(featureUsecaseProvider).getById(id);
}

// 사용
final detail = ref.watch(featureDetailProvider('item-id'));
```

---

## Riverpod — 페이지네이션

```dart
@riverpod
class FeaturePaginatedNotifier extends _$FeaturePaginatedNotifier {
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;

  @override
  AsyncValue<List<FeatureEntity>> build() {
    _load(reset: true);
    return const AsyncValue.loading();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    final items = await ref.read(featureUsecaseProvider).getPaged(
      page: _page,
      pageSize: _pageSize,
    );

    _hasMore = items.length == _pageSize;
    _page++;

    state = AsyncValue.data([
      ...if (!reset) (state.valueOrNull ?? []),
      ...items,
    ]);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;
    await _load();
  }

  Future<void> refresh() => _load(reset: true);
}

// 사용 — 스크롤 끝 감지
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification is ScrollEndNotification) {
      final pixels = notification.metrics.pixels;
      final maxExtent = notification.metrics.maxScrollExtent;
      if (pixels >= maxExtent - 200) {
        ref.read(featurePaginatedNotifierProvider.notifier).loadMore();
      }
    }
    return false;
  },
  child: listView,
)
```

---

## Riverpod — Realtime (Supabase Stream)

```dart
@riverpod
Stream<List<FeatureEntity>> featureStream(FeatureStreamRef ref) {
  return ref.read(featureDatasourceProvider)
    .stream()
    .map((models) => models.map((m) => m.toEntity()).toList());
}

// 사용
final streamState = ref.watch(featureStreamProvider);
```

---

## Widget — HookConsumerWidget 패턴

```dart
class FeatureScreen extends HookConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNotifierProvider);
    final notifier = ref.read(featureNotifierProvider.notifier);

    // Flutter Hooks 활용
    final scrollController = useScrollController();
    final isScrolled = useState(false);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    useEffect(() {
      void onScroll() => isScrolled.value = scrollController.offset > 0;
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    // ref.listen — 에러 발생 시 스낵바
    ref.listen(featureNotifierProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: state.when(
          data: (items) => RefreshIndicator(
            onRefresh: notifier.refresh,
            color: AppColors.primary,
            child: items.isEmpty
              ? AppEmptyState(message: '아직 항목이 없어요')
              : _FeatureList(
                  items: items,
                  scrollController: scrollController,
                ),
          ),
          loading: () => const FeatureCardShimmer(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: notifier.refresh,
          ),
        ),
      ),
    );
  }
}
```

---

## Supabase — CRUD 전체 패턴

```dart
// features/[feature]/data/datasources/feature_datasource.dart

class FeatureDatasource {
  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  // ── Read All ──────────────────────────────────────────────────────────────
  Future<List<FeatureModel>> getAll() async {
    final response = await _client
        .from('features')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => FeatureModel.fromJson(e)).toList();
  }

  // ── Read Paginated ────────────────────────────────────────────────────────
  Future<List<FeatureModel>> getPaged({required int page, required int pageSize}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final response = await _client
        .from('features')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .range(from, to);
    return (response as List).map((e) => FeatureModel.fromJson(e)).toList();
  }

  // ── Read Single ───────────────────────────────────────────────────────────
  Future<FeatureModel> getById(String id) async {
    final response = await _client
        .from('features')
        .select()
        .eq('id', id)
        .single();
    return FeatureModel.fromJson(response);
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<FeatureModel> create(Map<String, dynamic> data) async {
    final response = await _client
        .from('features')
        .insert({...data, 'user_id': _userId})
        .select()
        .single();
    return FeatureModel.fromJson(response);
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<FeatureModel> update(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('features')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return FeatureModel.fromJson(response);
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _client
        .from('features')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Realtime Stream ───────────────────────────────────────────────────────
  Stream<List<FeatureModel>> stream() {
    return _client
        .from('features')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at')
        .map((data) => data.map((e) => FeatureModel.fromJson(e)).toList());
  }

  // ── Storage Upload ────────────────────────────────────────────────────────
  Future<String> uploadImage(String path, Uint8List bytes) async {
    final fileName = '${_userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('images').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return _client.storage.from('images').getPublicUrl(fileName);
  }
}
```

---

## Supabase — 인증 패턴

```dart
// features/auth/data/datasources/auth_datasource.dart

class AuthDatasource {
  SupabaseClient get _client => Supabase.instance.client;

  // 현재 유저 스트림 (앱 전체 인증 상태 감지)
  Stream<User?> get authStateStream =>
    _client.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

// 인증 상태 Provider
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.read(authDatasourceProvider).authStateStream;
}

// go_router redirect에서 사용
redirect: (context, state) {
  final user = ref.read(authStateProvider).valueOrNull;
  final isAuth = user != null;
  final isGoingToAuth = state.matchedLocation.startsWith('/auth');

  if (!isAuth && !isGoingToAuth) return '/auth/login';
  if (isAuth && isGoingToAuth) return '/';
  return null;
},
```

---

## json_serializable 패턴

```dart
// features/[feature]/data/models/feature_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'feature_model.g.dart';

@JsonSerializable(explicitToJson: true)
class FeatureModel {
  const FeatureModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdAt,
    this.tags = const [],
    this.metadata,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeatureModelToJson(this);

  FeatureEntity toEntity() => FeatureEntity(
    id: id,
    name: name,
    description: description,
    imageUrl: imageUrl,
    createdAt: createdAt,
    tags: tags,
  );

  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
}

// ── 모델 수정 후 반드시 실행 ──────────────────────────────────────────────────
// fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

## go_router — 전체 설정 패턴

```dart
// router/app_router.dart

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    redirect: (context, state) {
      final user = authNotifier.valueOrNull;
      final isAuth = user != null;
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isGoingToAuth) return '/auth/login';
      if (isAuth && isGoingToAuth) return '/';
      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(context, state, const HomeScreen()),
        routes: [
          GoRoute(
            path: 'feature',
            pageBuilder: (context, state) => _buildPage(context, state, const FeatureScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _buildPage(
                  context, state,
                  FeatureDetailScreen(id: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (context, state) => _buildPage(context, state, const LoginScreen()),
      ),
    ],
  );
});

// platform.md의 platformTransitionPage 함수 사용
CustomTransitionPage<void> _buildPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => platformTransitionPage(context: context, state: state, child: child);
```

---

## easy_localization 패턴

```dart
// 기본 사용
Text('feature.title'.tr())

// 인자 삽입
Text('feature.greeting'.tr(namedArgs: {'name': '홍길동'}))

// 복수형
Text('feature.count'.plural(count))

// assets/translations/ko.json
{
  "feature": {
    "title": "기능 목록",
    "greeting": "안녕하세요, {name}님",
    "count": {
      "zero": "항목 없음",
      "one": "항목 1개",
      "other": "항목 {}개"
    },
    "empty_message": "아직 항목이 없습니다",
    "add": "추가하기",
    "delete_confirm": "정말 삭제하시겠어요?"
  }
}
```

> **주의**: 새 문자열 추가 시 모든 언어 파일에 동시에 추가한다.
> 누락 시 앱 런타임에 키 이름 그대로 표시됨.

---

## shared_preferences — 타입 안전 래퍼

```dart
// core/storage/local_storage.dart

class LocalStorage {
  LocalStorage(this._prefs);
  final SharedPreferences _prefs;

  // Generic getter/setter
  T? get<T>(String key) {
    return switch (T) {
      String  => _prefs.getString(key) as T?,
      int     => _prefs.getInt(key) as T?,
      double  => _prefs.getDouble(key) as T?,
      bool    => _prefs.getBool(key) as T?,
      _       => null,
    };
  }

  Future<bool> set<T>(String key, T value) {
    return switch (value) {
      String v  => _prefs.setString(key, v),
      int v     => _prefs.setInt(key, v),
      double v  => _prefs.setDouble(key, v),
      bool v    => _prefs.setBool(key, v),
      _         => throw UnimplementedError('Unsupported type: ${T.runtimeType}'),
    };
  }

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();
}

// 키 상수 관리
class StorageKeys {
  StorageKeys._();
  static const String onboardingDone = 'onboarding_done';
  static const String themeMode = 'theme_mode';
  static const String lastSyncAt = 'last_sync_at';
}

// Provider
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError(); // main.dart에서 override
});

// main.dart
final prefs = await SharedPreferences.getInstance();
runApp(
  ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(LocalStorage(prefs)),
    ],
    child: const App(),
  ),
);
```

---

## 에러 처리 — 전역 패턴

```dart
// core/errors/failure.dart

sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('네트워크 연결을 확인해 주세요');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = '서버 오류가 발생했어요']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = '로그인이 필요해요']) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = '데이터를 찾을 수 없어요']) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}

// Repository에서 사용 (Either 패턴 없이 심플하게)
Future<List<FeatureEntity>> getAll() async {
  try {
    final models = await _datasource.getAll();
    return models.map((m) => m.toEntity()).toList();
  } on PostgrestException catch (e) {
    if (e.code == '401') throw const AuthFailure();
    throw ServerFailure(e.message);
  } on SocketException {
    throw const NetworkFailure();
  } catch (e) {
    throw UnknownFailure(e.toString());
  }
}

// UI에서 에러 메시지 표시
String mapFailureToMessage(Object error) {
  return switch (error) {
    NetworkFailure() => '인터넷 연결을 확인해 주세요',
    AuthFailure()    => '로그인이 필요해요',
    NotFoundFailure(message: final msg) => msg,
    ServerFailure(message: final msg)   => msg,
    _                => '알 수 없는 오류가 발생했어요',
  };
}
```

---

## SnackBar / Toast 헬퍼

```dart
// core/utils/snack_bar_helper.dart

class SnackBarHelper {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_iconForType(type), color: Colors.white, size: AppValues.iconM),
              const SizedBox(width: AppValues.spaceS),
              Expanded(
                child: Text(message, style: AppTypography.bodySm.copyWith(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: _colorForType(type),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radiusM),
          ),
          margin: const EdgeInsets.all(AppValues.paddingL),
        ),
      );
  }

  static IconData _iconForType(AppSnackBarType type) => switch (type) {
    AppSnackBarType.success => Icons.check_circle_outline,
    AppSnackBarType.error   => Icons.error_outline,
    AppSnackBarType.warning => Icons.warning_amber_outlined,
    AppSnackBarType.info    => Icons.info_outline,
  };

  static Color _colorForType(AppSnackBarType type) => switch (type) {
    AppSnackBarType.success => AppColors.success,
    AppSnackBarType.error   => AppColors.error,
    AppSnackBarType.warning => AppColors.warning,
    AppSnackBarType.info    => AppColors.textPrimary,
  };
}

enum AppSnackBarType { success, error, warning, info }

// 사용
SnackBarHelper.show(context, message: '저장됐어요!', type: AppSnackBarType.success);
SnackBarHelper.show(context, message: e.toString(), type: AppSnackBarType.error);
```
