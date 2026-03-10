# Design Reference

## 이 파일을 읽기 전 — 실제 토큰 파일 먼저 읽기

UI 작업 전 아래 파일을 실제로 읽어 프로젝트의 현재 값을 파악한다.
파일이 없으면 이 문서의 "기본 구조"를 기준으로 생성한다.

```
lib/core/constants/app_colors.dart
lib/core/constants/app_typography.dart
lib/core/constants/app_values.dart
lib/core/theme/app_theme.dart
```

---

## 토큰 사용 규칙 — 하드코딩 절대 금지

### 색상

```dart
// ❌ 절대 금지
color: Color(0xFF1A1A2E)
color: Colors.blue
color: Colors.grey[300]!
backgroundColor: Colors.white
containerColor: const Color(0xFFF5F5F5)

// ✅ 항상 이렇게
color: AppColors.primary
color: AppColors.textSecondary
color: AppColors.surface
backgroundColor: context.colorScheme.background
containerColor: context.colorScheme.surfaceVariant
```

### 타이포그래피

```dart
// ❌ 절대 금지
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
style: TextStyle(fontSize: 14, color: Colors.grey)
style: const TextStyle(fontFamily: 'Pretendard', fontSize: 12)

// ✅ 항상 이렇게
style: context.textTheme.titleMedium
style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)
style: AppTypography.heading1
style: AppTypography.caption.copyWith(color: AppColors.textTertiary)
```

### 간격·크기

```dart
// ❌ 절대 금지
padding: const EdgeInsets.all(16)
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
const SizedBox(height: 8)
BorderRadius.circular(12)
margin: const EdgeInsets.only(top: 24, bottom: 16)

// ✅ 항상 이렇게
padding: const EdgeInsets.all(AppValues.paddingL)
padding: const EdgeInsets.symmetric(
  horizontal: AppValues.paddingXL,
  vertical: AppValues.paddingM,
)
SizedBox(height: AppValues.spaceS)
BorderRadius.circular(AppValues.radiusM)
margin: const EdgeInsets.only(top: AppValues.spaceXL, bottom: AppValues.spaceL)
```

---

## 토큰 기본 구조 (파일 없으면 이대로 생성)

### app_colors.dart

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF6366F1); // 프로젝트에 맞게 수정
  static const Color primaryLight = Color(0xFFE0E7FF);
  static const Color secondary    = Color(0xFF8B5CF6);
  static const Color accent       = Color(0xFFF59E0B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Background
  static const Color background       = Color(0xFFFAFAFA);
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceVariant   = Color(0xFFF3F4F6);
  static const Color surfaceContainer = Color(0xFFE5E7EB);

  // Text
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);
  static const Color textDisabled  = Color(0xFFD1D5DB);

  // Border
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF6366F1);

  // Dark variants
  static const Color backgroundDark     = Color(0xFF0F0F0F);
  static const Color surfaceDark        = Color(0xFF1A1A1A);
  static const Color surfaceVariantDark = Color(0xFF262626);
  static const Color textPrimaryDark    = Color(0xFFF9FAFB);
  static const Color textSecondaryDark  = Color(0xFF9CA3AF);
}
```

### app_values.dart

```dart
class AppValues {
  AppValues._();

  // Spacing
  static const double space2  = 2;
  static const double spaceXS = 4;
  static const double spaceS  = 8;
  static const double spaceM  = 12;
  static const double spaceL  = 16;
  static const double spaceXL = 24;
  static const double space2X = 32;
  static const double space3X = 48;
  static const double space4X = 64;

  // Padding (alias for readability)
  static const double paddingXS = 4;
  static const double paddingS  = 8;
  static const double paddingM  = 12;
  static const double paddingL  = 16;
  static const double paddingXL = 24;
  static const double padding2X = 32;

  // Border Radius
  static const double radiusXS   = 4;
  static const double radiusS    = 8;
  static const double radiusM    = 12;
  static const double radiusL    = 16;
  static const double radiusXL   = 20;
  static const double radius2X   = 24;
  static const double radiusFull = 999;

  // Elevation
  static const double elevationNone = 0;
  static const double elevationXS   = 1;
  static const double elevationS    = 2;
  static const double elevationM    = 4;
  static const double elevationL    = 8;
  static const double elevationXL   = 16;

  // Icon Size
  static const double iconXS = 12;
  static const double iconS  = 16;
  static const double iconM  = 20;
  static const double iconL  = 24;
  static const double iconXL = 32;
  static const double icon2X = 48;

  // Touch Target (최소 48×48 — Apple HIG / Material 기준)
  static const double touchTarget    = 48;
  static const double touchTargetMin = 44;

