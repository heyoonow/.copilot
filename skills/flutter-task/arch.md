# Architecture Reference

## 기술 스택

| 역할             | 패키지                                                             |
| ---------------- | ------------------------------------------------------------------ |
| 상태관리         | `hooks_riverpod` + `flutter_hooks`                                 |
| 라우팅           | `go_router`                                                        |
| 백엔드           | `supabase_flutter`                                                 |
| Firebase         | `firebase_core`, `firebase_analytics`, `firebase_messaging`        |
| 다국어           | `easy_localization`                                                |
| 직렬화           | `json_annotation` + `json_serializable` + `build_runner`           |
| 로컬 저장소      | `shared_preferences`                                               |
| 이미지 캐시      | `cached_network_image`                                             |
| 애니메이션       | `flutter_staggered_animations`                                     |
| 스켈레톤 로딩    | `shimmer`                                                          |
| UI 유틸          | `velocity_x`                                                       |
| 아이콘           | `font_awesome_flutter`                                             |
| 광고             | `google_mobile_ads`                                                |
| 스플래시         | `flutter_native_splash`                                            |
| 트래킹           | `app_tracking_transparency`                                        |
| Flutter 관리     | `fvm`                                                              |

---

## 폴더 구조 (전체)

```
lib/
├── main.dart                    ← 초기화 + ProviderScope
├── app.dart                     ← MaterialApp + 테마 + 라우터
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      ← 색상 토큰 (하드코딩 절대 금지)
│   │   ├── app_typography.dart  ← 텍스트 스타일 토큰
│   │   └── app_values.dart      ← spacing / radius / icon / button 크기
│   ├── errors/
│   │   └── failure.dart         ← Failure sealed class
│   ├── extensions/
│   │   ├── context_extension.dart   ← context.textTheme, context.colorScheme
│   │   ├── string_extension.dart
│   │   └── datetime_extension.dart
│   ├── providers/
│   │   └── app_providers.dart   ← 공통 Provider (SharedPreferences 등)
│   ├── theme/
│   │   └── app_theme.dart       ← ThemeData (light / dark)
│   ├── storage/
│   │   └── local_storage.dart   ← SharedPreferences 래퍼
│   ├── utils/
│   │   ├── logger.dart
│   │   └── snack_bar_helper.dart
│   └── widgets/                 ← 전역 공통 위젯
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── app_shimmer.dart
│       ├── app_empty_state.dart
│       ├── app_error_state.dart
│       ├── app_bottom_sheet.dart
│       ├── app_avatar.dart
│       ├── app_badge.dart
│       └── app_divider.dart
├── router/
│   └── app_router.dart          ← GoRouter 정의 + 인증 redirect
└── features/
    └── [feature_name]/
        ├── data/
        │   ├── datasources/
        │   │   └── [feature]_datasource.dart
        │   ├── models/
        │   │   ├── [feature]_model.dart          ← @JsonSerializable
        │   │   └── [feature]_model.g.dart        ← build_runner 생성 (커밋 O)
        │   └── repositories/
        │       └── [feature]_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── [feature]_entity.dart         ← 순수 Dart (Flutter 의존 없음)
        │   ├── repositories/
        │   │   └── [feature]_repository.dart     ← abstract interface
        │   └── usecases/
        │       └── [feature]_usecase.dart
        └── presentation/
            ├── screens/
            │   ├── [feature]_screen.dart
            │   └── [feature]_detail_screen.dart
            ├── widgets/
            │   └── [feature]_card.dart           ← feature 전용 위젯
            └── providers/
                ├── [feature]_notifier.dart
                └── [feature]_notifier.g.dart     ← build_runner 생성 (커밋 O)
```

---

## 레이어 규칙

```
Presentation  →  Domain  (O)
Presentation  →  Data    (X)  ← 직접 접근 금지
Data          →  Domain  (O)
Domain        →  Data    (X)  ← 의존 역전 원칙
Domain        →  Flutter (X)  ← 순수 Dart만
```

---

## main.dart 기본 구조

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase 초기화
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // 다국어 초기화
  await EasyLocalization.ensureInitialized();

  // 화면 세로 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      child: ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(LocalStorage(prefs)),
        ],
        child: const App(),
      ),
    ),
  );
}
```

---

## app.dart 기본 구조

```dart
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '앱 이름',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        // 폰트 크기 시스템 설정 무시 (디자인 고정)
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
```

---

## 신규 Feature 추가 체크리스트

```
□ 1. domain/entities/[feature]_entity.dart 생성
□ 2. domain/repositories/[feature]_repository.dart (abstract) 생성
□ 3. domain/usecases/[feature]_usecase.dart 생성
□ 4. data/models/[feature]_model.dart 생성 (@JsonSerializable)
□ 5. fvm flutter pub run build_runner build --delete-conflicting-outputs
□ 6. data/datasources/[feature]_datasource.dart 생성
□ 7. data/repositories/[feature]_repository_impl.dart 생성
□ 8. presentation/providers/[feature]_notifier.dart 생성 (@riverpod)
□ 9. fvm flutter pub run build_runner build --delete-conflicting-outputs
□ 10. presentation/screens/[feature]_screen.dart 생성
□ 11. presentation/widgets/ 필요한 위젯 생성
□ 12. router/app_router.dart에 Route 등록
□ 13. core/providers/app_providers.dart에 Provider 등록
□ 14. assets/translations/ko.json에 문자열 추가
```

---

## context_extension.dart

```dart
// core/extensions/context_extension.dart

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  void push(String path) => GoRouter.of(this).push(path);
  void go(String path) => GoRouter.of(this).go(path);
}
```

---

## app_theme.dart 기본 구조

```dart
// core/theme/app_theme.dart

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        background: isLight ? AppColors.background : AppColors.backgroundDark,
        surface: isLight ? AppColors.surface : AppColors.surfaceDark,
        primary: AppColors.primary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: isLight ? AppColors.background : AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: isLight ? AppColors.background : AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.heading3.copyWith(
          color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
        ),
        iconTheme: IconThemeData(
          color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
          size: AppValues.iconL,
        ),
        systemOverlayStyle: isLight
          ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      ),
      textTheme: _buildTextTheme(isLight),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.border : AppColors.border.withOpacity(0.2),
        thickness: 1,
        space: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isLight) {
    final color = isLight ? AppColors.textPrimary : AppColors.textPrimaryDark;
    return TextTheme(
      displayLarge: AppTypography.display1.copyWith(color: color),
      displayMedium: AppTypography.display2.copyWith(color: color),
      headlineLarge: AppTypography.heading1.copyWith(color: color),
      headlineMedium: AppTypography.heading2.copyWith(color: color),
      headlineSmall: AppTypography.heading3.copyWith(color: color),
      bodyLarge: AppTypography.bodyLg.copyWith(color: color),
      bodyMedium: AppTypography.body.copyWith(color: color),
      bodySmall: AppTypography.bodySm.copyWith(color: color),
      labelLarge: AppTypography.labelLg.copyWith(color: color),
      labelMedium: AppTypography.label.copyWith(color: color),
      labelSmall: AppTypography.labelSm.copyWith(color: color),
    );
  }
}
```
