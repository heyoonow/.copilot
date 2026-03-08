---
name: flutter-task
description: "Flutter 앱 개발 작업을 실행한다. 기능 구현, UI 개발, 상태관리 등 Flutter 관련 작업 요청이 오면 클린 아키텍처 구조와 일관된 디자인 시스템을 유지하며 구현한다. Android/iOS 양 플랫폼 최적화, 압도적인 사용자 경험, 인상적인 디자인과 애니메이션을 최우선으로 한다."
---

# Flutter Task Executor

클린 아키텍처 기반으로 Flutter 작업을 실행한다.
디자인, 애니메이션, 사용자 경험은 절대 타협하지 않는다. 1억 다운로드 앱 기준으로 만든다.

---

## 기술 스택

| 역할 | 패키지 |
|---|---|
| 상태관리 | `hooks_riverpod` + `flutter_hooks` |
| 라우팅 | `go_router` |
| 백엔드 | `supabase_flutter` |
| Firebase | `firebase_core`, `firebase_analytics` |
| 다국어 | `easy_localization` |
| 직렬화 | `json_annotation` + `json_serializable` + `build_runner` |
| 저장소 | `shared_preferences` |
| UI 유틸 | `velocity_x` |
| 아이콘 | `font_awesome_flutter` |
| 광고 | `google_mobile_ads` |
| 스플래시 | `flutter_native_splash` |
| 트래킹 | `app_tracking_transparency` |
| Flutter 관리 | `fvm` |

---

## 폴더 구조

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_values.dart
│   ├── errors/
│   │   └── failure.dart
│   ├── extensions/
│   │   ├── context_extension.dart
│   │   └── string_extension.dart
│   ├── providers/
│   │   └── app_providers.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── logger.dart
├── router/
│   └── app_router.dart
└── features/
    └── [feature]/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        ├── domain/
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        └── presentation/
            ├── screens/
            ├── widgets/
            └── providers/
```

---

## 작업 실행 워크플로우

### 1단계: 파악
- UI인지 로직인지 둘 다인지 판단
- 연관된 기존 코드 확인 (Provider, Repository, Widget)
- 디자인 토큰 확인 (기존 색상, 타이포, 간격 일관성)
- 플랫폼별 UX 패턴 확인

### 2단계: 레이어 순서
```
Domain → Data → Presentation (Provider → Screen → Widget)
```

### 3단계: 검증
- 컴파일 에러 없는지 확인
- Provider 의존성 체인 확인
- Android/iOS 양쪽 레이아웃 확인
- 애니메이션 자연스러운지 확인

---

## 플랫폼별 UX 원칙

### 공통
- 터치 타겟 최소 **48x48dp**
- 즉각적인 시각 피드백 (탭 시 항상 반응)
- 로딩은 Shimmer (스피너 최소화)
- 에러 상태 항상 처리 (빈 화면 금지)

### Android 최적화
```dart
// 상태바 투명 처리
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ),
);

// 오버스크롤 글로우 제거
ScrollConfiguration(
  behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
  child: listView,
)
```
- Material 3 디자인 언어 준수
- FAB, BottomNavigationBar 적극 활용
- 뒤로가기 처리 (`PopScope`)

### iOS 최적화
```dart
// 네이티브 바운스 유지
physics: const BouncingScrollPhysics()

// SafeArea 항상 적용
SafeArea(child: content)
```
- iOS 스와이프백 제스처 방해 금지
- 상태바/Dynamic Island 침범 금지
- 모달은 바텀시트 또는 풀스크린 슬라이드

### 플랫폼별 화면 전환
```dart
CustomTransitionPage(
  child: screen,
  transitionsBuilder: (context, animation, _, child) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
      ? SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child)
      : FadeTransition(opacity: animation, child: child);
  },
)
```

---

## 디자인 원칙

- **일관성**: `core/constants/` 토큰만 사용, 하드코딩 절대 금지
- **인상**: 평범한 UI 금지. 사용자가 기억하는 디테일
- **여백**: 콘텐츠가 숨 쉬어야 한다. 답답한 UI 금지
- **계층**: 그림자, 색상 대비, 크기로 시각적 계층 명확히

```dart
// 색상 하드코딩 금지
color: Color(0xFF1A1A2E)  // ❌
color: AppColors.primary   // ✅

