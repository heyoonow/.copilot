# Boilerplate Reference

## STEP 7 — 클린 아키텍처 폴더 구조 생성

```bash
# core 폴더
mkdir -p lib/core/constants
mkdir -p lib/core/errors
mkdir -p lib/core/extensions
mkdir -p lib/core/providers
mkdir -p lib/core/theme
mkdir -p lib/core/utils
mkdir -p lib/core/widgets

# router
mkdir -p lib/router

# features (auth, home 기본 생성 — 프로젝트에 맞게 수정)
for feature in auth home; do
  mkdir -p lib/features/$feature/data/datasources
  mkdir -p lib/features/$feature/data/models
  mkdir -p lib/features/$feature/data/repositories
  mkdir -p lib/features/$feature/domain/entities
  mkdir -p lib/features/$feature/domain/repositories
  mkdir -p lib/features/$feature/domain/usecases
  mkdir -p lib/features/$feature/presentation/screens
  mkdir -p lib/features/$feature/presentation/widgets
  mkdir -p lib/features/$feature/presentation/providers
done

echo "✅ 폴더 구조 생성 완료"
find lib -type d | sort
```

---

## STEP 8 — 보일러플레이트 파일 작성

### `lib/main.dart`

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 다국어 초기화
  await EasyLocalization.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase 초기화 (dart-define으로 주입)
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // 화면 세로 고정
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 상태바 투명
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const App(),
      ),
    ),
  );
}
```

---

### `lib/app.dart`

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'App Name',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        // 시스템 폰트 크기 무시 — 디자인 고정
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}
```

---

### `lib/router/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/home/presentation/screens/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // TODO: 인증 상태 체크 추가
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('페이지를 찾을 수 없어요: ${state.uri}')),
    ),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(
          context, state, const HomeScreen(),
        ),
      ),
    ],
  );
});

// 플랫폼별 화면 전환 애니메이션
CustomTransitionPage<void> _buildPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (isIOS) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      }
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    },
  );
}
```

---

### `lib/core/providers/app_providers.dart`

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SharedPreferences — main()에서 override
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main()에서 override 필요');
});

// Supabase Client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 현재 로그인 유저 ID (null = 미로그인)
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});
```

---

### `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_values.dart';

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
        surface: isLight ? AppColors.surface : AppColors.surfaceDark,
        primary: AppColors.primary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor:
          isLight ? AppColors.background : AppColors.backgroundDark,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor:
            isLight ? AppColors.background : AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.heading3.copyWith(
          color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
        ),
        iconTheme: IconThemeData(
          color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
          size: AppValues.iconL,
        ),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
                .copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Colors.transparent),
      ),

      // TextTheme
      textTheme: _buildTextTheme(isLight),

      // Divider
      dividerTheme: DividerThemeData(
        color: isLight
            ? AppColors.border
            : AppColors.border.withOpacity(0.2),
        thickness: 1,
        space: 0,
      ),

      // Card
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppValues.radiusM),
          side: BorderSide(
            color: isLight
                ? AppColors.border
                : AppColors.border.withOpacity(0.15),
          ),
        ),
        color: isLight ? AppColors.surface : AppColors.surfaceDark,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isLight) {
    final color =
        isLight ? AppColors.textPrimary : AppColors.textPrimaryDark;
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

---

### `lib/core/constants/app_colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — 프로젝트에 맞게 교체
  static const Color primary      = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFFE0E7FF);
  static const Color secondary    = Color(0xFF8B5CF6);
  static const Color accent       = Color(0xFFF59E0B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Background (Light)
  static const Color background       = Color(0xFFFAFAFA);
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceVariant   = Color(0xFFF3F4F6);
  static const Color surfaceContainer = Color(0xFFE5E7EB);

  // Background (Dark)
  static const Color backgroundDark     = Color(0xFF0F0F0F);
  static const Color surfaceDark        = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF262626);

  // Text (Light)
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);
  static const Color textDisabled  = Color(0xFFD1D5DB);

  // Text (Dark)
  static const Color textPrimaryDark   = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Border
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF6366F1);
}
```

---

### `lib/core/constants/app_values.dart`

```dart
class AppValues {
  AppValues._();

