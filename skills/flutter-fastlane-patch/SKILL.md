---
description: "Flutter 앱 패치 버전을 배포하는 스킬. 플랫폼 결정 → 버전 전략 승인 → 릴리즈 노트 작성 → 버전 업 → 빌드 → Fastlane 업로드 → 심사 제출(직접)까지 전 과정을 다룬다. '패치 배포 ㄱㄱ', '업데이트 올려줘', '패치버전 배포', '버전 올려줘' 등의 요청에 반드시 이 스킬을 사용할 것."
---

# 패치 배포 (Fastlane)

---

## 전체 흐름

```
플랫폼 결정 → 버전 전략 승인 → git log 확인 → 릴리즈 노트 작성 → 버전 업 → git 커밋/태그 → Fastlane 업로드 (빌드 포함) → 심사 제출
```

---

## ⚠️ 배포 전 안전 체크 (Step 0 전에 반드시)

```bash
# Fastlane 최신 버전 업데이트
brew upgrade fastlane

# 미커밋 변경사항 확인 — 없어야 정상
git status
```

- 미커밋 변경사항 있으면 → **커밋 또는 stash 후 진행**

---

## Step 0. 빌드 대상 플랫폼 결정

요청 메시지에서 플랫폼 키워드를 감지하여 빌드 대상을 결정한다. **별도 질문 없이 즉시 판단한다.**

| 요청 키워드                                       | 빌드 대상               |
| ------------------------------------------------- | ----------------------- |
| 키워드 없음 (예: "배포 빌드 해줘", "릴리즈 해줘") | **Android + iOS 둘 다** |
| `aos`, `안드`, `안드로이드`, `android`            | **Android만**           |
| `ios`, `아이폰`, `아이오에스`                     | **iOS만**               |
| `aos, ios`, `안드 ios`, `둘다` 등 둘 다 명시      | **Android + iOS 둘 다** |

결정된 플랫폼을 첫 줄에 명시한 뒤 바로 다음 단계로 진행한다.
예: `🎯 빌드 대상: Android + iOS`

---

## Step 1. 버전 전략 승인 (대표님 확인 필수)

`pubspec.yaml`의 현재 버전을 확인한 뒤, 아래 선택지를 제시하고 **반드시 답변을 기다린다.**

예시 (현재 버전이 `1.3.1+34`인 경우):

> **"대표님, 이번 배포의 버전 전략을 선택해 주십시오. (현재: 1.3.1+34)"**
>
> 1. 패치 버전 + 빌드 번호 올리기 → `1.3.2+35`
> 2. 마이너 버전 + 빌드 번호 올리기 → `1.4.0+35`
> 3. 메이저 버전 + 빌드 번호 올리기 → `2.0.0+35`
> 4. 버전 유지, 빌드 번호만 올리기 → `1.3.1+35`

> ⚠️ 빌드번호(`+` 뒤 숫자)는 이전보다 반드시 커야 함. 안 올리면 업로드 실패.

---

## Step 2. 변경사항 확인

마지막 배포 이후 커밋 목록 확인:

```bash
# 마지막 태그 이후 커밋 로그
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# 태그 없으면 최근 20개
git log --oneline -20
```

---

## Step 3. 릴리즈 노트 작성

커밋 내용을 보고 **유저 언어**로 변환해서 작성. **한국어/영어 둘 다** 작성한다.

### 변환 원칙

| 커밋 메시지              | 릴리즈 노트                               |
| ------------------------ | ----------------------------------------- |
| `fix: login crash`       | 로그인 시 앱이 종료되던 문제를 고쳤습니다 |
| `feat: dark mode`        | 다크모드를 추가했습니다                   |
| `refactor: performance`  | 앱 실행 속도가 빨라졌습니다               |
| `chore: update deps`     | (생략 - 유저에게 의미 없음)               |
| `클린 아키텍처 리팩토링` | 앱 안정성 및 성능 최적화                  |
| `ATT 팝업 중복 제거`     | 사용자 경험 개선                          |

