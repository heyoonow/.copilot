---
description: FVM으로 프로젝트에 최적화된 Flutter/Dart 버전을 분석·결정하고 적용합니다. pubspec.yaml의 의존 패키지(특히 Firebase), Android Gradle, iOS 배포 대상을 종합 분석하여 가장 적합한 최신 버전을 선택하고 그 이유를 설명합니다.
---

# FVM 버전 결정 스킬

사용자가 "fvm 설정해줘", "flutter 버전 맞춰줘", "fvm으로 버전 잡아줘" 등을 요청하면 아래 절차를 순서대로 수행한다.

---

## STEP 1. 프로젝트 의존성 수집

아래 파일들을 읽어 제약 조건을 수집한다.

```bash
# pubspec.yaml 전체 확인
cat pubspec.yaml

# Android 그레이들 설정 확인
cat android/app/build.gradle
cat android/build.gradle
cat android/gradle/wrapper/gradle-wrapper.properties

# iOS 배포 대상 확인
grep -E "IPHONEOS_DEPLOYMENT_TARGET|platform :ios" ios/Podfile ios/Runner.xcodeproj/project.pbxproj 2>/dev/null | head -20

# 현재 .fvmrc 또는 .flutter-version 확인 (이미 지정된 버전이 있는지)
cat .fvmrc 2>/dev/null || cat .flutter-version 2>/dev/null || echo "FVM 버전 미지정"

# 현재 설치된 fvm 버전 목록 확인
fvm list
```

---

## STEP 2. 제약 조건 분석

수집한 정보를 기반으로 아래 항목별 제약을 분석한다.

### 2-1. Firebase 버전 분석 (최우선 제약)

`pubspec.yaml`에서 아래 패키지들의 버전을 확인한다.

| 패키지                 | 확인 이유                                                     |
| ---------------------- | ------------------------------------------------------------- |
| `firebase_core`        | 모든 Firebase 패키지의 베이스. Flutter SDK 최소 요구사항 결정 |
| `firebase_auth`        | Flutter 및 Dart SDK 하한선 제약                               |
| `cloud_firestore`      | gRPC 네이티브 의존성으로 Dart 버전에 민감                     |
| `firebase_messaging`   | iOS APNs 연동, Flutter 최소 버전 제약                         |
| `firebase_analytics`   | 주요 버전 변경마다 Flutter 최소 버전 상향                     |
| `firebase_crashlytics` | 네이티브 플러그인, Gradle 버전과 연동                         |
| `google_mobile_ads`    | Firebase 의존, iOS SDK 제약                                   |