  // Spacing
  static const double space2  = 2;
  static const double spaceXS = 4;
  static const double spaceS  = 8;
  static const double spaceM  = 12;
  static const double spaceL  = 16;
  static const double spaceXL = 24;
  static const double space2X = 32;
  static const double space3X = 48;
  static const double space4X = 64;

  // Padding
  static const double paddingXS = 4;
  static const double paddingS  = 8;
  static const double paddingM  = 12;
  static const double paddingL  = 16;
  static const double paddingXL = 24;
  static const double padding2X = 32;

  // Border Radius
  static const double radiusXS   = 4;
  static const double radiusS    = 8;
  static const double radiusM    = 12;
  static const double radiusL    = 16;
  static const double radiusXL   = 20;
  static const double radius2X   = 24;
  static const double radiusFull = 999;

  // Elevation
  static const double elevationNone = 0;
  static const double elevationXS   = 1;
  static const double elevationS    = 2;
  static const double elevationM    = 4;
  static const double elevationL    = 8;

  // Icon Size
  static const double iconXS = 12;
  static const double iconS  = 16;
  static const double iconM  = 20;
  static const double iconL  = 24;
  static const double iconXL = 32;
  static const double icon2X = 48;

  // Touch Target
  static const double touchTarget    = 48;
  static const double touchTargetMin = 44;

  // Button
  static const double buttonHeightS = 40;
  static const double buttonHeightM = 48;
  static const double buttonHeightL = 56;

  // AppBar
  static const double appBarHeight = 56;

  // BottomNav
  static const double bottomNavHeight = 64;

  // Max Content Width
  static const double maxContentWidth = 480;
}
```

---

### `lib/core/constants/app_typography.dart`

```dart
import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard'; // 폰트 없으면 기본 폰트 사용

  static const TextStyle display1 = TextStyle(fontFamily: fontFamily, fontSize: 40, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5);
  static const TextStyle display2 = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.3);
  static const TextStyle heading1 = TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.2);
  static const TextStyle heading2 = TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, height: 1.35, letterSpacing: -0.1);
  static const TextStyle heading3 = TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle bodyLg   = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static const TextStyle body     = TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, height: 1.6);
  static const TextStyle bodySm   = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle labelLg  = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.1);
  static const TextStyle label    = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.1);
  static const TextStyle labelSm  = TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle caption  = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: 0.2);
  static const TextStyle captionBold = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.2);
  static const TextStyle overline = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0.8);
}
```

---

### `lib/core/errors/failure.dart`

```dart
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

// UI에서 사용
String mapFailureToMessage(Object error) {
  return switch (error) {
    NetworkFailure()  => '인터넷 연결을 확인해 주세요',
    AuthFailure()     => '로그인이 필요해요',
    NotFoundFailure() => '데이터를 찾을 수 없어요',
    ServerFailure(message: final msg) => msg,
    UnknownFailure(message: final msg) => msg,
    _ => '알 수 없는 오류가 발생했어요',
  };
}
```

---

### `lib/core/extensions/context_extension.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;
}
```

---

### `lib/core/utils/logger.dart`

```dart
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) debugPrint('[DEBUG] $message${error != null ? '\nError: $error' : ''}');
  }

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[WARN] $message${error != null ? '\nError: $error' : ''}');
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('[ERROR] $message${error != null ? '\nError: $error' : ''}');
    // TODO: Firebase Crashlytics 연동 시 여기에 추가
  }
}
```

---

### `lib/features/home/presentation/screens/home_screen.dart` (임시)

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            '🚀 세팅 완료!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}
```

---

## build_runner 초기 실행

모든 파일 작성 완료 후 실행:

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
fvm flutter analyze
```

에러 없으면 다음 단계 진행.
