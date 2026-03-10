---
name: flutter-init
description: "Flutter 신규 프로젝트 초기 세팅을 처음부터 끝까지 실행한다. 패키지 설치, 클린 아키텍처 구조 생성, Firebase/Supabase 연결, Android/iOS 플랫폼 설정까지 포함한다. 새 Flutter 프로젝트 시작, 초기 세팅, 프로젝트 셋업 요청 시 반드시 이 스킬을 사용한다."
---

# Flutter Init

신규 Flutter 프로젝트를 처음부터 끝까지 세팅한다.
순서대로 빠짐없이 실행한다. 절대 건너뛰지 않는다.

---

## 참조 문서 — 시작 전 전부 읽는다

flutter-init은 조건부 로딩 없이 전부 읽는다. 세팅 전체가 연결되어 있기 때문이다.

| 파일 | 내용 |
|------|------|
| `./packages.md` | 패키지 설치 전체 목록 + assets + pubspec 설정 |
| `./boilerplate.md` | main.dart · app.dart · router · providers · theme · 공통 파일 전체 |
| `./backend.md` | Firebase 초기화 + Supabase MCP + dart-define 주입 |
| `./platform.md` | Android + iOS 네이티브 설정 + .gitignore |

---

## 세팅 순서 (11단계)

```
STEP 1  주석 제거
STEP 2  analysis_options.yaml 설정
STEP 3  패키지 전체 설치            → packages.md
STEP 4  assets/ 폴더 + pubspec 등록 → packages.md
STEP 5  Firebase 초기화             → backend.md
STEP 6  Supabase MCP 설정           → backend.md
STEP 7  클린 아키텍처 폴더 구조 생성 → boilerplate.md
STEP 8  보일러플레이트 파일 작성     → boilerplate.md
STEP 9  Android 네이티브 설정       → platform.md
STEP 10 iOS 네이티브 설정           → platform.md
STEP 11 .gitignore 추가             → platform.md
```

---

## STEP 1 — 주석 제거

Flutter 생성 기본 주석 전부 제거.

```bash
find . -name "*.dart" \
  -not -path "*/.*" \
  -not -path "*/build/*" \
  -not -path "*/.dart_tool/*" | xargs sed -i 's|//.*$||g; /^[[:space:]]*$/d'
```

---

## STEP 2 — analysis_options.yaml

`formatter:` 섹션이 없으면 파일 하단에 추가한다.

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore  # json_serializable 경고 무시

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
    prefer_single_quotes: true

formatter:
  trailing_commas: preserve
```

---

## 최종 체크리스트

세팅 완료 후 하나씩 확인한다.

```
[ ] STEP 1  주석 제거
[ ] STEP 2  analysis_options.yaml formatter 설정
[ ] STEP 3  패키지 전체 설치 (pub get 성공 확인)
[ ] STEP 4  assets/ 폴더 생성 + pubspec.yaml 등록
[ ] STEP 5  flutterfire configure 실행 + firebase_options.dart 생성 확인
[ ] STEP 6  .mcp.json Supabase MCP 등록
[ ] STEP 7  클린 아키텍처 폴더 구조 생성 확인
[ ] STEP 8  main.dart / app.dart / app_router.dart / app_providers.dart 작성
[ ] STEP 8  core/constants/ 토큰 파일 3개 작성
[ ] STEP 8  core/errors/failure.dart 작성
[ ] STEP 8  core/extensions/context_extension.dart 작성
[ ] STEP 9  Android multiDexEnabled = true
[ ] STEP 9  Android AndroidManifest AdMob 테스트 ID 추가
[ ] STEP 9  Android minSdk 21 이상 확인
[ ] STEP 10 iOS Info.plist 항목 추가
[ ] STEP 10 iOS Podfile platform 13.0 이상 확인
[ ] STEP 11 .gitignore 추가
[ ] fvm flutter analyze 에러 없음 확인
[ ] fvm flutter run 정상 실행 확인
```

---

## 완료 후 사용자 안내 (배포 전 필수)

| 항목 | 할 일 |
|------|-------|
| AdMob App ID | AndroidManifest.xml, Info.plist 테스트 키 → 실제 ID 교체 |
| Supabase 키 | `SUPABASE_URL`, `SUPABASE_ANON_KEY` dart-define 또는 CI/CD 환경변수 등록 |
| 런처 아이콘 | `pubspec.yaml`에 아이콘 이미지 등록 후 `fvm dart run flutter_launcher_icons` |
| 스플래시 | `pubspec.yaml`에 스플래시 설정 후 `fvm dart run flutter_native_splash:create` |
| iOS Podfile | `platform :ios, '13.0'` 이상 확인 |
| Android minSdk | `minSdk = 21` 이상 확인 |
| ATT 권한 | 앱 시작 시 `AppTrackingTransparency.requestTrackingAuthorization()` 호출 |
| firebase_options.dart | `.gitignore`에 추가 여부 재확인 |
