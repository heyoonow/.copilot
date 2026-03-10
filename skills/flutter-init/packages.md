# Packages Reference

## STEP 3 — 패키지 전체 설치

순서대로 실행한다. 에러 발생 시 해당 패키지 pub.dev에서 최신 버전 확인 후 재시도.

```bash
# ── 상태관리 ──────────────────────────────────────────────────────────────────
fvm flutter pub add hooks_riverpod
fvm flutter pub add flutter_hooks
fvm flutter pub add riverpod_annotation

# ── 라우팅 ────────────────────────────────────────────────────────────────────
fvm flutter pub add go_router

# ── 백엔드 ────────────────────────────────────────────────────────────────────
fvm flutter pub add supabase_flutter
fvm flutter pub add firebase_core
fvm flutter pub add firebase_analytics

# ── 다국어 ────────────────────────────────────────────────────────────────────
fvm flutter pub add easy_localization

# ── 직렬화 ────────────────────────────────────────────────────────────────────
fvm flutter pub add json_annotation

# ── 로컬 저장소 ───────────────────────────────────────────────────────────────
fvm flutter pub add shared_preferences

# ── UI / 아이콘 ───────────────────────────────────────────────────────────────
fvm flutter pub add font_awesome_flutter
fvm flutter pub add velocity_x
fvm flutter pub add shimmer                       # 스켈레톤 로딩
fvm flutter pub add flutter_staggered_animations  # 리스트 등장 애니메이션
fvm flutter pub add cached_network_image          # 네트워크 이미지 캐시

# ── 광고 / 트래킹 ─────────────────────────────────────────────────────────────
fvm flutter pub add google_mobile_ads
fvm flutter pub add app_tracking_transparency

# ── 네이티브 ──────────────────────────────────────────────────────────────────
fvm flutter pub add flutter_native_splash

# ── 개발 의존성 ───────────────────────────────────────────────────────────────
fvm flutter pub add -d build_runner
fvm flutter pub add -d json_serializable
fvm flutter pub add -d riverpod_generator
fvm flutter pub add -d flutter_launcher_icons
```

설치 완료 후 확인:

```bash
fvm flutter pub get
fvm flutter pub deps | head -30  # 의존성 트리 간단 확인
```

---

## 전체 패키지 역할 정리

| 패키지 | 역할 | 비고 |
|--------|------|------|
| `hooks_riverpod` | 상태관리 | `flutter_hooks`와 반드시 같이 |
| `flutter_hooks` | React hooks 스타일 | useState, useEffect 등 |
| `riverpod_annotation` | @riverpod 코드 생성 | `riverpod_generator`와 세트 |
| `go_router` | 선언형 라우팅 | deep link 자동 지원 |
| `supabase_flutter` | Supabase SDK | Auth, DB, Storage, Realtime |
| `firebase_core` | Firebase 초기화 | 모든 Firebase 패키지의 기반 |
| `firebase_analytics` | 이벤트 트래킹 | GA4 연동 |
| `easy_localization` | 다국어 (i18n) | JSON 파일 기반 |
| `json_annotation` | JSON 직렬화 어노테이션 | `json_serializable`과 세트 |
| `shared_preferences` | 로컬 키-값 저장소 | 설정, 토큰 등 |
| `font_awesome_flutter` | FontAwesome 아이콘 | 풍부한 아이콘 세트 |
| `velocity_x` | UI 유틸 확장 | Flutter UI 작성 편의 |
| `shimmer` | 스켈레톤 로딩 효과 | 스피너 대체 |
| `flutter_staggered_animations` | 리스트 순차 등장 | 자연스러운 UX |
| `cached_network_image` | 네트워크 이미지 캐시 | Image.network 대체 |
| `google_mobile_ads` | AdMob 광고 | 수익화 |
| `app_tracking_transparency` | iOS ATT 권한 요청 | iOS 14.5+ 필수 |
| `flutter_native_splash` | 네이티브 스플래시 | 앱 로딩 시 표시 |
| `build_runner` (dev) | 코드 생성 실행기 | |
| `json_serializable` (dev) | Model .g.dart 생성 | |
| `riverpod_generator` (dev) | Notifier .g.dart 생성 | |
| `flutter_launcher_icons` (dev) | 런처 아이콘 생성 | |

---

## STEP 4 — assets 폴더 구조 생성

```bash
# 폴더 생성
mkdir -p assets/translations
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts

# 번역 파일 초기화
echo '{
  "app": {
    "name": "App Name"
  },
  "common": {
    "loading": "Loading...",
    "error": "An error occurred",
    "retry": "Retry",
    "empty": "No items yet",
    "cancel": "Cancel",
    "confirm": "Confirm",
    "save": "Save",
    "delete": "Delete"
  }
}' > assets/translations/en.json

echo '{
  "app": {
    "name": "앱 이름"
  },
  "common": {
    "loading": "로딩 중...",
    "error": "오류가 발생했어요",
    "retry": "다시 시도",
    "empty": "아직 항목이 없어요",
    "cancel": "취소",
    "confirm": "확인",
    "save": "저장",
    "delete": "삭제"
  }
}' > assets/translations/ko.json
```

---

## pubspec.yaml — flutter 섹션 전체 설정

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/translations/
    - assets/images/
    - assets/icons/

  # 폰트 등록 예시 (Pretendard 사용 시)
  # fonts:
  #   - family: Pretendard
  #     fonts:
  #       - asset: assets/fonts/Pretendard-Regular.otf
  #         weight: 400
  #       - asset: assets/fonts/Pretendard-Medium.otf
  #         weight: 500
  #       - asset: assets/fonts/Pretendard-SemiBold.otf
  #         weight: 600
  #       - asset: assets/fonts/Pretendard-Bold.otf
  #         weight: 700
```

---

## flutter_launcher_icons 설정 (배포 전)

```yaml
# pubspec.yaml에 추가
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"  # 1024x1024 PNG
  adaptive_icon_background: "#FFFFFF"       # Android adaptive icon 배경색
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  web:
    generate: false
  windows:
    generate: false
  macos:
    generate: false
```

```bash
# 아이콘 생성
fvm dart run flutter_launcher_icons
```

---

## flutter_native_splash 설정 (배포 전)

```yaml
# pubspec.yaml에 추가
flutter_native_splash:
  color: "#FFFFFF"                           # 스플래시 배경색
  image: assets/images/splash_logo.png      # 중앙 로고 이미지
  color_dark: "#0F0F0F"                      # 다크모드 배경
  image_dark: assets/images/splash_logo_dark.png
  android_12:
    image: assets/images/splash_logo.png
    color: "#FFFFFF"
  fullscreen: true
```

```bash
# 스플래시 생성
fvm dart run flutter_native_splash:create
```
