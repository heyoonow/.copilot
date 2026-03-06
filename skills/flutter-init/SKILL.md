---
description: Flutter 신규 프로젝트 초기 세팅 (패키지 설치, 클린 아키텍처, Android/iOS 플랫폼 설정)
---

Flutter 신규 프로젝트의 초기 세팅을 아래 순서대로 빠짐없이 실행한다.

---

## STEP 1. 주석 제거

프로젝트 내 모든 Dart 파일의 주석을 제거한다. `//` 단행 주석 및 자동 생성 보일러플레이트 주석 포함.

```bash
find . -name "*.dart" \
  -not -path "*/.*" \
  -not -path "*/build/*" \
  -not -path "*/.dart_tool/*" | xargs sed -i 's|//.*$||g; /^[[:space:]]*$/d'
```

---

## STEP 2. analysis_options.yaml 수정

`formatter:` 섹션이 없으면 파일 하단에 추가한다.

```yamla
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

## STEP 4. assets 폴더 구조 생성

```bash
mkdir -p assets/translations assets/images assets/icons assets/fonts
echo '{}' > assets/translations/en.json
echo '{}' > assets/translations/ko.json
```

`pubspec.yaml`의 `flutter:` 섹션에 아래를 추가한다.

```yaml
flutter:
  assets:
    - assets/translations/
    - assets/images/
    - assets/icons/
```

---

## STEP 5. Firebase 초기화 (CLI)

Firebase CLI와 FlutterFire CLI가 설치되어 있지 않으면 먼저 설치한다.

```bash
# Firebase CLI 설치 (최초 1회)
npm install -g firebase-tools

# FlutterFire CLI 설치 (최초 1회)
dart pub global activate flutterfire_cli
```

Firebase 로그인 및 프로젝트 연결:

```bash
firebase login
flutterfire configure
```

`flutterfire configure` 실행 시:

- Firebase 프로젝트 선택 (또는 신규 생성)
- Android / iOS / 웹 플랫폼 선택
- `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` 자동 생성

생성된 `firebase_options.dart`를 main.dart에서 사용한다.

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

> `firebase_options.dart`는 API 키가 포함되므로 `.gitignore`에 추가를 권장한다.

---

## STEP 6. Supabase MCP 설정

Supabase MCP를 통해 프로젝트를 연결하고 키를 자동으로 가져온다.

### MCP 서버 등록

`.vscode/mcp.json` 파일을 생성하고 아래를 추가한다 (없으면 새로 만든다):

```json
{
  "servers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "${input:supabaseAccessToken}"
      }
    }
  },
  "inputs": [
    {
      "id": "supabaseAccessToken",
      "type": "promptString",
      "description": "Supabase Personal Access Token",
      "password": true
    }
  ]
}
```

### 토큰 발급 및 로그인

1. [https://supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) 에서 Personal Access Token 발급
2. VS Code에서 MCP 서버 시작 시 토큰 입력
3. MCP가 연결되면 Copilot에게 아래를 요청한다:

```
supabase MCP로 이 프로젝트에 연결된 SUPABASE_URL과 SUPABASE_ANON_KEY를 가져와서
--dart-define에 넣을 수 있게 정리해줘
```

### main.dart 적용

MCP에서 받은 값을 `--dart-define`으로 주입한다:

```bash
fvm flutter run \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

---

## STEP 7. 클린 아키텍처 폴더 구조 생성

Feature-first 클린 아키텍처로 구성한다. 각 feature는 `data / domain / presentation` 3레이어를 갖는다.

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_strings.dart
│   │   └── app_values.dart
│   ├── errors/
│   │   └── failure.dart
│   ├── extensions/
│   │   ├── context_extension.dart
│   │   └── string_extension.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
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
            ├── pages/
            │   └── [feature]_page.dart
            ├── widgets/
            │   └── [feature]_widget.dart
            └── providers/
                └── [feature]_provider.dart
```

```bash
mkdir -p lib/core/constants lib/core/errors lib/core/extensions lib/core/theme lib/core/utils
mkdir -p lib/router

