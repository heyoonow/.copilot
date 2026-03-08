---
name: flutter-debugging
description: "Flutter 앱의 버그 수정, 버전 충돌 해결, 코드 구조 개선을 담당한다. 단순 에러 수정이 아니라 근본 원인 파악 후 더 나은 구조로 개선한다. 에러, 크래시, 버전 충돌, 성능 이슈, 플러그인 문제 등 Flutter 관련 문제가 발생하면 이 스킬을 사용한다."
---

# Flutter Debugging

단순히 에러를 고치지 않는다. 왜 발생했는지 파악하고, 더 나은 구조로 개선한다.
버전은 철저히 확인하고, 최신 best practice로 맞춘다.

---

## 디버깅 워크플로우

### 1단계: 현황 파악

**프로젝트 버전 전체 확인 — 가장 먼저 한다**

```bash
fvm flutter --version
cat pubspec.yaml | grep -A 100 "dependencies:"
fvm flutter pub deps
```

**에러 전체 수집**

```bash
fvm flutter analyze
fvm flutter pub get 2>&1
```

문제가 뭔지, 어느 레이어에서 발생했는지 파악한다:

- UI 레이어 (Widget, Screen)
- 상태 레이어 (Provider, Notifier)
- 도메인 레이어 (Usecase, Entity)
- 데이터 레이어 (Repository, Datasource, Model)
- 플랫폼 레이어 (Android, iOS 네이티브)
- 의존성 (패키지 버전 충돌)

---

### 2단계: 버전 호환성 검증

**반드시 웹 검색으로 확인한다** — 버전 정보는 항상 최신 공식 문서 기준

```
[패키지명] latest version pub.dev
[패키지명] changelog breaking changes
[패키지명] flutter [버전] compatibility issue
```

**충돌 패턴 확인**

```bash
# 의존성 트리 전체 출력
fvm flutter pub deps --style=tree

# 충돌 원인 확인
fvm flutter pub outdated

# 특정 패키지 버전 강제 확인
fvm flutter pub deps | grep [패키지명]
```

**버전 고정이 필요한 경우 `pubspec.yaml`에 명시:**

```yaml
dependency_overrides:
  some_package: ^2.1.0 # 충돌 해결용 — 이유 주석 필수
```

---

### 3단계: 근본 원인 분석

에러 메시지만 보고 덮어쓰지 않는다. 왜 발생했는지 파악한다.

**자주 보는 패턴별 원인:**

| 증상                                       | 의심 원인                                  |
| ------------------------------------------ | ------------------------------------------ |
| `ProviderException` / `ProviderScope` 에러 | Provider 계층 구조 잘못됨                  |
| `setState() called after dispose()`        | 비동기 작업 후 Widget 이미 사라짐          |
| `Null check operator used on a null value` | 초기화 순서 문제 또는 late 변수 미초기화   |
| `MissingPluginException`                   | 네이티브 플러그인 미등록 or 재빌드 필요    |
| `Duplicate GlobalKey`                      | 위젯 트리에서 같은 키 중복 사용            |
| `RenderFlex overflowed`                    | 레이아웃 제약 조건 누락                    |
| `type mismatch` in Supabase                | 모델 필드 타입과 DB 컬럼 타입 불일치       |
| build_runner 충돌                          | generated 파일과 소스 불일치 → 재생성 필요 |

---

### 4단계: 최신 best practice 검색

고치기 전에 현재 방식이 최선인지 확인한다.

**검색 키워드 패턴:**

```
flutter [해당기능] best practice 2024
riverpod [패턴] latest example
go_router [기능] migration guide
supabase flutter [기능] latest
```

**특히 확인할 것:**

- Riverpod 2.x `@riverpod` 코드 생성 방식 사용 중인지
- go_router 최신 `pageBuilder` 패턴 사용 중인지
- Supabase Flutter SDK breaking change 없는지
- Flutter 버전에 맞는 Material 3 위젯 사용 중인지

---

### 5단계: 수정 + 구조 개선

에러만 고치지 않는다. 해당 코드가 더 나은 구조가 될 수 있다면 함께 개선한다.

**개선 우선순위:**

1. 컴파일 에러 / 크래시 → 즉시 수정
2. 버전 충돌 → 호환되는 버전으로 정리
3. 안티패턴 발견 → 올바른 패턴으로 교체
4. 중복 코드 → 공통화
5. 성능 이슈 → 최적화

**자주 발견되는 안티패턴 → 개선:**

```dart
// ❌ BuildContext를 async 너머로 넘기기
onPressed: () async {
  await someAsyncWork();
  Navigator.of(context).pop(); // context가 이미 죽었을 수 있음
}

// ✅ mounted 확인
onPressed: () async {
  await someAsyncWork();
  if (!mounted) return;
  Navigator.of(context).pop();
}
```