  // AppBar
  static const double appBarHeight   = 56;
  static const double appBarHeightLg = 64;

  // BottomNav
  static const double bottomNavHeight = 64;

  // Button
  static const double buttonHeightS = 40;
  static const double buttonHeightM = 48;
  static const double buttonHeightL = 56;

  // Card
  static const double cardPadding = 16;

  // Max Content Width (태블릿 대응)
  static const double maxContentWidth = 480;
}
```

### app_typography.dart

```dart
import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard'; // 프로젝트에 맞게 수정

  // Display
  static const TextStyle display1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const TextStyle display2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // Heading
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.1,
  );
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label
  static const TextStyle labelLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );
  static const TextStyle captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.8,
  );
}
```

---

## 공통 위젯 구현 — 없으면 반드시 생성

### AppButton

```dart
// lib/core/widgets/app_button.dart

enum AppButtonVariant { primary, secondary, outline, ghost, danger }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  double get _height => switch (widget.size) {
    AppButtonSize.sm => AppValues.buttonHeightS,
    AppButtonSize.md => AppValues.buttonHeightM,
    AppButtonSize.lg => AppValues.buttonHeightL,
  };

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: _buildButtonContent(context),
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    final (bg, fg, border) = switch (widget.variant) {
      AppButtonVariant.primary   => (AppColors.primary, Colors.white, Colors.transparent),
      AppButtonVariant.secondary => (AppColors.primaryLight, AppColors.primary, Colors.transparent),
      AppButtonVariant.outline   => (Colors.transparent, AppColors.primary, AppColors.primary),
      AppButtonVariant.ghost     => (Colors.transparent, AppColors.textPrimary, Colors.transparent),
      AppButtonVariant.danger    => (AppColors.error, Colors.white, Colors.transparent),
    };

    return Container(
      width: widget.isFullWidth ? double.infinity : null,
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppValues.paddingXL),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppValues.radiusM),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: AppValues.iconS,
              height: AppValues.iconS,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            ),
            const SizedBox(width: AppValues.spaceS),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, color: fg, size: AppValues.iconM),
            const SizedBox(width: AppValues.spaceS),
          ],
          Text(
            widget.label,
            style: AppTypography.label.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
```

### AppShimmer (스켈레톤 로딩)

```dart
// lib/core/widgets/app_shimmer.dart
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.surface,
      child: child,
    );
  }
}

// 사용 예시 — 박스형 스켈레톤
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppValues.radiusS),
      ),
    );
  }
}

