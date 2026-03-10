# Versions Reference

## 버전 확인 명령어

```bash
# 현재 버전 현황
fvm flutter --version
cat pubspec.yaml

# 의존성 트리 + 충돌 확인
fvm flutter pub deps --style=tree
fvm flutter pub outdated

# 특정 패키지 버전 확인
fvm flutter pub deps | grep [패키지명]
```

---

## 버전 충돌 해결 순서

1. `fvm flutter pub outdated` 로 현황 파악
2. 충돌 패키지를 **pub.dev에서 웹 검색**으로 최신 버전 + changelog 확인
3. breaking change 없으면 버전 업
4. breaking change 있으면 마이그레이션 가이드 찾아서 코드 수정 후 업
5. 버전 고정이 불가피하면 `dependency_overrides` 사용 + 주석으로 이유 명시

```bash
# pub.dev 검색 키워드
[패키지명] latest version pub.dev
[패키지명] changelog breaking changes
[패키지명] flutter [현재버전] compatibility issue
[패키지명] migration guide [이전버전] to [새버전]
```

---

## dependency_overrides 패턴 (최후 수단)

```yaml
# pubspec.yaml — 불가피한 경우에만, 반드시 이유 주석
dependency_overrides:
  some_package: ^2.1.0  # flutter_hooks와 버전 충돌 → 임시 고정 (2024-01)
  another_package: 1.5.3  # firebase_core 3.x 호환 문제 → 추후 업그레이드 필요
```

> `dependency_overrides` 는 근본 해결이 아님. 반드시 추후 제거 목표로.

---

## 자주 충돌하는 패키지 조합

| 패키지 조합 | 주의사항 | 확인 방법 |
|-------------|----------|-----------|
| `hooks_riverpod` + `flutter_hooks` | 반드시 같은 메이저 버전 | 두 패키지 동시 업그레이드 |
| `firebase_core` + 다른 `firebase_*` | 모두 같은 BOM 버전 | 공식 호환 버전표 확인 |
| `google_mobile_ads` | Google Play Services 버전 영향 | Android Gradle 버전도 확인 |
| `json_annotation` + `json_serializable` | 항상 같이 업데이트 | 둘 다 동시에 올리기 |
| `build_runner` | 다른 `_builder` 패키지들과 충돌 잦음 | 모두 최신으로 맞추기 |
| `freezed` + `freezed_annotation` | 같은 버전 그룹 유지 | 둘 다 동시 업그레이드 |
| `riverpod_generator` + `riverpod` | 같은 메이저 버전 | @riverpod 사용 시 필수 |

---

## Firebase 버전 통일

Firebase 패키지는 반드시 공식 호환 버전표를 확인한다.

```bash
# 웹 검색으로 최신 호환 버전 확인
firebase flutter compatibility table 2024
flutterfire versions
```

```yaml
# ✅ 올바른 패턴 — 호환되는 버전으로 통일
dependencies:
  firebase_core: ^3.x.x
  firebase_analytics: ^11.x.x    # core 버전에 맞는 버전
  firebase_messaging: ^15.x.x    # core 버전에 맞는 버전
  firebase_crashlytics: ^4.x.x   # core 버전에 맞는 버전
```

> 버전 숫자는 예시 — 항상 https://firebase.flutter.dev/docs/overview 에서 최신 확인

---

## Flutter 버전 관리 (fvm)

```bash
# fvm 설치 (없을 때)
dart pub global activate fvm

# 사용 가능한 Flutter 버전 목록
fvm releases

# 특정 버전 설치
fvm install 3.22.0

# 프로젝트에 버전 고정
fvm use 3.22.0

# 현재 사용 중인 버전 확인
fvm flutter --version

# .fvm/fvm_config.json 생성됨 — Git에 커밋 O
```

---

## 패키지 업그레이드 절차

```bash
# 1. 현황 파악
fvm flutter pub outdated

# 2. 안전한 업그레이드 (major 제외)
fvm flutter pub upgrade --minor-versions

# 3. 전체 업그레이드 (breaking change 위험)
fvm flutter pub upgrade

# 4. 특정 패키지만 업그레이드
# pubspec.yaml에서 버전 직접 수정 후:
fvm flutter pub get

# 5. build_runner 파일 재생성 (모델 관련 패키지 변경 시 필수)
fvm flutter pub run build_runner build --delete-conflicting-outputs

# 6. 전체 분석
fvm flutter analyze
```

---

## pubspec.yaml 버전 표기 규칙

```yaml
dependencies:
  # ^ : 마이너·패치 업그레이드 허용 (메이저 고정)
  some_package: ^2.1.0       # 2.1.0 이상 3.0.0 미만

  # >= <= : 범위 지정
  other_package: ">=1.0.0 <2.0.0"

  # 정확한 버전 고정 (가장 엄격)
  exact_package: 1.5.3

  # Git에서 직접 (로컬 개발 or 공식 미출시)
  dev_package:
    git:
      url: https://github.com/org/repo
      ref: main
```

---

## Riverpod 버전 마이그레이션

```bash
# Riverpod 버전 확인
fvm flutter pub deps | grep riverpod

# Riverpod 2.x → 코드 생성 방식 사용 여부 확인
# ✅ 현재 권장 방식
@riverpod
class FeatureNotifier extends _$FeatureNotifier { ... }

# ❌ 레거시 방식 (2.x 이전)
final featureProvider = StateNotifierProvider<FeatureNotifier, List<Item>>(...);
```

```yaml
# Riverpod 2.x 필수 패키지 조합
dependencies:
  hooks_riverpod: ^2.x.x
  flutter_hooks: ^0.20.x    # hooks_riverpod 버전에 맞게
  riverpod_annotation: ^2.x.x

dev_dependencies:
  riverpod_generator: ^2.x.x
  build_runner: ^2.x.x
```

---

## go_router 버전 이슈

```bash
# go_router 버전 확인
fvm flutter pub deps | grep go_router
```

```dart
// go_router 7.x → 현재 최신 마이그레이션 포인트
// 1. GoRouter.of(context) → GoRouterHelper 확장 함수
context.go('/path')      // ✅ 현재 방식
context.push('/path')    // ✅ 현재 방식
GoRouter.of(context).go  // ✅ 여전히 작동

// 2. redirect 파라미터 변경 이력 있음
// 버전 업 시 반드시 changelog 확인:
// https://pub.dev/packages/go_router/changelog
```
