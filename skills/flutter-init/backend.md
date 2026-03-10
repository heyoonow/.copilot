# Backend Reference

## STEP 5 — Firebase 초기화

### 사전 조건

```bash
# Firebase CLI 설치 (최초 1회)
npm install -g firebase-tools

# FlutterFire CLI 설치 (최초 1회)
dart pub global activate flutterfire_cli

# PATH에 pub global 추가 확인
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Firebase 프로젝트 연결

```bash
# Firebase 로그인
firebase login

# Flutter 프로젝트와 Firebase 연결
flutterfire configure
```

`flutterfire configure` 실행 흐름:
1. Firebase 프로젝트 선택 (또는 새 프로젝트 생성)
2. 플랫폼 선택: android, ios (web은 불필요 시 제외)
3. `lib/firebase_options.dart` 자동 생성됨
4. `android/app/google-services.json` 자동 생성됨
5. `ios/Runner/GoogleService-Info.plist` 자동 생성됨

### firebase_options.dart 사용

```dart
// lib/main.dart — Firebase 초기화
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

> `firebase_options.dart` — API 키 포함 파일. `.gitignore`에 추가 권장.
> 팀 작업 시 별도 안전한 채널로 공유.

### android/build.gradle 확인

```groovy
// android/build.gradle — google-services 플러그인
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0' // 버전 자동 추가됨
    }
}
```

### android/app/build.gradle 확인

```groovy
// android/app/build.gradle — 마지막 줄에 있어야 함
apply plugin: 'com.google.gms.google-services'
```

---

## STEP 6 — Supabase MCP 설정

### .mcp.json 생성 (프로젝트 루트)

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

토큰 발급: https://supabase.com/dashboard/account/tokens
→ "Generate new token" 클릭 → 이름 입력 → 토큰 복사

> `.mcp.json`에 토큰이 포함되므로 반드시 `.gitignore`에 추가.

### Supabase URL / ANON KEY 확인

MCP 연결 후 AI에게 요청:
```
Supabase MCP로 이 프로젝트의 SUPABASE_URL과 SUPABASE_ANON_KEY 가져와줘
```

또는 Supabase 대시보드에서 직접 확인:
- 프로젝트 선택 → Settings → API → Project URL / anon public key

### Supabase 실행 방식 — dart-define 주입

```bash
# 개발 실행
fvm flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxxxxx

# IDE 설정 (VS Code launch.json)
{
  "configurations": [
    {
      "name": "Flutter Dev",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://xxxx.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=eyJxxxxxx"
      ]
    }
  ]
}
```

### main.dart에서 Supabase 초기화

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

> `String.fromEnvironment()`는 빌드 시 dart-define 값으로 대체됨.
> 값이 없으면 빈 문자열 → Supabase 초기화 실패하므로 반드시 주입.

### Supabase Auth 설정 (iOS Deep Link)

```xml
<!-- ios/Runner/Info.plist에 추가 -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.YOUR_PROJECT_REF</string>
    </array>
  </dict>
</array>
```

```groovy
// android/app/build.gradle defaultConfig에 추가
manifestPlaceholders = [
  'supabaseUrl': 'https://YOUR_PROJECT_REF.supabase.co',
  'supabaseAnonKey': 'YOUR_ANON_KEY'
]
```

---

## Firebase Analytics — 기본 설정

```dart
// lib/core/providers/app_providers.dart에 추가
import 'package:firebase_analytics/firebase_analytics.dart';

final analyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

// 이벤트 로깅 헬퍼
final analyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((ref) {
  return FirebaseAnalyticsObserver(
    analytics: ref.read(analyticsProvider),
  );
});
```

```dart
// app_router.dart에 옵저버 추가
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: [ref.read(analyticsObserverProvider)], // 화면 전환 자동 트래킹
    // ...
  );
});
```

---

## ATT (App Tracking Transparency) 설정

iOS 14.5+에서 광고 트래킹 전 사용자 동의 필요.

```dart
// 앱 시작 시 (HomeScreen 또는 온보딩 완료 후) 호출
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

Future<void> requestTrackingPermission() async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await Future.delayed(const Duration(milliseconds: 300)); // 앱 초기화 대기
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}
```
