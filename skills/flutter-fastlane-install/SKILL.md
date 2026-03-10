---
description: Mac에서 Fastlane을 처음 설치하는 스킬. Homebrew, Ruby, Fastlane 설치 및 Flutter 프로젝트에 초기 세팅까지 다룬다. "Fastlane 설치", "설치 ㄱㄱ", "처음 세팅" 등의 요청에 반드시 이 스킬을 사용할 것.
---

# Fastlane 설치 (Mac 전용)

---

## Step 1. Homebrew 확인

```bash
brew -v
```

**결과별 대응:**

- 버전 뜨면 → Step 2로
- `command not found` 뜨면 → 아래 설치 먼저

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치 후 터미널 재시작하고 `brew -v` 다시 확인.

---

## Step 2. Ruby 확인 및 세팅

```bash
ruby -v
```

**결과별 대응:**

- `ruby 2.6` 이상 → Step 3으로
- 버전 낮거나 없으면 → rbenv로 관리

```bash
brew install rbenv ruby-build

# .zshrc에 rbenv 추가
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Ruby 설치
rbenv install 3.2.0
rbenv global 3.2.0

# 확인
ruby -v
```

> ⚠️ Mac 기본 Ruby(`/usr/bin/ruby`)는 시스템 Ruby라 건드리면 안 됨. rbenv로 별도 설치하는 게 정석.

---

## Step 3. Fastlane 설치 및 최신 버전 유지

```bash
brew install fastlane
```

설치 완료 후 확인:

```bash
fastlane -v
```

버전 숫자 뜨면 OK. 예시: `fastlane 2.232.2`

**`command not found` 뜨면:**

```bash
echo 'export PATH="$HOME/.fastlane/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
fastlane -v
```

**이미 설치된 경우 → 최신 버전으로 업데이트:**

```bash
brew upgrade fastlane
```

> ⚠️ Fastlane이 오래된 버전이면 App Store Connect API 호환 오류 발생 가능. 배포 전 항상 `brew upgrade fastlane` 한 번씩 실행 권장.

---

## Step 4. Xcode Command Line Tools 확인 (iOS 필수)

```bash
xcode-select -p
```

경로가 뜨면 OK. 없으면:

```bash
xcode-select --install
```

팝업 뜨면 설치 클릭. 시간 좀 걸림.

---

## Step 5. Flutter 프로젝트에 Fastlane 초기화

### iOS

```bash
cd your_flutter_app/ios
fastlane init
```

물어보는 것들:

```
What would you like to use fastlane for?
1. Automate screenshots
2. Automate beta distribution to TestFlight  ← 이거 선택 (2)
3. Automate App Store distribution
4. Manual setup

Apple ID: your@email.com 입력
App Identifier: com.yourcompany.yourapp 입력
```

완료되면 `ios/fastlane/` 폴더 안에 `Fastfile`, `Appfile` 자동 생성됨.

### Android

```bash
cd your_flutter_app/android
fastlane init
```

물어보는 것들:

```
Package Name: com.yourcompany.yourapp 입력
Path to JSON secret file: (일단 엔터 → 나중에 설정)
```

완료되면 `android/fastlane/` 폴더 안에 `Fastfile`, `Appfile` 자동 생성됨.

---

## Step 6. Appfile 설정

### iOS `ios/fastlane/Appfile`

```ruby
app_identifier("com.yourcompany.yourapp")   # 번들 ID
apple_id("your@email.com")                  # Apple ID
team_id("XXXXXXXXXX")                       # 팀 ID
```