// 카드형 스켈레톤 예시
class FeatureCardShimmer extends StatelessWidget {
  const FeatureCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingL),
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppValues.spaceL),
              child: Row(
                children: [
                  const ShimmerBox(width: 48, height: 48, borderRadius: AppValues.radiusFull),
                  const SizedBox(width: AppValues.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: MediaQuery.of(context).size.width * 0.5, height: 14),
                        const SizedBox(height: AppValues.spaceXS),
                        ShimmerBox(width: MediaQuery.of(context).size.width * 0.3, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### AppEmptyState

```dart
// lib/core/widgets/app_empty_state.dart

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.action,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.padding2X),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: AppValues.icon2X,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppValues.spaceXL),
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppValues.spaceS),
            ],
            Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppValues.spaceXL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

### AppErrorState

```dart
// lib/core/widgets/app_error_state.dart

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.padding2X),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: AppValues.icon2X,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppValues.spaceXL),
            Text(
              '오류가 발생했습니다',
              style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppValues.spaceS),
            Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppValues.spaceXL),
            AppButton(
              label: '다시 시도',
              onPressed: onRetry,
              variant: AppButtonVariant.outline,
              isFullWidth: false,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
```

### AppBottomSheet

```dart
// lib/core/widgets/app_bottom_sheet.dart

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.padding,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;
  final EdgeInsets? padding;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppValues.radius2X),
        ),
      ),
      padding: padding ?? EdgeInsets.only(
        left: AppValues.paddingXL,
        right: AppValues.paddingXL,
        top: AppValues.paddingM,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppValues.paddingXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppValues.radiusFull),
              ),
            ),
          if (title != null) ...[
            const SizedBox(height: AppValues.spaceL),
            Text(title!, style: AppTypography.heading3),
          ],
          const SizedBox(height: AppValues.spaceL),
          child,
        ],
      ),
    );
  }
}
```

### AppTextField

```dart
// lib/core/widgets/app_text_field.dart

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppValues.spaceXS),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppValues.radiusM),
            border: Border.all(
              color: hasError
                ? AppColors.error
                : _isFocused
                  ? AppColors.primary
                  : AppColors.border,
              width: _isFocused || hasError ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            enabled: widget.enabled,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
              prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: AppValues.iconM, color: AppColors.textSecondary)
                : null,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppValues.paddingL,
                vertical: AppValues.paddingM,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppValues.space2),
          Row(
            children: [
              const Icon(Icons.info_outline, size: AppValues.iconXS, color: AppColors.error),
              const SizedBox(width: AppValues.space2),
              Text(
                widget.errorText!,
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
```

---

## 애니메이션 가이드

### Duration + Curve 기준표

| 유형                        | Duration  | Curve                   |
| --------------------------- | --------- | ----------------------- |
| 버튼 탭 피드백               | 100~150ms | `easeOutCubic`          |
| 아이콘·색상 상태 전환         | 150ms     | `easeOutCubic`          |
| 화면 전환 (슬라이드)          | 280~300ms | `easeOutCubic`          |
| 페이드 인/아웃               | 200~250ms | `easeOutCubic`          |
| 콘텐츠 순차 등장 (stagger)    | 300~350ms | `easeOutCubic`          |
| 바텀시트 / 모달 등장          | 350ms     | `easeOutCubic`          |
| 성공 / 완료 강조 애니메이션    | 400~500ms | `elasticOut`            |
| 경고 / 에러 쉐이크            | 300ms     | `easeInOutCubic`        |

### 핵심 패턴 코드

```dart
// 1. 버튼 탭 피드백 — 모든 탭 가능한 위젯에 적용
GestureDetector(
  onTapDown: (_) => setState(() => _pressed = true),
  onTapUp: (_) => setState(() => _pressed = false),
  onTapCancel: () => setState(() => _pressed = false),
  child: AnimatedScale(
    scale: _pressed ? 0.97 : 1.0,
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOutCubic,
    child: child,
  ),
)

// 2. 로딩 → 데이터 상태 전환 (깜빡임 없이)
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  switchInCurve: Curves.easeOutCubic,
  child: isLoading
    ? const FeatureShimmer(key: ValueKey('shimmer'))
    : FeatureContent(key: ValueKey('content'), data: data),
)

// 3. 리스트 아이템 순차 등장 (flutter_staggered_animations 패키지)
ListView.builder(
  itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
    position: index,
    duration: const Duration(milliseconds: 350),
    delay: const Duration(milliseconds: 50),
    child: SlideAnimation(
      verticalOffset: 16,
      curve: Curves.easeOutCubic,
      child: FadeInAnimation(
        curve: Curves.easeOutCubic,
        child: ItemWidget(item: items[index]),
      ),
    ),
  ),
)

// 4. 탭 전환 (BottomNav 등)
AnimatedCrossFade(
  firstChild: ScreenA(),
  secondChild: ScreenB(),
  crossFadeState: _currentIndex == 0
    ? CrossFadeState.showFirst
    : CrossFadeState.showSecond,
  duration: const Duration(milliseconds: 200),
  firstCurve: Curves.easeOutCubic,
  secondCurve: Curves.easeOutCubic,
)

// 5. 숫자 카운터 애니메이션
TweenAnimationBuilder<int>(
  tween: IntTween(begin: 0, end: targetValue),
  duration: const Duration(milliseconds: 800),
  curve: Curves.easeOutCubic,
  builder: (context, value, _) => Text(
    value.toString(),
    style: AppTypography.display2.copyWith(color: AppColors.primary),
  ),
)

// 6. 성공 체크마크 (완료 후)
AnimatedContainer(
  duration: const Duration(milliseconds: 400),
  curve: Curves.elasticOut,
  width: _isDone ? 60 : 0,
  height: _isDone ? 60 : 0,
  decoration: const BoxDecoration(
    color: AppColors.success,
    shape: BoxShape.circle,
  ),
  child: _isDone
    ? const Icon(Icons.check, color: Colors.white, size: AppValues.iconL)
    : const SizedBox.shrink(),
)
```

---

## 화면 레이아웃 패턴

```dart
// 기본 화면 구조
class FeatureScreen extends HookConsumerWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNotifierProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.background,
      appBar: AppBar(
        title: Text('화면 제목', style: AppTypography.heading3),
        centerTitle: false,
        elevation: 0,
        backgroundColor: context.colorScheme.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: state.when(
          data: (data) => data.isEmpty
            ? AppEmptyState(
                icon: Icons.inbox_outlined,
                title: '아직 없어요',
                message: '첫 번째 항목을 추가해보세요',
                action: AppButton(
                  label: '추가하기',
                  onPressed: () {},
                  isFullWidth: false,
                ),
              )
            : _FeatureContent(data: data),
          loading: () => const FeatureCardShimmer(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(featureNotifierProvider),
          ),
        ),
      ),
    );
  }
}
```
