# Platform Reference

## STEP 9 — Android 설정

### android/app/build.gradle — 전체 defaultConfig

```groovy
android {
    namespace "com.example.app"    // 앱 패키지명으로 교체
    compileSdk 34

    defaultConfig {
        applicationId "com.example.app"    // 앱 패키지명으로 교체
        minSdk 21          // 필수 — 대부분 플러그인 요구사항
        targetSdk 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true   // 필수 — 메서드 수 초과 방지
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug  // 배포 전 실제 키스토어로 교체
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'  // multiDex 활성화 시 추가
}
```

---

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- 인터넷 권한 (Supabase, Firebase 필수) -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- 광고 ID 접근 (AdMob 선택) -->
    <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>

    <application
        android:label="앱 이름"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true"
        android:hardwareAccelerated="true">

        <!-- AdMob App ID (테스트 키 — 배포 전 실제 ID로 교체) -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>

        <!-- 상태바 투명 처리 -->
        <item name="android:windowTranslucentStatus">true</item>
        <item name="android:windowTranslucentNavigation">true</item>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Flutter 기본 인텐트 필터 -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Deep Link (Supabase Auth) -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data
                    android:scheme="https"
                    android:host="YOUR_PROJECT_REF.supabase.co"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

---

### android/build.gradle — Kotlin 버전 확인

```groovy
buildscript {
    ext.kotlin_version = '1.9.10'  // 최신 안정 버전 확인 후 설정
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

---

## STEP 10 — iOS 설정

### ios/Runner/Info.plist — 전체 필수 항목

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>

    <!-- ── 앱 기본 ─────────────────────────────────────────────────── -->
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>앱 이름</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>앱 이름</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>

    <!-- ── 암호화 면제 ────────────────────────────────────────────── -->
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>

    <!-- ── 광고 / ATT ─────────────────────────────────────────────── -->
    <key>NSUserTrackingUsageDescription</key>
    <string>더 관련성 높은 광고를 제공하기 위해 광고 식별자에 접근합니다. 개인정보는 수집·전송되지 않습니다.</string>

    <key>GADApplicationIdentifier</key>
    <string>ca-app-pub-3940256099942544~1458002511</string>
    <!-- ↑ 테스트 키 — 배포 전 실제 AdMob App ID로 교체 -->

    <!-- ── 배경 실행 (FCM 푸시 알림) ──────────────────────────────── -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>

    <!-- ── 화면 방향 (세로 고정) ──────────────────────────────────── -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>

    <!-- ── 기타 ────────────────────────────────────────────────────── -->
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>

</dict>
</plist>
```

> **필요 시 권한 추가** (사용하는 기능에 따라):
```xml
<!-- 카메라 -->
<key>NSCameraUsageDescription</key>
<string>사진 촬영을 위해 카메라 접근이 필요합니다</string>

<!-- 사진 라이브러리 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>사진 선택을 위해 갤러리 접근이 필요합니다</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>사진 저장을 위해 갤러리 접근이 필요합니다</string>

<!-- 위치 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>현재 위치 확인을 위해 위치 정보가 필요합니다</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>백그라운드 위치 추적을 위해 위치 정보가 필요합니다</string>

<!-- 마이크 -->
<key>NSMicrophoneUsageDescription</key>
<string>음성 녹음을 위해 마이크 접근이 필요합니다</string>

<!-- 연락처 -->
<key>NSContactsUsageDescription</key>
<string>연락처 검색을 위해 접근이 필요합니다</string>
```

---

### ios/Podfile — 최소 버전 + M1/M2 대응

```ruby
# ios/Podfile
platform :ios, '13.0'  # 13.0 이상 권장

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end
  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig and running flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # M1/M2 Mac 시뮬레이터 arm64 제외 (빌드 에러 방지)
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

---

## STEP 11 — .gitignore 추가

`.gitignore` 파일에 아래 항목 추가:

```gitignore
# ── Firebase ──────────────────────────────────────────────────────────────────
google-services.json
GoogleService-Info.plist
lib/firebase_options.dart

# ── Supabase / 환경변수 ────────────────────────────────────────────────────────
.env
.env.*
.mcp.json        # 액세스 토큰 포함

# ── Flutter 기본 ───────────────────────────────────────────────────────────────
# Flutter/Dart/Pub 관련 (이미 있을 수 있음)
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
*.iml
*.log

# ── IDE ────────────────────────────────────────────────────────────────────────
.idea/
.vscode/
*.swp
*.swo

# ── macOS ─────────────────────────────────────────────────────────────────────
.DS_Store
*.DS_Store

# ── 기타 ──────────────────────────────────────────────────────────────────────
shrimp_data/
coverage/
```

> **주의**: `build_runner`가 생성하는 `.g.dart` 파일은 Git에 **커밋한다**.
> CI/CD 환경에서 build_runner 재실행이 번거롭고, 생성 결과가 결정적이기 때문.

---

## 최종 빌드 확인

```bash
# 전체 분석
fvm flutter analyze

# Android 디버그 빌드 확인
fvm flutter build apk --debug

# iOS 디버그 빌드 확인 (macOS 필요)
fvm flutter build ios --debug --no-codesign

# 실제 실행
fvm flutter run
```

모두 에러 없으면 세팅 완료.