### 릴리즈 노트 템플릿

```
이번 업데이트에서 달라진 것들:

• [변경사항 1]
• [변경사항 2]
• [버그 수정 내용]

항상 더 나은 앱을 만들기 위해 노력하고 있습니다.
```

> ❌ "버그 수정 및 성능 개선" 절대 쓰지 말 것
> ✅ 구체적으로 뭐가 바뀌었는지 사람한테 말하듯 써라

---

## Step 4. 버전 업 및 릴리즈 노트 파일 수정

**pubspec.yaml**

```yaml
version: 1.0.1+2 # 앞: 버전명, 뒤: 빌드번호
```

**릴리즈 노트 파일 경로**

```
# iOS (⚠️ ko-KR 아님! App Store Connect는 ko 폴더 사용)
ios/fastlane/metadata/ko/release_notes.txt
ios/fastlane/metadata/en-US/release_notes.txt

# Android (⚠️ default.txt 아님! 빌드번호.txt 형식 사용)
android/fastlane/metadata/android/ko-KR/changelogs/{빌드번호}.txt
android/fastlane/metadata/android/en-US/changelogs/{빌드번호}.txt
```

예) 빌드번호가 37이면: `changelogs/37.txt`

> ❌ `changelogs/default.txt` 쓰면 "Cannot find changelog, no version code given" 에러
> ✅ 항상 `changelogs/{빌드번호}.txt` 형식으로 생성

---

## Step 5. git 커밋 & 태그

```bash
git add pubspec.yaml
git add ios/fastlane/metadata
git add android/fastlane/metadata
git commit -m "chore: release v[버전]"
git tag v[버전]
git push && git push --tags
```

---

## Step 6. Fastlane 업로드 (빌드 포함)

**fastlane이 내부에서 빌드까지 자동 처리. 별도 `flutter build` 명령 불필요.**

**Android 먼저, iOS 나중에. 절대 동시 실행 금지.** (Flutter startup lock 충돌)

```bash
# 1. Android - AAB 빌드 + Google Play 내부트랙 업로드
cd android && fastlane beta

# 2. Android - 내부트랙 → 프로덕션 프로모트
cd android && fastlane release

# 3. iOS - App Store 업로드 + 심사 자동 제출
cd ios && fastlane submit

# (TestFlight만 올릴 때)
cd ios && fastlane beta

# (심사 미제출, 업로드만)
cd ios && fastlane release
```

---

## Step 7. 심사 제출

### iOS

