---
name: fastlane-first
description: Fastlane 설치 후 Flutter 앱을 처음으로 App Store + Google Play에 배포하는 스킬. Fastfile 작성, 메타데이터 세팅, 스샷 준비, 빌드 & 업로드 전 과정을 다룬다. "첫배포", "처음 올리기", "스토어 등록" 등의 요청에 반드시 이 스킬을 사용할 것.
---

# 첫 배포 (App Store + Google Play)

## 전체 흐름

```
Fastfile 작성 → Appfile 확인 → 메타데이터 작성 → 스샷 준비 → 빌드 → 업로드 → 심사 제출 (직접)
```

> ⚠️ 심사 제출은 Fastlane이 절대 자동으로 하지 않음. 마지막은 항상 직접.

---

## Step 1. Appfile 확인

### iOS `ios/fastlane/Appfile`

```ruby
app_identifier("com.yourcompany.yourapp")   # 번들 ID - 앱마다 다름
apple_id("heyoonow@gmail.com")              # 고정
team_id("48KKS3W2LW")                       # 고정
```

> ⚠️ `itc_team_id`는 절대 넣지 말 것. 오류 남.

### Android `android/fastlane/Appfile`

```ruby
json_key_file("fastlane/google-play-key.json")   # google-play-key.json 복사해서 넣기
package_name("com.yourcompany.yourapp")           # 패키지명 - 앱마다 다름
```

---

## Step 2. iOS Fastfile 작성

`ios/fastlane/Fastfile` 전체 교체:

```ruby
default_platform(:ios)

platform :ios do

  desc "메타데이터 + 스샷 App Store 업로드"
  lane :upload_metadata do
    deliver(
      submit_for_review: false,
      automatic_release: false,
      force: true,
      skip_binary_upload: true,
      skip_screenshots: false,
      metadata_path: "./fastlane/metadata",
      screenshots_path: "./fastlane/screenshots"
    )
  end

  desc "빌드 + TestFlight 업로드"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight
  end

  desc "빌드 + App Store 업로드 (심사 제출은 직접)"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    deliver(
      submit_for_review: false,
      automatic_release: false,
      force: true,
      skip_metadata: true,
      skip_screenshots: true
    )
  end

end
```

---

## Step 3. Android Fastfile 작성

`android/fastlane/Fastfile` 전체 교체:

```ruby
default_platform(:android)

platform :android do

  desc "메타데이터 + 스샷 Google Play 업로드"
  lane :upload_metadata do
    supply(
      track: "internal",
      skip_upload_apk: true,
      skip_upload_aab: true,
      metadata_path: "./fastlane/metadata/android",
      screenshots_path: "./fastlane/screenshots"
    )
  end

  desc "빌드 + Internal Track 업로드"
  lane :beta do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "./"
    )
    upload_to_play_store(track: "internal")
  end

  desc "빌드 + Production 업로드 (심사 제출은 직접)"
  lane :release do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "./"
    )
    upload_to_play_store(
      track: "production",
      release_status: "draft"
    )
  end

end
```

---

## Step 4. 메타데이터 폴더 만들기

### iOS

```bash
mkdir -p ios/fastlane/metadata/ko-KR
mkdir -p ios/fastlane/metadata/en-US
touch ios/fastlane/metadata/ko-KR/{name,subtitle,description,keywords,release_notes,promotional_text}.txt
touch ios/fastlane/metadata/en-US/{name,subtitle,description,keywords,release_notes,promotional_text}.txt
```

### Android

```bash
mkdir -p android/fastlane/metadata/android/ko-KR/changelogs
touch android/fastlane/metadata/android/ko-KR/{title,short_description,full_description}.txt
touch android/fastlane/metadata/android/ko-KR/changelogs/default.txt
```

---

## Step 5. 메타데이터 내용 작성

| 파일                   | 내용                                 | 제한       |
| ---------------------- | ------------------------------------ | ---------- |
| `name.txt`             | 앱 이름                              | iOS 30자   |
| `subtitle.txt`         | 부제목                               | iOS 30자   |
| `description.txt`      | 상세 설명                            | iOS 4000자 |
| `keywords.txt`         | 키워드 (쉼표 구분, 공백 없이)        | iOS 100자  |
| `release_notes.txt`    | 업데이트 내용                        | iOS 4000자 |
| `promotional_text.txt` | 홍보 문구 (심사 없이 수시 변경 가능) | iOS 170자  |

