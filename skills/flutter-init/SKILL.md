---
name: flutter-init
description: "Flutter 신규 프로젝트 초기 세팅을 처음부터 끝까지 실행한다. 패키지 설치, 클린 아키텍처 구조 생성, Firebase/Supabase 연결, Android/iOS 플랫폼 설정까지 포함한다. 새 Flutter 프로젝트 시작, 초기 세팅, 프로젝트 셋업 요청 시 반드시 이 스킬을 사용한다."
---

# Flutter Init

신규 Flutter 프로젝트를 처음부터 끝까지 세팅한다. 순서대로 빠짐없이 실행한다.

---

## STEP 1. 주석 제거

```bash
find . -name "*.dart" \
  -not -path "*/.*" \
  -not -path "*/build/*" \
  -not -path "*/.dart_tool/*" | xargs sed -i 's|//.*$||g; /^[[:space:]]*$/d'
```

---

## STEP 2. analysis_options.yaml

`formatter:` 섹션이 없으면 파일 하단에 추가한다.

```yaml
formatter:
  trailing_commas: preserve
```

---

## STEP 3. 패키지 설치

```bash
fvm flutter pub add go_router
fvm flutter pub add easy_localization
fvm flutter pub add json_annotation
fvm flutter pub add shared_preferences
fvm flutter pub add flutter_native_splash
fvm flutter pub add hooks_riverpod
fvm flutter pub add flutter_hooks
fvm flutter pub add velocity_x
fvm flutter pub add app_tracking_transparency
fvm flutter pub add font_awesome_flutter
fvm flutter pub add google_mobile_ads
fvm flutter pub add firebase_core
fvm flutter pub add firebase_analytics
fvm flutter pub add supabase_flutter

fvm flutter pub add -d build_runner
fvm flutter pub add -d json_serializable
fvm flutter pub add -d flutter_launcher_icons
```

---

## STEP 4. assets 폴더 구조

```bash
mkdir -p assets/translations assets/images assets/icons assets/fonts
echo '{}' > assets/translations/en.json
echo '{}' > assets/translations/ko.json
```

`pubspec.yaml` `flutter:` 섹션에 추가:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/translations/
    - assets/images/
    - assets/icons/
```

---

## STEP 5. Firebase 초기화

```bash
# 최초 1회
npm install -g firebase-tools
dart pub global activate flutterfire_cli

firebase login
flutterfire configure
```

`flutterfire configure` 실행 시 Firebase 프로젝트 선택 → Android/iOS 플랫폼 선택 → `firebase_options.dart` 자동 생성.

> `firebase_options.dart`는 API 키 포함 — `.gitignore`에 추가 권장.

---

## STEP 6. Supabase MCP 설정

프로젝트 루트에 `.mcp.json` 생성:

```json
{
  "supabase": {
    "command": "npx",
    "args": ["-y", "@supabase/mcp-server-supabase@latest"],
    "env": {
      "SUPABASE_ACCESS_TOKEN": "your_personal_access_token"
    }
  }
}
```

토큰은 [https://supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) 에서 발급.

MCP 연결 후 URL/키 확인:

```
Supabase MCP로 이 프로젝트의 SUPABASE_URL과 SUPABASE_ANON_KEY 가져와줘
```

`--dart-define`으로 주입:

```bash
fvm flutter run \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

---

## STEP 7. 클린 아키텍처 폴더 구조

Feature-first 구조. screens/는 UI 화면, 전역 Provider는 core/providers/.

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
│   ├── providers/           # 전역 Provider (router, supabase, prefs 등)
│   │   └── app_providers.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── logger.dart
├── router/
│   └── app_router.dart
└── features/
    └── [feature_name]/
        ├── data/
        │   ├── datasources/
        │   │   └── [feature]_remote_datasource.dart
        │   ├── models/
        │   │   └── [feature]_model.dart
        │   └── repositories/
        │       └── [feature]_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── [feature]_entity.dart
        │   ├── repositories/
        │   │   └── [feature]_repository.dart
        │   └── usecases/
        │       └── get_[feature]_usecase.dart
        └── presentation/
            ├── screens/
            │   └── [feature]_screen.dart
            ├── widgets/
            │   └── [feature]_widget.dart
            └── providers/
                └── [feature]_provider.dart
```

```bash
mkdir -p lib/core/constants lib/core/errors lib/core/extensions
mkdir -p lib/core/providers lib/core/theme lib/core/utils
mkdir -p lib/router

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
```

---

## STEP 8. 보일러플레이트 작성

### `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
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

### `lib/app.dart`

```dart
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### `lib/router/app_router.dart`

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
```

### `lib/core/providers/app_providers.dart`

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // main()에서 override
});

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

### `lib/core/theme/app_theme.dart`

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    // 추가 테마 설정
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}
```

---

## STEP 9. Android 설정

### `android/app/build.gradle`

`defaultConfig` 블록에 추가:

```groovy
defaultConfig {
    multiDexEnabled = true
}
```

### `android/app/src/main/AndroidManifest.xml`

`<application>` 태그 안에 추가 (테스트 키 — 배포 전 교체):

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

---

## STEP 10. iOS 설정

### `ios/Runner/Info.plist`

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>NSUserTrackingUsageDescription</key>
<string>You need to bring an advertising identifier of your device to provide more interesting ads in the app. The identified information is not transmitted or collected to the server.</string>

<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

> `GADApplicationIdentifier` 테스트 키 — 배포 전 실제 ID로 교체.

---

## STEP 11. .gitignore 추가

```
# Firebase
google-services.json
GoogleService-Info.plist
firebase_options.dart

# Supabase
.env
shrimp_data/
```

---

## 완료 후 안내

세팅 완료 후 사용자에게 아래를 안내한다.

### 배포 전 필수

| 항목         | 할 일                                                                       |
| ------------ | --------------------------------------------------------------------------- |
| AdMob App ID | AndroidManifest.xml, Info.plist 테스트 키 → 실제 ID 교체                    |
| Supabase 키  | `SUPABASE_URL`, `SUPABASE_ANON_KEY` 환경변수 설정                           |
| 런처 아이콘  | `pubspec.yaml` 아이콘 등록 후 `fvm dart run flutter_launcher_icons`         |
| 스플래시     | `pubspec.yaml` 스플래시 설정 후 `fvm dart run flutter_native_splash:create` |

### 권장

| 항목           | 내용                                                                     |
| -------------- | ------------------------------------------------------------------------ |
| iOS Podfile    | `platform :ios, '13.0'` 이상 확인                                        |
| Android minSdk | `minSdk = 21` 이상 확인                                                  |
| ATT 권한       | 앱 시작 시 `AppTrackingTransparency.requestTrackingAuthorization()` 호출 |

---

## 체크리스트

```
[ ] 주석 제거
[ ] analysis_options.yaml formatter 설정
[ ] 패키지 전체 설치
[ ] assets/ 폴더 구조 및 pubspec.yaml 등록
[ ] flutterfire configure 실행
[ ] .mcp.json Supabase MCP 등록
[ ] 클린 아키텍처 폴더 구조 생성
[ ] main.dart / app.dart / app_router.dart / app_providers.dart 작성
[ ] Android multiDexEnabled = true
[ ] Android AndroidManifest AdMob 테스트 ID
[ ] iOS Info.plist 3개 항목 추가
[ ] .gitignore 추가
[ ] 실제 AdMob ID 교체 (배포 전)
```
