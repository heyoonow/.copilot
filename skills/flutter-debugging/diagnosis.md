# Diagnosis Reference

## 현황 파악 명령어

```bash
# 1. 버전 전체 확인
fvm flutter --version
cat pubspec.yaml | grep -A 100 "dependencies:"

# 2. 의존성 트리 전체 출력
fvm flutter pub deps --style=tree

# 3. 충돌 원인 확인
fvm flutter pub outdated

# 4. 특정 패키지 버전 확인
fvm flutter pub deps | grep [패키지명]

# 5. 전체 분석
fvm flutter analyze

# 6. pub get 에러 수집
fvm flutter pub get 2>&1
```

---

## 레이어별 에러 분류

에러 메시지를 보고 어느 레이어인지 파악한 뒤 해당 영역을 집중 확인한다.

| 레이어 | 파일 위치 | 주요 에러 유형 |
|--------|-----------|----------------|
| UI | `presentation/screens/`, `presentation/widgets/` | RenderFlex overflow, BuildContext 오용, setState after dispose |
| 상태 | `presentation/providers/` | ProviderException, 순환 의존성, ref 오용 |
| 도메인 | `domain/` | 인터페이스 불일치, Usecase 로직 에러 |
| 데이터 | `data/` | 타입 불일치, json 파싱 에러, Supabase 응답 처리 |
| 플랫폼 | `android/`, `ios/` | Gradle 실패, Pod 충돌, 아키텍처 문제 |
| 의존성 | `pubspec.yaml` | 버전 충돌, MissingPluginException |

---

## 증상별 원인 표

| 증상 | 의심 원인 | 참조 |
|------|-----------|------|
| `ProviderException` / `ProviderScope` 에러 | Provider 계층 구조 잘못됨, ProviderScope 바깥에서 ref 사용 | `fixes.md` |
| `setState() called after dispose()` | 비동기 작업 후 Widget이 이미 사라짐 | `fixes.md` |
| `Null check operator used on a null value` | 초기화 순서 문제, `late` 변수 미초기화, 비동기 타이밍 | `fixes.md` |
| `MissingPluginException` | 네이티브 플러그인 미등록 or 재빌드 필요 | `platform.md` |
| `Duplicate GlobalKey` | 위젯 트리에서 같은 키 중복 사용 | `fixes.md` |
| `RenderFlex overflowed` | Column/Row에서 레이아웃 제약 조건 누락 | `fixes.md` |
| `type mismatch` in Supabase | 모델 필드 타입과 DB 컬럼 타입 불일치 | `fixes.md` |
| build_runner 충돌 | generated 파일과 소스 불일치 → 재생성 필요 | 아래 참조 |
| `pub get` 실패 / 버전 충돌 | 패키지 간 호환 버전 불일치 | `versions.md` |
| Gradle 빌드 실패 | SDK 버전 문제, minSdk 부족, multiDex 필요 | `platform.md` |
| iOS Pod 에러 | Pod 캐시 충돌, Xcode 버전 불일치 | `platform.md` |
| `Bad state: Future already completed` | Future 중복 완료, Stream 잘못된 구독 | `fixes.md` |
| `LateInitializationError` | late 변수 초기화 전 접근 | `fixes.md` |
| Firebase 초기화 에러 | `Firebase.initializeApp()` 누락 또는 순서 문제 | `versions.md` |
| `NoSuchMethodError` | null 객체 메서드 호출, 타입 불일치 캐스팅 | `fixes.md` |

---

## build_runner 에러 진단

```bash
# 생성 파일 전체 삭제 후 재생성
fvm flutter pub run build_runner clean
fvm flutter pub run build_runner build --delete-conflicting-outputs

# 충돌이 계속되면 수동 삭제
find lib -name "*.g.dart" -delete
find lib -name "*.freezed.dart" -delete
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

**build_runner 관련 주요 에러:**

| 에러 | 원인 | 해결 |
|------|------|------|
| `Conflicting outputs` | 이전 생성 파일과 충돌 | `--delete-conflicting-outputs` 플래그 |
| `Could not resolve` | 소스 파일 경로 잘못됨 | `part of` 선언 경로 확인 |
| `Missing output` | `part` 선언했는데 생성 안 됨 | `@JsonSerializable()` 어노테이션 확인 |
| `Invalid annotation` | 어노테이션 사용법 잘못됨 | pub.dev changelog에서 API 변경 확인 |

---

## Riverpod 에러 진단

```dart
// 에러: ProviderScope를 찾을 수 없음
// 원인: runApp()에서 ProviderScope 누락
// 확인:
void main() {
  runApp(
    ProviderScope(  // ← 반드시 최상위에
      child: const App(),
    ),
  );
}

// 에러: ref.read/watch를 build() 밖에서 사용
// 원인: initState, dispose 등에서 직접 ref 사용
// → fixes.md 참조

// 에러: Provider가 disposed 상태에서 접근
// 원인: autoDispose Provider를 화면 닫힌 후 접근
// 확인: keepAlive 설정 또는 Provider 스코프 검토
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  // keepAlive가 필요하면:
  AsyncValue<List<FeatureEntity>> build() {
    ref.keepAlive();
    // ...
  }
}
```

---

## Supabase 에러 진단

```dart
// 에러: type 'Null' is not a subtype of type 'String'
// 원인: Supabase 컬럼이 nullable인데 모델에서 non-null로 선언

// 확인 방법:
// 1. Supabase 대시보드에서 실제 컬럼 스키마 확인
// 2. nullable 여부 확인 후 모델 수정

// ❌ 위험한 패턴
final name = json['name'] as String;   // nullable이면 런타임 에러

// ✅ 안전한 패턴
final name = json['name'] as String?;  // nullable 허용
final name = (json['name'] as String?) ?? '';  // 기본값 제공

// 에러: PostgrestException
// 원인 확인:
try {
  final response = await Supabase.instance.client
      .from('table')
      .select()
      .single();
} on PostgrestException catch (e) {
  print('code: ${e.code}');     // 에러 코드
  print('message: ${e.message}'); // 에러 메시지
  print('details: ${e.details}'); // 상세 정보
  print('hint: ${e.hint}');     // 힌트
}
```

---

## 성능 이슈 진단

```bash
# Flutter DevTools로 성능 분석
fvm flutter run --profile
# 실행 후 Chrome DevTools 또는 VS Code DevTools에서 확인

# 불필요한 리빌드 감지
# DevTools > Widget Rebuild Count 확인
# 빨간 숫자가 많으면 과도한 리빌드
```

**리빌드 과다 원인 패턴:**

```dart
// 문제 1: build()에서 매번 새 객체 생성
Widget build(BuildContext context) {
  return SomeWidget(
    style: TextStyle(fontSize: 16),  // 매번 새 인스턴스
    onTap: () => doSomething(),      // 매번 새 함수 객체
  );
}
// → fixes.md에서 해결 패턴 확인

// 문제 2: Provider 전체를 watch할 때 불필요한 리빌드
final list = ref.watch(listProvider);   // 리스트 전체 변경 시 리빌드
// → .select()로 필요한 부분만 watch
// → fixes.md에서 해결 패턴 확인

// 문제 3: ListView에서 각 아이템이 전체 상태를 watch
ref.watch(fullStateProvider)  // 아이템 하나 바뀌어도 전체 리빌드
// → 아이템별 개별 Provider 또는 .select() 사용
```