**팀 ID 확인 방법:**
[developer.apple.com](https://developer.apple.com/account) → Membership → Team ID

### Android `android/fastlane/Appfile`

```ruby
json_key_file("fastlane/google-play-key.json")   # API 키 경로
package_name("com.yourcompany.yourapp")           # 패키지명
```

---

## Step 7. Google Play API 키 발급 (Android 필수)

1. [Google Play Console](https://play.google.com/console) 접속
2. 설정 → API 액세스 → Google Cloud 프로젝트 연결
3. 서비스 계정 만들기 클릭
4. [Google Cloud Console](https://console.cloud.google.com) → IAM → 서비스 계정 → 키 만들기 → JSON 선택
5. 다운로드된 JSON 파일 → `android/fastlane/google-play-key.json`으로 이름 바꾸고 이동
6. Google Play Console로 돌아와서 해당 서비스 계정에 **릴리즈 관리자** 권한 부여

> ⚠️ `PERMISSION_DENIED` 에러 뜨면 → [Google Cloud Console](https://console.cloud.google.com) → APIs & Services → Enable APIs → **Google Play Android Developer API** 검색 → 활성화

**`.gitignore`에 반드시 추가:**

```
**/fastlane/google-play-key.json
```

### Android Fastfile 전체 교체

`android/fastlane/Fastfile`을 아래로 교체:

```ruby
default_platform(:android)

platform :android do
  desc "Build AAB and upload to Google Play internal track"
  lane :beta do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "./"
    )
    upload_to_play_store(
      track: "internal",
      aab: "../build/app/outputs/bundle/release/app-release.aab"
    )
  end

  desc "Promote internal track to production"
  lane :release do
    upload_to_play_store(
      track: "internal",
      track_promote_to: "production",
      # 프로모트 시 메타데이터 업로드 불필요 — 아래 skip 옵션 필수
      skip_upload_apk: true,
      skip_upload_aab: true,
      skip_upload_metadata: true,
      skip_upload_changelogs: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
```

> ⚠️ `release` 레인에서 skip 옵션 없으면 "Cannot find changelog, no version code given" 에러 발생.
> Android 프로덕션 프로모트 후 심사 제출은 **Google Play Console에서 직접** 해야 함.
> Play Console → 프로덕션 → **"검토를 위해 출시 전송"** 버튼 클릭

---

## Step 8. App Store Connect API Key 발급 (iOS 필수)

Xcode가 자동으로 뜨는 것 방지. 이 설정을 해야 `fastlane beta` 한 줄로 자동 업로드 가능.

### 키 정보 (헤이나우)

| 항목      | 값                                     |
| --------- | -------------------------------------- |
| Key ID    | `Q4HF636LXV`                           |
| Issuer ID | `40765efc-ec69-4b49-bd1c-3efd712f27a3` |
| .p8 파일  | `fastlane/AuthKey_Q4HF636LXV.p8`       |

### 키 발급 (신규 발급 시)

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 사용자 및 액세스 → 통합 → App Store Connect API
2. `+` 버튼 → 이름 입력, 액세스: **앱 관리** 선택
3. 생성 후 **Key ID** 메모, **.p8 파일 다운로드** (딱 한 번만 가능)
4. **Issuer ID** 메모 (페이지 상단 UUID)

### 파일 배치

```
ios/fastlane/AuthKey_XXXXXXXXXX.p8
```

**`.gitignore`에 반드시 추가:**

```
**/fastlane/AuthKey_*.p8
```

### iOS Fastfile 전체 교체

`ios/fastlane/Fastfile`을 아래로 교체:

```ruby
default_platform(:ios)

platform :ios do
  def get_api_key
    app_store_connect_api_key(
      key_id: "XXXXXXXXXX",           # AuthKey 파일명에서 추출
      issuer_id: "XXXXXXXX-XXXX-...", # App Store Connect 웹 상단 UUID
      key_filepath: "fastlane/AuthKey_XXXXXXXXXX.p8"
    )
  end

  def prepare_signing(api_key)
    # Distribution 인증서 자동 생성 + 프로비저닝 프로파일 갱신
    # ⚠️ 이 두 줄 없으면 "No signing certificate iOS Distribution" 에러 발생
    cert(api_key: api_key, keychain_password: ENV["KEYCHAIN_PASSWORD"])
    sigh(api_key: api_key, force: true)
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    api_key = get_api_key
    prepare_signing(api_key)
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
      configuration: "Release",
      export_xcargs: "-allowProvisioningUpdates"
    )
    upload_to_testflight(
      api_key: api_key,
      skip_waiting_for_build_processing: true
    )
  end

  desc "Build and upload to App Store (심사 미제출)"
  lane :release do
    api_key = get_api_key
    prepare_signing(api_key)
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
      configuration: "Release",
      export_xcargs: "-allowProvisioningUpdates"
    )
    upload_to_app_store(
      api_key: api_key,
      force: true,
      submit_for_review: false,
      automatic_release: false,
      skip_screenshots: true
    )
  end

  desc "App Store 업로드 + 심사 자동 제출"
  lane :submit do
    api_key = get_api_key
    prepare_signing(api_key)
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store",
      configuration: "Release",
      export_xcargs: "-allowProvisioningUpdates"
    )
    upload_to_app_store(
      api_key: api_key,
      force: true,
      submit_for_review: true,
      automatic_release: false,
      skip_screenshots: true,                   # 이미 제출된 버전 있으면 스크린샷 재정렬 에러 방지
      precheck_include_in_app_purchases: false, # API Key로는 인앱구매 precheck 불가
      submission_information: {
        add_id_info_uses_idfa: false
      }
    )
  end
end
```

> ⚠️ `cert` + `sigh` 없으면 첫 배포 시 "No signing certificate iOS Distribution found" 에러 발생. 반드시 포함할 것.

---

## Step 9. .env 파일 설정 (마지막 필수 단계)

Apple 계정 정보를 파일로 관리해서 매번 입력 안 해도 되게 설정.

```bash
touch ios/fastlane/.env
```

`ios/fastlane/.env` 내용:

```
APPLE_ID=your@email.com
TEAM_ID=XXXXXXXXXX
KEYCHAIN_PASSWORD=your_mac_login_password  # cert 액션이 키체인 접근 시 필요
```

> `KEYCHAIN_PASSWORD`는 Mac 로그인 비밀번호. 없으면 `fastlane beta/submit` 실행 시 키체인 비밀번호 프롬프트 뜸.

`.gitignore`에 반드시 추가:

```
**/fastlane/.env
```

이제부터 배포는:

```bash
cd ios && fastlane beta      # TestFlight 업로드
cd ios && fastlane submit    # App Store 업로드 + 심사 제출
cd android && fastlane beta  # Google Play 내부트랙
cd android && fastlane release  # 내부트랙 → 프로덕션 프로모트
```

---

## 완료 체크

```
✅ brew -v 버전 확인
✅ ruby -v 2.6 이상 (rbenv 버전)
✅ fastlane -v 버전 확인
✅ xcode-select -p 경로 확인
✅ ios/fastlane/Fastfile 생성됨 (cert + sigh + KEYCHAIN_PASSWORD 포함)
✅ ios/fastlane/Appfile 설정 완료
✅ android/fastlane/Fastfile 생성됨
✅ android/fastlane/Appfile 설정 완료
✅ google-play-key.json 위치 확인
✅ App Store Connect API Key 발급 및 .p8 파일 배치
✅ Fastfile에 api_key + cert + sigh 설정 완료
✅ ios/fastlane/.env 생성 (APPLE_ID + TEAM_ID + KEYCHAIN_PASSWORD)
✅ .gitignore에 .env + key 파일 추가
```

---

## 트러블슈팅

| 오류                                              | 원인                              | 해결                                                                                           |
| ------------------------------------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------- |
| `fastlane: command not found`                     | PATH 미등록                       | `echo 'export PATH="$HOME/.fastlane/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc`                |
| `Ruby version too old`                            | 시스템 Ruby 사용 중               | rbenv로 Ruby 재설치                                                                            |
| `No Xcode installation`                           | Xcode CLI 없음                    | `xcode-select --install`                                                                       |
| `Invalid Apple ID`                                | 2FA 문제                          | 앱 전용 비밀번호 사용                                                                          |
| `Permission denied (Google Play)`                 | 서비스 계정 권한 부족 or API 미활성화 | Play Console에서 릴리즈 관리자 권한 부여 + Google Cloud Console에서 `androidpublisher` API 활성화 |
| `json_key_file not found`                         | 키 파일 경로 틀림                 | Appfile 경로와 실제 파일 위치 일치 확인                                                        |
| `No signing certificate "iOS Distribution" found` | Keychain에 배포용 인증서 없음     | Fastfile에 `cert` + `sigh` 추가 (Step 8 Fastfile 템플릿 참고)                                  |
| `Keychain password prompt`                        | KEYCHAIN_PASSWORD 미설정          | `ios/fastlane/.env`에 `KEYCHAIN_PASSWORD=맥로그인비밀번호` 추가                                 |
| `Unsupported directory name: ko-KR` (iOS)         | iOS 메타데이터 폴더명 오류        | `ios/fastlane/metadata/ko/` 폴더 사용 (ko-KR 아님!)                                            |
| `Can't Reorder Assets after Submission`           | 이미 심사 제출된 버전 있음        | `upload_to_app_store`에 `skip_screenshots: true` 추가                                          |
| `Precheck cannot check In-app purchases`          | API Key로 인앱구매 조회 불가      | `upload_to_app_store`에 `precheck_include_in_app_purchases: false` 추가                        |
| `Cannot find changelog, no version code given`    | Android changelog 파일명 오류     | `changelogs/default.txt` → `changelogs/{빌드번호}.txt` 로 파일 생성 (예: `37.txt`)              |

**iOS 인증서 사전 체크:**

```bash
security find-identity -v -p codesigning | grep "iPhone Distribution"
```

**Google Play API 활성화 (PERMISSION_DENIED 시):**

```
Google Cloud Console → APIs & Services → Enable APIs → Android Publisher API 검색 → 활성화
```
