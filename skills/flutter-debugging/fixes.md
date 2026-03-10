# Fixes Reference

## Best Practice 검색 키워드

고치기 전에 현재 방식이 최선인지 항상 확인한다.

```
flutter [해당기능] best practice 2024
riverpod [패턴명] latest example
go_router [기능] migration guide
supabase flutter [기능] latest
flutter [위젯명] performance optimization
```

---

## 안티패턴 → 올바른 패턴

### BuildContext를 async 너머로 넘기기

```dart
// ❌ 위험 — async 완료 후 context가 죽었을 수 있음
onPressed: () async {
  await someAsyncWork();
  Navigator.of(context).pop(); // context가 이미 dispose됐을 수 있음
  ScaffoldMessenger.of(context).showSnackBar(...);
}

// ✅ mounted 확인 필수
onPressed: () async {
  await someAsyncWork();
  if (!mounted) return;  // Widget 살아있는지 확인 후 진행
  if (!context.mounted) return;  // Flutter 3.7+ 방식
  Navigator.of(context).pop();
}

// ✅ go_router 사용 시 (context 직접 안 씀)
onPressed: () async {
  await someAsyncWork();
  if (!mounted) return;
  context.go('/home');  // go_router는 context.mounted 확인 후
}
```

---

### initState에서 ref 직접 접근

```dart
// ❌ 에러 — initState 시점에는 ref.read 불가
@override
void initState() {
  super.initState();
  ref.read(featureNotifierProvider.notifier).fetchData(); // 에러!
}

// ✅ WidgetsBinding 사용 (StatefulWidget)
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(featureNotifierProvider.notifier).fetchData();
  });
}

// ✅ useEffect 사용 (HookConsumerWidget — 권장)
@override
Widget build(BuildContext context, WidgetRef ref) {
  useEffect(() {
    ref.read(featureNotifierProvider.notifier).fetchData();
    return null;
  }, const []);  // 빈 배열 = 마운트 시 1회 실행
  // ...
}
```

---

### Provider 안에서 순환 의존성

```dart
// ❌ 위험 — 순환 의존성 또는 불필요한 watch
final providerA = Provider((ref) {
  final b = ref.watch(providerB); // A가 B를 watch
  return ClassA(b);
});

final providerB = Provider((ref) {
  final a = ref.watch(providerA); // B가 A를 watch → 순환!
  return ClassB(a);
});

// ✅ 의존성 방향을 단방향으로 정리
final providerB = Provider((ref) => ClassB());

final providerA = Provider((ref) {
  final b = ref.read(providerB); // read로 1회 읽기 (watch 사용 최소화)
  return ClassA(b);
});

// ✅ 복잡한 경우 — Notifier로 분리
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  AsyncValue<FeatureState> build() {
    // ref.watch는 build() 안에서만
    final config = ref.watch(configProvider);
    return AsyncValue.data(FeatureState(config: config));
  }

  void doSomething() {
    // 메서드 안에서는 ref.read
    final service = ref.read(serviceProvider);
    service.execute();
  }
}
```

---

### Supabase 응답 타입 안전하지 않은 캐스팅

```dart
// ❌ 위험 — 런타임 에러 가능
final data = response as List;
final name = json['name'] as String;
final id = json['id'] as int;

// ✅ 안전한 타입 처리
final data = (response as List<dynamic>)
    .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
    .toList();

final name = (json['name'] as String?) ?? '';
final id = (json['id'] as num?)?.toInt() ?? 0;

// ✅ json_serializable 사용 시 (권장)
// fromJson이 타입 처리를 담당 → 직접 캐스팅 불필요
factory ItemModel.fromJson(Map<String, dynamic> json) =>
    _$ItemModelFromJson(json);
```

---

### LateInitializationError

```dart
// ❌ 위험 — 초기화 전 접근
late String _userId;

@override
Widget build(BuildContext context, WidgetRef ref) {
  print(_userId); // 초기화 전이면 LateInitializationError
}

// ✅ 초기화 보장
late final String _userId;  // final + late: 1회만 할당 가능

// 또는 nullable로 선언
String? _userId;

// 또는 Riverpod State로 관리 (권장)
final userId = ref.watch(authProvider.select((s) => s.userId));
```

---

### Duplicate GlobalKey

```dart
// ❌ 위험 — 리스트에서 같은 키 재사용
final _key = GlobalKey<FormState>();

ListView.builder(
  itemBuilder: (context, index) => Form(
    key: _key, // 모든 아이템이 같은 키 사용 → 에러
    child: ...,
  ),
)

// ✅ 아이템마다 고유 키
ListView.builder(
  itemBuilder: (context, index) => Form(
    key: GlobalKey<FormState>(), // 각 아이템마다 새 키
    child: ...,
  ),
)

// ✅ 키가 필요 없으면 제거
ListView.builder(
  itemBuilder: (context, index) => Form(
    // key 없음 — 대부분의 경우 불필요
    child: ...,
  ),
)
```

---

### RenderFlex overflowed

