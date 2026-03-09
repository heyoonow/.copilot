---
name: fastlane-install
description: Mac에서 Fastlane을 처음 설치하는 스킬. Homebrew, Ruby, Fastlane 설치 및 Flutter 프로젝트에 초기 세팅까지 다룬다. "Fastlane 설치", "설치 ㄱㄱ", "처음 세팅" 등의 요청에 반드시 이 스킬을 사용할 것.
---

# Fastlane 설치 (Mac 전용)

## TODO

- [ ] 1. 설치
- [ ] 2. 첫배포
- [ ] 3. 패치배포

지금은 **1. 설치** 단계.

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

## Step 3. Fastlane 설치

```bash
brew install fastlane
```

설치 완료 후 확인:

```bash
fastlane -v
```

버전 숫자 뜨면 OK. 예시: `fastlane 2.219.0`

**`command not found` 뜨면:**

```bash
echo 'export PATH="$HOME/.fastlane/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
fastlane -v
```

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

**`.gitignore`에 반드시 추가:**

```
**/fastlane/google-play-key.json
```

---

## Step 8. 환경변수 설정 (선택 but 권장)

비밀번호/키를 파일에 안 넣고 환경변수로 관리:

```bash
# ~/.zshrc에 추가
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

**Apple 앱 전용 비밀번호 발급:**
[appleid.apple.com](https://appleid.apple.com) → 보안 → 앱 전용 암호 생성

---

## 완료 체크

```
✅ brew -v 버전 확인
✅ ruby -v 2.6 이상 (rbenv 버전)
✅ fastlane -v 버전 확인
✅ xcode-select -p 경로 확인
✅ ios/fastlane/Fastfile 생성됨
✅ ios/fastlane/Appfile 설정 완료
✅ android/fastlane/Fastfile 생성됨
✅ android/fastlane/Appfile 설정 완료
✅ google-play-key.json 위치 확인
✅ .gitignore에 key 파일 추가
```

---

## 트러블슈팅

| 오류                              | 원인                  | 해결                                                                            |
| --------------------------------- | --------------------- | ------------------------------------------------------------------------------- |
| `fastlane: command not found`     | PATH 미등록           | `echo 'export PATH="$HOME/.fastlane/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc` |
| `Ruby version too old`            | 시스템 Ruby 사용 중   | rbenv로 Ruby 재설치                                                             |
| `No Xcode installation`           | Xcode CLI 없음        | `xcode-select --install`                                                        |
| `Invalid Apple ID`                | 2FA 문제              | 앱 전용 비밀번호 사용                                                           |
| `Permission denied (Google Play)` | 서비스 계정 권한 부족 | Play Console에서 릴리즈 관리자 권한 부여                                        |
| `json_key_file not found`         | 키 파일 경로 틀림     | Appfile 경로와 실제 파일 위치 일치 확인                                         |
