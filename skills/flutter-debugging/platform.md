# Platform Reference

## Android 에러 해결

### Gradle 빌드 실패 — 기본 정리

```bash
# 1. 캐시 전체 정리 (가장 먼저 시도)
fvm flutter clean
fvm flutter pub get

# 2. Gradle 캐시 정리
cd android && ./gradlew clean && cd ..

# 3. 전체 초기화
fvm flutter clean
cd android && ./gradlew clean
rm -rf ~/.gradle/caches/
cd .. && fvm flutter pub get

# 4. 빌드 재시도
fvm flutter build apk --debug
```

### minSdk 에러

```
Error: uses-sdk:minSdkVersion X cannot be smaller than version Y declared in library
```

```groovy
// android/app/build.gradle
defaultConfig {
    applicationId "com.example.app"
    minSdk 21        // 21 이상으로 설정 (대부분의 플러그인 요구사항)
    targetSdk 34
    versionCode 1
    versionName "1.0"
}
```

### multiDex 에러

```
Error: Cannot fit requested classes in a single dex file
```

```groovy
// android/app/build.gradle
defaultConfig {
    multiDexEnabled true  // 추가
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // 추가
}
```

### MissingPluginException

```
MissingPluginException(No implementation found for method X on channel Y)
```

```bash
# 해결 방법 1: 앱 완전 재빌드 (핫리로드 X)
fvm flutter clean
fvm flutter pub get
fvm flutter run  # 새로 빌드

# 해결 방법 2: 네이티브 플러그인 등록 확인
# android/app/src/main/kotlin/.../MainActivity.kt 확인
# 일부 플러그인은 수동 등록 필요
```

### Kotlin 버전 에러

```
error: unresolved reference: BuildConfig
Kotlin compiler version X is not compatible
```

```groovy
// android/build.gradle
buildscript {
    ext.kotlin_version = '1.9.0'  // 버전 업그레이드
    // ...
}
```

### compileSdk / targetSdk 에러

```groovy
// android/app/build.gradle
android {
    compileSdk 34     // 최신 stable
    defaultConfig {
        targetSdk 34  // compileSdk와 같거나 낮게
        minSdk 21
    }
}
```

### google-services.json 없음

```
File google-services.json is missing.
```

```bash
# Firebase Console에서 다운로드 후:
# android/app/google-services.json 에 위치시키기

# pubspec.yaml에 있어야 할 설정:
# dependencies:
#   firebase_core: ^X.X.X
```

---

## iOS 에러 해결

### Pod 충돌 — 기본 정리

```bash
# 1. Pod 재설치 (가장 먼저 시도)
cd ios
pod deintegrate
pod install
cd ..

# 2. 캐시 완전 삭제 후 재설치
cd ios
rm -rf Pods
rm -f Podfile.lock
pod install --repo-update
cd ..

# 3. fvm flutter clean 후 재시도
fvm flutter clean
fvm flutter pub get
cd ios && pod install && cd ..
```

### M1/M2 Mac 아키텍처 문제

```bash
# arm64 아키텍처 충돌 시
cd ios
arch -x86_64 pod install
cd ..

# 또는 Rosetta 터미널에서
arch -arm64 pod install

# Podfile에 아키텍처 설정 추가 (근본 해결)
```

```ruby
# ios/Podfile — post_install 블록에 추가
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # M1/M2 아키텍처 설정
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

### iOS Deployment Target 에러

```
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to X.0, but the range of supported deployment target versions is Y.0 to Z.0
```

```ruby
# ios/Podfile
platform :ios, '13.0'  # 최소 버전 올리기 (대부분의 플러그인은 12.0+ 또는 13.0+)
```

### Xcode 빌드 에러 — 완전 초기화

```bash
# 1. 전체 정리
fvm flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf .symlinks
cd ..

# 2. pub get + pod install
fvm flutter pub get
cd ios && pod install && cd ..

# 3. Xcode 캐시 정리
rm -rf ~/Library/Developer/Xcode/DerivedData

# 4. 빌드 재시도
fvm flutter build ios --debug --no-codesign
```

### GoogleService-Info.plist 없음

```
Could not locate configuration file: 'GoogleService-Info.plist'
```

```bash
# Firebase Console에서 다운로드 후:
# ios/Runner/GoogleService-Info.plist 에 위치시키기

# Xcode에서도 Runner 타겟에 파일 추가 확인
# Xcode > Runner > TARGETS > Runner > Build Phases > Copy Bundle Resources
```

### Info.plist 권한 누락

```
This app has crashed because it attempted to access privacy-sensitive data
```

```xml
<!-- ios/Runner/Info.plist -->
<!-- 필요한 권한을 추가 -->

<!-- 카메라 -->
<key>NSCameraUsageDescription</key>
<string>사진을 찍기 위해 카메라 접근이 필요합니다</string>

<!-- 사진 라이브러리 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 선택하기 위해 갤러리 접근이 필요합니다</string>

<!-- 위치 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>현재 위치를 확인하기 위해 위치 정보가 필요합니다</string>

<!-- 마이크 -->
<key>NSMicrophoneUsageDescription</key>
<string>음성 녹음을 위해 마이크 접근이 필요합니다</string>

<!-- 알림 (FCM) -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

### Code Signing 에러 (배포 시)

```bash
# 개발 중 codesign 없이 빌드
fvm flutter build ios --debug --no-codesign

# 실기기 테스트 시
fvm flutter run --release

# Xcode에서 직접 처리
# Xcode > Signing & Capabilities > Team 선택
```

---

## 공통 — fvm flutter clean 사용 시점

`fvm flutter clean`은 만능이 아니다. 아래 상황에서만 사용한다.

| 상황 | clean 필요 여부 |
|------|----------------|
| 패키지 추가/삭제 후 이상 동작 | O |
| 빌드 에러가 코드 변경 없이 발생 | O |
| 플랫폼 파일 변경 (AndroidManifest, Info.plist) | O |
| 네이티브 플러그인 추가 후 | O |
| 단순 Dart 코드 에러 | X (불필요) |
| 핫리로드 에러 | X (핫리스타트 먼저) |
| pub get 실패 | X (pub get 재시도 먼저) |

---

## 실기기 디버깅

```bash
# 연결된 디바이스 확인
fvm flutter devices

# 특정 디바이스로 실행
fvm flutter run -d [device-id]

# 로그 확인
fvm flutter logs

# 릴리즈 모드로 실행 (성능 측정)
fvm flutter run --release

# 프로파일 모드 (DevTools 사용 가능)
fvm flutter run --profile
```