```dart
// ❌ initState에서 직접 ref 접근
@override
void initState() {
  ref.read(provider).fetchData(); // 에러
}

// ✅ WidgetsBinding 사용 or useEffect
useEffect(() {
  ref.read(notifierProvider.notifier).fetchData();
  return null;
}, []);
```

```dart
// ❌ Provider 안에서 또 다른 Provider watch
final provider = Provider((ref) {
  final other = ref.watch(otherProvider); // 순환 의존성 위험
  return SomeClass(other);
});

// ✅ read or 의존성 명확히 분리
```

```dart
// ❌ Supabase 응답 타입 캐스팅
final data = response as List; // 런타임 에러 가능

// ✅ 명시적 타입 처리
final data = (response as List<dynamic>)
  .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
  .toList();
```

---

### 6단계: 검증

```bash
# 전체 분석
fvm flutter analyze

# 빌드 확인 (Android)
fvm flutter build apk --debug

# 빌드 확인 (iOS)
fvm flutter build ios --debug --no-codesign

# build_runner 재생성 (모델 변경 시)
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 버전 충돌 해결 가이드

### 충돌 발생 시 순서

1. `fvm flutter pub outdated` 로 현황 파악
2. 충돌 패키지 pub.dev에서 최신 버전 + changelog 확인 (웹 검색)
3. breaking change 없으면 버전 업
4. breaking change 있으면 마이그레이션 가이드 찾아서 코드 수정 후 업
5. 버전 고정이 불가피하면 `dependency_overrides` 사용 + 주석으로 이유 명시

### 자주 충돌하는 조합

| 패키지                                  | 주의사항                             |
| --------------------------------------- | ------------------------------------ |
| `hooks_riverpod` + `flutter_hooks`      | 반드시 같은 메이저 버전              |
| `firebase_core` + 다른 firebase\_\*     | 모두 같은 BOM 버전으로 맞춰야 함     |
| `google_mobile_ads`                     | Google Play Services 버전 영향 받음  |
| `json_annotation` + `json_serializable` | 항상 같이 업데이트                   |
| `build_runner`                          | 다른 `_builder` 패키지들과 충돌 잦음 |

### Firebase 버전 통일

```yaml
# firebase 패키지는 반드시 호환 버전표 확인
# https://firebase.flutter.dev/docs/overview 참고
dependencies:
  firebase_core: ^3.x.x
  firebase_analytics: ^11.x.x # core 버전에 맞춰야 함
```

---

## 플랫폼별 네이티브 에러

### Android

```
# Gradle 빌드 실패
fvm flutter clean && fvm flutter pub get
cd android && ./gradlew clean && cd ..

# multiDex 에러
# android/app/build.gradle
defaultConfig {
  multiDexEnabled = true
}

# minSdk 에러
# android/app/build.gradle
defaultConfig {
  minSdk = 21
}
```

### iOS

```bash
# Pod 충돌
cd ios && pod deintegrate && pod install && cd ..

# Xcode 빌드 에러
fvm flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..

# 아키텍처 문제 (M1/M2 Mac)
cd ios && arch -x86_64 pod install && cd ..
# 또는
cd ios && pod install --repo-update && cd ..
```

---

## 성능 이슈 디버깅

```dart
// 불필요한 리빌드 감지
// Flutter DevTools > Widget Rebuild Count 확인

// ❌ 매 빌드마다 새 객체 생성
Widget build(BuildContext context) {
  return SomeWidget(
    style: TextStyle(fontSize: 16), // 매번 새 객체
  );
}

// ✅ const 또는 외부로 빼기
const _style = TextStyle(fontSize: 16);

Widget build(BuildContext context) {
  return SomeWidget(style: _style);
}
```

```dart
// ❌ 리스트에서 전체 리빌드
ref.watch(listProvider) // 리스트 전체가 바뀔 때마다 리빌드

// ✅ 개별 아이템만 watch
ref.watch(listProvider.select((list) => list[index]))
```

---

## 주의사항

- 버전 정보는 항상 웹 검색으로 최신 확인 (pub.dev, 공식 docs)
- `dependency_overrides` 남발 금지 — 근본 해결이 우선
- 에러 하나 고칠 때 관련 코드 전체 맥락 파악
- `fvm flutter clean` 은 만능이 아님 — 원인 파악 후 사용
- build_runner 파일은 Git에 커밋해도 되지만 항상 재생성 가능해야 함
- 고친 후 반드시 `fvm flutter analyze` 통과 확인