각 패키지의 버전을 확인한 뒤 [pub.dev](https://pub.dev) 기준으로 해당 버전이 요구하는 **최소 Flutter SDK / Dart SDK** 를 파악한다.

> (중요) Firebase FlutterFire 패키지는 버전대별로 요구 Flutter 버전이 크게 다르다.  
> 예: `firebase_core: ^3.x` → Flutter 3.19+ 필요, `firebase_core: ^2.x` → Flutter 3.3+ 필요

### 2-2. 기타 주요 패키지 분석

아래 패키지들도 Flutter/Dart 버전 제약이 강하므로 확인한다.

- `supabase_flutter` — Dart 3.x 이상 요구 여부
- `riverpod` / `hooks_riverpod` — 최신 버전의 Dart 요구사항
- `go_router` — Flutter 안정 채널 최소 버전
- `flutter_local_notifications` — iOS/Android 네이티브 API 제약
- `in_app_purchase` / `purchases_flutter` (RevenueCat) — 스토어 SDK 버전 연동

### 2-3. Android 제약 분석

```
compileSdkVersion / targetSdkVersion → 요구 AGP(Android Gradle Plugin) 버전 결정
AGP 버전 → 요구 Gradle 버전 결정
Gradle 버전 → Flutter가 지원하는 최소 버전 결정
```

| AGP 버전 | 최소 Flutter 버전 |
| -------- | ----------------- |
| 8.x      | Flutter 3.16+     |
| 7.x      | Flutter 3.0+      |
| 6.x      | Flutter 2.x       |

### 2-4. iOS 제약 분석

- `IPHONEOS_DEPLOYMENT_TARGET` 이 12 미만이면 최신 Flutter 불가
- iOS 13+ 이상이면 최신 Flutter 모두 지원
- CocoaPods 버전에 따라 Flutter 버전 제약 가능

---

## STEP 3. 최적 Flutter 버전 결정

> (중요) **기본 원칙: 항상 stable 최신 버전을 목표로 한다.**  
> 제약 조건이 없는 한 최신 버전을 적용하고, 현재 프로젝트 버전보다 신규 버전이 있으면 반드시 업그레이드한다.

```bash
# stable 최신 버전 확인
fvm releases | grep stable | tail -10
```

분석된 모든 제약 조건을 종합하여 다음 우선순위로 버전을 결정한다.

```
1. stable 채널 최신 버전 → 1차 목표 (기본값)
2. 모든 패키지의 최소 Flutter 버전 중 가장 높은 값 → 하한선 확인
3. 최신 버전이 하한선을 만족하면 → 최신 버전 채택
4. 최신 버전이 특정 패키지와 충돌하면 → 충돌 해소 가능한 가장 높은 버전 채택
5. 메이저 버전이 올라가는 경우(예: 3.x → 4.x)는 패키지 호환성 재검토 후 결정
```

**현재 프로젝트 버전 vs 최신 버전 비교:**

- `.fvmrc`에 기재된 현재 버전을 확인한다.
- 최신 stable 버전과 다르면 → **업그레이드 대상으로 분류**한다.
- 업그레이드 시 제약 조건 재분석 후 적용 가능 여부를 검토한다.

---

## STEP 4. 결정 이유 보고 (대표님께 설명)

버전을 적용하기 **전에** 반드시 아래 형식으로 보고한다.

아래 두 가지 케이스 중 해당하는 형식으로 작성한다.

**[케이스 A] 최신 버전으로 업그레이드 가능한 경우**

```
📋 FVM 버전 분석 결과

📌 현재 버전: Flutter X.XX.X → 🆕 최신 stable: Flutter Y.YY.Y

✅ 업그레이드 가능 판정:
- firebase_core: ^3.6.0 → Flutter 3.16+ 필요 → 최신 버전(Y.YY.Y) 충족
- compileSdkVersion 34 → AGP 8.x → Flutter 3.16+ 필요 → 충족
- IPHONEOS_DEPLOYMENT_TARGET 13.0 → 제약 없음
- 모든 제약 조건 통과 → 최신 버전 적용 가능

🎯 적용할 버전: Flutter Y.YY.Y (Dart Z.Z.Z)

지금 설치하고 버전 올릴게요!
```

**[케이스 B] 특정 버전으로 고정해야 하는 경우**

```
📋 FVM 버전 분석 결과

📌 현재 버전: Flutter X.XX.X → 🆕 최신 stable: Flutter Y.YY.Y

⚠️ 최신 버전 적용 불가 이유:
- [제약 패키지]: (예) cloud_firestore: ^4.17.5 → Dart 3.3 미만 필요
  → 최신 Flutter Y.YY.Y (Dart Z.Z.Z) 와 충돌
- 충돌 없이 올릴 수 있는 최고 버전: Flutter X.XX.X

🎯 적용할 버전: Flutter X.XX.X (Dart A.A.A)

💡 참고: [제약 패키지]를 업데이트하면 더 높은 Flutter 버전 사용 가능.
   패키지도 같이 올릴까요?
```

보고 후 대표님의 확인 없이 **즉시 STEP 5로 진행한다.**  
단, 케이스 B에서 패키지 동반 업그레이드 제안 시에는 대표님 응답을 기다린다.

---

## STEP 5. FVM 버전 설치 및 적용

```bash
# 해당 버전 설치 (미설치 시)
fvm install X.XX.X

# 프로젝트에 버전 지정
fvm use X.XX.X

# .fvmrc가 생성되었는지 확인
cat .fvmrc
```

---

## STEP 6. .gitignore에 FVM 심볼릭 링크 등록

`.gitignore`에 아래 항목이 없으면 추가한다.

```bash
# .gitignore에 fvm 관련 항목 추가 여부 확인
grep -q ".fvm/flutter_sdk" .gitignore || echo ".fvm/flutter_sdk" >> .gitignore
grep -q ".fvm/versions" .gitignore || echo ".fvm/versions" >> .gitignore
```

---

## STEP 7. 버전 적용 검증

```bash
# fvm으로 flutter 버전 확인
fvm flutter --version

# pub 의존성 재설치
fvm flutter pub get

# 분석 (에러 없는지 확인)
fvm flutter analyze --no-fatal-infos
```

에러 발생 시 원인을 분석하고 대표님께 보고한 뒤 해결 방안을 제시한다.

---

## STEP 8. 최종 결과 보고

```
✅ FVM 설정 완료

- 적용 버전: Flutter X.XX.X / Dart X.X.X
- .fvmrc 생성됨
- .gitignore 업데이트됨
- flutter pub get 완료
- flutter analyze: 이상 없음 (또는 발견된 경고 요약)

앞으로 이 프로젝트에서는 `fvm flutter` 명령어를 사용하세요.
예: fvm flutter run / fvm flutter build appbundle
```