// 텍스트 스타일 하드코딩 금지
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)  // ❌
style: context.textTheme.titleMedium                          // ✅
```

---

## 애니메이션 가이드

### Duration 기준
| 유형 | Duration |
|---|---|
| 마이크로 인터랙션 (버튼, 탭) | 100~150ms |
| 화면 전환 | 250~300ms |
| 콘텐츠 등장 | 300~400ms |
| 강조 애니메이션 | 400~600ms |

### 상황별 패턴
```dart
// 버튼 탭 피드백
AnimatedScale(
  scale: isPressed ? 0.95 : 1.0,
  duration: const Duration(milliseconds: 100),
  child: button,
)

// 리스트 아이템 순차 등장
SlideAnimation(
  verticalOffset: 20,
  child: FadeInAnimation(child: item),
)

// 상태 전환
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  child: isLoading ? const ShimmerWidget() : ContentWidget(key: ValueKey(data)),
)

// 숫자/텍스트 변화
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 150),
  style: targetStyle,
  child: text,
)
```

### Curve 추천
| 상황 | Curve |
|---|---|
| 일반 등장 | `Curves.easeOutCubic` |
| 스프링 느낌 | `Curves.elasticOut` |
| 빠르게 사라짐 | `Curves.easeInQuart` |
| 자연스러운 전환 | `Curves.easeInOutCubic` |

---

## 코딩 컨벤션

### Riverpod
```dart
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  AsyncValue<FeatureState> build() => const AsyncValue.data(FeatureState());

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(featureUsecaseProvider).execute(),
    );
  }
}
```

### Widget
```dart
class FeatureScreen extends HookConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNotifierProvider);

    return Scaffold(
      body: state.when(
        data: (data) => FeatureContent(data: data),
        loading: () => const FeatureShimmer(),
        error: (e, _) => FeatureError(
          onRetry: () => ref.invalidate(featureNotifierProvider),
        ),
      ),
    );
  }
}
```

### go_router
```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HomeScreen(),
          transitionsBuilder: platformTransition,
        ),
      ),
    ],
  );
});
```

### easy_localization
```dart
Text('feature.title'.tr())            // 기본
Text('feature.greeting'.tr(args: [userName]))  // 파라미터
```

### json_annotation
```dart
@JsonSerializable()
class ItemModel {
  const ItemModel({required this.id, required this.name});
  factory ItemModel.fromJson(Map<String, dynamic> json) => _$ItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$ItemModelToJson(this);
}
// 수정 후: fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 자주 쓰는 패턴

### Supabase fetch
```dart
final response = await Supabase.instance.client
  .from('items')
  .select()
  .order('created_at', ascending: false);
return (response as List).map((e) => ItemModel.fromJson(e)).toList();
```

### AsyncValue 처리
```dart
state.when(
  data: (data) => ContentWidget(data: data),
  loading: () => const ShimmerWidget(),
  error: (e, _) => ErrorWidget(
    message: e.toString(),
    onRetry: () => ref.invalidate(provider),
  ),
)
```

### SafeArea 패턴
```dart
Scaffold(
  body: SafeArea(bottom: false, child: content),
  bottomNavigationBar: SafeArea(child: BottomNavBar()),
)
```

---

## 주의사항

- `fvm flutter` 사용 (flutter 직접 호출 금지)
- 모델 수정 시 항상 `build_runner` 실행
- 새 문자열은 `assets/translations/` 에도 추가
- 색상/타이포 하드코딩 절대 금지
- `SafeArea` 빠뜨리지 않기 (노치, Dynamic Island)
- 화면 회전 세로 고정 (`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`)