```dart
// ❌ 제약 없는 Column/Row
Column(
  children: [
    SomeWidget(),       // 높이를 알 수 없음
    Expanded(child: ...), // Expanded는 Column 안에서만
  ],
)

// ✅ 방법 1: Expanded/Flexible로 남은 공간 분배
Column(
  children: [
    SomeWidget(),
    Expanded(
      child: ScrollableWidget(), // 남은 공간 채움
    ),
  ],
)

// ✅ 방법 2: SingleChildScrollView로 스크롤 허용
SingleChildScrollView(
  child: Column(
    children: [...],
  ),
)

// ✅ 방법 3: 가로 오버플로우 — Wrap 사용
Wrap(
  spacing: AppValues.spaceS,
  runSpacing: AppValues.spaceS,
  children: items.map((item) => Chip(label: Text(item))).toList(),
)

// ✅ 방법 4: FittedBox로 텍스트 축소
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(longText),
)
```

---

### setState called after dispose

```dart
// ❌ 비동기 완료 후 setState 호출
void fetchData() async {
  final data = await api.getData();
  setState(() { _data = data; }); // Widget이 이미 없으면 에러
}

// ✅ mounted 확인
void fetchData() async {
  final data = await api.getData();
  if (!mounted) return;
  setState(() { _data = data; });
}

// ✅ HookConsumerWidget + Riverpod 사용 시 (권장)
// setState 자체를 안 씀 → 이 에러 발생 안 함
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(featureNotifierProvider);
  // state 변경 → 자동 리빌드, mounted 걱정 없음
}
```

---

## 성능 최적화 패턴

### 불필요한 리빌드 방지

```dart
// ❌ 매 빌드마다 새 객체 생성
Widget build(BuildContext context) {
  return SomeWidget(
    style: const TextStyle(fontSize: 16),   // const 붙이거나
    config: ItemConfig(color: Colors.blue), // 외부로 빼기
    onTap: () => doSomething(),             // 매번 새 함수 객체
  );
}

// ✅ const 또는 외부 상수로
const _itemStyle = TextStyle(fontSize: 16);
const _itemConfig = ItemConfig(color: Colors.blue);

Widget build(BuildContext context) {
  return SomeWidget(
    style: _itemStyle,
    config: _itemConfig,
    onTap: _handleTap,  // 클래스 메서드 참조
  );
}

void _handleTap() => doSomething();
```

### Provider .select()로 필요한 부분만 watch

```dart
// ❌ 전체 상태 watch → 어떤 값이 바뀌어도 리빌드
final state = ref.watch(featureNotifierProvider);
final name = state.name;

// ✅ 필요한 값만 watch
final name = ref.watch(
  featureNotifierProvider.select((state) => state.name)
);
// name이 바뀔 때만 리빌드됨

// ✅ 리스트에서 특정 인덱스만
final item = ref.watch(
  listNotifierProvider.select((list) => list[index])
);
```

### const 위젯 적극 활용

```dart
// ✅ const 위젯 — 절대 리빌드 안 함
const SizedBox(height: AppValues.spaceL)
const AppDivider()
const Icon(Icons.arrow_forward_ios, size: AppValues.iconS)

// ✅ const 생성자 있는 위젯
class AppDivider extends StatelessWidget {
  const AppDivider({super.key}); // const 생성자 필수
  // ...
}
```

### ListView.builder — itemExtent 지정

```dart
// ✅ 아이템 높이가 고정이면 itemExtent 지정 (성능 향상)
ListView.builder(
  itemCount: items.length,
  itemExtent: 72.0,  // 고정 높이 지정 → 스크롤 성능 향상
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)
```

---

## 마이그레이션 패턴

### StateNotifier → Notifier (Riverpod 2.x 코드 생성)

```dart
// ❌ 레거시 StateNotifier
class FeatureNotifier extends StateNotifier<List<FeatureEntity>> {
  FeatureNotifier(this._usecase) : super([]);
  final FeatureUsecase _usecase;

  Future<void> fetch() async {
    state = await _usecase.getAll();
  }
}

final featureProvider = StateNotifierProvider<FeatureNotifier, List<FeatureEntity>>(
  (ref) => FeatureNotifier(ref.read(featureUsecaseProvider)),
);

// ✅ 현재 방식 (@riverpod 코드 생성)
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  AsyncValue<List<FeatureEntity>> build() {
    _fetch();
    return const AsyncValue.loading();
  }

  Future<void> _fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(featureUsecaseProvider).getAll(),
    );
  }
}

// 사용
ref.watch(featureNotifierProvider)  // AsyncValue<List<FeatureEntity>>
ref.read(featureNotifierProvider.notifier)._fetch()
```

### Navigator → go_router

```dart
// ❌ 레거시 Navigator
Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeatureScreen()));
Navigator.of(context).pop();
Navigator.of(context).pushReplacement(...);

// ✅ go_router
context.push('/feature');
context.pop();
context.go('/feature');        // 히스토리 교체
context.replace('/feature');  // 현재 항목 교체
```