# feature 이름은 프로젝트에 맞게 수정
for feature in auth home; do
  mkdir -p lib/features/$feature/data/datasources
  mkdir -p lib/features/$feature/data/models
  mkdir -p lib/features/$feature/data/repositories
  mkdir -p lib/features/$feature/domain/entities
  mkdir -p lib/features/$feature/domain/repositories
  mkdir -p lib/features/$feature/domain/usecases
  mkdir -p lib/features/$feature/presentation/pages
  mkdir -p lib/features/$feature/presentation/widgets
  mkdir -p lib/features/$feature/presentation/providers
done
```

### 레이어별 역할

| 레이어                   | 역할                     | 주요 패키지                            |
| ------------------------ | ------------------------ | -------------------------------------- |
| `data/datasources`       | 외부 API, DB 직접 호출   | `supabase_flutter`                     |
| `data/models`            | JSON 직렬화/역직렬화     | `json_annotation`, `json_serializable` |
| `data/repositories`      | domain repository 구현체 | -                                      |
| `domain/entities`        | 순수 도메인 객체         | -                                      |
| `domain/repositories`    | abstract interface       | -                                      |
| `domain/usecases`        | 단일 책임 비즈니스 로직  | -                                      |
| `presentation/pages`     | UI 화면                  | `go_router`, `flutter_hooks`           |
| `presentation/providers` | 상태 관리                | `hooks_riverpod`                       |

### 핵심 보일러플레이트

**`lib/main.dart`**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const App());
}
```

**`lib/app.dart`**

```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
            );
          },
        ),
      ),
    );
  }
}
```

**`lib/router/app_router.dart`**

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});
```

---

## STEP 8. Android 설정

### `android/app/build.gradle`

`defaultConfig` 블록에 추가:

```groovy
defaultConfig {
    ...
    multiDexEnabled = true
}
```

### `android/app/src/main/AndroidManifest.xml`

`<application>` 태그 안에 추가 (테스트 키 — 배포 전 교체 필수):

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

---

## STEP 9. iOS 설정

### `ios/Runner/Info.plist`

`<dict>` 안에 추가:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>NSUserTrackingUsageDescription</key>
<string>You need to bring an advertising identifier of your device to provide more interesting ads in the app. The identified information is not transmitted or collected to the server.</string>

<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

> `GADApplicationIdentifier` 값은 테스트 키. 배포 전 실제 ID로 교체 필수.

---

## STEP 10. 완료 후 안내 사항

세팅 완료 후 아래 항목들을 사용자에게 안내한다.

### 🔴 배포 전 필수 처리

| 항목         | 할 일                                                                              |
| ------------ | ---------------------------------------------------------------------------------- |
| AdMob App ID | AndroidManifest.xml, Info.plist의 테스트 키를 실제 ID로 교체                       |
| Supabase 키  | `SUPABASE_URL`, `SUPABASE_ANON_KEY` 환경변수 설정                                  |
| 런처 아이콘  | `pubspec.yaml`에 아이콘 등록 후 `fvm dart run flutter_launcher_icons` 실행         |
| 스플래시     | `pubspec.yaml`에 스플래시 설정 후 `fvm dart run flutter_native_splash:create` 실행 |

### 🟡 권장

| 항목                  | 설명                                                                     |
| --------------------- | ------------------------------------------------------------------------ |
| iOS Podfile 최소 버전 | `platform :ios, '13.0'` 이상 확인                                        |
| Android minSdk        | `minSdk = 21` 이상 확인                                                  |
| ATT 권한 요청         | 앱 시작 시 `AppTrackingTransparency.requestTrackingAuthorization()` 호출 |
| ProviderScope 확인    | `runApp(ProviderScope(child: App()))` 구조 확인                          |

---

## 체크리스트

```
[ ] 주석 제거
[ ] analysis_options.yaml formatter 설정
[ ] 패키지 전체 설치
[ ] assets/ 폴더 구조 및 pubspec.yaml 등록
[ ] flutterfire configure 실행 (firebase_options.dart 자동 생성)
[ ] .vscode/mcp.json Supabase MCP 등록 및 토큰 연결
[ ] 클린 아키텍처 폴더 구조 생성
[ ] main.dart / app.dart / app_router.dart 보일러플레이트 작성
[ ] Android multiDexEnabled = true
[ ] Android AndroidManifest AdMob 테스트 ID
[ ] iOS Info.plist 3개 항목 추가
[ ] 실제 AdMob ID 교체 (배포 전)
```