`fastlane submit`이 빌드 + 업로드 + 심사 제출까지 자동으로 처리. 완료 후 [App Store Connect](https://appstoreconnect.apple.com)에서 상태 확인.

### Android ⚠️ 수동 필수

`fastlane release`는 프로덕션 트랙 프로모트까지만. 심사 제출은 직접 해야 함.

[play.google.com/console](https://play.google.com/console) → 내 앱 → **프로덕션** → **"검토를 위해 출시 전송"** 버튼 클릭

> `fastlane release` 실행 후 Play Console에 "검토를 위해 전송되지 않음" 상태로 표시됨. 반드시 버튼 눌러야 심사 진행.

---

## 패치 배포 체크리스트

```
✅ brew upgrade fastlane + git status 확인
✅ 빌드 대상 플랫폼 결정
✅ 버전 전략 대표님 승인
✅ git log로 변경사항 확인
✅ 릴리즈 노트 한/영 작성
✅ pubspec.yaml 버전 + 빌드번호 업
✅ ios/fastlane/metadata/ko/release_notes.txt 업데이트
✅ ios/fastlane/metadata/en-US/release_notes.txt 업데이트
✅ android/.../ko-KR/changelogs/{빌드번호}.txt 생성
✅ android/.../en-US/changelogs/{빌드번호}.txt 생성
✅ git commit & tag & push
✅ cd android && fastlane beta (내부트랙 업로드)
✅ cd android && fastlane release (프로덕션 프로모트)
✅ Google Play Console → "검토를 위해 출시 전송" 클릭
✅ cd ios && fastlane submit (빌드 + 업로드 + 심사 제출 자동)
```

---

## 트러블슈팅

| 오류                                              | 원인                              | 해결                                                                                        |
| ------------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------- |
| `Build number already exists`                     | 빌드번호 안 올림                  | pubspec.yaml `+` 뒤 숫자 +1                                                                 |
| `No profiles for bundle ID`                       | 프로비저닝 만료                   | Xcode → 자동 서명 재설정                                                                    |
| `Version code already used`                       | Android 버전코드 중복             | pubspec.yaml 빌드번호 확인                                                                  |
| `Authentication failed`                           | 앱 전용 비밀번호 만료             | appleid.apple.com에서 재발급                                                                |
| `Java heap space` (Gradle OOM)                    | `org.gradle.jvmargs` 너무 낮음    | `android/gradle.properties`에서 `-Xmx4096M`으로 수정 후 재실행                              |
| `No signing certificate "iOS Distribution" found` | Keychain에 배포용 인증서 없음     | Fastfile에 `cert` + `sigh` 추가 (flutter-fastlane-install 스킬 Fastfile 템플릿 참고)        |
| `Keychain password prompt`                        | KEYCHAIN_PASSWORD 미설정          | `ios/fastlane/.env`에 `KEYCHAIN_PASSWORD=맥로그인비밀번호` 추가                              |
| `Unsupported directory name: ko-KR` (iOS)         | iOS 메타데이터 폴더명 오류        | `ios/fastlane/metadata/ko/` 폴더 사용. ko-KR 폴더 삭제                                      |
| `Can't Reorder Assets after Submission`           | 이미 심사 제출된 버전 스크린샷 충돌 | `upload_to_app_store`에 `skip_screenshots: true` 추가                                      |
| `Precheck cannot check In-app purchases`          | API Key로 인앱구매 조회 불가      | `upload_to_app_store`에 `precheck_include_in_app_purchases: false` 추가                    |
| `Cannot find changelog, no version code given`    | Android changelog 파일명 오류     | `changelogs/default.txt` 대신 `changelogs/{빌드번호}.txt` 생성 (예: `37.txt`)               |
| `PERMISSION_DENIED` (Google Play)                 | Android Publisher API 미활성화    | Google Cloud Console → APIs & Services → `androidpublisher` API 활성화                     |

---

## 핫픽스 플로우 (긴급 배포 전용)

> 크래시, 결제 오류, 로그인 불가 등 즉시 대응이 필요한 경우에만 사용.

일반 패치와 다른 점: **릴리즈 노트 간소화 + 버전 유지 + 빌드번호만 올림**

```
안전 체크 → 버전 유지/빌드번호+1 → 릴리즈 노트 한 줄 → git 커밋/태그 → 빌드 → 업로드 → 심사 제출
```

릴리즈 노트 예시:

```
긴급 업데이트: [증상] 문제를 즉시 수정했습니다. 불편을 드려 죄송합니다.
```

> ⚠️ 핫픽스는 심사 가속(Expedite Review) 신청 가능 — App Store Connect 심사 제출 시 "심사 가속 요청" 체크

---

## 배포 후 모니터링

업로드 완료 후 **24시간 이내** 아래 항목 확인:

```
[ ] Firebase Crashlytics — 새 버전에서 크래시율 이상 없는지
[ ] App Store Connect — 심사 상태 (보통 24~48시간)
[ ] Google Play Console — 출시 검토 상태
[ ] 앱 리뷰 — 새 버전 관련 부정 리뷰 모니터링
```

> 크래시율이 이전 버전 대비 급등하면 → 즉시 핫픽스 플로우 진행
