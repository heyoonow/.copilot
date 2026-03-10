# Platform Reference

## 공통 원칙

- 터치 타겟 최소 **48×48dp** — 더 작으면 절대 안 됨
- 탭 즉시 시각 피드백 — AnimatedScale 또는 InkWell
- 로딩은 항상 Shimmer — CircularProgressIndicator는 최소화
- 에러·빈 상태 반드시 처리 — 흰 화면 방치 금지
- SafeArea 항상 적용 — 노치·Dynamic Island·홈 인디케이터 침범 금지

---

## 화면 전환 (플랫폼별 자동 분기)

```dart
// router/app_router.dart — 모든 Route에 이 함수 적용

CustomTransitionPage<void> platformTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (isIOS) {
        // iOS: 슬라이드 (오른쪽에서 왼쪽)
        return SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: SlideTransition(
            position: Tween(
              begin: Offset.zero,
              end: const Offset(-0.2, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      }

      // Android: 페이드 + 위로 슬라이드 (Material 3)
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}
```

---

## SafeArea — 올바른 사용법

```dart
// ✅ 기본 패턴 — 상단만 SafeArea, 하단은 별도 처리
Scaffold(
  body: SafeArea(
    bottom: false,  // 바텀 네비게이션 있을 때 false
    child: content,
  ),
  bottomNavigationBar: SafeArea(
    top: false,
    child: bottomNav,
  ),
)

// ✅ 바텀 네비게이션 없는 화면
Scaffold(
  body: SafeArea(
    child: content,
  ),
)

// ✅ 전체 화면 (이미지, 영상 등)
Scaffold(
  extendBodyBehindAppBar: true,
  extendBody: true,
  appBar: ...,
  body: Stack(
    children: [
      fullScreenContent,
      Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0, right: 0,
        child: customAppBar,
      ),
    ],
  ),
)
```

---

## Android 최적화

### 상태바 투명 + 아이콘 색상

```dart
// main.dart — 앱 시작 시 1회 설정
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,        // light 테마
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ),
);

// android/app/src/main/res/values/styles.xml
// <item name="android:windowTranslucentStatus">true</item>
// <item name="android:windowTranslucentNavigation">true</item>
```

### 오버스크롤 글로우 제거

```dart
// app.dart — builder에서 전역 적용
builder: (context, child) {
  return ScrollConfiguration(
    behavior: const _NoGlowScrollBehavior(),
    child: child!,
  );
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(context, child, details) => child;
}
```

### 뒤로가기 처리

```dart
// 종료 확인 다이얼로그 (루트 화면)
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('종료')),
        ],
      ),
    );
    if (shouldPop == true && context.mounted) Navigator.pop(context);
  },
  child: scaffold,
)
```

### Ripple 효과 커스텀

```dart
// 기본 InkWell (Material 3 ripple)
InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(AppValues.radiusM),
  splashColor: AppColors.primary.withOpacity(0.1),
  highlightColor: AppColors.primary.withOpacity(0.05),
  child: content,
)

// 커스텀 탭 피드백 (iOS/Android 통일)
GestureDetector(
  onTap: onTap,
  child: AnimatedScale(
    scale: _isPressed ? 0.97 : 1.0,
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOutCubic,
    child: content,
  ),
)
```

---

## iOS 최적화

### 스크롤 물리

```dart
// iOS 스타일 바운스 스크롤
ListView(
  physics: const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  ),
  children: [...],
)

// Pull-to-refresh 조합
CustomScrollView(
  physics: const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  ),
  slivers: [
    CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
    ),
    SliverList(...),
  ],
)
```

### 스와이프백 — 절대 방해하지 않는다

```dart
// ❌ 금지 — iOS 엣지 스와이프백 막음
GestureDetector(
  onHorizontalDragStart: (_) {},  // X
)

// ❌ 금지 — NavigatorObserver로 스와이프 막음
// ✅ go_router 기본 설정 유지, 커스텀 제스처는 세로 방향만 사용
```

### 쿠퍼티노 다이얼로그 (iOS 스타일)

```dart
// 플랫폼 분기 다이얼로그
void showConfirmDialog(BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  bool isDestructive = false,
}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () { Navigator.pop(context); onConfirm(); },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () { Navigator.pop(context); onConfirm(); },
            style: isDestructive
              ? TextButton.styleFrom(foregroundColor: AppColors.error)
              : null,
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
```

### 모달 바텀시트

```dart
AppBottomSheet.show(
  context: context,
  title: '옵션 선택',
  child: Column(
    children: [
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('수정'),
        onTap: () { Navigator.pop(context); onEdit(); },
      ),
      ListTile(
        leading: Icon(Icons.delete_outline, color: AppColors.error),
        title: Text('삭제', style: TextStyle(color: AppColors.error)),
        onTap: () { Navigator.pop(context); onDelete(); },
      ),
    ],
  ),
);
```

---

## 키보드 대응

```dart
// 키보드 올라올 때 콘텐츠 밀림 (폼 화면)
Scaffold(
  resizeToAvoidBottomInset: true,  // 기본값, 폼 화면에서 true
  body: SingleChildScrollView(
    reverse: true,  // 입력 필드가 키보드 위에 오도록
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: content,
  ),
)

// 키보드 내리기 (화면 어디든 탭 시)
GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  behavior: HitTestBehavior.opaque,
  child: scaffold,
)

// 다음 필드로 포커스 이동
AppTextField(
  textInputAction: TextInputAction.next,
  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
)

// 마지막 필드 — 완료
AppTextField(
  textInputAction: TextInputAction.done,
  onSubmitted: (_) { FocusScope.of(context).unfocus(); onSubmit(); },
)
```

---

## 이미지 처리

```dart
// 캐시 네트워크 이미지 (항상 이걸 사용, Image.network 금지)
CachedNetworkImage(
  imageUrl: imageUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(color: AppColors.surfaceVariant),
  errorWidget: (context, url, error) => Container(
    color: AppColors.surfaceVariant,
    child: Icon(Icons.broken_image_outlined, color: AppColors.textTertiary),
  ),
)

// 원형 아바타
ClipOval(
  child: CachedNetworkImage(
    imageUrl: avatarUrl ?? '',
    width: 40, height: 40,
    fit: BoxFit.cover,
    placeholder: (_, __) => Container(
      color: AppColors.primaryLight,
      child: Icon(Icons.person, color: AppColors.primary, size: AppValues.iconM),
    ),
    errorWidget: (_, __, ___) => Container(
      color: AppColors.primaryLight,
      child: Icon(Icons.person, color: AppColors.primary, size: AppValues.iconM),
    ),
  ),
)

// 로컬 이미지 (assets)
Image.asset(
  'assets/images/placeholder.png',
  fit: BoxFit.cover,
)
```

---

## 화면 세로 고정

```dart
// main.dart
await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
```

---

## 딥링크 처리 (go_router)

```dart
// android/app/src/main/AndroidManifest.xml
// <intent-filter android:autoVerify="true">
//   <action android:name="android.intent.action.VIEW" />
//   <category android:name="android.intent.category.DEFAULT" />
//   <category android:name="android.intent.category.BROWSABLE" />
//   <data android:scheme="https" android:host="yourapp.com" />
// </intent-filter>

// ios/Runner/Info.plist
// <key>CFBundleURLTypes</key>
// <array><dict>
//   <key>CFBundleURLSchemes</key>
//   <array><string>yourapp</string></array>
// </dict></array>

// go_router에서 자동 처리됨 — 별도 코드 불필요
```