### 설명 글 잘 쓰는 법 (1억 다운로드 기준)

**첫 3줄이 전부다.** 유저는 "더 보기" 안 누름.

**기능 나열 ❌ → 변화 서술 ✅**

- ❌ "타이머, 통계, 알림 기능 제공"
- ✅ "3분이면 하루가 달라진다"

**구조 템플릿:**

```
[첫 줄] 유저가 얻는 결과 (감정적)
[둘째 줄] 어떻게 다른가 (차별점)
[셋째 줄] 사회적 증거 or 구체적 수치

• 기능명이 아니라 "이 기능 쓰면 어떻게 됨"

[마지막] CTA - 지금 시작하게 만드는 문장
```

### 심사 관련

| 항목                         | 심사 필요 여부 |
| ---------------------------- | -------------- |
| 앱 설명 / 키워드 / 스샷 변경 | ❌ 즉시 반영   |
| 앱 바이너리 변경             | ✅ 심사 필요   |

---

## Step 6. 스샷 준비

| 플랫폼  | 필수 사이즈                                          |
| ------- | ---------------------------------------------------- |
| iOS     | 6.9인치 (iPhone 16 Pro Max), 6.5인치 (iPhone 8 Plus) |
| Android | 폰 스샷 최소 2장, 최대 8장                           |

**가장 빠른 루트:**

1. [Previewed.app](https://previewed.app) 또는 [AppScreens](https://appscreens.com) 에서 디자인
2. 사이즈별 export
3. 폴더에 넣기:

```
ios/fastlane/screenshots/ko-KR/
├── iPhone_69-01.png
├── iPhone_69-02.png
├── iPhone_65-01.png
└── iPhone_65-02.png

android/fastlane/screenshots/ko-KR/phoneScreenshots/
├── 01.png
└── 02.png
```

---

## Step 7. 메타데이터 + 스샷 업로드

```bash
cd ios && fastlane upload_metadata
cd android && fastlane upload_metadata
```

> 설명 / 키워드 / 스샷은 심사 없이 즉시 반영됨.

---

## Step 8. 빌드 & 업로드

```bash
# 빌드
flutter build ipa
flutter build appbundle

# 업로드
cd ios && fastlane beta      # TestFlight (권장)
cd ios && fastlane release   # App Store 바로
cd android && fastlane beta  # Internal Track
cd android && fastlane release  # Production 초안
```

---

## Step 9. 심사 제출 (직접)

**iOS:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 내 앱 → 해당 버전 → 심사를 위해 제출

**Android:** [play.google.com/console](https://play.google.com/console) → 내 앱 → 프로덕션 → 초안 → 출시 검토

---

## 완료 체크

```
✅ Appfile 번들ID / 패키지명 확인
✅ google-play-key.json android/fastlane/ 에 복사
✅ iOS Fastfile 작성
✅ Android Fastfile 작성
✅ 메타데이터 폴더 생성
✅ 텍스트 파일 내용 작성
✅ 스샷 준비 & 폴더에 넣기
✅ fastlane upload_metadata 실행 (iOS + Android)
✅ flutter build ipa / appbundle 완료
✅ fastlane beta or release 실행
✅ App Store Connect 심사 제출
✅ Google Play Console 출시 검토
```

---

## 트러블슈팅

| 오류                                 | 원인                       | 해결                                    |
| ------------------------------------ | -------------------------- | --------------------------------------- |
| `No provisioning profile`            | 서명 설정 안 됨            | Xcode → Runner → Signing 자동 서명 켜기 |
| `Deliver error: Screenshots missing` | 스샷 폴더 경로 틀림        | 경로 확인 후 재실행                     |
| `Gradle build failed`                | keystore 미설정            | `android/key.properties` 확인           |
| `Authentication failed`              | Apple ID 2FA               | 앱 전용 비밀번호로 환경변수 설정        |
| `Package not found`                  | 앱 등록 안 됨              | Play Console에서 앱 먼저 수동 등록 필요 |
| `itc_team_id error`                  | Appfile에 itc_team_id 있음 | Appfile에서 해당 줄 삭제                |
